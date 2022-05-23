#!/usr/bin/env python3
# Copyright (c) 2014 Quanta Research Cambridge, Inc
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

import ply.lex as lex
import AST
import json, os, re, sys

import bsvpreprocess
import globalv
import cppgen, bsvgen

scripthome = os.path.dirname(os.path.abspath(__file__))
noisyFlag=True
parseDebugFlag=False
parseTrace=False

tokens = (
    'AMPER',
    'AMPERAMPER',
    'AMPERAMPERAMPER',
    'APOSTROPHE',
    'BANG',
    'BAR',
    'BARBAR',
    'BUILTINVAR',
    'CARET',
    'COLON',
    'COLONCOLON',
    'COMMA',
    'DOT',
    'EQEQ',
    'EQUAL',
    'GEQ',
    'GREATER',
    'GREATERGREATER',
    'HASH',
    'LARROW',
    'LBRACE',
    'LBRACKET',
    'LEQ',
    'LESS',
    'LESSLESS',
    'LPAREN',
    'LPARENSTAR',
    'MINUS',
    'NEQ',
    'NUM',
    'PERCENT',
    'PLUS',
    'QUESTION',
    'RBRACE',
    'RBRACKET',
    'RPAREN',
    'RPARENSTAR',
    'SEMICOLON',
    'SLASH',
    'STAR',
    'STARSTAR',
    'STR',
    'TILDE',
    'TILDEAMPER',
    'TILDEBAR',
    'TILDECARET',
    'VAR'
)

reserved = {
    'action': 'TOKACTION',
    'Action': 'TOKUACTION',
    'actionvalue': 'TOKACTIONVALUE',
    'BDPI': 'TOKBDPI',
    'begin': 'TOKBEGIN',
    'BVI': 'TOKBVI',
    'C': 'TOKC',
    'case': 'TOKCASE',
    'CF': 'TOKCF',
    'clocked_by': 'TOKCLOCKED_BY',
    'default': 'TOKDEFAULT',
    'default_clock': 'TOKDEFAULT_CLOCK',
    'default_reset': 'TOKDEFAULT_RESET',
    '`define': 'TOKTICKDEFINE',
    'dependencies': 'TOKDEPENDENCIES',
    'deriving': 'TOKDERIVING',
    'determines': 'TOKDETERMINES',
    'else': 'TOKELSE',
    'enable': 'TOKENABLE',
    'end': 'TOKEND',
    'endaction': 'TOKENDACTION',
    'endactionvalue': 'TOKENDACTIONVALUE',
    'endcase': 'TOKENDCASE',
    'endfunction': 'TOKENDFUNCTION',
    'endinstance': 'TOKENDINSTANCE',
    'endinterface': 'TOKENDINTERFACE',
    'endmethod': 'TOKENDMETHOD',
    'endmodule': 'TOKENDMODULE',
    'endpackage': 'TOKENDPACKAGE',
    'endpar': 'TOKENDPAR',
    'endrule': 'TOKENDRULE',
    'endrules': 'TOKENDRULES',
    'endseq': 'TOKENDSEQ',
    'endtypeclass': 'TOKENDTYPECLASS',
    'enum': 'TOKENUM',
    'export': 'TOKEXPORT',
    'for': 'TOKFOR',
    'function': 'TOKFUNCTION',
    'if': 'TOKIF',
    'import': 'TOKIMPORT',
#    'in': 'TOKIN',
    'input_clock': 'TOKINPUT_CLOCK',
    'input_reset': 'TOKINPUT_RESET',
    'instance': 'TOKINSTANCE',
    'interface': 'TOKINTERFACE',
    'let': 'TOKLET',
    'match': 'TOKMATCH',
    'matches': 'TOKMATCHES',
    'method': 'TOKMETHOD',
    'module': 'TOKMODULE',
    'no_reset': 'TOKNO_RESET',
    'numeric': 'TOKNUMERIC',
    'output_clock': 'TOKOUTPUT_CLOCK',
    'output_reset': 'TOKOUTPUT_RESET',
    'package': 'TOKPACKAGE',
    'par': 'TOKPAR',
    'port': 'TOKPORT',
    'parameter': 'TOKPARAMETER',
    'port': 'TOKPORT',
    'provisos': 'TOKPROVISOS',
    'ready': 'TOKREADY',
    'reset_by': 'TOKRESET_BY',
    'return': 'TOKRETURN',
    'rule': 'TOKRULE',
    'rules': 'TOKRULES',
    'SB': 'TOKSB',
    'SBR': 'TOKSBR',
    'schedule': 'TOKSCHEDULE',
    'seq': 'TOKSEQ',
    '_when_': 'TOKWHEN',
    'Stmt' : 'TOKSTMT',
    'struct': 'TOKSTRUCT',
    'tagged': 'TOKTAGGED',
    'type': 'TOKTYPE',
    'typeclass': 'TOKTYPECLASS',
    'typedef': 'TOKTYPEDEF',
    'union': 'TOKUNION',
    'while': 'TOKWHILE',
}

for tok in reserved.values():
    tokens = tokens + (tok,)

