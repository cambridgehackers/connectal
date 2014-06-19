#!/usr/bin/python
import ply.lex as lex
import AST
import sys
import os

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
    'parameter': 'TOKPARAMETER',
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
t_NUM = r'(([0-9]+\'?)|(\'))[bdh\.]?[0-9a-zA-Z]*'
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
    print "Illegal character '%s' in file '%s'" % (t.value[0], globalfilename)
    t.lexer.skip(1)

def t_VAR(t):
    r'`?[a-zA-Z_][$a-zA-Z0-9_]*'
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
    #print t.value, t.value.count('\n'), t.lineno
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

def p_type(p):
    '''type : VAR
            | NUM
            | VAR HASH LPAREN typeParams RPAREN'''
    if len(p) == 2:
        p[0] = AST.Type(p[1], [])
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
    '''expression : binaryExpression'''

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
                       | TOKACTION colonVar expressionStmts TOKENDACTION colonVar'''

def p_term(p):
    '''term : NUM
            | STR
            | VAR
            | VAR COLONCOLON VAR
            | QUESTION
            | term QUESTION expression
            | term QUESTION expression COLON expression
            | LPAREN expression RPAREN
            | TOKINTERFACE VAR SEMICOLON expressionStmts TOKENDINTERFACE colonVar
            | TOKINTERFACE VAR expressionStmts TOKENDINTERFACE colonVar
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
            | term LBRACKET expression RBRACKET
            | term LBRACKET expression COLON expression RBRACKET
            | term LPAREN expressions RPAREN'''

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
               | DOT STAR'''

def p_patterns(p):
    '''patterns : pattern
                | patterns COMMA pattern'''

def p_importDecl(p):
    'importDecl : TOKIMPORT VAR COLONCOLON STAR SEMICOLON'
    #globalimports.append(p[2])
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
                            | TOKNUMERIC TOKTYPE VAR'''
    if len(p) == 3:
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

def p_subinterfaceDecl(p):
    '''subinterfaceDecl : TOKINTERFACE type VAR SEMICOLON
                        | type VAR SEMICOLON'''
    if len(p) == 5:
        name = p[3]
        t = p[2]
    else:
        name = p[2]
        t = p[1]
    p[0] = AST.Interface(t.name, t.params, [], name, globalfilename) 

def p_parenthesizedFormalParams(p):
    '''parenthesizedFormalParams : 
                                 |  LPAREN moduleFormalParams RPAREN'''
    if len(p) == 1:
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

def p_varDecl(p):
    '''varDecl : type VAR'''
    p[0] = AST.Variable(p[2], p[1])
    

def p_lvalue(p):
    '''lvalue : VAR
              | LPAREN lvalue RPAREN
              | lvalue DOT VAR
              | lvalue LBRACKET expression RBRACKET
              | lvalue LBRACKET expression COLON expression RBRACKET
              | TOKMATCH pattern '''

def p_varAssign(p):
    '''varAssign : TOKLET VAR EQUAL expression
                 | TOKLET VAR LARROW expression
                 | type VAR EQUAL expression
                 | type VAR LBRACKET expression RBRACKET EQUAL expression
                 | type VAR LBRACKET expression RBRACKET LBRACKET NUM RBRACKET EQUAL expression
                 | type VAR LARROW expression
                 | lvalue EQUAL expression
                 | lvalue LEQ expression
                 | lvalue LARROW expression'''
    p[0] = AST.Variable(p[2], p[1])

def p_ruleCond(p):
    '''ruleCond : LPAREN expression RPAREN'''

def p_implicitCond(p):
    '''implicitCond :
                    | TOKIF LPAREN expression RPAREN'''

def p_rule(p):
    '''rule : TOKRULE VAR implicitCond SEMICOLON expressionStmts TOKENDRULE colonVar
            | TOKRULE VAR ruleCond implicitCond SEMICOLON expressionStmts TOKENDRULE colonVar'''

def p_ifStmt(p):
    '''ifStmt : TOKIF LPAREN expression RPAREN expressionStmt
              | TOKIF LPAREN expression RPAREN expressionStmt TOKELSE expressionStmt'''

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
    '''forStmt : TOKFOR LPAREN varAssign SEMICOLON expression SEMICOLON varAssign RPAREN expressionStmt'''

def p_whenStmt(p):
    '''whenStmt : TOKWHEN LPAREN expression RPAREN LPAREN expression RPAREN SEMICOLON'''

def p_beginStmt(p):
    '''beginStmt : TOKBEGIN expressionStmts TOKEND'''

def p_expressionStmt(p):
    '''expressionStmt : TOKRETURN expression SEMICOLON
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
                      | interfaceDef
                      | functionDef
                      | methodDef
                      | moduleDef
                      | TOKACTION colonVar expressionStmts TOKENDACTION colonVar
                      | typeDef
                      | instanceAttributes rule
                      | TOKSEQ fsmStmts TOKENDSEQ'''

def p_expressionStmts(p):
    '''expressionStmts : expressionStmts expressionStmt
                       | expressionStmt '''

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
    '''functionFormal : type VAR'''

def p_functionFormals(p):
    '''functionFormals :
                       | functionFormal
                       | functionFormals COMMA functionFormal '''
def p_fsmStmt(p):
    '''fsmStmt : TOKSEQ fsmStmts TOKENDSEQ
               | TOKWHILE ruleCond fsmStmt
               | expressionStmt'''

def p_fsmStmts(p):
    '''fsmStmts : fsmStmt fsmStmts
                | fsmStmt'''

def p_fsmStmtDef(p):
    '''fsmStmtDef : TOKSTMT VAR EQUAL fsmStmts SEMICOLON'''

def p_functionDef(p):
    '''functionDef : instanceAttributes TOKFUNCTION type VAR LPAREN functionFormals RPAREN provisos functionBody
                   | instanceAttributes TOKFUNCTION type VAR LPAREN functionFormals RPAREN provisos functionValue'''
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
    p[0] = p[1]

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

def p_vars(p):
    '''vars : VAR
            | vars COMMA VAR'''
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
    p[0] = AST.TypeDef(p[2], p[3])


def p_interfaceDef(p):
    '''interfaceDef : TOKINTERFACE type VAR SEMICOLON expressionStmts TOKENDINTERFACE colonVar
                    | TOKINTERFACE type VAR EQUAL expression SEMICOLON
                    | TOKINTERFACE VAR EQUAL expression SEMICOLON'''

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
                 | attrSpecs attrSpec'''

