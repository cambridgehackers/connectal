
#include <linux/types.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include "/usr/include/linux/i2c.h"
#include "/usr/include/linux/i2c-dev.h"
static void i2c_write_array(int fd, int device, unsigned char *datap, int size)
{
    struct i2c_smbus_ioctl_data args;
    union i2c_smbus_data ioctl_data;
    args.read_write = I2C_SMBUS_WRITE;
    args.size = I2C_SMBUS_BYTE_DATA;
    args.data = &ioctl_data;

    int status = ioctl(fd, I2C_SLAVE, device);
    if (status != 0)
	 fprintf(stderr, "ioctl I2C_SLAVE status=%d errno=%d\n", status, errno);
    while (size) {
        args.command = *datap++;
        ioctl_data.byte = *datap++;
        status = ioctl(fd, I2C_SMBUS, &args);
	if (status != 0)
	     fprintf(stderr, "ioctl I2C_SLAVE status=%d errno=%d\n", status, errno);
        size -= 2;
    }
}
static unsigned char i2c_read_reg(int fd, int device, unsigned char reg)
{
    struct i2c_smbus_ioctl_data args;
    union i2c_smbus_data ioctl_data;
    args.read_write = I2C_SMBUS_READ;
    args.size = I2C_SMBUS_BYTE_DATA;
    args.data = &ioctl_data;

    int status = ioctl(fd, I2C_SLAVE, device);
    if (status != 0)
	 fprintf(stderr, "ioctl I2C_SLAVE status=%d errno=%d\n", status, errno);

    args.command = reg;
    ioctl_data.byte = 0;
    status = ioctl(fd, I2C_SMBUS, &args);
    if (status != 0)
      fprintf(stderr, "ioctl I2C_SLAVE status=%d errno=%d\n", status, errno);
    fprintf(stderr, "reg=%x byte=%x\n", reg, ioctl_data.byte);
    return ioctl_data.byte;
}
static int i2c_open()
{
  return open("/dev/i2c-0", O_RDWR);
}
static void init_i2c_hdmi(void)
{
static unsigned char muxdata[] = {2, 2};
static unsigned char hdmidata[] = {
    0x41, 0x10,  0xD6, 0xC0,  0x15, 0x01,  0x16, 0x38,
    0x18, 0xAB,  0x19, 0x37,  0x1A, 0x08,  0x1B, 0x00,
    0x1C, 0x00,  0x1D, 0x00,  0x1E, 0x1A,  0x1F, 0x86,
    0x20, 0x1A,  0x21, 0x49,  0x22, 0x08,  0x23, 0x00,
    0x24, 0x1D,  0x25, 0x3F,  0x26, 0x04,  0x27, 0x22,
    0x28, 0x00,  0x29, 0x00,  0x2A, 0x08,  0x2B, 0x00,
    0x2C, 0x0E,  0x2D, 0x2D,  0x2E, 0x19,  0x2F, 0x14,
    0x48, 0x08,  0x55, 0x00,  0x56, 0x28,  0x98, 0x03,
    0x9A, 0xE0,  0x9C, 0x30,  0x9D, 0x61,  0xA2, 0xA4,
    0xA3, 0xA4,  0xAF, 0x04,  0xE0, 0xD0,  0xF9, 0x00};

    int fd = open("/dev/i2c-0", O_RDWR);
    //set mux for hdmi
    i2c_write_array(fd, 0x74, muxdata, sizeof(muxdata));
    //set hdmi data
    i2c_write_array(fd, 0x39, hdmidata, sizeof(hdmidata));
}
static void init_i2c_hdmi_rgb24(void)
{
static unsigned char muxdata[] = {2, 2};
static unsigned char hdmidata[] = {
    0x41, 0x10,  0xD6, 0xC0,  0x15, 0x00,  0x16, 0x38,
    0x18, 0xAB,  0x19, 0x37,  0x1A, 0x08,  0x1B, 0x00,
    0x1C, 0x00,  0x1D, 0x00,  0x1E, 0x1A,  0x1F, 0x86,
    0x20, 0x1A,  0x21, 0x49,  0x22, 0x08,  0x23, 0x00,
    0x24, 0x1D,  0x25, 0x3F,  0x26, 0x04,  0x27, 0x22,
    0x28, 0x00,  0x29, 0x00,  0x2A, 0x08,  0x2B, 0x00,
    0x2C, 0x0E,  0x2D, 0x2D,  0x2E, 0x19,  0x2F, 0x14,
    0x48, 0x08,  0x55, 0x00,  0x56, 0x28,  0x98, 0x03,
    0x9A, 0xE0,  0x9C, 0x30,  0x9D, 0x61,  0xA2, 0xA4,
    0xA3, 0xA4,  0xAF, 0x04,  0xE0, 0xD0,  0xF9, 0x00};

    int fd = open("/dev/i2c-0", O_RDWR);
    //set mux for hdmi
    i2c_write_array(fd, 0x74, muxdata, sizeof(muxdata));
    //set hdmi data
    i2c_write_array(fd, 0x39, hdmidata, sizeof(hdmidata));
}
