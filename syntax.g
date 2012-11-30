globalvars = {}       # We will store the calculator's variables here
globaldecls = []      # sorted by declaration order
def lookup(map, name):
    #print "lookup", map, name
    for x, v in map:
        if x == name: return v
    if not globalvars.has_key(name):
        #print 'Undefined (defaulting to 0):', name
        pass
    return globalvars.get(name, 0)

def define(decl):
    globalvars[decl.name] = decl
    globaldecls.append(decl)

from AST import *

%%
parser HSDL:
    #option:      "context-insensitive-scanner"

    token ENDTOKEN: " "
    token LPAREN: "("
    token RPAREN: ")"
    token TOKAMPERAMPERAMPER: "&&&"
    token TOKAMPERAMPER: "&&"
    token TOKAMPER: '&'
    token TOKBARBAR: "||"
    token TOKBAR: "|"
    token COLON: ':'
    token SEMICOLON: ';'
    token QUESTION: "?"
    token CARET: "^"
    token TOKTILDE: "~"
    token LESSLESS: "<<"
    token LEQ: "<="
    token LARROW: "<-"
    token LESS: "<"
    token GREATERGREATER: ">>"
    token GEQ: ">="
    token TOKGREATER: ">"
    token EQEQ: "=="
    token EQUAL: "="
    token STARSTAR: "**"
    token STAR: "*"
    token TOKNOTEQUAL: "!="
    token TOKEXCLAIM: "!"
    token TOKMINUS: "-"
    token TOKPERCENT: "%"
    token TOKPLUS: "+"
    token TOKSLASH: "/"
    token LBRACKET: "["
    token RBRACKET: "]"
    token LBRACE: "{"
    token RBRACE: "}"
    token APOSTROPHE: "'"
    token DOT: "."
    token COMMA: ','

    token TOKOPPLUS: '\\+'
    token TOKOPMINUS: '\\-'
    token TOKOPTILDECARET: '\\~^'
    token TOKOPCARETTILDE: '\\^~'
    token TOKOPCARET: '\\^'
    token TOKOPSLASH: '\\/'
    token TOKOPAMPERAMPER: '\\&&'
    token TOKOPAMPER: '\\&'
    token TOKOPBAR: '\\|'
    token TOKOPPERCENT: '\\%'
    token TOKOPLESSLESS: '\\<<'
    token TOKOPLEQ: '\\<='
    token TOKOPLESS: '\\<'
    token TOKOPGREATERGREATER: '\\>>'
    token TOKOPGEQ: '\\>='
    token TOKOPGREATER: '\\>'
    token TOKOPEQUALEQUAL: '\\=='
    token TOKOPSTARSTAR: '\\**'
    token TOKOPSTAR: '\\*'

    token TOKBDPI: '"BDPI"'
    token TOKBVI: '"BVI"'

    token NUM: " "
    token STR:   " "
    token VAR: " "
    token TYPEVAR: " "
    token CLASSVAR: " " 
    token BUILTINVAR: " "

    token TOKACTIONSTATEMENT: "action"
    token TOKACTIONVALUESTATEMENT: "actionvalue"
    token TOKBEGIN: "begin"
    token TOKBITS: "Bits"
    token TOKBOUNDED: "Bounded"
    token TOKC: "C"
    token TOKCASE: "case"
    token TOKCF: "CF"
    token TOKCLOCKED_BY: "clocked_by"
    token TOKDEFAULT: "default"
    token TOKDEFAULT_CLOCK: "default_clock"
    token TOKDEFAULT_RESET: "default_reset"
    token TOKDEPENDENCIES: "dependencies"
    token TOKDERIVING: "deriving"
    token TOKDETERMINES: "determines"
    token TOKELSE: "else"
    token TOKENABLE: "enable"
    token TOKEND: "end"
    token TOKENDACTION: "endaction"
    token TOKENDACTIONVALUE: "endactionvalue"
    token TOKENDCASE: "endcase"
    token TOKENDFUNCTION: "endfunction"
    token TOKENDINSTANCE: "endinstance"
    token TOKENDINTERFACE: "endinterface"
    token TOKENDMETHOD: "endmethod"
    token TOKENDMODULE: "endmodule"
    token TOKENDPACKAGE: "endpackage"
    token TOKENDPAR: "endpar"
    token TOKENDRULE: "endrule"
    token TOKENDRULES: "endrules"
    token TOKENDSEQ: "endseq"
    token TOKENDTYPECLASS: "endtypeclass"
    token TOKENUM: "enum"
    token TOKEQ: "Eq"
    token TOKEXPORT: "export"
    token TOKFOR: "for"
    token TOKFUNCTION: "function"
    token TOKIF: "if"
    token TOKIMPORT: "import"
    #token TOKIN: "in"
    token TOKINPUT_CLOCK: "input_clock"
    token TOKINPUT_RESET: "input_reset"
    token TOKINSTANCE: "instance"
    token TOKINTERFACE: "interface"
    token TOKLET: "let"
    token TOKMATCH: "match"
    token TOKMATCHES: "matches"
    token TOKMETHOD: "method"
    token TOKMODULE: "module"
    token TOKNO_RESET: "no_reset"
    token TOKNUMERIC: "numeric"
    token TOKOUTPUT_CLOCK: "output_clock"
    token TOKOUTPUT_RESET: "output_reset"
    token TOKPACKAGE: "package"
    token TOKPAR: "par"
    token TOKPARAMETER: "parameter"
    token TOKPROVISOS: "provisos"
    token TOKREADY: "ready"
    token TOKRESET_BY: "reset_by"
    token TOKRETURN: "return"
    token TOKRULE: "rule"
    token TOKRULES: "rules"
    token TOKSB: "SB"
    token TOKSBR: "SBR"
    token TOKSCHEDULE: "schedule"
    token TOKSEQ: "seq"
    token TOKSTRUCT: "struct"
    token TOKTAGGED: "tagged"
    token TOKTYPE: "type"
    token TOKTYPECLASS: "typeclass"
    token TOKTYPEDEF: "typedef"
    token TOKUNION: "union"
    token TOKWHILE: "while"

