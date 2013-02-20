#include "portal.h"

class HdmiDisplay : public PortalInstance {
public:
    static HdmiDisplay *createHdmiDisplay(const char *instanceName);
    void setPatternReg ( unsigned long );
    void startFrameBuffer0 ( unsigned long );
    void startFrameBuffer1 ( unsigned long );
    void waitForVsync ( unsigned long );
    virtual void vsyncReceived ( unsigned long long ){ }
    void hdmiLinesPixels ( unsigned long );
    void hdmiBlankLinesPixels ( unsigned long );
    void hdmiStrideBytes ( unsigned long );
    void hdmiLineCountMinMax ( unsigned long );
    void hdmiPixelCountMinMax ( unsigned long );
    void hdmiSyncWidths ( unsigned long );
    void beginTranslationTable ( unsigned long );
    void addTranslationEntry ( unsigned long, unsigned long );
    virtual void translationTableEntry ( std::bitset<96> ){ }
    virtual void fbReading ( std::bitset<96> ){ }

protected:
    void handleMessage(PortalMessage *msg);
    HdmiDisplay(const char *instanceName);
    ~HdmiDisplay();
};
