-- core.vhd
-- DAPHNE2 core logic
--
-- This core logic supports BOTH the SELF-TRIGGERED and STREAMING mode senders.
--
-- Each streaming sender is connected to four channels. The ch_sel input determines which input
-- channel is connected to which streaming sender.
--
-- Each self-triggered sender is "hard wired" to ten input channels. See the channel mapping below.
--
-- there are four output links which are controlled by the outmode bits. for example, link0 is controlled 
-- by bits [1..0] like this:
-- 0X = send idles
-- 10 = streaming sender
-- 11 = self-triggered sender
--
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;

use work.daphne2_package.all;

entity core is
port(
    mclk: in std_logic; -- master clock 62.5MHz
    sclk100: in std_logic; -- system clock 100MHz 
    reset: in std_logic; -- for sender logic and for GTP quad
    din: in array_5x9x14_type;  -- AFE data synch to mclk
    timestamp: in std_logic_vector(63 downto 0); -- sync to mclk

    outmode: in std_logic_vector(7 downto 0); -- for each output link select streaming, self-trig, or disabled
    ch_sel: in array_4x4x6_type; -- choose which input channels are used for streaming senders
    threshold: in std_logic_vector(13 downto 0); -- for self-triggered mode, relative to average baseline

    slot_id: in std_logic_vector(3 downto 0);
    crate_id: in std_logic_vector(9 downto 0);
    detector_id: in std_logic_vector(5 downto 0);
    version_id: in std_logic_vector(5 downto 0);

    oeiclk: in std_logic;
    trig: in std_logic;
    spy_addr: in std_logic_vector(11 downto 0);
    spy_data: out std_logic_vector(31 downto 0);

    -- GTP/SFP external interface
    
    daq_refclk_p, daq_refclk_n: in std_logic; -- MGT REFCLK for DAQ, LVDS, quad 213, refclk0, 120.237MHz

    daq0_tx_p, daq0_tx_n: out std_logic;
    daq1_tx_p, daq1_tx_n: out std_logic;
    daq2_tx_p, daq2_tx_n: out std_logic;
    daq3_tx_p, daq3_tx_n: out std_logic

);
end core;

architecture core_arch of core is

    component dstr4 -- 4 channel streaming sender
    generic( link: std_logic_vector(5 downto 0) := "000000" );  
    port(
        reset: in std_logic;
        slot_id: in std_logic_vector(3 downto 0);
        crate_id: in std_logic_vector(9 downto 0);
        detector_id: in std_logic_vector(5 downto 0);
        version_id: in std_logic_vector(5 downto 0);
        mclk: in std_logic; -- master clock 62.5 MHz
        timestamp: in std_logic_vector(63 downto 0);
    	afe_dat0, afe_dat1, afe_dat2, afe_dat3: in std_logic_vector(13 downto 0); -- four AFE ADC channels
        ch0_id, ch1_id, ch2_id, ch3_id: in std_logic_vector(5 downto 0); -- the channel ID number       
        fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
        dout: out std_logic_vector(31 downto 0);
        kout: out std_logic_vector( 3 downto 0));
    end component;

    component st10_top -- 10 channel self-triggered sender
    generic( link_id: std_logic_vector(5 downto 0)  := "000000" );
    port(
        reset: in std_logic;    
        threshold: in std_logic_vector(13 downto 0); -- user defined threshold over baseline
        slot_id: in std_logic_vector(3 downto 0);
        crate_id: in std_logic_vector(9 downto 0);
        detector_id: in std_logic_vector(5 downto 0);
        version_id: in std_logic_vector(5 downto 0);
        aclk: in std_logic; -- AFE clock 62.500 MHz
        timestamp: in std_logic_vector(63 downto 0);
    	afe_dat: in array_10x14_type;
        fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
        dout: out std_logic_vector(31 downto 0);
        kout: out std_logic_vector(3 downto 0)
    );
    end component;

    component spy
    port(
        clka:  in std_logic;  
        reset: in std_logic;
        trig:  in std_logic;
        dia:   in std_logic_vector(15 downto 0);
        clkb:  in  std_logic;
        addrb: in  std_logic_vector(11 downto 0);
        dob:   out std_logic_vector(15 downto 0)
      );
    end component;

    -- the following component is from Xilinx IP generator...

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

    signal fclk0, fclk1, fclk2, fclk3: std_logic;

    signal st10_sender0_input, st10_sender1_input, st10_sender2_input, st10_sender3_input: array_10x14_type;
    signal ch_mux: array_4x4x14_type;

    signal stream_sender0_dout, stream_sender1_dout, stream_sender2_dout, stream_sender3_dout:   std_logic_vector(31 downto 0);
    signal selftrig_sender0_dout, selftrig_sender1_dout, selftrig_sender2_dout, selftrig_sender3_dout: std_logic_vector(31 downto 0);
    signal sender0_dout, sender1_dout, sender2_dout, sender3_dout: std_logic_vector(31 downto 0);

    signal stream_sender0_kout, stream_sender1_kout, stream_sender2_kout, stream_sender3_kout: std_logic_vector(3 downto 0);
    signal selftrig_sender0_kout, selftrig_sender1_kout, selftrig_sender2_kout, selftrig_sender3_kout: std_logic_vector(3 downto 0);
    signal sender0_kout, sender1_kout, sender2_kout, sender3_kout: std_logic_vector(3 downto 0);

    signal trig_fclk_reg: std_logic;

