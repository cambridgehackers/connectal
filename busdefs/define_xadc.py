#

xadc_pinout= {
    'zc702': [
        ("XADC_gpio[0]", 'H17', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[1]", 'H22', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[2]", 'G22', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[3]", 'H18', 'LVCMOS25', 'OUTPUT'),
        ],
    'zedboard': [
        ("XADC_gpio[0]", 'H15', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[1]", 'R15', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[2]", 'K15', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[3]", 'J15', 'LVCMOS25', 'OUTPUT'),
        ],
    'kc705': [],
    'vc707': [],
    }

class Register:
    def __init__(self, busHandlers):
        busHandlers['XADC'] = self
    def top_bus_ports(self, busname,t,params):
        return ''
    def top_bus_wires(self, busname,t,params):
        return ''
    def ps7_bus_port_map(self,busname,t,params):
        return ''
    def dut_bus_port_map(self, busname,t,params):
        return '''
      .%(busname)s_xadc(XADC_gpio),
''' % {'busname': busname}
    def top_bus_assignments(self,busname,t,params):
        return ''
    def bus_assignments(self,busname,t,params):
        return ''
    def pinout(self, board):
        return xadc_pinout[board]

