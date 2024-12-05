#!/bin/bash
trap "exit" INT

WHAT=$1;
PARAM=$2;
if [ "$#" -lt 1 ]; then
    echo "wcHelper.sh <OPTION>";
    exit 1;
fi

SCRAM_ARCH=slc7_amd64_gcc10
CMSSW=CMSSW_12_3_1
NJOBS=50
SVN=4078
SUFFIX=powheg-svn${SVN}-j${NJOBS}
MPROC=Wc

PROCS=(WplusCharmToMuNu-13TeV-minnlolike WminusCharmToMuNu-13TeV-minnlolike)
PROCS=(WplusCharmToMuNu-13TeV-minnlolike-fold222 WminusCharmToMuNu-13TeV-minnlolike-fold222)

case $WHAT in

    INIT )
        ln -s ../../genproductions/bin/Powheg/*.py .
        ln -s ../../genproductions/bin/Powheg/*.sh .
        ln -s ../../genproductions/bin/Powheg/patches .
        ln -s ../../genproductions/bin/Powheg/production/pre2017/13TeV/Wc_NNPDF31_13TeV .
    ;;
    
    PRINT )
        for PROC in ${PROCS[@]}
        do
            echo ${PROC}
            echo ${MPROC}
        done
    ;;
    
    COMPILE )
        cmssw-cc7 -- ./$0 COMPILE_DO
    ;;
    
    COMPILE_DO )
        eval `scramv1 runtime -sh`
        for PROC in ${PROCS[@]}
        do
            python ./run_pwg_condor.py -p 0 -i Wc_NNPDF31_13TeV/${PROC}-powheg.input -m ${MPROC} -f ${PROC}-${SUFFIX} -d 1 --svn ${SVN}
        done
    ;;

    GRIDS )
        for PROC in ${PROCS[@]}
        do
            k5reauth -R -- python3 ./run_pwg_parallel_condor.py -p 123 -i Wc_NNPDF31_13TeV/${PROC}-powheg.input -m ${MPROC} -f ${PROC}-${SUFFIX} -q 1:longlunch,2:workday,3:longlunch --step3pilot -x 3 -j ${NJOBS}
        done
    ;;
    
    XS )
        for PROC in ${PROCS[@]}
        do
            echo ${PROC}
            cat ${PROC}-${SUFFIX}/pwg-0001-st3-stat.dat | grep total
        done
    ;;
    
    PACK )
        eval `scramv1 runtime -sh`
        for PROC in ${PROCS[@]}
        do
            python3 ./run_pwg_condor.py -p 9 -m ${MPROC} -f ${PROC}-${SUFFIX} 
        done
        ./wcHelper.sh PACK_REDUCED
        ./wcHelper.sh PACK_NORWL
    ;;
    
    TEST )
        mkdir TEST; cd TEST
        eval `scramv1 runtime -sh`
        for PROC in ${PROCS[@]}
        do
            DIR=${PROC}-${SUFFIX}
            rm -r ${DIR}; mkdir ${DIR}; cd ${DIR}
            tar -xzf ../../${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}.tgz
            /usr/bin/time -v ./runcmsgrid.sh 20 1 1 &
            cd ..
        done
    ;;
    
    LONGTEST )
        mkdir TEST; cd TEST
        eval `scramv1 runtime -sh`
        for PROC in ${PROCS[@]}
        do
            DIR=${PROC}-${SUFFIX}
            rm -r ${DIR}; mkdir ${DIR}; cd ${DIR}
            tar -xzf ../../${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}.tgz
            /usr/bin/time -v ./runcmsgrid.sh 800 1 1 &
            cd ..
        done
    ;;
    
    PACK_REDUCED )
        mkdir PACK_REDUCED; cd PACK_REDUCED
        for PROC in ${PROCS[@]}
        do
            DIR=${PROC}-${SUFFIX}
            rm -r ${DIR}; mkdir ${DIR}; cd ${DIR}
            tar -xzf ../../${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}.tgz
            cp ../../pwg-rwl-reduced.dat pwg-rwl.dat
            tar zcf ../${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}-reducedrwl.tgz *
            cd ..
        done
    ;;
    
    TEST_REDUCED )
        cd PACK_REDUCED; mkdir TEST; cd TEST
        eval `scramv1 runtime -sh`
        for PROC in ${PROCS[@]}
        do
            DIR=${PROC}-${SUFFIX}
            rm -r ${DIR}; mkdir ${DIR}; cd ${DIR}
            tar -xzf ../../${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}-reducedrwl.tgz
            ./runcmsgrid.sh 10 1 1 &
            cd ..
        done
    ;;

    COPY )
        for PROC in ${PROCS[@]}
        do
            echo ${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}.tgz
            echo ${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}-reducedrwl.tgz
            echo ${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}-norwl.tgz
            cp -p -v ${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}.tgz /afs/cern.ch/work/m/mseidel/public/MiNNLO-gridpacks/
            cp -p -v PACK_REDUCED/${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}-reducedrwl.tgz /afs/cern.ch/work/m/mseidel/public/MiNNLO-gridpacks/
            cp -p -v PACK_REDUCED/${MPROC}_${SCRAM_ARCH}_${CMSSW}_${PROC}-${SUFFIX}-norwl.tgz /afs/cern.ch/work/m/mseidel/public/MiNNLO-gridpacks/
        done
    ;;

    LS )
        for PROC in ${PROCS[@]}
        do
            echo ${PROC}-${SUFFIX}
            ls ${PROC}-${SUFFIX}
        done
    ;;

    COPYTEST )
        for PROC in ${PROCS[@]}
        do
            echo ${PROC}-${SUFFIX}
            cp -r ${PROC}-${SUFFIX} ${PROC}-${SUFFIX}-test
        done
    ;;

esac
