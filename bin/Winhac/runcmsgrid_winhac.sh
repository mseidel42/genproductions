#!/bin/bash

fail_exit() { echo "$@"; exit 1; }

echo "   ______________________________________     "
echo "         Running WINHAC                       "
echo "   ______________________________________     "

nevt=${1}
echo "%MSG-WINHAC number of events requested = $nevt"

rnum=${2}
echo "%MSG-WINHAC random seed used for the run = $rnum"

ncpu=${3}
echo "%MSG-WINHAC number of cputs for the run = $ncpu"


LHEWORKDIR=`pwd`

use_gridpack_env=true
if [ -n "$4" ]
  then
  use_gridpack_env=$4
fi

if [ "$use_gridpack_env" = true ]
  then
    if [ -n "$5" ]
      then
        scram_arch_version=${5}
      else
        scram_arch_version=SCRAM_ARCH_VERSION_REPLACE
    fi
    echo "%MSG-MG5 SCRAM_ARCH version = $scram_arch_version"

    if [ -n "$6" ]
      then
        cmssw_version=${6}
      else
        cmssw_version=CMSSW_VERSION_REPLACE
    fi
    echo "%MSG-MG5 CMSSW version = $cmssw_version"
    export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
    source $VO_CMS_SW_DIR/cmsset_default.sh
    export SCRAM_ARCH=${scram_arch_version}
    scramv1 project CMSSW ${cmssw_version}
    cd ${cmssw_version}/src
    eval `scramv1 runtime -sh`
fi
cd $LHEWORKDIR
 
seed=$rnum

# Release to be used to define the environment and the compiler needed
export WORKDIR=`pwd`

# LHAPDF setup
LHAPDFCONFIG=`echo "$LHAPDF_DATA_PATH/../../bin/lhapdf-config"`
#if lhapdf6 external is available then above points to lhapdf5 and needs to be overridden
LHAPDF6TOOLFILE=$CMSSW_BASE/config/toolbox/$SCRAM_ARCH/tools/available/lhapdf6.xml
if [ -e $LHAPDF6TOOLFILE ]; then
  LHAPDFCONFIG=`cat $LHAPDF6TOOLFILE | grep "<environment name=\"LHAPDF6_BASE\"" | cut -d \" -f 4`/bin/lhapdf-config
fi
#make sure env variable for pdfsets points to the right place
export LHAPDF_DATA_PATH=`$LHAPDFCONFIG --datadir`

# extend lib path
export LD_LIBRARY_PATH=${PWD}/winhac/photos/lib:$LD_LIBRARY_PATH

# initialize the CMS environment 
card=${WORKDIR}/demo.input

if [[ ! -e ${card} ]]; then
 fail_exit "input file not found!"
fi

mkdir run
cp ${card} run/demo.input
cp winhac/demo/demo.exe run/demo.exe
cp winhac/winhac/data_DEFAULTS run/data_DEFAULTS
cd run

colseed=`printf "%15i" ${seed}`
colnevt=`printf "%15i" ${nevt}`
sed -i -e "s/2000############### NEvents/2000${colnevt} NEvents/g" demo.input
sed -i -e "s/2001############### RanSeed/2001${colseed} RanSeed/g" demo.input

cat demo.input
./demo.exe 2>&1 | tee log_winhac_${seed}.txt; test $? -eq 0 || fail_exit "winhac error: exit code not 0"

echo "<LesHouchesEvents version=\"3.0\">" >> cmsgrid_final.lhe
echo "<!--" >> cmsgrid_final.lhe
cat demo.input | sed "/^\*.*/d" >> cmsgrid_final.lhe
echo "-->" >> cmsgrid_final.lhe
cat demo.lhe.init >> cmsgrid_final.lhe
cat demo.lhe >> cmsgrid_final.lhe
echo "</LesHouchesEvents>" >> cmsgrid_final.lhe

xmllint --stream --noout cmsgrid_final.lhe > /dev/null 2>&1; test $? -eq 0 || fail_exit "xmllint integrity check failed on pwgevents.lhe"

grep ">        NaN</wgt>" cmsgrid_final.lhe; test $? -ne 0 || fail_exit "Weights equal to NaN found, there must be a problem in the reweighting"

ls -l cmsgrid_final.lhe
pwd

# exit 0

if [ -s stat ]; then
  XSECTION=`tac stat | grep "weighted cross section" | awk '{ print $(NF-3) }'`
  XSECUNC=`tac stat | grep "weighted cross section" | awk '{ print $(NF-1) }'`

  head=`cat   cmsgrid_final.lhe | grep -in "<init>" | sed "s@:@ @g" | awk '{print $1+1}' | tail -1`
  tail=`wc -l cmsgrid_final.lhe | awk -v tmp="$head" '{print $1-2-tmp}'`
  tail -${tail} cmsgrid_final.lhe                           >  cmsgrid_final.lhe_tail
  head -${head} cmsgrid_final.lhe                           >  cmsgrid_final.lhe_F
  proclin=`expr $head + 1`
  proc=`sed -n -e ${proclin}p  cmsgrid_final.lhe |  awk '{print $4}'`
  echo "  "$XSECTION"   "$XSECUNC"  1.00000000000E-00 "$proc >>  cmsgrid_final.lhe_F
  echo "</init>"                                           >>  cmsgrid_final.lhe_F
  cat cmsgrid_final.lhe_tail                               >>  cmsgrid_final.lhe_F
  mv cmsgrid_final.lhe_F cmsgrid_final.lhe
fi
#Replace the negative so pythia will work
sed "s@-1000021@ 1000022@g" cmsgrid_final.lhe           > cmsgrid_final.lhe_F1
sed "s@1000021@1000022@g"   cmsgrid_final.lhe_F1          > cmsgrid_final.lhe
cp cmsgrid_final.lhe ${WORKDIR}/.

echo "Output ready with cmsgrid_final.lhe at $WORKDIR"
echo "End of job on " `date`
exit 0;