t_AMPER = r'&'
t_AMPERAMPER = r'&&'
t_AMPERAMPERAMPER = r'&&&'
t_APOSTROPHE = r'\''
t_BANG = r'!'
t_BAR = r'\|'
t_BARBAR = r'\|\|'
t_CARET = r'\^'
t_COLON = r':'
t_COLONCOLON = r'::'
t_COMMA = r','
t_DOT = r'[\.]'
t_EQEQ = r'=='
t_EQUAL = r'='
t_GEQ = r'>='
t_GREATER = r'>'
t_GREATERGREATER = r'>>'
t_HASH = r'\#'
t_LARROW = r'<-'
t_LBRACE = r'{'
t_LBRACKET = r'\['
t_LEQ = r'<='
t_LESS = r'<'
t_LESSLESS = r'<<'
t_LPAREN = r'\('
t_LPARENSTAR = r'\(\*'
t_MINUS = r'[-]'
t_NEQ = r'!='
t_NUM = r'(([0-9]+\'?[bdh\.]?[0-9a-zA-Z?]*)|(\'[bdh\.]?[0-9a-zA-Z?]+))'
t_PERCENT = r'%'
t_PLUS = r'\+'
t_QUESTION = r'\?'
t_RBRACE = r'}'
t_RBRACKET = r'\]'
t_RPAREN = r'\)'
t_RPARENSTAR = r'\*\)'
t_SEMICOLON = r';'
t_SLASH = r'/'
t_STAR = r'\*'
t_STARSTAR = r'\*\*'
t_STR = r'"[^\"]*"'
t_TILDE = r'~'
t_TILDEAMPER = r'~\&'
t_TILDEBAR = r'~\|'
t_TILDECARET = r'~^'

t_ignore = ' \t\f'

def t_error(t):
    print("Illegal character '%s' in file '%s'" % (t.value[0], globalfilename))
    t.lexer.skip(1)

def p_error(errtoken):
    if hasattr(errtoken, 'lineno'):
        sys.stderr.write("%s:%d: Syntax error, token=%s\n" % (globalfilename, errtoken.lineno, errtoken.type))
    else:
        sys.stderr.write("%s: Syntax error, token=%s\n" % (globalfilename, errtoken))
    return None
    
def t_VAR(t):
    r'`?([a-zA-Z_][$a-zA-Z0-9_]*)|(\\[-+*/|^&][*]?)'
    t.type = reserved.get(t.value,'VAR')    
    return t

t_BUILTINVAR = r'\$[a-zA-Z_][a-zA-Z0-9_]*'

def t_newline(t):
    r'\n+'
    t.lexer.lineno += len(t.value)

def t_COMMENT(t):
    r'//.*'
    pass

def t_MCOMMENT(t):
    r'/\*(.|\n)*?\*/'
    #print(t.value, t.value.count('\n'), t.lineno)
    t.lineno += t.value.count('\n')

import ply.yacc as yacc

def p_goal(p):
    'goal : package '
    p[0] = p[1]

def p_typeParams(p):
    '''typeParams :
                  | type
                  | typeParams COMMA type'''
    if len(p) == 2:
        p[0] = [p[1]]
    elif len(p) == 4:
        p[0] = p[1] + [p[3]]
    else:
        p[0] = []

def p_type(p):
    '''type : VAR
            | VAR COLONCOLON VAR
            | NUM
            | TOKUACTION
            | VAR HASH LPAREN typeParams RPAREN
            | VAR COLONCOLON VAR HASH LPAREN typeParams RPAREN'''
    if len(p) == 2:
        p[0] = AST.Type(p[1], [])
    elif len(p) == 4:
        p[0] = p[3]
    elif len(p) == 8:
        p[0] = AST.Type(p[3], p[6])
    else:
        p[0] = AST.Type(p[1], p[4])

def p_expressions(p):
    '''expressions : expression
                   | 
                   | expressions COMMA expression'''

precedence = (
    ('left', 'STAR', 'SLASH', 'PERCENT'),
    ('left', 'PLUS', 'MINUS'),
    ('left', 'GREATERGREATER', 'LESSLESS'),
    ('left', 'LEQ', 'GEQ', 'LESS', 'GREATER'),
    ('left', 'EQEQ', 'NEQ'),
    ('left', 'AMPER'),
    ('left', 'CARET'),
    ('left', 'TILDECARET'),
    ('left', 'BAR'),
    ('left', 'AMPERAMPER'),
    ('left', 'BARBAR'),
    ('left', 'AMPERAMPERAMPER')
)

def p_colonVar(p):
    '''colonVar :
                | COLON VAR'''

def p_expression(p):
    '''expression : caseExpr
                  | binaryExpression'''
    p[0] = p[1]

def p_caseExprItem(p):
    '''caseExprItem : pattern COLON expression SEMICOLON'''

def p_caseExprItems(p):
    '''caseExprItems :
                 | caseExprItems caseExprItem'''

def p_defaultExprItem(p):
    '''defaultExprItem :
                   | TOKDEFAULT expression SEMICOLON
                   | TOKDEFAULT COLON expression SEMICOLON'''

def p_caseExpr(p):
    '''caseExpr : TOKCASE LPAREN expression RPAREN caseExprItems defaultExprItem TOKENDCASE
                | TOKCASE LPAREN expression RPAREN TOKMATCHES caseExprItems defaultExprItem TOKENDCASE'''

