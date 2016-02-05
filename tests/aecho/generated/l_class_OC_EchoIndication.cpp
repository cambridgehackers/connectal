#include "l_class_OC_EchoIndication.h"
void l_class_OC_EchoIndication::heard(unsigned int heard_v) {
        stop_main_program = 1;
        ("Heard an echo: %d\n")->(heard_v);
}
bool l_class_OC_EchoIndication::heard__RDY(void) {
        return 1;
}
