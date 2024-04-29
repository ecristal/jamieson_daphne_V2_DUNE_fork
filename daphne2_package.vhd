-- daphne2_package.vhd
-- for the DAPHNE2 design
-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package daphne2_package is

    -- Set lower byte of static IP for GbE Interface.
    -- MAC = 00:80:55:DE:00:XX and IP = 192.168.133.XX
    -- where XX is EFUSE_USER[15..8] NOTE this is one time programmable!

    -- Address Mapping using the std_match notation '-' is a "don't care" bit

    constant BRAM0_ADDR:    std_logic_vector(31 downto 0) := "0000000000000111000000----------";  -- 0x00070000-0x000703FF
    constant DEADBEEF_ADDR: std_logic_vector(31 downto 0) := X"0000aa55";
    constant STATVEC_ADDR:  std_logic_vector(31 downto 0) := X"00001974";
    constant SFPSTATVEC_ADDR:  std_logic_vector(31 downto 0) := X"00001975";
    constant GITVER_ADDR:   std_logic_vector(31 downto 0) := X"00009000";
    constant TESTREG_ADDR:  std_logic_vector(31 downto 0) := X"12345678";
    constant FIFO_ADDR:     std_logic_vector(31 downto 0) := X"80000000";

    type array_4x4_type is array (3 downto 0) of std_logic_vector(3 downto 0);
    type array_4x6_type is array (3 downto 0) of std_logic_vector(5 downto 0);
    type array_4x14_type is array (3 downto 0) of std_logic_vector(13 downto 0);
    type array_4x32_type is array (3 downto 0) of std_logic_vector(31 downto 0);
    type array_5x8_type is array (4 downto 0) of std_logic_vector(7 downto 0);
    type array_5x9_type is array (4 downto 0) of std_logic_vector(8 downto 0);
    type array_8x4_type is array (7 downto 0) of std_logic_vector(3 downto 0);
    type array_8x14_type is array (7 downto 0) of std_logic_vector(13 downto 0);
    type array_8x32_type is array (7 downto 0) of std_logic_vector(31 downto 0);
    type array_9x14_type is array (8 downto 0) of std_logic_vector(13 downto 0);
    type array_9x16_type is array (8 downto 0) of std_logic_vector(15 downto 0);
    type array_10x6_type is array (9 downto 0) of std_logic_vector(5 downto 0);
    type array_10x14_type is array (9 downto 0) of std_logic_vector(13 downto 0);

    type array_4x4x6_type is array (3 downto 0) of array_4x6_type;
    type array_4x4x14_type is array (3 downto 0) of array_4x14_type;
    type array_4x10x6_type is array (3 downto 0) of array_10x6_type;
    type array_4x10x14_type is array (3 downto 0) of array_10x14_type;
    type array_5x8x4_type is array (4 downto 0) of array_8x4_type;
    type array_5x8x14_type is array (4 downto 0) of array_8x14_type;
    type array_5x8x32_type is array (4 downto 0) of array_8x32_type;
    type array_5x9x14_type is array (4 downto 0) of array_9x14_type;
    type array_5x9x16_type is array (4 downto 0) of array_9x16_type;

    -- write anything to this address to force trigger

    constant TRIGGER_ADDR: std_logic_vector(31 downto 0) := X"00002000";

    -- write anything to this address to force front end recalibration

    constant FE_RST_ADDR: std_logic_vector(31 downto 0) := X"00002001";

    -- read the status of the automatic front end logic (is it done?)

    constant FEDONE_ADDR: std_logic_vector(31 downto 0) := X"00002002";

    -- read the status of the automatic front end logic (warning of bit errors)

    constant FEWARN_ADDR: std_logic_vector(31 downto 0) := X"00002003";

    -- read the error count for each AFE front end module (range 0 to 255)

    constant AFE0_ERRCNT_ADDR: std_logic_vector(31 downto 0) := X"00002010";
    constant AFE1_ERRCNT_ADDR: std_logic_vector(31 downto 0) := X"00002011";
    constant AFE2_ERRCNT_ADDR: std_logic_vector(31 downto 0) := X"00002012";
    constant AFE3_ERRCNT_ADDR: std_logic_vector(31 downto 0) := X"00002013";
    constant AFE4_ERRCNT_ADDR: std_logic_vector(31 downto 0) := X"00002014";

    -- output link parameters

    constant DAQ_OUT_PARAM_ADDR: std_logic_vector(31 downto 0) := X"00003000";

    constant DEFAULT_DAQ_OUT_SLOT_ID:     std_logic_vector(3 downto 0) := "0010";
    constant DEFAULT_DAQ_OUT_CRATE_ID:    std_logic_vector(9 downto 0) := "0000000001";
    constant DEFAULT_DAQ_OUT_DETECTOR_ID: std_logic_vector(5 downto 0) := "000010";
    constant DEFAULT_DAQ_OUT_VERSION_ID:  std_logic_vector(5 downto 0) := "000010";

    -- DAQ output link mode selection register

    constant DAQ_OUTMODE_BASEADDR: std_logic_vector(31 downto 0) := X"00003001";

    constant DEFAULT_DAQ_OUTMODE: std_logic_vector(7 downto 0) := X"00";

    -- master clock and timing endpoint status register

    constant MCLK_STAT_ADDR: std_logic_vector(31 downto 0) := X"00004000";

    -- master clock and timing endpoint control register

    constant MCLK_CTRL_ADDR: std_logic_vector(31 downto 0) := X"00004001";
    
    -- write anything to this address to reset master clock MMCM1

    constant MMCM1_RST_ADDR: std_logic_vector(31 downto 0) := X"00004002";

    -- write anything to this address to reset timing endpoint logic

    constant EP_RST_ADDR: std_logic_vector(31 downto 0) := X"00004003";

    -- choose which inputs are connected to each streaming core sender.
    -- This is a block of 16 registers and is R/W 0x5000 - 0x500F  

    constant CORE_INMUX_ADDR: std_logic_vector(31 downto 0) := "0000000000000000010100000000----";

    -- address of the threshold register for the self trig senders

    constant THRESHOLD_BASEADDR: std_logic_vector(31 downto 0) := X"00006000";

    constant DEFAULT_THRESHOLD: std_logic_vector(13 downto 0) := "00000100000000";

    -- enable disable individual input channels for self triggered sender only

    constant ST_ENABLE_ADDR: std_logic_vector(31 downto 0) := X"00006001";

    constant DEFAULT_ST_ENABLE: std_logic_vector(39 downto 0) := X"0000000000"; -- all self triggered channels OFF 

    -- address of the ad hoc command for the self trig senders

    constant ST_ADHOC_BASEADDR: std_logic_vector(31 downto 0) := X"00006010";

    constant DEFAULT_ST_ADHOC_COMMAND: std_logic_vector(7 downto 0) := X"07";
    
    -- spy buffers are 4k deep

    constant SPYBUF_AFE0_D0_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000000----------------";
    constant SPYBUF_AFE0_D1_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000001----------------";
    constant SPYBUF_AFE0_D2_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000010----------------";
    constant SPYBUF_AFE0_D3_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000011----------------";
    constant SPYBUF_AFE0_D4_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000100----------------";
    constant SPYBUF_AFE0_D5_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000101----------------";
    constant SPYBUF_AFE0_D6_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000110----------------";
    constant SPYBUF_AFE0_D7_BASEADDR: std_logic_vector(31 downto 0) := "0100000000000111----------------";
    constant SPYBUF_AFE0_FR_BASEADDR: std_logic_vector(31 downto 0) := "0100000000001000----------------";

    constant SPYBUF_AFE1_D0_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010000----------------";
    constant SPYBUF_AFE1_D1_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010001----------------";
    constant SPYBUF_AFE1_D2_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010010----------------";
    constant SPYBUF_AFE1_D3_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010011----------------";
    constant SPYBUF_AFE1_D4_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010100----------------";
    constant SPYBUF_AFE1_D5_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010101----------------";
    constant SPYBUF_AFE1_D6_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010110----------------";
    constant SPYBUF_AFE1_D7_BASEADDR: std_logic_vector(31 downto 0) := "0100000000010111----------------";
    constant SPYBUF_AFE1_FR_BASEADDR: std_logic_vector(31 downto 0) := "0100000000011000----------------";

    constant SPYBUF_AFE2_D0_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100000----------------";
    constant SPYBUF_AFE2_D1_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100001----------------";
    constant SPYBUF_AFE2_D2_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100010----------------";
    constant SPYBUF_AFE2_D3_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100011----------------";
    constant SPYBUF_AFE2_D4_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100100----------------";
    constant SPYBUF_AFE2_D5_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100101----------------";
    constant SPYBUF_AFE2_D6_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100110----------------";
    constant SPYBUF_AFE2_D7_BASEADDR: std_logic_vector(31 downto 0) := "0100000000100111----------------";
    constant SPYBUF_AFE2_FR_BASEADDR: std_logic_vector(31 downto 0) := "0100000000101000----------------";

    constant SPYBUF_AFE3_D0_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110000----------------";
    constant SPYBUF_AFE3_D1_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110001----------------";
    constant SPYBUF_AFE3_D2_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110010----------------";
    constant SPYBUF_AFE3_D3_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110011----------------";
    constant SPYBUF_AFE3_D4_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110100----------------";
    constant SPYBUF_AFE3_D5_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110101----------------";
    constant SPYBUF_AFE3_D6_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110110----------------";
    constant SPYBUF_AFE3_D7_BASEADDR: std_logic_vector(31 downto 0) := "0100000000110111----------------";
    constant SPYBUF_AFE3_FR_BASEADDR: std_logic_vector(31 downto 0) := "0100000000111000----------------";

    constant SPYBUF_AFE4_D0_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000000----------------";
    constant SPYBUF_AFE4_D1_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000001----------------";
    constant SPYBUF_AFE4_D2_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000010----------------";
    constant SPYBUF_AFE4_D3_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000011----------------";
    constant SPYBUF_AFE4_D4_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000100----------------";
    constant SPYBUF_AFE4_D5_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000101----------------";
    constant SPYBUF_AFE4_D6_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000110----------------";
    constant SPYBUF_AFE4_D7_BASEADDR: std_logic_vector(31 downto 0) := "0100000001000111----------------";
    constant SPYBUF_AFE4_FR_BASEADDR: std_logic_vector(31 downto 0) := "0100000001001000----------------";

    -- spy buffer for the 64 bit timestamp value

    constant SPYBUFTS_BASEADDR: std_logic_vector(31 downto 0) := "0100000001010000----------------";

    -- spy buffer for the first output link 

    constant SPYBUFDOUT0_BASEADDR: std_logic_vector(31 downto 0) := "0100000001100000----------------";

    -- SPI slave has two FIFOs, each 2kx8. The command FIFO is write only. The response FIFO is read only.
    -- because of this they can and do share an address.

    constant SPI_FIFO_ADDR: std_logic_vector(31 downto 0) := X"90000000";

end package;