def p_binaryExpression(p):
    '''binaryExpression : unaryExpression
                        | binaryExpression AMPERAMPERAMPER binaryExpression
                        | binaryExpression MINUS binaryExpression
                        | binaryExpression PLUS binaryExpression
                        | binaryExpression STAR binaryExpression
                        | binaryExpression STARSTAR binaryExpression
                        | binaryExpression APOSTROPHE binaryExpression
                        | binaryExpression SLASH binaryExpression
                        | binaryExpression CARET binaryExpression
                        | binaryExpression LESS binaryExpression
                        | binaryExpression GREATER binaryExpression
                        | binaryExpression GEQ binaryExpression
                        | binaryExpression LESSLESS binaryExpression
                        | binaryExpression LEQ binaryExpression
                        | binaryExpression GREATERGREATER binaryExpression
                        | binaryExpression EQEQ binaryExpression
                        | binaryExpression NEQ binaryExpression
                        | binaryExpression AMPER binaryExpression
                        | binaryExpression AMPERAMPER binaryExpression
                        | binaryExpression BAR binaryExpression
                        | binaryExpression BARBAR binaryExpression
                        | binaryExpression PERCENT binaryExpression'''
    p[0] = p[1]

def p_unaryExpression(p):
    '''unaryExpression : term
                       | PLUS term
                       | MINUS term
                       | BANG term
                       | TILDE term
                       | AMPER term
                       | TILDEAMPER term
                       | BAR term
                       | TILDEBAR term
                       | CARET term
                       | TILDECARET term
                       | TOKACTION colonVar expressionStmts TOKENDACTION colonVar
                       | TOKACTIONVALUE colonVar expressionStmts TOKENDACTIONVALUE colonVar
                       '''
    p[0] = p[1]

def p_term(p):
    '''term : type
            | type LBRACKET expression RBRACKET
            | type LBRACKET expression COLON expression RBRACKET
            | STR
            | QUESTION
            | term QUESTION expression
            | term QUESTION expression COLON expression
            | LPAREN expression RPAREN
            | TOKINTERFACE VAR interfaceHashParams SEMICOLON expressionStmts TOKENDINTERFACE colonVar
            | TOKINTERFACE VAR COLONCOLON VAR interfaceHashParams SEMICOLON expressionStmts TOKENDINTERFACE colonVar
            | TOKINTERFACE VAR expressionStmts TOKENDINTERFACE colonVar
            | TOKINTERFACE VAR COLONCOLON VAR expressionStmts TOKENDINTERFACE colonVar
            | BUILTINVAR
            | TOKCLOCKED_BY expression
            | TOKRESET_BY expression
            | TOKTAGGED VAR
            | TOKTAGGED VAR expression
            | TOKTAGGED VAR LBRACE structInits RBRACE
            | term LBRACE structInits RBRACE
            | term TOKMATCHES pattern
            | LBRACE expressions RBRACE
            | term DOT VAR
            | term LBRACKET expression RBRACKET DOT term
            | term LBRACKET expression RBRACKET
            | term LBRACKET expression COLON expression RBRACKET
            | term LPAREN params RPAREN DOT term
            | term LPAREN params RPAREN'''
    if len(p) > 2 and type(p[1]) == str:
        p[0] = p[2]
    else:
        p[0] = p[1]

def p_structInits(p):
    '''structInits : 
                   | structInits COMMA VAR COLON expression
                   | structInits COMMA VAR COLON DOT VAR
                   | VAR COLON expression
                   | VAR COLON DOT VAR'''

def p_structPatternElements(p):
    '''structPatternElements : VAR COLON pattern
                             | structPatternElements COMMA VAR COLON pattern '''

def p_pattern(p):
    '''pattern : TOKTAGGED VAR
               | TOKTAGGED VAR DOT VAR
               | TOKTAGGED VAR LBRACE structPatternElements RBRACE
               | LBRACE patterns RBRACE
               | DOT VAR
               | DOT STAR
               | NUM'''

def p_patterns(p):
    '''patterns : pattern
                | patterns COMMA pattern'''

def p_importDecl(p):
    'importDecl : TOKIMPORT VAR COLONCOLON STAR SEMICOLON'
    if not p[2] in globalimports:
        globalimports.append(p[2])
    p[0] = p[2]

def p_importDecls(p):
    '''importDecls : 
                   | importDecls importDecl'''

def p_exportDecl(p):
    '''exportDecl : TOKEXPORT VAR LPAREN DOT DOT RPAREN SEMICOLON
                  | TOKEXPORT VAR SEMICOLON
                  | TOKEXPORT VAR COLONCOLON STAR SEMICOLON'''
    p[0] = p[2]

def p_exportDecls(p):
    '''exportDecls :
                   | exportDecls exportDecl'''

def p_interfaceFormalParam(p):
    '''interfaceFormalParam : TOKTYPE VAR
                            | VAR interfaceHashParams
                            | NUM
                            | TOKNUMERIC TOKTYPE VAR'''
    if len(p) == 2:
        p[0] = p[1]
    elif len(p) == 3:
        p[0] = p[2]
    else:
        p[0] = p[3]

