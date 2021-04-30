#! /bin/bash

shellPWD="$(pwd)"
echo ${shellPWD}
sudo pwd

echo "Usage: ~/catalyst-env-init/e-learning-env-init.sh [clientIdentifier] [base_branch] [moodle_git_url] [moodle_branch]"
echo "Or run with interactive mode..."

clientIdentifier=${1}
BaseDockerEnvBranch=${2}
moodleRepoURL=${3}
moodleRepoBranch=${4}

# clientIdentifier is used for the parent folder name created inside user's ${HOME}.
if [[ -z ${clientIdentifier} ]]; then
    echo 'Please enter the client identifier, lower case no space please, this will be used to create the container directory:'
    while read clientIdentifier; do
        if [[ ! -z ${clientIdentifier} ]]; then
            echo "$clientIdentifier is entered."
            break
        fi
    done
fi

# Create the client folder in the $HOME directory.
cd /home/${USER}/ && mkdir -p repo && cd repo && mkdir -p ${clientIdentifier}/

if [[ -z ${BaseDockerEnvBranch} ]]; then
    PS3='Please input your base environment branch option and press enter [option number only]: '
    options=("1804-psql" "2004-psql" "Quit")

    select opt in "${options[@]}"

    do
        case $opt in
            "1804-psql Ubuntu 18.04 with PostgreSQL 9.6")
                BaseDockerEnvBranch='1804-psql'
                break
                ;;
            "2004-psql Ubuntu 20.04 with PostgreSQL 9.6")
                BaseDockerEnvBranch='2004-psql'
                break
                ;;
            "Quit")
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
fi

echo "You selected base docker environment ${BaseDockerEnvBranch}"

# GEt moodle site repo URL.
if [[ -z ${moodleRepoURL} ]]; then
    echo 'Please enter your site repo git URL:'
    while read moodleRepoURL; do
        if [[ ! -z ${moodleRepoURL} ]]; then
            echo "${moodleRepoURL} is entered."
            break
        fi
    done
fi

# Get moodle site repo branch.
if [[ -z ${moodleRepoBranch} ]]; then
    echo 'Please enter your site repo branch name:'
    while read moodleRepoBranch; do
        if [[ ! -z ${moodleRepoBranch} ]]; then
            echo "${moodleRepoBranch} is entered."
            break
        fi
    done
fi

# Ask if user wants to run composer install and phpunit init inside the container.
echo 'Do you wish to run init jobs (composer install/phpunit init) inside container? [Y/N]'
while read answerInitInsideContainer; do
    if [[ ! -z ${answerInitInsideContainer} ]]; then
        echo "${answerInitInsideContainer} is entered."
        break
    fi
done

# Create the client folder in the $HOME directory.
cd /home/${USER}/repo/${clientIdentifier}/ && mkdir -p ${moodleRepoBranch} && cd ${moodleRepoBranch}
echo "Current directory: $(pwd)"
repoRootPath="/home/${USER}/repo/${clientIdentifier}/${moodleRepoBranch}"

# Switch the docker-compose.yml file to docker-compose-mysql.yml based on the base docker arg string.
dockerComposeFileName="docker-compose.yml"
moodleConfigFileName="moodle-config"
if [[ ${BaseDockerEnvBranch} == *"mysql"* ]]; then
    echo "Using mysql docker-composer.yml file."
    dockerComposeFileName="docker-compose-mysql.yml"
    moodleConfigFileName="moodle-config.mysql"
fi

# Copy required docker-compose file to local folder.
echo "Copy required docker-compose files: cp -rf ${shellPWD}/${BaseDockerEnvBranch}/ ${shellPWD}/${dockerComposeFileName} ${shellPWD}/moodle-config ."
cp -rf ${shellPWD}/${BaseDockerEnvBranch}/ .
cp -rf ${shellPWD}/${moodleConfigFileName} ./moodle-config
cp -rf ${shellPWD}/${dockerComposeFileName} ./docker-compose.yml

# The branch name and other variables will be used in the container host names, as well as in the local path for persistent DB data.
# These will be saved to a .env file so that the docker-compose can pick them up and use.
echo "MOODLE_BRANCH=${moodleRepoBranch}" > ./.env && \
echo "BASE_DOCKER_ENV_BRANCH=${BaseDockerEnvBranch}" >> ./.env && \
echo "REPO_ROOT_PATH=${repoRootPath}" >> ./.env && \
echo "MOODLE_DOCKERFILE_BASE_PATH=${shellPWD}" >> ./.env

