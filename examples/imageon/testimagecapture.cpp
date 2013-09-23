
#include "ImageCapture.h"
#include <stdio.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <pthread.h>
#include <semaphore.h>
#include "i2chdmi.h"
#include "i2ccamera.h"
#include "/usr/include/linux/spi/spidev.h"

#define SPIDEVICENAME "/dev/spidev2.0"

static ImageCapture *device = 0;

#define DECL(A) \
    static sem_t sem_ ## A; \
    static unsigned long cv_ ## A;

DECL(iserdes_control)
DECL(decoder_control)
DECL(crc_control)
DECL(crc_status)
DECL(remapper_control)
DECL(triggen_control)
DECL(clock_gen_locked)

#define RXFN(A) \
    virtual void A ## _value ( unsigned long v ){ \
        cv_ ## A = v; \
        sem_post(&sem_ ## A); \
    }

#define GETFN(A) \
    static unsigned long read_ ## A (void) \
    { \
        device->get_ ## A(); \
        sem_wait(&sem_ ## A); \
        return cv_ ## A; \
    }

class TestImageCaptureIndications : public ImageCaptureIndications {
    void spi_trace_sample_count_value(long unsigned int) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    void spi_trace_sample_value(long long unsigned int) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    void spi_control_value(long unsigned int) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    void spi_rxfifo_value(long unsigned int) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    RXFN(iserdes_control)
    RXFN(decoder_control)
    RXFN(crc_control)
    RXFN(crc_status)
    RXFN(remapper_control)
    RXFN(triggen_control)
    RXFN(clock_gen_locked)
    void putFailed(unsigned long v){
      fprintf(stderr, "putFailed: %x\n", v);
      exit(1);
    }
    void debugind(long unsigned int v) {
printf("[%s:%d] valu %lx\n", __FUNCTION__, __LINE__, v);
    }
};

static void init_local_semaphores(void)
{
    sem_init(&sem_iserdes_control, 0, 0);
    sem_init(&sem_decoder_control, 0, 0);
    sem_init(&sem_crc_control, 0, 0);
    sem_init(&sem_remapper_control, 0, 0);
    sem_init(&sem_triggen_control, 0, 0);
    sem_init(&sem_crc_status, 0, 0);
    sem_init(&sem_clock_gen_locked, 0, 0);
}
GETFN(iserdes_control)
GETFN(decoder_control)
GETFN(crc_control)
GETFN(crc_status)
GETFN(remapper_control)
GETFN(triggen_control)
GETFN(clock_gen_locked)

//#define VITA_ISERDES_CONTROL_REG     0x0010
   #define VITA_ISERDES_RESET_BIT       0x0001
   #define VITA_ISERDES_AUTO_ALIGN_BIT  0x0002
   #define VITA_ISERDES_ALIGN_START_BIT 0x0004
   #define VITA_ISERDES_FIFO_ENABLE_BIT 0x0008
//#define VITA_DECODER_CONTROL_REG           0x0020
   #define VITA_DECODER_RESET_BIT            0x0001
   #define VITA_DECODER_ENABLE_BIT           0x0002
//#define VITA_CRC_CONTROL_REG               0x0070
   #define VITA_CRC_RESET_BIT              0x0001
   #define VITA_CRC_INITVALUE_BIT          0x0002
//#define VITA_CRC_STATUS_REG                0x0074

static uint32_t uManualTap;
static struct {
   // Sync Channel Decoder status
   uint32_t cntBlackLines;
   uint32_t cntImageLines;
   uint32_t cntBlackPixels;
   uint32_t cntImagePixels;
   uint32_t cntFrames;
   uint32_t cntWindows;
   uint32_t cntStartLines;
   uint32_t cntEndLines;
   uint32_t cntClocks;
   uint32_t crcStatus;
} vita_status_t2;

#define VITA_SPI_SEQ1_QTY  8
/* Table 6. enable clock management register upload - part 1 */
static uint16_t vita_spi_seq1[VITA_SPI_SEQ1_QTY][3] = {
   // Enable Clock Management - Part 1
   //    V1/SN/SE 10-bit mode with PLL
   {  2, 0xFFFF,      0}, // Monochrome Sensor
// {  2, 0xFFFF, 0x0001}, // Color Sensor
   { 32, 0xFFFF, 0x2004}, // Configure clock management
   { 20, 0xFFFF,      0}, // Configure clock management
   { 17, 0xFFFF, 0x2113}, // Configure PLL
   { 26, 0xFFFF, 0x2280}, // Configure PLL lock detector
   { 27, 0xFFFF, 0x3D2D}, // Configure PLL lock detector
   {  8, 0xFFFF,      0}, // Release PLL soft reset
   { 16, 0xFFFF, 0x0003}  // Enable PLL
};

#define VITA_SPI_SEQ3_QTY  3
/* Table 7. enable clock management register upload - part 2 */
static uint16_t vita_spi_seq3[VITA_SPI_SEQ3_QTY][3] = {
   // Enable Clock Management - Part 2
   //    V1/SN/SE 10-bit mode with PLL
   {  9, 0xFFFF,      0}, // Release clock generator soft reset
   { 32, 0xFFFF, 0x2006}, // Enable logic clock
   { 34, 0xFFFF, 0x0001}  // Enable logic blocks
};

#define VITA_SPI_SEQ4_QTY  17
/* Table 8. required register upload */
static uint16_t vita_spi_seq4[VITA_SPI_SEQ4_QTY][3] = {
   // Required Register Upload
   //    V1/SN/SE 10-bit mode with PLL
   { 41, 0xFFFF,      0}, // Configure image core
   {129, 0x2000,      0}, // [13] 10-bit mode
   { 65, 0xFFFF, 0x288B}, // Configure CP biasing
   { 66, 0xFFFF, 0x53C6}, // Configure AFE biasing
   { 67, 0xFFFF, 0x0344}, // Configure MUX biasing
   { 68, 0xFFFF, 0x0085}, // Configure LVDS biasing
   { 70, 0xFFFF, 0x4888}, // Configure reserved register
   { 81, 0xFFFF, 0x86A1}, // Configure reserved register
   {128, 0xFFFF, 0x460F}, // Configure  calibration
   {176, 0xFFFF, 0x00F5}, // Configure AEC
   {180, 0xFFFF, 0x00FD}, // Configure AEC
   {181, 0xFFFF, 0x0144}, // Configure AEC
   {194, 0xFFFF, 0x0404}, // Configure sequencer
   {218, 0xFFFF, 0x160B}, // Configure sequencer
   {224, 0xFFFF, 0x3E13}, // Configure sequencer
   {391, 0xFFFF, 0x1010}, // Configure sequencer
   {456, 0xFFFF, 0x0386}  // Configure sequencer
};

#define VITA_SPI_SEQ5_QTY  7
/* Table 9. soft power up register uploads for mode dependent registers */
static uint16_t vita_spi_seq5[VITA_SPI_SEQ5_QTY][3] = {
   // Soft Power-Up
   //    V1/SN/SE 10-bit mode with PLL
   { 32, 0xFFFF, 0x2007}, // Enable analog clock distribution
   { 10, 0xFFFF,      0}, // Release soft reset state
   { 64, 0xFFFF, 0x0001}, // Enable biasing block
   { 72, 0xFFFF, 0x0203}, // Enable charge pump
   { 40, 0xFFFF, 0x0003}, // Enable column multiplexer
   { 48, 0xFFFF, 0x0001}, // Enable AFE
   {112, 0xFFFF, 0x0007}  // Enable LVDS transmitters
};

//#define VITA_SPI_SEQ6_QTY  1
#define VITA_SPI_SEQ6_QTY  2
/* Table 10. enable sequencer register upload */
static uint16_t vita_spi_seq6[VITA_SPI_SEQ6_QTY][3] = {
// {192, 0x0001, 0x0001}  // [0] Enable Sequencer
#if defined(TRIGGERED_MASTER_MODE)
   {192, 0x0051, 0x0011}, // [0] Enable Sequencer
                          // [4] triggered_mode = on
                          // [6] xsm_delay_enable = off
   {193, 0xFF00,      0}  // [15:8] xsm_delay = 0x00
#elif defined(STRETCH_VITA_HTIMING)
   {192, 0x3841, 0x3841},
// {192, 0x0041, 0x0041}, // [0] Enable Sequencer
                          // [6] xsm_delay_enable = on
   {193, 0xFF00, 0x0400}  // [15:8] xsm_delay = 0x04
#else
   {192, 0x0001, 0x0001}, // [0] Enable Sequencer
                        // [6] xsm_delay_enable = off
   {193, 0xFF00,      0}  // [15:8] xsm_delay = 0x00
#endif
};

#define VITA_AUTOEXP_ON_QTY  1
static uint16_t vita_autoexp_on_seq[VITA_AUTOEXP_ON_QTY][3] = {
   // Auto-Exposure ON
   {160, 0x0001, 0x0001} // [4] Auto Exposure enable
   };

#define VITA_ROI0_CROP_1080P_QTY  2
static uint16_t vita_roi0_crop_1080p_seq[VITA_ROI0_CROP_1080P_QTY][3] = {
   // Crop ROI0 from 1920x1200 to 1920x1080
   //   R257[10:0] y_start = 60 (0x3C)
   //   R258[10:0] y_end   = 60+1080 = 1140 (0x474)
   {257, 0xFFFF, 0x003C},
   {258, 0xFFFF, 0x0474} };

#define VITA_MULT_TIMER_LINE_RESOLUTION_QTY  1
static uint16_t vita_mult_timer_line_resolution_seq[VITA_MULT_TIMER_LINE_RESOLUTION_QTY][3] = {
   // R199[15:0] mult_timer = (1920+88+44+148)/4 = 2200/4 = 550 (0x0226)
   //199, 0xFFFF, 0x0226
   // R199[15:0] mult_timer = (1920+88+44+132)/4 = 2184/4 = 546 (0x0222)
   {199, 0xFFFF, 0x0222} };

/************************ SPI ******************************/
static int spidevicefd;
static uint8_t spimode = 0;
static uint8_t spibits = 8;
static uint32_t speed = 50000;
static uint16_t delay = 100;
static uint16_t zynq_spi(uint32_t addr, uint32_t data)
{
    unsigned int ii;
    uint8_t tx[sizeof(uint32_t)], rx[sizeof(uint32_t)];
    uint32_t retval = 0;
    static struct spi_ioc_transfer tr;
    uint32_t command = addr << 23 | (data << 6);
//printf("[%s:%d] addr %x data %x command %x\n", __FUNCTION__, __LINE__, addr, data, command);

    for (ii = 0; ii < sizeof(uint32_t); ii++) {
        tx[3-ii] = command;
        command >>= 8;
    }
    tr.tx_buf = (unsigned long)tx;
    tr.rx_buf = (unsigned long)rx;
    tr.len = sizeof(tx);
    tr.delay_usecs = delay;
    tr.speed_hz = speed;
    tr.bits_per_word = spibits;
    if (ioctl(spidevicefd, SPI_IOC_MESSAGE(1), &tr) < 1)
        printf("can't send spi message\n");
    for (ii = 0; ii < sizeof(uint32_t); ii++)
        retval = retval << 8 | rx[ii];
    return (retval >> 5) & 0xffff;
}
static uint16_t vita_spi_read(uint32_t uAddr)
{
    return zynq_spi(uAddr, 0);
}
static int vita_spi_write(uint32_t uAddr, uint16_t uData)
{
    zynq_spi(uAddr, 0x10000 | uData);
    return 0;
}

/******************************************************************************
* This function performs a sequence of SPI write transactions.
******************************************************************************/
static void vita_spi_write_sequence(uint16_t pConfig[][3], uint32_t uLength)
{
   uint16_t uData;
   int i;

   for ( i = 0; i < (int)uLength; i++) {
      if ( pConfig[i][1] != 0xFFFF) {
         uData = vita_spi_read(pConfig[i][0]) & ~pConfig[i][1];
         printf( "\t                    0x%04X\n\r", pConfig[i][1]);
     }
   }
   for ( i = 0; i < (int)uLength; i++) {
      if ( pConfig[i][1] == 0xFFFF)
         uData = pConfig[i][2];
      else {
         uData = vita_spi_read(pConfig[i][0]) & ~pConfig[i][1];
         uData |=  pConfig[i][2];
      }
      vita_spi_write(pConfig[i][0], uData); usleep(100); // 100 usec
   }
}

static int fmc_imageon_vita_receiver_get_status(void)
{
   sleep(1);
   //vita_status_t2.cntBlackLines  = vita_reg_read(VITA_DECODER_CNT_BLACK_LINES_REG);
   //vita_status_t2.cntImageLines  = vita_reg_read(VITA_DECODER_CNT_IMAGE_LINES_REG);
   //vita_status_t2.cntBlackPixels = vita_reg_read(VITA_DECODER_CNT_BLACK_PIXELS_REG);
   //vita_status_t2.cntImagePixels = vita_reg_read(VITA_DECODER_CNT_IMAGE_PIXELS_REG);
   //vita_status_t2.cntFrames      = vita_reg_read(VITA_DECODER_CNT_FRAMES_REG);
   //vita_status_t2.cntWindows     = vita_reg_read(VITA_DECODER_CNT_WINDOWS_REG);
   //vita_status_t2.cntStartLines  = vita_reg_read(VITA_DECODER_CNT_START_LINES_REG);
   //vita_status_t2.cntEndLines    = vita_reg_read(VITA_DECODER_CNT_END_LINES_REG);
   //vita_status_t2.cntClocks      = vita_reg_read(VITA_DECODER_CNT_CLOCKS_REG);
   //vita_status_t2.crcStatus = read_crc_status();
   return 0;
}

static struct {
    const char *pName;
    uint32_t VActiveVideo;
    uint32_t VFrontPorch;
    uint32_t VSyncWidth;
    uint32_t VBackPorch;
    uint32_t VSyncPolarity;
    uint32_t HActiveVideo;
    uint32_t HFrontPorch;
    uint32_t HSyncWidth;
    uint32_t HBackPorch;
    uint32_t HSyncPolarity;
} vres = {
   "1080P", 1080,    4,    5,   36,    1, 1920,   88,   44,  148,    1 // VIDEO_RESOLUTION_1080P
};

static void fmc_imageon_demo_enable_ipipe( void)
{
   // VITA-2000 Initialization
   printf( "FMC-IMAGEON VITA Initialization ...\n\r");
   uint16_t uData;
   uint32_t uStatus;
   int timeout;
   uint32_t h_active    = 1920;
   uint32_t h_fporch    =   88;
   uint32_t h_syncwidth =   44;
 #if defined(STRETCH_VITA_HTIMING)
   uint32_t h_bporch    =  148;
 #else
   uint32_t h_bporch    =  132;
 #endif
   uint32_t h_syncpol   =    1;
   //v_active    = 1080;
   uint32_t v_active    = 1080+1;
   uint32_t v_fporch    =    4;
   uint32_t v_syncwidth =    5;
   //v_bporch    =   36;
   uint32_t v_bporch    =  300;
   uint32_t v_syncpol   =    1;
   // Horizontal settings
   device->set_syncgen_delay(((1920+88+44+148)>>2)*6); // approx. 6 lines of delay
   device->set_syncgen_hactive(h_active);
   device->set_syncgen_hfporch(h_fporch);
   device->set_syncgen_hsync((h_syncpol)<<15 | (h_syncwidth)<<0);
   device->set_syncgen_hbporch(h_bporch);
   // Vertical settings
   device->set_syncgen_vactive(v_active);
   device->set_syncgen_vfporch(v_fporch);
   device->set_syncgen_vsync ((v_syncpol)<<15 | (v_syncwidth)<<0);
   device->set_syncgen_vbporch(v_bporch);
   printf( "VITA ISERDES - Setting Training Sequence to 0x03A6\n\r");
   device->set_serdes_training(0x03A6);
   printf( "VITA ISERDES - Setting Manual Tap to 0x%08X\n\r", uManualTap);
   device->set_serdes_manual_tap(uManualTap);
   device->set_decoder_startoddeven(0);
   device->set_decoder_code_ls(0x00AA);
   device->set_decoder_code_le(0x012A);
   device->set_decoder_code_fs(0x02AA);
   device->set_decoder_code_fe(0x032A);
   device->set_decoder_code_bl(0x0015);
   device->set_decoder_code_img(0x0035);
   device->set_decoder_code_tr(0x03A6);
   device->set_decoder_code_crc(0x0059);

   printf( "VITA REMAPPER - Configuring for image lines in normal mode\n\r");
   device->set_remapper_control( 1);
   uint32_t uControl = read_remapper_control();
   printf( "VITA REMAPPER - Control = 0x%08X\n\r", uControl);
   device->set_iserdes_control( VITA_ISERDES_RESET_BIT);
   device->set_decoder_control( VITA_DECODER_RESET_BIT);
   device->set_crc_control( VITA_CRC_INITVALUE_BIT | VITA_CRC_RESET_BIT);

   usleep(10); // 10 usec
#if 0
   printf("VITA SPI Sequence 0 - Assert RESET_N pin\n\r");
   device->set_spi_control( VITA_VITA_RESET_BIT);
#endif
   usleep(10); // 10 usec
   printf( "VITA ISERDES - Releasing Reset\n\r");
   device->set_iserdes_control( 0);
   printf( "VITA DECODER - Releasing Reset\n\r");
   device->set_decoder_control( 0);
   printf( "VITA CRC - Releasing Reset\n\r");
   device->set_crc_control( VITA_CRC_INITVALUE_BIT);
   sleep(1); // 1 sec (time to get clocks to lock)
#if 0
   printf("VITA SPI Sequence 0 - Releasing RESET_N pin\n\r");
   device->set_spi_control( 0);
#endif
   usleep(20); // 20 usec
   uData = vita_spi_read(0);
printf("[%s:%d] %x\n", __FUNCTION__, __LINE__, uData);
   switch ( uData) {
   case 0:
       printf( "\tVITA Sensor absent\n\r");
       break;
   case 0x560D:
       printf( "\tVITA-1300 Sensor detected\n\r");
       break;
   case 0x5614:
       printf( "\tVITA-2000 Sensor detected\n\r");
       break;
   case 0x5632:
       printf( "\tVITA-5000 Sensor detected\n\r");
       break;
   case 0x56FA:
       printf( "\tVITA-25K Sensor detected\n\r");
       break;
   default:
       printf( "\tERROR: Unknown CHIP_ID !!!\n\r");
       break;
   }
   if ( uData != 0x5614) {
      printf( "\tERROR: Absent or unsupported VITA sensor !!!\n\r");
      return;
   }
   printf("VITA SPI Sequence 1 - Enable Clock Management - Part 1\n\r");
   vita_spi_write_sequence(vita_spi_seq1, VITA_SPI_SEQ1_QTY);
   {
   uint16_t uLock = 0;
   printf("VITA SPI Sequence 2 - Verify PLL Lock Indicator\n\r");
   timeout = 10;
   while ( !(uLock) && --timeout) {
      usleep(100000);
      uLock = vita_spi_read(24);
   }
   if ( !timeout) {
       printf( "\tERROR: Timed Out while waiting for PLL lock to assert !!!\n\r");
      return;
   }
   }
   printf("VITA SPI Sequence 3 - Enable Clock Management - Part 2\n\r");
   vita_spi_write_sequence(vita_spi_seq3, VITA_SPI_SEQ3_QTY);
   printf("VITA SPI Sequence 4 - Required Register Upload\n\r");
   vita_spi_write_sequence(vita_spi_seq4, VITA_SPI_SEQ4_QTY);
   printf("VITA SPI Sequence 5 - Soft Power-Up\n\r");
   vita_spi_write_sequence(vita_spi_seq5, VITA_SPI_SEQ5_QTY);
   uStatus = read_iserdes_control();
   printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
   uStatus = read_iserdes_control();
   printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
   uStatus = read_iserdes_control();
   printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
   timeout = 9;
   while ( !(uStatus & 0x0100) && --timeout) {
      uStatus = read_iserdes_control();
      printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
      usleep(1);
   }
   if ( !timeout) {
      printf( "\tTimed Out !!!\n\r");
      return;
   }
   printf( "VITA ISERDES - Align Start\n\r");
   device->set_iserdes_control( VITA_ISERDES_ALIGN_START_BIT);
   printf( "VITA ISERDES - Waiting for ALIGN_BUSY to assert\n\r");
   uStatus = read_iserdes_control();
   printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
   timeout = 9;
   while ( !(uStatus & 0x0200) && --timeout) {
      uStatus = read_iserdes_control();
      printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
      usleep(1);
   }
   if ( !timeout) {
      printf( "\tTimed Out !!!\n\r");
      return;
   }
   device->set_iserdes_control( 0);
   printf( "VITA ISERDES - Waiting for ALIGN_BUSY to de-assert\n\r");
   uStatus = read_iserdes_control();
   printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
   timeout = 9;
   while ( (uStatus & 0x0200) && --timeout) {
      uStatus = read_iserdes_control();
      printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
      usleep(1);
   }
   if ( !timeout)
      printf( "\tTimed Out !!!\n\r");
   uStatus = read_iserdes_control();
   printf( "VITA ISERDES - Status = 0x%08X\n\r", uStatus);
   printf("VITA SPI Sequence   - Crop ROI0 to 1920x1080\n\r");
   vita_spi_write_sequence(vita_roi0_crop_1080p_seq, VITA_ROI0_CROP_1080P_QTY);
   printf("VITA SPI Sequence   - Set mult_timer to line resolution\n\r");
   vita_spi_write_sequence(vita_mult_timer_line_resolution_seq, VITA_MULT_TIMER_LINE_RESOLUTION_QTY);
   printf("VITA SPI Sequence   - Set auto-exposure to ON\n\r");
   vita_spi_write_sequence(vita_autoexp_on_seq, VITA_AUTOEXP_ON_QTY);
   printf("VITA SPI Sequence 6 - Enable Sequencer\n\r");
   vita_spi_write_sequence(vita_spi_seq6, VITA_SPI_SEQ6_QTY);
   device->set_iserdes_control( VITA_ISERDES_FIFO_ENABLE_BIT);
   device->set_decoder_control(VITA_DECODER_ENABLE_BIT);
   uControl = read_decoder_control();
   printf( "VITA DECODER - Control = 0x%08X\n\r", uControl);
   uStatus = read_crc_status();
   printf( "VITA CRC - Status = 0x%08X\n\r", uStatus);
   usleep(100);
   uStatus = read_crc_status();
   printf( "VITA CRC - Status = 0x%08X\n\r", uStatus);
   sleep(1);
   printf( "VITA 1080P60 - Disable Sequencer\n\r");
   vita_spi_write(192, 0); usleep(100); // 100 usec
   printf( "VITA 1080P60 - Adjust line spacing in VITA\n\r");
   vita_spi_write(193, 0x0400); usleep(100); // 100 usec
   vita_spi_write(192, 0x0040); usleep(100); // 100 usec
   printf( "VITA 1080P60 - Tolerate 6 lines of jitter (required for programmable exposure)\n\r");
   device->set_syncgen_delay(0x0CE4);
   printf( "VITA 1080P60 - Adjust line spacing in sync generator\n\r");
   device->set_syncgen_hactive(0x0780);
   device->set_syncgen_hfporch(0x0058);
   device->set_syncgen_hsync(0x802C);
   device->set_syncgen_hbporch(0x0094);
   printf( "VITA 1080P60 - Adjust frame spacing in VITA\n\r");
   vita_spi_write(199, 0x0001); usleep(100); // 100 usec
   vita_spi_write(200, 0); usleep(100); // 100 usec
   vita_spi_write(194, 0); usleep(100); // 100 usec
   printf( "VITA 1080P60 - Adjust frame spacing in sync generator\n\r");
   device->set_syncgen_vactive (0x0438);
   device->set_syncgen_vfporch (0x0004);
   device->set_syncgen_vsync(0x8005);
   device->set_syncgen_vbporch(0x0024);
   printf( "VITA 1080P60 - Crop ROI0 from 1920x1200 to 1920x1080\n\r");
   vita_spi_write(257, 0x003C); usleep(100); // 100 usec
   vita_spi_write(258, 0x0474); usleep(100); // 100 usec

   printf( "VITA 1080P60 - Disable auto-exposure\n\r");
   vita_spi_write(160, 0x0010); usleep(100); // 100 usec

   printf( "VITA 1080P60 - Enable trig generator\n\r");
   uint32_t trigDutyCycle    = 90; // exposure time is 90% of frame time (ie. 15msec)
   uint32_t vitaTrigGenDefaultFreq = (((1920+88+44+148)*(1080+4+5+36))>>2) - 2;
   device->set_trigger_default_freq(vitaTrigGenDefaultFreq);
   device->set_trigger_cnt_trigger0high((vitaTrigGenDefaultFreq * (100-trigDutyCycle))/100); // negative polarity
   device->set_trigger_cnt_trigger0low(1);
   device->set_triggen_control(0x31000011); // invert trigger[2:0], internal trigger, enable trigger[0], update triggen_cnt registers
   device->set_triggen_control(0x30000011); // invert trigger[2:0], internal trigger, enable trigger[0]
   printf("VITA 1080P60 - Exposure related settings\n\r");
   vita_spi_write(194, 0x0400);
   vita_spi_write(0x29, 0x0700);
   uint16_t vspi_data = vita_spi_read(192) | 0x0071; usleep(100); // 100 usec
   vita_spi_write(192, vspi_data); usleep(100); // 100 usec
   fmc_imageon_vita_receiver_get_status();
   uint32_t lastframes = vita_status_t2.cntFrames;
   fmc_imageon_vita_receiver_get_status();
   printf("VITA Status = \n\r");
   printf("\tImage Width  = %d\n\r", vita_status_t2.cntImagePixels * 4);
   printf("\tImage Height = %d\n\r", vita_status_t2.cntImageLines);
   printf("\tFrame Rate   = %d frames/sec\n\r", vita_status_t2.cntFrames - lastframes);
   printf("Initializing iPipe cores ... done!\r\n");
   usleep(10000);
}

static void fmc_imageon_demo_init(int argc, const char **argv)
{
    int ret;
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    //ret = fmc_iic_axi_init(uBaseAddr_IIC_FmcImageon);
    //fmc_iic_axi_GpoWrite(uBaseAddr_IIC_FmcImageon, fmc_iic_axi_GpoRead(uBaseAddr_IIC_FmcImageon) | 2);
    device->set_host_oe(1);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);

    spidevicefd = open(SPIDEVICENAME, O_RDWR);
    if (spidevicefd < 0
     || ioctl(spidevicefd, SPI_IOC_WR_MODE, &spimode) == -1
     || ioctl(spidevicefd, SPI_IOC_RD_MODE, &spimode) == -1
     || ioctl(spidevicefd, SPI_IOC_WR_BITS_PER_WORD, &spibits) == -1
     || ioctl(spidevicefd, SPI_IOC_RD_BITS_PER_WORD, &spibits) == -1
     || ioctl(spidevicefd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1
     || ioctl(spidevicefd, SPI_IOC_RD_MAX_SPEED_HZ, &speed) == -1)
        printf("Error: cannot open SPI device\n");

    device->set_iic_reset(0);
    device->set_iic_reset(1);
    init_i2c_camera();
    init_i2c_hdmi();
    //init_vclk();

    // Reset DCMs
    /* puts the DCM_0 PCORE into reset */
    //fmc_iic_axi_GpoWrite(uBaseAddr_IIC_FmcImageon, fmc_iic_axi_GpoRead(uBaseAddr_IIC_FmcImageon) | 4);
    device->set_clock_gen_reset(1);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    usleep(200000);
    /* releases the DCM_0 PCORE from reset */
    //fmc_iic_axi_GpoWrite(uBaseAddr_IIC_FmcImageon, fmc_iic_axi_GpoRead(uBaseAddr_IIC_FmcImageon) & ~4);
    device->set_clock_gen_reset(0);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);

    usleep(500000);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
printf("[%s:%d] locked %ld\n", __FUNCTION__, __LINE__, read_clock_gen_locked());
    // FMC-IMAGEON VITA Receiver Initialization
    printf( "FMC-IMAGEON VITA Receiver Initialization ...\n\r");
    uManualTap = 25;
    device->set_spi_timing((100/10));
    fmc_imageon_demo_enable_ipipe();
}

