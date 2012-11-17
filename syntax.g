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
parser Calculator:
    ignore:    "[ \r\t\n]+"
    ignore:    "\\/\\/.*?\r?\n"
    ignore:    "/\\*.*\\*/"
    token BEGIN: "begin"
    token END: "end"
    token FUNCTION: "function"
    token MATCHES: "matches"
    token ENDTOKEN: "$"
    token NUM: "[0-9\\']+[dhb]*[a-fA-F0-9]*"
    token VAR: "`*[a-zA-Z_][a-zA-Z0-9_]*"
    token STR:   r'"([^\\"]+|\\.)*"'
    token LPAREN: "\\(" token RPAREN: "\\)"
    token LBRACKET: "\\[" token RBRACKET: "\\]"
    token LBRACE: "{" token RBRACE: "}"
    token HASH: "#"
    token DOT: r"[\\.]"
    token COMMA: ','
    token AMPER: '&' token AMPERAMPER: "&&" token AMPERAMPERAMPER: "&&&"
    token BAR: "\\|" token BARBAR: "\\|\\|"
    token COLON: ':' token COLONCOLON: "::" token SEMICOLON: ';'
    token QUESTION: "\\?"
    token CARET: "\\^"
    token LESS: "<" token LESSLESS: "<<" token LEQ: "<=" token LARROW: "<-"
    token GEQ: ">="
    token EQUAL: "=" token EQEQ: "=="
    token STAR: "[*]"

    # Each line can either be an expression or an assignment statement
    rule gggoal:   expr<<[]>> ENDTOKEN            {{ return expr }}
               | "set" VAR expr<<[]>> ENDTOKEN  {{ globalvars[VAR] = expr }}
                                           {{ return expr }}

    rule expr<<V>>:
         exprint<<V>>
             [ QUESTION expr<<V>> COLON expr<<V>> ]
             {{return exprint}}
         | case_statement {{ return "0" }}
         | rules_statement {{ return "0" }}

    # An expression is the sum and difference of factors
    rule exprint<<V>>:   factor<<V>>         {{ n = factor }}
                     ( "[+]" factor<<V>>
#  {{ n = 0 }} # {{ n = n+factor }}
                     |  "-"  factor<<V>>
#  {{ n = n-factor }}
                     )*                   {{ return n }}

    rule field_match:
        VAR COLON DOT VAR

    # A factor is the product and division of terms
    rule factor<<V>>: nterm<<V>>           {{ v = nterm }}
                     ( STAR nterm<<V>>
#    {{ v = v*nterm }}
                     |  "/"  nterm<<V>>
#    {{ v = v/nterm }}
                     |  CARET  nterm<<V>>
                     |  LESS  nterm<<V>>
                     |  ">"  nterm<<V>>
                     |  GEQ  nterm<<V>>
                     |  LESSLESS  nterm<<V>>
                     |  LEQ  nterm<<V>>
                     |  ">>"  nterm<<V>>
                     |  EQEQ  nterm<<V>>
                     |  "!="  nterm<<V>>
                     |  AMPER  nterm<<V>>
                     |  AMPERAMPER  nterm<<V>>
                     |  AMPERAMPERAMPER  nterm<<V>>
                     |  BAR  nterm<<V>>
                     |  BARBAR  nterm<<V>>
                     |  MATCHES
                          ( "tagged" VAR
                              [ 
                                  ( DOT fieldname
                                  | LBRACE field_match (COMMA field_match)* RBRACE
                                  )
                              ]
                          | VAR
                          )
                     |  "%"  nterm<<V>>
                     )*                   {{ return v }}

    rule fieldname: VAR

    rule nterm<<V>>:
        [ ("!" | "~" | "-" ) ] term<<V>> {{ return term }}

    rule call_params<<V>>:
        LPAREN [ assign_value [VAR]( COMMA assign_value [VAR])* ] RPAREN

    rule item_name:
        VAR
        | helper_name

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term_partial<<V>>:
               NUM       {{ return int(10) }}
               | "tagged" ("Valid" VAR | "Invalid" | "LoadPage" | "StorePage" )
               | item_name ( COLONCOLON VAR )*
                    ( call_params<<V>>
                    | LBRACE fieldname COLON expr<<V>> ( COMMA fieldname COLON expr<<V>> )* RBRACE
                    | HASH
                    )*
                    {{ return lookup(V, item_name) }}
               | Type_item {{ return Type_item }}
               | STR {{ return STR }}
               #| LPAREN expr<<V>> RPAREN  {{ return expr }}
               | LPAREN assign_value RPAREN  {{ return assign_value }}
               | LBRACE expr<<V>> ( COMMA expr<<V>> )* RBRACE {{ return expr }}
               | QUESTION

    rule term<<V>>:
        term_partial<<V>>
        ( LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET
        | DOT fieldname [ call_params<<V>> ]
        )*
        {{ return term_partial }}

               #| "let" VAR EQUAL expr<<V>>  {{ V = [(VAR, expr)] + V }}
               #  "in" expr<<V>>           {{ return expr }}

