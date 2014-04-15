

# Step 1 is Gotoh's algorithm]
# arrays C[0..m, 0..n], D[0..m, 0..n] I[0..M, 0..N]
# scalar t
# paramters w(a, b), g, h
# where w(a,b) is the cost of converting a to b
# and cost of a gap is g + hk where k is the length ofthe gap

# C(i,j) is the minimum cost of converting A(0..i) to B(0..j)
# D(i,j) is the minimum cost of converting A(0..i) to B(0..j) when ai is deleted
# C(i,j) is the minimum cost of converting A(0..i) to B(0..j) when bj is inserted
# 

def w(a, b):
    if (a == b):
        return 0.0
    else:
        return 1.0

g = 2.0
h = 0.5

def gap(k):
    return g + (k * h)

def gotoh(A, B):
    m = len(A)
    n = len(B)
    C = [[0 for j in xrange(n+1)] for i in xrange(m+1)]
    D = [[0 for j in xrange(n+1)] for i in xrange(m+1)]
    I = [[0 for j in xrange(n+1)] for i in xrange(m+1)]
    C[0][0] = 0
    for j in xrange(1,n+1):
        C[0][j] = gap(j)
        D[0][j] = C[0][j] + g
    for i in xrange(1,m+1):
        C[i][0] = gap(i)
        I[i][0] = C[i][0] + g
        for j in xrange(1,n+1):
            I[i][j] = min(I[i][j-1], C[i][j-1] + g) + h
            D[i][j] = min(D[i-1][j], C[i-1][j] + g) + h
            C[i][j] = min(D[i][j], I[i][j], C[i-1][j-1] + w(A[i-1], B[j-1]))
    print A, B, D, I, C

A = "agtac"
B = "aag"
goto(A, B)


# The recurrances in Gotoh only depend on the previous row, so
# in a manner analagous to the conversion from Hirschberg algorithm A
# to Hirschberg algorithm B we can write algorithm gotohb that uses
# only two row vectors CC and DD

def gotohb(A, B):
    m = len(A)
    n = len(B)
    e = 0
    c = 0
    s = 0
    t = 0
    CC = [0 for j in xrange(n+1)]
    DD = [0 for j in xrange(n+1)]
