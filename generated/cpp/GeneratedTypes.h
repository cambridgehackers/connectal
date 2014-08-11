#ifndef __GENERATED_TYPES__
#define __GENERATED_TYPES__
#include "portal.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef enum IfcNames { IfcNames_MemreadIndication, IfcNames_MemreadRequest, IfcNames_DmaIndication, IfcNames_DmaConfig } IfcNames;
typedef enum ChannelType { ChannelType_Read, ChannelType_Write } ChannelType;
typedef struct DmaDbgRec {
    uint32_t x : 32;
    uint32_t y : 32;
    uint32_t z : 32;
    uint32_t w : 32;
} DmaDbgRec;
typedef enum DmaErrorType { DmaErrorType_DmaErrorNone, DmaErrorType_DmaErrorBadPointer1, DmaErrorType_DmaErrorBadPointer2, DmaErrorType_DmaErrorBadPointer3, DmaErrorType_DmaErrorBadPointer4, DmaErrorType_DmaErrorBadPointer5, DmaErrorType_DmaErrorBadAddrTrans, DmaErrorType_DmaErrorBadPageSize, DmaErrorType_DmaErrorBadNumberEntries, DmaErrorType_DmaErrorBadAddr, DmaErrorType_DmaErrorTagMismatch } DmaErrorType;

enum { CHAN_NUM_DmaConfigProxy_sglist,CHAN_NUM_DmaConfigProxy_region,CHAN_NUM_DmaConfigProxy_addrRequest,CHAN_NUM_DmaConfigProxy_getStateDbg,CHAN_NUM_DmaConfigProxy_getMemoryTraffic,CHAN_NUM_DmaConfigProxy_putFailed};

int DmaConfigProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void DmaConfigProxy_sglist (struct PortalInternal *p , const uint32_t pointer, const uint32_t pointerIndex, const uint64_t addr, const uint32_t len );

void DmaConfigProxy_region (struct PortalInternal *p , const uint32_t pointer, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );

void DmaConfigProxy_addrRequest (struct PortalInternal *p , const uint32_t pointer, const uint32_t offset );

void DmaConfigProxy_getStateDbg (struct PortalInternal *p , const ChannelType rc );

void DmaConfigProxy_getMemoryTraffic (struct PortalInternal *p , const ChannelType rc );
enum { CHAN_NUM_MemreadRequestProxy_startRead,CHAN_NUM_MemreadRequestProxy_putFailed};

int MemreadRequestProxy_handleMessage(struct PortalInternal *p, unsigned int channel);

void MemreadRequestProxy_startRead (struct PortalInternal *p , const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );

int MemreadIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void MemreadIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t mismatchCount );
enum { CHAN_NUM_MemreadIndicationWrapper_readDone};

int DmaIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel);
void DmaIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer );
void DmaIndicationWrapperaddrResponse_cb (  struct PortalInternal *p, const uint64_t physAddr );
void DmaIndicationWrapperreportStateDbg_cb (  struct PortalInternal *p, const DmaDbgRec rec );
void DmaIndicationWrapperreportMemoryTraffic_cb (  struct PortalInternal *p, const uint64_t words );
void DmaIndicationWrapperdmaError_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_DmaIndicationWrapper_configResp,CHAN_NUM_DmaIndicationWrapper_addrResponse,CHAN_NUM_DmaIndicationWrapper_reportStateDbg,CHAN_NUM_DmaIndicationWrapper_reportMemoryTraffic,CHAN_NUM_DmaIndicationWrapper_dmaError};
#ifdef __cplusplus
}
#endif
#endif //__GENERATED_TYPES__
