# This calculator on ints supports the usual (numbers, add, subtract,
# multiply, divide), global variables (stored in a global variable in
# Python), and local variables (stored in an attribute passed around
# in the grammar).

globalvars = {}       # We will store the calculator's variables here

def lookup(map, name):
    for x, v in map:  
        if x == name: return v
    if not globalvars.has_key(name): 
        print 'Undefined (defaulting to 0):', name
    return globalvars.get(name, 0)

%%
parser Calculator:
    ignore:    "[ \r\t\n]+"
    token END: "$"
    token NUM: "[0-9]+"
    token VAR: "[a-zA-Z_]+"

    # Each line can either be an expression or an assignment statement
    rule goal:   expr<<[]>> END            {{ return expr }}
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
                     )*                   {{ return v }}

    # A term is a number, variable, or an expression surrounded by parentheses
    rule term<<V>>:   
                 NUM                      {{ return int(NUM) }}
               | VAR                      {{ return lookup(V, VAR) }}
               | "\\(" expr<<V>> "\\)"    {{ return expr }}
               | "let" VAR "=" expr<<V>>  {{ V = [(VAR, expr)] + V }}
                 "in" expr<<V>>           {{ return expr }}
%%

tests = [
    ('3', 3),
    ('2 * 3', 6),
    ('set x 5', 5),
    ('x', 5),
    ('x / 2', 2),
    ('x - 1', 4),
    ('let x = 3 in x + 1', 4),
    ('x', 5),
    ('x + let x = 3 in x', 8),
    ('(let x = 3 in x) + x', 8),
]

def run_tests():
    for (expr, value) in tests:
        assert parse('goal', expr) == value, 'Test parse(%r) == %s failed' % (expr, value)
    globalvars.clear()

            
if __name__=='__main__':
    run_tests()

    print 'Welcome to the calculator sample for Yapps 2.'
    print '  Enter either "<expression>" or "set <var> <expression>",'
    print '  or just press return to exit.  An expression can have'
    print '  local variables:  let x = expr in expr'
    # We could have put this loop into the parser, by making the
    # `goal' rule use (expr | set var expr)*, but by putting the
    # loop into Python code, we can make it interactive (i.e., enter
    # one expression, get the result, enter another expression, etc.)
    while 1:
        try: s = raw_input('>>> ')
        except EOFError: break
        if not s.strip(): break
        print '=', parse('goal', s)
    print 'Bye.'

