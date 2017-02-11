#include <semaphore.h>
#include <iostream>
#include <iomanip>

#include "SPIIndication.h"
#include "SPIRequest.h"
#include "GeneratedTypes.h"
#include "portal.h"

// x is {2'b01, cmd, arg}
uint8_t getCRC7(uint64_t x) {
    uint8_t crc = 0;
    
    for (int i = 39 ; i >= 0 ; i--) {
        if (((crc >> 6) ^ (x >> i)) & 1) {
            crc = (0x7F & (crc << 1)) ^ 0x09;
        } else {
            crc = 0x7F & (crc << 1);
        }
    }

    return crc;
}

void printR1Resp( uint8_t resp ) {
    std::cout << "R1 Resp:";
    if (resp != 0) {
        if (resp & (1 << 7)) std::cout << " ERROR_first_bit_not_zero";
        if (resp & (1 << 6)) std::cout << " parameter_error";
        if (resp & (1 << 5)) std::cout << " address_error";
        if (resp & (1 << 4)) std::cout << " erase_sequence_error";
        if (resp & (1 << 3)) std::cout << " com_crc_error";
        if (resp & (1 << 2)) std::cout << " illegal_command";
        if (resp & (1 << 1)) std::cout << " erase_reset";
        if (resp & (1 << 0)) std::cout << " in_idle_state";
    } else {
        std::cout << " (all zero)";
    }
    std::cout << std::endl;
}

class SPI : public SPIIndicationWrapper {
    private:
        SPIRequestProxy spiRequest;
        sem_t sem;
        uint8_t data;

    public:
        SPI(unsigned int indicationId, unsigned int requestId)
                : SPIIndicationWrapper(indicationId),
                  spiRequest(requestId)
        {
            sem_init(&sem, 1, 0);
        }

        void setSclkDiv(uint16_t x) {
            spiRequest.setSclkDiv(x);
        }

        void enableChip(bool x) {
            // ncs is active-low, so true => 0 and false => 1
            if (x) {
                spiRequest.setNcs(0);
            } else {
                spiRequest.setNcs(1);
            }
        }

        uint8_t req(uint8_t x) {
            spiRequest.put(x);
            sem_wait(&sem);
            return data;
        }

        void get(uint8_t x) {
            data = x;
            sem_post(&sem);
        }
};

class SD_SPIMode {
    private:
        SPI *spi;
        bool verbose;

        static const int cmd_resp_no_resp_flag = 0x200; // set if SD card never sent a valid response
        static const int cmd_resp_error_flag   = 0x100; // set if there is a critical error in the response
        static const int cmd_resp_crc_error    = 0x008;
        static const int cmd_resp_illegal_cmd  = 0x004;

    public:
        SD_SPIMode(SPI* myspi) {
            spi = myspi;
            verbose = true;
        }

        // If this returns a value greater than 0xFF, then any further response
        // bytes will not be sent.
        int sendSDReq(uint8_t cmdIndx, uint32_t arg) {
            // This extra request is needed for some reason. This is not part
            // of the actual command.
            spi->req(0xFF);

            // Calculate crc
            uint64_t crc_in = 0x4000000000ull;
            crc_in = crc_in | ((0x3F & ((uint64_t) cmdIndx)) << 32) | ((uint64_t) arg);
            uint8_t crc = getCRC7(crc_in);

            // Send command
            if (verbose) std::cout << "Sending CMD" << std::dec << (int) cmdIndx << " with argument 0x" << std::hex << arg << std::endl;
            spi->req(0x40 | (0x3F & cmdIndx));
            spi->req(0xFF & (arg >> (3*8)));
            spi->req(0xFF & (arg >> (2*8)));
            spi->req(0xFF & (arg >> (1*8)));
            spi->req(0xFF & arg);
            spi->req(0x01 | ((0x7F & crc) << 1));

            // Get initial R1 response
            int resp;
            for (int i = 0 ; i <= 8 ; i++) {
                resp = (int) spi->req(0xFF);
                if ((resp & 0x80) == 0) {
                    // This is a valid response
                    if (resp & cmd_resp_illegal_cmd) {
                        std::cerr << "ERROR: CMD" << std::dec << (int) cmdIndx << " is not supported by this SD card" << std::endl;
                        // Set error flag
                        resp |= cmd_resp_error_flag;
                    }
                    if (resp & cmd_resp_crc_error) {
                        std::cerr << "ERROR: sendSDReq() for CMD" << std::dec << (int) cmdIndx << " had a CRC error" << std::endl;
                        // Set error flag
                        resp |= cmd_resp_error_flag;
                    }
                    return resp;
                }
            }
            std::cerr << "ERROR: sendSDReq() for CMD" << std::dec << (int) cmdIndx << " failed to get an R1 response after 9 tries" << std::endl;
            return cmd_resp_no_resp_flag;
        }

        uint8_t getByteResp() {
            return spi->req(0xFF);
        }

        uint32_t getWordResp() {
            uint32_t resp = (0xFF & ((uint32_t) spi->req(0xFF))) << (8*3);
            resp = resp | (0xFF & ((uint32_t) spi->req(0xFF))) << (8*2);
            resp = resp | (0xFF & ((uint32_t) spi->req(0xFF))) << (8*1);
            resp = resp | (0xFF & ((uint32_t) spi->req(0xFF)));
            return resp;
        }