static void *pthread_worker(void *ptr)
{
    portalExec(NULL);
    return NULL;
}

int main(int argc, const char **argv)
{
    pthread_t threaddata;
    init_local_semaphores();
    device = ImageCapture::createImageCapture("fpga0", new TestImageCaptureIndications);

    int rc = pthread_create(&threaddata, NULL, &pthread_worker, (void *)device);
    fmc_imageon_demo_init(argc, argv);
    usleep(200000);
    while (getchar() != EOF) {
device->set_debugreq(1);
device->get_debugind();
printf("[%s:%d] iserdes %lx\n", __FUNCTION__, __LINE__, read_iserdes_control());
printf("[%s:%d] decode %lx\n", __FUNCTION__, __LINE__, read_decoder_control());
printf("[%s:%d] crccontrol %lx\n", __FUNCTION__, __LINE__, read_crc_control());
printf("[%s:%d] crcstatus %lx\n", __FUNCTION__, __LINE__, read_crc_status());
printf("[%s:%d] remapper %lx\n", __FUNCTION__, __LINE__, read_remapper_control());
printf("[%s:%d] triggen %lx\n", __FUNCTION__, __LINE__, read_triggen_control());
static int regids[] = {24, 97, 186, 0};
int i;
for (i = 0; regids[i]; i++)
    printf("[%s:%d] spi %d. %x\n", __FUNCTION__, __LINE__, regids[i], vita_spi_read(regids[i]));
    }
return 0;
}
