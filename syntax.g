globalvars = {}       # We will store the calculator's variables here
def lookup(map, name):
    print "lookup", map, name
    for x, v in map:
        if x == name: return v
    if not globalvars.has_key(name):
        print 'Undefined (defaulting to 0):', name
    return globalvars.get(name, 0)

%%
parser Calculator:
    ignore:    "[ \r\t\n]+"
    ignore:    "\\/\\/.*?\r?\n"
    token END: "$"
    token NUM: "[0-9]+"
    token VAR: "[a-zA-Z_][a-zA-Z0-9_]*"
    token STR:   r'"([^\\"]+|\\.)*"'

    # Each line can either be an expression or an assignment statement
    rule gggoal:   expr<<[]>> END            {{ return expr }}
               | "set" VAR expr<<[]>> END  {{ globalvars[VAR] = expr }}
                                           {{ return expr }}

    # An expression is the sum and difference of factors
    rule expr<<V>>:   factor<<V>>         {{ n = factor }}
                     ( "[+]" factor<<V>>  {{ n = n+factor }}
                     |  "-"  factor<<V>>  {{ n = n-factor }}
                     )*                   {{ return n }}

    # A factor is the product and division of terms
    rule factor<<V>>: term<<V>>           {{ v = term }}
                     ( "[*]" term<<V>>    {{ v = v*term }}
                     |  "/"  term<<V>>    {{ v = v/term }}
                     |  "<<"  term<<V>>
                     |  ">>"  term<<V>>
                     |  "=="  term<<V>>
                     |  "\\?"  term<<V>> ':'  term<<V>>
                     )*                   {{ return v }}

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term<<V>>:
                 NUM                      {{ return int(NUM) }}
               | VAR 
                    ( r"[\\.]" VAR
                    | [ '#' ]
                        [ "\\(" expr<<V>> [( ',' expr<<V>> )*] "\\)"
                        | "{" VAR ':' expr<<V>> [( ',' VAR ':' expr<<V>> )*] "}"
                        ]
                    )
                    [ "\\[" expr<<V>> [ ':' expr<<V>> ] "\\]" ]
                    {{ return lookup(V, VAR) }}
               | STR
               | "\\(" expr<<V>> "\\)"
                    [ "\\[" expr<<V>> [ ':' expr<<V>> ] "\\]" ]
                    {{ return expr }}
               | "{" expr<<V>> [( ',' expr<<V>> )*] "}"
               | "let" VAR "=" expr<<V>>  {{ V = [(VAR, expr)] + V }}
                 "in" expr<<V>>           {{ return expr }}

###########jca

