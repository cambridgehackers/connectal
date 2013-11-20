
import sys
import os
import util
import re
import syntax

busHandlers={}

import busdefs.define_ddr
busdefs.define_ddr.Register(busHandlers)
import busdefs.define_hdmi
busdefs.define_hdmi.Register(busHandlers)
import busdefs.define_leds
busdefs.define_leds.Register(busHandlers)
import busdefs.define_xadc
busdefs.define_xadc.Register(busHandlers)
import busdefs.define_imageon
busdefs.define_imageon.Register(busHandlers)

edkversion = '14.3'
edkversions = ['14.3', '14.4']
if os.environ.has_key('XILINX_EDK'):
    m = re.match('.*/(\d+.\d+)/ISE_DS/EDK$', os.environ['XILINX_EDK'])
    if m:
        edkversion = m.group(1)
use_acp = 0


xdc_template = '''
set_property iostandard "%(iostandard)s" [get_ports "%(name)s"]
set_property PACKAGE_PIN "%(pin)s" [get_ports "%(name)s"]
set_property slew "SLOW" [get_ports "%(name)s"]
set_property PIO_DIRECTION "%(direction)s" [get_ports "%(name)s"]
'''
xdc_diff_term_template = '''
set_property DIFF_TERM "TRUE" [get_ports "%(name)s"]
'''

impactCmdTemplate = '''
setMode -bscan
setCable -p auto
addDevice -p 1 -file ./%(base)s.runs/impl_1/mk%(Base)sPcieTop.bit
program -p 1
quit
'''

programTclTemplate = '''
connect_hw_server
open_hw_target 
set fpga [lindex [get_hw_devices] 0]
set file ./%(base)s.runs/impl_1/mk%(Base)sPcieTop.bit
set_property PROGRAM.FILE $file $fpga
puts "fpga is $fpga, bit file size is [exec ls -sh $file]"
program_hw_devices $fpga
'''

top_verilog_template='''
`timescale 1 ps / 1 ps
// lib IP_Integrator_Lib
(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLanguage=VERILOG}" *) 
module %(dut)s_top_1(
%(top_bus_ports)s
    output [7:0] GPIO_leds
);

%(axi_master_parameters)s
%(axi_slave_parameters)s
parameter C_FAMILY = "virtex6";

%(top_interrupt_wires)s
%(top_axi_master_wires)s
%(top_axi_slave_wires)s
%(top_bus_wires)s

/* dut goes here */
mk%(Dut)sWrapper %(Dut)sIMPLEMENTATION (
      %(dut_clock_arg)s
      %(dut_axi_master_port_map)s
      %(dut_axi_slave_port_map)s
      %(dut_bus_port_map)s
      %(dut_interrupt_map)s
      );

%(axi_master_scheduler)s
%(axi_slave_scheduler)s
%(bus_assignments)s

wire [15:0] irq_f2p;
%(irq_f2p_assignments)s

processing_system7#(.C_NUM_F2P_INTR_INPUTS(16))
 processing_system7_1(
%(top_ps7_axi_slave_port_map)s
%(top_ps7_axi_master_port_map)s
%(ps7_bus_port_map)s
        .PS_CLK(FIXED_IO_ps_clk));
   
%(top_bus_assignments)s
%(default_leds_assignment)s
endmodule
'''

axi_signal_list=[
    ['araddr', 31], ['arburst', 1], ['arcache', 3], ['arid', 99], ['arlen', 3],
    ['arprot', 2], ['arready', 0], ['arsize', 2], ['arvalid', 0],
    ['awaddr', 31], ['awburst', 1], ['awcache', 3], ['awid', 99], ['awlen', 3],
    ['awprot', 2], ['awready', 0], ['awsize', 2], ['awvalid', 0],
    ['bid', 99], ['bready', 0], ['bresp', 1], ['bvalid', 0],
    ['rdata', -31], ['rid', 99], ['rlast', 0], ['rready', 0],
    ['rresp', 1], ['rvalid', 0],
    ['wdata', -31], ['wid', 99], ['wlast', 0], ['wready', 0],
    ['wstrb', -3], ['wvalid', 0]];

