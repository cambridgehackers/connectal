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


void MemreadIndication_readDone ( struct PortalInternal *p, const uint32_t mismatchCount );
enum { CHAN_NUM_MemreadIndication_readDone};
#define MemreadIndication_reqsize 4

int MemreadIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*readDone) (  struct PortalInternal *p, const uint32_t mismatchCount );
} MemreadIndicationCb;

void DmaDebugIndication_addrResponse ( struct PortalInternal *p, const uint64_t physAddr );
void DmaDebugIndication_reportStateDbg ( struct PortalInternal *p, const DmaDbgRec rec );
void DmaDebugIndication_reportMemoryTraffic ( struct PortalInternal *p, const uint64_t words );
enum { CHAN_NUM_DmaDebugIndication_addrResponse,CHAN_NUM_DmaDebugIndication_reportStateDbg,CHAN_NUM_DmaDebugIndication_reportMemoryTraffic};
#define DmaDebugIndication_reqsize 16

int DmaDebugIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*addrResponse) (  struct PortalInternal *p, const uint64_t physAddr );
    void (*reportStateDbg) (  struct PortalInternal *p, const DmaDbgRec rec );
    void (*reportMemoryTraffic) (  struct PortalInternal *p, const uint64_t words );
} DmaDebugIndicationCb;

void MMUConfigRequest_sglist ( struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len );
void MMUConfigRequest_region ( struct PortalInternal *p, const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
void MMUConfigRequest_idRequest ( struct PortalInternal *p, const SpecialTypeForSendingFd fd );
void MMUConfigRequest_idReturn ( struct PortalInternal *p, const uint32_t sglId );
void MMUConfigRequest_setInterface ( struct PortalInternal *p, const uint32_t interfaceId, const uint32_t sglId );
enum { CHAN_NUM_MMUConfigRequest_sglist,CHAN_NUM_MMUConfigRequest_region,CHAN_NUM_MMUConfigRequest_idRequest,CHAN_NUM_MMUConfigRequest_idReturn,CHAN_NUM_MMUConfigRequest_setInterface};
#define MMUConfigRequest_reqsize 40

int MMUConfigRequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*sglist) (  struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len );
    void (*region) (  struct PortalInternal *p, const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
    void (*idRequest) (  struct PortalInternal *p, const SpecialTypeForSendingFd fd );
    void (*idReturn) (  struct PortalInternal *p, const uint32_t sglId );
    void (*setInterface) (  struct PortalInternal *p, const uint32_t interfaceId, const uint32_t sglId );
} MMUConfigRequestCb;

void MMUConfigIndication_idResponse ( struct PortalInternal *p, const uint32_t sglId );
void MMUConfigIndication_configResp ( struct PortalInternal *p, const uint32_t sglId );
void MMUConfigIndication_error ( struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
void MMUConfigIndication_dmaError ( struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_MMUConfigIndication_idResponse,CHAN_NUM_MMUConfigIndication_configResp,CHAN_NUM_MMUConfigIndication_error,CHAN_NUM_MMUConfigIndication_dmaError};
#define MMUConfigIndication_reqsize 24

int MMUConfigIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*idResponse) (  struct PortalInternal *p, const uint32_t sglId );
    void (*configResp) (  struct PortalInternal *p, const uint32_t sglId );
    void (*error) (  struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
    void (*dmaError) (  struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
} MMUConfigIndicationCb;

void MemreadRequest_startRead ( struct PortalInternal *p, const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
enum { CHAN_NUM_MemreadRequest_startRead};
#define MemreadRequest_reqsize 16

int MemreadRequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*startRead) (  struct PortalInternal *p, const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
} MemreadRequestCb;

void DmaDebugRequest_addrRequest ( struct PortalInternal *p, const uint32_t sglId, const uint32_t offset );
void DmaDebugRequest_getStateDbg ( struct PortalInternal *p, const ChannelType rc );
void DmaDebugRequest_getMemoryTraffic ( struct PortalInternal *p, const ChannelType rc );
enum { CHAN_NUM_DmaDebugRequest_addrRequest,CHAN_NUM_DmaDebugRequest_getStateDbg,CHAN_NUM_DmaDebugRequest_getMemoryTraffic};
#define DmaDebugRequest_reqsize 8

int DmaDebugRequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*addrRequest) (  struct PortalInternal *p, const uint32_t sglId, const uint32_t offset );
    void (*getStateDbg) (  struct PortalInternal *p, const ChannelType rc );
    void (*getMemoryTraffic) (  struct PortalInternal *p, const ChannelType rc );
} DmaDebugRequestCb;
#ifdef __cplusplus
}
#endif
#endif //__GENERATED_TYPES__
