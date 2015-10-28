class l_class_OC_Fifo1;
class l_class_OC_Fifo;
class l_class_OC_Module;
class l_class_OC_Module {
public:
  class l_class_OC_Rule *rfirst;
  class l_class_OC_Module *next;
  class l_class_OC_Module *shadow;
  unsigned long long size;
};

class l_class_OC_Fifo {
public:
  unsigned int  (**Module) ( int, ...);
  class l_class_OC_Module _vptr_EC_Fifo;
};

class l_class_OC_Fifo1 {
public:
  class l_class_OC_Fifo Fifo_MD_int_OD_;
  unsigned int element;
  bool full;
bool enq__RDY(void) {
          return ((full) ^ 1);
;
}

void enq(unsigned int v) {
        (element) = v;
        (full) = 1;
}

bool deq__RDY(void) {
          return (full);
;
}

void deq(void) {
        (full) = 0;
}

bool first__RDY(void) {
          return (full);
;
}

unsigned int first(void) {
          return (element);
;
}

};

class l_class_OC_EchoTest;
class l_class_OC_EchoTest_KD__KD_drive;
class l_class_OC_Rule;
class l_class_OC_Rule {
public:
  unsigned int  (**_vptr_EC_Rule) ( int, ...);
  class l_class_OC_Rule *next;
};

class l_class_OC_EchoTest_KD__KD_drive {
public:
  class l_class_OC_Rule Rule;
  class l_class_OC_EchoTest *module;
};

class l_class_OC_EchoTest {
public:
  class l_class_OC_Module Module;
  class l_class_OC_Echo *echo;
  unsigned int x;
  class l_class_OC_EchoTest_KD__KD_drive driveRule;
};

class l_class_OC_Echo_KD__KD_respond_KD__KD_respond2;
class l_class_OC_Echo_KD__KD_respond_KD__KD_respond2 {
public:
  class l_class_OC_Rule Rule;
  class l_class_OC_Echo *module;
};

class l_class_OC_Echo_KD__KD_respond_KD__KD_respond1;
class l_class_OC_Echo_KD__KD_respond_KD__KD_respond1 {
public:
  class l_class_OC_Rule Rule;
  class l_class_OC_Echo *module;
};


/* External Global Variable Declarations */
extern class l_class_OC_EchoTest echoTest;
extern unsigned char *_ZTVN10__cxxabiv120__si_class_type_infoE;
extern unsigned char *_ZTVN10__cxxabiv117__class_type_infoE;
extern unsigned char *_ZTVN10__cxxabiv121__vmi_class_type_infoE;
extern unsigned int stop_main_program;
extern class l_class_OC_Module *_ZN6Module5firstE;

