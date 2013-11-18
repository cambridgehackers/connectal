#

hdmi_pinout = {
    'zc702': [
        ( "hdmi_clk", 'L16', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_hsync", 'R18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_vsync", 'H15', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_de", 'T18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[0]", 'AB21', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[1]", 'AA21', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[2]", 'AB22', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[3]", 'AA22', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[4]", 'V19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[5]", 'V18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[6]", 'V20', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[7]", 'U20', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[8]", 'W21', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[9]", 'W20', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[10]", 'W18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[11]", 'T19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[12]", 'U19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[13]", 'R19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[14]", 'T17', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[15]", 'T16', 'LVCMOS25', 'OUTPUT'),
        ],
    'zedboard':[
        ( "hdmi_clk", 'W18', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_vsync", 'W17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_hsync", 'V17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_de", 'U16', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[0]", 'Y13', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[1]", 'AA13', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[2]", 'AA14', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[3]", 'Y14', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[4]", 'AB15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[5]", 'AB16', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[6]", 'AA16', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[7]", 'AB17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[8]", 'AA17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[9]", 'Y15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[10]", 'W13', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[11]", 'W15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[12]", 'V15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[13]", 'U17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[14]", 'V14', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[15]", 'V13', 'LVCMOS33', 'OUTPUT'),
        ]
    }

class Hdmi:
    def __init__(self, busHandlers):
        busHandlers['HDMI'] = self
    def top_bus_ports(self, busname,t,params):
        return '''    output hdmi_clk,
    output hdmi_vsync,
    output hdmi_hsync,
    output hdmi_de,
    output [15:0] hdmi_data,
'''
    def top_bus_wires(self, busname,t,params):
        return ''
    def ps7_bus_port_map(self,busname,t,params):
        return '''
'''
    def dut_bus_port_map(self, busname,t,params):
        return '''
      .%(busname)s_hdmi_vsync(hdmi_vsync),
      .%(busname)s_hdmi_hsync(hdmi_hsync),
      .%(busname)s_hdmi_de(hdmi_de),
      .%(busname)s_hdmi_data(hdmi_data),
      .CLK_%(busname)s_hdmi_clock_if(hdmi_clk),
''' % {'busname': busname}
    def top_bus_assignments(self,busname,t,params):
        return '''
'''
    def bus_assignments(self,busname,t,params):
        return ''
    def pinout(self, board):
        return hdmi_pinout[board]
