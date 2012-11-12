#!/usr/bin/python2
#
# grammar.py, part of Yapps 2 - yet another python parser system
# Copyright 1999-2003 by Amit J. Patel <amitp@cs.stanford.edu>
#
# This version of the Yapps 2 grammar can be distributed under the
# terms of the MIT open source license, either found in the LICENSE
# file included with the Yapps distribution
# <http://theory.stanford.edu/~amitp/yapps/> or at
# <http://www.opensource.org/licenses/mit-license.php>
#

"""Parser for Yapps grammars.

This file defines the grammar of Yapps grammars.  Naturally, it is
implemented in Yapps.  The grammar.py module needed by Yapps is built
by running Yapps on yapps_grammar.g.  (Holy circularity, Batman!)

"""

import sys, re
import parsetree

######################################################################
def cleanup_choice(rule, lst):
    if len(lst) == 0: return Sequence(rule, [])
    if len(lst) == 1: return lst[0]
    return parsetree.Choice(rule, *tuple(lst))

def cleanup_sequence(rule, lst):
    if len(lst) == 1: return lst[0]
    return parsetree.Sequence(rule, *tuple(lst))

def resolve_name(rule, tokens, id, args):
    if id in [x[0] for x in tokens]:
        # It's a token
        if args:
            print 'Warning: ignoring parameters on TOKEN %s<<%s>>' % (id, args)
        return parsetree.Terminal(rule, id)
    else:
        # It's a name, so assume it's a nonterminal
        return parsetree.NonTerminal(rule, id, args)

%%
parser ParserDescription:
    option:      "context-insensitive-scanner"

    ignore:      "[ \t\r\n]+"
    ignore:      "#.*?\r?\n"
    token EOF:   "$"
    token ATTR:  "<<.+?>>"
    token STMT:  "{{.+?}}"
    token ID:    '[a-zA-Z_][a-zA-Z_0-9]*'
    token STR:   '[rR]?\'([^\\n\'\\\\]|\\\\.)*\'|[rR]?"([^\\n"\\\\]|\\\\.)*"'
    token LP:    '\\('
    token RP:    '\\)'
    token LB:    '\\['
    token RB:    '\\]'
    token OR:    '[|]'
    token STAR:  '[*]'
    token PLUS:  '[+]'
    token QUEST: '[?]'
    token COLON: ':'

    rule LINENO: # This is a pseudotoken.  It matches nothing; returns the line number
                 {{ return 1 + self._scanner.get_input_scanned().count('\n') }}
    
    rule Parser: "parser" ID ":"
                   Options
                   Tokens
                   Rules<<Tokens>>
                 EOF
                 {{ return parsetree.Generator(ID,Options,Tokens,Rules) }}

    rule Options: {{ opt = {} }}
                  ( "option" ":" Str {{ opt[Str] = 1 }} )*
                  {{ return opt }}

    rule Tokens:  {{ tok = [] }}
                  (
                    "token" ID ":" Str {{ tok.append( (ID,Str) ) }}
                  | "ignore"   ":" Str {{ tok.append( ('#ignore',Str) ) }}
                  )*
                  {{ return tok }}

    rule Rules<<tokens>>:
                  {{ rul = [] }}
                  ( LINENO
                    "rule" ID OptParam ":" ClauseA<<ID, tokens>>
                    # TODO: save LINENO somewhere?
                    {{ rul.append( (ID, OptParam, ClauseA) ) }}
                  )*
                  {{ return rul }}

    rule ClauseA<<rule, tokens>>:
                  ClauseB<<rule, tokens>>
                  {{ v = [ClauseB] }}
                  ( OR ClauseB<<rule, tokens>> {{ v.append(ClauseB) }} )*
                  {{ return cleanup_choice(rule, v) }}

    rule ClauseB<<rule, tokens>>:
                  {{ v = [] }}
                  ( ClauseC<<rule, tokens>> {{ v.append(ClauseC) }} )*
                  {{ return cleanup_sequence(rule, v) }}

    rule ClauseC<<rule, tokens>>:
                  ClauseD<<rule, tokens>>
                  ( PLUS {{ return parsetree.Plus(rule, ClauseD) }}
                  | STAR {{ return parsetree.Star(rule, ClauseD) }}
                  | QUEST {{ return parsetree.Option(rule, ClauseD) }}
                  |      {{ return ClauseD }} )

    rule ClauseD<<rule, tokens>>:
                  STR {{ t = (STR, eval(STR,{},{})) }}
                      {{ if t not in tokens: tokens.insert( 0, t ) }}
                      {{ return parsetree.Terminal(rule, STR) }}
                | ID OptParam {{ return resolve_name(rule, tokens, ID, OptParam) }}
                | LP ClauseA<<rule, tokens>> RP {{ return ClauseA }}
                | LB ClauseA<<rule, tokens>> RB {{ return parsetree.Option(rule, ClauseA) }}
                | STMT {{ return parsetree.Eval(rule, STMT[2:-2]) }}

    rule OptParam:
                  ATTR {{ return ATTR[2:-2] }}
                |      {{ return '' }}
    rule Str:   STR {{ return eval(STR,{},{}) }}
%%
