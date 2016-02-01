

entry:
	lui	sp,1
	jal     copybbl
	li      a0, 0x200
	jr      a0
stuck:	j	stuck
copybbl:	