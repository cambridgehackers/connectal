#!/usr/bin/env python3

from __future__ import print_function

import os, sys
import glob
import argparse
import re

import bsvdependencies

from shutil import copyfile
from sets import Set

default_bluespecdir=None
if 'BLUESPECDIR' in os.environ:
    default_bluespecdir = os.environ['BLUESPECDIR']

argparser = argparse.ArgumentParser("Quick and dirty packager for BSV projects. Copy all the bsv dependencies required to compile the BSVFILE from all the directory in the BSVPATH, and paste them in the directory OUTPUT.")

argparser.add_argument('bsvfile', help='BSV files to process', nargs='*')
argparser.add_argument('-D', '--bsvdefine', default=[], help='BSV define for preprocessing', action='append')
argparser.add_argument('--bsvpath', default=[], help='directories to add to bsc search path', action='append')
argparser.add_argument('--bluespecdir', default=default_bluespecdir, help='BSC bluespec dir')
argparser.add_argument('-o', '--output', help='Output directory', default='./bsvFiles/')

def find(name, path):
    for root, dirs, files in os.walk(path):
        if name in files:
            return os.path.join(root, name)

def getBsvPackages(bluespecdir):
    """BLUESPECDIR is expected to be the path to the bluespec distribution.
    The function GETBSVPACKAGES returns a list of all
    the packages in the prelude library of this distribution.
    """
    pkgs = []
    for f in glob.glob('%s/Prelude/*.bo' % bluespecdir) + glob.glob('%s/Libraries/*.bo' % bluespecdir):
        pkgs.append(os.path.splitext(os.path.basename(f))[0])
    return pkgs



def expandPackages(bsvfile):
    newpackage, bsvpat = bsvdependencies.bsvDependencies(bsvfile,
                                                         False,
                                                         default_bluespecdir,
                                                         options.bsvpath,
                                                         [])
    setPkg = Set(bsvfile)
    for _,pkgs,_,_ in newpackage:
        for pkg in pkgs:
            for pth in options.bsvpath:
                pkgFile = find("%s.bsv" % pkg, pth)
                if pkgFile != None:
                    subSet = expandPackages([pkgFile])
                    setPkg = subSet | setPkg
    for _,_,includes,_ in newpackage:
        setPkg = Set(includes) | setPkg
    return setPkg

if __name__=='__main__':
    options = argparser.parse_args()
    pkgPrelude = getBsvPackages(options.bluespecdir)
    filesProject = expandPackages(options.bsvfile)
    if not os.path.exists(options.output):
        os.makedirs(options.output)
    print(filesProject)
    for file in filesProject:
        copyfile(file, os.path.join(options.output,os.path.basename(file)))



