============
Installation
============

Installing Connectal from Packages
-----------------------------------

On Ubuntu systems, connectal may be installed from pre-built packages:

    sudo add-apt-repository -y ppa:jamey-hicks/connectal
    sudo apt-get update
    sudo apt-get -y install connectal


Installing Connectal from Source
--------------------------------

Connectal source comes from three repositories:

    git clone git://github.com/cambridgehackers/connectal
    git clone git://github.com/cambridgehackers/fpgamake
    git clone git://github.com/cambridgehackers/buildcache

To use Connectal to build hardware/software applications, some additional packages are required:

    cd connectal; sudo make install-dependences

Installing Connectal Drivers and PCI Express Utilities:
-------------------------------------------------------

To run Connectal applications on FPGAs attached via PCI Express, a
couple of device drivers have to be built and installed:

   cd connectal; make all && sudo make install

In addition, you will need to build and install fpgajtag and pciescan:

    git clone git://github.com/cambridgehackers/pciescan
    (cd pciescan; make && sudo make install)
    
    git clone git://github.com/cambridgehackers/fpgajtag
    (cd fpgajtag; make && sudo make install)


Installing Vivado
-----------------
    
Download Vivado from Xilinx

    http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2015-4.html

Connectal builds do not use the Vivado SDK.


