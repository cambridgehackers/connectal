#
#
set -x
set -e
./importbvi.py -o ALTERA_DDR3_WRAPPER.bsv -I AvalonDdr3 -P AvalonDdr3 \
	-c pll_ref_clk -r global_reset_n -r soft_reset_n -c afi_clk -c afi_half_clk -r afi_reset_n -r afi_reset_export_n \
	-f mem -f avl -f local -f oct -f pll \
	/home/hwang/dev/connectal/out/de5/synthesis/altera_mem_if_ddr3_emif_wrapper/altera_mem_if_ddr3_emif_wrapper.v
