`include "ConnectalProjectConfig.bsv"
import FShow::*;

//**********************************************************
// Type definitions of the flash controller and submodules
//**********************************************************

//NAND geometry
//Actual page size is 8640B, but we don't need the last 40B for ECC
//Valid Data: 2 x (243B x 16 + 208B) = 8192B; 
//With ECC: 2 x (255B x 16 + 220B) = 8600
typedef 8600 			PageSize;
typedef 8192 			PageSizeUser;
typedef 17 				PageECCBlks; //16 blocks of k=243; 1 block of k=208
`ifdef SIMULATION
	typedef 16 			PagesPerBlock;
	typedef 128			BlocksPerCE;
	typedef 8 			ChipsPerBus;
`elsif SLC
	typedef 128 		PagesPerBlock;
	typedef 8192 		BlocksPerCE;
	typedef 4 			ChipsPerBus;
`else //MLC
	typedef 256		 	PagesPerBlock;
	typedef 4096 		BlocksPerCE;
	typedef 8 			ChipsPerBus;
`endif 

typedef 2											BusWordBytes;
typedef TMul#(8, BusWordBytes) 				BusWordSz;
typedef 16 											WordBytes;
typedef TLog#(WordBytes)						WordBytesLog;
typedef TMul#(8,WordBytes) 					WordSz;
//Each burst is 128 bits via the controller interface
typedef TDiv#(PageSizeUser, WordBytes) 	PageWords;
typedef TMul#(TMul#(BlocksPerCE, PagesPerBlock), PageWords) WordsPerChip;

typedef WordSz FlashDataWidth;
typedef 44  FlashAddrWidth;

Integer pageSize 			= valueOf(PageSize); //bytes
Integer pageSizeUser 	= valueOf(PageSizeUser); //usable page size is 8k
Integer pageECCBlks 		= valueOf(PageECCBlks); //16 blocks of k=243; 1 block of k=208
Integer pagesPerBlock 	= valueOf(PagesPerBlock);
Integer blocksPerCE 		= valueOf(BlocksPerCE);
Integer chipsPerBus		= valueOf(ChipsPerBus);
Integer wordBytes 		= valueOf(WordBytes);
Integer pageWords 		= valueOf(PageWords);
//Integer blocksPerPlane = 2048;
//Integer planesPerLun = 2;
//Integer lunsPerTarget = 1; //1 for SLC, 2 for MLC


`ifdef NAND_SIM
	typedef 1 NUM_CHIPBUSES;
`else
	typedef 4 NUM_CHIPBUSES; 
`endif
	
typedef 2 BUSES_PER_CHIPBUS;
typedef TMul#(NUM_CHIPBUSES, BUSES_PER_CHIPBUS) NUM_BUSES;

typedef 8 NUM_DEBUG_ILAS;

typedef TMul#(NUM_BUSES, ChipsPerBus) NUM_TOTAL_CHIPS;


typedef 128 NumTags;
//typedef Bit#(TLog#(TDiv#(NumTags, NUM_BUSES))) BusTagT;
typedef Bit#(TLog#(NumTags)) TagT;
typedef Bit#(TLog#(ChipsPerBus)) ChipT;
typedef Bit#(TLog#(NUM_BUSES)) BusT;

Integer num_tags = valueOf(NumTags);
Integer num_buses = valueOf(NUM_BUSES);

typedef enum {
	SRC_HOST,
	SRC_USER_HW
} SourceT deriving (Bits, Eq, FShow);

typedef enum {
	ERASE_ERROR, 
   ERASE_DONE, 
	WRITE_DONE
} StatusT deriving (Bits, Eq);



//----------------------
//Aurora related types
//----------------------
typedef enum {
	F_CMD,
	F_DATA,
	F_ACK,
	F_WR_REQ
} PacketClass deriving (Bits, Eq);


