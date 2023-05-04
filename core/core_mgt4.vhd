-- core_mgt4.vhd
-- wrapper for Xilinx IP generated MGT

library ieee;
use ieee.std_logic_1164.all;

entity core_mgt4 is
port(
    sysclk_in: in std_logic; -- system clock 100MHz
    soft_reset_tx_in: in std_logic; 

    q0_clk0_gtrefclk_pad_p_in: in std_logic;
    q0_clk0_gtrefclk_pad_n_in: in std_logic;

    gt0_txdata_in: in std_logic_vector(31 downto 0);
    gt1_txdata_in: in std_logic_vector(31 downto 0);
    gt2_txdata_in: in std_logic_vector(31 downto 0);
    gt3_txdata_in: in std_logic_vector(31 downto 0);

    gt0_txcharisk_in: in std_logic_vector(3 downto 0);
    gt1_txcharisk_in: in std_logic_vector(3 downto 0);
    gt2_txcharisk_in: in std_logic_vector(3 downto 0);
    gt3_txcharisk_in: in std_logic_vector(3 downto 0);

    gt0_txusrclk2_out: out std_logic;
    gt1_txusrclk2_out: out std_logic;
    gt2_txusrclk2_out: out std_logic;
    gt3_txusrclk2_out: out std_logic;
   
    gt0_gtptxp_out, gt0_gtptxn_out: out std_logic;
    gt1_gtptxp_out, gt1_gtptxn_out: out std_logic;
    gt2_gtptxp_out, gt2_gtptxn_out: out std_logic;
    gt3_gtptxp_out, gt3_gtptxn_out: out std_logic

);
end core_mgt4;

