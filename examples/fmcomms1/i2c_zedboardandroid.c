/**************************************************************************//**
*   @file   i2c_zedboardandroid.c
*   @brief  ZYNQ Hardware I2C functions implementation.
*
*******************************************************************************
* API copied from i2c_ps7.c
* Copyright 2011(c) Analog Devices, Inc.
*/

#include "/usr/include/linux/i2c.h"
#include "/usr/include/linux/i2c-dev.h"
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <errno.h>

static int fd;

void dump_i2c_msg(struct i2c_msg *msg)
{
  int i;
  fprintf(stdout, "  addr 0x%02x flags[", msg->addr);
  if (msg->flags & I2C_M_RD) fprintf(stdout, " RD");
  else fprintf(stdout, " WR");
  if (msg->flags & I2C_M_RECV_LEN) fprintf(stdout, " RDLEN");
  else fprintf(stdout, "      ");
  fprintf(stdout, " ] len %d ", msg->len);
  if ((msg->flags & I2C_M_RD) == 0) {
    fprintf(stdout, " [");
    for (i = 0; i < msg->len; i += 1)
      fprintf(stdout, " %02x", msg->buf[i]);
    fprintf(stdout, " ]\n");
  } else {
    fprintf(stdout, "\n");
  }
}

void dump_i2c_rdwr(struct i2c_rdwr_ioctl_data *arg)
{
  int i;
  fprintf(stdout, "i2c_rdwr[%d]\n", arg->nmsgs);
  for (i = 0; i < arg->nmsgs; i += 1)
    dump_i2c_msg(&arg->msgs[i]);
}

/**************************************************************************//**
* @brief Initializes the I2C communication multiplexer.
*
* @param sel - Multiplexer selection value.
*
* @return Returns 0 or negative error code.
******************************************************************************/
uint32_t I2C_Init(char * devfile, uint32_t i2cAddr)
{
	uint32_t ret = 0;
	fprintf(stdout, "opening %s\n", devfile);
	fd = open(devfile, O_RDWR);
	if (fd < 0) {
	  fprintf(stdout, "can't open device %s: %s [%d]", devfile, strerror(errno), errno);
	}
	

	return ret;
}

/**************************************************************************//**
* @brief Writes data to an I2C slave.
*
* @param i2cAddr - The address of the I2C slave.
* @param regAddr - Address of the I2C register to be read.
*				   Must be set to -1 if it is not used.
* @param txSize - Number of bytes to write to the slave.
* @param txBuf - Buffer to store the data to be transmitted.
*
* @return Returns the number of bytes written.
******************************************************************************/
uint32_t I2C_Write(uint32_t i2cAddr, uint32_t regAddr, 
                       uint32_t txSize, uint8_t* txBuf)
{
  int status, i;
  unsigned char buf[128];
  struct i2c_msg msgs[1];
  struct i2c_rdwr_ioctl_data arg;
  msgs[0].addr = i2cAddr;
  msgs[0].flags = 0;
  msgs[0].buf = buf;
  arg.msgs = msgs;
  arg.nmsgs = 1;
  if (txSize > 127) return -1;
  if (regAddr != 0xffffffff) {
    buf[0] = regAddr;
    memcpy(&buf[1], txBuf, txSize);
    msgs[0].len = txSize + 1;
  } else {
    memcpy(&buf[0], txBuf, txSize);
    msgs[0].len = txSize;
  }
  fprintf(stdout, "I2C_Write(0x%02x, 0x%02x, %d, [", i2cAddr, regAddr, txSize);
  for (i = 0 ; i < msgs[0].len; i += 1)
    fprintf(stdout, " %02x", buf[i]);
  fprintf(stdout, " ])\n");
  dump_i2c_rdwr(&arg);
  status = ioctl(fd, I2C_RDWR, &arg);
  if (status != 0) {
    fprintf(stdout, "[%s:%d]: ioctl I2C_RW 1 status=%d errno=%d [%s]\n", __FILE__, __LINE__, status, errno, strerror(errno));
  }
  fprintf(stdout, "returns %d\n", txSize);
  return txSize;
}

/**************************************************************************//**
* @brief Reads data from an I2C slave.
*
* @param i2cAddr - The address of the I2C slave.
* @param regAddr - Address of the I2C register to be read.
*				   Must be set to -1 if it is not used.
* @param rxSize - Number of bytes to read from the slave.
* @param rxBuf - Buffer to store the read data.
*
* @return Returns the number of bytes read.
******************************************************************************/
uint32_t I2C_Read(uint32_t i2cAddr, uint32_t regAddr, 
                      uint32_t rxSize, uint8_t* rxBuf)
{
  int status, i;
  unsigned char buf[128];
  struct i2c_msg msgs[1];
  struct i2c_rdwr_ioctl_data arg;
  msgs[0].addr = i2cAddr;
  msgs[0].flags = I2C_M_RD | I2C_M_RECV_LEN;
  msgs[0].len = rxSize;
  msgs[0].buf = buf;
  arg.msgs = msgs;
  arg.nmsgs = 1;
  buf[0] = 1;
  if (regAddr != 0xffffffff) I2C_Write(i2cAddr, regAddr, 0, NULL);
  fprintf(stdout, "I2C_Read(0x%02x, 0x%02x, %d)\n", i2cAddr, regAddr, rxSize);
  dump_i2c_rdwr(&arg);
  status = ioctl(fd, I2C_RDWR, &arg);
  if (status != 0) {
    fprintf(stdout, "[%s, %d]: ioctl I2C_RW status=%d errno=%d [%s]\n", __FILE__, __LINE__, status, errno, strerror(errno));
  }
  if (buf[0] > rxSize) buf[0] = rxSize;
  memcpy(rxBuf, &buf[1], buf[0]);
  fprintf(stdout, "  returns %d [", buf[0]);
  for (i = 0 ; i <= buf[0]; i += 1)
    fprintf(stdout, " %02x", buf[i]);
  fprintf(stdout, " ]\n");
  return buf[0];

}

