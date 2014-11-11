#ifndef __GENERATED_TYPES__
#define __GENERATED_TYPES__
#include "portal.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef enum IfcNames { IfcNames_MemreadIndication, IfcNames_MemreadRequest, IfcNames_HostMemServerIndication, IfcNames_HostMemServerRequest, IfcNames_HostMMURequest, IfcNames_HostMMUIndication } IfcNames;
typedef enum ChannelType { ChannelType_Read, ChannelType_Write } ChannelType;
typedef struct DmaDbgRec {
    uint32_t x : 32;
    uint32_t y : 32;
    uint32_t z : 32;
    uint32_t w : 32;
} DmaDbgRec;
typedef enum DmaErrorType { DmaErrorType_DmaErrorNone, DmaErrorType_DmaErrorSGLIdOutOfRange_r, DmaErrorType_DmaErrorSGLIdOutOfRange_w, DmaErrorType_DmaErrorMMUOutOfRange_r, DmaErrorType_DmaErrorMMUOutOfRange_w, DmaErrorType_DmaErrorOffsetOutOfRange, DmaErrorType_DmaErrorSGLIdInvalid } DmaErrorType;


void MMUIndication_idResponse ( struct PortalInternal *p, const uint32_t sglId );
void MMUIndication_configResp ( struct PortalInternal *p, const uint32_t sglId );
void MMUIndication_error ( struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_MMUIndication_idResponse,CHAN_NUM_MMUIndication_configResp,CHAN_NUM_MMUIndication_error};
#define MMUIndication_reqsize 28

int MMUIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*idResponse) (  struct PortalInternal *p, const uint32_t sglId );
    void (*configResp) (  struct PortalInternal *p, const uint32_t sglId );
    void (*error) (  struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
} MMUIndicationCb;

void MemServerIndication_addrResponse ( struct PortalInternal *p, const uint64_t physAddr );
void MemServerIndication_reportStateDbg ( struct PortalInternal *p, const DmaDbgRec rec );
void MemServerIndication_reportMemoryTraffic ( struct PortalInternal *p, const uint64_t words );
void MemServerIndication_error ( struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
enum { CHAN_NUM_MemServerIndication_addrResponse,CHAN_NUM_MemServerIndication_reportStateDbg,CHAN_NUM_MemServerIndication_reportMemoryTraffic,CHAN_NUM_MemServerIndication_error};
#define MemServerIndication_reqsize 28

int MemServerIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*addrResponse) (  struct PortalInternal *p, const uint64_t physAddr );
    void (*reportStateDbg) (  struct PortalInternal *p, const DmaDbgRec rec );
    void (*reportMemoryTraffic) (  struct PortalInternal *p, const uint64_t words );
    void (*error) (  struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra );
} MemServerIndicationCb;

void MMURequest_sglist ( struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len );
void MMURequest_region ( struct PortalInternal *p, const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
void MMURequest_idRequest ( struct PortalInternal *p, const SpecialTypeForSendingFd fd );
void MMURequest_idReturn ( struct PortalInternal *p, const uint32_t sglId );
void MMURequest_setInterface ( struct PortalInternal *p, const uint32_t interfaceId, const uint32_t sglId );
enum { CHAN_NUM_MMURequest_sglist,CHAN_NUM_MMURequest_region,CHAN_NUM_MMURequest_idRequest,CHAN_NUM_MMURequest_idReturn,CHAN_NUM_MMURequest_setInterface};
#define MMURequest_reqsize 44

int MMURequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*sglist) (  struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len );
    void (*region) (  struct PortalInternal *p, const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 );
    void (*idRequest) (  struct PortalInternal *p, const SpecialTypeForSendingFd fd );
    void (*idReturn) (  struct PortalInternal *p, const uint32_t sglId );
    void (*setInterface) (  struct PortalInternal *p, const uint32_t interfaceId, const uint32_t sglId );
} MMURequestCb;

void MemreadIndication_readDone ( struct PortalInternal *p, const uint32_t mismatchCount );
enum { CHAN_NUM_MemreadIndication_readDone};
#define MemreadIndication_reqsize 8

int MemreadIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*readDone) (  struct PortalInternal *p, const uint32_t mismatchCount );
} MemreadIndicationCb;

void MemServerRequest_addrTrans ( struct PortalInternal *p, const uint32_t sglId, const uint32_t offset );
void MemServerRequest_stateDbg ( struct PortalInternal *p, const ChannelType rc );
void MemServerRequest_memoryTraffic ( struct PortalInternal *p, const ChannelType rc );
enum { CHAN_NUM_MemServerRequest_addrTrans,CHAN_NUM_MemServerRequest_stateDbg,CHAN_NUM_MemServerRequest_memoryTraffic};
#define MemServerRequest_reqsize 12

int MemServerRequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*addrTrans) (  struct PortalInternal *p, const uint32_t sglId, const uint32_t offset );
    void (*stateDbg) (  struct PortalInternal *p, const ChannelType rc );
    void (*memoryTraffic) (  struct PortalInternal *p, const ChannelType rc );
} MemServerRequestCb;

void MemreadRequest_startRead ( struct PortalInternal *p, const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
enum { CHAN_NUM_MemreadRequest_startRead};
#define MemreadRequest_reqsize 20

int MemreadRequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef struct {
    void (*startRead) (  struct PortalInternal *p, const uint32_t pointer, const uint32_t numWords, const uint32_t burstLen, const uint32_t iterCnt );
} MemreadRequestCb;
#ifdef __cplusplus
}
#endif
#endif //__GENERATED_TYPES__
