#!/bin/bash
set -o errexit
set -o pipefail

thisdir=`pwd`
utilsdir=$(readlink -f $(dirname $0))

##########################################
####### download some utilities ##########
##########################################
cd $utilsdir/src

if [ ! -f locpy/bin/activate ]; then
    echo; echo "  creating a local python environment..."

    cd $utilsdir/src
    #wpython=`which python`
    #isvenv=`python ../isvenv.py`
    #if [[ $isvenv == 1 ]]; then 
#	echo source $(dirname $wpython)/activate; 
#	#deactivate; 
#    fi
#    which $python
#    exit

    pyversion=`python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(major);'`
    minor=`python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(minor);'`


    if [[ $pyversion != 2 ]] && [[ $pyversion != 3 ]]; then
        pyv=`python -c 'import platform; print(platform.python_version())'`
        echo; echo " "Warning!! This script needs python version > 2.7 ! 
        echo "  "python version found is $pyv
        echo "  "Please change python version!!
        exit 1
    elif [[ $pyversion == 2 ]] && [[ $minor < 7 ]]; then
        pyv=`python -c 'import platform; print(platform.python_version())'`
        echo; echo " "Warning!! This script needs python version > 2.7 ! 
        echo "  "python version found is $pyv
        echo "  "Please change python version!!
        exit 1
    fi
    
    virtualenv $utilsdir/src/locpy  1> /dev/null

    source $utilsdir/src/locpy/bin/activate
    pip install --upgrade pip  &>   $utilsdir/src/locpy/install_output.txt
    pip install --upgrade distribute &>>   $utilsdir/src/locpy/install_output.txt
    pip install cython &>>   $utilsdir/src/locpy/install_output.txt
    pip install numpy &>>   $utilsdir/src/locpy/install_output.txt
    pip install pandas &>>   $utilsdir/src/locpy/install_output.txt
    pip install panda &>>   $utilsdir/src/locpy/install_output.txt
    pip install matplotlib &>>   $utilsdir/src/locpy/install_output.txt
    pip install seaborn &>>   $utilsdir/src/locpy/install_output.txt
    pip install pbcore &>>   $utilsdir/src/locpy/install_output.txt
    deactivate   
fi

source $utilsdir/src/locpy/bin/activate

if [ ! -d  $utilsdir/src/poretools ] ; then
    echo " Downloading and installing poretools..."
 
    # used to extract fastq from ont fast5
    cd $utilsdir/src/
    git clone https://github.com/arq5x/poretools.git &> /dev/null
    cd poretools/
    git reset --hard 4e04e25f22d03345af97e3d37bd8cf2bdf457fc9   1> /dev/null 
    python setup.py install  &> install_output.txt
fi

if [ ! -d  $utilsdir/src/pbh5tools ] ; then
    echo " Downloading and installing pbh5tools..."
    #used to extract fastq from pacbio hdf5 
    cd $utilsdir/src
    source $utilsdir/src/locpy/bin/activate
    pip install pysam &>>   $utilsdir/src/locpy/install_output.txt
    pip install h5py &>>   $utilsdir/src/locpy/install_output.txt
    pip install pbcore &>>   $utilsdir/src/locpy/install_output.txt
    git clone https://github.com/PacificBiosciences/pbh5tools.git &> /dev/null
    cd pbh5tools
    python setup.py install &> install_output.txt
fi

if [ ! -d  $utilsdir/src/fq2fa ] ; then
    echo " Downloading and installing fq2fa..."
    ## fastq 2 fasta
    cd $utilsdir/src
    git clone -b nogzstream https://github.com/fg6/fq2fa.git &> /dev/null
    cd fq2fa
    make &> install_output.txt
fi


if [ ! -d  $utilsdir/src/n50 ] ; then
    echo " Downloading and installing n50..."
    ## calculate fasta/fastq stats
    cd $utilsdir/src
    git clone -b nogzstream https://github.com/fg6/n50.git  &> /dev/null
    cd n50
    make &> install_output.txt
fi


	
if [ ! -d  $utilsdir/src/random_subreads ] ; then
    echo " Downloading and installing random_subreads..."
    ## subsample generator
    cd $utilsdir/src
    git clone -b YeastStrainsStudy https://github.com/fg6/random_subreads.git &> /dev/null
fi

if [ ! -d  $utilsdir/src/biobambam2-2.0.37-release-20160407134604-x86_64-etch-linux-gnu ] ; then
    echo " Downloading biobambam/bamtofastq "
    cd $utilsdir/src
    wget https://github.com/gt1/biobambam2/releases/download/2.0.37-release-20160407134604/biobambam2-2.0.37-release-20160407134604-x86_64-etch-linux-gnu.tar.gz &> /dev/null
     tar -xvzf biobambam2-2.0.37-release-20160407134604-x86_64-etch-linux-gnu.tar.gz > /dev/null
     rm biobambam2-2.0.37-release-20160407134604-x86_64-etch-linux-gnu.tar.gz
fi

if [ ! -f $utilsdir/src/pacbiosub/pacbiosub ]; then
	cd $utilsdir/src/pacbiosub/
	make
fi

