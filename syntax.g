globalvars = {}       # We will store the calculator's variables here
def lookup(map, name):
    #print "lookup", map, name
    for x, v in map:
        if x == name: return v
    if not globalvars.has_key(name):
        #print 'Undefined (defaulting to 0):', name
        pass
    return globalvars.get(name, 0)

%%
parser HSDL:
    #option:      "context-insensitive-scanner"

    token ENDTOKEN: " "
    token TOKLPARENSTAR: " (*"
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
    token TOKSTARRPAREN: " *)"
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

    token TOKACTION: "Action"
    token TOKACTIONSTATEMENT: "action"
    token TOKACTIONVALUE: "ActionValue"
    token TOKACTIONVALUESTATEMENT: "actionvalue"
    token TOKBEGIN: "begin"
    token TOKBITS: "Bits"
    token TOKBOOL: "Bool"
    token TOKBOUNDED: "Bounded"
    token TOKC: "C"
    token TOKCASE: "case"
    token TOKCF: "CF"
    token TOKCLK: "CLK"
    token TOKCLOCKED_BY: "clocked_by"
    token TOKDEFAULT: "default"
    token TOKDEFAULT_CLOCK: "default_clock"
    token TOKDEFAULT_RESET: "default_reset"
    token TOKDEPENDENCIES: "dependencies"
    token TOKDERIVING: "deriving"
    token TOKDETERMINES: "determines"
    token TOKDOC: "doc"
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
    token TOKIN: "in"
    token TOKINPUT_CLOCK: "input_clock"
    token TOKINPUT_RESET: "input_reset"
    token TOKINSTANCE: "instance"
    token TOKINTEGER: "Integer"
    token TOKINTERFACE: "interface"
    token TOKLET: "let"
    token TOKMATCH: "match"
    token TOKMATCHES: "matches"
    token TOKMETHOD: "method"
    token TOKMODULE: "module"
    token TOKNAT: "Nat"
    token TOKNO_RESET: "no_reset"
    token TOKNUMERIC: "numeric"
    token TOKOUTPUT_CLOCK: "output_clock"
    token TOKOUTPUT_RESET: "output_reset"
    token TOKPACKAGE: "package"
    token TOKPAR: "par"
    token TOKPARAMETER: "parameter"
    token TOKPREFIX: "prefix"
    token TOKPROVISOS: "provisos"
    token TOKREADY: "ready"
    token TOKREAL: "Real"
    token TOKRESET_BY: "reset_by"
    token TOKRESULT: "result"
    token TOKRETURN: "return"
    token TOKRULE: "rule"
    token TOKRULES: "rules"
    token TOKSB: "SB"
    token TOKSBR: "SBR"
    token TOKSCHEDULE: "schedule"
    token TOKSEQ: "seq"
    token TOKSET: "set"
    token TOKSTRING: "String"
    token TOKSTRUCT: "struct"
    token TOKTAGGED: "tagged"
    token TOKTTYPE: "Type"
    token TOKTYPE: "type"
    token TOKTYPECLASS: "typeclass"
    token TOKTYPEDEF: "typedef"
    token TOKUNION: "union"
    token TOKWHILE: "while"

