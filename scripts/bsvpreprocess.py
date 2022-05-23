#!/usr/bin/env python3
# Copyright (c) 2014-2015 Quanta Research Cambridge, Inc
# Copyright (c) 2015 Connectal Project
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

from __future__ import print_function

import os, sys, re, string
import argparse

argparser = argparse.ArgumentParser("Preprocess BSV files.")
argparser.add_argument('bsvfile', help='BSV files to parse', nargs='+')
argparser.add_argument('-D', '--bsvdefine', default=[], help='BSV define', action='append')
argparser.add_argument('-I', '--include', help='Specify import/include directories', default=[], action='append')
argparser.add_argument('--bsvpath', default=[], help='directories to add to bsc search path', action='append')
argparser.add_argument('-v', '--verbose', help='Display verbose information messages', action='store_true')

def preprocess(sourcefilename, source, defs, bsvpath):
    # convert defs to a dict
    # defs could be a list of symbol or symbol=value
    if type(defs) == list:
        d = {}
        for sym in defs:
            if '=' in sym:
                (s, val) = sym.split('=')
                d[s] = val
            else:
                d[sym] = ''
        defs = d
    stack = [(True,True)]
    def nexttok(s):
        k = re.search('[^A-Za-z0-9~_]', s)
        if k:
            sym = s[:k.start()]
            s = s[k.end():]
            return (sym, s)
        else:
            return (s, '')
    lines = source.splitlines()
    outlines = []
    noncomment = ''
    # true if a previous line started a block comment and didn't finish it
    multilinecomment = False
    while lines:
        line = lines[0]
        lines = lines[1:]
        cond  = stack[-1][0]
        valid = stack[-1][1]

        # FIXME
        if (line.endswith('\\')):
            noncomment += line[:-1]
            continue

        remaining = line
        comment = ''
        noncomment = ''

        if multilinecomment:
            commentEnd = remaining.find('*/')
            if commentEnd >= 0:
                comment += remaining[0:commentEnd+2]
                remaining = remaining[commentEnd+2:]
                multilinecomment = False
            else:
                comment += remaining
                remaining = ''

        while len(remaining):
            commentStart = remaining.find('/')
            if commentStart >= 0:
                noncomment += remaining[0:commentStart]
                restofline = remaining[commentStart:]
                if restofline.startswith('/*'):
                    commentEnd = restofline.find('*/')
                    if commentEnd >= 0:
                        comment += restofline[0:commentEnd+2]
                        remaining = restofline[commentEnd+2:]
                    else:
                        comment += restofline
                        remaining = ''
                        multilinecomment = True
                elif restofline.startswith('//'):
                    comment += remaining
                    remaining = ''
                else:
                    noncomment += restofline[0]
                    remaining = remaining[1:]
            else:
                noncomment += remaining
                remaining = ''
        i = noncomment.find('`')
        if i < 0:
            if valid:
                outlines.append(line)
            else:
                outlines.append('//SKIPPED %s' % line)
            continue

        s = noncomment[i+1:]
        (tok, s) = nexttok(s)
        if tok == 'ifdef':
            (sym, s) = nexttok(s)
            new_cond = sym in defs
            new_valid = new_cond and valid
            #sys.stderr.write('ifdef %s new_cond=%d new_valid=%d cond=%d valid=%d\n' % (sym, new_cond, new_valid, cond, valid))
            stack.append((new_cond,new_valid))
        elif tok == 'ifndef':
            (sym, s) = nexttok(s)
            new_cond = not sym in defs
            new_valid = valid and new_cond
            #sys.stderr.write('ifndef %s new_cond=%d new_valid=%d cond=%d valid=%d\n' % (sym, new_cond, new_valid, cond, valid))
            stack.append((new_cond,new_valid))
        elif tok == 'else':
            stack.pop()
            try:
                valid = stack[-1][1]
            except:
                sys.stderr.write('Failed to preprocess %s\n' % sourcefilename)
                sys.exit(1)
            new_cond = not cond
            new_valid = new_cond and valid
            #sys.stderr.write('else %s new_cond=%d new_valid=%d cond=%d valid=%d\n' % (sym, new_cond, new_valid, cond, valid))
            stack.append((new_cond,new_valid))
        elif tok == 'elsif':
            stack.pop()
            valid = stack[-1][1]
            (sym, s) = nexttok(s)
            new_cond = sym in defs
            new_valid = new_cond and valid
            stack.append((new_cond,new_valid))
        elif tok == 'endif':
            stack.pop()
            try:
                valid = stack[-1][1]
            except:
                sys.stderr.write('Failed to preprocess %s\n' % sourcefilename)
                sys.exit(1)
        elif tok == 'define':
            (sym, s) = nexttok(s)
            if s:
                defs[sym] = s
            else:
                defs[sym] = ''
        elif tok == 'include':
            m = re.search('"?([-_A-Za-z0-9.]+)"?', s)
            if not m:
                sys.stderr.write('syntax.preprocess %s: could not find file in line {%s}\n' % (sourcefilename, s))
                break
            filename = m.group(1)
            inc = ''
            for d in bsvpath:
                fn = os.path.join(d, filename)
                if os.path.exists(fn):
                    inc = open(fn).read()
                    break
            if not inc:
                sys.stderr.write('syntax.preprocess %s: did not find included file %s in path\n' % (sourcefilename, filename))
            outlines.append('//`include "%s"' % filename)
            lines = inc.splitlines() + lines
            continue
        elif tok:
            while '`' in noncomment:
                ## must be an undefined variable
                i = noncomment.find('`')
                (tok, s) = nexttok(noncomment[i+1:])
                #sys.stderr.write('syntax.preprocess %s: preprocessor variable `%s\n' % (sourcefilename, tok))
                if tok in defs:
                    val = defs[tok]
                else:
                    val = ''
                #sys.stderr.write('sym=%s val=%s\n' % (tok, val))
                noncomment = noncomment.replace('`%s' % tok, val)
            prefix='//SKIPPED ' if not valid else ''
            outlines.append('//PREPROCESSED: %s' % line)
            outlines.append(prefix + noncomment + comment)
            continue
        else:
            sys.stderr.write('syntax.preprocess %s: unhandled preprocessor token %s\n' % (sourcefilename, tok))
            sys.stderr.write('line: %s\n' % line)
            assert(tok in ['ifdef', 'ifndef', 'else', 'endif', 'define', ''])
        outlines.append('//PREPROCESSED: %s' % line)

    return '%s\n' % '\n'.join(outlines)

if __name__=='__main__':
    options = argparser.parse_args()
    for bsvfile in options.bsvfile:
        preprocessed = preprocess(bsvfile, open(bsvfile).read(), options.bsvdefine, options.include + options.bsvpath)
        print(preprocessed)

