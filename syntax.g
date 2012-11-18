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

    #ignore:    "[ \r\t\n]+"
    #ignore:    "\\/\\/.*?\r?\n"
    #ignore:    "/\\*.*\\*/"
    token ENDTOKEN: "$"
    token TOKLPARENSTAR: "(*"
    token LPAREN: "("
    token RPAREN: ")"
    token AMPERAMPERAMPER: "&&&"
    token AMPERAMPER: "&&"
    token AMPER: '&'
    token BARBAR: "||"
    token BAR: "|"
    token COLONCOLON: "::"
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
    token TOKSTARRPAREN: "*)"
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
    token HASH: "#"
    token APOSTROPHE: "'"
    token DOT: "."
    token COMMA: ','

    token TOKOPPLUS: '\+'
    token TOKOPMINUS: '\-'
    token TOKOPCARET: '\^'
    token TOKOPTILDECARET: '\~^'
    token TOKOPCARETTILDE: '\^~'
    token TOKOPSLASH: '\/'
    token TOKOPAMPERAMPER: '\&&'
    token TOKOPAMPER: '\&'
    token TOKOPBAR: '\|'
    token TOKOPPERCENT: '\%'
    token TOKOPLESSLESS: '\<<'
    token TOKOPLEQ: '\<='
    token TOKOPLESS: '\<'
    token TOKOPGREATERGREATER: '\>>'
    token TOKOPGEQ: '\>='
    token TOKOPGREATER: '\>'
    token TOKOPEQUALEQUAL: '\=='
    token TOKOPSTARSTAR: '\**'
    token TOKOPSTAR: '\*'

    token TOKDISPLAY: "$display"
    token TOKDUMPOFF: "$dumpoff"
    token TOKDUMPON: "$dumpon"
    token TOKDUMPVARS: "$dumpvars"
    token TOKERROR: "$error"
    token TOKFCLOSE: "$fclose"
    token TOKFDISPLAY: "$fdisplay"
    token TOKFFLUSH: "$fflush"
    token TOKFGETC: "$fgetc"
    token TOKFINISH: "$finish"
    token TOKFOPEN: "$fopen"
    token TOKFORMAT: "$format"
    token TOKFWRITE: "$fwrite"
    token TOKSTIME: "$stime"
    token TOKSTOP: "$stop"
    token TOKTESTPLUSARGS: "$test$plusargs"
    token TOKTIME: "$time"
    token TOKUNGETC: "$ungetc"
    token TOKWRITE: "$write"

    token TOKPDEFINE: "`define"
    token TOKPELSE: "`else"
    token TOKPENDIF: "`endif"
    token TOKPIFDEF: "`ifdef"
    token TOKPINCLUDE: "`include"

    token TOKBDPI: '"BDPI"'
    token TOKBVI: '"BVI"'

    token NUM: " [0-9]+[\\'dhb\\\\.]*[a-fA-F0-9_]*"
    token VAR: " `*[a-zA-Z_][a-zA-Z0-9_]*"
    token ANYCHAR: " [a-zA-Z0-9_]*"
    token STR:   r' "([^\\"]+|\\.)*"'

    token TOKEN_FIRSTNAME: " "
    token BEGIN: "begin"
    token TOKENDACTIONVALUE: "endactionvalue"
    token TOKENDACTION: "endaction"
    token TOKENDCASE: "endcase"
    token TOKENDFUNCTION: "endfunction"
    token TOKENDINSTANCE: "endinstance"
    token TOKENDINTERFACE: "endinterface"
    token TOKENDMETHOD: "endmethod"
    token TOKENDMODULE: "endmodule"
    token TOKENDPACKAGE: "endpackage"
    token TOKENDPAR: "endpar"
    token TOKENDRULES: "endrules"
    token TOKENDRULE: "endrule"
    token TOKENDSEQ: "endseq"
    token TOKENDTYPECLASS: "endtypeclass"
    token END: "end"
    token FUNCTION: "function"
    token MATCHES: "matches"
    token TOKACTIONVALUE: "ActionValue"
    token TOKACTION: "Action"
    token TOKACTIONVALUESTATEMENT: "actionvalue"
    token TOKACTIONSTATEMENT: "action"
    token TOKALWAYS_ENABLED: "always_enabled"
    token TOKALWAYS_READY: "always_ready"
    token TOKANCESTOR: "ancestor"
    token TOKBITHASH: "Bit#"
    token TOKBITS: "Bits"
    token TOKBOOL: "Bool"
    token TOKBOUNDED: "Bounded"
    token TOKCASE: "case"
    token TOKCLOCKED_BY: "clocked_by"
    token TOKCOMPLEXHASH: "ComplexF#"
    token TOKCF: "CF"
    token TOKCLK: "CLK"
    token TOKC: "C"
    token TOKDEFAULT_CLOCK: "default_clock"
    token TOKDEFAULT_RESET: "default_reset"
    token TOKDEFAULT: "default"
    token TOKDEPENDENCIES: "dependencies"
    token TOKDERIVING: "deriving"
    token TOKDESCENDING_URGENCY: "descending_urgency"
    token TOKDETERMINES: "determines"
    token TOKDOC: "doc"
    token TOKELSE: "else"
    token TOKENABLE: "enable"
    token TOKENUM: "enum"
    token TOKEQ: "Eq"
    token TOKEXECUTION_ORDER: "execution_order"
    token TOKEXPORT: "export"
    token TOKFIFOHASH: "FIFO#"
    token TOKFIRE_WHEN_ENABLED: "fire_when_enabled"
    token TOKFIXEDPOINTHASH: "FixedPoint#"
    token TOKFOR: "for"
    token TOKIF: "if"
    token TOKIMPORT: "import"
    token TOKINPUT_CLOCK: "input_clock"
    token TOKINPUT_RESET: "input_reset"
    token TOKINSTANCE: "instance"
    token TOKINTERFACE: "interface"
    token TOKINTEGER: "Integer"
    token TOKINTHASH: "Int#"
    token TOKIN: "in"
    token TOKLET: "let"
    token TOKMATCH: "match"
    token TOKMAYBEHASH: "Maybe#"
    token TOKMETHOD: "method"
    token TOKMODULE: "module"
    token TOKMUTUALLY_EXCLUSIVE: "mutually_exclusive"
    token TOKNAT: "Nat"
    token TOKNOINLINE: "noinline"
    token TOKNO_IMPLICIT_CONDITIONS: "no_implicit_conditions"
    token TOKNO_RESET: "no_reset"
    token TOKNUMERIC: "numeric"
    token TOKOUTPUT_CLOCK: "output_clock"
    token TOKOUTPUT_RESET: "output_reset"
    token TOKPACKAGE: "package"
    token TOKPARAMETER: "parameter"
    token TOKPAR: "par"
    token TOKPATH: "path"
    token TOKPORT: "port"
    token TOKPREEMPTS: "preempts"
    token TOKPREFIX: "prefix"
    token TOKPROVISOS: "provisos"
    token TOKREADY: "ready"
    token TOKREAL: "Real"
    token TOKREGHASH: "Reg#"
    token TOKRESET_BY: "reset_by"
    token TOKRESULT: "result"
    token TOKRETURN: "return"
    token TOKRST_N: "RST_N"
    token TOKRULES: "rules"
    token TOKRULE: "rule"
    token TOKSAME_FAMILY: "same_family"
    token TOKSBR: "SBR"
    token TOKSB: "SB"
    token TOKSCHEDULE: "schedule"
    token TOKSEQ: "seq"
    token TOKSET: "set"
    token TOKSTRING: "String"
    token TOKSTRUCT: "struct"
    token TOKSYNTHESIZE: "synthesize"
    token TOKTAGGED: "tagged"
    token TOKTUPLE2HASH: "Tuple2#"
    token TOKTYPECLASS: "typeclass"
    token TOKTYPEDEF: "typedef"
    token TOKTTYPE: "Type"
    token TOKTYPE: "type"
    token TOKUINTHASH: "Uint#"
    token TOKUNION: "union"
    token TOKVECTORHASH: "Vector#"
    token TOKWHILE: "while"

    rule expr<<V>>:
         exprint<<V>>
             #[ QUESTION expr<<V>> COLON expr<<V>> ]
             [ QUESTION assign_value COLON assign_value ]
             {{return exprint}}

    # An expression is the sum and difference of factors
    rule exprint<<V>>:   factor<<V>>         {{ n = factor }}
                     ( TOKPLUS factor<<V>>
#  {{ n = 0 }} # {{ n = n+factor }}
                     |  TOKMINUS  factor<<V>>
#  {{ n = n-factor }}
                     )*                   {{ return n }}

    rule dot_item:
        DOT (VAR | STAR)

    rule dot_field_item:
        [ VAR COLON ] dot_item

    rule tdot_field_item:
        TOKTAGGED VAR [ dot_item ]

    rule dot_field_list:
        dot_item
        | NUM
        | LBRACE dot_field_item (COMMA dot_field_item)* RBRACE

    rule dot_field_ltagged:
        TOKTAGGED VAR
        [
            (dot_field_list
            | VAR
            | LPAREN
                ( dot_field_list
                | TOKTAGGED VAR [ ( dot_item | VAR ) ]
                | VAR)
                RPAREN
            )
        ]

    rule dot_field_selection:
        dot_field_ltagged
        | LPAREN dot_field_ltagged RPAREN
        | NUM

    # A factor is the product and division of terms
    rule factor<<V>>: nterm<<V>>           {{ v = nterm }}
                     ( STAR nterm<<V>>
                     | STARSTAR nterm<<V>>
                     | APOSTROPHE nterm<<V>>
#    {{ v = v*nterm }}
                     |  TOKSLASH  nterm<<V>>
#    {{ v = v/nterm }}
                     |  CARET  nterm<<V>>
                     |  LESS  nterm<<V>>
                     |  TOKGREATER  nterm<<V>>
                     |  GEQ  nterm<<V>>
                     |  LESSLESS  nterm<<V>>
                     #gets confused with assignment |  LEQ  nterm<<V>>
                     |  GREATERGREATER  nterm<<V>>
                     |  EQEQ  nterm<<V>>
                     |  TOKNOTEQUAL  nterm<<V>>
                     |  AMPER  nterm<<V>>
                     |  AMPERAMPER  assign_value
#nterm<<V>>
                     |  AMPERAMPERAMPER  nterm<<V>>
                     |  BAR  nterm<<V>>
                     |  BARBAR  nterm<<V>>
                     |  MATCHES
                          ( dot_field_selection
                          | LBRACE dot_field_item (COMMA dot_field_item)* RBRACE
                          | VAR
                          )
                     |  TOKPERCENT  nterm<<V>>
                     )*                   {{ return v }}

    rule fieldname: VAR

    rule nterm<<V>>:
        [ (TOKEXCLAIM | TOKTILDE | TOKMINUS ) ] term<<V>> {{ return term }}

    rule call_params<<V>>:
        LPAREN ( assign_value [VAR]( COMMA assign_value [VAR])* RPAREN | RPAREN )

    rule item_name:
        VAR
        | helper_name

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term_partial<<V>>:
               NUM       {{ return int(10) }}
               | TOKTAGGED term_partial<<V>> [ term_partial<<V>> ]
               | item_name+ ( COLONCOLON VAR )*
                    ( call_params<<V>>
                    | LBRACE [ fieldname COLON assign_value ( COMMA fieldname COLON assign_value )* ] RBRACE
                    | HASH
                    )*
                    {{ return lookup(V, item_name) }}
               | Type_item {{ return Type_item }}
               | STR {{ return STR }}
               #| LPAREN expr<<V>> RPAREN  {{ return expr }}
               | LPAREN assign_value RPAREN  {{ return assign_value }}
               | LBRACE assign_value ( COMMA assign_value )* RBRACE {{ return assign_value }}

    rule term<<V>>:
        term_partial<<V>>
        ( LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET
        | DOT fieldname [ call_params<<V>> ]
        )*
        {{ return term_partial }}

               #| TOKLET VAR EQUAL expr<<V>>  {{ V = [(VAR, expr)] + V }}
               #  TOKIN expr<<V>>           {{ return expr }}

    rule expression: expr<<[]>>

    rule function_name: VAR
        | function_operator

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

    rule provisos:
        TOKPROVISOS LPAREN [ expression (COMMA expression )* ] RPAREN

    rule return_statement:
        TOKRETURN assign_value SEMICOLON

    rule attribute:
        TOKSYNTHESIZE
        | TOKRST_N  EQUAL STR
        | TOKCLK  EQUAL STR
        | TOKALWAYS_READY [ EQUAL (VAR | STR) ]
        | TOKALWAYS_ENABLED [ EQUAL VAR ]
        | TOKDESCENDING_URGENCY EQUAL expression
        | TOKPREEMPTS [ EQUAL ] LBRACE VAR COMMA  LPAREN VAR RPAREN RBRACE
        | TOKDOC EQUAL STR
        | TOKREADY EQUAL STR
        | TOKENABLE EQUAL ( STR | VAR )
        | TOKRESULT EQUAL ( STR | VAR )
        | TOKPREFIX EQUAL STR
        | TOKPORT  EQUAL STR
        | TOKEXECUTION_ORDER  EQUAL STR
        | TOKMUTUALLY_EXCLUSIVE  EQUAL STR
        | TOKNOINLINE
        | TOKFIRE_WHEN_ENABLED
        | TOKNO_IMPLICIT_CONDITIONS

    rule attribute_statement:
         TOKLPARENSTAR attribute ( COMMA attribute )* TOKSTARRPAREN

    rule Type_named_sub:
        HASH LPAREN assign_value (COMMA assign_value )* RPAREN

    rule Type_item_or_name:
        Type_item
        | VAR [ COLONCOLON VAR ] [ Type_named_sub ]

    rule importBVI_statement:
    TOKPARAMETER VAR  EQUAL expression SEMICOLON
