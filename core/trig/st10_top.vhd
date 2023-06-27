-- st10_top.vhd
-- DAPHNE core logic, top level, self triggered mode sender
-- ten AFE channels -> one FELIX output
-- 
-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.daphne2_package.all;

entity st10_top is
generic( link_id: std_logic_vector(5 downto 0)  := "000000" ); -- this is the OUTPUT link ID that goes into the header
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
    ch_id: in array_10x6_type; -- input channel IDs

    fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
    dout: out std_logic_vector(31 downto 0);
    kout: out std_logic_vector(3 downto 0)
);
end st10_top;

architecture st10_top_arch of st10_top is
 
    type state_type is (rst, scan, dump, idle);
    signal state: state_type;

    signal sel_reg : std_logic_vector(3 downto 0);

    signal fifo_ae: std_logic_vector(9 downto 0);
    signal fifo_rden: std_logic_vector(9 downto 0);
    signal fifo_ready: std_logic;

    type array_10x32_type is array(9 downto 0) of std_logic_vector(31 downto 0);
    type array_10x4_type  is array(9 downto 0) of std_logic_vector( 3 downto 0);
    signal fifo_do: array_10x32_type;
    signal fifo_ko: array_10x4_type;

    signal d, dout_reg: std_logic_vector(31 downto 0);
    signal k, kout_reg: std_logic_vector( 3 downto 0);

    component stc is
    generic( link_id: std_logic_vector(5 downto 0) := "000000"; ch_id: std_logic_vector(5 downto 0) := "000000" );
    port(
        reset: in std_logic;

        threshold: in std_logic_vector(13 downto 0);
        slot_id: in std_logic_vector(3 downto 0);
        crate_id: in std_logic_vector(9 downto 0);
        detector_id: in std_logic_vector(5 downto 0);
        version_id: in std_logic_vector(5 downto 0);
		enable: in std_logic;
		
        aclk: in std_logic; -- AFE clock 62.500 MHz
        timestamp: in std_logic_vector(63 downto 0);
    	afe_dat: in std_logic_vector(13 downto 0);
        --ch_id: in std_logic_vector(5 downto 0);
        fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
        fifo_rden: in std_logic;
        fifo_ae: out std_logic;
        fifo_do: out std_logic_vector(31 downto 0);
        fifo_ko: out std_logic_vector( 3 downto 0)
      );
    end component;