def p_instanceAttributes(p):
    '''instanceAttributes :
                          | instanceAttributes LPARENSTAR attrSpecs RPARENSTAR'''

def p_moduleContext(p):
    '''moduleContext : 
                     | LBRACKET VAR RBRACKET'''
    if len(p) > 2:
        p[0] = p[2]

def p_moduleDef(p):
    '''moduleDef : instanceAttributes TOKMODULE moduleContext VAR moduleParamsArgs provisos SEMICOLON expressionStmts TOKENDMODULE colonVar'''
    p[0] = AST.Module(p[3], p[4], p[5][0], p[5][1], p[6], p[8])

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
    '''typeClassDeclStmts : '''

def p_typeClassDecl(p):
    '''typeClassDecl : TOKTYPECLASS VAR HASH LPAREN interfaceFormalParams RPAREN provisos SEMICOLON typeClassDeclStmts TOKENDTYPECLASS'''
    p[0] = AST.Typeclass(p[2])

globaldecls = []
globalvars = {}
globalimports = []
globalfilename = []

def p_packageStmt(p):
    '''packageStmt : interfaceDecl
                   | typeClassDecl
                   | functionDef
                   | instanceDecl
                   | varDecl SEMICOLON
                   | varAssign SEMICOLON
                   | moduleDef
                   | macroDef
                   | typeDef'''
    decl = p[1]
    globaldecls.append(decl)
    globalvars[decl.name] = decl

def p_packageStmts(p):
    '''packageStmts :
                    | packageStmts packageStmt'''

def p_beginPackage(p):
    '''beginPackage :
                    | TOKPACKAGE VAR SEMICOLON'''

def p_endPackage(p):
    '''endPackage :
                  | TOKENDPACKAGE colonVar'''

def p_package(p):
    '''package : beginPackage exportDecls importDecls packageStmts endPackage'''
    p[0] = p[4]

if 0:
    data = open('/home/jamey/bluespec/zedboard_axi_blue/pcores/hdmidisplay_v1_00_a/hdl/verilog/HdmiDisplayWrapper.bsv').read()
    lexer.input(data)
    for tok in lexer:
        print tok

def parse(data, inputfilename):
    global globalfilename
    lexer = lex.lex(errorlog=lex.NullLogger())
    parser = yacc.yacc(optimize=1,errorlog=yacc.NullLogger())
    globalfilename = [inputfilename]
    print 'Parsing:', inputfilename
    return  parser.parse(data)
    
if __name__=='__main__':
    lexer = lex.lex()
    parser = yacc.yacc()
    for f in sys.argv[1:]:
        data = open(f).read()
        print f
        result = parser.parse(data)
        parser.restart()
        lexer = lex.lex()