############################################################################
############################# Datatypes ####################################
############################################################################

    rule type_decl:
        ( typevar_item
        | CLASSVAR typevar_item
        ) {{ return typevar_item}}
 [ LBRACKET NUM (COLON NUM)* RBRACKET ]

    rule formal_item:
        ( function_parameter {{return function_parameter}}
        | type_decl {{item_name=None}} [ item_name ] {{return Param(item_name, type_decl)}}
        )

    rule param_item: 
        (   LPAREN param_item {{pi=param_item}} RPAREN
        |   ( [ TOKNUMERIC | TOKPARAMETER ] TOKTYPE VAR {{pi=VAR}}
            | formal_item {{pi=formal_item}}
            | NUM {{pi=NUM}}
            | STR {{pi=STR}}
            )
            [ VAR ]
            [ typevar_param_list ]
        ) {{return pi}}

    rule typevar_param_list:
        LPAREN {{tlist=[]}} [ param_item {{tlist.append(param_item)}} (COMMA param_item {{tlist.append(param_item)}} )* ] RPAREN {{return tlist}}

    rule typevar_item:
        TYPEVAR {{typevar_param_list=[]}} [ typevar_param_list ] {{ return Type(TYPEVAR, typevar_param_list) }}

    rule Type_list:
        ( type_decl
        | LPAREN type_decl (COMMA type_decl)* RPAREN
        )

    rule enum_element: {{q=[]; v=None}}
        TYPEVAR
        [LBRACKET NUM {{q.append(NUM)}} [ COLON NUM {{q.append(NUM)}} ] RBRACKET ]
        [EQUAL NUM {{v=NUM}}] {{return EnumElement(TYPEVAR,q,v)}}

    rule enum_declaration: {{elts=[]}}
        TOKENUM LBRACE enum_element {{elts.append(enum_element)}}
                       [ ( ( COMMA enum_element {{elts.append(enum_element)}} )+ ) ] 
                RBRACE {{ return Enum(None, elts)}}

    rule deriving_type_class:
        TOKEQ | TOKBITS | TOKBOUNDED

    rule struct_member:
        typevar_item VAR SEMICOLON {{ return StructMember(typevar_item, VAR) }}

    rule struct_declaration:
        TOKSTRUCT {{elts=[]}}
                LBRACE
                    ( struct_member {{elts.append(struct_member)}} )*
                RBRACE {{return Struct(None, elts) }}

    rule union_member:
        ( typevar_item VAR
        | struct_declaration VAR
        | union_declaration VAR) SEMICOLON

    rule union_declaration:
	    TOKUNION TOKTAGGED {{elts=[]}}
                LBRACE
                    ( union_member )*
                RBRACE {{return Union(None, elts)}}

    rule single_type_definition:
        (   Type_list [ type_decl | TOKENABLE ]
        |   ( enum_declaration {{t=enum_declaration}}
            | struct_declaration {{t=struct_declaration}}
            | union_declaration {{t=union_declaration}}
            ) typevar_item {{t.name=typevar_item}}
            [ TOKDERIVING  LPAREN deriving_type_class ( COMMA deriving_type_class )* RPAREN ] 
        ) SEMICOLON {{return t}}

    rule formal_list: {{fl=[]}}
        LPAREN [ formal_item {{fl.append(formal_item)}} ( COMMA formal_item {{fl.append(formal_item)}})* ] RPAREN {{return fl}}

    rule function_argument:
        ( typevar_item
        | LPAREN function_argument (COMMA function_argument)* RPAREN
        )
        [VAR [ formal_list ] ]

    rule function_parameter:
        TOKFUNCTION function_argument