###########jca

    rule expression: expr<<[]>>

    rule function_name: VAR
        | function_operator

    rule function_operator:
        '\\\\\\+'
        | '\\\\\\-'
        | '\\\\\\*'

    rule provisos:
        [ "provisos" LPAREN expression (COMMA expression )* RPAREN ]
        SEMICOLON

    rule return_statement:
        "return" expression SEMICOLON

    rule attribute:
        "synthesize"
        | "RST_N"  EQUAL STR
        | "CLK"  EQUAL STR
        | "always_ready" [ EQUAL VAR ]
        | "always_enabled" [ EQUAL VAR ]
        | "descending_urgency" EQUAL expression
        | "preempts" [ EQUAL ] LBRACE VAR COMMA  LPAREN VAR RPAREN RBRACE
        | "doc" EQUAL STR
        | "ready" EQUAL STR
        | "enable" EQUAL STR
        | "result" EQUAL STR
        | "prefix" EQUAL STR
        | "port"  EQUAL STR
        | "noinline"
        | "fire_when_enabled"
        | "no_implicit_conditions"

    rule attribute_statement:
         "\\([*]" attribute "[*]\\)"

    rule Type_named_sub:
        HASH LPAREN expression (COMMA expression )* RPAREN

    rule Type_item_or_name:
        Type_item
        | VAR [ Type_named_sub ]

    rule importBVI_statement:
    "parameter" VAR  EQUAL expression SEMICOLON
#    "port" VAR  EQUAL expression SEMICOLON
    | "default_clock" VAR
        [ LPAREN VAR [ COMMA VAR ] RPAREN ] [ EQUAL expression ] SEMICOLON
    | "input_clock" VAR [ LPAREN VAR [ COMMA VAR ] RPAREN ]
        EQUAL expression SEMICOLON
    | "output_clock" VAR LPAREN VAR [ COMMA VAR ] RPAREN
        SEMICOLON
    | "no_reset" SEMICOLON
    | "schedule"
        ( VAR | LPAREN VAR (COMMA VAR)* RPAREN )
        ( "CF" | "SB" | "SBR" | "C" )
        ( VAR | LPAREN VAR (COMMA VAR)* RPAREN )
        SEMICOLON
    | "default_reset" VAR  LPAREN [ VAR ] RPAREN  [ EQUAL expression] SEMICOLON
    | "input_reset" [ VAR ]  LPAREN [ VAR ] RPAREN
        "clocked_by" LPAREN VAR RPAREN
        EQUAL expression SEMICOLON
    | "output_reset" VAR  LPAREN VAR RPAREN
        "clocked_by" LPAREN VAR RPAREN
        SEMICOLON
