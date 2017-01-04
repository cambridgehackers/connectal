import BlockDev::*;
import Serial::*;
import Simple::*;

interface DevicesPorts ports;
   interface SerialPort serial;
   interface Client#(BlockDevTransfer,Bit#(32)) blockDev;
endinterface

interface Devices;
   interface SimpleRequest simple;
   interface SerialPort   serial;
   interface BlockDevPort blockDev;
   interface DevicesPorts ports;
endinterface

interface Devices#(SimpleIndication simpleIndication,
		   SerialIndication serialIndication,
		   BlockDevResponse blockDevResponse)(Devices);
   let simple <- mksimple(simpleIndication);
   let serial <- mkSerial(serialIndication);
   let blockDev <- mkBlockDev(blockDevResponse);

   interface SimpleRequest simple= simple.request;
   interface SerialPort   serial = serial.request;
   interface BlockDevPort blockDev = blockDev.request;;

   interface DevicesPorts ports;
      interface SerialPort serial = serial.port;
      interface Client#(BlockDevTransfer,Bit#(32)) blockDev.client;
   endinterface
endinterface
