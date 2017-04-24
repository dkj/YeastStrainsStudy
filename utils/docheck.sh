#!/bin/bash
set -o errexit
set -o pipefail

thisdir=`pwd`
utilsdir=$(readlink -f $(dirname $0))
singlestrain=$1

if [ $singlestrain != "all" ]; then
    strains=( $singlestrain )
else
    strains=( s288c sk1 cbs n44 )
fi
platforms=( ont pacbio miseq )


# Number of reads the files are suppose to have:
#pass2D, all2D
ont_s288c=( 382637184 737451072 )
ont_sk1=( 51002440 )
ont_cbs=( 109308008 )
ont_n44=( 129796408 )
#whole, 31X_ont_emu
pacbio_s288c=( 1462662016  375115552)
pacbio_sk1=( 3018814976 )
pacbio_cbs=( 1639253632 )
pacbio_n44=( 1793698048 )
#reads_1, reads_2
miseq_s288c=( 497770048 497770048 )
miseq_sk1=( 492408000 492408000 )
miseq_cbs=( 477162912 477162912 )
miseq_n44=( 504046656 504046656 )

#file name details:
ontn=( pass2D all2D )
pacbion=( pacbio pacbio_ontemu_31X )

if [ ! -f  $utilsdir/src/n50/n50 ] ; then
    echo Some utilities are missing, please run ./launchme.sh install
    exit
fi



errors=0
missing=0
for platform in "${platforms[@]}"; do  

    echo; echo " *****************"; echo  "   " $platform files:; echo " *****************"; 
    folder=fastqs/$platform

    for strain in "${strains[@]}"; do   
        echo  "   strain=" $strain

	if [ $platform != "miseq" ]; then name=${platform}n[0]; fi
	file=$folder/$strain/$strain\_"${!name}".fastq
	if [ $platform == "miseq" ]; then 
	    file=$folder/$strain\_1.fastq; 
	    file2=$folder/$strain\_2.fastq; 
	fi
	
	if [ -f $file ]; then 
	    check=$platform\_${strain}
	    thischeck=`$utilsdir/src/n50/n50 $file | awk '{print $2}'`

	    if [ "${!check}" = "$thischeck" ]; then echo "    " $thistrain $file  OK;
	    else 
		echo; echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
		echo "     !!!! " $thistrain $file  NOT OK ;  
		echo "     !!!!    Something went wrong during the fastq preparation "
		echo "     !!!!    Please relaunch: $ ./launchme.sh download "  $strain
		echo "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " 
		rm -f $file
		errors=$(($errors+1))
	    fi
	else
            echo; echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
	    echo "     Cannot find fastq file for" $strain: $file ;
	    echo "          Download it with: "  $ ./launchme.sh download $strain 
	    missing=$(($missing+1))
	fi

	if [ $platform == "miseq" ]; then 
	    if [ -f $file ]; then 
		check=$platform\_${strain}[1]
		thischeck=`$utilsdir/src/n50/n50 $file2 | awk '{print $2}'`
		
		if [ "${!check}" = "$thischeck" ]; then echo "    " $thistrain $file2  OK;
		else 
		    echo;echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
		    echo "     !!!! " $thistrain $file2  NOT OK ;  
		    echo "     !!!!    Something went wrong during the fastq preparation "
		    echo "     !!!!    Please relaunch: $ ./launchme.sh download "  $strain		 
		    echo "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " 
	            rm -f $file2

                    errors=$(($errors+1))
		fi
	    else
                echo; echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
		echo "     Cannot find fastq file for" $strain\: $file2 ;
		echo "          Download it with: "  $ ./launchme.sh download $strain
                missing=$(($missing+1))
	    fi
	fi
	
	if [ $strain == "s288c" ] && [ $platform != "miseq" ]; then
	    name=${platform}n[1]
	    file=$folder/$strain/$strain\_"${!name}".fastq
	   
	    if [ -f $file ]; then 
		check=$platform\_${strain}[1]
		thischeck=`$utilsdir/src/n50/n50 $file | awk '{print $2}'`
		if [ "${!check}" = "$thischeck" ]; then echo "    " $thistrain $file  OK;
		else 
		    echo; echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
		    echo "     !!!! " $thistrain $file  NOT OK ;  
		    echo "     !!!!    Something went wrong during the fastq preparation "
		    echo "     !!!!    Please relaunch: $ ./launchme.sh download "  $strain
		    echo "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " 
                    rm -f $file
                    errors=$(($errors+1))
		fi
	    else
                echo; echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
		echo "     Cannot find fastq file for" $strain\: $file ;
		echo "          Download it with: "  $ ./launchme.sh download $strain 
                missing=$(($missing+1))
	    fi
	fi
    done
done


echo;echo 

if [[ $missing != 0 ]] || [[ $errors != 0 ]]; then
        echo "     !!!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!!! " 
        echo "      Some files failed to download or un-compress properly "
        echo "     Please check the warnings above and follow instructions "
	echo "       If the instructions do not help, try a deep check:"
	echo "            $ ./launchme.sh deepcheck $strain "
        echo "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " 
	echo
else
        echo; echo " All your fastq files appear to be fine"
	echo "   Please go ahead and clean up you folders with ./launchme.sh clean all"
	echo "     ...but remember that if you clean up your fast5 files will be deleted "
        echo "          and you will not be able to run nanopolish until you have redownloaded them"
	echo "   If you want to run Nanopolish, do instead a ./launchme.sh nanoclean all"
	echo "      this will delete all intermediate files except the fastqs and the fast5 files needed by Nanopolish"
	echo
fi







