sdcard_spi example
------------------

This example uses SPI mode on an SD card to read the first block of data.
This example was initially designed for the kc705g2 FPGA platform using an
8 GB SDHC card. Due to differences in initialization, this will not work on
older, smaller SD cards, and it may not work on larger, newer SD* cards.

The mkSPIMaster module in SPI.bsv has not been well tested. Currently this
example is the only time it has been used. You may find bugs if you try to
use it in a different situation (especially if SPI mode isn't 0).

