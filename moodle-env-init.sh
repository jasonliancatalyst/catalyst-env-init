#! /bin/bash

shellPWD="$(pwd)"

echo "Usage: ~/catalyst-env-init/e-learning-env-init.sh [base_branch] [moodle_git_url] [moodle_branch]"
echo "Or run with interactive mode..."

baseDockerBranch=${1}
moodleRepoURL=${2}
moodleRepoBranch=${3}

if [[ -z ${baseDockerBranch} ]]; then
    PS3='Please input your base environment branch option and press enter [option number only]: '
    options=("1804-psql" "2004-psql" "Quit")

    select opt in "${options[@]}"

    do
        case $opt in
            "1804-psql")
                baseDockerBranch='1804-psql'
                break
                ;;
            "2004-psql")
                baseDockerBranch='2004-psql'
                break
                ;;
            "Quit")
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
fi

if [[ -z ${moodleRepoURL} ]]; then
    promptInitRepoURL='Please enter your site repo git URL:'
    echo $promptInitRepoURL
    while read moodleRepoURL; do
        if [[ ! -z ${moodleRepoURL} ]]; then
            echo "$moodleRepoURL is entered."
            break
        fi
    done
fi

if [[ -z ${moodleRepoBranch} ]]; then
    promptInitRepoBranch='Please enter your site repo branch name:'
    echo $promptInitRepoBranch
    while read moodleRepoBranch; do
        if [[ ! -z ${moodleRepoBranch} ]]; then
            echo "$moodleRepoBranch is entered."
            break
        fi
    done
fi

# Ask if user wants to run composer install and phpunit init inside the container.
promptInitInsideContainer='Do you wish to run init jobs (composer install/phpunit init) inside container? [Y/N]'
echo $promptInitInsideContainer
while read answerInitInsideContainer; do
    if [[ ! -z $answerInitInsideContainer ]]; then
        echo "$answerInitInsideContainer is entered."
        break
    fi
done

echo "You selected base docker $baseDockerBranch"

echo "Clone the base environment docker repo: git clone -b $baseDockerBranch https://github.com/catalyst/docker_moodle.git ."
git clone -b $baseDockerBranch https://github.com/catalyst/docker_moodle.git . && \

# Environment variables for XDEBUG.
xdebuEnvConf='XDEBUG_CONFIG="remote_host=172.17.0.1 remote_port=9000"'
xdebugIdeConf='PHP_IDE_CONFIG="serverName=http://localhost"'

echo "docker-compose up -d --force-recreate --build"
docker-compose up -d --force-recreate --build
webcont="$(docker-compose ps -q moodle)"
docker exec -t $webcont bash -c "echo ${xdebuEnvConf} >> /etc/environment"
docker exec -t $webcont bash -c "echo ${xdebugIdeConf} >> /etc/environment"

echo "update owner and user group for ./siteroot, run: chown ${USER}:${USER} ./siteroot"
sudo chown ${USER}:${USER} ./siteroot
cd siteroot

echo "Clone moodle repo: git clone -b ${moodleRepoBranch} ${moodleRepoURL} ."
git clone -b ${moodleRepoBranch} ${moodleRepoURL} .  && \

echo "Copy config file: cp moodle-config siteroot/config.php"
cp ../moodle-config config.php  && \

echo "Update git submodule: git submodule update --init --recursive --jobs 16"
git submodule update --init --recursive --jobs 16  && \

cd ../

if [[ ! -f "${shellPWD}/docker-compose.yml" ]]; then
    echo "Current directory: ${shellPWD}"
    echo "Error docker-compose file ${shellPWD}/docker-compose.yml not found. Exiting..."
    exit
fi

# Check if use enter "Y" for proceeding with environment setup process inside the container.
if [[ ${answerInitInsideContainer,,} == "y" ]]
then
    echo "Proceeding...."
    wget -O - https://raw.githubusercontent.com/jasonliancatalyst/docker-env-init/master/container-setup.sh | docker exec -i $webcont bash -
    sudo chown ${USER}:${USER} ./siteroot
else
    echo "You can run it manually:"
    echo "webcont=\"$(docker-compose ps -q moodle)\" && \\"
    echo "wget -O - https://raw.githubusercontent.com/jasonliancatalyst/docker-env-init/master/container-setup.sh | docker exec -i $webcont bash -"
    echo "Exiting...."
    exit
fi