/* Function Declarations */
void _ZN14EchoIndication4echoEi(unsigned int Vv);
static void __cxx_global_var_init(void);
void _ZN8EchoTestC1Ev(class l_class_OC_EchoTest *Vthis);
void _ZN8EchoTestD1Ev(class l_class_OC_EchoTest *Vthis);
static void __dtor_echoTest(void);
void _ZN8EchoTestD2Ev(class l_class_OC_EchoTest *Vthis);
void _ZN8EchoTestC2Ev(class l_class_OC_EchoTest *Vthis);
void _ZN6ModuleC2Em(class l_class_OC_Module *Vthis, unsigned long long Vsize);
unsigned char *_Znwm(unsigned long long );
void _ZN4EchoC1EP14EchoIndication(class l_class_OC_Echo *Vthis, class l_class_OC_EchoIndication *Vind);
void _ZN14EchoIndicationC1Ev(class l_class_OC_EchoIndication *Vthis);
void _ZN8EchoTest5driveC1EPS_(class l_class_OC_EchoTest_KD__KD_drive *Vthis, class l_class_OC_EchoTest *Vmodule);
void _ZN8EchoTest5driveC2EPS_(class l_class_OC_EchoTest_KD__KD_drive *Vthis, class l_class_OC_EchoTest *Vmodule);
void _ZN4RuleC2Ev(class l_class_OC_Rule *Vthis);
void _ZN6Module7addRuleEP4Rule(class l_class_OC_Module *Vthis, class l_class_OC_Rule *Vrule);
bool _ZN8EchoTest5drive5guardEv(class l_class_OC_EchoTest_KD__KD_drive *Vthis);
void _ZN8EchoTest5drive6updateEv(class l_class_OC_EchoTest_KD__KD_drive *Vthis);
void _ZN14EchoIndicationC2Ev(class l_class_OC_EchoIndication *Vthis);
void _ZN4EchoC2EP14EchoIndication(class l_class_OC_Echo *Vthis, class l_class_OC_EchoIndication *Vind);
void _ZN5Fifo1IiEC1Ev(class l_class_OC_Fifo1 *Vthis);
void _ZN4Echo7respondC1EPS_(class l_class_OC_Echo_KD__KD_respond *Vthis, class l_class_OC_Echo *Vmodule);
void _ZN4Echo7respondC2EPS_(class l_class_OC_Echo_KD__KD_respond *Vthis, class l_class_OC_Echo *Vmodule);
void _ZN4Echo7respond8respond1C1EPS_(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond1 *Vthis, class l_class_OC_Echo *Vmodule);
void _ZN4Echo7respond8respond2C1EPS_(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond2 *Vthis, class l_class_OC_Echo *Vmodule);
void _ZN4Echo7respond8respond2C2EPS_(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond2 *Vthis, class l_class_OC_Echo *Vmodule);
bool _ZN4Echo7respond8respond25guardEv(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond2 *Vthis);
void _ZN4Echo7respond8respond26updateEv(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond2 *Vthis);
void _ZN4Echo7respond8respond1C2EPS_(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond1 *Vthis, class l_class_OC_Echo *Vmodule);
bool _ZN4Echo7respond8respond15guardEv(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond1 *Vthis);
void _ZN4Echo7respond8respond16updateEv(class l_class_OC_Echo_KD__KD_respond_KD__KD_respond1 *Vthis);
void _ZN5Fifo1IiEC2Ev(class l_class_OC_Fifo1 *Vthis);
void _ZN4FifoIiEC2Em(class l_class_OC_Fifo *Vthis, unsigned long long Vsize);
void _ZN5Fifo1IiED1Ev(class l_class_OC_Fifo1 *Vthis);
void _ZN5Fifo1IiED0Ev(class l_class_OC_Fifo1 *Vthis);
bool _ZN5Fifo1IiE8enq__RDYEv(class l_class_OC_Fifo1 *Vthis);
void _ZN5Fifo1IiE3enqEi(class l_class_OC_Fifo1 *Vthis, unsigned int Vv);
bool _ZN5Fifo1IiE8deq__RDYEv(class l_class_OC_Fifo1 *Vthis);
void _ZN5Fifo1IiE3deqEv(class l_class_OC_Fifo1 *Vthis);
bool _ZN5Fifo1IiE10first__RDYEv(class l_class_OC_Fifo1 *Vthis);
unsigned int _ZN5Fifo1IiE5firstEv(class l_class_OC_Fifo1 *Vthis);
bool _ZNK5Fifo1IiE8notEmptyEv(class l_class_OC_Fifo1 *Vthis);
bool _ZNK5Fifo1IiE7notFullEv(class l_class_OC_Fifo1 *Vthis);
void _ZdlPv(unsigned char *);
void _ZN5Fifo1IiED2Ev(class l_class_OC_Fifo1 *Vthis);
void _ZN4FifoIiED2Ev(class l_class_OC_Fifo *Vthis);
void _ZN4FifoIiED1Ev(class l_class_OC_Fifo *Vthis);
void _ZN4FifoIiED0Ev(class l_class_OC_Fifo *Vthis);
bool _ZN4FifoIiE8enq__RDYEv(class l_class_OC_Fifo *Vthis);
bool _ZN4FifoIiE8deq__RDYEv(class l_class_OC_Fifo *Vthis);
bool _ZN4FifoIiE10first__RDYEv(class l_class_OC_Fifo *Vthis);
unsigned char *malloc(unsigned long long );
static void _GLOBAL__I_a(void);
void _Z16run_main_programv(void);
unsigned char *llvm_translate_malloc(unsigned long long );
unsigned char *memset(unsigned char *, unsigned int , unsigned long long );