top_axi_master_wires_template='''
  wire [C_%(BUSNAME)s_DATA_WIDTH-1:0]%(busname)s_rdata;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1:0]%(busname)s_wdata;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_wdata_wire;
  wire [(C_%(BUSNAME)s_DATA_WIDTH/8)-1:0]%(busname)s_wstrb;
  wire RDY_%(busname)s_write_writeAddr;
  wire RDY_%(busname)s_write_writeData;
  wire RDY_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_read_readAddr;
  wire RDY_%(busname)s_read_readData;
  wire WILL_FIRE_%(busname)s_write_writeAddr;
  wire WILL_FIRE_%(busname)s_write_writeData;
  wire WILL_FIRE_%(busname)s_write_writeResponse;
  wire WILL_FIRE_%(busname)s_read_readAddr;
  wire WILL_FIRE_%(busname)s_read_readData;
'''

for item in axi_signal_list:
    t = ''
    if item[1] < 0:
        continue
    if item[1] != 0:
        thislen = item[1]
        if thislen == 99:
            thislen = 5
        t = '[' + str(thislen) + ':0]'
    top_axi_master_wires_template = top_axi_master_wires_template \
        + '  wire ' + t + '%(busname)s_' + item[0] + ';\n'

top_axi_slave_wires_template='''
  wire [1:0]%(busname)s_arlock;
  wire [1:0]%(busname)s_awlock;
  wire %(busname)s_mem0_araddr_matches;
  wire %(busname)s_mem0_awaddr_matches;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_read_readData;
  wire [1 : 0] %(busname)s_write_writeResponse;
  wire EN_%(busname)s_read_readAddr;
  wire RDY_%(busname)s_read_readAddr;
  wire EN_%(busname)s_read_readData;
  wire RDY_%(busname)s_read_readData;
  wire EN_%(busname)s_write_writeAddr;
  wire RDY_%(busname)s_write_writeAddr;
  wire EN_%(busname)s_write_writeData;
  wire RDY_%(busname)s_write_writeData;
  wire EN_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_write_bid;
'''

for item in axi_signal_list:
    t = ''
    if item[1] != 0:
        thislen = abs(item[1])
        if thislen == 99:
            thislen = 11
        t = '[' + str(thislen) + ':0]'
    top_axi_slave_wires_template = top_axi_slave_wires_template \
        + '  wire ' + t + '%(busname)s_' + item[0] + ';\n'

top_dut_axi_master_port_map_template='''
        .%(busname)s_aclk(processing_system7_fclk_clk0),
        .%(busname)s_aresetn(processing_system7_fclk_reset0_n),
'''

for item in axi_signal_list:
    top_dut_axi_master_port_map_template = top_dut_axi_master_port_map_template \
        + '        .%(busname)s_' + item[0] + '(%(busname)s_' + item[0] + '),\n'

top_ps7_axi_master_port_map_template='''
        .S_AXI_%(ps7bus)s_ACLK(processing_system7_1_fclk_clk0),
        .S_AXI_%(ps7bus)s_ARLOCK({GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_ARQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_AWLOCK({GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_AWQOS({GND_1,GND_1,GND_1,GND_1}),
        /* .S_AXI_%(ps7bus)s_RDISSUECAP1_EN(GND_1), */
        /* .S_AXI_%(ps7bus)s_WRISSUECAP1_EN(GND_1), */
'''

for item in axi_signal_list:
    top_ps7_axi_master_port_map_template = top_ps7_axi_master_port_map_template \
        + '        .S_AXI_%(ps7bus)s_' + item[0] + '(%(busname)s_' + item[0] + '),\n'

top_ps7_axi_slave_port_map_template='''
        .M_AXI_GP0_ACLK(processing_system7_1_fclk_clk0),
        .M_AXI_GP0_ARLOCK(%(busname)s_arlock),
        .M_AXI_GP0_AWLOCK(%(busname)s_awlock),
'''

for item in axi_signal_list:
    top_ps7_axi_slave_port_map_template = top_ps7_axi_slave_port_map_template \
        + '        .M_AXI_GP0_' + item[0].upper() + '(%(busname)s_' + item[0] + '),\n'