#    TOKPORT VAR  EQUAL expression SEMICOLON
    | TOKDEFAULT_CLOCK [ VAR ]
        [ LPAREN VAR [ COMMA VAR ] RPAREN ] [ EQUAL expression ] SEMICOLON
    | TOKINPUT_CLOCK [VAR] [ LPAREN VAR [ COMMA VAR ] RPAREN ]
        EQUAL expression SEMICOLON
    | TOKOUTPUT_CLOCK VAR LPAREN VAR [ COMMA VAR ] RPAREN
        SEMICOLON
    | TOKNO_RESET SEMICOLON
    | TOKSCHEDULE
        ( VAR | LPAREN VAR (COMMA VAR)* RPAREN )
        ( TOKCF | TOKSB | TOKSBR | TOKC )
        ( VAR | LPAREN VAR (COMMA VAR)* RPAREN )
        SEMICOLON
    | TOKDEFAULT_RESET VAR  LPAREN [ VAR ] RPAREN  [ EQUAL expression] SEMICOLON
    | TOKINPUT_RESET [ VAR ]  LPAREN [ VAR ] RPAREN
        [ TOKCLOCKED_BY LPAREN VAR RPAREN ]
        EQUAL expression SEMICOLON
    | TOKOUTPUT_RESET VAR  LPAREN VAR RPAREN
        TOKCLOCKED_BY LPAREN VAR RPAREN
        SEMICOLON
