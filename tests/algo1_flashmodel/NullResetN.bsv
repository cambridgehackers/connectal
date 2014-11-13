package NullResetN;

interface NullResetNIfc;
	interface Reset rst_n;
endinterface

import "BVI" null_reset_n =
module mkNullResetN (NullResetNIfc);
	default_clock no_clock;
	default_reset no_reset;

	output_reset rst_n(RESET_N);
endmodule

endpackage: NullResetN
