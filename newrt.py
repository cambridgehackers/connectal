#
# Yapps 2 Runtime, part of Yapps 2 - yet another python parser system
# Copyright 1999-2003 by Amit J. Patel <amitp@cs.stanford.edu>
#
# This version of the Yapps 2 Runtime can be distributed under the
# terms of the MIT open source license, either found in the LICENSE file
# included with the Yapps distribution
# <http://theory.stanford.edu/~amitp/yapps/> or at
# <http://www.opensource.org/licenses/mit-license.php>
#

import sys, re
import string
printtrace = False
lasttokenpos = 0

class SyntaxError(Exception):
    """When we run into an unexpected token, this is the exception to use"""
    def __init__(self, charpos=-1, msg="Bad Token", context=None):
        Exception.__init__(self)
        self.charpos = charpos
        self.msg = msg
        self.context = context
    def __str__(self):
        if self.charpos < 0: return 'SyntaxError'
        else: return 'SyntaxError@char%s(%s)' % (repr(self.charpos), self.msg)

class NoMoreTokens(Exception):
    """Another exception object, for when we run out of tokens"""
    pass

class Scanner:
    def __init__(self, patterns, ignore, input):
        self.thistoken = None
        self.input = input
        self.pos = 0
        self.whitespace = re.compile("[ \r\t\n]+")
        self.numbers = re.compile("[0-9]+[\\'dhb\\\\.]*[a-fA-F0-9_]*")
        self.anychar = re.compile("[a-zA-Z0-9_]*")
        self.alphatoken = re.compile("`*[a-zA-Z_][a-zA-Z0-9_]*#?")
        self.strings = re.compile(r'"([^\\"]+|\\.)*"')
        self.tokeninvalid = True
    def get_prev_char_pos(self, i=-1):
        global lasttokenpos
        return lasttokenpos
    def get_line_number(self):
        return 1 + self.input[:self.pos].count('\n')
    def get_column_number(self):
        return self.pos - (self.input[:self.pos].rfind('\n')+1)
    def jjtoken(self, restrict, advance_after_read):
        global printtrace
        p = self.tokeninvalid
        self.tokeninvalid = advance_after_read
        if not p:
            return self.thistoken
        best_match = 0
        best_pat = ''
        while True:
            if len(self.input[self.pos:]) > 2 and self.input[self.pos:self.pos+2] == '/*':
                commentindex = string.find(self.input, "*/", self.pos+2) 
                self.pos = commentindex + 2
            elif len(self.input[self.pos:]) > 2 and self.input[self.pos:self.pos+2] == '//':
                commentindex = string.find(self.input, "\n", self.pos+2) 
                self.pos = commentindex + 1
            else:
                m = self.whitespace.match(self.input, self.pos)
                if not m:
                    break
                self.pos = m.end()
        m = self.numbers.match(self.input, self.pos)
        if m:
            best_pat = 'NUM'
            best_match = len(m.group(0))
        #m = self.anychar.match(self.input, self.pos)
        m = self.alphatoken.match(self.input, self.pos)
        if m:
            best_pat = 'VAR'
            if m.group(0)[-1] == '#':
                best_pat = 'TYPEVAR'
            best_match = len(m.group(0))
        m = self.strings.match(self.input, self.pos)
        if m:
            best_pat = 'STR'
            best_match = len(m.group(0))
        first_pat = best_pat
        if self.pos == len(self.input):
            best_pat = 'ENDTOKEN'
        else:
            for p, regexp in self.patterns:
                if best_pat == '':
                    best_match = len(regexp)
                elif restrict and p not in restrict:
                    continue
                if self.input[self.pos:self.pos+best_match] == regexp:
                    best_pat = p
                    break
            if best_pat == '':
                msg = 'Bad Token'
                if restrict:
                    msg = 'Trying to find one of '+', '.join(restrict)
                raise SyntaxError(self.pos, msg)
        #self.tokens.append(self.pos)
        global lasttokenpos
        lasttokenpos = self.pos
        # Create a token with this data
        self.thistoken = (self.pos, self.pos+best_match, best_pat,
                 self.input[self.pos:self.pos+best_match], first_pat)
        self.pos = self.pos + best_match
        if printtrace:
            print "_scan:", self.thistoken
        return self.thistoken

class Parser:
    def __init__(self, scanner):
        self._scanner = scanner
        self._pos = 0
    def _peek(self, *types):
        tok = self._scanner.jjtoken(types, False)
        return tok[2]
    def _scan(self, type):
        tok = self._scanner.jjtoken([type], True)
        if tok[2] != type and tok[4] != type:
            raise SyntaxError(tok[0], 'Trying to find '+type)
        return tok[3]

class Context:
    def __init__(self, parent, scanner, tokenpos, rule, args=()):
        self.parent = parent
        self.scanner = scanner
        self.tokenpos = tokenpos
        self.rule = rule
        self.args = args
    def __str__(self):
        output = ''
        if self.parent: output = str(self.parent) + ' > '
        output += self.rule
        return output
    
def print_line_with_pointer(text, p):
    text = text[max(p-80, 0):p+80]
    p = p - max(p-80, 0)
    i = text[:p].rfind('\n')
    j = text[:p].rfind('\r')
    if i < 0 or (0 <= j < i): i = j
    if 0 <= i < p:
        p = p - i - 1
        text = text[i+1:]
    i = text.find('\n', p)
    j = text.find('\r', p)
    if i < 0 or (0 <= j < i): i = j
    if i >= 0:
        text = text[:i]
    while len(text) > 70 and p > 60:
        # Cut off 10 chars
        text = "..." + text[10:]
        p = p - 7
    print '> ',text
    print '> ',' '*p + '^'
    
def print_error(input, err, scanner):
    global lasttokenpos
    line_number = scanner.get_line_number()
    column_number = scanner.get_column_number()
    print '%d:%d: %s' % (line_number, column_number, err.msg)
    context = err.context
    if not context:
        print_line_with_pointer(input, err.charpos)
    while context:
        print 'while parsing %s%s:' % (context.rule, tuple(context.args))
        print_line_with_pointer(input, lasttokenpos)
        context = context.parent

def wrap_error_reporter(parser, rule):
    try:
        return getattr(parser, rule)()
    except SyntaxError, e:
        input = parser._scanner.input
        print_error(input, e, parser._scanner)
    except NoMoreTokens:
        print 'Could not complete parsing; stopped around here:'
        print parser._scanner