//----------------------
//Phy related types
//----------------------
typedef enum {
	PHY_CHIP_SEL,
	PHY_DESELECT_ALL,
	PHY_CMD,
	PHY_READ,
	PHY_WRITE,
	PHY_ADDR,
	PHY_SYNC_CALIB,
	PHY_ENABLE_NAND_CLK
} PhyCycle deriving (Bits, Eq);

typedef enum {
	N_RESET = 8'hFF,
	N_READ_STATUS = 8'h70,
	N_SET_FEATURES = 8'hEF,
	N_PROGRAM_PAGE = 8'h80,
	N_PROGRAM_PAGE_END = 8'h10,
	N_READ_MODE = 8'h00,
	N_READ_PAGE_END = 8'h30,
	N_ERASE_BLOCK = 8'h60,
	N_ERASE_BLOCK_END = 8'hD0,
	N_READ_ID = 8'h90

} ONFICmd deriving (Bits, Eq);

//using tagged union
typedef union tagged {
	ONFICmd OnfiCmd;
	ChipT ChipSel;
} NandCmd deriving (Bits);

typedef struct {
	Bool inSyncMode;
	PhyCycle phyCycle;
	NandCmd nandCmd;
	Bit#(16) numBurst;
	Bit#(32) postCmdWait; //number of cycles to wait after the command
} PhyCmd deriving (Bits);




//---------------------------------
// Bus controller related types
//---------------------------------
typedef enum {
	//INIT_BUS,
	//EN_SYNC,
	//INIT_SYNC,
	//READ_DATA,
	READ_CMD,
	GET_STATUS_READ_DATA,
	WRITE_DATA_BUF_REQ,
	WRITE_CMD_DATA,
	WRITE_GET_STATUS, 
	ERASE_CMD,
	ERASE_GET_STATUS,
	INVALID
} BusOp deriving (Bits, Eq);

typedef struct {
	TagT tag;
	BusOp busOp;
	ChipT chip;
	Bit#(16) block;
	Bit#(8) page;
} BusCmd deriving (Bits, Eq);


//---------------------------------
// Flash controller related types
//---------------------------------

typedef enum {
	INIT_BUS,
	EN_SYNC,
	INIT_SYNC,
	READ_PAGE,
	WRITE_PAGE,
	ERASE_BLOCK,
	INVALID
} FlashOp deriving (Bits, Eq);

typedef struct {
	TagT tag;
	FlashOp op;
	BusT bus; //3
	ChipT chip; //3
	Bit#(16) block;
	Bit#(8) page;
} FlashCmd deriving (Bits, Eq);

typedef struct {
	Bit#(8) page;
	Bit#(16) block;
	ChipT chip;
	BusT bus;
} FlashAddr deriving (Bits, Eq);

// Flash Controller User Ifc
interface FlashCtrlUser;
	method Action sendCmd (FlashCmd cmd);
	method Action writeWord (Tuple2#(Bit#(128), TagT) taggedData);
	method ActionValue#(Tuple2#(Bit#(128), TagT)) readWord (); 
	method ActionValue#(TagT) writeDataReq(); 
	method ActionValue#(Tuple2#(TagT, StatusT)) ackStatus (); 
endinterface

instance FShow#(BusOp);
	function Fmt fshow (BusOp label);
		case(label)
			READ_CMD: return fshow("BUSOP READ_CMD");
			GET_STATUS_READ_DATA: return fshow("BUSOP GET_STATUS_READ_DATA");
			WRITE_CMD_DATA: return fshow("BUSOP WRITE_CMD_DATA");
			ERASE_CMD: return fshow("BUSOP ERASE_CMD");
			WRITE_GET_STATUS: return fshow("BUSOP WRITE_GET_STATUS");
			WRITE_DATA_BUF_REQ: return fshow("BUSOP WRITE_DATA_BUF_REQ");
			ERASE_GET_STATUS: return fshow("BUSOP ERASE_GET_STATUS");
			INVALID: return fshow("BUSOP INVALID");
		endcase
	endfunction
endinstance


