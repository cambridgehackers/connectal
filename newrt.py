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
        self.whitespace = re.compile("[ \r\t\n]+|//.*\\n")
        self.preprocessor = re.compile("`[a-zA-Z0-9_]+")
        self.commentpattern = re.compile("/[*].*?[*]/", re.DOTALL)
        self.attributepattern = re.compile(r'\(\*.*?\*\)', re.DOTALL)
        self.numbers = re.compile("[0-9\\']+[dhb\\\\.]*[a-fA-F0-9_]*")
        self.anychar = re.compile("[a-zA-Z0-9_]*")
        self.alphatoken = re.compile("`*[a-zA-Z_][a-zA-Z0-9_]*")
        self.builtin = re.compile("\\$[a-zA-Z_]+")
        self.strings = re.compile(r'"([^\\"]+|\\.)*"', re.DOTALL)
        self.tokeninvalid = True
    def get_prev_char_pos(self, i=-1):
        global lasttokenpos
        return lasttokenpos
    def get_line_number(self):
        return 1 + self.input[:self.pos].count('\n')
    def get_column_number(self):
        return self.pos - (self.input[:self.pos].rfind('\n')+1)
    def skipwhitespace(self):
        while True:
            m = self.commentpattern.match(self.input, self.pos)
            if not m:
                m = self.whitespace.match(self.input, self.pos)
            if not m:
                m = self.attributepattern.match(self.input, self.pos)
                if m:
                    #print "attribute:", m.group(0)
                    pass
                    #"synthesize"
                    #| "RST_N"  EQUAL STRING
                    #| "CLK"  EQUAL STRING
                    #| "always_ready" [ EQUAL interface_method ]
                    #| "always_enabled" [ EQUAL interface_method ]
                    #| "descending" "urgency" EQUAL LBRACE rule_names RBRACE
                    #| "preempts" [ EQUAL ] LBRACE rule_names COMMA  LPAREN list_rule_names RPAREN RBRACE
                    #| "doc" EQUAL STRING
                    #| "ready" EQUAL STRING
                    #| "enable" EQUAL STRING
                    #| "result" EQUAL STRING
                    #| "prefix" EQUAL STRING
                    #| "port"  EQUAL STRING
                    #| "noinline"
                    #| "fire_when_enabled"
                    #| "no_implicit_conditions"
            if not m:
                m = self.preprocessor.match(self.input, self.pos)
                if m:
                    #print "preprocessor:", m.group(0)
                    s = m.group(0)
                    if s == '`define' or s == '`include' or s == '`ifdef' or s == '`else' or s == '`endif' or s == '`undef' or s == '`ifndef':
                        nextp = self.input.find('\n', self.pos)
                        if nextp != -1:
                            self.pos = nextp
                            continue
                    else:    # we are a substitution token
                        return ['VAR', len(s)]
                    pass
                    #    rule define_declaration:
                    #        TOKPDEFINE VAR [expr<<[]>>]
                    #    rule include_declaration:
                    #        TOKPINCLUDE STR
                    #    rule ifdef_statement:
                    #        TOKPIFDEF [VAR | ANYCHAR]
                    #           [ module_item
                    #           | TOKPUNDEF (VAR | ANYCHAR)
                    #           ]
                    #        [ TOKPELSE
                    #           [ module_item ]
                    #        ]
                    #        TOKPENDIF
            if not m:
                break
            self.pos = m.end()
        return None

    def jjtoken(self, restrict, advance_after_read):
        global printtrace
        global lasttokenpos
        p = self.tokeninvalid
        self.tokeninvalid = advance_after_read
        if not p:
            return self.thistoken
        best_match = 0
        best_pat = ''
        first_pat = ''
        preprocesstoken = self.skipwhitespace()
        lasttokenpos = self.pos
        if preprocesstoken != None:
            best_pat = preprocesstoken[0]
            best_match = preprocesstoken[1]
        if lasttokenpos >= len(self.input):
            best_pat = 'ENDTOKEN'
        else:
            m = self.numbers.match(self.input, lasttokenpos)
            if m:
                best_pat = 'NUM'
                best_match = len(m.group(0))
            #m = self.anychar.match(self.input, lasttokenpos)
            m = self.alphatoken.match(self.input, lasttokenpos)
            if m:
                best_pat = 'VAR'
                best_match = len(m.group(0))
                # lookahead past whitespace for '#' or '::'
                self.pos = m.end()
                self.skipwhitespace()
                if self.pos < len(self.input):
                    if m.group(0)[0].isupper():
                        best_pat = 'TYPEVAR'
                        if self.input[self.pos] == '#':
                            best_match = self.pos + 1 - lasttokenpos
                        else:
                            best_match = self.pos - lasttokenpos
                    elif self.input[self.pos] == '#':
                        best_pat = 'VAR'
                        best_match = self.pos + 1 - lasttokenpos
                    elif self.input[self.pos:self.pos+2] == '::':
                        best_pat = 'CLASSVAR'
                        best_match = self.pos + 2 - lasttokenpos
            m = self.strings.match(self.input, lasttokenpos)
            if m:
                best_pat = 'STR'
                best_match = len(m.group(0))
            m = self.builtin.match(self.input, lasttokenpos)
            if m:
                best_pat = 'BUILTINVAR'
                best_match = len(m.group(0))
                # '$display' '$dumpoff' '$dumpon' '$dumpvars'
                # '$error' '$fclose' '$fdisplay' '$fflush'
                # '$fgetc' '$finish' '$fopen' '$format'
                # '$fwrite' '$stime' '$stop' '$test$plusargs'
                # '$time' '$ungetc' '$write'
            first_pat = best_pat
            for p, regexp in self.patterns:
                if best_pat == '':
                    best_match = len(regexp)
                elif restrict and p not in restrict:
                    continue
                if self.input[lasttokenpos:lasttokenpos+best_match] == regexp:
                    best_pat = p
                    break
            if best_pat == '':
                msg = 'Bad Token'
                if restrict:
                    msg = 'Trying to find one of '+', '.join(restrict)
                raise SyntaxError(lasttokenpos, msg)
        self.pos = lasttokenpos + best_match
        # Create a token with this data
        self.thistoken = (lasttokenpos, self.pos, best_pat,
                 self.input[lasttokenpos:self.pos], first_pat)
        if printtrace:
            print '_scan:', self.thistoken
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
