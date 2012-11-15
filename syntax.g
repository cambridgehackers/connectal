globalvars = {}       # We will store the calculator's variables here
def lookup(map, name):
    print "lookup", map, name
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
    token BEGIN: "begin"
    token END: "end"
    token ENDTOKEN: "$"
    token NUM: "[0-9]+"
    token VAR: "[a-zA-Z_][a-zA-Z0-9_]*"
    token STR:   r'"([^\\"]+|\\.)*"'
    token LPAREN: "\\("
    token RPAREN: "\\)"
    token HASH: "#"
    token DOT: r"[\\.]"
    token COMMA: ','
    token COMMA2: ","
    token COLON: ':'
    token SEMICOLON: ';'
    token LBRACKET: "\\["
    token RBRACKET: "\\]"
    token LBRACE: "{"
    token RBRACE: "}"
    token QUESTION: "\\?"
    token CARET: "\\^"
    token LESS: "<"
    token LESSLESS: "<<"
    token LEQ: "<="
    token LARROW: "<-"
    token EQEQ: "=="
    token EQUAL: "="
    token STAR: "[*]"

    rule case_value:
        "case" LPAREN expression RPAREN
        (VAR COLON 'return' expression SEMICOLON )*
        "endcase"

    # Each line can either be an expression or an assignment statement
    rule gggoal:   expr<<[]>> ENDTOKEN            {{ return expr }}
               | "set" VAR expr<<[]>> ENDTOKEN  {{ globalvars[VAR] = expr }}
                                           {{ return expr }}

    # An expression is the sum and difference of factors
    rule expr<<V>>:   factor<<V>>         {{ n = factor }}
                     ( "[+]" factor<<V>>  {{ n = n+factor }}
                     |  "-"  factor<<V>>  {{ n = n-factor }}
                     )*                   {{ return n }}

    # A factor is the product and division of terms
    rule factor<<V>>: term<<V>>           {{ v = term }}
                     ( STAR term<<V>>    {{ v = v*term }}
                     |  "/"  term<<V>>    {{ v = v/term }}
                     |  CARET  term<<V>>
                     |  LESS  term<<V>>
                     |  ">"  term<<V>>
                     |  LESSLESS  term<<V>>
                     |  ">>"  term<<V>>
                     |  EQEQ  term<<V>>
                     |  "!="  term<<V>>
                     |  QUESTION term<<V>> COLON  term<<V>>
                     )*                   {{ return v }}

    rule fieldname: VAR

    rule typefieldname: VAR

    rule call_arg:
        ( expr<<[]>>
        | QUESTION
        )
    # A term is a number, variable, or an expression surrounded by parentheses
    rule term<<V>>:
               case_value
               | NUM  [ "\\'b" NUM ]      {{ return int(NUM) }}
               | VAR 
                    ( DOT fieldname )*
                    [ HASH ]
                    [   ( LPAREN [ call_arg ( COMMA call_arg )* ] RPAREN
                        | LBRACE typefieldname COLON expr<<V>> ( COMMA typefieldname COLON expr<<V>> )* RBRACE
                        )
                    ]
                    [ LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET ]
                    {{ return lookup(V, VAR) }}
               | STR
               | LPAREN expr<<V>> RPAREN ( DOT fieldname )*
                    [ LBRACKET expr<<V>> [ COLON expr<<V>> ] RBRACKET ]
                    {{ return expr }}
               | LBRACE expr<<V>> ( COMMA expr<<V>> )* RBRACE

               #| "let" VAR EQUAL expr<<V>>  {{ V = [(VAR, expr)] + V }}
               #  "in" expr<<V>>           {{ return expr }}

###########jca

    rule STRING: STR