#    "ancestor"  LPAREN clock1 COMMA clock2 RPAREN SEMICOLON
#    "same_family"  LPAREN clock1 COMMA clock2 RPAREN SEMICOLON

    rule import_declaration:
        "import"
        ( r'"BDPI"' [ VAR  EQUAL ]
            FUNCTION VAR [ HASH call_params<<[]>> ]
            function_name argument_list provisos
        | r'"BVI"' [VAR] [ EQUAL ]
            "module" VAR [ HASH  call_params<<[]>> ]
            argument_list provisos
            ( method_declaration
            | importBVI_statement
            )*
            "endmodule" [ COLON  VAR ]
        | VAR  COLONCOLON  STAR SEMICOLON
        | SEMICOLON
        )

    rule variable_assignment:
        term<<[]>> ( EQUAL | LEQ ) expression

    rule assign_value:
        ( seq_statement
        | interface_declaration
        | function_operator
        | expression
        )

    rule variable_declaration:
        Type_item_or_name VAR [ LBRACKET expression RBRACKET ]
        [ ( EQUAL | LARROW ) assign_value ] SEMICOLON

    rule declared_item:
        term<<[]>> [ ( EQUAL | LARROW ) assign_value ]

    rule variable_declaration_or_call:
        ( Type_item declared_item ( COMMA declared_item )*
        | term<<[]>> [   ( declared_item ( COMMA declared_item )*
                         | ( EQUAL | LEQ | LARROW) assign_value
                         )
                     ]
        ) SEMICOLON

    rule for_decl_item:
        Type_item_or_name [ VAR ] ( EQUAL | LEQ ) expression

    rule for_statement:
        "for" LPAREN
            for_decl_item (COMMA for_decl_item)* SEMICOLON
            expression SEMICOLON
            variable_assignment ( COMMA variable_assignment )* RPAREN
        function_body_statement

    rule while_statement:
        "while" LPAREN expression RPAREN
        action_statement

    rule helper_name:
        ( "\\$display" | "\\$write" | "\\$fopen" | "\\$fdisplay"
        | "\\$fwrite" | "\\$fgetc" | "\\$fflush" | "\\$fclose" | "\\$ungetc"
        | "\\$finish" | "\\$stop" | "\\$dumpon" | "\\$dumpoff" | "\\$dumpvars"
        | "\\$test\\$plusargs" | "\\$time" | "\\$stime"
        )

    rule helper_statement:
        helper_name
        [ LPAREN expression (COMMA expression)* RPAREN ]
        SEMICOLON

    rule function_body_statement:
        let_statement
        | for_statement
        | function_statement
        | case_statement
        | if_statement
        | group_statement
        | helper_statement
        | seq_statement
        | par_statement
        | ifdef_statement
        | action_statement
        | match_statement
        | return_statement
        #| rule_statement
        #| attribute_statement
        | actionvalue_statement
        | while_statement
        | variable_declaration_or_call
        # method_declaration cannot be in this rule!! (method declaration cannot be recursive)
        #messes up 'method' | interface_declaration

    rule statement_list:
        ( function_body_statement )+

    rule module_item:
        ( function_body_statement
        | rule_statement
        | method_declaration
        | attribute_statement
        | interface_declaration
        )*

    rule top_level_statement:
        typedef_declaration
        | function_statement
        | instance_statement
        | import_declaration
        | interface_declaration
        | attribute_statement
        | method_declaration
        | module_declaration
        | let_statement
        | package_statement
        | typeclass_statement
        | define_declaration
        | include_declaration
        | variable_declaration
        | ifdef_statement

    rule package_statement_list:
        ( typedef_declaration
        | import_declaration
        | define_declaration
        | interface_declaration
        | module_declaration
        | variable_declaration
        | attribute_statement
        | function_statement
        )*

    rule group_statement:
        BEGIN
        ( function_body_statement )*
        END

    rule seq_statement:
        "seq"
        ( function_body_statement )*
        "endseq"

    rule par_statement:
        "par"
        ( function_body_statement )*
        "endpar"

    rule method_body:
        SEMICOLON
        [
            statement_list
            "endmethod" [ COLON VAR]
        ]

    rule method_declaration:
        "method" 
        ( "Action" VAR  argument_list
            [ "if"  LPAREN expression RPAREN ]
            [ EQUAL expression ]
            method_body
        | "ActionValue"
            [ HASH LPAREN expression RPAREN ]
            VAR [ argument_list ]
            [ "if"  LPAREN expression RPAREN ]
            method_body
        | ("Type" | Type_item_basic | VAR [ Type_named_sub ]) [ VAR ]  [ argument_list ]
            [ ( ( "if" | "clocked_by" | "reset_by" | "enable" | "ready")
                LPAREN expression RPAREN 
              )*
            ]
            [ EQUAL expression ]
            method_body
        #| [ output_port ] VAR
        #    LPAREN LBRACE input_ports RBRACE RPAREN
        #    [ "enable" enable_port ]
        #    [ "ready" ready_port ] [ "clocked_by" VAR ]
        #    [ "reset_by" VAR] SEMICOLON
        )

    rule interface_arg:
        ["numeric"] "type" VAR
        | expression

    rule interfaceTypesub:
        HASH LPAREN interface_arg (COMMA interface_arg )* RPAREN

    rule subinterface_declaration:
        "interface" VAR
        ( subinterface_body
        | interfaceTypesub subinterface_body
        | EQUAL expression SEMICOLON
        )

    rule subinterface_body:
        VAR SEMICOLON

    rule maininterface_body:
        SEMICOLON
        #| SEMICOLON
            ( method_declaration
            | attribute_statement
            | subinterface_declaration
            )+
            "endinterface" [ COLON VAR ]

    rule interface_declaration:
        "interface" VAR [VAR]
        ( maininterface_body
        | interfaceTypesub maininterface_body
        | EQUAL expression SEMICOLON
        )

    rule match_arg:
        DOT term<<[]>>

    rule match_statement:
        "match"
        LBRACE match_arg (COMMA match_arg)* RBRACE EQUAL expression SEMICOLON

    rule module_param:
        Type_item_or_name [ VAR ] [ STAR ]

    rule module_declaration:
        "module" [ LBRACKET "Module" RBRACKET ] VAR [ HASH  argument_list ]
        LPAREN [ module_param (COMMA module_param)* ] RPAREN provisos
        module_item
        "endmodule" [ COLON VAR]

    rule package_statement:
        "package" VAR SEMICOLON
        package_statement_list
        "endpackage" [ COLON  VAR]

