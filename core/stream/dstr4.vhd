-- dstr4.vhd
-- DAPHNE streaming core module, input is 4 AFE data streams, each 14 bits wide, 
-- constantly arriving at 62.5MHz. Output is a 32 bit stream sync to fclk, 120.237 MHz
-- 
-- NOTE that the output stream runs SLIGHTLY faster than the input:
-- INPUT = 64 samples @ 62.5 MHz = 1.024000 us
-- OUTPUT = SOF + one frame of 118 words + EOF = 120 words @ 120.237 MHz = 0.998029 us
--
--  + 2 idles = 122 words @ 120.237 MHz = 1.014662 us
--  + 3 idles = 123 words @ 120.237 MHz = 1.022979 us
--  + 4 idles = 124 words @ 120.237 MHz = 1.031296 us
--

-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity dstr4 is
generic( link: std_logic_vector(5 downto 0) := "000000" );
port(
    reset: in std_logic;
    
    slot_id: std_logic_vector(3 downto 0);
    crate_id: std_logic_vector(9 downto 0);
    detector_id: std_logic_vector(5 downto 0);
    version_id: std_logic_vector(5 downto 0);

    mclk: in std_logic; -- master clock 62.500 MHz
    timestamp: in std_logic_vector(63 downto 0);
	afe_dat0, afe_dat1, afe_dat2, afe_dat3: in std_logic_vector(13 downto 0); -- four AFE ADC channels
    ch0_id, ch1_id, ch2_id, ch3_id: in std_logic_vector(5 downto 0); -- the channel ID number
    
    fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
    dout: out std_logic_vector(31 downto 0);
    kout: out std_logic_vector( 3 downto 0)
  );
end dstr4;

architecture dstr4_arch of dstr4 is

    signal wptr: std_logic_vector(1 downto 0) := "00";
    
    signal ch0_0_reg, ch0_1_reg, ch0_2_reg, ch0_3_reg: std_logic_vector(13 downto 0);
    signal ch1_0_reg, ch1_1_reg, ch1_2_reg, ch1_3_reg: std_logic_vector(13 downto 0);
    signal ch2_0_reg, ch2_1_reg, ch2_2_reg, ch2_3_reg: std_logic_vector(13 downto 0);
    signal ch3_0_reg, ch3_1_reg, ch3_2_reg, ch3_3_reg: std_logic_vector(13 downto 0);

    signal timestamp_reg, fifo_timestamp: std_logic_vector(63 downto 0);

    type array_7x32_type is array(6 downto 0) of std_logic_vector(31 downto 0);
    signal temp, fifo_do: array_7x32_type;

    signal fifo_wren, fifo_rden: std_logic;
    signal fifo_ae: std_logic_vector(6 downto 0); -- fifo almost empty flags

    type sender_fsm_type is (rst, idle, sof, hdr0, hdr1, hdr2, hdr3, hdr4, dat0, dat1, dat2, dat3, dat4, dat5, dat6, trailer, eof);
    signal state: sender_fsm_type;

    signal sample_count: std_logic_vector(3 downto 0) := "0000";

    component CRC_OL is
       generic( Nbits: positive := 32; CRC_Width: positive := 20;
                G_Poly: std_logic_vector := X"8359f"; G_InitVal: std_logic_vector := X"fffff" );
       port(
         CRC   : out    std_logic_vector(CRC_Width-1 downto 0);
         Calc  : in     std_logic;
         Clk   : in     std_logic;
         DIn   : in     std_logic_vector(Nbits-1 downto 0);
         Reset : in     std_logic);
    end component;

    signal crc_calc, crc_reset: std_logic;
    signal crc20: std_logic_vector(19 downto 0);
    signal k, kout_reg : std_logic_vector(3 downto 0);
    signal d, dout_reg : std_logic_vector(31 downto 0);

