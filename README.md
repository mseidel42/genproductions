B# Line by line instructions for the POWHEG tutorial

BEFORE LISTENING TO PRESENTATIONS

Choose a recent CMSSW release. While POWHEG is not CMS code, this is useful to define a precise set of
C++/fortran compilers, additional libraries etc. of which memory will be kept when the POWHEG workflow is 
submitted to official production. NOTICE THE DIFFERENCE WITH MADGRAPH CMS SETUP, where the CMSSW release is chosen
only later, when defining a specific event generation.

```
ssh lxplus8.cern.ch
scram p -n pwgtutorial_13_3_0 CMSSW_13_3_0
cd pwgtutorial_13_3_0/src
eval `scram runtime -csh`  (in bash: -sh)
```

Download the "genproductions" package, which is a generic container for CMS MC-generator scripts and configuration cards. 

```
git clone --single-branch --depth=1 --no-checkout -b tutorial-24-02-19 git@github.com:covarell/genproductions.git
cd genproductions
git sparse-checkout set .github bin/Powheg
git checkout
cd bin/Powheg
```

Run the "manyseeds" job (generates Higgs in gluon fusion, at the NLO QCD and with heavy-quark masses properly
taken into account)

```
python3 ./run_pwg_parallel_condor.py -i tutorial_ggH_powheg.input -m gg_H_quark-mass-effects -x 3 -f my_tutorial_ggHfull -q 1:espresso,2:longlunch,3:longlunch -j 10 
``` 

DAG job handling would allow you to close the shell window now. But in this case do not close it while listening to the presentations, in order to check later what is happening.

AFTER LISTENING TO THE PRESENTATIONS

Check if the morning job has finished (see slides), if so, create the POWHEG-pack:

```
python3 ./run_pwg_condor.py -p 9 -i tutorial_ggH_powheg.input -m gg_H_quark-mass-effects -f my_tutorial_ggHfull 
``` 

Now run a second, simpler POWHEG job (generates ttbar production at the NLO QCD)

```
python3 ./run_pwg_condor.py -i tutorial_ttbar_powheg.input -m hvq -p f -f my_tutorial_ttbar 
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