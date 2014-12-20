#
#
set -x
set -e
./importbvi.py -o PCIEWRAPPER.bsv -I PcieWrap -P PcieWrap \
    -r pin_perst -r npor -r reset_status \
    -c pld_clk -c refclk -c coreclkout_hip \
    -n serdes_pll_locked -n pld_core_ready -n pld_clk_inuse -n dlup -n dlup_exit -n ev128ns -n ev1us -n hotrst_exit -n l2_exit -n currentspeed -n ltssmstate \
    -n derr_cor_ext_rcv -n derr_cor_ext_rpl -n derr_rpl \
    -f app \
    -n int_status -f aer_msi_num -f pex_msi_num -f serr_out \
    -f cpl_err -f cpl_pending -f cpl_err_func \
    -f tl \
    -f lmi \
    -n pm \
    -f tx_st -f rx_st \
    -f rx -f tx \
    -n txdata -n txdatak -n txdetectrx -n txelecidle -n txcompl -n tx_cred -n txdeemph -n txmargin -n txswing  \
    -n rxpolarity -n powerdown -n rxdata -n rxvalid -n rxdatak -n rxelecidle -n rxstatus \
    -n eidleinfersel -n powerdown -n phystatus \
    -n sim_pipe_pclk_in -n sim_pipe_rate -n sim_ltssmstate -n simu_mode_pipe \
    -n test_in -n simu_mode_pipe -n lane_act -n testin_zero \
    ../../out/de5/synthesis/altera_pcie_sv_hip_ast.v

    #-f rxdata -f rxpolarity -f rx_in -f rxdatak -f rxelecidle -f rxstatus -f rxvalid \
    #-f txdata -f tx_cred -f tx_out -f txcompl -f txdatak -f txdetectrx -f txelecidle -f txdeemph -f txmargin -f txswing \
