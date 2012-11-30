#include "ushw.h"
#include "dut.h"

int main(int argc, const char **argv)
{
    DUT *dut = DUT::createDUT("foobridge1");
    int result = dut->operate(0x0fad0000, 0x00000bad);
    printf("Received result %08x\n", result);
    return 0;
}
