import SPI::*;

interface SPITest;
    interface SPIRequest spiRequest;
    (* prefix = "" *)
    interface SPIMasterPins spiMasterPins;
endinterface

interface SPIRequest;
    method Action setSclkDiv(Bit#(16) d);
    method Action setNcs(Bit#(1) x);
    method Action put(Bit#(8) x);
endinterface

interface SPIIndication;
    method Action get(Bit#(8) x);
endinterface

module mkSPITest#(SPIIndication spiIndication)(SPITest);
    SPIMaster spi <- mkSPIMaster;
    Reg#(Bool) init <- mkReg(False);
    Reg#(Bool) active <- mkReg(False);
    Bool verbose = False;

    rule doInit(!init);
        spi.setNcs(1);
        spi.setCpol(0);
        spi.setCpha(0);
        spi.setSclkDiv(2);
        init <= True;
    endrule

    rule doComplete;
        active <= False;
        let x <- spi.get;
        spiIndication.get(x);
        if (verbose) $display("get: ", fshow(x));
    endrule

    rule doDisplay(active);
        let sclk = spi.pins.sclk;
        let mosi = spi.pins.mosi;
        if (verbose) $display("sclk: %0d, mosi: %0d", sclk, mosi);
    endrule

    interface SPIRequest spiRequest;
        method Action setSclkDiv(Bit#(16) d);
            spi.setSclkDiv(d);
        endmethod
        method Action setNcs(Bit#(1) x);
            spi.setNcs(x);
        endmethod
        method Action put(Bit#(8) x);
            if (verbose) $display("put: ", fshow(x));
            active <= True;
            spi.put(x);
        endmethod
    endinterface

    interface SPIMasterPins spiMasterPins = spi.pins;
endmodule
