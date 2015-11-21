

/* Global Variable Definitions and Initialization */
class l_class_OC_EchoTest echoTest;
unsigned int stop_main_program;
//processing _ZN14EchoIndication4echoEi
void _ZN14EchoIndication4echoEi(unsigned int Vv) {
        printf((("Heard an echo: %d\n")), Vv);
        stop_main_program = 1;
}
//processing printf
//processing _ZN14EchoIndication4echoEi
bool l_class_OC_EchoTest::rule_drive__RDY(void) {
    bool tmp__1 =     ((*((echo)->fifo)).enq__RDY)();
        return tmp__1;
}
void l_class_OC_EchoTest::rule_drive(void) {
        ((*((echo)->fifo)).enq)(22);
}
void l_class_OC_EchoTest::run()
{
    if (rule_drive__RDY()) rule_drive();
    echo->run();
}
bool l_class_OC_Echo::rule_respond__RDY(void) {
    bool tmp__1 =     ((*(fifo)).deq__RDY)();
    bool tmp__2 =     ((*(fifo)).first__RDY)();
        return (tmp__1 & tmp__2);
}
void l_class_OC_Echo::rule_respond(void) {
        ((*(fifo)).deq)();
    unsigned int call =     ((*(fifo)).first)();
        _ZN14EchoIndication4echoEi(call);
}
void l_class_OC_Echo::run()
{
    if (rule_respond__RDY()) rule_respond();
}
void l_class_OC_Fifo1::deq(void) {
        (full) = 0;
}
bool l_class_OC_Fifo1::enq__RDY(void) {
        return ((full) ^ 1);
}
void l_class_OC_Fifo1::enq(unsigned int v) {
        (element) = v;
        (full) = 1;
}
bool l_class_OC_Fifo1::deq__RDY(void) {
        return (full);
}
bool l_class_OC_Fifo1::first__RDY(void) {
        return (full);
}
unsigned int l_class_OC_Fifo1::first(void) {
        return (element);
}
