#!/bin/bash
set -o errexit
set -o pipefail

thisdir=`pwd`
softdir=$(readlink -f $(dirname $0))

whattodo=$1
singlestrain=$2
forcereload=$3

if [ $# -lt 1 ]  || [ $1 == '-h' ]; then
    echo; echo "  Usage:" $(basename $0) \<command\> \<strain\>  
    echo "  command: command to be run. Options: install,download,check,cleani,nanoclean"
    echo "  strain: Download data for this strain/s, only for command=download or check."
    echo "          Options: s288c,sk1,cbs,n44,all"
    exit
fi


if [[ ${singlestrain} == "" ]]; then
	singlestrain=s288c
fi



if [ $whattodo == "install" ]; then
  ###################################################
  echo; echo " Downloading and installing some utilities..."
  ###################################################

	$softdir/utils/prepsrc.sh
	echo "                 ... all srcs ready!"
fi



if [ $whattodo == "download" ]; then
  ###################################################
  echo; echo " Downloading and preparing data..."
  ###################################################
	cd $thisdir
	$softdir/utils/prepdata.sh $singlestrain 0  $forcereload
	echo "                 ... requested data ready!"
fi


if [ $whattodo == "clean" ]; then
  ###################################################
  #### echo " Cleaning data..."
  ###################################################

        cd $thisdir
        $softdir/utils/prepdata.sh $singlestrain 1
        #echo "                 ... cleaned data!"
fi

if [ $whattodo == "nanoclean" ]; then
  #####################################################################
  echo; echo " Cleaning data saving the fast5 needed to run Nanopolish"
  #####################################################################

        cd $thisdir
        $softdir/utils/prepdata.sh $singlestrain -1
        #echo "                 ... cleaned data!"
fi



if [ $whattodo == "check" ]; then
  ###################################################
  echo; echo " Checking fastq files..." 
  ###################################################
        cd $thisdir
        $softdir/utils/docheck.sh $singlestrain
fi

if [ $whattodo == "deepcheck" ]; then
  ###################################################
  echo; echo " Checking intermediate files..." 
  ###################################################
        cd $thisdir
        $softdir/utils/deepcheck.sh $singlestrain 
fi