begin
    
    -- big mux to determine which input channels are connected to which streaming sender module
    -- each sender module can accept four inputs

    sendergen: for i in 3 downto 3 generate
        inputgen: for j in 3 downto 0 generate
            ch_mux(i)(j) <= din(0)(0) when (ch_sel(i)(j)="000000") else -- 0
                            din(0)(1) when (ch_sel(i)(j)="000001") else -- 1
                            din(0)(2) when (ch_sel(i)(j)="000010") else -- 2
                            din(0)(3) when (ch_sel(i)(j)="000011") else -- 3
                            din(0)(4) when (ch_sel(i)(j)="000100") else -- 4
                            din(0)(5) when (ch_sel(i)(j)="000101") else -- 5 
                            din(0)(6) when (ch_sel(i)(j)="000110") else -- 6 
                            din(0)(7) when (ch_sel(i)(j)="000111") else -- 7
                            din(1)(0) when (ch_sel(i)(j)="001000") else -- 8
                            din(1)(1) when (ch_sel(i)(j)="001001") else -- 9
                            din(1)(2) when (ch_sel(i)(j)="001010") else -- 10
                            din(1)(3) when (ch_sel(i)(j)="001011") else -- 11
                            din(1)(4) when (ch_sel(i)(j)="001100") else -- 12
                            din(1)(5) when (ch_sel(i)(j)="001101") else -- 13
                            din(1)(6) when (ch_sel(i)(j)="001110") else -- 14
                            din(1)(7) when (ch_sel(i)(j)="001111") else -- 15
                            din(2)(0) when (ch_sel(i)(j)="010000") else -- 16
                            din(2)(1) when (ch_sel(i)(j)="010001") else -- 17
                            din(2)(2) when (ch_sel(i)(j)="010010") else -- 18
                            din(2)(3) when (ch_sel(i)(j)="010011") else -- 19
                            din(2)(4) when (ch_sel(i)(j)="010100") else -- 20
                            din(2)(5) when (ch_sel(i)(j)="010101") else -- 21
                            din(2)(6) when (ch_sel(i)(j)="010110") else -- 22
                            din(2)(7) when (ch_sel(i)(j)="010111") else -- 23
                            din(3)(0) when (ch_sel(i)(j)="011000") else -- 24
                            din(3)(1) when (ch_sel(i)(j)="011001") else -- 25
                            din(3)(2) when (ch_sel(i)(j)="011010") else -- 26
                            din(3)(3) when (ch_sel(i)(j)="011011") else -- 27
                            din(3)(4) when (ch_sel(i)(j)="011100") else -- 28
                            din(3)(5) when (ch_sel(i)(j)="011101") else -- 29
                            din(3)(6) when (ch_sel(i)(j)="011110") else -- 30
                            din(3)(7) when (ch_sel(i)(j)="011111") else -- 31
                            din(4)(0) when (ch_sel(i)(j)="100000") else -- 32
                            din(4)(1) when (ch_sel(i)(j)="100001") else -- 33 
                            din(4)(2) when (ch_sel(i)(j)="100010") else -- 34
                            din(4)(3) when (ch_sel(i)(j)="100011") else -- 35
                            din(4)(4) when (ch_sel(i)(j)="100100") else -- 36
                            din(4)(5) when (ch_sel(i)(j)="100101") else -- 37
                            din(4)(6) when (ch_sel(i)(j)="100110") else -- 38
                            din(4)(7) when (ch_sel(i)(j)="000111") else -- 39
                            (others=>'0');
        end generate inputgen;
    end generate sendergen;

    -- instantiate four streaming senders

    stream_sender0_inst: dstr4 
    generic map( link => "000000" )
    port map(
        reset => reset,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        mclk => mclk,
        timestamp => timestamp,
    	afe_dat0 => ch_mux(0)(0), 
        afe_dat1 => ch_mux(0)(1),
        afe_dat2 => ch_mux(0)(2),
        afe_dat3 => ch_mux(0)(3),
        ch0_id => ch_sel(0)(0),
        ch1_id => ch_sel(0)(1), 
        ch2_id => ch_sel(0)(2),
        ch3_id => ch_sel(0)(3),
        fclk => fclk0,
        dout => stream_sender0_dout,
        kout => stream_sender0_kout
    );

    stream_sender1_inst: dstr4 
    generic map( link => "000001" )
    port map(
        reset => reset,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        mclk => mclk,
        timestamp => timestamp,
    	afe_dat0 => ch_mux(1)(0),
        afe_dat1 => ch_mux(1)(1),
        afe_dat2 => ch_mux(1)(2),
        afe_dat3 => ch_mux(1)(3),
        ch0_id => ch_sel(1)(0),
        ch1_id => ch_sel(1)(1),
        ch2_id => ch_sel(1)(2),
        ch3_id => ch_sel(1)(3),
        fclk => fclk1,
        dout => stream_sender1_dout,
        kout => stream_sender1_kout
    );

    stream_sender2_inst: dstr4 
    generic map( link => "000010" )
    port map(
        reset => reset,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        mclk => mclk,
        timestamp => timestamp,
    	afe_dat0 => ch_mux(2)(0), 
        afe_dat1 => ch_mux(2)(1),
        afe_dat2 => ch_mux(2)(2),
        afe_dat3 => ch_mux(2)(3),
        ch0_id => ch_sel(2)(0),
        ch1_id => ch_sel(2)(1), 
        ch2_id => ch_sel(2)(2),
        ch3_id => ch_sel(2)(3),
        fclk => fclk2,
        dout => stream_sender2_dout,
        kout => stream_sender2_kout
    );

    stream_sender3_inst: dstr4 
    generic map( link => "000011" )
    port map(
        reset => reset,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        mclk => mclk,
        timestamp => timestamp,
    	afe_dat0 => ch_mux(3)(0), 
        afe_dat1 => ch_mux(3)(1),
        afe_dat2 => ch_mux(3)(2),
        afe_dat3 => ch_mux(3)(3),
        ch0_id => ch_sel(3)(0),
        ch1_id => ch_sel(3)(1), 
        ch2_id => ch_sel(3)(2),
        ch3_id => ch_sel(3)(3),        
        fclk => fclk3,
        dout => stream_sender3_dout,
        kout => stream_sender3_kout
    );
  
    -- unlike the streaming senders, the self triggered senders 
    -- are "hard wired" to input channels. this mapping is defined here:

    st10_sender0_input(0) <= din(0)(0); -- AFE0 channel 0
    st10_sender0_input(1) <= din(0)(1);
    st10_sender0_input(2) <= din(0)(2);
    st10_sender0_input(3) <= din(0)(3);
    st10_sender0_input(4) <= din(0)(4);
    st10_sender0_input(5) <= din(0)(5);
    st10_sender0_input(6) <= din(0)(6);
    st10_sender0_input(7) <= din(0)(7);
    st10_sender0_input(8) <= din(1)(0); -- AFE1 channel 0
    st10_sender0_input(9) <= din(1)(1);

    st10_sender1_input(0) <= din(1)(2); 
    st10_sender1_input(1) <= din(1)(3);
    st10_sender1_input(2) <= din(1)(4);
    st10_sender1_input(3) <= din(1)(5);
    st10_sender1_input(4) <= din(1)(6);
    st10_sender1_input(5) <= din(1)(7);
    st10_sender1_input(6) <= din(2)(0); -- AFE2 channel 0
    st10_sender1_input(7) <= din(2)(1);
    st10_sender1_input(8) <= din(2)(2);
    st10_sender1_input(9) <= din(2)(3);

    st10_sender2_input(0) <= din(2)(4); 
    st10_sender2_input(1) <= din(2)(5);
    st10_sender2_input(2) <= din(2)(6);
    st10_sender2_input(3) <= din(2)(7);
    st10_sender2_input(4) <= din(3)(0); -- AFE3 channel 0
    st10_sender2_input(5) <= din(3)(1);
    st10_sender2_input(6) <= din(3)(2);
    st10_sender2_input(7) <= din(3)(3);
    st10_sender2_input(8) <= din(3)(4);
    st10_sender2_input(9) <= din(3)(5);

    st10_sender3_input(0) <= din(3)(6);
    st10_sender3_input(1) <= din(3)(7);
    st10_sender3_input(2) <= din(4)(0); -- AFE4 channel 0
    st10_sender3_input(3) <= din(4)(1);
    st10_sender3_input(4) <= din(4)(2);
    st10_sender3_input(5) <= din(4)(3);
    st10_sender3_input(6) <= din(4)(4);
    st10_sender3_input(7) <= din(4)(5);
    st10_sender3_input(8) <= din(4)(6);
    st10_sender3_input(9) <= din(4)(7);

    -- instantiate four 10-input self-triggered senders
    -- these senders are always present and active

    st10_sender0_inst: st10_top 
    generic map( link_id => "000000" )
    port map(
        reset => reset,
        threshold => threshold,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        aclk => mclk,
        timestamp => timestamp,
    	afe_dat => st10_sender0_input,
        fclk => fclk0,
        dout => selftrig_sender0_dout,
        kout => selftrig_sender0_kout
    );

    st10_sender1_inst: st10_top 
    generic map( link_id => "000001" )
    port map(
        reset => reset,
        threshold => threshold,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        aclk => mclk,
        timestamp => timestamp,
    	afe_dat => st10_sender1_input,
        fclk => fclk1,
        dout => selftrig_sender1_dout,
        kout => selftrig_sender1_kout
    );

    st10_sender2_inst: st10_top 
    generic map( link_id => "000010" )
    port map(
        reset => reset,
        threshold => threshold,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        aclk => mclk,
        timestamp => timestamp,
    	afe_dat => st10_sender2_input,
        fclk => fclk2,
        dout => selftrig_sender2_dout,
        kout => selftrig_sender2_kout
    );

    st10_sender3_inst: st10_top 
    generic map( link_id => "000011" )
    port map(
        reset => reset,
        threshold => threshold,
        slot_id => slot_id,
        crate_id => crate_id,
        detector_id => detector_id,
        version_id => version_id,
        aclk => mclk,
        timestamp => timestamp,
    	afe_dat => st10_sender3_input,
        fclk => fclk3,
        dout => selftrig_sender3_dout,
        kout => selftrig_sender3_kout
    );

    -- a mux determines whether the streaming sender or the self triggered sender
    -- is connected to each output. this mux is controlled by the outmode bits

    sender0_kout <= stream_sender0_kout   when (outmode(1 downto 0)="10") else 
                    selftrig_sender0_kout when (outmode(1 downto 0)="11") else 
                    "0001"; -- idle word

    sender1_kout <= stream_sender1_kout   when (outmode(3 downto 2)="10") else 
                    selftrig_sender1_kout when (outmode(3 downto 2)="11") else 
                    "0001";

    sender2_kout <= stream_sender2_kout   when (outmode(5 downto 4)="10") else 
                    selftrig_sender2_kout when (outmode(5 downto 4)="11") else 
                    "0001";

    sender3_kout <= stream_sender3_kout   when (outmode(7 downto 6)="10") else 
                    selftrig_sender3_kout when (outmode(7 downto 6)="11") else 
                    "0001";

    sender0_dout <= stream_sender0_dout   when (outmode(1 downto 0)="10") else 
                    selftrig_sender0_dout when (outmode(1 downto 0)="11") else 
                    X"000000BC";

    sender1_dout <= stream_sender1_dout   when (outmode(3 downto 2)="10") else 
                    selftrig_sender1_dout when (outmode(3 downto 2)="11") else 
                    X"000000BC";

    sender2_dout <= stream_sender2_dout   when (outmode(5 downto 4)="10") else 
                    selftrig_sender2_dout when (outmode(5 downto 4)="11") else 
                    X"000000BC";

    sender3_dout <= stream_sender3_dout   when (outmode(7 downto 6)="10") else 
                    selftrig_sender3_dout when (outmode(7 downto 6)="11") else 
                    X"000000BC";

    -- the trigger input to this module comes from the mclk clock domain
    -- and the pulse is guaranteed to be several mclk cycles wide.
    -- resample in the fclk domain before it can be used by the spy buffers

    trig_fclk_proc: process(fclk0)
    begin
        if rising_edge(fclk0) then
            trig_fclk_reg <= trig;
        end if;
    end process trig_fclk_proc;

    -- insert some spy buffers to capture the output of sender0
    -- stores the 32 bit data prior to 8b/10b encoding, depth is 4k
    -- has 64 pre-trigger samples too.

    sender0_spy_hi_inst: spy
    port map(
        clka  => fclk0,
        reset => reset,
        trig  => trig_fclk_reg,
        dia   => sender0_dout(31 downto 16),

        clkb  => oeiclk,
        addrb => spy_addr(11 downto 0),
        dob   => spy_data(31 downto 16)
      );

    sender0_spy_lo_inst: spy
    port map(
        clka  => fclk0,
        reset => reset,
        trig  => trig_fclk_reg,
        dia   => sender0_dout(15 downto 0),

        clkb  => oeiclk,
        addrb => spy_addr(11 downto 0),
        dob   => spy_data(15 downto 0)
      );

    -- One GTP QUAD configured for OUTPUT TX ONLY. RX disabled. DRP is not used here.

    daq_quad_inst : daphne2_daq_txonly
    port map
    (
        Q0_CLK0_GTREFCLK_PAD_N_IN => daq_refclk_n,  -- should be 120.237MHz for FELIX links
        Q0_CLK0_GTREFCLK_PAD_P_IN => daq_refclk_p,

        gt0_txdata_in => sender0_dout,
        gt0_txcharisk_in => sender0_kout,
        gt0_gtptxn_out => daq0_tx_n,
        gt0_gtptxp_out => daq0_tx_p,
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

        gt1_txdata_in => sender1_dout,
        gt1_txcharisk_in => sender1_kout,
        gt1_gtptxn_out => daq1_tx_n,
        gt1_gtptxp_out => daq1_tx_p,
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

        gt2_txdata_in => sender2_dout,
        gt2_txcharisk_in => sender2_kout,
        gt2_gtptxn_out => daq2_tx_n,
        gt2_gtptxp_out => daq2_tx_p,
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

        gt3_txdata_in => sender3_dout,
        gt3_txcharisk_in => sender3_kout,
        gt3_gtptxn_out => daq3_tx_n,
        gt3_gtptxp_out => daq3_tx_p,
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

        sysclk_in => sclk100, -- must supply this 100MHz clock even tho DRP is not used...
   
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

        soft_reset_tx_in => reset,

        GT0_TXUSRCLK_OUT => open, -- 240.474MHz don't use
        GT0_TXUSRCLK2_OUT => fclk0, -- 120.237MHz
        GT1_TXUSRCLK_OUT => open,
        GT1_TXUSRCLK2_OUT => fclk1,
        GT2_TXUSRCLK_OUT => open,
        GT2_TXUSRCLK2_OUT => fclk2,
        GT3_TXUSRCLK_OUT => open,
        GT3_TXUSRCLK2_OUT => fclk3

    );

end core_arch; 

