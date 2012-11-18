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
        self.tokens = [] # [(begin char pos, end char pos, token name, matched text), ...]
        self.restrictions = []
        self.input = input
        self.pos = 0
        self.first_line_number = 1
        self.whitespace = re.compile("[ \r\t\n]+")
        self.numbers = re.compile("[0-9]+[\\'dhb\\\\.]*[a-fA-F0-9_]*")
        self.anychar = re.compile("[a-zA-Z0-9_]*")
        self.alphatoken = re.compile("`*[a-zA-Z_][a-zA-Z0-9_]*")
        self.strings = re.compile(r'"([^\\"]+|\\.)*"')
    def get_token_pos(self):
        return len(self.tokens)
    def get_char_pos(self):
        return self.pos
    def get_prev_char_pos(self, i=None):
        if self.pos == 0: return 0
        if i is None: i = -1
        return self.tokens[i][0]
    def get_line_number(self):
        return self.first_line_number + self.get_input_scanned().count('\n')
    def get_column_number(self):
        s = self.get_input_scanned()
        i = s.rfind('\n') # may be -1, but that's okay in this case
        return len(s) - (i+1)
    def get_input_scanned(self):
        return self.input[:self.pos]
    def get_input_unscanned(self):
        return self.input[self.pos:]
    def __repr__(self):
        output = ''
        for t in self.tokens[-10:]:
            output = '%s\n  (@%s)  %s  =  %s' % (output,t[0],t[2],repr(t[3]))
        return output
    def token(self, i, restrict=None):
        if i == len(self.tokens):
            self.jjscan(restrict)
        if i < len(self.tokens):
            if restrict and self.restrictions[i]:
                for r in restrict:
                    if r not in self.restrictions[i]:
                        raise NotImplementedError("Unimplemented: restriction set changed")
            return self.tokens[i]
        raise NoMoreTokens()
    def jjscan(self, restrict):
        best_match = -1
        best_pat = '(error)'
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
            best_match = len(m.group(0))
        m = self.strings.match(self.input, self.pos)
        if m:
            best_pat = 'STR'
            best_match = len(m.group(0))
        for p, regexp in self.patterns:
            if restrict and p not in restrict:
                continue
            if self.pos == len(self.input):
                best_pat = p
                best_match = 0
                break
            if self.input[self.pos:self.pos+len(regexp)] == regexp:
                best_pat = p
                best_match = len(regexp)
                break
        if best_pat == '(error)' and best_match < 0:
            msg = 'Bad Token'
            if restrict:
                msg = 'Trying to find one of '+', '.join(restrict)
            raise SyntaxError(self.pos, msg)
        # Create a token with this data
        token = (self.pos, self.pos+best_match, best_pat,
                 self.input[self.pos:self.pos+best_match])
        self.pos = self.pos + best_match
        # Only add this token if it's not in the list (to prevent looping)
        if not self.tokens or token != self.tokens[-1]:
            self.tokens.append(token)
            self.restrictions.append(restrict)

class Parser:
    def __init__(self, scanner):
        self._scanner = scanner
        self._pos = 0
    def _peek(self, *types):
        tok = self._scanner.token(self._pos, types)
        if printtrace:
            print "_peek:", tok
        return tok[2]
    def _scan(self, type):
        global printtrace
        tok = self._scanner.token(self._pos, [type])
        if printtrace:
            print "_scan:", tok, type
        if tok[2] != type:
            raise SyntaxError(tok[0], 'Trying to find '+type+' :'+ ' ,'.join(self._scanner.restrictions[self._pos]))
        self._pos = 1 + self._pos
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
    line_number = scanner.get_line_number()
    column_number = scanner.get_column_number()
    print '%d:%d: %s' % (line_number, column_number, err.msg)
    context = err.context
    if not context:
        print_line_with_pointer(input, err.charpos)
    while context:
        print 'while parsing %s%s:' % (context.rule, tuple(context.args))
        print_line_with_pointer(input, context.scanner.get_prev_char_pos(context.tokenpos))
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