axi_master_parameter_verilog_template='''
parameter C_%(BUSNAME)s_DATA_WIDTH = %(buswidth)s;
parameter C_%(BUSNAME)s_ADDR_WIDTH = 32;
parameter C_%(BUSNAME)s_BURSTLEN_WIDTH = %(burstlenwidth)s;
parameter C_%(BUSNAME)s_PROT_WIDTH = %(protwidth)s;
parameter C_%(BUSNAME)s_CACHE_WIDTH = %(cachewidth)s;
parameter C_%(BUSNAME)s_ID_WIDTH = 6;
'''

axi_slave_parameter_verilog_template='''
parameter C_%(BUSNAME)s_DATA_WIDTH = 32;
parameter C_%(BUSNAME)s_ADDR_WIDTH = 32;
parameter C_%(BUSNAME)s_ID_WIDTH = 12;
parameter C_%(BUSNAME)s_MEM0_BASEADDR = 32'h%(busbase)s;
parameter C_%(BUSNAME)s_MEM0_HIGHADDR = 32'h%(bushigh)s;
'''

axi_master_port_decl_verilog_template='''
//============ %(BUSNAME)s ============
wire [C_%(BUSNAME)s_DATA_WIDTH - 1 : 0] %(busname)s_wdata_wire;
//============ %(BUSNAME)s ============
'''

axi_master_port_map_verilog_template='''
      .EN_%(busname)s_read_readAddr(WILL_FIRE_%(busname)s_read_readAddr),
      .%(busname)s_read_readAddr(%(busname)s_araddr),
      .RDY_%(busname)s_read_readAddr(RDY_%(busname)s_read_readAddr),

      .%(busname)s_read_readBurstLen(%(busname)s_arlen),
      .RDY_%(busname)s_read_readBurstLen(RDY_%(busname)s_read_readBurstLen),

      .%(busname)s_read_readBurstWidth(%(busname)s_arsize),
      .RDY_%(busname)s_read_readBurstWidth(RDY_%(busname)s_read_readBurstWidth),

      .%(busname)s_read_readBurstType(%(busname)s_arburst),
      .RDY_%(busname)s_read_readBurstType(RDY_%(busname)s_read_readBurstType),

      .%(busname)s_read_readBurstProt(%(busname)s_arprot),
      .RDY_%(busname)s_read_readBurstProt(RDY_%(busname)s_read_readBurstProt),

      .%(busname)s_read_readBurstCache(%(busname)s_arcache),
      .RDY_%(busname)s_read_readBurstCache(RDY_%(busname)s_read_readBurstCache),

      .%(busname)s_read_readId(%(busname)s_arid),
      .RDY_%(busname)s_read_readId(RDY_%(busname)s_read_readId),

      .%(busname)s_read_readData_data(%(busname)s_rdata),
      .%(busname)s_read_readData_resp(%(busname)s_rresp),
      .%(busname)s_read_readData_last(%(busname)s_rlast),
      .%(busname)s_read_readData_id(%(busname)s_rid),
      .EN_%(busname)s_read_readData(WILL_FIRE_%(busname)s_read_readData),
      .RDY_%(busname)s_read_readData(RDY_%(busname)s_read_readData),

      .EN_%(busname)s_write_writeAddr(WILL_FIRE_%(busname)s_write_writeAddr),
      .%(busname)s_write_writeAddr(%(busname)s_awaddr),
      .RDY_%(busname)s_write_writeAddr(RDY_%(busname)s_write_writeAddr),

      .%(busname)s_write_writeBurstLen(%(busname)s_awlen),
      .RDY_%(busname)s_write_writeBurstLen(RDY_%(busname)s_write_writeBurstLen),

      .%(busname)s_write_writeBurstWidth(%(busname)s_awsize),
      .RDY_%(busname)s_write_writeBurstWidth(RDY_%(busname)s_write_writeBurstWidth),

      .%(busname)s_write_writeBurstType(%(busname)s_awburst),
      .RDY_%(busname)s_write_writeBurstType(RDY_%(busname)s_write_writeBurstType),

      .%(busname)s_write_writeBurstProt(%(busname)s_awprot),
      .RDY_%(busname)s_write_writeBurstProt(RDY_%(busname)s_write_writeBurstProt),

      .%(busname)s_write_writeBurstCache(%(busname)s_awcache),
      .RDY_%(busname)s_write_writeBurstCache(RDY_%(busname)s_write_writeBurstCache),

      .%(busname)s_write_writeId(%(busname)s_awid),
      .RDY_%(busname)s_write_writeId(RDY_%(busname)s_write_writeId),

      .EN_%(busname)s_write_writeData(WILL_FIRE_%(busname)s_write_writeData),
      .%(busname)s_write_writeData(%(busname)s_wdata_wire),
      .RDY_%(busname)s_write_writeData(RDY_%(busname)s_write_writeData),

      .%(busname)s_write_writeWid(%(busname)s_wid),
      .RDY_%(busname)s_write_writeWid(RDY_%(busname)s_write_writeWid),

      .%(busname)s_write_writeDataByteEnable(%(busname)s_wstrb),
      .RDY_%(busname)s_write_writeDataByteEnable(RDY_%(busname)s_write_writeDataByteEnable),

      .%(busname)s_write_writeLastDataBeat(%(busname)s_wlast),
      .RDY_%(busname)s_write_writeLastDataBeat(RDY_%(busname)s_write_writeLastDataBeat),

      .%(busname)s_write_writeResponse_responseCode(%(busname)s_bresp),
      .%(busname)s_write_writeResponse_id(%(busname)s_bid),
      .EN_%(busname)s_write_writeResponse(WILL_FIRE_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_writeResponse(RDY_%(busname)s_write_writeResponse),
'''