############################################################################
############################# Expressions ##################################
############################################################################

    rule dot_item:
        DOT (VAR | STAR)

    rule dot_field_item:
        [ VAR COLON ] dot_item

    rule dot_field_list:
        dot_item
        | NUM
        | VAR
        | LBRACE dot_field_item (COMMA dot_field_item)* RBRACE

    rule tagged_dot_list:
        TOKTAGGED TYPEVAR
        [
            (dot_field_list
            | LPAREN
                ( dot_field_list
                | tagged_dot_list
                )
                RPAREN
            )
        ]

    rule matches_clause:
        ( tagged_dot_list
        | LPAREN tagged_dot_list RPAREN
        | LBRACE
             ( tagged_dot_list (COMMA tagged_dot_list)*
             | dot_field_item (COMMA dot_field_item)*
             ) RBRACE
        | TOKDEFAULT
        | NUM
        | VAR
        )

    rule expr<<V>>:
         exprint<<V>>
             [ QUESTION assign_rvalue COLON assign_rvalue ]
             {{return exprint}}

    # An expression is the sum and difference of factors
    rule exprint<<V>>:
        factor<<V>>         {{ n = factor }}
        (  TOKPLUS factor<<V>>
        |  TOKMINUS  factor<<V>>
        )* {{ return n }}

    # A factor is the product and division of terms
    rule factor<<V>>: nterm<<V>>           {{ v = nterm }}
        (  STAR nterm<<V>>
        |  STARSTAR nterm<<V>>
        |  APOSTROPHE nterm<<V>>
        |  TOKSLASH  nterm<<V>>
        |  CARET  nterm<<V>>
        |  LESS  nterm<<V>>
        |  TOKGREATER  nterm<<V>>
        |  GEQ  nterm<<V>>
        |  LESSLESS  nterm<<V>>
        #gets confused with assignment |  LEQ  nterm<<V>>
        |  GREATERGREATER  nterm<<V>>
        |  EQEQ  nterm<<V>>
        |  TOKNOTEQUAL  nterm<<V>>
        |  TOKAMPER  nterm<<V>>
        |  TOKAMPERAMPER  assign_rvalue
        |  TOKAMPERAMPERAMPER  nterm<<V>>
        |  TOKBAR  nterm<<V>>
        |  TOKBARBAR  nterm<<V>>
        |  TOKMATCHES matches_clause
        |  TOKPERCENT  nterm<<V>>
        )*  {{ return v }}

    rule nterm<<V>>:
        [ (TOKEXCLAIM | TOKTILDE | TOKMINUS | TOKBAR) ] term<<V>> {{ return term }}

    rule call_pitem:
        [ TOKCLOCKED_BY | TOKRESET_BY ] assign_rvalue

    rule call_params:
        LPAREN [ call_pitem ( COMMA call_pitem )* ] RPAREN

    rule item_name:
        ( VAR {{return VAR}} | TOKREADY {{return 'ready'}} | TOKENABLE {{ return 'enable'}})

    rule term_single:
        CLASSVAR* ( item_name | typevar_item)
        ( call_params
        | LBRACE [ VAR COLON assign_rvalue ( COMMA VAR COLON assign_rvalue )* ] RBRACE
        )*

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term<<V>>:
        (    NUM
        |    (TOKTAGGED TYPEVAR)+ [term_single]
        |    BUILTINVAR [ param_list ]
        |    term_single
        |    STR {{ return STR }}
        |    paren_expression
        |    LBRACE assign_rvalue ( COMMA assign_rvalue )* RBRACE
        )
        (    LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET
        |    DOT VAR [ call_params ]
        )*

    rule assign_rvalue:
        ( statement_yielding_value
        | interface_declaration
        | TOKRULES [ COLON  VAR]
            ( rule_statement )*
            TOKENDRULES [ COLON  VAR]
        | function_parameter
        | function_operator [expr<<[]>>]
        | expr<<[]>> ( LEQ expr<<[]>> )* [expr<<[]>>]
        | QUESTION
        )
        # values like "(OP_Reg Reg_Normal data)" are allowed
        ( expr<<[]>> )*

    rule assign_opvalue:
        ( EQUAL | LEQ | LARROW ) assign_rvalue

    rule equal_value:
        EQUAL assign_rvalue

    rule function_operator:
        TOKOPPLUS | TOKOPMINUS | TOKOPSTAR
        | TOKOPCARET | TOKOPCARETTILDE | TOKOPTILDECARET
        | TOKOPSLASH
        | TOKOPAMPERAMPER | TOKOPAMPER
        | TOKOPBAR
        | TOKOPPERCENT
        | TOKOPLESS | TOKOPLESSLESS | TOKOPLEQ
        | TOKOPGREATER | TOKOPGREATERGREATER | TOKOPGEQ
        | TOKOPEQUALEQUAL
        | TOKOPSTARSTAR

    rule function_name:
        VAR | function_operator

    rule var_list_elem:
        VAR (DOT VAR)*

    rule var_list:
        LPAREN [var_list_elem (COMMA var_list_elem)*] RPAREN

    rule paren_expression:
        LPAREN [ assign_rvalue ] RPAREN

    rule param_list:
        LPAREN [ assign_rvalue (COMMA assign_rvalue)* ] RPAREN

    rule provisos_clause:
        TOKPROVISOS param_list

