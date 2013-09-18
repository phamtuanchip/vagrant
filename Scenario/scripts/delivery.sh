#!/bin/bash

source /vagrant/scripts/library.sh

#  process *.tar.gz and *.zip files in DELIVERY_PATH
for archive_file_path in `find $DELIVERY_PATH -maxdepth 1 -name "*$TAR_EXT" -o -name "*$ZIP_EXT"`
do
  # change to delivery home directory
  cd $DELIVERY_PATH
  archive_file_name=
  
  file_ext=`basename $archive_file_path | awk -F . '{if (NF>1) {print $NF}}'`
  if [ ".$file_ext" = "$ZIP_EXT" ]
  then
    # get extract dir name
    archive_file_name=`basename $archive_file_path $ZIP_EXT`
    mkdir $archive_file_name
    # extract zip file
    unzip -oq $archive_file_path -d $archive_file_name
  else
  
    # get extract dir name
    archive_file_name=`basename $archive_file_path $TAR_EXT`
    mkdir $archive_file_name

    # extract tar file
    tar xf $archive_file_path -C $archive_file_name
  
  fi
  # find full path of the manifest file
  manifest_path=`find $DELIVERY_PATH/$archive_file_name -name $MANIFEST_NAME`
  
  if [ ! -f $manifest_path ]
  then
    continue
  fi

  CommitFilesToRepository $manifest_path
  error=$?
  
  # move archive file to succeeded folder or failed folder
  if [ $error -eq 0 ]
  then   
   mv $archive_file_path $DELIVERY_SUCCEEDED_PATH
  else
   mv $archive_file_path $DELIVERY_FAILED_PATH  
  fi

  # remove extract dir
  rm -fr $DELIVERY_PATH/$archive_file_name

done