axi_slave_port_map_verilog_template='''
      .%(busname)s_read_readAddr_addr(%(busname)s_araddr),
      .%(busname)s_read_readAddr_burstLen(%(busname)s_arlen),
      .%(busname)s_read_readAddr_burstWidth(%(busname)s_arsize),
      .%(busname)s_read_readAddr_burstType(%(busname)s_arburst),
      .%(busname)s_read_readAddr_burstProt(%(busname)s_arprot),
      .%(busname)s_read_readAddr_burstCache(%(busname)s_arcache),
      .%(busname)s_read_readAddr_arid(%(busname)s_arid),
      .EN_%(busname)s_read_readAddr(EN_%(busname)s_read_readAddr),
      .RDY_%(busname)s_read_readAddr(RDY_%(busname)s_read_readAddr),

      .%(busname)s_read_last(%(busname)s_rlast),
      .%(busname)s_read_rid(%(busname)s_rid),
      .EN_%(busname)s_read_readData(EN_%(busname)s_read_readData),
      .%(busname)s_read_readData(%(busname)s_rdata),
      .RDY_%(busname)s_read_readData(RDY_%(busname)s_read_readData),

      .%(busname)s_write_writeAddr_addr(%(busname)s_awaddr),
      .%(busname)s_write_writeAddr_burstLen(%(busname)s_awlen),
      .%(busname)s_write_writeAddr_burstWidth(%(busname)s_awsize),
      .%(busname)s_write_writeAddr_burstType(%(busname)s_awburst),
      .%(busname)s_write_writeAddr_burstProt(%(busname)s_awprot),
      .%(busname)s_write_writeAddr_burstCache(%(busname)s_awcache),
      .%(busname)s_write_writeAddr_awid(%(busname)s_awid),
      .EN_%(busname)s_write_writeAddr(EN_%(busname)s_write_writeAddr),
      .RDY_%(busname)s_write_writeAddr(RDY_%(busname)s_write_writeAddr),

      .%(busname)s_write_writeData_data(%(busname)s_wdata),
      .%(busname)s_write_writeData_byteEnable(%(busname)s_wstrb),
      .%(busname)s_write_writeData_last(%(busname)s_wlast),
      .%(busname)s_write_writeData_wid(%(busname)s_wid),
      .EN_%(busname)s_write_writeData(EN_%(busname)s_write_writeData),
      .RDY_%(busname)s_write_writeData(RDY_%(busname)s_write_writeData),

      .EN_%(busname)s_write_writeResponse(EN_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_writeResponse(RDY_%(busname)s_write_writeResponse),
      .%(busname)s_write_writeResponse(%(busname)s_bresp),
      .EN_%(busname)s_write_bid(EN_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_bid(RDY_%(busname)s_write_bid),
      .%(busname)s_write_bid(%(busname)s_bid),
'''

