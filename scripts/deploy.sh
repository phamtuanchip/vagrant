#!/bin/bash

source /vagrant/scripts/library.sh

# main function

cd $REPOSITORY_PATH

for branch in `git branch | cut -b 1 --complement | egrep -v 'master'`
do
  # switch to the branch
  git checkout $branch  >/dev/null 2>&1

  # list all files in the branch
  for file in `git ls-files | grep "$WAR_EXT$"`
  do      
       # deploy
       DeployWarFile "$REPOSITORY_PATH/$file" "$branch-`basename $file $WAR_EXT`" "$DEPLOYMENT_LOG_FILE"

  done
done
