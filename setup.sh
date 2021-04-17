#!/bin/bash

function ask() {
    question=$1
    default=$2
    read -r -p "$question: " -e -i "$default" value
    echo $value
}

function harden_ssh() {
    sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
    /etc/init.d/ssh restart
}

function install_updates() {
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get autoremove --purge -y
}

function install_essentials() {
    apt-get install -y htop git zip unzip tar screen
}

function install_docker() {
    curl -sSL https://get.docker.com/ | sh
    curl -L https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | cut -d \" -f4)/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

function install_lamp() {
    apt-get install -y mariadb-server mariadb-client

    mysql_secure_installation
    mysql -u root -e "use mysql; update user set plugin = '' where User = 'root'; flush privileges;"
    /etc/init.d/mysql restart

    apt-get install -y apache2
    apt-get install -y php php-mysql libapache2-mod-php

    wget -O /var/www/html/adminer.php https://github.com/vrana/adminer/releases/download/v4.7.7/adminer-4.7.7.php
}

function install_openjdk_11() {
    apt-get install -y openjdk-11-jdk
}

function install_mailcow() {
    install_docker
    cd /opt
    git clone https://github.com/mailcow/mailcow-dockerized
    cd mailcow-dockerized
    ./generate_config.sh
    docker-compose pull
    docker-compose up -d
    echo ""
    echo "A default mailcow admin user was created."
    echo "Username: admin"
    echo "Password: moohoo"
}

function mount_storagebox() {
    username=$(ask "Storage Box username")
    password=$(ask "Storage Box password")
    uid=$(ask "Mount as UID" "root")
    gid=$(ask "Mount as GID" "root")

    apt-get install -y cifs-utils

    echo "username=$username" >> /etc/storagebox-$username.txt
    echo "password=$password" >> /etc/storagebox-$username.txt
    chmod 600 /etc/storagebox-$username.txt

    echo "//$username.your-storagebox.de/backup /storagebox-$username iocharset=utf8,rw,credentials=/etc/storagebox-$username.txt,uid=$uid,gid=$gid,file_mode=0660,dir_mode=0770 0 0" >> /etc/fstab
    mkdir /storagebox-$username
    mount -a
}

action=""

while [[ $action != x ]]
do
    echo ""
    echo "[1] Harden SSH"
    echo "[2] Install updates"
    echo "[3] Install essentials (htop, git, zip, unzip, tar, screen)"
    echo "[4] Install Docker (docker, docker-compose)"
    echo "[5] Install LAMP stack (apache2, mariadb, php, adminer)"
    echo "[6] Install OpenJDK 11 JDK"
    echo "[7] Install mailcow (and also Docker)"
    echo "[8] Mount a Hetzner Storage Box"
    echo "[x] Exit"
    echo ""
    action=$(ask "Select an action")
    echo ""

    case $action
    in
        1) harden_ssh ;;
        2) install_updates ;;
        3) install_essentials ;;
        4) install_docker ;;
        5) install_lamp ;;
        6) install_openjdk_11 ;;
        7) install_mailcow ;;
        8) mount_storagebox ;;
    esac
done
