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
typedef enum DmaErrorType { DmaErrorType_DmaErrorNone, DmaErrorType_DmaErrorSGLIdOutOfRange_r, DmaErrorType_DmaErrorSGLIdOutOfRange_w, DmaErrorType_DmaErrorMMUOutOfRange_r, DmaErrorType_DmaErrorMMUOutOfRange_w, DmaErrorType_DmaErrorOffsetOutOfRange, DmaErrorType_DmaErrorSGLIdInvalid } DmaErrorType;


void MemreadIndicationProxy_readDone (struct PortalInternal *p , const uint32_t mismatchCount );
enum { CHAN_NUM_MemreadIndicationProxy_readDone};
#define MemreadIndicationProxy_reqsize 4

int MemreadIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*readDone) (  struct PortalInternal *p, const uint32_t mismatchCount );
} MemreadIndicationWrapperCb;
enum { CHAN_NUM_MemreadIndicationWrapper_readDone};
#define MemreadIndicationWrapper_reqsize 4

void DmaDebugIndicationProxy_addrResponse (struct PortalInternal *p , const uint64_t physAddr );
void DmaDebugIndicationProxy_reportStateDbg (struct PortalInternal *p , const DmaDbgRec rec );
void DmaDebugIndicationProxy_reportMemoryTraffic (struct PortalInternal *p , const uint64_t words );
void DmaDebugIndicationProxy_error (struct PortalInternal *p , const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_DmaDebugIndicationProxy_addrResponse,CHAN_NUM_DmaDebugIndicationProxy_reportStateDbg,CHAN_NUM_DmaDebugIndicationProxy_reportMemoryTraffic,CHAN_NUM_DmaDebugIndicationProxy_error};
#define DmaDebugIndicationProxy_reqsize 24

int DmaDebugIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*addrResponse) (  struct PortalInternal *p, const uint64_t physAddr );
    void (*reportStateDbg) (  struct PortalInternal *p, const DmaDbgRec rec );
    void (*reportMemoryTraffic) (  struct PortalInternal *p, const uint64_t words );
    void (*error) (  struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
} DmaDebugIndicationWrapperCb;
enum { CHAN_NUM_DmaDebugIndicationWrapper_addrResponse,CHAN_NUM_DmaDebugIndicationWrapper_reportStateDbg,CHAN_NUM_DmaDebugIndicationWrapper_reportMemoryTraffic,CHAN_NUM_DmaDebugIndicationWrapper_error};
#define DmaDebugIndicationWrapper_reqsize 24

void MMUConfigRequestProxy_sglist (struct PortalInternal *p , const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len );
void MMUConfigRequestProxy_region (struct PortalInternal *p , const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
void MMUConfigRequestProxy_idRequest (struct PortalInternal *p , const SpecialTypeForSendingFd fd );
void MMUConfigRequestProxy_idReturn (struct PortalInternal *p , const uint32_t sglId );
enum { CHAN_NUM_MMUConfigRequestProxy_sglist,CHAN_NUM_MMUConfigRequestProxy_region,CHAN_NUM_MMUConfigRequestProxy_idRequest,CHAN_NUM_MMUConfigRequestProxy_idReturn};
#define MMUConfigRequestProxy_reqsize 40

int MMUConfigRequestWrapper_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*sglist) (  struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len );
    void (*region) (  struct PortalInternal *p, const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
    void (*idRequest) (  struct PortalInternal *p, const SpecialTypeForSendingFd fd );
    void (*idReturn) (  struct PortalInternal *p, const uint32_t sglId );
} MMUConfigRequestWrapperCb;
enum { CHAN_NUM_MMUConfigRequestWrapper_sglist,CHAN_NUM_MMUConfigRequestWrapper_region,CHAN_NUM_MMUConfigRequestWrapper_idRequest,CHAN_NUM_MMUConfigRequestWrapper_idReturn};
#define MMUConfigRequestWrapper_reqsize 40

void MMUConfigIndicationProxy_idResponse (struct PortalInternal *p , const uint32_t sglId );
void MMUConfigIndicationProxy_configResp (struct PortalInternal *p , const uint32_t sglId );
void MMUConfigIndicationProxy_error (struct PortalInternal *p , const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_MMUConfigIndicationProxy_idResponse,CHAN_NUM_MMUConfigIndicationProxy_configResp,CHAN_NUM_MMUConfigIndicationProxy_error};
#define MMUConfigIndicationProxy_reqsize 24

int MMUConfigIndicationWrapper_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*idResponse) (  struct PortalInternal *p, const uint32_t sglId );
    void (*configResp) (  struct PortalInternal *p, const uint32_t sglId );
    void (*error) (  struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
} MMUConfigIndicationWrapperCb;
enum { CHAN_NUM_MMUConfigIndicationWrapper_idResponse,CHAN_NUM_MMUConfigIndicationWrapper_configResp,CHAN_NUM_MMUConfigIndicationWrapper_error};
#define MMUConfigIndicationWrapper_reqsize 24

void MemreadRequestProxy_startRead (struct PortalInternal *p , const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
enum { CHAN_NUM_MemreadRequestProxy_startRead};
#define MemreadRequestProxy_reqsize 16

int MemreadRequestWrapper_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*startRead) (  struct PortalInternal *p, const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
} MemreadRequestWrapperCb;
enum { CHAN_NUM_MemreadRequestWrapper_startRead};
#define MemreadRequestWrapper_reqsize 16

void DmaDebugRequestProxy_addrRequest (struct PortalInternal *p , const uint32_t sglId, const uint32_t offset );
void DmaDebugRequestProxy_getStateDbg (struct PortalInternal *p , const ChannelType rc );
void DmaDebugRequestProxy_getMemoryTraffic (struct PortalInternal *p , const ChannelType rc );
enum { CHAN_NUM_DmaDebugRequestProxy_addrRequest,CHAN_NUM_DmaDebugRequestProxy_getStateDbg,CHAN_NUM_DmaDebugRequestProxy_getMemoryTraffic};
#define DmaDebugRequestProxy_reqsize 8

int DmaDebugRequestWrapper_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*addrRequest) (  struct PortalInternal *p, const uint32_t sglId, const uint32_t offset );
    void (*getStateDbg) (  struct PortalInternal *p, const ChannelType rc );
    void (*getMemoryTraffic) (  struct PortalInternal *p, const ChannelType rc );
} DmaDebugRequestWrapperCb;
enum { CHAN_NUM_DmaDebugRequestWrapper_addrRequest,CHAN_NUM_DmaDebugRequestWrapper_getStateDbg,CHAN_NUM_DmaDebugRequestWrapper_getMemoryTraffic};
#define DmaDebugRequestWrapper_reqsize 8
#ifdef __cplusplus
}
#endif
#endif //__GENERATED_TYPES__
