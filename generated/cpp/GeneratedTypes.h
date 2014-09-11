#ifndef __GENERATED_TYPES__
#define __GENERATED_TYPES__
#include "portal.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef enum IfcNames { IfcNames_MemreadIndication, IfcNames_MemreadRequest, IfcNames_HostDmaDebugIndication, IfcNames_HostDmaDebugRequest, IfcNames_HostMMUConfigRequest, IfcNames_HostMMUConfigIndication } IfcNames;
typedef enum ChannelType { ChannelType_Read, ChannelType_Write } ChannelType;
typedef struct DmaDbgRec {
    uint32_t x : 32;
    uint32_t y : 32;
    uint32_t z : 32;
    uint32_t w : 32;
} DmaDbgRec;
typedef enum DmaErrorType { DmaErrorType_DmaErrorNone, DmaErrorType_DmaErrorBadPointer1, DmaErrorType_DmaErrorBadPointer2, DmaErrorType_DmaErrorBadPointer3, DmaErrorType_DmaErrorBadPointer4, DmaErrorType_DmaErrorBadPointer5, DmaErrorType_DmaErrorBadAddrTrans, DmaErrorType_DmaErrorBadPageSize, DmaErrorType_DmaErrorBadNumberEntries, DmaErrorType_DmaErrorBadAddr, DmaErrorType_DmaErrorTagMismatch } DmaErrorType;

enum { CHAN_NUM_MMUConfigRequestProxy_sglist,CHAN_NUM_MMUConfigRequestProxy_region,CHAN_NUM_MMUConfigRequestProxy_idRequest,CHAN_NUM_MMUConfigRequestProxy_putFailed};

int MMUConfigRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void MMUConfigRequestProxy_sglist (struct PortalInternal *p , const uint32_t pointer, const uint32_t pointerIndex, const uint64_t addr, const uint32_t len );

void MMUConfigRequestProxy_region (struct PortalInternal *p , const uint32_t pointer, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );

void MMUConfigRequestProxy_idRequest (struct PortalInternal *p   );
enum { CHAN_NUM_MemreadRequestProxy_startRead,CHAN_NUM_MemreadRequestProxy_putFailed};

int MemreadRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void MemreadRequestProxy_startRead (struct PortalInternal *p , const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
enum { CHAN_NUM_DmaDebugRequestProxy_addrRequest,CHAN_NUM_DmaDebugRequestProxy_getStateDbg,CHAN_NUM_DmaDebugRequestProxy_getMemoryTraffic,CHAN_NUM_DmaDebugRequestProxy_putFailed};

int DmaDebugRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void DmaDebugRequestProxy_addrRequest (struct PortalInternal *p , const uint32_t pointer, const uint32_t offset );

void DmaDebugRequestProxy_getStateDbg (struct PortalInternal *p , const ChannelType rc );

void DmaDebugRequestProxy_getMemoryTraffic (struct PortalInternal *p , const ChannelType rc );

int MemreadIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void MemreadIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t mismatchCount );
enum { CHAN_NUM_MemreadIndicationWrapper_readDone};

int DmaDebugIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void DmaDebugIndicationWrapperaddrResponse_cb (  struct PortalInternal *p, const uint64_t physAddr );
void DmaDebugIndicationWrapperreportStateDbg_cb (  struct PortalInternal *p, const DmaDbgRec rec );
void DmaDebugIndicationWrapperreportMemoryTraffic_cb (  struct PortalInternal *p, const uint64_t words );
void DmaDebugIndicationWrappererror_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_DmaDebugIndicationWrapper_addrResponse,CHAN_NUM_DmaDebugIndicationWrapper_reportStateDbg,CHAN_NUM_DmaDebugIndicationWrapper_reportMemoryTraffic,CHAN_NUM_DmaDebugIndicationWrapper_error};

int MMUConfigIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void MMUConfigIndicationWrapperidResponse_cb (  struct PortalInternal *p, const uint32_t sglId );
void MMUConfigIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer );
void MMUConfigIndicationWrappererror_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_MMUConfigIndicationWrapper_idResponse,CHAN_NUM_MMUConfigIndicationWrapper_configResp,CHAN_NUM_MMUConfigIndicationWrapper_error};
#ifdef __cplusplus
}
#endif
#endif //__GENERATED_TYPES__
