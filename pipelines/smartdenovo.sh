#!/bin/bash
set -o errexit
set -o pipefail



myexe=$1
strain=$2
platform=$3
cov=$4


thisdir=`pwd`
srcdir=$thisdir/../utils/src

assembler=smartdenovo
assembler_info=`echo $assembler version 1.1`
wdir=results/smartdenovo
exetype='SMARTDENOVO_vs1.0_LOCATION/smartdenovo.pl'

outdir=$strain\_$platform
outfile=$assembler\_$strain\_$platform.output



if [ $# -lt 3 ]  || [ $1 == '-h' ]; then
	echo; echo "  Usage:" $(basename $0) \<$assembler\> \<strain\> \<platform\>  \<cov\>
	echo "  " $assembler: location of $assembler_info script:  $exetype
	echo "   strain:  s288c, sk1, n44 or cbs (please notice that because of low depth only s288c has been assembled for ONT data)"
	echo "   platform: ont or pacbio "
	echo "   cov: only for pacbio s288c: choose coverage sample '31X' or 'allX' "

        exit 1
fi


if [ $platform == 'ont' ]; then
	reads=$thisdir/../fastqs/ont/$strain/$strain\_pass2D.fastq
	if [ ! -z ${cov-x} ] && [ $cov == 'allX' ]; then
        	echo 'allX option valid for pacbio s288c only!'
        	exit 1
        fi              
	
	if [ $strain != 's288c' ]; then
		echo; echo '  Warning!! Probably read depth not enough for denovo assembly with' $assembler for $strain ' ONT data'
	fi

else

	if [ $strain == 's288c' ] && [ -z ${cov-x} ]; then
		echo; echo "  For pacbio s288c you should choose if running the sample with all data (allX) or the subsample with '31X' coverage"; echo
	       	echo; echo "  Usage:" $(basename $0) \<$assembler\> \<strain\> \<platform\>  \<cov\>
	        echo "  " $assembler: location of $assembler_info script:  $exetype
        	echo "   strain:  s288c, sk1, n44 or cbs (please notice that because of low depth only s288c has been assembled for ONT data)"
       		echo "   platform: ont or pacbio "
        	echo "   cov: only for pacbio s288c: choose coverage sample '31X' or 'allX' " 
		exit 1
	fi

        if  [ ! -z ${cov-x} ]; then
                if [ $cov == '31X' ] && [ $strain != 's288c' ]; then 
                        echo '31X option valid for pacbio s288c only!'
                        exit 1
                elif [ $cov == '31X' ] && [ $strain == 's288c' ]; then	
	        	reads=$thisdir/../fastqs/pacbio/$strain/s288c_pacbio_ontemu_31X.fastq
			outdir=$outdir\_31X_ONTemu			
		else
                	reads=$thisdir/../fastqs/pacbio/$strain/$strain\_pacbio.fastq               	
		fi	
	else	
		if [ $strain == 's288c' ]; then
                	echo; echo "For pacbio s288c you should choose if running the sample with all data (allX) or the subsample with '31X' coverage"; echo
                	echo; echo "  Usage:" $(basename $0) \<$assembler\> \<strain\> \<platform\>  \<cov\>
                	echo "   cov: only for pacbio s288c: choose coverage sample '31X' or 'allX' "
                	exit 1
        	else
                	reads=$thisdir/../fastqs/pacbio/$strain/$strain\_pacbio.fastq                        
		fi

	fi

fi

if [ -z ${myexe-x} ]; then 
	echo ; echo "  Usage:"  $0 $exetype; echo
elif [ ! -f ${myexe} ] ; then
	echo; echo "  Usage:"  $0 $exetype 
	echo "  Could not find " $exetype= ${myexe}; echo
	exit 1
fi



if [ -f $reads ]; then check=`head -1 $reads`; fi
if [ ! -f $reads ]; then
        echo; echo "  Could not find read-file "  ${reads}; echo
elif [ -z "${check}" ]; then
        echo; echo "  The read-file "  ${reads} is empty!; echo
else
    mkdir -p $wdir/$outdir
    cd $wdir/$outdir
    readsfa=$(basename $reads .fastq).fasta
    if [ ! -f $readsfa ]; then
        echo "Smartdenovo needs a fasta file...creating it now.."
        $srcdir/fq2fa/fq2fa $reads
    fi

    command1=`echo $myexe -c 1 $readsfa `
    command2=`echo make -f yeast.mak`

    echo; echo  "  Running:" $assembler on  $(basename $reads) in folder $wdir/$outdir ; echo 
    echo  "  Assembly will be in " $wdir/$outdir/wtasm.dmo.cns
    $command1  > yeast.mak
    $command2  &> $outfile
fi

