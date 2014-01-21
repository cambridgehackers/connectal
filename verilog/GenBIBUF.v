
module GenBIBUF(IO, PAD);

parameter SIZE = 1;
inout [SIZE-1:0]IO;
inout [SIZE-1:0]PAD;

genvar i;
generate
    for(i = 0; i < SIZE; i = i + 1) begin
        BIBUF(.PAD(PAD[i]), .IO(IO[i]));
    end
endgenerate
endmodule