def p_interfaceFormalParams(p):
    '''interfaceFormalParams : interfaceFormalParam
                             | interfaceFormalParams COMMA interfaceFormalParam'''
    if len(p) == 2:
        p[0] = [p[1]]
    else:
        p[0] = p[1] + [p[3]]

def p_interfaceHashParams(p):
    '''interfaceHashParams :
                           | HASH LPAREN interfaceFormalParams RPAREN'''
    if len(p) == 5:
        p[0] = p[3]
    else:
        p[0] = []

def p_instanceAttributes(p):
    '''instanceAttributes :
                          | instanceAttributes LPARENSTAR attrSpecs RPARENSTAR'''

def p_subinterfaceDecl(p):
    '''subinterfaceDecl : instanceAttributes TOKINTERFACE type VAR SEMICOLON
                        | type VAR SEMICOLON'''
    if len(p) == 6:
        name = p[4]
        t = p[3]
    elif len(p) == 5:
        name = p[3]
        t = p[2]
    else:
        name = p[2]
        t = p[1]
    p[0] = AST.Interface(t.name, t.params, [], name, globalfilename) 

def p_parenthesizedFormalParams(p):
    '''parenthesizedFormalParams : 
                                 |  LPAREN RPAREN
                                 |  LPAREN moduleFormalParams RPAREN'''
    if len(p) < 4:
        p[0] = []
    else:
        p[0] = p[2]

def p_methodDecl(p):
    '''methodDecl : TOKMETHOD type VAR parenthesizedFormalParams SEMICOLON'''
    p[0] = AST.Method(p[3], p[2], p[4])

def p_interfaceStmt(p):
    '''interfaceStmt : subinterfaceDecl
                     | methodDecl '''
    p[0] = p[1]

def p_interfaceStmts(p):
    '''interfaceStmts :
                      | interfaceStmts interfaceStmt'''
    if len(p) == 3:
        p[0] = p[1] + [p[2]]
    else:
        p[0] = []

def p_interfaceDecl(p):
    '''interfaceDecl : instanceAttributes TOKINTERFACE VAR interfaceHashParams SEMICOLON interfaceStmts TOKENDINTERFACE colonVar'''
    interface = AST.Interface(p[3], p[4], p[6], None, globalfilename)
    p[0] = interface


# the token '[' signifies an array type 
def p_arrayDecl(p):
    '''arrayDecl : type VAR LBRACKET NUM RBRACKET'''
    arr_t = AST.Type(p[3],p[1])
    p[0] = AST.Variable(p[2], arr_t, None)

def p_varDecl(p):
    '''varDecl : arrayDecl
               | type VAR'''
    if len(p)==3:
        p[0] = AST.Variable(p[2], p[1], None)
    else:
        p[0] = p[1]

def p_params(p):
    '''params : expressions
              | TOKSEQ fsmStmts TOKENDSEQ'''

def p_lvalue(p):
    '''lvalue : VAR
              | LPAREN lvalue RPAREN
              | lvalue DOT VAR
              | TOKACTION fsmStmts TOKENDACTION
              | lvalue LBRACKET expression RBRACKET
              | lvalue LBRACKET expression COLON expression RBRACKET
              | TOKMATCH pattern'''

def p_varAssign1(p):
    '''varAssign1 : TOKLET VAR EQUAL expression
                  | TOKLET VAR LARROW expression'''
    p[0] = AST.Variable(p[2], None, p[4])

def p_varAssign2(p):
    '''varAssign2 : type VAR EQUAL expression
                  | type VAR LBRACKET expression RBRACKET EQUAL expression
                  | type VAR LBRACKET expression RBRACKET LBRACKET NUM RBRACKET EQUAL expression
                  | type VAR LARROW expression'''
    p[0] = AST.Variable(p[2], p[1], p[4])

def p_varAssign3(p):
    '''varAssign3 : lvalue EQUAL expression
                  | lvalue LEQ expression
                  | lvalue LARROW expression'''
    p[0] = AST.Variable(p[2], p[1], None)

def p_varAssign(p):
    '''varAssign : varAssign1
                 | varAssign2
                 | varAssign3'''

def p_ruleCond(p):
    '''ruleCond : LPAREN expression RPAREN'''

def p_implicitCond(p):
    '''implicitCond :
                    | TOKIF LPAREN expression RPAREN'''

def p_rule(p):
    '''rule : TOKRULE VAR implicitCond SEMICOLON expressionStmts TOKENDRULE colonVar
            | TOKRULE VAR ruleCond implicitCond SEMICOLON expressionStmts TOKENDRULE colonVar'''

def p_ifStmt(p):
    '''ifStmt : TOKIF LPAREN expression RPAREN fsmStmt
              | TOKIF LPAREN expression RPAREN fsmStmt TOKELSE fsmStmt'''

def p_caseItem(p):
    '''caseItem : expressions COLON expressionStmt'''

def p_caseItems(p):
    '''caseItems :
                 | caseItems caseItem'''

def p_defaultItem(p):
    '''defaultItem :
                   | TOKDEFAULT expressionStmt
                   | TOKDEFAULT COLON expressionStmt'''

