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

    rule expr<<V>>:
         exprint<<V>>
             [ QUESTION assign_value COLON assign_value ]
             {{return exprint}}

    # An expression is the sum and difference of factors
    rule exprint<<V>>:
        factor<<V>>         {{ n = factor }}
        (  TOKPLUS factor<<V>>
        |  TOKMINUS  factor<<V>>
        )* {{ return n }}

    rule dot_item:
        DOT (VAR | STAR)

    rule dot_field_item:
        [ VAR COLON ] dot_item

    rule tagged_match_arg:
        VAR COLON DOT VAR

    rule dot_field_list:
        dot_item
        | NUM
        | VAR
        | LBRACE dot_field_item (COMMA dot_field_item)* RBRACE

    rule dot_field_ltagged:
        TOKTAGGED VAR
        [
            (dot_field_list
            | LPAREN
                ( dot_field_list
                | dot_field_ltagged
                )
                RPAREN
            )
        ]

    rule dot_field_selection:
        dot_field_ltagged
        | LPAREN dot_field_ltagged RPAREN
        | NUM

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
        |  TOKAMPERAMPER  assign_value
        |  TOKAMPERAMPERAMPER  nterm<<V>>
        |  TOKBAR  nterm<<V>>
        |  TOKBARBAR  nterm<<V>>
        |  TOKMATCHES
            ( dot_field_selection
            | LBRACE dot_field_item (COMMA dot_field_item)* RBRACE
            | VAR
            )
        |  TOKPERCENT  nterm<<V>>
        )*  {{ return v }}

    rule nterm<<V>>:
        [ (TOKEXCLAIM | TOKTILDE | TOKMINUS | TOKBAR) ] term<<V>> {{ return term }}

    rule call_pitem:
        [ TOKCLOCKED_BY | TOKRESET_BY ] assign_value

    rule call_params:
        LPAREN [ call_pitem ( COMMA call_pitem )* ] RPAREN

    rule item_name:
        ( VAR | TOKREADY | TOKENABLE)

    rule term_single:
        CLASSVAR* ( item_name | typevar_item )
        ( call_params
        | LBRACE [ VAR COLON assign_value ( COMMA VAR COLON assign_value )* ] RBRACE
        )*

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term_partial<<V>>:
        NUM
        | (TOKTAGGED term_single)+ [term_single]
        | term_single
        | BUILTINVAR [ param_list ]
        | Type_item
        | STR {{ return STR }}
        | LPAREN assign_value RPAREN
        | LBRACE assign_value ( COMMA assign_value )* RBRACE

    rule term<<V>>:
        term_partial<<V>>
        ( LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET
        | DOT VAR [ call_params ]
        )*
        {{ return term_partial }}

    rule assign_value:
        ( seq_statement
        | interface_declaration
        | case_statement
        | action_statement
        | actionvalue_statement
        | TOKRULES [ COLON  VAR]
            ( rule_statement)*
            TOKENDRULES [ COLON  VAR]
        | TOKFUNCTION function_argument
        | function_operator [expr<<[]>>]
        | expr<<[]>> ( LEQ expr<<[]>> )* [expr<<[]>>]
        | QUESTION
        )
        # values like "(OP_Reg Reg_Normal data)" are allowed
        ( expr<<[]>> )*

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

    rule import_arg:
        ( VAR | LPAREN VAR (COMMA VAR)* RPAREN )

    rule provisos_clause:
        TOKPROVISOS param_list

    rule import_declaration:
        TOKIMPORT
        ( CLASSVAR STAR SEMICOLON
        | SEMICOLON
        | TOKBDPI [ VAR  EQUAL ]
            TOKFUNCTION typevar_item_or_var
            function_name
            argument_list
            [ provisos_clause ] SEMICOLON
        | TOKBVI [ VAR [ EQUAL ] ]
            TOKMODULE typevar_item_or_var
            [ argument_list ]
            [ provisos_clause ] SEMICOLON
            (   method_declaration
            |   TOKPARAMETER VAR  EQUAL expr<<[]>> SEMICOLON
            |   TOKDEFAULT_CLOCK [ VAR ]
                  [ LPAREN VAR [ COMMA VAR ] RPAREN ] [ EQUAL expr<<[]>> ] SEMICOLON
            |   TOKINPUT_CLOCK [VAR] [ LPAREN VAR [ COMMA VAR ] RPAREN ]
                  EQUAL expr<<[]>> SEMICOLON
            |   TOKOUTPUT_CLOCK VAR LPAREN VAR [ COMMA VAR ] RPAREN SEMICOLON
            |   TOKNO_RESET SEMICOLON
            |   TOKSCHEDULE import_arg
                  ( TOKCF | TOKSB | TOKSBR | TOKC ) import_arg SEMICOLON
            |   TOKDEFAULT_RESET VAR  LPAREN [ VAR ] RPAREN  [ EQUAL expr<<[]>>] SEMICOLON
            |   TOKINPUT_RESET [ VAR ]  LPAREN [ VAR ] RPAREN
                  [ TOKCLOCKED_BY LPAREN VAR RPAREN ]
                  EQUAL expr<<[]>> SEMICOLON
            |   TOKOUTPUT_RESET VAR  LPAREN VAR RPAREN
                  TOKCLOCKED_BY LPAREN VAR RPAREN SEMICOLON
            )*
            TOKENDMODULE [ COLON  VAR ]
        )

    rule export_declaration:
        TOKEXPORT VAR
        [ LPAREN DOT DOT RPAREN ]
        SEMICOLON

    rule declared_item:
        term<<[]>> [ ( EQUAL | LARROW ) assign_value ]

    rule variable_declaration_or_call:
        ( Type_item declared_item ( COMMA declared_item )*
        | expr<<[]>> [   ( declared_item ( COMMA declared_item )*
                         | ( EQUAL | LEQ | LARROW) assign_value
                         )
                     ]
        ) SEMICOLON

    rule for_decl_item:
        # datatype might not be present
        Type_nitem [ VAR ] ( EQUAL | LEQ ) assign_value

    rule for_variable_assignment:
        term<<[]>> ( EQUAL | LEQ | LARROW ) assign_value

    rule for_statement:
        TOKFOR LPAREN
            for_decl_item (COMMA for_decl_item)* SEMICOLON
            assign_value SEMICOLON
            for_variable_assignment ( COMMA for_variable_assignment )* RPAREN
        single_statement

    rule while_statement:
        TOKWHILE LPAREN expr<<[]>> RPAREN
        ( action_statement
        | seq_statement
        | group_statement
        | VAR SEMICOLON
        )

    rule return_statement:
        TOKRETURN assign_value SEMICOLON

    rule group_statement:
        TOKBEGIN
        statement_list
        TOKEND

    rule seq_statement:
        TOKSEQ
        statement_list
        TOKENDSEQ

    rule par_statement:
        TOKPAR
        statement_list
        TOKENDPAR

    rule action_statement:
        TOKACTIONSTATEMENT [ COLON  VAR] [ SEMICOLON ]
        statement_list
        TOKENDACTION [ COLON VAR]

    rule actionvalue_statement:
        TOKACTIONVALUESTATEMENT
        statement_list
        TOKENDACTIONVALUE

    rule case_statement:
        TOKCASE LPAREN expr<<[]>> RPAREN
        ( TOKMATCHES
          (
              ( dot_field_selection
              | LBRACE dot_field_ltagged (COMMA dot_field_ltagged)* RBRACE
              | TOKDEFAULT
              | VAR 
              )
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

    rule let_statement:
        TOKLET
        ( VAR
        | LBRACE VAR (COMMA VAR)* RBRACE
        )
        ( EQUAL | LARROW ) assign_value SEMICOLON

    rule if_statement:
        TOKIF LPAREN assign_value RPAREN
           single_statement [ TOKELSE single_statement ]

    rule rule_statement:
        TOKRULE VAR [LPAREN assign_value RPAREN] SEMICOLON
        statement_list
        TOKENDRULE [ COLON  VAR ]

    rule single_statement:
        let_statement
        | for_statement
        | case_statement
        | if_statement
        | group_statement
        | seq_statement
        | par_statement
        | action_statement
        | match_statement
        | return_statement
        | rule_statement
        | actionvalue_statement
        | while_statement
        | function_declaration
        | variable_declaration_or_call

    rule statement_list:
        ( single_statement)*

    rule module_item:
        ( single_statement
        | method_declaration
        | import_declaration
        | interface_declaration
        | typedef_declaration
        )+

    rule package_declaration_item:
        typedef_declaration
        | import_declaration
        | export_declaration
        | interface_declaration
        | function_declaration
        | module_declaration
        | vdeclaration
        | instance_statement
        | method_declaration
        | let_statement
        | rule_statement
        | typeclass_statement

    rule vdeclaration:
        Type_nitem VAR [ LBRACKET expr<<[]>> RBRACKET ]
        [ ( EQUAL | LARROW ) assign_value ] SEMICOLON

    rule top_level_statement:
        package_declaration_item
        | package_declaration

    rule typedef_declaration:
        TOKTYPEDEF single_type_definition

    rule method_body:
        [ provisos_clause ] SEMICOLON
        [
            ( single_statement )+
            TOKENDMETHOD [ COLON VAR]
        ]

    rule method_declaration:
        TOKMETHOD 
        ( (TOKACTIONVALUE | Type_item) VAR [ argument_list ]
        | VAR [ VAR ] [ argument_list [ VAR ] ]
        )
        #| [ output_port ] VAR
        #    LPAREN LBRACE input_ports RBRACE RPAREN
        #    [ TOKENABLE enable_port ]
        #    [ TOKREADY ready_port ] [ TOKCLOCKED_BY VAR ]
        #    [ TOKRESET_BY VAR] SEMICOLON
        ( ( TOKIF | TOKCLOCKED_BY | TOKRESET_BY | TOKENABLE | TOKREADY)
            LPAREN [ assign_value ] RPAREN 
        )*
        [ EQUAL assign_value ]
        method_body

    rule subinterface_declaration:
        TOKINTERFACE
        ( typevar_item VAR SEMICOLON
        | VAR
            ( EQUAL assign_value SEMICOLON
            | VAR
                ( EQUAL assign_value SEMICOLON
                | SEMICOLON
                    [
                        ( method_declaration )+
                        TOKENDINTERFACE [ COLON VAR ]
                    ]
                )
            )
        )

    rule interface_declaration:
        TOKINTERFACE [ CLASSVAR* VAR [VAR]]
        ( EQUAL assign_value SEMICOLON
        | [ typevar_item ] [SEMICOLON]
            ( method_declaration
            | subinterface_declaration
            )+
            TOKENDINTERFACE [ COLON VAR ]
        )

    rule match_arg:
        DOT ( term<<[]>> | STAR )
        | match_brace

    rule match_brace:
        LBRACE match_arg (COMMA match_arg)* RBRACE

    rule match_statement:
        TOKMATCH
        match_brace
        ( EQUAL | LARROW ) assign_value SEMICOLON

    rule module_param:
        Type_nitem [ VAR | STAR ]

    rule module_declaration:
        TOKMODULE [ LBRACKET assign_value RBRACKET ] typevar_item_or_var
        [ typevar_param_list ]
        [ provisos_clause ] SEMICOLON
        [
            module_item
            TOKENDMODULE [ COLON VAR]
        ]

    rule package_declaration:
        TOKPACKAGE VAR SEMICOLON
        ( package_declaration_item )*
        TOKENDPACKAGE [ COLON  VAR]

    rule Type_item:
        typevar_item
        | TOKINTEGER | TOKBOOL | TOKSTRING | TOKREAL | TOKNAT | TOKACTION

    rule function_return_type:
        ( TOKACTION VAR [call_params]
        | TOKACTIONVALUE
        | typevar_item_or_var
        )

    rule Type_nitem:
        Type_item
        | VAR [ LBRACKET NUM (COLON NUM)* RBRACKET ]
        | CLASSVAR function_return_type

    rule param_item:
        (   LPAREN param_item RPAREN
        |   ( [ TOKNUMERIC | TOKPARAMETER ] TOKTYPE VAR
            | argument_item
            | NUM
            | STR
            )
            [ VAR ]
            [ typevar_param_list ]
        )

    rule typevar_item:
        TYPEVAR typevar_param_list

    rule typevar_item_or_var:
        VAR [ typevar_param_list ]
#[call_params]
        | typevar_item

    rule typevar_param_list:
        LPAREN [ param_item (COMMA param_item )* ] RPAREN

    rule enum_element: term<<[]>> [EQUAL expr<<[]>>]

    rule deriving_type_class:
        TOKEQ | TOKBITS | TOKBOUNDED

    rule single_type_definition:
        (   (
# TOKTYPE |
            Type_nitem
            | NUM
            | LPAREN Type_nitem RPAREN
            )
            [ Type_nitem | TOKENABLE ]
        |   ( TOKENUM LBRACE enum_element ( COMMA enum_element )* RBRACE VAR
            | ( TOKSTRUCT | TOKUNION TOKTAGGED )
                LBRACE
                    ( single_type_definition )*
                RBRACE
                typevar_item_or_var
            )
            [ TOKDERIVING  LPAREN deriving_type_class ( COMMA deriving_type_class )* RPAREN ]
        )
        SEMICOLON

    rule function_argument: 
        ( function_return_type
        | LPAREN function_argument (COMMA function_argument)* RPAREN
        )
        [VAR [ argument_list ] ]

    rule Type_sitem:
        Type_nitem
# [ LBRACKET NUM COLON NUM RBRACKET ]

    rule argument_item:
        ( TOKFUNCTION function_argument
        | Type_sitem [ item_name ]
        )

    rule argument_list:
        LPAREN [ argument_item ( COMMA argument_item)* ] RPAREN

    rule param_list:
        LPAREN [ assign_value (COMMA assign_value)* ] RPAREN

    rule function_declaration:
        TOKFUNCTION
        [
            ( Type_sitem
            | LPAREN Type_nitem (COMMA Type_nitem)* RPAREN
            )
        ]
        [function_name]
        [ argument_list ]
        [ provisos_clause ]
        ( EQUAL assign_value SEMICOLON
        | SEMICOLON
            [
              ( single_statement)+
              TOKENDFUNCTION [ COLON  function_name]
            ]
        )

    rule instance_statement:
        TOKINSTANCE typevar_item
        [ provisos_clause ] SEMICOLON
        ( function_declaration
        | module_declaration
        )*
        TOKENDINSTANCE [ COLON VAR ]

    rule dep_item:
        VAR TOKDETERMINES VAR

    rule typeclass_statement:
        TOKTYPECLASS typevar_item
        [ TOKDEPENDENCIES LPAREN dep_item (COMMA dep_item)* RPAREN ]
        SEMICOLON
        ( function_declaration
        | module_declaration
        )*
        TOKENDTYPECLASS [ COLON VAR ]

    rule goal:
        (top_level_statement)* ENDTOKEN

%%
import string
import newrt

if __name__=='__main__':
    if len(sys.argv) > 2:
        newrt.printtrace = True
    s = open(sys.argv[1]).read() + '\n'
    s1 = parse('goal', s)