architecture core_mgt4_arch of core_mgt4 is

    component daphne2_daq_txonly
    port
    (
        SOFT_RESET_TX_IN                        : in   std_logic;
        DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
        Q0_CLK0_GTREFCLK_PAD_N_IN               : in   std_logic;
        Q0_CLK0_GTREFCLK_PAD_P_IN               : in   std_logic;
    
        GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT0_DATA_VALID_IN                       : in   std_logic;
        GT0_TX_MMCM_LOCK_OUT                    : out  std_logic;
        GT1_TX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT1_RX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT1_DATA_VALID_IN                       : in   std_logic;
        GT1_TX_MMCM_LOCK_OUT                    : out  std_logic;
        GT2_TX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT2_RX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT2_DATA_VALID_IN                       : in   std_logic;
        GT2_TX_MMCM_LOCK_OUT                    : out  std_logic;
        GT3_TX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT3_RX_FSM_RESET_DONE_OUT               : out  std_logic;
        GT3_DATA_VALID_IN                       : in   std_logic;
        GT3_TX_MMCM_LOCK_OUT                    : out  std_logic;
     
        GT0_TXUSRCLK_OUT                        : out  std_logic;
        GT0_TXUSRCLK2_OUT                       : out  std_logic;
     
        GT1_TXUSRCLK_OUT                        : out  std_logic;
        GT1_TXUSRCLK2_OUT                       : out  std_logic;
     
        GT2_TXUSRCLK_OUT                        : out  std_logic;
        GT2_TXUSRCLK2_OUT                       : out  std_logic;
     
        GT3_TXUSRCLK_OUT                        : out  std_logic;
        GT3_TXUSRCLK2_OUT                       : out  std_logic;
    
        --_________________________________________________________________________
        --GT0  (X0Y0)
        --____________________________CHANNEL PORTS________________________________
        ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
        gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
        gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
        gt0_drpen_in                            : in   std_logic;
        gt0_drprdy_out                          : out  std_logic;
        gt0_drpwe_in                            : in   std_logic;
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in                     : in   std_logic;
        -------------------------- RX Margin Analysis Ports ------------------------
        gt0_eyescandataerror_out                : out  std_logic;
        gt0_eyescantrigger_in                   : in   std_logic;
        ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        gt0_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in                        : in   std_logic;
        gt0_rxlpmreset_in                       : in   std_logic;
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in                        : in   std_logic;
        gt0_txuserrdy_in                        : in   std_logic;
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt0_txdata_in                           : in   std_logic_vector(31 downto 0);
        ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
        gt0_txcharisk_in                        : in   std_logic_vector(3 downto 0);
        --------------- Transmit Ports - TX Configurable Driver Ports --------------
        gt0_gtptxn_out                          : out  std_logic;
        gt0_gtptxp_out                          : out  std_logic;
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt0_txoutclkfabric_out                  : out  std_logic;
        gt0_txoutclkpcs_out                     : out  std_logic;
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt0_txresetdone_out                     : out  std_logic;
    
        --GT1  (X0Y1)
        --____________________________CHANNEL PORTS________________________________
        ---------------------------- Channel - DRP Ports  --------------------------
        gt1_drpaddr_in                          : in   std_logic_vector(8 downto 0);
        gt1_drpdi_in                            : in   std_logic_vector(15 downto 0);
        gt1_drpdo_out                           : out  std_logic_vector(15 downto 0);
        gt1_drpen_in                            : in   std_logic;
        gt1_drprdy_out                          : out  std_logic;
        gt1_drpwe_in                            : in   std_logic;
        --------------------- RX Initialization and Reset Ports --------------------
        gt1_eyescanreset_in                     : in   std_logic;
        -------------------------- RX Margin Analysis Ports ------------------------
        gt1_eyescandataerror_out                : out  std_logic;
        gt1_eyescantrigger_in                   : in   std_logic;
        ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        gt1_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt1_gtrxreset_in                        : in   std_logic;
        gt1_rxlpmreset_in                       : in   std_logic;
        --------------------- TX Initialization and Reset Ports --------------------
        gt1_gttxreset_in                        : in   std_logic;
        gt1_txuserrdy_in                        : in   std_logic;
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt1_txdata_in                           : in   std_logic_vector(31 downto 0);
        ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
        gt1_txcharisk_in                        : in   std_logic_vector(3 downto 0);
        --------------- Transmit Ports - TX Configurable Driver Ports --------------
        gt1_gtptxn_out                          : out  std_logic;
        gt1_gtptxp_out                          : out  std_logic;
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt1_txoutclkfabric_out                  : out  std_logic;
        gt1_txoutclkpcs_out                     : out  std_logic;
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt1_txresetdone_out                     : out  std_logic;
    
        --GT2  (X0Y2)
        --____________________________CHANNEL PORTS________________________________
        ---------------------------- Channel - DRP Ports  --------------------------
        gt2_drpaddr_in                          : in   std_logic_vector(8 downto 0);
        gt2_drpdi_in                            : in   std_logic_vector(15 downto 0);
        gt2_drpdo_out                           : out  std_logic_vector(15 downto 0);
        gt2_drpen_in                            : in   std_logic;
        gt2_drprdy_out                          : out  std_logic;
        gt2_drpwe_in                            : in   std_logic;
        --------------------- RX Initialization and Reset Ports --------------------
        gt2_eyescanreset_in                     : in   std_logic;
        -------------------------- RX Margin Analysis Ports ------------------------
        gt2_eyescandataerror_out                : out  std_logic;
        gt2_eyescantrigger_in                   : in   std_logic;
        ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        gt2_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt2_gtrxreset_in                        : in   std_logic;
        gt2_rxlpmreset_in                       : in   std_logic;
        --------------------- TX Initialization and Reset Ports --------------------
        gt2_gttxreset_in                        : in   std_logic;
        gt2_txuserrdy_in                        : in   std_logic;
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt2_txdata_in                           : in   std_logic_vector(31 downto 0);
        ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
        gt2_txcharisk_in                        : in   std_logic_vector(3 downto 0);
        --------------- Transmit Ports - TX Configurable Driver Ports --------------
        gt2_gtptxn_out                          : out  std_logic;
        gt2_gtptxp_out                          : out  std_logic;
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt2_txoutclkfabric_out                  : out  std_logic;
        gt2_txoutclkpcs_out                     : out  std_logic;
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt2_txresetdone_out                     : out  std_logic;
    
        --GT3  (X0Y3)
        --____________________________CHANNEL PORTS________________________________
        ---------------------------- Channel - DRP Ports  --------------------------
        gt3_drpaddr_in                          : in   std_logic_vector(8 downto 0);
        gt3_drpdi_in                            : in   std_logic_vector(15 downto 0);
        gt3_drpdo_out                           : out  std_logic_vector(15 downto 0);
        gt3_drpen_in                            : in   std_logic;
        gt3_drprdy_out                          : out  std_logic;
        gt3_drpwe_in                            : in   std_logic;
        --------------------- RX Initialization and Reset Ports --------------------
        gt3_eyescanreset_in                     : in   std_logic;
        -------------------------- RX Margin Analysis Ports ------------------------
        gt3_eyescandataerror_out                : out  std_logic;
        gt3_eyescantrigger_in                   : in   std_logic;
        ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        gt3_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt3_gtrxreset_in                        : in   std_logic;
        gt3_rxlpmreset_in                       : in   std_logic;
        --------------------- TX Initialization and Reset Ports --------------------
        gt3_gttxreset_in                        : in   std_logic;
        gt3_txuserrdy_in                        : in   std_logic;
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt3_txdata_in                           : in   std_logic_vector(31 downto 0);
        ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
        gt3_txcharisk_in                        : in   std_logic_vector(3 downto 0);
        --------------- Transmit Ports - TX Configurable Driver Ports --------------
        gt3_gtptxn_out                          : out  std_logic;
        gt3_gtptxp_out                          : out  std_logic;
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt3_txoutclkfabric_out                  : out  std_logic;
        gt3_txoutclkpcs_out                     : out  std_logic;
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt3_txresetdone_out                     : out  std_logic;
    
        GT0_DRPADDR_COMMON_IN                   : in   std_logic_vector(7 downto 0);
        GT0_DRPDI_COMMON_IN                     : in   std_logic_vector(15 downto 0);
        GT0_DRPDO_COMMON_OUT                    : out  std_logic_vector(15 downto 0);
        GT0_DRPEN_COMMON_IN                     : in   std_logic;
        GT0_DRPRDY_COMMON_OUT                   : out  std_logic;
        GT0_DRPWE_COMMON_IN                     : in   std_logic;
        --____________________________COMMON PORTS________________________________
        GT0_PLL0OUTCLK_OUT  : out std_logic;
        GT0_PLL0OUTREFCLK_OUT  : out std_logic;
        GT0_PLL0LOCK_OUT  : out std_logic;
        GT0_PLL0REFCLKLOST_OUT  : out std_logic;    
        GT0_PLL1OUTCLK_OUT  : out std_logic;
        GT0_PLL1OUTREFCLK_OUT  : out std_logic;
        sysclk_in : in std_logic);
    end component;

