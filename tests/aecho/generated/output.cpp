

/* Global Variable Definitions and Initialization */
class l_class_OC_EchoTest echoTest;
unsigned int stop_main_program;
class l_class_OC_Module *_ZN6Module5firstE;
//processing _ZN4Echo7respond8respond23RDYEv
bool _ZN4Echo7respond8respond23RDYEv(void) {
        return 1;
}
//processing _ZN4Echo7respond8respond23ENAEv
void _ZN4Echo7respond8respond23ENAEv(void) {
}
//processing _ZN4Echo7respond8respond13RDYEv
bool _ZN4Echo7respond8respond13RDYEv(void) {
    bool Vtmp__1 =     echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_.deq__RDY();
    bool Vtmp__2 =     echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_.first__RDY();
        return (Vtmp__1 & Vtmp__2);
}
//processing _ZN4Echo7respond8respond13ENAEv
void _ZN4Echo7respond8respond13ENAEv(void) {
        echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_.deq();
    unsigned int Vcall =     echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_.first();
        _ZN14EchoIndication4echoEi(Vcall);
}
//processing _ZN8EchoTest5drive3RDYEv
bool _ZN8EchoTest5drive3RDYEv(void) {
    bool Vtmp__1 =     echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_.enq__RDY();
        return Vtmp__1;
}
//processing _ZN8EchoTest5drive3ENAEv
void _ZN8EchoTest5drive3ENAEv(void) {
        echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_.enq(22);
}
//processing _ZN14EchoIndication4echoEi
void _ZN14EchoIndication4echoEi(unsigned int Vv) {
        printf((("Heard an echo: %d\n")), Vv);
        stop_main_program = 1;
}
//processing printf
typedef struct {
    bool (*RDY)(void);
    void (*ENA)(void);
    } RuleVTab;//Rules:
const RuleVTab ruleList[] = {
    {_ZN4Echo7respond8respond23RDYEv, _ZN4Echo7respond8respond23ENAEv},
    {_ZN4Echo7respond8respond13RDYEv, _ZN4Echo7respond8respond13ENAEv},
    {_ZN8EchoTest5drive3RDYEv, _ZN8EchoTest5drive3ENAEv},
    {} };