begin

    -- make 10 STC machines to monitor 10 AFE channels

    gen_stc: for i in 9 downto 0 generate

        stc_inst: stc 
        generic map( link_id => link_id, ch_id => std_logic_vector(to_unsigned(i,6)) ) 
        port map(
            reset => reset,

            threshold => threshold,
            slot_id => slot_id,
            crate_id => crate_id,
            detector_id => detector_id,
            version_id => version_id,

            aclk => aclk,
            timestamp => timestamp,
        	afe_dat => afe_dat(i),
            enable => '1',
            fclk => fclk,
            fifo_rden => fifo_rden(i),
            fifo_ae => fifo_ae(i),
            fifo_do => fifo_do(i),
            fifo_ko => fifo_ko(i)
          );

    end generate gen_stc;

    -- fifo read enable and fifo flag selection

    fifo_ready <= '1' when (sel_reg="0000" and fifo_ae(0)='1') else 
                  '1' when (sel_reg="0001" and fifo_ae(1)='1') else 
                  '1' when (sel_reg="0010" and fifo_ae(2)='1') else 
                  '1' when (sel_reg="0011" and fifo_ae(3)='1') else 
                  '1' when (sel_reg="0100" and fifo_ae(4)='1') else 
                  '1' when (sel_reg="0101" and fifo_ae(5)='1') else 
                  '1' when (sel_reg="0110" and fifo_ae(6)='1') else 
                  '1' when (sel_reg="0111" and fifo_ae(7)='1') else 
                  '1' when (sel_reg="1000" and fifo_ae(8)='1') else 
                  '1' when (sel_reg="1001" and fifo_ae(9)='1') else 
                  '0';

    fifo_rden(0) <= '1' when (sel_reg="0000" and state=dump) else '0';
    fifo_rden(1) <= '1' when (sel_reg="0001" and state=dump) else '0';
    fifo_rden(2) <= '1' when (sel_reg="0010" and state=dump) else '0';
    fifo_rden(3) <= '1' when (sel_reg="0011" and state=dump) else '0';
    fifo_rden(4) <= '1' when (sel_reg="0100" and state=dump) else '0';
    fifo_rden(5) <= '1' when (sel_reg="0101" and state=dump) else '0';
    fifo_rden(6) <= '1' when (sel_reg="0110" and state=dump) else '0';
    fifo_rden(7) <= '1' when (sel_reg="0111" and state=dump) else '0';
    fifo_rden(8) <= '1' when (sel_reg="1000" and state=dump) else '0';
    fifo_rden(9) <= '1' when (sel_reg="1001" and state=dump) else '0';

    -- FSM scans all STC machines in round robin manner, looking for a FIFO almost empty "fifo_ae" flag set. when it finds
    -- this, it reads one complete frame from that machine, then sends a few idles, then returns to scanning again.

    fsm_proc: process(fclk)
    begin
        if rising_edge(fclk) then
            if (reset='1') then
                state <= rst;
            else
                case(state) is

                    when rst =>
                        sel_reg <= "0000";
                        state <= scan;

                    when scan => 
                        if (fifo_ready='1') then
                            state <= dump;
                        else
                            if (sel_reg="1001") then
                                sel_reg <= "0000";
                            else
                                sel_reg <= std_logic_vector(unsigned(sel_reg)+1);
                            end if;
                            state <= scan;
                        end if;

                    when dump =>
                        if (k="0001" and d(7 downto 0)=X"DC") then -- this the EOF word, done reading from this STC
                            state <= idle;
                        else
                            state <= dump;
                        end if;

                    when idle => -- send one idle word and resume scanning...
                        if (sel_reg="1001") then
                            sel_reg <= "0000";
                        else
                            sel_reg <= std_logic_vector(unsigned(sel_reg)+1);
                        end if;
                        state <= scan;

                    when others => 
                        state <= rst;
                end case;
            end if;
        end if;
    end process fsm_proc;

    -- output muxes

    d <= fifo_do(0) when (sel_reg="0000" and state=dump) else
         fifo_do(1) when (sel_reg="0001" and state=dump) else
         fifo_do(2) when (sel_reg="0010" and state=dump) else
         fifo_do(3) when (sel_reg="0011" and state=dump) else
         fifo_do(4) when (sel_reg="0100" and state=dump) else
         fifo_do(5) when (sel_reg="0101" and state=dump) else
         fifo_do(6) when (sel_reg="0110" and state=dump) else
         fifo_do(7) when (sel_reg="0111" and state=dump) else
         fifo_do(8) when (sel_reg="1000" and state=dump) else
         fifo_do(9) when (sel_reg="1001" and state=dump) else
         X"000000BC"; -- idle word

    k <= fifo_ko(0) when (sel_reg="0000" and state=dump) else
         fifo_ko(1) when (sel_reg="0001" and state=dump) else
         fifo_ko(2) when (sel_reg="0010" and state=dump) else
         fifo_ko(3) when (sel_reg="0011" and state=dump) else
         fifo_ko(4) when (sel_reg="0100" and state=dump) else
         fifo_ko(5) when (sel_reg="0101" and state=dump) else
         fifo_ko(6) when (sel_reg="0110" and state=dump) else
         fifo_ko(7) when (sel_reg="0111" and state=dump) else
         fifo_ko(8) when (sel_reg="1000" and state=dump) else
         fifo_ko(9) when (sel_reg="1001" and state=dump) else
         "0001"; -- idle word

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

end st10_top_arch;