begin
    
    -- One GTP QUAD configured for OUTPUT TX ONLY. RX disabled. DRP is not used here.

    daq_quad_inst : daphne2_daq_txonly
    port map
    (
        Q0_CLK0_GTREFCLK_PAD_N_IN => q0_clk0_gtrefclk_pad_n_in,
        Q0_CLK0_GTREFCLK_PAD_P_IN => q0_clk0_gtrefclk_pad_p_in,

        gt0_txdata_in => gt0_txdata_in,
        gt0_txcharisk_in => gt0_txcharisk_in,
        gt0_gtptxn_out => gt0_gtptxn_out,
        gt0_gtptxp_out => gt0_gtptxp_out,
        gt0_drpaddr_in => "000000000",
        gt0_drpdi_in => X"0000",
        gt0_drpdo_out => open,
        gt0_drpen_in => '0',
        gt0_drprdy_out => open,
        gt0_drpwe_in => '0',
        gt0_eyescanreset_in => '0',
        gt0_eyescandataerror_out => open,
        gt0_eyescantrigger_in => '0',
        gt0_dmonitorout_out => open,
        gt0_gtrxreset_in => '0',
        gt0_rxlpmreset_in => '0',
        gt0_gttxreset_in => '0',
        gt0_txuserrdy_in => '1',
        gt0_txoutclkfabric_out => open,
        gt0_txoutclkpcs_out => open,
        gt0_txresetdone_out => open,

        gt1_txdata_in => gt1_txdata_in,
        gt1_txcharisk_in => gt1_txcharisk_in,
        gt1_gtptxn_out => gt1_gtptxn_out,
        gt1_gtptxp_out => gt1_gtptxp_out,
        gt1_drpaddr_in => "000000000",
        gt1_drpdi_in => X"0000",
        gt1_drpdo_out => open,
        gt1_drpen_in => '0',
        gt1_drprdy_out => open,
        gt1_drpwe_in => '0',
        gt1_eyescanreset_in => '0',
        gt1_eyescandataerror_out => open,
        gt1_eyescantrigger_in => '0',
        gt1_dmonitorout_out => open,
        gt1_gtrxreset_in => '0',
        gt1_rxlpmreset_in => '0',
        gt1_gttxreset_in => '0',
        gt1_txuserrdy_in => '1',
        gt1_txoutclkfabric_out => open,
        gt1_txoutclkpcs_out => open,
        gt1_txresetdone_out => open,

        gt2_txdata_in => gt2_txdata_in,
        gt2_txcharisk_in => gt2_txcharisk_in,
        gt2_gtptxn_out => gt2_gtptxn_out,
        gt2_gtptxp_out => gt2_gtptxp_out,
        gt2_drpaddr_in => "000000000",
        gt2_drpdi_in => X"0000",
        gt2_drpdo_out => open,
        gt2_drpen_in => '0',
        gt2_drprdy_out => open,
        gt2_drpwe_in => '0',
        gt2_eyescanreset_in => '0',
        gt2_eyescandataerror_out => open,
        gt2_eyescantrigger_in => '0',
        gt2_dmonitorout_out => open,
        gt2_gtrxreset_in => '0',
        gt2_rxlpmreset_in => '0',
        gt2_gttxreset_in => '0',
        gt2_txuserrdy_in => '1',
        gt2_txoutclkfabric_out => open,
        gt2_txoutclkpcs_out => open,
        gt2_txresetdone_out => open,

        gt3_txdata_in => gt3_txdata_in,
        gt3_txcharisk_in => gt3_txcharisk_in,
        gt3_gtptxn_out => gt3_gtptxn_out,
        gt3_gtptxp_out => gt3_gtptxp_out,
        gt3_drpaddr_in => "000000000",
        gt3_drpdi_in => X"0000",
        gt3_drpdo_out => open,
        gt3_drpen_in => '0',
        gt3_drprdy_out => open,
        gt3_drpwe_in => '0',
        gt3_eyescanreset_in => '0',
        gt3_eyescandataerror_out => open,
        gt3_eyescantrigger_in => '0',
        gt3_dmonitorout_out => open,
        gt3_gtrxreset_in => '0',
        gt3_rxlpmreset_in => '0',
        gt3_gttxreset_in => '0',
        gt3_txuserrdy_in => '1',
        gt3_txoutclkfabric_out => open,
        gt3_txoutclkpcs_out => open,
        gt3_txresetdone_out => open,

        sysclk_in => sysclk_in, -- must supply this 100MHz clock even tho DRP is not used...
   
        GT0_DRPADDR_COMMON_IN => "00000000",
        GT0_DRPDI_COMMON_IN => "0000000000000000",
        GT0_DRPDO_COMMON_OUT => open,
        GT0_DRPEN_COMMON_IN => '0',
        GT0_DRPRDY_COMMON_OUT => open,
        GT0_DRPWE_COMMON_IN => '0',

        GT0_PLL0OUTCLK_OUT  => open,
        GT0_PLL0OUTREFCLK_OUT  => open,
        GT0_PLL0LOCK_OUT  => open,
        GT0_PLL0REFCLKLOST_OUT  => open,    
        GT0_PLL1OUTCLK_OUT  => open,
        GT0_PLL1OUTREFCLK_OUT  => open,

        GT0_TX_MMCM_LOCK_OUT => open,
        GT0_TX_FSM_RESET_DONE_OUT => open,
        GT0_RX_FSM_RESET_DONE_OUT => open,
        GT0_DATA_VALID_IN => '0',

        GT1_TX_MMCM_LOCK_OUT => open,
        GT1_TX_FSM_RESET_DONE_OUT => open,
        GT1_RX_FSM_RESET_DONE_OUT => open,
        GT1_DATA_VALID_IN => '0',

        GT2_TX_MMCM_LOCK_OUT => open,
        GT2_TX_FSM_RESET_DONE_OUT => open,
        GT2_RX_FSM_RESET_DONE_OUT => open,
        GT2_DATA_VALID_IN => '0',

        GT3_TX_MMCM_LOCK_OUT => open,
        GT3_TX_FSM_RESET_DONE_OUT => open,
        GT3_RX_FSM_RESET_DONE_OUT => open,
        GT3_DATA_VALID_IN => '0',

        DONT_RESET_ON_DATA_ERROR_IN => '0',

        soft_reset_tx_in => soft_reset_tx_in,

        GT0_TXUSRCLK_OUT => open, -- 240.474MHz don't use
        GT0_TXUSRCLK2_OUT => gt0_txusrclk2_out, -- 120.237MHz
        GT1_TXUSRCLK_OUT => open,
        GT1_TXUSRCLK2_OUT => gt1_txusrclk2_out,
        GT2_TXUSRCLK_OUT => open,
        GT2_TXUSRCLK2_OUT => gt2_txusrclk2_out,
        GT3_TXUSRCLK_OUT => open,
        GT3_TXUSRCLK2_OUT => gt3_txusrclk2_out

    );

end core_mgt4_arch; 

