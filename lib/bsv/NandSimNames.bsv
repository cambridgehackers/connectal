

typedef enum {
   
   HostDmaDebugIndication, 
   HostDmaDebugRequest,

   NandsimDma0DebugIndication, 
   NandsimDma0DebugRequest,
   NandsimDma1DebugIndication, 
   NandsimDma1DebugRequest,
	      
   BackingStoreMMUConfigRequest,
   BackingStoreMMUConfigIndication,
   AlgoMMUConfigRequest,
   AlgoMMUConfigIndication,

   NandsimMMU0ConfigRequest,
   NandsimMMU0ConfigIndication,
   NandsimMMU1ConfigRequest,
   NandsimMMU1ConfigIndication,

   NandSimIndication, 
   NandSimRequest, 
   AlgoIndication, 
   AlgoRequest 
 
   } IfcNames deriving (Eq,Bits);

