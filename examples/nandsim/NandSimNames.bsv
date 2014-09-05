

typedef enum {
   
   HostmemDmaDebugIndication, 
   HostmemDmaDebugRequest,
   NandsimDmaDebugIndication, 
   NandsimDmaDebugRequest,
	      
   BackingStoreSGListConfigRequest,
   BackingStoreSGListConfigIndication,
   AlgoSGListConfigRequest,
   AlgoSGListConfigIndication,
   NandsimSGListConfigRequest,
   NandsimSGListConfigIndication,

   NandSimIndication, 
   NandSimRequest, 
   AlgoIndication, 
   AlgoRequest 
 
   } IfcNames deriving (Eq,Bits);

