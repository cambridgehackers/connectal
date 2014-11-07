

typedef enum {
   
   HostMemServerIndication, 
   HostMemServerRequest,

   NandsimMemServer0Indication, 
   NandsimMemServer0Request,
   NandsimMemServer1Indication, 
   NandsimMemServer1Request,
	      
   BackingStoreMMURequest,
   BackingStoreMMUIndication,
   AlgoMMURequest,
   AlgoMMUIndication,

   NandsimMMU0Request,
   NandsimMMU0Indication,
   NandsimMMU1Request,
   NandsimMMU1Indication,

   NandSimIndication, 
   NandSimRequest, 
   AlgoIndication, 
   AlgoRequest 
 
   } IfcNames deriving (Eq,Bits);