# The local path for persistent DB data.
dbpath="/var/docker_db/${moodleRepoBranch}/"

echo "Current directory ${workdir}."
echo "docker-compose up -f ./docker-compose.yml -d --force-recreate --build "
docker-compose -f ./docker-compose.yml up -d --force-recreate --build --remove-orphans --always-recreate-deps && \
echo "Complete docker-compose setup, containers are up."

echo "update owner and user group for ./siteroot, run: chown ${USER}:${USER} ./siteroot"
sudo chown -R ${USER}:${USER} ./siteroot
cd siteroot

# Check  if siteroot folder is empty.
if [[ ! -z "$(ls -A ./)" ]]; then
    # If siteroot folder is not empty, prompt to delete all files.
    echo "Files in siteroot: $(ls -A ./)"
    echo "The folder $(pwd) is not empty, do you wish to remove all files in the folder [Y/N]?"
    while read canRemoveAllSiterootFiles; do
        if [[ ! -z ${canRemoveAllSiterootFiles} ]] && [[ ${canRemoveAllSiterootFiles,,} == "y" ]]; then
            echo "You selected ${canRemoveAllSiterootFiles}, proceeding..."
            cd .. && sudo rm -rf siteroot && mkdir siteroot && cd siteroot && echo "Siteroot folder cleared." || exit
            break
        else
            echo "Do not remove file, proceeding..."
            break
        fi
    done
fi

if [[ ! -z "$(ls -A ./)" ]]; then
    echo "The folder $(pwd) is not empty, do you wish to continue git clone moodle repo [Y/N/S]?"
    echo "Y = Continue; N = Exit; S = Skip git clone and continue setup"
    while read continueGitCloneEvenIfFolderNotEmpty; do
        if [[ ! -z ${continueGitCloneEvenIfFolderNotEmpty} ]] && [[ ${continueGitCloneEvenIfFolderNotEmpty,,} == "n" ]]; then
            echo "You selected ${continueGitCloneEvenIfFolderNotEmpty}, exiting..."
            exit
        else
            break
        fi
    done
fi

if [[ -z ${continueGitCloneEvenIfFolderNotEmpty} ]] || [[ ${continueGitCloneEvenIfFolderNotEmpty,,} == "y" ]]; then
    # Attempt to clone to current directory $(pwd), if any error then exit.
    echo "Clone moodle repo: git clone -b ${moodleRepoBranch} ${moodleRepoURL} ."
    git clone -b ${moodleRepoBranch} ${moodleRepoURL} . && echo "Clone moodle site repo complete." || exit
fi

# Copy the site config file.
echo "Copy config file: cp moodle-config siteroot/config.php"
cp -f ../moodle-config config.php

# Set up the submodules.
echo "Update git submodule: git submodule update --init --recursive --jobs 16"
git submodule update --init --recursive --jobs 16  && echo "Installed git submodules..." || exit

# Update the folder owner and user group to current user ${USER}.
echo "Process directory chown: cd ../ && sudo chown -R ${USER}:${USER} ./siteroot"
cd ../ && sudo chown -R ${USER}:${USER} ./siteroot

# Check if use enter "Y" for proceeding with environment setup process inside the container.
if [[ ${answerInitInsideContainer,,} == "y" ]]
then
    # Get the container ID string.
    webContainer="$(docker-compose ps -q moodle)"

    if [[ -z ${webContainer} ]]; then
        echo "Something's wrong, container is not detected... exiting..."
        exit
    fi

    echo "Current directory: $(pwd)"
    echo "Proceeding to tasks running using container-setup.sh inside container ${webContainer} ...."
    # Download setup script to run inside container.
    wget -O - https://raw.githubusercontent.com/jasonliancatalyst/docker-env-init/master/container-setup.sh | docker exec -i $webContainer bash -
    sudo chown ${USER}:${USER} ./siteroot
else
    echo "You can run it manually:"
    echo "webContainer=\'$(docker-compose ps -q moodle)\'"
    echo "container-setup.sh | docker exec -i ${webContainer} bash -"
    echo "Exiting...."
fi