#    Type_item_or_name VAR LARROW VAR argument_list SEMICOLON
#    Type_item_or_name VAR LARROW VAR argument_list COMMA
#        "clocked_by" VAR COMMA
#        "reset_by" reset_name ] RPAREN SEMICOLON

    rule tagged_match_arg:
        VAR COLON DOT VAR

    rule rule_predicate:
        LPAREN
        expression
        [ MATCHES "tagged" VAR
            ( LBRACE tagged_match_arg (COMMA tagged_match_arg)* RBRACE
            | DOT VAR
            )
        ]
        RPAREN

    rule rule_statement:
        "rule" VAR [rule_predicate] SEMICOLON
        ( function_body_statement )*
        "endrule" [ COLON  VAR ]

    rule rules_statement:
        "rules" [ COLON  VAR]
        (rule_statement)*
        (variable_declaration_or_call SEMICOLON)*
        "endrules" [ COLON  VAR]

    rule action_statement:
        "action" [ COLON  VAR] [ SEMICOLON ]
        ( function_body_statement )*
        "endaction" [ COLON VAR]

    rule Type_item_basic:
        ( "Bit#" | "Int#" | "Uint#" | "ComplexF#" | "Reg#" | "FIFO#" | "Maybe#" )
           LPAREN expression RPAREN
        | ("Vector#" | "Tuple2#" | "FixedPoint#")
           LPAREN expression (COMMA expression)* RPAREN
        | "Integer" | "Bool" | "String"
        | "Nat"

    rule Type_item:
        Type_item_basic
        | "Action" | "ActionValue#" LPAREN Type_item_or_name RPAREN

#    "type identifier LARROW assign_value SEMICOLON
#    identifier LARROW assign_value SEMICOLON

    rule dot_field:
        DOT VAR

    rule case_statement:
        "case" LPAREN expression RPAREN
        ( MATCHES
          ( "tagged"
             #(
             VAR 
#( "Just" | "Load" | "Store" | "Add" | "Sub"
               #| "Mul" | "Div" | "Cond" | "Jump" | "SetPrefetch"
               #| "ForwardSrc" | "ForwardDest" | "Op"
               #| "ArithmeticInstruction"
               #| "Branch" | "CWData_Bit" | "DAdd" | "DEC_FUU"
               #| "DFBLuma" | "Imm0"
               #| "Left" | "LoadPage" | "LoadReq" | "LoadServiced"
               #| "NewUnit" | "Pass" | "RowSize" | "SetReg"
               #| "StoreReq" | "TV_V" | "Valid"
               #)
                 [ dot_field | LBRACE dot_field (COMMA dot_field)* RBRACE ]
             #| "Invalid"
             #| "Nil"
             #| "Nothing"
             #| "Stop"
             #)
              COLON function_body_statement
          | "default" COLON function_body_statement
          )*
        | ((VAR | NUM) (COMMA (VAR | NUM))* COLON 
                function_body_statement
          | "default" COLON function_body_statement
          )*
        )
        "endcase"

    rule let_statement:
        "let"
        ( VAR
        | LBRACE VAR (COMMA VAR)* RBRACE
        )
        ( EQUAL | LARROW )
        assign_value SEMICOLON