        // This follows the SDHC portion of figure 7-2 in the Physical Layer
        // Specification Version 5.00
        bool init(uint16_t d) {
            spi->enableChip(false);
            spi->setSclkDiv(d);
            usleep(100000);
            spi->enableChip(true);
            usleep(100000);

            for (int i = 0 ; i < 10 ; i++) {
                spi->req(0xFF);
            }

            // CMD0
            if (verbose) std::cout << "init(): sending CMD0" << std::endl;
            int resp = sendSDReq(0, 0);
            if (resp > 0xFF) {
                return false;
            }
            if (resp != 1) {
                std::cerr << "ERROR: Unexpected R1 response from CMD0 during init()" << std::endl;
                printR1Resp(resp);
                return false;
            }

            // CMD8 - specifying 2.7-2.6 V and using 0x5B as the check pattern
            if (verbose) std::cout << "init(): sending CMD8" << std::endl;
            uint8_t echo_back = 0x5B;
            resp = sendSDReq(8, 0x100 | ((uint32_t) echo_back));
            if (resp > 0xFF) {
                if (resp & cmd_resp_illegal_cmd) {
                    std::cerr << "INFO: CMD8 is not supported by this SD card (SD card Ver 1.X)" << std::endl;
                    std::cerr << "ERROR: This code does not support SD card Ver 1.X" << std::endl;
                    printR1Resp(0xFF & resp);
                }
                return false;
            }
            uint32_t r7 = getWordResp();
            if (r7 != (0x100 | ((uint32_t) echo_back))) {
                std::cerr << "ERROR: CMD8 echo failed. r7 = " << std::hex << r7 << std::endl;
                return false;
            }

            // CMD58 (optional) - read OCR
            if (verbose) std::cout << "init(): sending CMD58" << std::endl;
            resp = sendSDReq(58, 0);
            if (resp > 0xFF) {
                return false;
            }
            uint32_t ocr = getWordResp();
            bool ccs = (bool) (ocr & (1ull << 30));
            bool ready = (bool) (ocr & (1ull << 31));
            if (verbose) {
                std::cout << "OCR: 0x" << std::hex << ocr << std::dec << std::endl;
                std::cout << "ccs: " << (ccs ? "yes" : "no") << std::endl;
                std::cout << "ready: " << (ready ? "yes" : "no") << std::endl;
            }

            // CMD55 -> ACMD41
            if (verbose) std::cout << "init(): sending CMD55 and ACMD41" << std::endl;
            do {
                resp = sendSDReq(55, 0);
                if (resp > 0xFF) {
                    return false;
                }
                resp = sendSDReq(41, 0x1u << 30); // HCS = 1
                if (resp > 0xFF) {
                    return false;
                }
                usleep(1000);
            } while (resp == 1);

            // CMD58 - read OCR (again)
            if (verbose) std::cout << "init(): sending CMD58" << std::endl;
            resp = sendSDReq(58, 0);
            if (resp > 0xFF) {
                return false;
            }
            ocr = getWordResp();
            ccs = (bool) (ocr & (1ull << 30));
            ready = (bool) (ocr & (1ull << 31));
            if (verbose) {
                std::cout << "OCR: 0x" << std::hex << ocr << std::dec << std::endl;
                std::cout << "ccs: " << (ccs ? "yes" : "no") << std::endl;
                std::cout << "ready: " << (ready ? "yes" : "no") << std::endl;
            }

            if (!ready) {
                std::cerr << "ERROR: ready bit in OCR is not set" << std::endl;
                return false;
            }
            if (!ccs) {
                std::cerr << "INFO: ccs bit in OCR is not set." << std::endl;
                std::cerr << "ERROR: This code does not suport normal SD cards at the moment" << std::endl;
                return false;
            }

            if (verbose) {
                std::cout << "init(): made it to the end without failing" << std::endl;
            }
            return true;
        }

        // The block is 512 bytes
        bool readBlock(uint32_t blockAddr, void* data) {
            uint8_t resp = sendSDReq(17, blockAddr);
            if (resp > 0xFF) {
                std::cerr << "ERROR: readBlock failed" << std::endl;
                return false;
            }
            if (resp != 0) {
                printR1Resp(0xFF & resp);
            }

            uint8_t byte = 0;
            do {
                byte = spi->req(0xFF);
            } while (byte == 0xFF);

            // the first byte of the data response should be 0xFE
            if (byte != 0xFE) {
                std::cerr << "ERROR: Unexpected start of write block. resp = 0x" << std::hex << (int) resp << std::endl;
                return false;
            }

            uint8_t *dataChar = (uint8_t*) data;
            for (int i = 0 ; i < 512 ; i++) {
                dataChar[i] = spi->req(0xFF);
            }
            // Ignore the 16-bit CRC for now
            spi->req(0xFF);
            spi->req(0xFF);
            // Read was successful
            return true;
        } 
};

int main(int argc, char* argv[]) {
    simulator_dump_vcd = 1;

    SPI spi(IfcNames_SPIIndicationH2S, IfcNames_SPIRequestS2H);

    SD_SPIMode sd(&spi);

    // 2500 is the argument for setSclkDiv
    if (!sd.init(2500)) {
        std::cerr << "ERROR: sd.init() failed" << std::endl;
        return -1;
    } else {
        std::cout << "sd.init() successful" << std::endl;
    }

    // much faster clock
    spi.setSclkDiv(2);

    uint8_t data[512];
    std::cout << "reading block 0" << std::endl;
    sd.readBlock(0, (void*) data);

    std::cout << "printing block 0" << std::endl;
    for (int i = 0 ; i < 512 ; i++) {
        if (((i % 16) == 0) && (i != 0)) {
            std::cout << std::endl;
        } else if (((i % 2) == 0) && (i != 0)) {
            std::cout << " ";
        }
        std::cout << std::setfill('0') << std::setw(2) << std::hex << (int) data[i];
    }
    std::cout << std::endl;

    return 0;
}
