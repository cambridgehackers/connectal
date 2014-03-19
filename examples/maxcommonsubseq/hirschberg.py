# ASIC project
# This code implements Hirschberg's longest common subsequence algorithm from
# CACM June 1975
# Given strings A and B of lengths m and n, this runs in O(mn) time and O(m + n) space
# with recursion depth O(lg n)

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
        for j in xrange(n+1):
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
    # solve the reverse problem, using string suffixes
    L2 = hirschbergalgb(A[:i:-1], B[::-1])
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


    
