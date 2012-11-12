# This parser can parse a simple subset of Lisp's syntax.

parser Lisp:
    ignore:      r'\s+'
    token NUM:   r'[0-9]+'
    token ID:    r'[-+*/!@$%^&=.a-zA-Z0-9_]+'
    token STR:   r'"([^\\"]+|\\.)*"'

    rule expr:   ID              {{ return ('id',ID) }}
               | STR             {{ return ('str',eval(STR)) }}
               | NUM             {{ return ('num',int(NUM)) }}
               | r"\("           
                        {{ e = [] }}             # initialize the list
                 ( expr {{ e.append(expr) }} ) * # put each expr into the list
                 r"\)"  {{ return e }}           # return the list
