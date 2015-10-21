#include "Vxsimtop.h"
#include "verilated.h"
#if VM_TRACE
# include <verilated_vcd_c.h>   // Trace file format header                                                                                        
#endif

vluint64_t main_time = 0;
int main(int argc, char **argv, char **env)
{
  Verilated::commandArgs(argc, argv);
  Vxsimtop* top = new Vxsimtop;

#if VM_TRACE                    // If verilator was invoked with --trace                                                                           
  Verilated::traceEverOn(true);       // Verilator must compute traced signals                                                                   
  VL_PRINTF("Enabling waves...\n");
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 4);       // Trace 4 levels of hierarchy
  tfp->open ("vlt_dump.vcd"); // Open the dump file                                                                                              
#endif

  //top->CLK = 0;
  while (!Verilated::gotFinish()) {
    if ((main_time % 4) == 1) {	// Toggle clock
      top->CLK = 1;
    }
    if ((main_time % 4) == 3) {
      top->CLK = 0;
    }
    top->eval();

#if VM_TRACE
    if (tfp) tfp->dump (main_time); // Create waveform trace for this timestamp                                                                
#endif

    main_time++;
  }
  top->final();

#if VM_TRACE                                                                                                                                       
  if (tfp) tfp->close();                                                                                                                         
#endif                                                                                                                                             

  delete top;
  exit(0);
}
