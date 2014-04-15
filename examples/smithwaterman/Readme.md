Smith-Waterman

L. Stewart <stewart@qrclab.com>
March17, 2014

Smith-Waterman is an algorithm for determining the best alignment of
two strands of DNA.  It is a variant of dynamic programming, published
in 1981.  For strands of lengths m and n, it runs in O(mn) space and
O(mn) time and returns all alignments with the best score, according
to weights for mismatches, insertions, and deletions.

In 1982, Gotoh found an O(mn) time but only O(shorter of m and n)
space scheme that returns only a single instance of the best match.

In 1986, Altschul and Erickson published a version with "affine gap
costs."  The original Smith-Waterman had the same weight for each step
in a run of inserts or deletes, but a model in which the first insert
or delete costs more than adding to an existing run models biology
more accurately.

In 1988, Miller, Webb, and Myers adapted a computer science algorithm
by Hirshberg (1975) to the problem, leading O(smaller of m or n)
space.

Limiting space usage is fairly important for FPGA implementations,
since while FGPAs or ASICs have a lot of internal memory units, they
aren't very big each.  In order to achieve a big speedup on
sequencing, we have to have a lot of parallelism.  Each instance can
have its own memory, but not very much of it.

For the Hirschberg algorithm, see xbsv/examples/maxcommonsubseq.