def p_caseStmt(p):
    '''caseStmt : TOKCASE LPAREN expression RPAREN caseItems defaultItem TOKENDCASE
                | TOKCASE LPAREN expression RPAREN TOKMATCHES caseItems defaultItem TOKENDCASE'''

def p_forStmt(p):
    '''forStmt : TOKFOR LPAREN varAssign SEMICOLON expression SEMICOLON varAssign RPAREN fsmStmt'''

def p_whenStmt(p):
    '''whenStmt : TOKWHEN LPAREN expression RPAREN LPAREN expression RPAREN SEMICOLON'''

def p_beginStmt(p):
    '''beginStmt : TOKBEGIN expressionStmts TOKEND'''

def p_expressionStmt(p):
    '''expressionStmt : TOKRETURN expression SEMICOLON
                      | fsmStmtDef
                      | whenStmt
                      | lvalue SEMICOLON
                      | lvalue LPAREN params RPAREN DOT expression SEMICOLON
                      | lvalue LPAREN params RPAREN SEMICOLON
                      | BUILTINVAR LPAREN expressions RPAREN SEMICOLON
                      | varAssign SEMICOLON
                      | varDecl SEMICOLON
                      | beginStmt
                      | ifStmt
                      | caseStmt
                      | forStmt
                      | interfaceDef
                      | functionDef
                      | methodDef
                      | moduleDef
                      | TOKACTION colonVar expressionStmts TOKENDACTION colonVar
                      | TOKACTIONVALUE colonVar expressionStmts TOKENDACTIONVALUE colonVar
                      | typeDef
                      | instanceAttributes rule
                      | TOKACTION fsmStmts TOKENDACTION
                      '''
    if parseTrace:
        print('ENDSTATEMENT', [pitem for pitem in p])

def p_expressionStmts(p):
    '''expressionStmts : expressionStmts expressionStmt
                       | '''

def p_provisos(p):
    '''provisos :
                | TOKPROVISOS LPAREN typeParams RPAREN'''
    if len(p) == 5:
        p[0] = p[3]
    else:
        p[0] = []

def p_endFunction(p):
    '''endFunction : TOKENDFUNCTION colonVar'''

def p_functionBody(p):
    '''functionBody : SEMICOLON expressionStmts endFunction''' 

def p_functionValue(p):
    '''functionValue : EQUAL expression SEMICOLON'''

def p_functionFormal(p):
    '''functionFormal : type VAR
                      | VAR'''

def p_functionFormals(p):
    '''functionFormals :
                       | functionFormal
                       | functionFormals COMMA functionFormal '''
def p_fsmStmt(p):
    '''fsmStmt : TOKSEQ fsmStmts TOKENDSEQ
               | TOKPAR fsmStmts TOKENDPAR
               | TOKWHILE ruleCond fsmStmt
               | expressionStmt'''

def p_fsmStmts(p):
    '''fsmStmts : fsmStmt fsmStmts
                | fsmStmt'''

def p_fsmStmtDef(p):
    '''fsmStmtDef : TOKSTMT VAR EQUAL fsmStmts SEMICOLON'''

def p_functionDef(p):
    '''functionDef : instanceAttributes TOKFUNCTION type VAR LPAREN functionFormals RPAREN provisos functionBody
                   | instanceAttributes TOKFUNCTION      VAR LPAREN functionFormals RPAREN provisos functionBody
                   | instanceAttributes TOKFUNCTION type VAR LPAREN functionFormals RPAREN provisos functionValue
                   | instanceAttributes TOKFUNCTION      VAR LPAREN functionFormals RPAREN provisos functionValue
                   '''
    if len(p) == 9:
        # no type
        p[0] = AST.Function(p[3], None, p[5])
    else:
        p[0] = AST.Function(p[4], p[3], p[6])

def p_methodDef(p):
    '''methodDef : TOKMETHOD type VAR LPAREN functionFormals RPAREN implicitCond SEMICOLON methodBody
                 | TOKMETHOD type VAR implicitCond SEMICOLON methodBody
                 | TOKMETHOD type VAR EQUAL expression SEMICOLON
                 | TOKMETHOD type VAR LPAREN functionFormals RPAREN EQUAL expression SEMICOLON
                 | TOKMETHOD VAR LPAREN functionFormals RPAREN EQUAL expression SEMICOLON
                 | TOKMETHOD VAR EQUAL expression SEMICOLON'''
    returnType = p[2]
    name = p[3]
    params = []
    p[0] = AST.Method(name, returnType, params)

def p_methodBody(p):
    '''methodBody : expressionStmts endMethod
                  | endMethod'''

def p_endMethod(p):
    '''endMethod : TOKENDMETHOD colonVar'''

def p_unionMember(p):
    '''unionMember : type VAR SEMICOLON
                   | subStruct VAR SEMICOLON
                   | subUnion VAR SEMICOLON'''

def p_subStruct(p):
    '''subStruct : TOKSTRUCT LBRACE structMembers RBRACE'''

def p_structMembers(p):
    '''structMembers :
                     | structMember
                     | structMembers structMember'''
    if len(p) == 1:
        p[0] = []
    elif len(p) == 2:
        p[0] = [p[1]]
    elif len(p) == 3:
        p[0] = p[1] + [p[2]]

