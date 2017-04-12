#!/bin/bash
set -o errexit
set -o pipefail

thisdir=`pwd`


singlestrain=$1


if [ $# -lt 1 ]  || [ $1 == '-h' ]; then
    echo; echo "  Usage:" $(basename $0) \<strain\> 
    echo "  strain: Download data for this strain [s288c] (s288c,sk1,cbs,n44,all,none)"
    exit
fi

if  [ $singlestrain == "none" ]; then
    strains=( )
elif [ $singlestrain != "all" ]; then
    strains=( $singlestrain )
else
    strains=( s288c sk1 cbs n44 )
fi

##########################################
####### download some utilities ##########
##########################################
echo; echo " Downloading some utilities..."
$thisdir/utils/prepsrc.sh

### check
ls $thisdir/utils/src
echo "     ... all srcs ready!"



# if 'none' option: all done, end here
if [[ ${#strains[@]} -eq 0 ]]; then exit; fi


###################################################
  echo; echo " Downloading and preparing data..."
###################################################
source $thisdir/utils/runlist.sh



###########################################
########## Download data from ENA #########
###########################################
cd $thisdir
source $thisdir/utils/src/locpy/bin/activate


#******************* ONT ******************* #

folder=$thisdir/fastqs/ont
	
mkdir -p $folder
cd $folder

for strain in "${strains[@]}"; do
    mkdir -p $folder/$strain
    cd  $folder/$strain

    if [ ! -f $strain\_pass2D.fastq ]; then  ## only if fastq file is not there already

	thislist=ont${strain}[@]
	for tarfile  in "${!thislist}"; do
	    file=$ontftp/$tarfile
	    fold=$(basename "$tarfile" .tar.gz)
	    
	    if [ ! -f $tarfile ] && [ ! -f $fold\_pass2D.fastq ] ; then
		if [[ `wget -S --spider $file 2>&1  | grep exists` ]]; then
	    	    wget $ontftp/$tarfile
		else 
		    echo "Could not find url " $file
		fi
	    fi

	    if [ ! -d $fold ] && [ ! -f $fold\_pass2D.fastq ] ; then
		tar -xvzf $tarfile
		echo untar
	    fi
	    
	    if [ ! -f $fold\_pass2D.fastq ]; then
		
		fast5pass=$fold/reads/downloads/pass
		fast5fail=$fold/reads/downloads/fail
		
		if ! ls $fast5pass  &> /dev/null; then
		    echo "  " no fast5 found! $fast5pass
		    nfiles=0
		else
		    nfiles=`ls $fast5pass | wc -l`
		fi
		
		if [ $nfiles -gt 0 ]; then
		    #echo poretools
		    poretools fastq --type 2D $fast5pass > $fold\_pass2D.fastq
		    if [ $strain == "s288c" ]; then
		    #echo poretools fail
			poretools fastq --type 2D $fast5fail > $fold\_fail2D.fastq
		    fi
		    
		else
		    echo no fast5 found! $fast5pass
		fi
	    fi ## poretools
	done # runs
    
    

	if ! ls *fastq  &> /dev/null; then
	    fqs=0
	else
	    fqs=`ls *fastq | wc -l` 
	fi
	

	if [ $fqs -eq 0 ]; then  
	    echo; echo " Error! no ONT fastqs found or creaed"  $strain
	else
	    echo " Merging " $fqs "fastqs for the " $strain " strain"
	    
	    for f in *_pass2D.fastq; do 
		cat $f >> $strain\_pass2D.fastq
	    done 
	    chmod -w $strain\_pass2D.fastq

	    
	    if [ $strain == "s288c" ]; then
	        cp $strain\_pass2D.fastq $strain\_all2D.fastq
		for f in *fail2D.fastq; do 
		    cat $f >> $strain\_all2D.fastq
		done
		chmod -w $strain\_all2D.fastq
	    fi
	fi
    
    fi ## if ! global fastq file 

    # clean all except fastq files before starting next strain
    if [ -f $strain\_pass2D.fastq ]; then 
	dd=`ls -I "*fastq" | wc -l`
	if [ $dd -gt 0 ]; then  
	    rm -r $(ls -I "*fastq")
	fi
    fi
done # strain

#******************* PacBio ******************* #

folder=$thisdir/fastqs/pacbio
mkdir -p $folder
cd $folder



for strain in "${strains[@]}"; do   ## loop on strains
    mkdir -p $folder/$strain
    cd  $folder/$strain


    if [ ! -f $strain\_pacbio.fastq ]; then  ##  if fastq file is not there already

	runs=pb${strain}[@]
	for run in "${!runs}"; do   ## loop over pacbio runs
	    
	    thislist=pb$strain\_${run}[@]
	    for tarfile  in "${!thislist}"; do # loop over pacbio runs
		if [ ! -f $(basename $tarfile) ]; then  # download if file is not there already
		    if [[ `wget -S --spider $tarfile 2>&1  | grep exists` ]]; then
			wget $tarfile
		    else 
			echo "Could not find url " $tarfile
		    fi
		fi
	    done  # download each file in a run

	    # files are downloaded, now extract fastq 	    
	    for file in *.bas.h5; do
		if [ ! -f $(basename $file .bas.h5).fastq ]; then
		    python $thisdir/utils/src/pbh5tools/bin/bash5tools.py --minLength 500 --minReadScore 0.8000 --readType subreads --outType fastq $file 
		fi
	    done
	    
	done  ## runs

	# fastq per run ready: now merge them in a single file
	for f in *.fastq; do 
	    cat $f >> $strain\_pacbio.fastq
	done 
	chmod -w $strain\_pacbio.fastq


	if [ $strain == "s288c" ]; then
	    echo recreate pacbio s288c subsample 31X

	fi
	
   fi ## if ! global fastq file 

   # if all successful: clean all except fastq files before starting next strain
   if [ -f $strain\_pacbio.fastq ]; then 
       dd=`ls -I "*fastq" | wc -l`
       if [ $dd -gt 0 ]; then  
	   rm -r $(ls -I "*fastq")
       fi
   fi
   
done

exit
#******************* MiSeq ******************* #

folder=$thisdir/fastqs/miseq
	
mkdir -p $folder
cd $folder

for strain in "${strains[@]}"; do
    mkdir -p $folder/$strain
    cd  $folder/$strain

    thislist=miseq${strain}[@]
    for cramfile  in "${!thislist}"; do
	file=$miseqftp/$cramfile
	if [ -f $cramfile ]; then
	    if [[ `wget -S --spider $file 2>&1  | grep exists` ]]; then
	    	#wget $miseqftp/$cramfile
		echo "   " $strain $file ok
	    else 
		echo "Could not find url " $file
	    fi
	fi
    done
done
