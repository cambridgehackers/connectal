#include "HdmiDisplay.h"

HdmiDisplay *HdmiDisplay::createHdmiDisplay(const char *instanceName)
{
    HdmiDisplay *instance = new HdmiDisplay(instanceName);
    return instance;
}

HdmiDisplay::HdmiDisplay(const char *instanceName)
 : PortalInstance(instanceName)
{
}
HdmiDisplay::~HdmiDisplay()
{
    close();
}


struct HdmiDisplaysetPatternRegMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long yuv422;

    } request;
};

void HdmiDisplay::setPatternReg ( unsigned long yuv422 )
{
    HdmiDisplaysetPatternRegMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 0;
    msg.request.yuv422 = yuv422;

    sendMessage(&msg);
};

struct HdmiDisplaystartFrameBuffer0MSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long base;

    } request;
};

void HdmiDisplay::startFrameBuffer0 ( unsigned long base )
{
    HdmiDisplaystartFrameBuffer0MSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 1;
    msg.request.base = base;

    sendMessage(&msg);
};

struct HdmiDisplaystartFrameBuffer1MSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long base;

    } request;
};

void HdmiDisplay::startFrameBuffer1 ( unsigned long base )
{
    HdmiDisplaystartFrameBuffer1MSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 2;
    msg.request.base = base;

    sendMessage(&msg);
};

struct HdmiDisplaywaitForVsyncMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long unused;

    } request;
};

void HdmiDisplay::waitForVsync ( unsigned long unused )
{
    HdmiDisplaywaitForVsyncMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 3;
    msg.request.unused = unused;

    sendMessage(&msg);
};

struct HdmiDisplayvsyncReceivedMSG : public PortalMessage
{
//fix Adapter.bsv to unreverse these
        unsigned long long result;

};

struct HdmiDisplayhdmiLinesPixelsMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long value;

    } request;
};

void HdmiDisplay::hdmiLinesPixels ( unsigned long value )
{
    HdmiDisplayhdmiLinesPixelsMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 5;
    msg.request.value = value;

    sendMessage(&msg);
};

struct HdmiDisplayhdmiBlankLinesPixelsMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long value;

    } request;
};

void HdmiDisplay::hdmiBlankLinesPixels ( unsigned long value )
{
    HdmiDisplayhdmiBlankLinesPixelsMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 6;
    msg.request.value = value;

    sendMessage(&msg);
};

struct HdmiDisplayhdmiStrideBytesMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long strideBytes;

    } request;
};

void HdmiDisplay::hdmiStrideBytes ( unsigned long strideBytes )
{
    HdmiDisplayhdmiStrideBytesMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 7;
    msg.request.strideBytes = strideBytes;

    sendMessage(&msg);
};

struct HdmiDisplayhdmiLineCountMinMaxMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long value;

    } request;
};

void HdmiDisplay::hdmiLineCountMinMax ( unsigned long value )
{
    HdmiDisplayhdmiLineCountMinMaxMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 8;
    msg.request.value = value;

    sendMessage(&msg);
};

struct HdmiDisplayhdmiPixelCountMinMaxMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long value;

    } request;
};

void HdmiDisplay::hdmiPixelCountMinMax ( unsigned long value )
{
    HdmiDisplayhdmiPixelCountMinMaxMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 9;
    msg.request.value = value;

    sendMessage(&msg);
};

struct HdmiDisplayhdmiSyncWidthsMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long value;

    } request;
};

void HdmiDisplay::hdmiSyncWidths ( unsigned long value )
{
    HdmiDisplayhdmiSyncWidthsMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 10;
    msg.request.value = value;

    sendMessage(&msg);
};

struct HdmiDisplaybeginTranslationTableMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long index:8;

    } request;
};

void HdmiDisplay::beginTranslationTable ( unsigned long index )
{
    HdmiDisplaybeginTranslationTableMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 11;
    msg.request.index = index;

    sendMessage(&msg);
};

struct HdmiDisplayaddTranslationEntryMSG : public PortalMessage
{
    struct Request {
    //fix Adapter.bsv to unreverse these
        unsigned long length:12;
        unsigned long address:20;

    } request;
};

void HdmiDisplay::addTranslationEntry ( unsigned long address, unsigned long length )
{
    HdmiDisplayaddTranslationEntryMSG msg;
    msg.size = sizeof(msg.request);
    msg.channel = 12;
    msg.request.address = address;
    msg.request.length = length;

    sendMessage(&msg);
};

struct HdmiDisplaytranslationTableEntryMSG : public PortalMessage
{
//fix Adapter.bsv to unreverse these
        std::bitset<96> result;

};

struct HdmiDisplayfbReadingMSG : public PortalMessage
{
//fix Adapter.bsv to unreverse these
        std::bitset<96> result;

};

void HdmiDisplay::handleMessage(PortalMessage *msg)
{
    switch (msg->channel) {
    case 4: vsyncReceived(((HdmiDisplayvsyncReceivedMSG *)msg)->result); break;
    case 13: translationTableEntry(((HdmiDisplaytranslationTableEntryMSG *)msg)->result); break;
    case 14: fbReading(((HdmiDisplayfbReadingMSG *)msg)->result); break;

    default: break;
    }
}
