

typedef enum {
   
   HostDmaDebugIndication, 
   HostDmaDebugRequest,
   NandsimDmaDebugIndication, 
   NandsimDmaDebugRequest,
	      
   BackingStoreMMUConfigRequest,
   BackingStoreMMUConfigIndication,
   AlgoMMUConfigRequest,
   AlgoMMUConfigIndication,
   NandsimMMUConfigRequest,
   NandsimMMUConfigIndication,

   NandSimIndication, 
   NandSimRequest, 
   AlgoIndication, 
   AlgoRequest 
 
   } IfcNames deriving (Eq,Bits);

