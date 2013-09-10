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

  # install java 
  sudo apt-get -y install openjdk-7-jre-headless 


  
  # install unzip 
  sudo apt-get -y install unzip

  # install tomcat  
  sudo apt-get -y install tomcat6
  sudo apt-get -y install tomcat6-admin
  # change /etc/tomcat6/tomcat-users.xml
  sudo sed -i '$d' /etc/tomcat6/tomcat-users.xml
  sudo echo '  <role rolename="manager"/>' >> /etc/tomcat6/tomcat-users.xml
  sudo echo '  <role rolename="admin"/>' >> /etc/tomcat6/tomcat-users.xml
  sudo echo '  <user username="root" password="gtngtn" roles="admin,manager"/>' >> /etc/tomcat6/tomcat-users.xml
  sudo echo '</tomcat-users>' >> /etc/tomcat6/tomcat-users.xml

  # start server 
  sudo /etc/init.d/tomcat6 restart

  # install the newest versions of packages currently installed
  # sudo apt-get -y upgrade

  
  # install git 
  sudo apt-get -y install git-core 

  # install git-daemon
  sudo apt-get -y install git-daemon-run

  # add git basic configurations
  sudo git config --global user.name "Tuan Pham"
  sudo git config --global user.email "phamtuanchip@gmail.com"

  # config the git-daemon , change option 'base-path' and add option 'export-all'
  #   
  echo '#!/bin/sh' >  /tmp/setup.sh.$$
  echo 'exec 2>&1' >> /tmp/setup.sh.$$
  echo "echo 'git-daemon starting.'" >> /tmp/setup.sh.$$
  echo 'exec chpst -ugitdaemon \' >> /tmp/setup.sh.$$
  echo '  /usr/lib/git-core/git-daemon --verbose --export-all --base-path=/vagrant' >> /tmp/setup.sh.$$

  sudo cp /tmp/setup.sh.$$ /etc/sv/git-daemon/run

  # restart the git-daemon
  sudo sv restart git-daemon


  InitializeGitRepository

  InstallCurl

   

fi

