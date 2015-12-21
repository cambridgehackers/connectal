class l_class_OC_EchoRequest {
public:
  void say(unsigned int v);
  bool say__RDY(void);
};

class l_class_OC_Module {
public:
};

class l_class_OC_Fifo {
public:
  void deq(void);
  bool deq__RDY(void);
  void enq(unsigned int v);
  bool enq__RDY(void);
  unsigned int first(void);
  bool first__RDY(void);
};

class l_class_OC_EchoIndication {
public:
  void heard(unsigned int v);
  bool heard__RDY(void);
};

class l_class_OC_Fifo1 {
public:
  unsigned int element;
  bool full;
  void deq(void);
  bool deq__RDY(void);
  void enq(unsigned int v);
  bool enq__RDY(void);
  unsigned int first(void);
  bool first__RDY(void);
};

class l_class_OC_Echo {
public:
  class l_class_OC_Fifo1 fifo;
  class l_class_OC_EchoIndication *ind;
  unsigned int pipetemp;
  void respond_rule(void);
  bool respond_rule__RDY(void);
  void say(unsigned int v);
  bool say__RDY(void);
  void run();
};

class l_class_OC_EchoTest {
public:
  class l_class_OC_Echo *echo;
  unsigned int x;
};

