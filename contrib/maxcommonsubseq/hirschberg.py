# Copyright (c) 2014 Quanta Research Cambridge, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
# ASIC project
# This code implements Hirschberg's longest common subsequence algorithm from
# CACM June 1975
# Given strings A and B of lengths m and n, this runs in O(mn) time and O(m + n) space
# with recursion depth O(lg n)
from __future__ import print_function

try:
    xrange
except NameError:
    xrange = range  # Python 3 compatibility

# compute maximal length subsequence of A and B
# returns a full matrix L, where L[i][j] is the longest common subsequence in 
# the prefixes A[:i] B[:j] up to L[m][n] which is the answer
# uses O(mn) time and O(mn) space

def hirschbergalga(A, B):
    m = len(A)
    n = len(B)
    L = [[0 for j in xrange(n+1)] for i in xrange(m+1)]
    for i in xrange(1, m+1):
        L[i][0] = 0
    for j in xrange(1, n+1):
        L[0][j] = 0
    for i in xrange(1, m+1):
        for j in xrange(1, n+1):
            if A[i-1]==B[j-1]:
                L[i][j] = L[i-1][j-1] + 1
            else:
                L[i][j] = max(L[i][j-1], L[i-1][j])
    return L

# should be 2
hirschbergalga("   a b c   ", "xxbsscee")


# compute the length of the longest common subsequence
# returns the last row of the L matrix above, namely L[m][j] for j in [0..m]
# uses O(mn) time and O(n) space.
# It is prudent to pass B as the shorter argument
def hirschbergalgb(A, B):
    m = len(A)
    n = len(B)
    K = [[0 for j in xrange(n+1)] for i in xrange(2)]
    for i in xrange(1,m+1):
        for j in xrange(1,n+1):
            K[0][j] = K[1][j]
        for j in xrange(1, n+1):
            if A[i-1]==B[j-1]:
                K[1][j] = K[0][j-1] + 1
            else:
                K[1][j] = max(K[1][j-1], K[0][j])
    LL = [K[1][j] for j in xrange(n+1)]
    return(LL)

# returns the actual longest common subsequence, as a string
# The natural order of execution will return the parts of the answer <in order> so the results
# could be pushed into a stream or fifo
def hirschbergalgc(A, B):
    print("algC ", A, B)
    m = len(A)
    n = len(B)
    if n == 0:
        return ""
    if m == 1:
        if A[0] in B:
            return A
        else:
            return ""
    i = m / 2
    # solve the forward problem, using string prefixes
    L1 = hirschbergalgb(A[0:i], B)
    print("algB ", " A ", A[0:i], " B ", B, " L1 ", L1)
    # solve the reverse problem, using string suffixes
    L2 = hirschbergalgb(A[i:][::-1], B[::-1])
    print("algB ", " A ", A[i:][::-1], " B ", B, " L2 ", L2)
    # find k, the j at which m is maximized
    m = -1
    for j in xrange(n+1):
        t = L1[j] + L2[n-j];
        if t > m:
            m = t
            k = j
    # given break points i and k, solve the two subproblems recursively
    C1 = hirschbergalgc(A[0:i],B[0:k])
    C2 = hirschbergalgc(A[i:], B[k:])
    return C1 + C2

def hirschbergalgc2(sa, sb, A, B):
    m = len(A)
    n = len(B)
    print("algC ", "sa ", sa, " la ", m, " sb ", sb, " lb ", n, A, B)
    if n == 0:
        return ""
    if m == 1:
        if A[0] in B:
            return A
        else:
            return ""
    i = m / 2
    print("m= ", m, " i = ", i)
    # solve the forward problem, using string prefixes
    L1 = hirschbergalgb(A[0:i], B)
    print("algB ", " A ", A[0:i], " B ", B, " L1 ", L1)
    # solve the reverse problem, using string suffixes
    L2 = hirschbergalgb(A[i:][::-1], B[::-1])
    print("algB ", " A ", A[i:][::-1], " B ", B, " L2 ", L2)
    # find k, the j at which m is maximized
    m = -1
    for j in xrange(n+1):
        t = L1[j] + L2[n-j];
        if t > m:
            m = t
            k = j
    # given break points i and k, solve the two subproblems recursively
    C1 = hirschbergalgc2(sa, sb, A[0:i],B[0:k])
    C2 = hirschbergalgc2(sa +i, sb + k, A[i:], B[k:])
    return C1 + C2


strA = "___a_____b______c____"
strB = "..a........b.c....";    
strA = "012a45678b012345c7890";
strB = "ABaDEFGHIJKbMcOPQR";
    
hirschbergalgc2(0, 0, strA, strB)
