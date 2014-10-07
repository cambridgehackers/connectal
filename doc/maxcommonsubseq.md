## Maximum Common Subsequence

A problem very much related to DNA sequence alignment is the problem of finding the longest common subsequence in a pair of strings.

Suppose we have two strings:

A = "   A  B   C    D  "
B = "........B....C.."

The longest common subsequence is "BC" even though the positions of the B and the C are different in the two strings and the gap between them is different.

It was known in 1974 how to find the answer in O(mn) time and O(mn) space where m = len(A) and n = len(B).

In 1975, Hirschberg discovered a way to find the longest common subsequence in O(mn) time but only O(m+n) space.

Hirschberg, D. S. (1975). A Linear Space Algorithm for Computing Maximal Common Subsequences. CACM, 18(6), pp 341-343.(A Linear Space Algorithm for Computing Maximal Common Subsequences)

Refer to [http://www.akira.ruc.dk/~keld/teaching/algoritmedesign_f03/Artikler/05/Hirschberg75.pdf]{

See also [http://en.wikipedia.org/wiki/Hirschberg's_algorithm](Wikipedia article on Hirschberg's Algorithm)

The straightforward way to solve this problem is via dynamic programming.   Let A_i be the first i characters of A, and B_j be the first j characters of B.

 Imagine a matrix L with m rows and n columns, such that L[i][j] is the length of the longest common subsequence of A_i and B_j

Then

            if A[i-1]==B[j-1]:
                L[i][j] = L[i-1][j-1] + 1
            else:
                L[i][j] = max(L[i][j-1], L[i-1][j])

If the last characters match, then L[i][j], the length of the longest common subsequence is the lcs of the prefixes plus 1.  If the last characters don't match, then the lcs is the longer of L[i-1][j] or L[i][j-1].  In the references to A[i-1] and B[j-1], the -1's are there because in python strings are 0 origin.

Since the dependencies of the recurrence are only "up" and "to the left" we can compute the whole matrix incrementally from top to bottom and left to right. Here is Hirschberg's Algorithm A:

    # compute maximal length subsequence of A and B
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

Consider again the recurrence. Row j of L depends only on earlier values in row j and on row j-1. Therefore we do not need to retain the entire matrix, but rather only the last two rows.  If we also return the final row we get Hirschberg's Algorithm B

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


This is not coded as efficiently as it could be, in that the rows of K are copied every time through the loop.

At this point, Hirschberg adopts a recursive strategy.  For any point i in A there is at least one point j in B
such that

    L[m][n] = L[i][j] + L'[i][j]  

where L' is the "reverse problem", the maximum length subsequence from subscripts i and j to the ends of strings A and B.  In other words.   The algorithm chooses an i halfway through string A, then uses Algorithm B to locate the corresponding point j, then recursively solves the two subproblems.


    def hirschbergalgc(A, B):
	m = len(A)
	n = len(B)
	C = ""
	if n == 0:
	    return ""
	if m == 1:
	    if A[0] in B:
		return A
	    else:
		return ""
	i = m / 2
	L1 = hirschbergalgb(A[0:i], B)
	L2 = hirschbergalgb(A[i:][::-1], B[::-1])
	m = -1
	for j in xrange(n+1):
	    t = L1[j] + L2[n-j];
	    if t > m:
		m = t
		k = j
	C1 = hirschbergalgc(A[0:i],B[0:k])
	C2 = hirschbergalgc(A[i:], B[k:])
	return C1 + C2


    This method takes a logarithmic recursion depth, because the subproblems are half the size at each level. The storage used is O(m+n) and the time is O(mn).  The really clever bit is the use of Algorithm B to locate
the j corresponding to a particular i.  Algorithm B uses the dynamic programming recurrance to solve for all possible j values in a single pass, then it is a simple matter to find the best j.

See the actual example code in connectal/examples/maxcommonsubseq/hirschberg.py
