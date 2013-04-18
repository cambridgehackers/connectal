#! /usr/bin/env python
# Copyright (c) 2013 Quanta Research Cambridge, Inc
# Original author John Ankcorn
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

from __future__ import print_function
import re

curtoken_index = 0
def expression_getnext():
    global curtoken, curtoken_index, litem
    OINF = { '+': [1, lambda x, y: x + y], '-': [1, lambda x, y: x - y],
             '*': [2, lambda x, y: x * y], '/': [2, lambda x, y: x / y],
             '==': [1, lambda x, y: 'TRUE' if x == y else 'FALSE'], '!=': [1, lambda x, y: 'TRUE' if x != y else 'FALSE'],
             '&&': [1, lambda x, y: 'TRUE' if x and y else 'FALSE'], '||': [1, lambda x, y: 'TRUE' if x or y else 'FALSE'],
             '>': [1, lambda x, y: 'TRUE' if x > y else 'FALSE'] }
    if curtoken_index >= len(litem):
        curtoken = ['ENDOFFILE', 666]
        return
    number, vname, operator = litem[curtoken_index]
    curtoken_index = curtoken_index + 1
    if number:
        curtoken = ['NUMBER', number]
    elif vname:
        curtoken = ['VARIABLE', vname]
    elif operator == '(':
        curtoken = ['LEFTPAREN', None]
    elif operator == ')':
        curtoken = ['RIGHTPAREN', None]
    else:
        curtoken = ['BINOP', OINF[operator]]
    #print('cur', curtoken)

def compute_expr(outer_precedence, tmaster, lookup_param):
    global curtoken
    expression_getnext()
    if curtoken[0] == 'LEFTPAREN':
        atom_lhs = compute_expr(1, tmaster, lookup_param)
        assert curtoken[0] == 'RIGHTPAREN'
    elif curtoken[0] == 'NUMBER':
        atom_lhs = int(curtoken[1])
    elif curtoken[0] == 'VARIABLE':
        atom_lhs = 0
        item = lookup_param(tmaster, curtoken[1])
        if item:
            atom_lhs = int(item['VALUE'])
        #print('lookupvar', curtoken[1], atom_lhs)
    else:
        raise RuntimeError('Syntax error')
    expression_getnext()
    while curtoken[0] == 'BINOP' and curtoken[1][0] >= outer_precedence:
        atom_lhs = curtoken[1][1](atom_lhs, compute_expr(curtoken[1][0] + 1, tmaster, lookup_param))
    return atom_lhs

def eval_expression(item, tmaster, lookup_param):
    global curtoken_index, litem
    curtoken_index = 0
    litem = re.compile("\s*(?:(\d+)|([a-zA-Z_][a-zA-Z_0-9]*)|(.[=&|]*))").findall(item)
    evalue = str(compute_expr(1, tmaster, lookup_param))
    return evalue
