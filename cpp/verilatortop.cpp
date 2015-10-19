#include "Vxsimtop.h"
#include "verilated.h"
int main(int argc, char **argv, char **env)
{
  Verilated::commandArgs(argc, argv);
  Vxsimtop* top = new Vxsimtop;
  while (!Verilated::gotFinish()) { top->eval(); }
  delete top;
  exit(0);
}
