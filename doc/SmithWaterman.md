## Smith-Waterman

L. Stewart <stewart@qrclab.com> March 17, 2014

Smith-Waterman is an algorithm for determining the best alignment of two strands of DNA.  It is a variant of dynamic programming, published in 1981.  For strands of lengths m and n, it runs in O(mn) space and O(mn) time and returns all alignments with the best score, according to weights for mismatches, insertions, and deletions.

In 1982, Gotoh found an O(mn) time but only O(shorter of m and n) space scheme that returns only a single instance of the best match.

In 1986, Altschul and Erickson published a version with "affine gap costs."  The original Smith-Waterman had the same weight for each step in a run of inserts or deletes, but a model in which the first insert or delete costs more than adding to an existing run models biology more accurately.

In 1988, Miller, Webb, and Myers adapted a computer science algorithm by Hirshberg (1975) to the problem, leading O(smaller of m or n) space.

Limiting space usage is fairly important for FPGA implementations, since while FGPAs or ASICs have a lot of internal memory units, they aren't very big each.  In order to achieve a big speedup on sequencing, we have to have a lot of parallelism.  Each instance can have its own memory, but not very much of it.

For the Hirschberg algorithm, see connectal/examples/maxcommonsubseq.


How it works

The problem is to find the minimum cost of converting one string, A, into another one, B.  Three things can happen: a character can be deleted from string A, a character can be inserted into string A, and combination event, in which a character in string A is changed (delete combined with insert).

Parameters are needed: a substitution matrix that details the cost of converting a character to another (or itself), and a gap model, which expresses the cost of deleting or inserting a run of characters.

The simplest gap model has a fixed cost for every deletion or insertion, but an "affine model" better matches what happens in biology: there is a startup cost for a run of deletions or insertions, and a typically lower, cost for extending a run.

Call the substitution matrix w(a, b)

    def w(a, b): 
      if (a == b): 
        return 0.0 
      else: 
        return 1.0

In other words, no cost to leave a character unchanged, and unit cost to change it.

A typical gap model is

    g = 2.0 h = 0.5

    def gap(k): 
      return g + (k * h)

The magnitudes of these costs are irrelevant, only the relative costs matter.

The basic idea of Smith Waterman is dynamic programming. Suppose that

    m = len(A) 
    n = len(B)

Define A_i to be the subsequence A[0]..A[i].

Let's define C[i][j] as the minimum cost of a conversion from A_i to B_j.  D[i][j] as the minimum cost of a conversion from A_i to B_j such that A[i] is deleted (a suffix gap in A), and that I[i][j] is the minimum cost of conversion from A_i to B_j such that b[j] is inserted (into A).

D and I are only necessary to handle the gap cost model - you have to know whether the best answer up to a point has a gap at the end or not, so you can apply the gap cost model to either extend a gap or open a new one.

The essence of dynamic programming is a recurrance that expresses that expresses matrix values as functions of "earlier" values.

    C[i][j] = min ( 
      D[i][j], 
      I[i][j], 
      C[i-1][j-1] + w(a[i], b[j]))

    D[i][j] = min( 
      D[i-1][j] + h, // extend an old gap 
      C[i-1][j] + g + h) // start a new gap


    I[i][j] = min( 
      I[i][j-1] + h, // extend an old gap 
      C[i][j-1] + g + h) // start a new gap

The Gotoh version of Smith-Waterman does exactly this, building the full C, D, and I matrices.

From inspection of the recurrance relations, it is clear that you don't need to save the full matrices, and the algorithm Gotohb keeps only two row vectors.  CC[j] represents conversion costs of A_i to B_j (for all j) and DD[j] represents conversion costs of A_i to B_j ending with a deletion, for all j.

All of the above follows the lines of Hirschberg's algorithms A and B for the maximum common subsequence problem.

The key insight in the Myers and Miller paper is that you can write a recursive version of Smith Waterman along the lines of Hirschberg's algorithm C.

1 Choose a midpoint i in the A string.  
2 Find j such that the best overall solution passes through C[i][j]
3 Recursively solve the conversion of A_i to B_j and the solution of A_m-i to B_n-j, where A_m-i and B_n-j are the suffixes of A and B.


Step 1 is straightforward, the best solution passes through A_i, although we don't know at what j.

Step 2 uses Gotoh Algorithm B to find the cost of solutions which cross A_i for all values of j.

This is done in two parts.  The first half part is done in the forward direction by using GotohB(A_i, B_j). This produces vectors CC and DD as above.  Then GotohB(A*_m-i, B*_j) is run, where A* and B* are the reversed strings A and B. A*_m-i is the reversed suffix of A, from i+1 to the end. This produces vectors RR, the conversion from A*_m-i to B*_j for all j, and SS, the conversion costs from A*_i to B*_j ending with a delete.  The reverse solution finds costs for the suffixes of A and B

There are two cases.  In type 1 cases, the cost of the overall conversion that splits B at j is just CC[j] + RR[N-j].  This is minimized over j to find the best split point for string B.  In type 2 cases, the best solution for the prefix of B ends with a delete and the best solution for the suffix begins with a delete. In this case, we have to coalesce the deletions into a single gap.

min over j (CC[j] + RR[N-j], DD[j] + SS[N-j] -g)

Given the split points i and j, we can run step 3, to solve the prefix and suffix problems recursively.

Below the top level of the recursion, it may be necessary to coalesce gaps at either the beginning or end of the string, and for this reason, additional parameters are passed in to control this accounting.

    def gotohc(A, B, tb, te): ...

In order to make the python version more like the eventual hardware version, we also pass in sa and sb, the starting indices in A and B, and m and n, the lengths of the active substrings in A and B.
 
    def gotohc(A, B, sa, sb, m, n, tb, te): ...

For full details, see examples/smithwaterman/sw.py

