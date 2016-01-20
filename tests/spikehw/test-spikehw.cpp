#include <stdio.h>

#include <spikehw.h>

SpikeHw *spikeHw;

int main(int argc, const char **argv)
{
    spikeHw = new SpikeHw();
    // not needed yet
    //spikeHw->setupDma(memfd);

    // query mmcm and interrupt status
    spikeHw->status();

    // read ethernet identification register
    uint32_t id;
    spikeHw->read(0x180000 + 0x4f8, (uint8_t *)&id);
    fprintf(stderr, "AXI Ethernet Identification %08x (expected %08x)\n", id, 0x09000000);
    return 0;
}
