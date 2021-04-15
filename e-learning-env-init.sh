#! /bin/bash

shellPWD="$(pwd)"

bashBranch='2004-psql'

PS3='Please input your base environment branch and press enter [option number only]: '
options=("1804-psql" "2004-psql" "Quit")

select opt in "${options[@]}"

do
    case $opt in
        "1804-psql")
            bashBranch='1804-psql'
            break
            ;;
        "2004-psql")
            bashBranch='2004-psql'
            break
            ;;
        "Quit")
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo "You selected $bashBranch"

echo "Clone the base environment docker repo: git clone -b $bashBranch --single-branch https://github.com/catalyst/docker_moodle.git ."
git clone -b $bashBranch --single-branch https://github.com/catalyst/docker_moodle.git .

echo "docker-composer down and create the containers again:\n docker-compose -f 'docker-compose.yml' down && docker-compose up -d --force-recreate --build"
docker-compose -f 'docker-compose.yml' down && docker-compose up -d --force-recreate --build

echo "update owner and user group for ./siteroot, run: chown ${USER}:${USER} ./siteroot"
sudo chown ${USER}:${USER} ./siteroot
cd siteroot

promptInitRepoURL='Please enter your site repo git URL:'
echo $promptInitRepoURL
read repoURL
echo "$repoURL is entered.\n"

promptInitRepoBranch='Please enter your site repo branch name:'
echo $promptInitRepoBranch
read repoBranch
echo "$repoBranch is entered.\n"

echo "Clone moodle repo: git clone --single-branch -b ${repoBranch} ${repoURL} ."
git clone -b ${repoBranch} --single-branch ${repoURL} .

echo "Copy config file: cp moodle-config siteroot/config.php"
cp ../moodle-config config.php

echo "Update git submodule: git submodule update --init --recursive --jobs 16"
git submodule update --init --recursive --jobs 16

cd ../

if [[ ! -f "${shellPWD}/docker-compose.yml" ]]; then
    echo "Current directory: ${shellPWD}"
    echo "Error docker-compose file ${shellPWD}/docker-compose.yml not found. Exiting..."
    exit
fi

webcont="$(docker-compose ps -q moodle)"
wget -O - https://raw.githubusercontent.com/jasonliancatalyst/docker-env-init/master/container-setup.sh | docker exec -i $webcont bash -