############################################################################
############################# Statements ###################################
############################################################################

    rule for_decl_item:
        # datatype might not be present
        type_decl [ VAR ] assign_opvalue

    rule for_variable_assignment:
        term<<[]>> assign_opvalue

    rule declared_item:
        term<<[]>> [ assign_opvalue ] {{ return term }}

    rule rule_statement:
        TOKRULE VAR {{ruleid=VAR}}[paren_expression] [TOKIF paren_expression] SEMICOLON
        statement_list
        TOKENDRULE [ COLON  VAR ] {{ return 'rule: ' + ruleid }}

    rule match_arg:
        DOT ( term<<[]>> | STAR )
        | match_brace

    rule match_brace:
        LBRACE match_arg (COMMA match_arg)* RBRACE

    rule statement_yielding_value:
          TOKBEGIN statement_list TOKEND
        | TOKSEQ statement_list TOKENDSEQ
        | TOKACTIONSTATEMENT [ COLON  VAR] [ SEMICOLON ]
            statement_list
            TOKENDACTION [ COLON VAR]
        | TOKACTIONVALUESTATEMENT statement_list TOKENDACTIONVALUE
        ## | TOKCASE paren_expression
        ##     ( TOKMATCHES
        ##       (   matches_clause
        ##           COLON (QUESTION SEMICOLON | single_statement)
        ##       )*
        ##     | (
        ##           (expr<<[]>> (COMMA expr<<[]>>)*
        ##           | TOKDEFAULT
        ##           )
        ##           COLON (QUESTION SEMICOLON | single_statement)
        ##       )*
        ##     )
        ##     TOKENDCASE

    rule statement_or_declaration:
          TOKFUNCTION [ Type_list ]
            [function_name]
            [ formal_list ]
            [ provisos_clause ]
            ( equal_value SEMICOLON
            | SEMICOLON [ ( single_statement)+ TOKENDFUNCTION [ COLON  function_name] ]
            )
        | ( TOKLET ( VAR | LBRACE VAR (COMMA VAR)* RBRACE) assign_opvalue
          | typevar_item declared_item ( COMMA declared_item )*
          ) SEMICOLON
        | rule_statement {{ return rule_statement }}

    rule single_statement_no_declaration:
          TOKFOR LPAREN
                for_decl_item (COMMA for_decl_item)* SEMICOLON
                assign_rvalue SEMICOLON
                for_variable_assignment ( COMMA for_variable_assignment )*
            RPAREN
            single_statement
        | TOKIF paren_expression single_statement [ TOKELSE single_statement ]