def p_structMember(p):
    '''structMember : type VAR SEMICOLON
                    | subUnion VAR SEMICOLON'''
    p[0] = AST.StructMember(p[1], p[2])

def p_subUnion(p):
    '''subUnion : TOKUNION TOKTAGGED LBRACE unionMembers RBRACE'''

def p_unionMembers(p):
    '''unionMembers : unionMember
                    | unionMembers unionMember'''

def p_taggedUnionDef(p):
    '''taggedUnionDef : TOKUNION TOKTAGGED LBRACE unionMembers RBRACE'''

def p_structDef(p):
    '''structDef : TOKSTRUCT LBRACE structMembers RBRACE'''
    p[0] = AST.Struct(p[3])

def p_enumRange(p):
    '''enumRange : 
                 | LBRACKET NUM RBRACKET
                 | LBRACKET NUM COLON NUM RBRACKET'''
                 

def p_enumElement(p):
    '''enumElement : VAR enumRange
                   | VAR enumRange EQUAL NUM'''
    if len(p) == 3:
        p[0] = [p[1], None]
    else:
        p[0] = [p[1], p[4]]

def p_enumElements(p):
    '''enumElements : enumElement
                    | enumElements COMMA enumElement'''
    if len(p) == 2:
        p[0] = [p[1]]
    else:
        p[0] = p[1] + [p[3]]

def p_enumDef(p):
    '''enumDef : TOKENUM LBRACE enumElements RBRACE'''
    p[0] = AST.Enum(p[3])

def p_vardot(p):
    '''vardot : VAR
            | vardot DOT VAR'''
    if len(p) == 2:
        p[0] = p[1]
    else:
        p[0] = p[3]

def p_vars(p):
    '''vars : vardot
            | vars COMMA vardot'''
    if len(p) == 2:
        p[0] = [p[1]]
    else:
        p[0] = p[1] + [p[3]]

def p_deriving(p):
    '''deriving : 
                | TOKDERIVING LPAREN vars RPAREN'''
    if len(p) == 5:
        p[0] = p[3]
    else:
        p[0] = []

def p_macroDef(p):
    '''macroDef : TOKTICKDEFINE VAR expression'''


def p_typeDefBody(p):
    '''typeDefBody : taggedUnionDef
                   | structDef
                   | enumDef
                   | type'''
    p[0] = p[1]

def p_typeDef(p):
    '''typeDef : TOKTYPEDEF typeDefBody VAR deriving SEMICOLON
               | TOKTYPEDEF typeDefBody VAR interfaceHashParams deriving SEMICOLON'''
    if len(p) == 6:
        p[0] = AST.TypeDef(p[2], p[3], [])
    else:
        p[0] = AST.TypeDef(p[2], p[3], p[4])


def p_interfaceDef(p):
    '''interfaceDef : TOKINTERFACE type VAR SEMICOLON expressionStmts TOKENDINTERFACE colonVar
                    | TOKINTERFACE type VAR EQUAL expression SEMICOLON
                    | TOKINTERFACE VAR EQUAL expression SEMICOLON'''
    if parseTrace:
        print('ENDINTERFACE', [pitem for pitem in p])

def p_formalParam(p):
    '''formalParam : type VAR'''
    param = AST.Param(p[2], p[1])
    p[0] = param

def p_moduleFormalParams(p):
    '''moduleFormalParams : formalParam
                          | TOKFUNCTION type VAR parenthesizedFormalParams
                          | moduleFormalParams COMMA formalParam
                          |'''
    if len(p) == 1:
        p[0] = []
    elif len(p) == 2:
        p[0] = [p[1]]
    elif len(p) == 5:
        p[0] = p[2]
    elif len(p) == 4:
        p[0] = p[1] + [p[3]]

def p_moduleFormalArg(p):
    '''moduleFormalArg : instanceAttributes type
                       | instanceAttributes type VAR'''

def p_moduleFormalArgs(p):
    '''moduleFormalArgs :
                        | moduleFormalArg
                        | moduleFormalArgs COMMA moduleFormalArg'''
    if len(p) == 2:
        p[0] = [p[1]]
    else:
        p[0] = p[1] + [p[3]]

def p_moduleParamsArgs(p):
    '''moduleParamsArgs :
                        | HASH LPAREN moduleFormalParams RPAREN
                        | HASH LPAREN moduleFormalParams RPAREN LPAREN moduleFormalArgs RPAREN
                        | LPAREN moduleFormalArgs RPAREN'''
    if len(p) == 8:
        p[0] = [ p[3], p[6] ]
    elif len(p) == 5:
        p[0] = [ p[3], None ]
    else:
        p[0] = [ None, p[2] ]

def p_attrSpec(p):
    '''attrSpec : VAR
                | VAR EQUAL expression'''

def p_attrSpecs(p):
    '''attrSpecs : attrSpec
                 | attrSpecs COMMA attrSpec'''

def p_moduleContext(p):
    '''moduleContext : 
                     | LBRACKET VAR RBRACKET'''
    if len(p) > 2:
        p[0] = p[2]

