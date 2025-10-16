# DY MiNNLO gridpack production

## General workflow

```
# check out 
git clone git@github.com:cms-sw/genproductions.git --no-checkout --depth 1
cd genproductions
git sparse-checkout set bin/Powheg bin/Horace bin/Winhac
git checkout
cd -

# set up CMSSW
cmssw-el8 --command-to-run cmsrel CMSSW_14_2_0
cd CMSSW_14_2_0/src

# link MiNNLO helper script
ln -s ../../genproductions/bin/Powheg/production/Run3/13p6TeV/DY_MiNNLO_NNPDF31_13p6TeV/minnloHelper_Run3.sh .

# link Powheg scripts
./minnloHelper_Run3.sh INIT

# fetch and compile Powheg source + patches
#./minnloHelper_Run3.sh EL8 COMPILE
# ATTENTION: no svn in el8 container -> login to lxplus8
./minnloHelper_Run3.sh COMPILE

# copy old grids if available
./minnloHelper_Run3.sh COPY_GRIDS

# submit integration grids to batch system
./minnloHelper_Run3.sh GRIDS

# check resulting cross section
./minnloHelper_Run3.sh XS

# create reweighting file
python3 make_rwl.py 1 306000 1

# pack muon gridpacks
./minnloHelper_Run3.sh PACK

# create electron and tau gridpacks
./minnloHelper_Run3.sh PACK_LEP
```
