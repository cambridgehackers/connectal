/**************************************************************************//**
*   @file   i2c_zedboardandroid.h
*   @brief  ZYNQ Hardware I2C header file.
*
*******************************************************************************
* API copied from i2c_ps7.h
* Copyright 2011(c) Analog Devices, Inc.
*/

#include <stdint.h>

uint32_t I2C_Init(const char * devfile, uint32_t i2cAddr);

uint32_t I2C_Read(uint32_t i2cAddr, uint32_t regAddr, uint32_t rxSize, uint8_t* rxBuf);

uint32_t I2C_Write(uint32_t i2cAddr, uint32_t regAddr, uint32_t txSize, uint8_t* txBuf);