def p_moduleDefHeader(p):
    '''moduleDefHeader : instanceAttributes TOKMODULE moduleContext VAR moduleParamsArgs provisos SEMICOLON'''
    p[0] = [p[3], p[4], p[5][0], p[5][1], p[6]]

def p_moduleDef(p):
    '''moduleDef : moduleDefHeader expressionStmts TOKENDMODULE colonVar'''
    if parseTrace:
        print('ENDMODULE', [pitem for pitem in p])
    p[0] = AST.Module(p[1][0], p[1][1], p[1][2], p[1][3], p[1][4], p[2])

def p_importBviDef(p):
    '''importBviDef : TOKIMPORT STR VAR EQUAL bviModuleDef
            | TOKIMPORT STR TOKFUNCTION TOKUACTION VAR LPAREN functionFormals RPAREN SEMICOLON'''
    p[0] = p[5]
    if len(p) > 6:
        p[0] = AST.Module(None, p[5], None, None, None, None)

def p_bviModuleDef(p):
    '''bviModuleDef : instanceAttributes TOKMODULE moduleContext VAR moduleParamsArgs provisos SEMICOLON bviExpressionStmts TOKENDMODULE colonVar'''
    p[0] = AST.Module(p[3], p[4], p[5][0], p[5][1], p[6], p[8])

def p_bviExpressionStmts(p):
    '''bviExpressionStmts : bviExpressionStmts bviExpressionStmt
                          | bviExpressionStmt '''

def p_bviExpressionStmt(p):
    '''bviExpressionStmt : TOKRETURN expression SEMICOLON
                         | fsmStmtDef
                         | whenStmt
                         | lvalue SEMICOLON
                         | lvalue LPAREN expressions RPAREN SEMICOLON
                         | BUILTINVAR LPAREN expressions RPAREN SEMICOLON
                         | varAssign SEMICOLON
                         | varDecl SEMICOLON
                         | beginStmt
                         | ifStmt
                         | caseStmt
                         | forStmt
                         | bviInterfaceDef
                         | functionDef
                         | bviMethodDef
                         | moduleDef
                         | TOKACTION colonVar expressionStmts TOKENDACTION colonVar
                         | typeDef
                         | instanceAttributes rule
                         | TOKSEQ fsmStmts TOKENDSEQ
                         | TOKPORT VAR EQUAL expression SEMICOLON
                         | TOKPARAMETER VAR EQUAL expression SEMICOLON
                         | TOKDEFAULT_CLOCK VAR LPAREN RPAREN SEMICOLON
                         | TOKDEFAULT_CLOCK VAR LPAREN VAR RPAREN SEMICOLON
                         | TOKDEFAULT_RESET VAR LPAREN RPAREN SEMICOLON
                         | TOKDEFAULT_RESET TOKNO_RESET SEMICOLON
                         | TOKDEFAULT_RESET VAR LPAREN VAR RPAREN SEMICOLON
                         | TOKINPUT_CLOCK VAR LPAREN VAR RPAREN EQUAL expression SEMICOLON
                         | TOKINPUT_RESET VAR LPAREN VAR RPAREN EQUAL expression SEMICOLON
                         | TOKINPUT_RESET VAR LPAREN RPAREN EQUAL expression SEMICOLON
                         | TOKOUTPUT_CLOCK VAR LPAREN VAR RPAREN SEMICOLON
                         | TOKOUTPUT_RESET VAR LPAREN VAR RPAREN SEMICOLON
                         | TOKSCHEDULE LPAREN vars RPAREN schedOp LPAREN vars RPAREN SEMICOLON'''

def p_schedOp(p):
    '''schedOp : TOKCF
               | TOKC
               | TOKSB
               | TOKSBR'''

def p_bviInterfaceDef(p):
    '''bviInterfaceDef : TOKINTERFACE type VAR SEMICOLON bviExpressionStmts TOKENDINTERFACE colonVar
                       | TOKINTERFACE type VAR EQUAL expression SEMICOLON
                       | TOKINTERFACE VAR EQUAL expression SEMICOLON'''

def p_bviMethodAttributes(p):
    '''bviMethodAttributes :
                           | bviMethodAttributes bviMethodAttribute'''
def p_bviMethodAttribute(p):
    '''bviMethodAttribute :
                          | TOKENABLE LPAREN instanceAttributes VAR RPAREN
                          | TOKCLOCKED_BY LPAREN instanceAttributes VAR RPAREN
                          | TOKRESET_BY LPAREN instanceAttributes VAR RPAREN'''

def p_bviMethodDef(p):
    '''bviMethodDef : TOKMETHOD VAR LPAREN VAR RPAREN bviMethodAttributes SEMICOLON
                    | TOKMETHOD VAR VAR LPAREN RPAREN bviMethodAttributes SEMICOLON'''

def p_instanceDeclStmt(p):
    '''instanceDeclStmt : varAssign SEMICOLON
                        | functionDef
                        | moduleDef'''
    p[0] = p[1]

def p_instanceDeclStmts(p):
    '''instanceDeclStmts : 
                         | instanceDeclStmt
                         | instanceDeclStmts instanceDeclStmt'''

