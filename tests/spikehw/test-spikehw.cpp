#include <stdio.h>

#include "spikehw.h"

#ifdef REGISTER_SPIKE_DEVICES
#include <riscv/decode.h>
#include <riscv/devices.h>
#include <map>
#include <vector>
#include <functional>
#endif

static SpikeHw *spikeHw;

#ifdef REGISTER_SPIKE_DEVICES
// spike stubs
std::map<reg_t, std::function<abstract_device_t*()>>& devices()
{
    static std::map<reg_t, std::function<abstract_device_t*()>> v;
    return v;
}
void register_device(reg_t addr, std::function<abstract_device_t*()> f)
{
}
void register_mem_allocator(std::function<char *(size_t)> f)
{
}
#endif

const char *regnames[] = {
  "CR",
  "SR",
  "TX_FIFO",
  "RX_FIFO",
  "ADR",
  "TX_FIFO_OCY",
  "RX_FIFO_OCY",
  "TBA",
  "RX_FIFO_DEPTH",
  "GPO"  
};

static void dumpI2cRegs()
{
    fprintf(stderr, "------------------------------------------------------------\n");
    fprintf(stderr, "I2C GIE %04x\n", spikeHw->read(0x10301c));
    fprintf(stderr, "I2C ISR %04x\n", spikeHw->read(0x103020));
    fprintf(stderr, "I2C IER %04x\n", spikeHw->read(0x103028));

    for (int i = 0; i < 10; i++)
	fprintf(stderr, "I2C REG%d %s %04x\n", i, regnames[i], spikeHw->read(0x103100 + 4*i));
    fprintf(stderr, "------------------------------------------------------------\n");
}

int main(int argc, const char **argv)
{
    spikeHw = new SpikeHw();
    // not needed yet
    //spikeHw->setupDma(memfd);

    // query mmcm and interrupt status
    spikeHw->status();

    fprintf(stderr, "boot rom[0] %x\n", spikeHw->read(0));

    fprintf(stderr, "scratch register %x\n", spikeHw->read(0x10001c));
    spikeHw->write(0x10001c, 0x22);
    fprintf(stderr, "scratch register %x\n", spikeHw->read(0x10001c));
    fprintf(stderr, "scratch register %x\n", spikeHw->read(0x10001c));
    fprintf(stderr, "scratch register %x\n", spikeHw->read(0x10001c));
    fprintf(stderr, "scratch register %x\n", spikeHw->read(0x10001c));

    spikeHw->read(0x100000);
    spikeHw->write(0x100000, 'h');

    spikeHw->write(0x103040, 0xa); // SOFTR

    dumpI2cRegs();

    // let's read i2c 0x50
    spikeHw->write(0x103108, 0x100 | (0x56 << 1) | 1); // TX_FIFO
    spikeHw->write(0x103120, 1); // RX_FIFO_DEPTH
    spikeHw->write(0x103100, 5); // CR enable
    spikeHw->write(0x103108, (uint32_t)1); // TX_FIFO
    spikeHw->write(0x103108, 0x200 | 2); // TX_FIFO
    fprintf(stderr, "I2C RX_FIFO_OCY %04x\n", spikeHw->read(0x103118));

    dumpI2cRegs();
    dumpI2cRegs();
    dumpI2cRegs();
    dumpI2cRegs();

    return 0;

    // let's write 1 to 0x50
    spikeHw->write(0x103108, 0x100 | (0x56 << 1) | 0); // TX_FIFO
    spikeHw->write(0x103100, 5); // CR enable
    spikeHw->write(0x103108, 0x200 | 1); // TX_FIFO

    dumpI2cRegs();


    // let's read i2c 0x50
    spikeHw->write(0x103108, 0x100 | (0x56 << 1) | 1); // TX_FIFO
    spikeHw->write(0x103120, 2); // RX_FIFO_DEPTH
    spikeHw->write(0x103100, 5); // CR enable
    spikeHw->write(0x103108, 0x200 | 1); // TX_FIFO
    fprintf(stderr, "I2C RX_FIFO_OCY %04x\n", spikeHw->read(0x103118));

    dumpI2cRegs();
    return 0;

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
