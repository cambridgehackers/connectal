##
## Copyright (c) 2013 Quanta Research Cambridge, Inc.

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
from __future__ import print_function

import os
import filecmp
import string

def createDirAndOpen(f, m):
    (d, name) = os.path.split(f)
    if not os.path.exists(d):
        os.makedirs(d)
    return open(f, m)

def replaceIfChanged(name, replacement):
    if not os.path.isfile(name):
        print('os.rename(%s, %s)' % (replacement, name))
        os.rename(replacement, name)
        return
    if filecmp.cmp(name, replacement):
        print('os.unlink(%s)' % replacement)
        os.unlink(replacement)
    else:
        print('os.rename(%s, %s)' % (replacement, name))
        os.rename(replacement, name)

## for camelcase preservation
def capitalize(s):
    return '%s%s' % (s[0].upper(), s[1:])
def decapitalize(s):
    return '%s%s' % (s[0].lower(), s[1:])

## things I thought would have been in functools (mdk)
intersperse = lambda e,l: sum([[x, e] for x in l],[])[:-1]
def foldl(f, x, l):
    if len(l) == 0:
        return x
    return foldl(f, f(x, l[0]), l[1:])

## Given a string V, V=, or V=VAL returns (V,VAL)
def splitBinding(s):
    if '=' in s:
        return s.split('=')
    else:
        return (s,'')

def escapequotes(s):
    s = s.replace('\"', '\\\"')
    return s
