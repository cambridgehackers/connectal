parser Calculator:
    token END: "$"
    token NUM: "[0-9]+"

    rule goal:           expr END         {{ return expr }}

    # An expression is the sum and difference of factors
    rule expr:           factor           {{ v = factor }}
                       ( "[+]" factor       {{ v = v+factor }}
                       |  "-"  factor       {{ v = v-factor }}
                       )*                 {{ return v }}

    # A factor is the product and division of terms
    rule factor:         term             {{ v = term }}
                       ( "[*]" term         {{ v = v*term }}
                       |  "/"  term         {{ v = v/term }}
                       )*                 {{ return v }}

    # A term is either a number or an expression surrounded by parentheses
    rule term:           NUM              {{ return atoi(NUM) }}
                       | "\\(" expr "\\)" {{ return expr }}
