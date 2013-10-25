
interface IserdesDatadeser;
endinterface: IserdesDatadeser

import "BVI" iserdes_datadeser = 
module mkIserdesDatadeser#(Clock CLK, Clock CLKDIV)(IserdesDatadeser);

   default_clock clk(CLOCK);
   default_reset RESET;
   method ibufds_out(ibufds_out); // clocked_by () reset_by ()
   //method sdatan(SDATAN); // unused
   method align_start(ALIGN_START) clocked_by (CLOCK);
   method ALIGN_BUSY align_busy() clocked_by (CLOCK);
   method ALIGNED aligned() clocked_by (CLOCK);
   method SAMPLEINFIRSTBIT sampleinfirstbit() clocked_by (CLOCK);
   method SAMPLEINLASTBIT sampleinlastbit() clocked_by (CLOCK);
   method SAMPLEINOTHERBIT sampleinotherbit() clocked_by (CLOCK);
   method autoalign(AUTOALIGN) clocked_by (CLOCK);
   method training(TRAINING) clocked_by (CLOCK);
   method manual_tap(MANUAL_TAP) clocked_by (CLOCK);
   method fifo_wren(FIFO_WREN) clocked_by (CLKDIV);
   method delay_wren(DELAY_WREN) clocked_by (CLKDIV);
   method fifo_rden(FIFO_RDEN) clocked_by (CLOCK);
   method FIFO_EMPTY fifo_empty() clocked_by (CLOCK);
   method FIFO_DATAOUT fifo_dataout() clocked_by(CLOCK);

endmodule: vmkIserdesDatadeser
