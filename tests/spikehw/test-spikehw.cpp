#include <stdio.h>

#include <spikehw.h>

#include <riscv/decode.h>
#include <riscv/devices.h>
#include <map>
#include <vector>
#include <functional>

SpikeHw *spikeHw;

// spike stubs
std::map<reg_t, std::function<abstract_device_t*()>>& devices()
{
    std::map<reg_t, std::function<abstract_device_t*()>> v;
    return v;
}
void register_device(reg_t addr, std::function<abstract_device_t*()> f)
{
}

int main(int argc, const char **argv)
{
    spikeHw = new SpikeHw();
    // not needed yet
    //spikeHw->setupDma(memfd);

    // query mmcm and interrupt status
    spikeHw->status();

    // read boot rom
    uint32_t word = 0;
    uint32_t expected[] = {
	0x00001137,
	0x010000ef,
	0x20000513,
	0x00050067,
	0x0000006f,
	0x040007b7,
	0x40078793,
	0xfc0005b7
    };
    for (int i = 0; i < 8; i++){
	spikeHw->read(0x000000 + i*4, (uint8_t *)&word);
	fprintf(stderr, "word %04x of boot ROM %08x (expected %08x)\n", i*4, word, expected[i]);
    }

    // read ethernet identification register
    uint32_t id;
    spikeHw->read(0x180000 + 0x4f8, (uint8_t *)&id);
    fprintf(stderr, "AXI Ethernet Identification %08x (expected %08x)\n", id, 0x09000000);

    // put flash in query mode
    spikeHw->setFlashParameters(50); // divides clock by 50
    uint32_t values[4] = { 0x98 };
    spikeHw->writeFlash(0x00aa, (uint8_t *)&values[0]);
    spikeHw->readFlash(0x0020, (uint8_t *)&values[1]);
    spikeHw->readFlash(0x0022, (uint8_t *)&values[2]);
    spikeHw->readFlash(0x0024, (uint8_t *)&values[3]);
    fprintf(stderr, "Query flash %02x.%02x.%02x %c%c%c (expected QRY)\n", values[1], values[2], values[3], values[1], values[2], values[3]);

    return 0;
}