#    TOKANCESTOR  LPAREN clock1 COMMA clock2 RPAREN SEMICOLON
#    TOKSAME_FAMILY  LPAREN clock1 COMMA clock2 RPAREN SEMICOLON

    rule import_declaration:
        TOKIMPORT
        ( TOKBDPI [ VAR  EQUAL ]
            FUNCTION VAR [ HASH call_params<<[]>> ]
            function_name
            argument_list
            [ provisos ] SEMICOLON
        | TOKBVI [VAR] [ EQUAL ]
            TOKMODULE VAR
            [ HASH  call_params<<[]>> ]
            argument_list
            [ provisos ] SEMICOLON
            ( method_declaration
            | importBVI_statement
            )*
            TOKENDMODULE [ COLON  VAR ]
        | VAR  COLONCOLON  STAR SEMICOLON
        | SEMICOLON
        )

    rule export_declaration:
        TOKEXPORT VAR
        [ LPAREN DOT DOT RPAREN ]
        SEMICOLON

    rule variable_assignment:
        term<<[]>> ( EQUAL | LEQ | LARROW ) assign_value

    rule assign_value:
        ( seq_statement
        | interface_declaration
        | function_operator [expression]
        | case_statement
        | action_statement
        | actionvalue_statement
        | rules_statement
        | FUNCTION function_argument
        | expression ( LEQ expression )* [expression]
        | QUESTION
        )

    rule variable_declaration:
        Type_item_or_name VAR [ LBRACKET expression RBRACKET ]
        [ ( EQUAL | LARROW ) assign_value ] SEMICOLON

    rule declared_item:
        term<<[]>> [ ( EQUAL | LARROW ) assign_value ]

    rule variable_declaration_or_call:
        ( Type_item declared_item ( COMMA declared_item )*
        #| term<<[]>> [   ( declared_item ( COMMA declared_item )*
        | expression [   ( declared_item ( COMMA declared_item )*
                         | ( EQUAL | LEQ | LARROW) assign_value
                         # following weird rules needed since "VAR VAR" is a valid expression!!
                                         ( COMMA declared_item )*
                         |               ( COMMA declared_item )+
                         )
                     ]
        ) SEMICOLON

    rule for_decl_item:
        Type_item_or_name [ VAR ] ( EQUAL | LEQ ) assign_value

    rule for_statement:
        TOKFOR LPAREN
            for_decl_item (COMMA for_decl_item)* SEMICOLON
            assign_value SEMICOLON
            variable_assignment ( COMMA variable_assignment )* RPAREN
        function_body_statement

    rule while_statement:
        TOKWHILE LPAREN expression RPAREN
        ( action_statement
        | seq_statement
        | group_statement
        | VAR SEMICOLON
        )

    rule helper_name:
        ( TOKDISPLAY | TOKWRITE | TOKFOPEN | TOKFDISPLAY
        | TOKFWRITE | TOKFGETC | TOKFFLUSH | TOKFCLOSE | TOKUNGETC
        | TOKFINISH | TOKSTOP | TOKDUMPON | TOKDUMPOFF | TOKDUMPVARS
        | TOKTESTPLUSARGS | TOKTIME | TOKSTIME | TOKFORMAT
        | TOKERROR
        )

    #rule helper_statement:
        #helper_name
        #[ LPAREN [ expression (COMMA expression)* ] RPAREN ]
        #SEMICOLON

    rule function_body_statement:
        let_statement
        | for_statement
        | function_statement
        | case_statement
        | if_statement
        | group_statement
        #| helper_statement
        | seq_statement
        | par_statement
        | ifdef_statement
        | include_declaration
        | action_statement
        | match_statement
        | return_statement
        | rule_statement
        | actionvalue_statement
        | while_statement
        | variable_declaration_or_call

    rule module_item:
        ( function_body_statement
        | method_declaration
        | attribute_statement
        | import_declaration
        | interface_declaration
        | typedef_declaration
        )+

    rule top_level_statement:
        package_statement_item
        | package_statement
        #| instance_statement
        #| method_declaration
        #| let_statement
        #| typeclass_statement

    rule package_statement_item:
        typedef_declaration
        | import_declaration
        | export_declaration
        | define_declaration
        | include_declaration
        | ifdef_statement
        | interface_declaration
        | module_declaration
        | variable_declaration
        | attribute_statement
        | function_statement
        | instance_statement
        | method_declaration
        | let_statement
        | rule_statement
        | typeclass_statement

    rule group_statement:
        BEGIN
        ( function_body_statement
        | attribute_statement
        )*
        END

    rule seq_statement:
        TOKSEQ
        ( function_body_statement
        | attribute_statement
        )*
        TOKENDSEQ

    rule par_statement:
        TOKPAR
        ( function_body_statement
        | attribute_statement
        )*
        TOKENDPAR

    rule method_body:
        [ provisos ]
        SEMICOLON
        [
            ( function_body_statement )+
            TOKENDMETHOD [ COLON VAR]
        ]

    rule method_declaration:
        TOKMETHOD 
        ( TOKACTION VAR  [ argument_list ]
            [ TOKIF  LPAREN assign_value RPAREN ]
            [ EQUAL assign_value ]
            method_body
        | TOKACTIONVALUE
            [ HASH LPAREN expression RPAREN ]
            VAR [ argument_list ]
            [ TOKIF  LPAREN assign_value RPAREN ]
            method_body
        | (TOKTTYPE | Type_item_basic | VAR [ Type_named_sub ]) [ VAR ]  [ argument_list ]
            [ VAR ]
            ( ( TOKIF | TOKCLOCKED_BY | TOKRESET_BY | TOKENABLE | TOKREADY)
                LPAREN [ ( assign_value | TOKENABLE | TOKREADY ) ] RPAREN 
            )*
            [ EQUAL assign_value ]
            method_body
        #| [ output_port ] VAR
        #    LPAREN LBRACE input_ports RBRACE RPAREN
        #    [ TOKENABLE enable_port ]
        #    [ TOKREADY ready_port ] [ TOKCLOCKED_BY VAR ]
        #    [ TOKRESET_BY VAR] SEMICOLON
        )

    rule interface_arg:
        struct_arg
        | expression

    rule interfaceTypesub:
        HASH LPAREN interface_arg (COMMA interface_arg )* RPAREN

    rule subinterface_declaration:
        TOKINTERFACE VAR
        ( interfaceTypesub VAR SEMICOLON
        | EQUAL assign_value SEMICOLON
        | VAR
            ( EQUAL assign_value SEMICOLON
            | SEMICOLON
                [
                ( method_declaration
                | attribute_statement
                #| subinterface_declaration
                )+
                TOKENDINTERFACE [ COLON VAR ]
                ]
            )
        )

    rule interface_body:
        ( method_declaration
        | attribute_statement
        | subinterface_declaration
        )+
        TOKENDINTERFACE [ COLON VAR ]

    rule interface_declaration:
        TOKINTERFACE VAR [COLONCOLON VAR] [VAR]
        ( [ SEMICOLON ] interface_body
        | interfaceTypesub SEMICOLON interface_body
        | EQUAL assign_value SEMICOLON
        )

    rule match_arg:
        DOT ( term<<[]>> | STAR )

    rule match_statement:
        TOKMATCH
        LBRACE match_arg (COMMA match_arg)* RBRACE ( EQUAL | LARROW ) assign_value SEMICOLON

    rule module_param:
        Type_item_or_name [ VAR ] [ STAR ]

    rule module_declaration:
        TOKMODULE [ LBRACKET assign_value RBRACKET ] VAR [ HASH  argument_list ]
        LPAREN [ module_param (COMMA module_param)* ] RPAREN
        [ provisos ]
        SEMICOLON
        [
            module_item
            TOKENDMODULE [ COLON VAR]
        ]

    rule package_statement:
        TOKPACKAGE VAR SEMICOLON
        ( package_statement_item )*
        TOKENDPACKAGE [ COLON  VAR]

    rule tagged_match_arg:
        VAR COLON DOT VAR

    rule rule_predicate:
        LPAREN
        assign_value
        [ MATCHES TOKTAGGED VAR
            ( LBRACE tagged_match_arg (COMMA tagged_match_arg)* RBRACE
            | DOT VAR
            )
        ]
        RPAREN

    rule rule_statement:
        TOKRULE VAR [rule_predicate] SEMICOLON
        ( function_body_statement
        | attribute_statement
        )*
        TOKENDRULE [ COLON  VAR ]

    rule rules_statement:
        TOKRULES [ COLON  VAR]
        ( rule_statement
        | variable_declaration_or_call SEMICOLON
        | attribute_statement
        )*
        TOKENDRULES [ COLON  VAR]

    rule action_statement:
        TOKACTIONSTATEMENT [ COLON  VAR] [ SEMICOLON ]
        ( function_body_statement
        | attribute_statement
        )*
        TOKENDACTION [ COLON VAR]

    rule Type_item_basic:
        ( TOKBITHASH | TOKINTHASH | TOKUINTHASH | TOKCOMPLEXHASH | TOKREGHASH | TOKFIFOHASH | TOKMAYBEHASH )
           LPAREN expression [ COMMA expression ] RPAREN
        | (TOKVECTORHASH | TOKTUPLE2HASH | TOKFIXEDPOINTHASH )
           LPAREN expression (COMMA expression)* RPAREN
        | TOKINTEGER | TOKBOOL | TOKSTRING | TOKREAL | TOKNAT

    rule Type_item:
        Type_item_basic
        | TOKACTION | TOKACTIONVALUE HASH LPAREN Type_item_or_name RPAREN

    rule case_statement:
        TOKCASE LPAREN expression RPAREN
        ( MATCHES
          (
              ( dot_field_selection
              | LBRACE tdot_field_item (COMMA tdot_field_item)* RBRACE
              | TOKDEFAULT
              | VAR 
              )
              COLON (QUESTION SEMICOLON | function_body_statement)
          )*
        | (
              (expression (COMMA expression)*
              | TOKDEFAULT
              #| VAR
              )
              COLON (QUESTION SEMICOLON | function_body_statement)
          )*
        )
        TOKENDCASE

    rule let_statement:
        TOKLET
        ( VAR
        | LBRACE VAR (COMMA VAR)* RBRACE
        )
        ( EQUAL | LARROW )
        assign_value SEMICOLON

    rule Elements: term<<[]>> [EQUAL expression]

    rule TypeClass:
        TOKEQ | TOKBITS | TOKBOUNDED

    rule deriving_clause:
        TOKDERIVING  LPAREN TypeClass ( COMMA TypeClass )* RPAREN

    rule struct_arg:
        [ TOKNUMERIC | TOKPARAMETER ] TOKTYPE VAR

    rule struct_arg_list:
        LPAREN struct_arg (COMMA struct_arg)* RPAREN

    rule typedef_declaration:
        TOKTYPEDEF 
        Member

    rule Member:
        ( ( TOKTYPE | Type_item_or_name | NUM | LPAREN Type_item_or_name RPAREN ) [VAR | TOKENABLE ]
            [ HASH struct_arg_list ] SEMICOLON
        | TOKENUM LBRACE Elements ( COMMA Elements )* RBRACE VAR
            [ deriving_clause ] SEMICOLON
        | TOKSTRUCT LBRACE
            #( Type_item_or_name VAR SEMICOLON )* RBRACE
            ( Member )* RBRACE
            VAR [ HASH struct_arg_list ]
            [ deriving_clause ] SEMICOLON
        | TOKUNION TOKTAGGED
            LBRACE (Member)+ RBRACE
            VAR
            [ HASH
                ( struct_arg
                | struct_arg_list
                )
            ]
            [ deriving_clause ] SEMICOLON
        )

    rule function_return_type:
        ( TOKACTION VAR
        | TOKACTIONVALUE
        | VAR
        )
        [ HASH LPAREN assign_value (COMMA assign_value)* RPAREN ]

    rule function_argument: 
        ( function_return_type
        | LPAREN function_return_type RPAREN
        )
        [VAR]
        [ argument_list ]

    rule Type_item_or_name_sub:
        Type_item_or_name
        [ LBRACKET NUM COLON NUM RBRACKET ]

    rule argument_item:
        ( FUNCTION function_argument
        | Type_item_or_name_sub [ VAR | TOKENABLE | TOKREADY ]
        )

    rule argument_list:
        LPAREN [ argument_item ( COMMA argument_item)* ] RPAREN

    rule variable_assignment_or_call:
        term<<[]>>
        ( EQUAL assign_value SEMICOLON
        | LEQ assign_value SEMICOLON
        | SEMICOLON
        )

    rule if_statement:
        TOKIF LPAREN assign_value RPAREN
           function_body_statement [ TOKELSE function_body_statement ]

    rule actionvalue_statement:
        TOKACTIONVALUESTATEMENT
        ( return_statement
        | let_statement
        | case_statement
        | for_statement
        | function_statement
        #| expression SEMICOLON
        | variable_declaration_or_call
        )*
        TOKENDACTIONVALUE

    rule function_header:
        FUNCTION
        [
            ( Type_item_or_name_sub
            | LPAREN Type_item_or_name RPAREN
            )
        ]
        [function_name]
        [ argument_list ]

    rule function_statement:
        function_header
        [ provisos ]
        ( EQUAL assign_value SEMICOLON
        | SEMICOLON
            [
              ( function_body_statement
              | attribute_statement
              )+
              TOKENDFUNCTION [ COLON  function_name]
            ]
        )

    rule path_statement:
        TOKPATH LPAREN VAR COMMA VAR RPAREN  SEMICOLON

    rule instance_arg:
        Type_item_or_name
        | NUM

    rule instance_statement:
        TOKINSTANCE VAR HASH LPAREN instance_arg ( COMMA instance_arg )* RPAREN
        [ provisos ] SEMICOLON
        ( function_statement
        | module_declaration
        )*
        TOKENDINSTANCE [ COLON VAR ]

    rule dep_item:
        VAR TOKDETERMINES VAR

    rule typeclass_statement:
        TOKTYPECLASS VAR interfaceTypesub
        [ TOKDEPENDENCIES LPAREN dep_item (COMMA dep_item)* RPAREN ]
        SEMICOLON
        (function_header SEMICOLON
        | module_declaration
        )*
        TOKENDTYPECLASS [ COLON VAR ]

    rule define_declaration:
        TOKPDEFINE VAR [expression]

    rule include_declaration:
        TOKPINCLUDE STR

    rule ifdef_statement:
        TOKPIFDEF [VAR | ANYCHAR]
           [ module_item ]
        [ TOKPELSE
           [ module_item ]
        ]
        TOKPENDIF

    rule goal:
        (top_level_statement)* ENDTOKEN

%%
import string
import newrt

if __name__=='__main__':
    s = open(sys.argv[1]).read()
    # line continuation in string literals not handled by runtime
    s = string.replace(s, "\\\n", "  ")
    if len(sys.argv) > 2:
        newrt.printtrace = True
    s1 = parse('goal', s)