#        | TOKMATCH ( TOKTAGGED TYPEVAR dot_field_list | match_brace ) assign_opvalue SEMICOLON
        | TOKPAR statement_list TOKENDPAR
        | TOKRETURN assign_rvalue SEMICOLON
        | TOKWHILE paren_expression ( statement_yielding_value | VAR SEMICOLON)
        | statement_yielding_value

    rule single_statement:
          statement_or_declaration
        | single_statement_no_declaration

    rule statement_list:
        ( single_statement )*

############################################################################
############################# Declarations #################################
############################################################################

    rule method_declaration: {{methodid=None; formal_list=[]}}
        TOKMETHOD type_decl [ VAR {{methodid=VAR}}] [ formal_list [VAR] ]
        ( ( TOKIF | TOKCLOCKED_BY | TOKRESET_BY | TOKENABLE | TOKREADY) paren_expression )*
        [ equal_value ]
        [ provisos_clause ] SEMICOLON
        [
            (   ( single_statement )+ TOKENDMETHOD [ COLON VAR]
            |   TOKENDMETHOD [ COLON VAR]
            )
        ] {{ return Method(methodid, type_decl, formal_list) }}

    rule interface_declaration: {{ interfaceid = "" }}
        TOKINTERFACE ( CLASSVAR {{ print CLASSVAR; interfaceid = interfaceid + CLASSVAR }} )* 
        TYPEVAR {{ interfaceid = TYPEVAR; interfacevalue=[]; var=None }} [ VAR {{print VAR; var=VAR}} ]
            ( equal_value
            | [ SEMICOLON ]
                ( method_declaration {{ interfacevalue.append(method_declaration) }}
                | TOKINTERFACE {{subinterfaceid=""}} ( CLASSVAR {{ print CLASSVAR; subinterfaceid = subinterfaceid + CLASSVAR }} )* 
                  TYPEVAR {{ subinterfaceid = TYPEVAR }} VAR {{subvar=VAR}} SEMICOLON
                  {{interfacevalue.append(Interface(subinterfaceid, [], subvar))}}
                )*
                TOKENDINTERFACE [ COLON VAR ]
            ) {{ i=Interface(interfaceid, interfacevalue, var); return i }}

    rule import_arg:
        ( VAR | var_list )

    rule dep_item:
        VAR TOKDETERMINES VAR

    rule single_declaration:
          interface_declaration [SEMICOLON] {{ i=interface_declaration; define(i); return i }}
        | statement_or_declaration {{ return statement_or_declaration }}
        | method_declaration {{ return method_declaration }}
        | TOKMODULE [ LBRACKET assign_rvalue RBRACKET ] VAR {{ print VAR; moduleid = VAR; modulevalue = [] }}
            [ typevar_param_list ]
            [ provisos_clause ] SEMICOLON
            [
                ( TOKENDMODULE [ COLON VAR]
                | ( single_statement_no_declaration {{ modulevalue.append(single_statement_no_declaration) }}
                   | single_declaration {{ modulevalue.append(single_declaration) }})+
                  TOKENDMODULE [ COLON VAR]
                )
            ] {{ m=Module(moduleid, modulevalue); define(m); return m}}
        | TOKTYPEDEF ( single_type_definition ) {{t=single_type_definition; define(t)}}
        | TOKIMPORT
            ( CLASSVAR STAR SEMICOLON
            | SEMICOLON
            | TOKBDPI [ VAR  EQUAL ]
                TOKFUNCTION typevar_item
                function_name
                formal_list
                [ provisos_clause ] SEMICOLON
            | TOKBVI [ VAR [ EQUAL ] ]
                TOKMODULE typevar_item
                [ formal_list ]
                [ provisos_clause ] SEMICOLON
                ( method_declaration
                | interface_declaration [SEMICOLON]
                | TOKPARAMETER VAR  equal_value SEMICOLON
                | TOKDEFAULT_CLOCK [ VAR ] [ var_list ] [ equal_value ] SEMICOLON
                | TOKINPUT_CLOCK [VAR] var_list equal_value SEMICOLON
                | TOKOUTPUT_CLOCK VAR var_list SEMICOLON
                | TOKNO_RESET SEMICOLON
                | TOKSCHEDULE import_arg ( TOKCF | TOKSB | TOKSBR | TOKC ) import_arg SEMICOLON
                | TOKDEFAULT_RESET VAR var_list  [ equal_value ] SEMICOLON
                | TOKINPUT_RESET [ VAR ] var_list [ TOKCLOCKED_BY var_list ] equal_value SEMICOLON
                | TOKOUTPUT_RESET VAR var_list TOKCLOCKED_BY var_list SEMICOLON
                )*
                TOKENDMODULE [ COLON  VAR ]
            )
        | TOKEXPORT VAR [ LPAREN DOT DOT RPAREN ] SEMICOLON
        | TOKINSTANCE typevar_item
            [ provisos_clause ] SEMICOLON
            ( single_declaration )*
            TOKENDINSTANCE [ COLON VAR ]
        | TOKTYPECLASS typevar_item
            [ TOKDEPENDENCIES LPAREN dep_item (COMMA dep_item)* RPAREN ]
            SEMICOLON
            ( single_declaration )*
            TOKENDTYPECLASS [ COLON VAR ]

    rule goal:
        ( single_declaration
        | TOKPACKAGE VAR SEMICOLON ( single_declaration )* TOKENDPACKAGE [ COLON  VAR]
        )* ENDTOKEN {{ return globalvars }}

%%
import string
import newrt

if __name__=='__main__':
    if len(sys.argv) > 2:
        newrt.printtrace = True
    s = open(sys.argv[1]).read() + '\n'
    s1 = parse('goal', s)
