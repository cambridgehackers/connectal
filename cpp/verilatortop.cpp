#include "Vxsimtop.h"
#include "verilated.h"
vluint64_t main_time = 0;
int main(int argc, char **argv, char **env)
{
  Verilated::commandArgs(argc, argv);
  Vxsimtop* top = new Vxsimtop;
  while (!Verilated::gotFinish()) {
    if ((main_time % 4) == 1) {	// Toggle clock
      top->CLK = 1;
    }
    if ((main_time % 4) == 3) {
      top->CLK = 0;
    }
    top->eval();
    main_time++;
  }
  delete top;
  exit(0);
}