#    token STR:   '"[^\\"]+"'

    rule STRING: VAR

    rule interface_method: VAR

    rule Package_name: VAR

    rule rule_names: VAR

    rule list_rule_names: "LRN"

    rule Ifc_type: VAR

    rule Return_type: VAR

    rule Type: VAR

    rule action_name: VAR

    rule action_statements: "ACTST"

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

    rule method_body_statements: "METHBOD"

    rule method_name: VAR

    rule method_predicate: expression

    rule module_instantiations: "MODINSTANC"

    rule module_name: VAR

    rule module_statements: "MODSTA"

    rule output_port: VAR

    rule parameter: VAR

    rule port_name1: VAR

    rule port_name2: VAR

    rule provisos: "provisos" "\\(" expression [(',' expression )* ] "\\)"

    rule ready_port: VAR

    rule return_statement: "return" expression ';'

    rule rule_name: VAR

    rule rule_predicate: expression

    rule rule_satements: "RULESST"

    rule rule_statements: "RULEST"

    rule rules_name: VAR

    rule verilog_module_name: VAR

    rule attribute:
        "synthesize"
        | "RST_N"  "=" STRING
        | "CLK"  "=" STRING
        | "always_ready" [ "=" interface_method ]
        | "always_enabled" [ "=" interface_method ]
        | "descending" "urgency" "=" "{" rule_names "}"
        | "preempts" [ "=" ] "{" rule_names ","  "\\(" list_rule_names "\\)" "}"
        | "doc" "=" STRING
        | "ready" "=" STRING
        | "enable" "=" STRING
        | "result" "=" STRING
        | "prefix" "=" STRING
        | "port"  "=" STRING
        | "noinline"
        | "fire_when_enabled"
        | "no_implicit_conditions"

    rule attribute_statement:
         "\\([*]" attribute [ "=" expression ] "[*]\\)"

    rule import_statements:
        "import"
        ( "BDPI" [ c_function_name  "=" ] "function" Return_type
            function_name [ "{" arguments "}" ] "\\)"  [ provisos ] ';'
        | "BVI" [verilog_module_name]  "="
            "module" [ [ Type ] ] module_name [ "#"  "\\(" "{" parameter "}" "\\)" ]
            "\\(" "{" Ifc_type ifc_name "}" "\\)"  [ provisos ] ';'
            module_statements
            importBVI_statements
            "endmodule" [ ":"  module_name ]
        | Package_name  "::"  "[*]" ';'
        )

    rule method_declarations:
        "method" 
        ( "Type" method_name  [ "\\(" "{" parameter "}" "\\)" ]
            [ "if"  "\\("method_predicate"\\)" ]
            ';'
            [
            method_body_statements
            return_statement
            "endmethod" [ ":" method_name]
            ]
        | "Action" method_name  "\\(" "{" parameter "}" "\\)"
            [ "if"  "\\("method_predicate"\\)" ] ';'
            method_body_statements
            "endmethod" [ ":" method_name]
        | "ActionValue" method_name "\\(" "{" parameter "}" "\\)"
            [ "if"  "\\("method_predicate"\\)" ] ';'
            method_body_statements
            return_statement
            "endmethod" [ ":" method_name]
        | [ output_port ] method_name
            "\\(" "{" input_ports "}" "\\)"
            [ enable enable_port ]
            [ "ready" ready_port ] [ "clocked_by" clock_name ]
            [ "reset_by" clock_name] ';'
        )

    rule subinterface_declarations:

    rule interface_declarations:
        "interface" ifc_name 
        ( ';'
            method_declarations
            subinterface_declarations
            "endinterface" [ ":" ifc_name ]
        | "#" "\\(" "type" Type_name "\\)" ';'
            method_declarations
            subinterface_declarations
            "endinterface" [ ":" ifc_name ]
        )

    rule module_declarations:
        "module" module_name [ "#"  "\\(" "{" parameter "}" "\\)" ]
        "\\(" "{" Ifc_type ifc_name "[*]" "}" "\\)" [provisos] ';'
        module_instantiations
        variable_declaration_and_initializations
        rule_statements
        interface_method_definitions
        "endmodule" [ ":" module_name]

    rule package_statement:
        "package" Package_name ';'
        typedef_statements
        import_statements
        interface_declarations
        module_declarations
        "endpackage" [ ":"  Package_name]

#    "Rules"
#    "Tuple2#" "\\("t1 "," t2"\\)"  ... "Tuple7#" "\\("t1 ","... "," t7"\\)"
#    "int" | "Nat" | "Maybe#" "\\(" t "\\)"
#    Type_name
#    Type_name "#" "\\(" type_variable "\\)"

#    Ifc_type ifc_name "<-" module_name "\\("{parameter}"\\)" ';'
#    Ifc_type ifc_name "<-" module_name "\\("[{parameter ","}
#        "clocked_by" clock_name ","
#        "reset_by" reset_name ] "\\)" ';'

    rule rule_statement:
        "rule" rule_name [rule_predicate] ';'
        action_statements
        "endrule" [ ":"  rule_name ]

    rule variable_assignment:
        VAR  "=" expression ';'

    rule variable_declaration:
        Type_item VAR [ "=" expression ] ';'

    rule variable_declaration_and_initializations: "VDI"

    rule rules_statement:
        "rules" [ ":"  rules_name]
        rule_satements
        #(variable_declaration | variable_assignment)
        variable_declaration
        "endrules" [ ":"  rules_name]

    rule action_statement:
        "action" [ ":"  action_name] ';'
        action_statements
        "endaction" [ ":" action_name]

    rule Type_name: VAR

    rule Type_item:
        ( "Bit#" | "Int#" | "Uint#" | "ComplexF#" ) "\\(" expression "\\)"
        | "Integer" | "Bool" | "String" | "Action" | "ActionValue#" "\\(" VAR "\\)"
        | "Nat"

