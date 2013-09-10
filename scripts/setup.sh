#!/bin/bash

source /vagrant/scripts/library.sh

# main function

dpkg-query -Wf'${db:Status-abbrev}' tomcat6 2>/dev/null

if [ $? -ne 0 ]
then

  sudo mkdir -p $LOG_PATH
  sudo mkdir -p $DELIVERY_PATH
  sudo mkdir -p $DELIVERY_FAILED_PATH
  sudo mkdir -p $DELIVERY_SUCCEEDED_PATH
  sudo mkdir -p $DELIVERY_TMP_PATH
  sudo mkdir -p $REPOSITORY_PATH
  # update the local package index files with the latest changes made in repositories
  sudo apt-get -y update

  # install the newest versions of packages currently installed
  sudo apt-get -y upgrade

  sudo apt-get -y install unzip

  InstallApacheTomcat

  InstallGit

  InitializeGitRepository

  InstallCurl

  # add script delivery.sh and deploy.sh to crontab
  AddScriptToCrontab /vagrant/scripts/delivery.sh 5
  AddScriptToCrontab /vagrant/scripts/deploy.sh 5

fi

