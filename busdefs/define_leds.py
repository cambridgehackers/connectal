#

led_pinout = {
    'zc702': [
        ('GPIO_leds[0]', 'E15', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[1]', 'D15', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[2]', 'W17', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[3]', 'W5', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[4]', 'V7', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[5]', 'W10', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[6]', 'P18', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[7]', 'P17', 'LVCMOS25', 'OUTPUT')
    ],
    'zedboard': [
        ('GPIO_leds[0]', 'T22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[1]', 'T21', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[2]', 'U22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[3]', 'U21', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[4]', 'V22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[5]', 'W22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[6]', 'U19', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[7]', 'U14', 'LVCMOS33', 'OUTPUT')],
    'kc705': [],
    'vc707': [],
    }

class Leds:
    def __init__(self, busHandlers):
        busHandlers['LEDS'] = self
    def top_bus_ports(self, busname,t,params):
        return ''
    def top_bus_wires(self, busname,t,params):
        return ''
    def ps7_bus_port_map(self,busname,t,params):
        return ''
    def dut_bus_port_map(self, busname,t,params):
        return '''
      .%(busname)s_leds(GPIO_leds),
''' % {'busname': busname}
    def top_bus_assignments(self,busname,t,params):
        return ''
    def bus_assignments(self,busname,t,params):
        return ''
    def pinout(self, board):
        return led_pinout[board]
