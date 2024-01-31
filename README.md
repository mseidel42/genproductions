# Line by line instructions for the POWHEG tutorial

Choose a recent CMSSW release. While POWHEG is not CMS code, this is useful to define a precise set of
C++/fortran compilers, additional libraries etc. of which memory will be kept when the POWHEG workflow is 
submitted to official production. NOTICE THE DIFFERENCE WITH MADGRAPH CMS SETUP, where the CMSSW release is chosen
only later, when defining a specific event generation.

```
ssh lxplus7.cern.ch
setenv SCRAM_ARCH slc7_amd64_gcc12  (in bash: export SCRAM_ARCH=slc7_amd64_gcc12)
scram p -n pwgtutorial_13_3_0 CMSSW_13_3_0
cd pwgtutorial_13_3_0/src
eval `scram runtime -csh`  (in bash: -sh)
```

Download the "genproductions" package, which is a generic container for CMS MC-generator scripts and configuration cards. 

```
git clone --single-branch --depth=1 -b tutorial-24-02-19 git@github.com:covarell/genproductions.git
cd genproductions/bin/Powheg
```

Run the "manyseeds" job (generates Higgs in gluon fusion, at the NLO QCD and with heavy-quark masses properly
taken into account)

```
nohup python ./run_pwg_parallel_condor.py -i tutorial_ggH_powheg.input -m gg_H_quark-mass-effects -x 3 -f my_tutorial_ggHfull -q espresso -q2 longlunch -j 10 > check_manyseeds.log &
``` 

"nohup" would allow you to close the shell window where the job is running. But in this case do not close it while listening to the presentation, in order to check later what is happening.

Run a simple POWHEG job (generates ttbar production at the NLO QCD)

```
python ./run_pwg_condor.py -i tutorial_ttbar_powheg.input -m hvq -p f -f my_tutorial_ttbar 
```

Generate 3000 ttbar LH events.

```
mkdir test_ttbar
cd test_ttbar
tar -xzvf ../hvq_slc7_amd64_gcc12_CMSSW_13_3_0_my_tutorial_ttbar.tgz
(if the job failed: tar -xzvf /afs/cern.ch/user/c/covarell/public/tutorial-24-02-19/hvq_slc7_amd64_gcc12_CMSSW_13_3_0_my_tutorial_ttbar.tgz)
./runcmsgrid.sh 5000 12 1
```

Now move to the analysis part (LHE or NanoGEN).