#    register_name LEQ expression SEMICOLON

    rule Typeclass: VAR

    rule type_variable: VAR

    rule Elements: term<<[]>> [EQUAL expression]

    rule TypeClass:
        "Eq" | "Bits"

    rule deriving_clause:
        "deriving"  LPAREN Typeclass ( COMMA TypeClass )* RPAREN

    rule struct_arg:
        [ "numeric" ] "type" type_variable

    rule struct_arg_list:
        LPAREN struct_arg (COMMA struct_arg)* RPAREN

    rule typedef_declaration:
        "typedef" 
        Member

    rule Member:
        ( ( "type" | Type_item_or_name | NUM ) [VAR]
            [ HASH struct_arg_list ] SEMICOLON
        | "enum" LBRACE Elements ( COMMA Elements )* RBRACE VAR
            [ deriving_clause ] SEMICOLON
        | "struct" LBRACE
            ( Type_item_or_name VAR SEMICOLON )* RBRACE
            VAR [ HASH struct_arg_list ]
            [ deriving_clause ] SEMICOLON
        | "union" "tagged"
            LBRACE (Member)+ RBRACE
            VAR
            [ HASH
                ( struct_arg
                | struct_arg_list
                )
            ]
            [ deriving_clause ] SEMICOLON
        )

#    "Type" variable_name  EQUAL "Type" LBRACE member COLON expression RBRACE
#        "Coord" c1  EQUAL Coord{x COLON 1 COMMA y COLON foo}SEMICOLON

#    "Type" variable_name  EQUAL Member expression SEMICOLON
#    "tagged" "Member" [ pattern ]
#    "tagged" "Type" [ member COLON pattern ]
#    "tagged" { pattern COMMA pattern }
#    "case"  LPAREN f LPAREN a RPAREN RPAREN  matches
#        "tagged" "Valid" .x  COLON  return x SEMICOLON
#        "tagged" "Invalid"  COLON  return 0 SEMICOLON
#    "endcase"
#    if  LPAREN x matches tagged Valid .n &&& n > 5 ... RPAREN
#    "match" pattern  EQUAL expression SEMICOLON

    rule argument_item:
        ( FUNCTION 
            ( "Action" VAR
            | VAR
            )
            [ HASH LPAREN VAR (COMMA VAR)* RPAREN ]
            [VAR]
            LPAREN argument_item (COMMA argument_item)* RPAREN
        | Type_item_or_name [ VAR ]
        )

    rule argument_list:
        LPAREN [ argument_item ( COMMA argument_item)* ] RPAREN

    rule variable_assignment_or_call:
        term<<[]>>
        ( EQUAL expression SEMICOLON
        | LEQ expression SEMICOLON
        | SEMICOLON
        )

    rule if_statement:
        "if" LPAREN expression RPAREN
           function_body_statement [ "else" function_body_statement ]

    rule actionvalue_statement:
        "actionvalue"
        ( return_statement
        | let_statement
        | case_statement
        | expression SEMICOLON
        )*
        "endactionvalue"

    rule function_header:
        FUNCTION Type_item_or_name [function_name] [ argument_list ]

    rule function_statement:
        function_header
        ( EQUAL expression SEMICOLON
        | provisos
            [ (function_body_statement)+
              "endfunction" [ COLON  function_name]
            ]
        )

    rule path_statement:
        "path" LPAREN VAR COMMA VAR RPAREN  SEMICOLON

    rule instance_arg:
        Type_item_or_name

    rule instance_statement:
        "instance" VAR HASH LPAREN instance_arg ( COMMA instance_arg )* RPAREN
            provisos
        (function_statement)*
        "endinstance"

    rule dep_item:
        VAR "determines" VAR

    rule typeclass_statement:
        "typeclass" VAR interfaceTypesub
        [ "dependencies" LPAREN dep_item (COMMA dep_item)* RPAREN ]
        SEMICOLON
        (function_header SEMICOLON)*
        "endtypeclass" COLON VAR

    rule define_declaration:
        "`define" VAR expression

    rule include_declaration:
        "`include" STR

    rule ifdef_statement:
        "`ifdef" [VAR]
           ( function_body_statement )*
        "`endif"

    rule goal:
        (top_level_statement)* ENDTOKEN

%%
############jca
import string

if __name__=='__main__':
    #print 'args', sys.argv
    #print 'args1', sys.argv[1]
    s = open(sys.argv[1]).read()
    # line continuation in string literals not handled by runtime
    s = string.replace(s, "\\\n", "  ")
    s1 = parse('goal', s)
    #print 'Output:', s1
    #print 'Bye.'

