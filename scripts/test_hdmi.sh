#/bin/bash

echo "hdmidisplay_axi_master_interconnect_0_wrapper
    hdmidisplay_axi_slave_interconnect_0_wrapper
    hdmidisplay_axi_slave_interconnect_1_wrapper
    hdmidisplay_hdmidisplay_0_wrapper
    hdmidisplay_processing_system7_0_wrapper
    hdmidisplay" | while read name ; do
        ./run_xst.sh $name
done
