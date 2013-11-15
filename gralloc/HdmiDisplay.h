#include "portal.h"

class HdmiDisplayIndications : public PortalIndication {
public:
    HdmiDisplayIndications();
    virtual ~HdmiDisplayIndications();
    virtual void vsync ( unsigned long long ){ }

protected:
    virtual void handleMessage(PortalMessage *msg);
    friend class PortalRequest;
};

class HdmiDisplay : public PortalRequest {
public:
    static HdmiDisplay *createHdmiDisplay(const char *instanceName, HdmiDisplayIndications *indications=0);
    void setPatternReg ( unsigned long );
    void startFrameBuffer0 ( unsigned long );
    void startFrameBuffer1 ( unsigned long );
    void waitForVsync ( unsigned long );
    void hdmiLinesPixels ( unsigned long );
    void hdmiBlankLinesPixels ( unsigned long );
    void hdmiStrideBytes ( unsigned long );
    void hdmiLineCountMinMax ( unsigned long );
    void hdmiPixelCountMinMax ( unsigned long );
    void hdmiSyncWidths ( unsigned long );
    void beginTranslationTable ( unsigned long );
    void addTranslationEntry ( unsigned long, unsigned long );

protected:
    HdmiDisplay(const char *instanceName, HdmiDisplayIndications *indications=0);
    ~HdmiDisplay();
};
