
## How to trace AXI bus transactions on the Zynq platform.

### Preparation

1. Connect a usb cable to either a linux box or Mac

2. Install openocd
      Linux: sudo apt-get install openocd

      Mac using 'port': 

          sudo port install libftdi

          sudo port install openocd

      Mac using 'brew': 

	  brew install libftdi

	  brew install openocd --enable-ft2232_libftdi

      On Mac, if you get the message: 'unable to claim usb device. Make sure the default FTDI driver is not in use':

          Please read: http://pylibftdi.readthedocs.org/en/latest/troubleshooting.html

          Summarized here:

              OS X Mavericks

              OS X Mavericks includes kernel drivers which will reserve the FTDI device by default. This needs unloading before libftdi will be able to communicate with the device:

              sudo kextunload -bundle-id com.apple.driver.AppleUSBFTDI

              Similarly to reload it:

              sudo kextload -bundle-id com.apple.driver.AppleUSBFTDI

              OS X Mountain Lion and earlier

              Whereas Mavericks includes an FTDI driver directly, earlier versions of OS X did not, and if this issue occurred it would typically as a result of installing some other program - for example the Arduino IDE.

              As a result, the kernel module may have different names, but FTDIUSBSerialDriver.kext is the usual culprit. Unload the kernel driver as follows:

              sudo kextunload /System/Library/Extensions/FTDIUSBSerialDriver.kext


### Compile time

In the project makefile, add the line:
     CONNECTALFLAGS=--bscflags " -D TRACE_AXI"

For getting timestamps inserted in read request data, also specify the conditional compile flag AXI_READ_TIMING.

This will compile ConnectableWithTrace to trace transactions into BRAM.

### After running the test:

1. run the script connectal/jtag/run_trace.sh.

2. the trace output will be in the file trace.log.