axi_master_scheduler_verilog_template='''
assign WILL_FIRE_%(busname)s_read_readAddr = (%(busname)s_arready & RDY_%(busname)s_read_readAddr);
assign WILL_FIRE_%(busname)s_read_readData = (%(busname)s_rvalid & RDY_%(busname)s_read_readData);
assign %(busname)s_arvalid = RDY_%(busname)s_read_readAddr;
assign %(busname)s_rready = RDY_%(busname)s_read_readData;

assign WILL_FIRE_%(busname)s_write_writeAddr = (%(busname)s_awready & RDY_%(busname)s_write_writeAddr);
assign WILL_FIRE_%(busname)s_write_writeData = (%(busname)s_wready & RDY_%(busname)s_write_writeData);
assign WILL_FIRE_%(busname)s_write_writeResponse = (%(busname)s_bvalid & RDY_%(busname)s_write_writeResponse);
assign %(busname)s_awvalid = RDY_%(busname)s_write_writeAddr;
assign %(busname)s_wvalid = RDY_%(busname)s_write_writeData;
assign %(busname)s_bready = RDY_%(busname)s_write_writeResponse;
assign %(busname)s_wdata = (RDY_%(busname)s_write_writeData == 1) ? %(busname)s_wdata_wire : 32'hdeadd00d;
'''

axi_slave_scheduler_verilog_template='''
assign %(busname)s_mem0_araddr_matches = (%(busname)s_araddr >= C_%(BUSNAME)s_MEM0_BASEADDR & %(busname)s_araddr <= C_%(BUSNAME)s_MEM0_HIGHADDR);
assign %(busname)s_mem0_awaddr_matches = (%(busname)s_awaddr >= C_%(BUSNAME)s_MEM0_BASEADDR & %(busname)s_awaddr <= C_%(BUSNAME)s_MEM0_HIGHADDR);

assign %(busname)s_arready_unbuf = RDY_%(busname)s_read_readAddr & %(busname)s_arvalid & %(busname)s_mem0_araddr_matches;
assign %(busname)s_arready = %(busname)s_arready_unbuf;
assign %(busname)s_rvalid_unbuf = EN_%(busname)s_read_readData;
assign %(busname)s_rvalid = %(busname)s_rvalid_unbuf;
assign %(busname)s_rresp[1:0]  = "00";

assign %(busname)s_awready  = RDY_%(busname)s_write_writeAddr & %(busname)s_mem0_awaddr_matches;
assign %(busname)s_wready = RDY_%(busname)s_write_writeData;
assign %(busname)s_bvalid  = EN_%(busname)s_write_writeResponse;
assign %(busname)s_bresp = %(busname)s_write_writeResponse;

assign EN_%(busname)s_read_readAddr = RDY_%(busname)s_read_readAddr & %(busname)s_arvalid & %(busname)s_mem0_araddr_matches;
assign EN_%(busname)s_read_readData = RDY_%(busname)s_read_readData & %(busname)s_rready;

assign EN_%(busname)s_write_writeAddr = RDY_%(busname)s_write_writeAddr & %(busname)s_awvalid & %(busname)s_mem0_awaddr_matches;
assign EN_%(busname)s_write_writeData = RDY_%(busname)s_write_writeData & %(busname)s_wvalid;
assign EN_%(busname)s_write_writeResponse = RDY_%(busname)s_write_writeResponse & %(busname)s_bready;
'''

