#!/usr/bin/env python

'''
Script for HORACE generator production
'''

import sys
import os
import shutil
from glob import glob
from optparse import OptionParser

def main():
    parser = OptionParser()
    parser.add_option('-c', '--commands', dest="commands", default= 'checkout,compile,pack', help='commands/stages to run')
    parser.add_option('-f', '--folderName', dest="dir", default='input', help='local folder name [input]')
    parser.add_option('-i', '--input', dest="input", default= 'input', help='input cfg file[input]')

    # args = parser.parse_args ()
    (args, opts) = parser.parse_args(sys.argv)

    if args.dir == 'input':
        args.dir = args.input.split('/')[-1]

    print(args)

    if 'checkout' in args.commands:
        checkout(args)

    if 'compile' in args.commands:
        compile(args)

    if 'calc' in args.commands:
        calc(args)

    if 'pack' in args.commands:
        pack(args)



def checkout(args):
    print('Checking out WINHAC')
    if not os.path.exists(args.dir):
        os.mkdir(args.dir)

    try:
        import git
    except ImportError:
        print('Error: gitpython is missing :( Please install it via\n\tpip install gitpython --user')
        sys.exit(1)

    try:
        # Unlock SSH key if running in background:
        # eval "$(ssh-agent -s)"
        # ssh-add ~/.ssh/id_rsa
        git.Git(args.dir).clone('ssh://git@gitlab.cern.ch:7999/mseidel/winhac.git')
    except git.exc.GitCommandError as err:
        print(err)

    print('Copying input file')
    cwd = os.getcwd()+'/'
    shutil.copy(cwd+args.input, cwd+args.dir+'/demo.input')



def compile(args):
    print('Compiling WINHAC')
    cwd = os.getcwd()+'/'
    os.chdir(cwd+args.dir+'/winhac')
    os.system('make')
    os.chdir(cwd+args.dir+'/winhac/demo')
    os.system('make')
    os.chdir(cwd)



def pack(args):
    print('Packing gridpack')
    cwd = os.getcwd()+'/'
    packdir = cwd+args.dir

    scram_arch = os.getenv('SCRAM_ARCH')
    cmssw_version = os.getenv('CMSSW_VERSION')
    shutil.copy(cwd+'/runcmsgrid_winhac.sh', packdir+'/runcmsgrid.sh')
    os.chdir(packdir)
    os.system('sed -i s/SCRAM_ARCH_VERSION_REPLACE/%s/g runcmsgrid.sh' % scram_arch)
    os.system('sed -i s/CMSSW_VERSION_REPLACE/%s/g runcmsgrid.sh' % cmssw_version)
    os.chdir(cwd)

    import tarfile
    tarname = scram_arch+'_'+cmssw_version+'_'+args.dir+'.tar.gz'
    print(tarname)
    with tarfile.open(tarname, "w:gz") as tar:
        tar.add(packdir, arcname='')



if __name__ == "__main__":
    main()