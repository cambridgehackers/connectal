class DUT {
public:
    static DUT *createDUT(const char *instanceName);
    void operate ( unsigned int, unsigned int );
private:
    DUT(UshwInstance *);
    ~DUT();
    UshwInstance *p;
};