class InterfaceMixin:
    def axiMasterBusSubst(self, busnumber, businfo):
        (busname,t,params) = businfo
        addrwidth = params[0].numeric()
        buswidth = params[1].numeric()
        buswidthbytes = buswidth / 8
        # print 'bustype: ', t, ('AXI4' if (t == 'AxiMaster') else 'AXI3'), buswidth
        dutName = util.decapitalize(self.base)
        hpBusOffset = 0
        if buswidth == 32:
            ps7bustype = 'GP'
            ps7bus = 'GP%s' % busnumber
        elif use_acp and busnumber == 0:
            ps7bustype = 'ACP'
            ps7bus = 'ACP'
            hpBusOffset = -1
        else:
            ps7bustype = 'HP'
            ps7bus = 'HP%s' % (busnumber + hpBusOffset)
        return {
            'dut': dutName,
            'BUSNAME': busname.upper(),
            'busname': busname,
            'busnumber': busnumber,
            'addrwidth': addrwidth,
            'buswidth': buswidth,
            'buswidthbytes': buswidthbytes,
            'ps7bustype': ps7bustype,
            'ps7bus': ps7bus,
            'burstlenwidth': 8 if (t == 'AxiMaster') else 4,
            'protwidth': 3 if (t == 'AxiMaster') else 2,
            'cachewidth': 4 if (t == 'AxiMaster') else 3,
            'axiprotocol': 'AXI4' if (t == 'AxiMaster') else 'AXI3',
            }
    def writeTopVerilog(self, topverilogname, silent=False):
        if not silent:
            print 'Writing top Verilog file', topverilogname
        topverilog = util.createDirAndOpen(topverilogname, 'w')
        dutName = util.decapitalize(self.base)
        axiMasters = self.collectInterfaceNames('Axi3?Client', True)
        axiSlaves = [('ctrl','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        masterBusSubsts = [self.axiMasterBusSubst(busnumber,axiMasters[busnumber]) for busnumber in range(len(axiMasters))]
        slaveBusSubsts = []
        for i in range(len(axiSlaves)):
            (busname,t,params) = axiSlaves[i]
            slaveBusSubsts.append({'busname': busname,
                                   'BUSNAME': busname.upper(),
                                   'busbase': '%08x' % (0x6e400000 + 0x00020000*i),
                                   'bushigh': '%08x' % (0x6e400000 + 0x00020000*i + 0xFFFFF)})
        buses = {}
        for busType in busHandlers:
            b = self.collectInterfaceNames(busType)
            buses[busType] = b
        # hack to force generation of DDR definitions. jca
        buses['DDR'] = [('a', 'b', 'c')]
        if len(buses['LEDS']):
            default_leds_assignment = ''
        else:
            default_leds_assignment = '''assign GPIO_leds = 8'haa;'''
        dut_clknames = self.getClockArgNames(syntax.globalvars['mk%s' % self.name])
        substs = {
            'dut': dutName.lower(),
            'Dut': util.capitalize(self.base),
            'axi_master_parameters':
                ''.join([axi_master_parameter_verilog_template
                  % subst for subst in masterBusSubsts]),
            'axi_slave_parameters':
                ''.join([axi_slave_parameter_verilog_template
                  % subst for subst in slaveBusSubsts]),
            'top_axi_master_wires': ''.join([top_axi_master_wires_template
                  % subst for subst in masterBusSubsts]),
            'top_axi_slave_wires': ''.join([top_axi_slave_wires_template
                  % subst for subst in slaveBusSubsts]),
            'top_dut_axi_master_port_map': ''.join([top_dut_axi_master_port_map_template
                  % subst for subst in masterBusSubsts]),
            'top_ps7_axi_master_port_map': ''.join([top_ps7_axi_master_port_map_template
                  % subst for subst in masterBusSubsts]),
            'top_ps7_axi_slave_port_map': ''.join([top_ps7_axi_slave_port_map_template
                  % subst for subst in slaveBusSubsts]),
            'dut_clock_arg': '\n'.join(['.CLK_%s(%s),'
                  % (clk,clk) for clk in dut_clknames]),
            'top_bus_ports':
                ''.join([''.join([busHandlers[busType].top_bus_ports(busname,t,params)
                  for (busname,t,params) in buses[busType]])
                  for busType in busHandlers]),
            'top_bus_wires':
                ''.join([''.join([busHandlers[busType].top_bus_wires(busname,t,params)
                  for (busname,t,params) in buses[busType]])
                  for busType in busHandlers]),
            'dut_axi_master_port_map': ''.join([axi_master_port_map_verilog_template
                  % subst for subst in masterBusSubsts]),
            'dut_axi_slave_port_map':
                ''.join([axi_slave_port_map_verilog_template
                  % {'BUSNAME': busname.upper(), 'busname': busname}
                  for (busname,t,params) in axiSlaves]),
            'dut_bus_port_map': ''.join([''.join([busHandlers[busType].dut_bus_port_map(busname,t,params)
                  for (busname,t,params) in buses[busType]])
                  for busType in busHandlers]),
            'axi_master_scheduler':
                ''.join([axi_master_scheduler_verilog_template
                  % subst for subst in masterBusSubsts ]),
            'axi_slave_scheduler':
                ''.join([axi_slave_scheduler_verilog_template
                  % {'BUSNAME': busname.upper(), 'busname': busname}
                  for (busname,t,params) in axiSlaves]),
            'ps7_bus_port_map':
                ''.join([''.join([busHandlers[busType].ps7_bus_port_map(busname,t,params)
                  for (busname,t,params) in buses[busType]])
                  for busType in busHandlers]),
            'top_bus_assignments': ''.join([''.join([busHandlers[busType].top_bus_assignments(busname,t,params)
                  for (busname,t,params) in buses[busType]])
                  for busType in busHandlers]),
            'bus_assignments': ''.join([''.join([busHandlers[busType].bus_assignments(busname,t,params)
                  for (busname,t,params) in buses[busType]])
                  for busType in busHandlers]),
            'default_leds_assignment': default_leds_assignment,
            'irq_f2p_assignments': ''.join(self.collectInterrupts()),
            'dut_interrupt_map' : ''.join(util.intersperse(',\n      ', 
                  ['.interrupts_%s__read(%s_%s_interrupt)'
                  % (x,dutName,x) for x in range (0,self.numPortals)])),
            'top_interrupt_wires' : ''.join(['  wire %s_%s_interrupt;\n'
                  % (dutName,x) for x in range(0,self.numPortals)])
            }
        topverilog.write(top_verilog_template % substs)
        topverilog.close()
        return
    
    def collectInterrupts(self):
        dutName = util.decapitalize(self.base)
        rv = []
        for x in range(0,15):
            if self.numPortals > x:
                rv.append('assign irq_f2p[%s] = %s_%s_interrupt;\n' % (x,dutName,x))
            else:
                rv.append('assign irq_f2p[%s] = 0;\n' % (x))
        return rv

    def writeXdc(self, xdcname, boardname='zc702', silent=False):
        if not silent:
            print 'Writing XDC file', xdcname
        xdc = util.createDirAndOpen(xdcname, 'w')
        dutName = util.decapitalize(self.base)
        if not len(self.collectInterfaceNames('LEDS')):
            ## we always connect these pins to a default pattern
            for (name, pin, iostandard, direction) in busHandlers['LEDS'].pinout(boardname):
                xdc.write(xdc_template % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
        for busType in busHandlers:
            buses = self.collectInterfaceNames(busType)
            if len(buses):
                for entry in busHandlers[busType].pinout(boardname):
                    if len(entry) == 4:
                        (name, pin, iostandard, direction) = entry
                        xdc.write(xdc_template
                                  % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
                        if (iostandard == 'LVDS_25'):
                            xdc.write(xdc_diff_term_template
                                      % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
        xdc.close()
        return
    def writeImpactCmd(self, impactcmdname):
        f = util.createDirAndOpen(impactcmdname, 'w')
        f.write(impactCmdTemplate % { 'base': self.base.lower(), 'Base': self.base })
        f.close()
    def writeProgramTcl(self, programtclname):
        f = util.createDirAndOpen(programtclname, 'w')
        f.write(programTclTemplate % { 'base': self.base.lower(), 'Base': self.base })
        f.close()
