#
set -x
set -e
scripts/importbvi.py \
    -r SAXIACP:S_AXI_ACP_ \
    -r MAXI:M_AXI_ \
    -r SAXI:S_AXI_ \
    -r DDR:DDR_ \
    -r EMIOCAN:CAN \
    -r EMIOCORE:CORE_ \
    -r EMIODMA:DMA \
    -r EMIOENET:ENET \
    -r EVENT:EVENT_ \
    -r FCLKCLKTRIG:FCLKCLKTRIG_ \
    -r FCLKRESET:FCLK_RESET_ \
    -r FCLKCLK:FCLK_ \
    -r FPGA:FPGA_ \
    -r FTMD:FTMD_ \
    -r FTMT:FTMT_ \
    -r EMIOGPIO:GPIO_ \
    -r EMIOI2C:I2C \
    -r IRQ:IRQ_ \
    -r EMIOPJTAG:PJTAG_ \
    -r EMIOPS:PS \
    -r EMIOSDIO:SDIO \
    -r EMIOSPI:SPI \
    -r EMIOSRAM:SRAM_ \
    -r EMIOTRACE:TRACE_ \
    -r EMIOTTC:TTC \
    -r EMIOUART:UART \
    -r EMIOUSB:USB \
    -r EMIOWDT:WDT_ \
    ../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib >xx.jlib

#    -r PS:PS_ \