def p_instanceDecl(p):
    '''instanceDecl : TOKINSTANCE VAR HASH LPAREN typeParams RPAREN provisos SEMICOLON instanceDeclStmts TOKENDINSTANCE'''
    p[0] = AST.TypeclassInstance(p[2], p[5], p[7], p[9])

def p_typeClassDeclStmts(p):
    '''typeClassDeclStmts : 
                          | moduleDefHeader'''

def p_typeClassDecl(p):
    '''typeClassDecl : TOKTYPECLASS VAR HASH LPAREN interfaceFormalParams RPAREN provisos SEMICOLON typeClassDeclStmts TOKENDTYPECLASS'''
    p[0] = AST.Typeclass(p[2])

globalimports = []
globalfilename = None

def p_packageStmt(p):
    '''packageStmt : interfaceDecl
                   | typeClassDecl
                   | functionDef
                   | instanceDecl
                   | varDecl SEMICOLON
                   | varAssign SEMICOLON
                   | moduleDef
                   | macroDef
                   | typeDef
                   | importBviDef'''
    globalv.add_new(p[1])

def p_packageStmts(p):
    '''packageStmts :
                    | packageStmts packageStmt exportDecls'''

def p_beginPackage(p):
    '''beginPackage :
                    | TOKPACKAGE VAR SEMICOLON'''

def p_endPackage(p):
    '''endPackage :
                  | TOKENDPACKAGE colonVar'''

def p_package(p):
    '''package : beginPackage exportDecls importDecls packageStmts exportDecls endPackage'''
    p[0] = p[4]

def syntax_parse(argdata, inputfilename, bsvdefines, bsvpath):
    global globalfilename
    globalfilename = inputfilename
    data = bsvpreprocess.preprocess(inputfilename, argdata + '\n', bsvdefines, bsvpath)
    lexer = lex.lex(errorlog=lex.NullLogger())
    parserdir=scripthome+'/syntax'
    if not os.path.isdir(parserdir):
        os.makedirs(parserdir)
    if not (parserdir in sys.path):
        sys.path.append(parserdir)
    parser = yacc.yacc(optimize=1,errorlog=yacc.NullLogger(),outputdir=parserdir,debugfile=parserdir+'/parser.out')
    if noisyFlag:
        print('Parsing:', inputfilename)
    if parseDebugFlag:
        return parser.parse(data,debug=1)
    return  parser.parse(data)

def generate_bsvcpp(filelist, project_dir, bsvdefines, interfaces, bsvpath):
    for inputfile in filelist:
        syntax_parse(open(inputfile).read(), inputfile, bsvdefines, bsvpath)
    ## code generation pass
    ilist = []
    for i in interfaces:
        ifc = globalv.globalvars.get(i)
        if not ifc:
            print('Connectal: Unable to locate the interface:', i)
            for keys in globalv.globalvars:
                print('    ', keys)
            sys.exit(1)
        ifc = ifc.instantiate(dict(zip(ifc.params, ifc.params)))
        ilist.append(ifc)
        for ditem in ifc.decls:
            for pitem in ditem.params:
                thisType = pitem.type
                p = globalv.globalvars.get(thisType.name)
                if p and thisType.params and p.params:
                    myName = '%sL_%s_P' % (thisType.name, '_'.join([t.name for t in thisType.params if t]))
                    pitem.oldtype = pitem.type
                    pitem.type = AST.Type(myName, [])
                    if not globalv.globalvars.get(myName):
                        globalv.add_new(AST.TypeDef(p.tdtype.instantiate(dict(zip(p.params, thisType.params))), myName, []))
    jsondata = AST.serialize_json(ilist, globalimports, bsvdefines)
    if project_dir:
        cppgen.generate_cpp(project_dir, noisyFlag, jsondata)
        bsvgen.generate_bsv(project_dir, noisyFlag, False, jsondata)
    
if __name__=='__main__':
    if len(sys.argv) == 1:
        parserdir=scripthome+'/syntax'
        sys.path.append(parserdir)
        if not os.path.isdir(parserdir):
            os.makedirs(parserdir)
        parser = yacc.yacc(outputdir=parserdir,debugfile=parserdir+'/parser.out')
        import parsetab
        sys.exit(0)
    ifitems = []
    t = os.environ.get('INTERFACES')
    if t:
        t = t.split()
        for item in t:
            if item not in ifitems:
                ifitems.append(item)
    deflist = []
    t = os.environ.get('BSVDEFINES_LIST')
    if t:
        deflist = t.split()
    noisyFlag = os.environ.get('D') == '1'
    if os.environ.get('D'):
        parseDebugFlag=True
    if noisyFlag:
        parseTrace=True
    project_dir =  os.environ.get('DTOP')
    tmp = os.environ.get('PROTODEBUG')
    if tmp:
        print('JSONNN', tmp)
        j2file = open(tmp).read()
        jsondata = json.loads(j2file)
        cppgen.generate_cpp(project_dir, noisyFlag, jsondata)
        bsvgen.generate_bsv(project_dir, noisyFlag, True, jsondata)
    else:
        bsvpath = os.environ.get('BSVPATH', []).split(':')
        generate_bsvcpp(sys.argv[1:], project_dir, deflist, ifitems, bsvpath)