#VAR

    rule interface_method: VAR

    rule Package_name: VAR

    rule rule_names: VAR

    rule list_rule_names: "LRN"

    rule Return_type: VAR

    rule Type: VAR

    rule action_name: VAR

    rule c_function_name: VAR

    rule clock_name: VAR

    rule enable: VAR

    rule enable_port: VAR

    rule expression: expr<<[]>>

    rule function_name: VAR
        | '\\\\\\+'
        | '\\\\\\-'
        | '\\\\\\*'

    rule ifc_name: VAR

    rule importBVI_statements: "IMPBVI"

    rule input_ports: VAR

    rule interface_method_definitions: "IFCMETHDEF"

    rule module_instantiations: "MODINSTANC"

    rule module_name: VAR

    rule module_statements: "MODSTA"

    rule output_port: VAR

    rule port_name1: VAR

    rule port_name2: VAR

    rule provisos: "provisos" LPAREN expression (COMMA expression )* RPAREN

    rule ready_port: VAR

    rule return_statement: "return" expression SEMICOLON

    rule rule_name: VAR

    rule rule_predicate: LPAREN expression RPAREN

    rule rules_name: VAR

    rule verilog_module_name: VAR

    rule attribute:
        "synthesize"
        | "RST_N"  EQUAL STRING
        | "CLK"  EQUAL STRING
        | "always_ready" [ EQUAL interface_method ]
        | "always_enabled" [ EQUAL interface_method ]
        | "descending" "urgency" EQUAL LBRACE rule_names RBRACE
        | "preempts" [ EQUAL ] LBRACE rule_names COMMA  LPAREN list_rule_names RPAREN RBRACE
        | "doc" EQUAL STRING
        | "ready" EQUAL STRING
        | "enable" EQUAL STRING
        | "result" EQUAL STRING
        | "prefix" EQUAL STRING
        | "port"  EQUAL STRING
        | "noinline"
        | "fire_when_enabled"
        | "no_implicit_conditions"

    rule attribute_statement:
         "\\([*]" attribute [ EQUAL expression ] "[*]\\)"

    rule Type_item_or_name:
        Type_item
        | VAR [ HASH LPAREN expression (COMMA expression )* RPAREN ]

    rule Ifc_type: Type_item_or_name

    rule import_statements:
        "import"
        ( "BDPI" [ c_function_name  EQUAL ] "function" Return_type
            function_name [ LBRACE arguments RBRACE ] RPAREN  [ provisos ] SEMICOLON
        | "BVI" [verilog_module_name]  EQUAL
            "module" [ Type ] module_name [ HASH  LPAREN parameter RPAREN ]
            LPAREN Ifc_type ifc_name RPAREN  [ provisos ] SEMICOLON
            module_statements
            importBVI_statements
            "endmodule" [ COLON  module_name ]
        | Package_name  "::"  STAR SEMICOLON
        )

    rule for_statement:
        "for" LPAREN
            Type_item_or_name VAR EQUAL expression SEMICOLON
            expression SEMICOLON
            variable_assignment RPAREN
        BEGIN
            ( let_statement
            | if_statement
            | variable_declaration_or_call
            )*
        END

    rule method_body_statements:
        ( let_statement
        | for_statement
        | return_statement
        | variable_declaration_or_call
        )+

    rule method_name: VAR

    rule method_predicate: expression

    rule method_declarations:
        "method" 
        ( "Type" method_name  [ LPAREN parameter RPAREN ]
            [ "if"  LPAREN method_predicate RPAREN ] SEMICOLON
            [ method_body_statements
              "endmethod" [ COLON method_name]
            ]
        | "Action" method_name  LPAREN parameter RPAREN
            [ "if"  LPAREN method_predicate RPAREN ] SEMICOLON
            [ method_body_statements
              "endmethod" [ COLON method_name]
            ]
        | "ActionValue"
            [ HASH LPAREN expression RPAREN ]
            method_name LPAREN [ parameter ] RPAREN
            [ "if"  LPAREN method_predicate RPAREN ] SEMICOLON
            [ method_body_statements
              #return_statement
              "endmethod" [ COLON method_name]
            ]
        | [ output_port ] method_name
            LPAREN LBRACE input_ports RBRACE RPAREN
            [ enable enable_port ]
            [ "ready" ready_port ] [ "clocked_by" clock_name ]
            [ "reset_by" clock_name] SEMICOLON
        )

    rule subinterface_declarations: "SUBINTER"

    rule interface_declarations:
        "interface" ifc_name 
        ( SEMICOLON
            ( method_declarations
# ";"
            #| subinterface_declarations
            )*
            "endinterface" [ COLON ifc_name ]
        | HASH LPAREN "type" Type_name RPAREN SEMICOLON
            ( method_declarations
# ";"
            #| subinterface_declarations
            )*
            "endinterface" [ COLON ifc_name ]
        )

    rule variable_assignment:
        term<<[]>>
        ( EQUAL | LEQ ) expression
        #VAR [ LBRACKET expression [ COLON expression ] RBRACKET ]
        #(EQUAL | LEQ) expression

    rule variable_declaration:
        Type_item_or_name VAR [ ( EQUAL | LARROW ) expression ] SEMICOLON

    rule variable_declaration_or_call:
        ( Type_item VAR [ ( EQUAL | LARROW ) expression ]
        | term<<[]>> [   ( VAR [ ( EQUAL | LARROW ) expression ]
                         | ( EQUAL | LEQ ) expression
                         )
                     ]
        ) SEMICOLON

    rule variable_declaration_and_initializations:
        let_statement
        | variable_declaration_or_call

    rule module_declarations:
        "module" [ LBRACKET "Module" RBRACKET ] module_name [ HASH  LPAREN parameter RPAREN ]
        LPAREN [ Ifc_type ] [ ifc_name ] [ STAR ] RPAREN [provisos] SEMICOLON
        ( module_instantiations
        | rule_statements
        | interface_method_definitions
        | return_statement
        | function_statement
        | rule_statement
        | method_declarations
        | for_statement
        | variable_declaration_and_initializations
        )*
        "endmodule" [ COLON module_name]

    rule package_statement:
        "package" Package_name SEMICOLON
        typedef_statements
        import_statements
        interface_declarations
        module_declarations
        "endpackage" [ COLON  Package_name]

