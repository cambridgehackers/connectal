#include "vlsim.h"
#include "verilated.h"
#include <XsimTop.h>
#include <ConnectalProjectConfig.h>

#ifdef BSV_POSITIVE_RESET
  #define BSV_RESET_VALUE 1
  #define BSV_RESET_EDGE 0 //posedge
#else
  #define BSV_RESET_VALUE 0
  #define BSV_RESET_EDGE 1 //negedge
#endif

#if VM_TRACE
# include <verilated_vcd_c.h>   // Trace file format header                                                                                        
#endif

vluint64_t main_time = 0;
int main(int argc, char **argv, char **env)
{
  fprintf(stderr, "vlsim::main\n");
  Verilated::commandArgs(argc, argv);
  vlsim* top = new vlsim;

  fprintf(stderr, "vlsim calling dpi_init\n");
  dpi_init();

#if VM_TRACE                    // If verilator was invoked with --trace                                                                           
  Verilated::traceEverOn(true);       // Verilator must compute traced signals                                                                   
  VL_PRINTF("Enabling waves...\n");
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace (tfp, 4);       // Trace 4 levels of hierarchy
  tfp->open ("vlt_dump.vcd"); // Open the dump file                                                                                              
#endif

  fprintf(stderr, "starting simulation\n");
  top->CLK = 0;
  top->RST_N = BSV_RESET_VALUE;
  while (!Verilated::gotFinish()) {
    if (main_time >= 10) {
      if ((top->CLK == BSV_RESET_EDGE) && (top->RST_N == BSV_RESET_VALUE)) {
	fprintf(stderr, "time=%d leaving reset new value %d\n", main_time, !BSV_RESET_VALUE);
	top->RST_N = !BSV_RESET_VALUE;
      }
    }

    if ((main_time % 2) == 1) {	// Toggle clock
      top->CLK = 1;
    }
    if ((main_time % 2) == 0) {
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
