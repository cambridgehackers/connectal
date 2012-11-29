class DUT {
public:
    static DUT *createDUT(const char *instanceName);
    void put ( unsigned int, unsigned int );
    void get (  );
private:
    DUT(UshwInstance *);
    ~DUT();
    UshwInstance *p;
};