#    Ifc_type ifc_name LARROW module_name LPARENparameterRPAREN SEMICOLON
#    Ifc_type ifc_name LARROW module_name LPAREN[parameter COMMA2
#        "clocked_by" clock_name COMMA2
#        "reset_by" reset_name ] RPAREN SEMICOLON

    rule rule_statements: "RULEST"

    rule rule_statement:
        "rule" rule_name [rule_predicate] SEMICOLON
        action_statements
        "endrule" [ COLON  rule_name ]

    rule rules_statement:
        "rules" [ COLON  rules_name]
        rule_statements
        (variable_declaration_or_call SEMICOLON)*
        "endrules" [ COLON  rules_name]

    rule action_statement:
        "action" [ COLON  action_name] [ SEMICOLON ]
        action_statements
        "endaction" [ COLON action_name]

    rule Type_name: VAR

    rule Type_item:
        ( "Bit#" | "Int#" | "Uint#" | "ComplexF#" | "Reg#" | "FIFO#" | "Maybe#" ) LPAREN expression RPAREN
        | "Integer" | "Bool" | "String" | "Action" | "ActionValue#" LPAREN VAR RPAREN
        | "Nat"

#    "type identifier LARROW expression SEMICOLON
#    identifier LARROW expression SEMICOLON

    rule let_statement:
        "let" VAR  ( EQUAL | LARROW ) expression SEMICOLON

#    register_name LEQ expression SEMICOLON

    rule Typeclass: VAR

    rule type_variable: VAR

    rule Elements: VAR

    rule Member: VAR

    rule TypeClass:
        "Eq" | "Bits"

    rule deriving_clause:
        "deriving"  LPAREN Typeclass ( COMMA TypeClass )* RPAREN
    rule typedef_statements:
        "typedef" 
        ( "type" Type_name [ HASH LPAREN ( "type" type_variable ) RPAREN ] SEMICOLON
        | "enum" LBRACE ( Elements )* RBRACE Type_name
            [ deriving_clause ] SEMICOLON
        | "struct" LBRACE ( Type_item VAR SEMICOLON )* RBRACE
            Type_name [ HASH LPAREN [ "numeric" ] "type" type_variable RPAREN ]
                [ deriving_clause ] SEMICOLON
        | "union" "tagged"
            LBRACE "type" Member SEMICOLON RBRACE
            Type_name [ HASH [ "numeric" ] "type" type_variable ] SEMICOLON
        )

#    "Type" variable_name  EQUAL "Type" LBRACE member COLON expression RBRACE
#        "Coord" c1  EQUAL Coord{x COLON 1 COMMA2 y COLON foo}SEMICOLON

