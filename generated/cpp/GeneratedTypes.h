#ifndef __GENERATED_TYPES__
#define __GENERATED_TYPES__
#include "portal.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef enum IfcNames { IfcNames_HostDmaDebugIndication, IfcNames_HostDmaDebugRequest, IfcNames_NandsimDmaDebugIndication, IfcNames_NandsimDmaDebugRequest, IfcNames_BackingStoreSGListConfigRequest, IfcNames_BackingStoreSGListConfigIndication, IfcNames_AlgoSGListConfigRequest, IfcNames_AlgoSGListConfigIndication, IfcNames_NandsimSGListConfigRequest, IfcNames_NandsimSGListConfigIndication, IfcNames_NandSimIndication, IfcNames_NandSimRequest, IfcNames_AlgoIndication, IfcNames_AlgoRequest } IfcNames;
typedef enum ChannelType { ChannelType_Read, ChannelType_Write } ChannelType;
typedef struct DmaDbgRec {
    uint32_t x : 32;
    uint32_t y : 32;
    uint32_t z : 32;
    uint32_t w : 32;
} DmaDbgRec;
typedef enum DmaErrorType { DmaErrorType_DmaErrorNone, DmaErrorType_DmaErrorBadPointer1, DmaErrorType_DmaErrorBadPointer2, DmaErrorType_DmaErrorBadPointer3, DmaErrorType_DmaErrorBadPointer4, DmaErrorType_DmaErrorBadPointer5, DmaErrorType_DmaErrorBadAddrTrans, DmaErrorType_DmaErrorBadPageSize, DmaErrorType_DmaErrorBadNumberEntries, DmaErrorType_DmaErrorBadAddr, DmaErrorType_DmaErrorTagMismatch } DmaErrorType;

enum { CHAN_NUM_NandSimRequestProxy_startRead,CHAN_NUM_NandSimRequestProxy_startWrite,CHAN_NUM_NandSimRequestProxy_startErase,CHAN_NUM_NandSimRequestProxy_configureNand,CHAN_NUM_NandSimRequestProxy_putFailed};

int NandSimRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void NandSimRequestProxy_startRead (struct PortalInternal *p , const uint32_t drampointer, const uint32_t dramOffset, const uint32_t nandAddr, const uint32_t numBytes, const uint32_t burstLen );

void NandSimRequestProxy_startWrite (struct PortalInternal *p , const uint32_t drampointer, const uint32_t dramOffset, const uint32_t nandAddr, const uint32_t numBytes, const uint32_t burstLen );

void NandSimRequestProxy_startErase (struct PortalInternal *p , const uint32_t nandAddr, const uint32_t numBytes );

void NandSimRequestProxy_configureNand (struct PortalInternal *p , const uint32_t ptr, const uint32_t numBytes );
enum { CHAN_NUM_SGListConfigRequestProxy_sglist,CHAN_NUM_SGListConfigRequestProxy_region,CHAN_NUM_SGListConfigRequestProxy_putFailed};

int SGListConfigRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void SGListConfigRequestProxy_sglist (struct PortalInternal *p , const uint32_t pointer, const uint32_t pointerIndex, const uint64_t addr, const uint32_t len );

void SGListConfigRequestProxy_region (struct PortalInternal *p , const uint32_t pointer, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
enum { CHAN_NUM_DmaDebugRequestProxy_addrRequest,CHAN_NUM_DmaDebugRequestProxy_getStateDbg,CHAN_NUM_DmaDebugRequestProxy_getMemoryTraffic,CHAN_NUM_DmaDebugRequestProxy_putFailed};

int DmaDebugRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void DmaDebugRequestProxy_addrRequest (struct PortalInternal *p , const uint32_t pointer, const uint32_t offset );

void DmaDebugRequestProxy_getStateDbg (struct PortalInternal *p , const ChannelType rc );

void DmaDebugRequestProxy_getMemoryTraffic (struct PortalInternal *p , const ChannelType rc );

int SGListConfigIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void SGListConfigIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer );
void SGListConfigIndicationWrappererror_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_SGListConfigIndicationWrapper_configResp,CHAN_NUM_SGListConfigIndicationWrapper_error};

int DmaDebugIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void DmaDebugIndicationWrapperaddrResponse_cb (  struct PortalInternal *p, const uint64_t physAddr );
void DmaDebugIndicationWrapperreportStateDbg_cb (  struct PortalInternal *p, const DmaDbgRec rec );
void DmaDebugIndicationWrapperreportMemoryTraffic_cb (  struct PortalInternal *p, const uint64_t words );
void DmaDebugIndicationWrappererror_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_DmaDebugIndicationWrapper_addrResponse,CHAN_NUM_DmaDebugIndicationWrapper_reportStateDbg,CHAN_NUM_DmaDebugIndicationWrapper_reportMemoryTraffic,CHAN_NUM_DmaDebugIndicationWrapper_error};

int NandSimIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void NandSimIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t tag );
void NandSimIndicationWrapperwriteDone_cb (  struct PortalInternal *p, const uint32_t tag );
void NandSimIndicationWrappereraseDone_cb (  struct PortalInternal *p, const uint32_t tag );
void NandSimIndicationWrapperconfigureNandDone_cb (  struct PortalInternal *p );
enum { CHAN_NUM_NandSimIndicationWrapper_readDone,CHAN_NUM_NandSimIndicationWrapper_writeDone,CHAN_NUM_NandSimIndicationWrapper_eraseDone,CHAN_NUM_NandSimIndicationWrapper_configureNandDone};
#ifdef __cplusplus
}
#endif
#endif //__GENERATED_TYPES__