begin

    load_proc: process(mclk) -- register 4 channels, 4 samples
    begin
        if rising_edge(mclk) then
            if (reset='1') then
                wptr <= "00";
            else
                wptr <= std_logic_vector(unsigned(wptr) + 1);
                case(wptr) is
                    when "00" =>
                        timestamp_reg <= timestamp;
                        ch0_0_reg <= afe_dat0;
                        ch1_0_reg <= afe_dat1;
                        ch2_0_reg <= afe_dat2;
                        ch3_0_reg <= afe_dat3;
                    when "01" =>
                        ch0_1_reg <= afe_dat0;
                        ch1_1_reg <= afe_dat1;
                        ch2_1_reg <= afe_dat2;
                        ch3_1_reg <= afe_dat3;
                    when "10" =>
                        ch0_2_reg <= afe_dat0;
                        ch1_2_reg <= afe_dat1;
                        ch2_2_reg <= afe_dat2;
                        ch3_2_reg <= afe_dat3;
                    when "11" =>
                        ch0_3_reg <= afe_dat0;
                        ch1_3_reg <= afe_dat1;
                        ch2_3_reg <= afe_dat2;
                        ch3_3_reg <= afe_dat3;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process load_proc;

    -- here is that nasty packing scheme... 
    -- 4 channels x 4 samples x 14 bit words (224 bits) ----> 7 x 32 bit words (224 bits)

    temp(0)(31 downto 0) <= ch2_0_reg(3 downto 0) & ch1_0_reg & ch0_0_reg;
    temp(1)(31 downto 0) <= ch0_1_reg(7 downto 0) & ch3_0_reg & ch2_0_reg(13 downto 4);
    temp(2)(31 downto 0) <= ch2_1_reg(11 downto 0) & ch1_1_reg & ch0_1_reg(13 downto 8);
    temp(3)(31 downto 0) <= ch1_2_reg(1 downto 0) & ch0_2_reg & ch3_1_reg & ch2_1_reg(13 downto 12);
    temp(4)(31 downto 0) <= ch3_2_reg(5 downto 0) & ch2_2_reg & ch1_2_reg(13 downto 2);
    temp(5)(31 downto 0) <= ch1_3_reg(9 downto 0) & ch0_3_reg & ch3_2_reg(13 downto 6);
    temp(6)(31 downto 0) <= ch3_3_reg & ch2_3_reg & ch1_3_reg(13 downto 10);

    -- write into 7 FIFOs (each 32 bits wide x 512 deep)

    fifo_wren <= '1' when (reset='0' and wptr="00") else '0';

    fifo_gen: for i in 6 downto 0 generate
        fifo18e1_inst: fifo18e1
        generic map(
            ALMOST_EMPTY_OFFSET => X"0010",   
            ALMOST_FULL_OFFSET => X"0080",    
            DATA_WIDTH => 36,                
            DO_REG => 1,                      
            EN_SYN => FALSE,
            FIFO_MODE => "FIFO18_36",
            FIRST_WORD_FALL_THROUGH => FALSE,
            INIT => X"000000000",
            SIM_DEVICE => "7SERIES",
            SRVAL => X"000000000"             
        )
        port map(
            rst    => reset,
            rstreg => '0',
            regce  => '1',
            wrclk => mclk, 
            wren  => fifo_wren,
            di    => temp(i),
            dip   => "0000",
            rdclk => fclk,
            rden  => fifo_rden,
            do    => fifo_do(i),
            almostempty => fifo_ae(i)
        );
    end generate fifo_gen;

    -- one extra FIFO 64 bits wide for storing the timestamp value

    ts_fifo_inst: FIFO36E1
    generic map(
        ALMOST_EMPTY_OFFSET => X"0010",
        ALMOST_FULL_OFFSET => X"0080",
        DATA_WIDTH => 72,                 
        DO_REG => 1,
        EN_ECC_READ => FALSE,
        EN_ECC_WRITE => FALSE,
        EN_SYN => FALSE,                  
        FIFO_MODE => "FIFO36_72",         
        FIRST_WORD_FALL_THROUGH => FALSE, 
        INIT => X"000000000000000000",             
        SIM_DEVICE => "7SERIES",          
        SRVAL => X"000000000000000000"
    )
    port map(
        rst    => reset,
        rstreg => '0',
        regce  => '1',
        injectdbiterr => '0',
        injectsbiterr => '0',
        wrclk  => mclk, 
        wren   => fifo_wren,
        di     => timestamp_reg(63 downto 0),
        dip    => "00000000",
        rdclk  => fclk,
        rden   => fifo_rden,
        do     => fifo_timestamp
    );

    -- output sender logic state machine
    -- 
    -- send IDLE frames until all FIFOs have some stuff in them (almost-empty=0)
    -- then transmit SOF + header 5 header words
    -- followed by 16 x 7 data words from the FIFOs (112 words total)
    -- followed by 1 trailer word + EOF (total DAPHNE frame including SOF and EOF = 120 words)
    -- then repeat...
    --
    -- normally we should see 3 or 4 idle words between EOF and SOF...
    -- 

    sender_fsm_proc: process(fclk)
    begin
        if rising_edge(fclk) then
            if (reset='1') then
                state <= rst;
            else
                case(state) is
                    when rst =>
                        state <= idle;
                    when idle => 
                        if (fifo_ae="0000000") then -- all fifos have some stuff, start transmitting
                            state <= sof; 
                            sample_count <= "0000";
                        else
                            state <= idle;                            
                        end if;
                    when sof =>
                        state <= hdr0;
                    when hdr0 =>
                        state <= hdr1;
                    when hdr1 =>
                        state <= hdr2;
                    when hdr2 =>
                        state <= hdr3;
                    when hdr3 =>
                        state <= hdr4;
                    when hdr4 =>
                        state <= dat0;
                    when dat0 =>
                        state <= dat1;
                    when dat1 =>
                        state <= dat2;
                    when dat2 =>
                        state <= dat3;
                    when dat3 =>
                        state <= dat4;
                    when dat4 =>
                        state <= dat5;
                    when dat5 =>
                        state <= dat6;
                    when dat6 =>
                        if (sample_count="1111") then -- we have cycled through dat0-dat6 states 16 times
                            state <= trailer;
                        else
                            sample_count <= std_logic_vector(unsigned(sample_count) + 1);
                            state <= dat0;
                        end if;
                    when trailer =>
                        state <= eof;
                    when eof =>
                        state <= idle;
                    when others => 
                        state <= rst;
                end case;
            end if;
        end if;
    end process sender_fsm_proc;

    fifo_rden <= '1' when (state=dat6) else '0';

    -- now form the output stream

    d <= X"0000003C" when (state=sof) else -- sof of frame word = D0.0 & D0.0 & D0.0 & K28.1
         link & slot_id & crate_id & detector_id & version_id when (state=hdr0) else
         fifo_timestamp(31 downto 0)  when (state=hdr1) else
         fifo_timestamp(63 downto 32) when (state=hdr2) else
         X"00" & ch3_id & ch2_id & ch1_id & ch0_id when (state=hdr3) else
         X"DEADBEEF" when (state=hdr4) else
         fifo_do(0)  when (state=dat0) else
         fifo_do(1)  when (state=dat1) else
         fifo_do(2)  when (state=dat2) else
         fifo_do(3)  when (state=dat3) else
         fifo_do(4)  when (state=dat4) else
         fifo_do(5)  when (state=dat5) else
         fifo_do(6)  when (state=dat6) else
         X"FFFFFFFF" when (state=trailer) else 
         ("0000" & crc20 & X"DC") when (state=eof) else -- end of frame word = D0.0 & D0.0 & D0.0 & K28.6
         X"000000BC"; -- send idle word = D0.0 & D0.0 & D0.0 & K28.5

    k <= "0001" when (state=sof) else 
         "0001" when (state=eof) else
         "0001" when (state=idle) else
         "0000";

    -- CRC generator is calculated over the DAPHNE frame, not including the SOF and EOF words

    crc_calc <=  '1' when (state=hdr0) else
                 '1' when (state=hdr1) else
                 '1' when (state=hdr2) else
                 '1' when (state=hdr3) else
                 '1' when (state=hdr4) else
                 '1' when (state=dat0) else
                 '1' when (state=dat1) else
                 '1' when (state=dat2) else
                 '1' when (state=dat3) else
                 '1' when (state=dat4) else
                 '1' when (state=dat5) else
                 '1' when (state=dat6) else
                 '1' when (state=trailer) else
                 '0';

    crc_reset <= '1' when (state=idle) else '0';

    crc_inst: CRC_OL
       generic map (Nbits => 32, CRC_Width => 20, G_Poly => X"8359f", G_InitVal => X"FFFFF")
       port map(
         reset => crc_reset,
         clk => fclk,
         calc => crc_calc,
         din => d,
         crc => crc20);

    -- register the outputs

    outreg_proc: process(fclk)
    begin
        if rising_edge(fclk) then
            dout_reg <= d;
            kout_reg <= k;
        end if;
    end process outreg_proc;

    dout <= dout_reg;
    kout <= kout_reg;

end dstr4_arch;
