class l_class_OC_EchoRequest {
private:
public:
  void say(unsigned int say_v);
  bool say__RDY(void);
};

class l_class_OC_EchoIndication {
private:
public:
  void heard(unsigned int heard_v);
  bool heard__RDY(void);
};

class l_class_OC_Echo {
private:
  class l_class_OC_Fifo1 fifo;
  class l_class_OC_EchoIndication *ind;
  unsigned int pipetemp;
public:
  void respond_rule(void);
  bool respond_rule__RDY(void);
  void say(unsigned int say_v);
  bool say__RDY(void);
  void run();
  void setind(class l_class_OC_EchoIndication *v) { ind = v; }
};

class l_class_OC_EchoTest {
private:
  class l_class_OC_Echo *echo;
  unsigned int x;
public:
  void setecho(class l_class_OC_Echo *v) { echo = v; }
};

