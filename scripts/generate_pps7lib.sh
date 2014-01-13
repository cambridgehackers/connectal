#
set -x
set -e
scripts/importbvi.py \
    -f DDR -f FTMT -f FTMD -f IRQ \
    -f EMIOGPIO -f EMIOPJTAG -f EMIOTRACE -f EMIOWDT -f EVENT -f PS -f SAXIACP \
    -c MAXIGP0ACLK -c MAXIGP1ACLK -c SAXIACPACLK \
    -c SAXIGP0ACLK -c SAXIGP1ACLK \
    -c SAXIHP0ACLK -c SAXIHP1ACLK -c SAXIHP2ACLK -c SAXIHP3ACLK \
    -i PS7EXTENDED:Pps7Emiocan:Pps7Emioenet:Pps7Emiopjtag:Pps7Emiosdio:Pps7Emiospi:Pps7Emiotrace:Pps7Emiottc:Pps7Emiouart:Pps7Emiousb:Pps7Emiowdt:Pps7Dma \
    ../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib >PPS7.bsv

#    -c DMA0ACLK -c DMA1ACLK -c DMA2ACLK -c DMA3ACLK \
#    -c EMIOENET0GMIIRXCLK -c EMIOENET0GMIITXCLK \
#    -c EMIOENET1GMIIRXCLK -c EMIOENET1GMIITXCLK \
#    -c EMIOSDIO0CLKFB -c EMIOSDIO1CLKFB -c EMIOTRACECLK \