#    "type identifier "<-" expression ';'
#    identifier "<-" expression ';'
#    "let" identifier  "=" expression ';'
#    "let" identifier "<-"­ expression ';'
#    register_name "<=" expression ';'

    rule Typeclass: VAR

    rule type_variable: VAR

    rule Elements: VAR

    rule Member: VAR

    rule TypeClass:
        "Eq" | "Bits"

    rule deriving_clause:
        "deriving"  "\\(" Typeclass ( ',' TypeClass )* "\\)"
    rule typedef_statements:
        "typedef" 
        ( "type" Type_name [ "#" "\\(" ( "type" type_variable ) "\\)" ] ';'
        | "enum" "{" ( Elements )* "}" Type_name
            [ deriving_clause ] ';'
        | "struct" "{" ( Type_item VAR ';' )* "}"
            Type_name [ "#" "\\(" [ "numeric" ] "type" type_variable "\\)" ]
                [ deriving_clause ] ';'
        | "union" "tagged"
            "{" "type" Member ';' "}"
            Type_name [ "#" [ "numeric" ] "type" type_variable ] ';'
        )

#    "Type" variable_name  "=" "Type" "{" member ":" expression "}"
#        "Coord" c1  "=" Coord{x ":" 1 "," y ":" foo}';'

#    "Type" variable_name  "=" Member expression ';'
#    "tagged" "Member" [ pattern ]
#    "tagged" "Type" [ member ":" pattern ]
#    "tagged" { pattern "," pattern }
#    "case"  "\\(" f "\\(" a "\\)" "\\)"  matches
#        "tagged" "Valid" .x  ":"  return x ';'
#        "tagged" "Invalid"  ":"  return 0 ';'
#    "endcase"
#    if  "\\(" x matches tagged Valid .n &&& n > 5 ... "\\)"
#    "match" pattern  "=" expression ';'

    rule arguments:
        Type_item VAR [( ',' Type_item VAR)*]

    rule function_body_statements:
        variable_declaration

    rule function_statement:
        "function" Type_item function_name  "\\("[arguments] "\\)"
        ( "=" expression ';'
        | [provisos] ';'
            ( function_body_statements
            | return_statement
            )*
            "endfunction" [ ":"  function_name]
        )

#    $display $write $fopen $fdisplay $fwrite $fgetc $fflush $fclose $ungetc
#    $finish $stop $dumpon $dumpoff $dumpvars $test$plusargs $time $stime

#    "parameter" parameter_name  "=" expression ';'
#    "port" port_name  "=" expression ';'
#    "default_clock" clock_name
#        [ "\\("port_name "," port_name "\\)" ] [ "=" expression ] ';'
#    "input_clock" clock_name [ "\\(" port_name ","
#        port_name "\\)" ]  "=" expression ';'
#    "output_clock" clock_name
#         "\\(" port_name [ "," port_name ] "\\)" ';'
#    "no_reset" ';'
#    "default_reset" clock_name  "\\(" [ port_name ] "\\)"  [ "=" expression] ';'
#    "input_reset" clock_name  "\\(" [ port_name ] "\\)"   "=" expression ';'
#    "output_reset" clock_name  "\\(" port_name "\\)" ';'
#    "ancestor"  "\\(" clock1 "," clock2 "\\)" ';'
#    "same_family"  "\\(" clock1 "," clock2 "\\)" ';'

    rule schedule_statement:
         "schedule"  "\\(" ( method_name ) "\\)"  ( "CF" | "SB" | "SBR" | "C" )
         "\\(" ( method_name ) "\\)" ';'

    rule path_statement:
        "path" "\\(" port_name1 "," port_name2 "\\)"  ';'

    rule instance_arg:
        Type_item
        | VAR

    rule instance_statement:
        "instance" Type_name "#" "\\(" instance_arg [( ',' instance_arg )* ] "\\)"
            [ provisos ] ';'
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

    rule goal:
        (top_level_statements)* END

%%
############jca

if __name__=='__main__':
    print 'args', sys.argv
    print 'args1', sys.argv[1]
    s = open(sys.argv[1]).read()
    s1 = parse('goal', s)
    print 'Output:', s1
    print 'Bye.'