#    "Type" variable_name  EQUAL Member expression SEMICOLON
#    "tagged" "Member" [ pattern ]
#    "tagged" "Type" [ member COLON pattern ]
#    "tagged" { pattern COMMA2 pattern }
#    "case"  LPAREN f LPAREN a RPAREN RPAREN  matches
#        "tagged" "Valid" .x  COLON  return x SEMICOLON
#        "tagged" "Invalid"  COLON  return 0 SEMICOLON
#    "endcase"
#    if  LPAREN x matches tagged Valid .n &&& n > 5 ... RPAREN
#    "match" pattern  EQUAL expression SEMICOLON

    rule argument_item:
        ( "function" 
            ( "Action" VAR
            | VAR [VAR]
            )
            LPAREN argument_item (COMMA argument_item)* RPAREN
        | Type_item_or_name VAR
        )

    rule arguments:
        argument_item ( COMMA argument_item)*

    rule parameter: arguments

    rule variable_assignment_or_call:
        term<<[]>>
        ( EQUAL expression SEMICOLON
        | LEQ expression SEMICOLON
        | SEMICOLON
        )

    rule if_item:
        ( BEGIN
            ( variable_assignment_or_call )*
          END
        | variable_assignment_or_call
        )

    rule if_statement:
        "if" LPAREN expression RPAREN
           if_item [ "else" (if_statement | if_item) ]

    rule action_statements:
        ( let_statement
        | for_statement
        | if_statement
        | variable_declaration_or_call
        )*

    rule function_body_statements:
        let_statement
        | action_statement
        | variable_declaration_or_call

    rule function_statement:
        "function" Type_item_or_name function_name  LPAREN[arguments] RPAREN
        ( EQUAL expression SEMICOLON
        | [provisos] SEMICOLON
            ( return_statement
            | function_body_statements
            )*
            "endfunction" [ COLON  function_name]
        )

#    $display $write $fopen $fdisplay $fwrite $fgetc $fflush $fclose $ungetc
#    $finish $stop $dumpon $dumpoff $dumpvars $test$plusargs $time $stime

#    "parameter" parameter_name  EQUAL expression SEMICOLON
#    "port" port_name  EQUAL expression SEMICOLON
#    "default_clock" clock_name
#        [ LPAREN port_name COMMA2 port_name RPAREN ] [ EQUAL expression ] SEMICOLON
#    "input_clock" clock_name [ LPAREN port_name COMMA2
#        port_name RPAREN ]  EQUAL expression SEMICOLON
#    "output_clock" clock_name
#         LPAREN port_name [ COMMA2 port_name ] RPAREN SEMICOLON
#    "no_reset" SEMICOLON
#    "default_reset" clock_name  LPAREN [ port_name ] RPAREN  [ EQUAL expression] SEMICOLON
#    "input_reset" clock_name  LPAREN [ port_name ] RPAREN   EQUAL expression SEMICOLON
#    "output_reset" clock_name  LPAREN port_name RPAREN SEMICOLON
#    "ancestor"  LPAREN clock1 COMMA2 clock2 RPAREN SEMICOLON
#    "same_family"  LPAREN clock1 COMMA2 clock2 RPAREN SEMICOLON

    rule schedule_statement:
         "schedule"  LPAREN ( method_name ) RPAREN  ( "CF" | "SB" | "SBR" | "C" )
         LPAREN ( method_name ) RPAREN SEMICOLON

    rule path_statement:
        "path" LPAREN port_name1 COMMA2 port_name2 RPAREN  SEMICOLON

    rule instance_arg:
        Type_item_or_name

    rule instance_statement:
        "instance" Type_name HASH LPAREN instance_arg ( COMMA instance_arg )* RPAREN
            [ provisos ] SEMICOLON
        (function_statement)*
        "endinstance"

    rule top_level_statements:
        typedef_statements
        | function_statement
        | instance_statement
        | import_statements
        | interface_declarations
        | attribute_statement
        | method_declarations
        | module_declarations
        | let_statement

    rule goal:
        (top_level_statements)* ENDTOKEN

%%
############jca

if __name__=='__main__':
    print 'args', sys.argv
    print 'args1', sys.argv[1]
    s = open(sys.argv[1]).read()
    s1 = parse('goal', s)
    print 'Output:', s1
    print 'Bye.'

