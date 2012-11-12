""" kifExpr.g -- a Yapps grammar for KIF Expressions
$Id: kifExpr.g,v 1.1 2001/09/03 17:22:00 connolly Exp $

References

Knowledge Interchange Format

       draft proposed American National Standard (dpANS)

                           NCITS.T2/98-004
Knowledge Interchange Format
http://logic.stanford.edu/kif/dpans.html
Thu, 25 Jun 1998 22:31:37 GMT

@@Yapps
"""

%%

parser KIFParser:

    # 4.2 Characters
    # 4.3 Lexemes

    ignore: r'[ \t\r\n\f]+'

    #  upper ::= A | B | C ...| Z
    #  lower ::= a | b | c ... | z
    #  digit ::= 0 | 1 | 2 ... | 9
    #  alpha ::= ! | $ | % | & | * | + | - | . | / | < | = | > | ? |
    #            @ | _ | ~ |
    #  special ::= " | # | ' | ( | ) | , | \ | ^ | `
    #  white ::= space | tab | return | linefeed | page
    #  normal ::= upper | lower | digit | alpha

    # "There are five types of lexemes in KIF -- special lexemes, #
    # words, character references, character strings, and # character
    # blocks."

    # word ::= normal | word normal | word\character

    token word: r'[A-Za-z0-9!$%&*+\-\./<=>?@_~]([A-Za-z0-9!$%&*+\-\./<=>?@_~]|(\\.))*' #@@ backslash-newline?

    # charref ::= #\character
    token charref: r'#\\[.\n]'


    #  string ::= "quotable"
    #  quotable ::= empty | quotable strchar | quotable\character
    #  strchar ::= character - {",\}
    token string: r'"([^\"\\]|\\.)*"' #@@ backslash-newline?

    # block ::= # int(n) q character^n | # int(n) Q character^n
    token block: r'#\d+.*' # @@block will require custom code in the Scanner

    #  indvar ::= ?word
    token indvar: r'\?[A-Za-z0-9!$%&*+\-\./<=>?@_~]([A-Za-z0-9!$%&*+\-\./<=>?@_~]|\\[.\n])*'

    #  seqvar ::= @word
    token seqvar: r'@?[A-Za-z0-9!$%&*+\-\./<=>?@_~]([A-Za-z0-9!$%&*+\-\./<=>?@_~]|\\[.\n])*'



    #  variable ::= indvar | seqvar
    rule variable: indvar | seqvar

    #  operator ::= termop | sentop | defop
    rule operator: termop | sentop | defop

    #  termop ::= value | listof | quote | if
    rule termop : "value" | "listof" | "quote" | "if"

    #  sentop ::= holds | = | /= | not | and | or | => | <= | <=> |
    #             forall | exists
    rule sentop : "holds" | "=" | "/=" | "not" | "and" | "or" 
		  | "=>" | "<=" | "<=>" | "forall" | "exists"

    #  defop ::= defobject | defunction | defrelation | deflogical |
    #            := | :-> | :<= | :=>
    rule defop: "defobject" | "defunction" | "defrelation" | "deflogical"
              | ":=" | ":->" | ":<=" | ":=>"


    # constant ::= word - variable - operator
    rule constant: word #@@hmm... does ordering work here?


    # 4.4 Expressions

    rule term: indvar | constant | charref | string | block | quoterm
    # | funterm #@@ not LL(1)
    # | listterm #@@ not LL(1)
    # | logterm #@@ not LL(1)

    rule quoterm: "\\(" "quote" listexpr "\\)" | "'" listexpr

    rule listexpr: atom | "\\(" listexpr* "\\)"

    rule atom: word | charref | string | block

