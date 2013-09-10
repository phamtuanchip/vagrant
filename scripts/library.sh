#!/bin/bash

LOG_PATH=/vagrant/logs
DELIVERY_PATH=/vagrant/delivery
DELIVERY_FAILED_PATH=$DELIVERY_PATH/failed
DELIVERY_SUCCEEDED_PATH=$DELIVERY_PATH/succeeded
DELIVERY_TMP_PATH=$DELIVERY_PATH/tmp
DELIVERY_LOG_FILE=$LOG_PATH/delivery.txt
TAR_EXT=.tar.gz
ZIP_EXT=.zip
WAR_EXT=.war


MANIFEST_NAME=manifest.txt
# the field separator in each line in the manifest.txt
FIELD_SEPARATOR=,
# ignore lines beginning with '#'
LINE_COMMENT=#

REPOSITORY_PATH=/vagrant/repository
DEPLOYMENT_LOG_FILE=$LOG_PATH/deployment.txt

################################################################################################
# print current time with special format
function TIMESTAMP() {

  local NOW=$(date +"%m-%d-%Y %H:%M:%S")
  echo $NOW $*

}

################################################################################################
# initialize git repository
function InitializeGitRepository() {
  if [ ! -d $REPOSITORY_PATH/.git ]
  then
    mkdir -p $REPOSITORY_PATH
    cd $REPOSITORY_PATH
    git init
    touch Readme
    git add Readme
    git commit -m "Create an empty repository"
  fi
}

################################################################################################
# commit the file to the repository
# $1 : log file
# $2 : the file which be commited, it is stored in /vagrant/delivery/tmp
# $3 : the branch which the file should be commited
# $4 : the commit message

function CommitFileToRepository() {

  # change to repository directory
  cd $REPOSITORY_PATH

# switch to the branch
git checkout $3
error=$?
if [ $error -ne 0 ]
then
  git branch $3
  git checkout $3
  error=$?
  if [ $error -ne 0 ]
  then
    TIMESTAMP "ERROR: Couldn't create the branch $3 [returned code :$error]" >> $1
    return $error
  fi
fi

local file_relative_path=`echo $2 | sed -e s:$DELIVERY_TMP_PATH/::g`
mkdir -p `dirname $file_relative_path`

mv $2 $REPOSITORY_PATH/$file_relative_path

# add the file to the repository
git add $file_relative_path

# commit the file
git commit -m "$4"

error=$?
if [ $error -ne 0 ]
then
   # the file is the same as in the repository
   if git diff --exit-code $file_relative_path
   then
     return 0
   fi
  TIMESTAMP "ERROR: Couldn't commit the file $2 to the branch $3 [returned code :$error]" >> $1
fi

return $error

}

################################################################################################
# $1 full path to the manifest.txt file
function CommitFilesToRepository {

  local manifest_dir=`dirname $1`
 
  cd $manifest_dir

  # trim white space from both sides of a line
  # remove blank line
  # remove comment line ( started with '#' )
  sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//' $MANIFEST_NAME | sed '/^$/d' | egrep -v "^$LINE_COMMENT" > $MANIFEST_NAME.$$

  local LINE_NUMBERS=`wc -l < $MANIFEST_NAME.$$`
  local SUCEESS_NUMBERS=0
  for(( i = 1; i <= $LINE_NUMBERS; i++ ))
  do
    cd $manifest_dir
    # ignore the line that doesn't contain exactly three fields ( separated by , )
    local NF=`sed -n "$i"p $MANIFEST_NAME.$$ | awk -F"$FIELD_SEPARATOR" '{print NF}'`
    if [ $NF -ne 3 ]
    then
      continue
    fi

    commit_name=`sed -n "$i"p $MANIFEST_NAME.$$ | awk -F"$FIELD_SEPARATOR" '{print $1}'`
    commit_branch=`sed -n "$i"p $MANIFEST_NAME.$$ | awk -F"$FIELD_SEPARATOR" '{print $2}'`
    commit_message=`sed -n "$i"p $MANIFEST_NAME.$$ | awk -F"$FIELD_SEPARATOR" '{print $3}'`

    if [ -f $commit_name ]
    then
      # copy the file to tmp dir
      mkdir -p `dirname $DELIVERY_TMP_PATH/$commit_name`
      cp $commit_name $DELIVERY_TMP_PATH/$commit_name
      error=$?
      if [ $error -ne 0 ]
      then
        TIMESTAMP "ERROR: Couldn't copy the file $commit_name to the directory $DELIVERY_TMP_PATH/$commit_name [returned code :$error]" >> $DELIVERY_LOG_FILE
        continue
      fi
      # commit the file in tmp dir to the repository
      CommitFileToRepository $DELIVERY_LOG_FILE "$DELIVERY_TMP_PATH/$commit_name" "$commit_branch" "$commit_message"
      error=$?
      if [ $error -eq 0 ]
      then
        SUCEESS_NUMBERS=$(( SUCEESS_NUMBERS + 1 ))
      fi
    else
      TIMESTAMP "ERROR: The file $commit_name doesn't exist in $manifest_dir" >> $DELIVERY_LOG_FILE
    fi
  done

  rm -f $manifest_dir/$MANIFEST_NAME.$$

  if [ $LINE_NUMBERS -eq $SUCEESS_NUMBERS ]
  then
    return 0
  else
    return 1
  fi

}

################################################################################################
# run a job every 't' minutes
# $1 job name
# $2 the number of minutes the job will run after
function AddScriptToCrontab() {

  # try to remove the old schedule of the job
  sudo crontab -l | grep -v $1 > /tmp/cron.$$
  # add the new schedule
  sudo echo "*/$2 * * * * bash $1" >> /tmp/cron.$$
 
  sudo crontab /tmp/cron.$$
  sudo rm -f /tmp/cron.$$
}

################################################################################################
# $1 file path which should be deployed
# $2 context path
# $3 the deployment log
function DeployWarFile() {

  curl --upload-file $1 "http://admin:admin@localhost:8080/manager/deploy?path=/$2&update=true" 1>>$3 2>/dev/null

}


################################################################################################
function InstallApacheTomcat() {

sudo apt-get -y install tomcat6
sudo apt-get -y install tomcat6-admin

# change /etc/tomcat6/tomcat-users.xml
sudo sed -i '$d' /etc/tomcat6/tomcat-users.xml
sudo echo '  <role rolename="manager"/>' >> /etc/tomcat6/tomcat-users.xml
sudo echo '  <role rolename="admin"/>' >> /etc/tomcat6/tomcat-users.xml
sudo echo '  <user username="admin" password="admin" roles="admin,manager"/>' >> /etc/tomcat6/tomcat-users.xml
sudo echo '</tomcat-users>' >> /etc/tomcat6/tomcat-users.xml

sudo /etc/init.d/tomcat6 restart

}

################################################################################################
function InstallGit() {

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

}

################################################################################################
function InstallCurl() {

# install a tool to transfer data from or to a server
sudo apt-get -y install curl


}
