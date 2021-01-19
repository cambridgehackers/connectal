from __future__ import print_function

try:
    xrange
except NameError:
    xrange = range  # Python 3 compatibility

def printmatrix(m):
  print("%s\n" * len (m) % tuple(m))
              
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
    print("String A %s String B %s" % (A, B))
    print("Matrix C")
    printmatrix(C)
    print("Matrix D")
    printmatrix(D)
    print("Matrix I")
    printmatrix(I)
    return(C[m][n])

A = "agtac"
B = "aag"
gotoh(A, B)


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
    CC = [0 for j in xrange(n+1)]
    DD = [0 for j in xrange(n+1)]
    CC[0] = 0
    for j in xrange(1,n+1):
        CC[j] = gap(j)
        DD[j] = CC[j] + g
    # print 0, CC, DD, e, c, s
    for i in xrange(1,m+1):
        s = CC[0]
        c = gap(i)
        CC[0] = c
        e = c + g
        for j in xrange(1, n+1):
            e = min(e, c + g) + h
            DD[j] = min(DD[j], CC[j] + g) + h
            c = min(DD[j], e, s+w(A[i-1], B[j-1]))
            s = CC[j]
            CC[j] = c
    return([CC, DD])

print("Calling gotohb(%s, %s)" % (A, B))
regular = gotohb(A, B)
print(regular)

def gotohb2(A, B, t):
    m = len(A)
    n = len(B)
    e = 0
    c = 0
    s = 0
    CC = [0 for j in xrange(n+1)]
    DD = [0 for j in xrange(n+1)]
    CC[0] = 0
    for j in xrange(1,n+1):
        CC[j] = gap(j)
        DD[j] = CC[j] + g
    for i in xrange(1,m+1):
        s = CC[0]
        c = t + i * h
        CC[0] = c
        e = c + g
        for j in xrange(1, n+1):
            e = min(e, c + g) + h
            DD[j] = min(DD[j], CC[j] + g) + h
            c = min(DD[j], e, s+w(A[i-1], B[j-1]))
            s = CC[j]
            CC[j] = c
    DD[0] = CC[0]
    return([CC, DD])

print("Calling gotohb2 (%s, %s) " % ( A, B))
alternate = gotohb2(A, B, g)
print(alternate)
              
#
#
#



def gotohc(A, B, sa, sb, m, n, tb, te):
    # m = len(A) - sa
    # n = len(B) - sb
    print("in gotohc", A, B, sa, sb, m, n, tb, te)
    if n == 0:
        if m > 0:
            print("delete A[%d] through A[%d]" % (sa, sa + m - 1))
    elif m == 0:
        print("insert B[%d] through B[%d]" % (sb, sb + n - 1))
    elif m == 1:
        alt1 = min(tb, te) + h + gap(n)
        minsofar = alt1;
        jsofar = 1;
        for j in xrange(1, n+1):
            alt2 = gap(j-1) + w(A[sa + 0], B[sb + j-1]) + gap(n-j)
            if (min(alt1, alt2) < minsofar):
                minsofar = min(alt1, alt2)
                jsofar = j
        if (jsofar > 1):
            print("delete B[%d] through B[%d]" % (sb, sb + jsofar -1))
        print("convert A[%d] (%s) to B[%d] (%s) " % (sa, A[sa], sb + jsofar - 1, B[sb + jsofar - 1]))
        if jsofar < n:
            print("delete B[%d] through B[%d]" % (sb + jsofar, sb + n - 1))
    else:
        i = m >> 1
        # print "fwd rev", A, sa, i, B, sb, n
        fwd = gotohb2(A[sa : sa + i], B[sb:sb+n], tb)
        rev = gotohb2(A[sa + i:sa + m][::-1],B[sb:sb+n][::-1], te)
        minfound = 0
        minsofar = 0
        print("CC ", fwd[0], " DD ", fwd[1])
        print("RR ", rev[0], " SS ", rev[1])
        for j in xrange(0,n+1):
            t1 = fwd[0][j] + rev[0][n-j]
            t2 = fwd[1][j] + rev[1][n-j] - g
            if (minfound == 0) or (t1 < minsofar):
                mintype = 1
                minsofar = t1
                minj = j
            if (t2 < minsofar):
                mintype = 2
                minsofar = t2
                minj = j
            minfound = 1
        # minj minsofar and mintype are set
        if mintype == 1:
            print("type 1 midpoint at %d,%d" % (i, minj))
            gotohc(A,B, sa, sb, i, minj, tb, g)
            gotohc(A,B, sa+i, sb+minj, m-i, n-minj, g, te)
        else:
            print("type 2 midpoint at %d,%d" % (i, minj))
            gotohc(A,B, sa, sb, i - 1, minj, tb, 0)
            print("delete a[", sa + i, "] and a[", sa + i + 1, "]")
            gotohc(A,B, sa + i + 1, sb + minj, m - i - 1, n - minj, 0, te)

print("calling gotohc(%s, %s)" %(A, B))
gotohc(A, B, 0, 0, len(A), len(B),  g, g)
