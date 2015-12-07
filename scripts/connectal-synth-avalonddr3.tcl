# Copyright (c) 2015 Connectal Project
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

proc create_altera_de5_ddr3 {} {
    set core_name {altera_mem_if_ddr3_emif}
    set core_version {14.0}
    set ip_name {altera_mem_if_ddr3_emif_wrapper}

	set params [ dict create ]

    dict set params MEM_VENDOR                          "JEDEC"
    dict set params MEM_FORMAT                          "UNBUFFERED"
    dict set params RDIMM_CONFIG                        0
    dict set params LRDIMM_EXTENDED_CONFIG              "0x000000000000000000"
    dict set params DISCRETE_FLY_BY                     "true"
    dict set params DEVICE_DEPTH                        1
    dict set params MEM_MIRROR_ADDRESSING               0
    dict set params MEM_CLK_FREQ_MAX                    "800.0"
    dict set params MEM_ROW_ADDR_WIDTH                  15
    dict set params MEM_COL_ADDR_WIDTH                  10
    dict set params MEM_DQ_WIDTH                        64
    dict set params MEM_DQ_PER_DQS                      8
    dict set params MEM_BANKADDR_WIDTH                  3
    dict set params MEM_IF_DM_PINS_EN                   "true"
    dict set params MEM_IF_DQSN_EN                      "true"
    dict set params MEM_NUMBER_OF_DIMMS                 1
    dict set params MEM_NUMBER_OF_RANKS_PER_DIMM        1
    dict set params MEM_NUMBER_OF_RANKS_PER_DEVICE      1
    dict set params MEM_RANK_MULTIPLICATION_FACTOR      1
    dict set params MEM_CK_WIDTH                        1
    dict set params MEM_CS_WIDTH                        1
    dict set params MEM_CLK_EN_WIDTH                    1
    dict set params ALTMEMPHY_COMPATIBLE_MODE           "false"
    dict set params NEXTGEN                             "true"
    dict set params MEM_IF_BOARD_BASE_DELAY             10
    dict set params MEM_IF_SIM_VALID_WINDOW             0
    dict set params MEM_GUARANTEED_WRITE_INIT           "false"
    dict set params MEM_VERBOSE                         "true"
    dict set params PINGPONGPHY_EN                      "false"
    dict set params REFRESH_BURST_VALIDATION            "false"
    dict set params MEM_BL                              "OTF"
    dict set params MEM_BT                              "Sequential"
    dict set params MEM_ASR                             "Manual"
    dict set params MEM_SRT                             "Normal"
    dict set params MEM_PD                              "DLL off"
    dict set params MEM_DRV_STR                         "RZQ/7"
    dict set params MEM_DLL_EN                          "true"
    dict set params MEM_RTT_NOM                         "RZQ/6"
    dict set params MEM_RTT_WR                          "RZQ/4"
    dict set params MEM_WTCL                            8
    dict set params MEM_ATCL                            "Disabled"
    dict set params MEM_TCL                             11
    dict set params MEM_AUTO_LEVELING_MODE              "true"
    dict set params MEM_USER_LEVELING_MODE              "Leveling"
    dict set params MEM_INIT_EN                         "false"
    dict set params DAT_DATA_WIDTH                      32
    dict set params TIMING_TIS                          170
    dict set params TIMING_TIH                          120
    dict set params TIMING_TDS                          10
    dict set params TIMING_TDH                          45
    dict set params TIMING_TDQSQ                        100
    dict set params TIMING_TQH                          "0.38"
    dict set params TIMING_TDQSCK                       225
    dict set params TIMING_TDQSCKDS                     450
    dict set params TIMING_TDQSCKDM                     900
    dict set params TIMING_TDQSCKDL                     1200
    dict set params TIMING_TDQSS                        "0.25"
    dict set params TIMING_TQSH                         "0.4"
    dict set params TIMING_TDSH                         "0.18"
    dict set params TIMING_TDSS                         "0.18"
    dict set params MEM_TINIT_US                        500
    dict set params MEM_TMRD_CK                         4
    dict set params MEM_TRAS_NS                         "35.0"
    dict set params MEM_TRCD_NS                         "13.75"
    dict set params MEM_TRP_NS                          "13.75"
    dict set params MEM_TREFI_US                        "7.8"
    dict set params MEM_TRFC_NS                         "160.0"
    dict set params CFG_TCCD_NS                         "2.5"
    dict set params MEM_TWR_NS                          "15.0"
    dict set params MEM_TWTR                            "6"
    dict set params MEM_TFAW_NS                         "30.0"
    dict set params MEM_TRRD_NS                         "6.0"
    dict set params MEM_TRTP_NS                         "7.5"
    dict set params RATE                                "Quarter"
    dict set params MEM_CLK_FREQ                        "800.0"
    dict set params USE_MEM_CLK_FREQ                    "false"
    dict set params SYS_INFO_DEVICE_FAMILY              "Stratix V"
    dict set params SPEED_GRADE                         2
    dict set params PACKAGE_DESKEW                      "true"
    dict set params AC_PACKAGE_DESKEW                   "true"
    dict set params TIMING_BOARD_MAX_CK_DELAY           "1.33"
    dict set params TIMING_BOARD_MAX_DQS_DELAY          "0.61"
    dict set params TIMING_BOARD_SKEW_CKDQS_DIMM_MIN    "0.0"
    dict set params TIMING_BOARD_SKEW_CKDQS_DIMM_MAX    "0.0"
    dict set params TIMING_BOARD_SKEW_BETWEEN_DIMMS     "0.05"
    dict set params TIMING_BOARD_SKEW_WITHIN_DQS        "0.0070"
    dict set params TIMING_BOARD_SKEW_BETWEEN_DQS       "0.09"
    dict set params TIMING_BOARD_DQ_TO_DQS_SKEW         "0.0020"
    dict set params TIMING_BOARD_AC_SKEW                "0.05"
    dict set params TIMING_BOARD_AC_TO_CK_SKEW          "0.012"
    dict set params REF_CLK_FREQ                        "50.0"
    dict set params REF_CLK_FREQ_PARAM_VALID            "false"
    dict set params REF_CLK_FREQ_MIN_PARAM              "0.0"
    dict set params REF_CLK_FREQ_MAX_PARAM              "0.0"
    dict set params PHY_ONLY                            "false"

#    dict set params PLL_SHARING_MODE                    "Master"
#    dict set params NUM_PLL_SHARING_INTERFACES          "1"
#    dict set params DLL_SHARING_MODE                    "Master"
#    dict set params NUM_DLL_SHARING_INTERFACES          "1"
#    dict set params OCT_SHARING_MODE                    "Master"
#    dict set params NUM_OCT_SHARING_INTERFACES          "1"

    set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}

    connectal_altera_synth_ip $core_name $core_version $ip_name $component_parameters
}

create_altera_de5_ddr3