############################################################################
############################# Datatypes ####################################
############################################################################

    rule builtin_type:
        typevar_item
        | TOKINTEGER | TOKBOOL | TOKSTRING | TOKREAL | TOKNAT | TOKACTION | TOKACTIONVALUE

    rule type_decl:
        builtin_type
        | VAR [ LBRACKET NUM (COLON NUM)* RBRACKET ]
        | CLASSVAR typevar_item_or_var

    rule formal_item:
        ( function_parameter
        | type_decl [ item_name ]
        )

    rule param_item:
        (   LPAREN param_item RPAREN
        |   ( [ TOKNUMERIC | TOKPARAMETER ] TOKTYPE VAR
            | formal_item
            | NUM
            | STR
            )
            [ VAR ]
            [ typevar_param_list ]
        )

    rule typevar_param_list:
        LPAREN [ param_item (COMMA param_item )* ] RPAREN

    rule typevar_item:
        TYPEVAR typevar_param_list

    rule typevar_item_or_var:
        VAR [ typevar_param_list ]
        | typevar_item
        | TOKACTION
        | TOKACTIONVALUE

    rule Type_list:
        ( type_decl
        | LPAREN type_decl (COMMA type_decl)* RPAREN
        )

    rule enum_element:
        term<<[]>> [EQUAL expr<<[]>>]

    rule deriving_type_class:
        TOKEQ | TOKBITS | TOKBOUNDED

    rule single_type_definition:
        (   Type_list [ type_decl | TOKENABLE ]
        |   ( TOKENUM LBRACE enum_element [ ( ( COMMA enum_element )+ | SEMICOLON ) ]  RBRACE VAR
            | ( TOKSTRUCT | TOKUNION TOKTAGGED )
                LBRACE
                    ( single_type_definition )*
                RBRACE
                typevar_item_or_var
            )
            [ TOKDERIVING  LPAREN deriving_type_class ( COMMA deriving_type_class )* RPAREN ]
        )
        SEMICOLON

    rule formal_list:
        LPAREN [ formal_item ( COMMA formal_item)* ] RPAREN

    rule function_argument:
        ( typevar_item_or_var
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
        TOKTAGGED VAR
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
        ( VAR | TOKREADY | TOKENABLE)
        #[ typevar_param_list ]

    rule term_single:
        CLASSVAR* ( item_name | typevar_item )
        ( call_params
        | LBRACE [ VAR COLON assign_rvalue ( COMMA VAR COLON assign_rvalue )* ] RBRACE
        )*

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term<<V>>:
        (    NUM
        |    (TOKTAGGED term_single)+ [term_single]
        |    BUILTINVAR [ param_list ]
        |    term_single
        |    builtin_type
        |    STR {{ return STR }}
        |    paren_expression
        |    LBRACE assign_rvalue ( COMMA assign_rvalue )* RBRACE
        )
        (    LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET
        |    DOT VAR [ call_params ]
        )*

    rule assign_rvalue:
        ( group_statement
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
        term<<[]>> [ assign_opvalue ]

    rule let_statement:
         TOKLET
            ( VAR | LBRACE VAR (COMMA VAR)* RBRACE)
            assign_opvalue SEMICOLON
        | builtin_type declared_item ( COMMA declared_item )* SEMICOLON
        | expr<<[]>>
            [   ( declared_item ( COMMA declared_item )*
                | assign_opvalue
                )
            ] SEMICOLON

    rule rule_statement:
        TOKRULE VAR [paren_expression] SEMICOLON
        statement_list
        TOKENDRULE [ COLON  VAR ]

    rule match_arg:
        DOT ( term<<[]>> | STAR )
        | match_brace

    rule match_brace:
        LBRACE match_arg (COMMA match_arg)* RBRACE

    rule group_statement:
          TOKBEGIN statement_list TOKEND
        | TOKSEQ statement_list TOKENDSEQ
        | TOKACTIONSTATEMENT [ COLON  VAR] [ SEMICOLON ]
            statement_list
            TOKENDACTION [ COLON VAR]
        | TOKACTIONVALUESTATEMENT statement_list TOKENDACTIONVALUE
        | TOKCASE paren_expression
            ( TOKMATCHES
              (   matches_clause
                  COLON (QUESTION SEMICOLON | single_statement)
              )*
            | (
                  (expr<<[]>> (COMMA expr<<[]>>)*
                  | TOKDEFAULT
                  )
                  COLON (QUESTION SEMICOLON | single_statement)
              )*
            )
            TOKENDCASE

    rule single_statement:
          TOKFOR LPAREN
                for_decl_item (COMMA for_decl_item)* SEMICOLON
                assign_rvalue SEMICOLON
                for_variable_assignment ( COMMA for_variable_assignment )*
            RPAREN
            single_statement
        | function_declaration
        | group_statement
        | TOKIF paren_expression single_statement [ TOKELSE single_statement ]
        | let_statement
        | TOKMATCH ( TOKTAGGED VAR dot_field_list | match_brace ) assign_opvalue SEMICOLON
        | TOKPAR statement_list TOKENDPAR
        | TOKRETURN assign_rvalue SEMICOLON
        | rule_statement
        | TOKWHILE paren_expression ( group_statement | VAR SEMICOLON)

    rule statement_list:
        ( single_statement)*

############################################################################
############################# Declarations #################################
############################################################################

    rule method_declaration:
        TOKMETHOD type_decl [ VAR ] [ formal_list [VAR] ]
        ( ( TOKIF | TOKCLOCKED_BY | TOKRESET_BY | TOKENABLE | TOKREADY) paren_expression )*
        [ equal_value ]
        [ provisos_clause ] SEMICOLON
        [
            (   ( single_statement )+ TOKENDMETHOD [ COLON VAR]
            |   TOKENDMETHOD [ COLON VAR]
            )
        ]

    rule interface_body:
        ( method_declaration
        | TOKINTERFACE
            ( typevar_item VAR SEMICOLON
            | VAR ( equal_value SEMICOLON
                  | VAR ( equal_value SEMICOLON
                        | SEMICOLON [ method_declaration+ TOKENDINTERFACE [ COLON VAR ] ]
                        )
                  )
            )
        )+

    rule interface_contents:
          SEMICOLON [ interface_body ] TOKENDINTERFACE [ COLON VAR ]
        | equal_value
        | interface_body TOKENDINTERFACE [ COLON VAR ]
        | TOKENDINTERFACE [ COLON VAR ]

    rule interface_declaration:
        TOKINTERFACE CLASSVAR*
        ( typevar_item [SEMICOLON] [ interface_body ]
            TOKENDINTERFACE [ COLON VAR ]
        | interface_contents
        | VAR [ VAR ] interface_contents
        )

    rule function_declaration:
        TOKFUNCTION [ Type_list ]
        [function_name]
        [ formal_list ]
        [ provisos_clause ]
        ( equal_value SEMICOLON
        | SEMICOLON [ ( single_statement)+ TOKENDFUNCTION [ COLON  function_name] ]
        )

    rule import_arg:
        ( VAR | var_list )

    rule module_contents_declaration:
          interface_declaration [SEMICOLON]
        | function_declaration
        | method_declaration
        | TOKMODULE [ LBRACKET assign_rvalue RBRACKET ] typevar_item_or_var
            [ typevar_param_list ]
            [ provisos_clause ] SEMICOLON
            [
                (   TOKENDMODULE [ COLON VAR]
                |   ( module_contents_declaration | single_statement)+ TOKENDMODULE [ COLON VAR]
                )
            ]
        | TOKTYPEDEF ( single_type_definition | NUM VAR SEMICOLON )
        | TOKIMPORT
            ( CLASSVAR STAR SEMICOLON
            | SEMICOLON
            | TOKBDPI [ VAR  EQUAL ]
                TOKFUNCTION typevar_item_or_var
                function_name
                formal_list
                [ provisos_clause ] SEMICOLON
            | TOKBVI [ VAR [ EQUAL ] ]
                TOKMODULE typevar_item_or_var
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

    rule dep_item:
        VAR TOKDETERMINES VAR

    rule declaration_item:
          module_contents_declaration
        | TOKEXPORT VAR [ LPAREN DOT DOT RPAREN ] SEMICOLON
        | TOKINSTANCE typevar_item
            [ provisos_clause ] SEMICOLON
            ( module_contents_declaration )*
            TOKENDINSTANCE [ COLON VAR ]
        | let_statement
        | rule_statement
        | TOKTYPECLASS typevar_item
            [ TOKDEPENDENCIES LPAREN dep_item (COMMA dep_item)* RPAREN ]
            SEMICOLON
            ( module_contents_declaration )*
            TOKENDTYPECLASS [ COLON VAR ]

    rule goal:
        ( declaration_item
        | TOKPACKAGE VAR SEMICOLON
            ( declaration_item )*
            TOKENDPACKAGE [ COLON  VAR]
        )* ENDTOKEN

%%
import string
import newrt

if __name__=='__main__':
    if len(sys.argv) > 2:
        newrt.printtrace = True
    s = open(sys.argv[1]).read() + '\n'
    s1 = parse('goal', s)
