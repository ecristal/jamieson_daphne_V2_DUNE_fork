-- testbench for the single self triggered core module STC
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

library unisim;
use unisim.vcomponents.all;

entity stc_testbench is
end stc_testbench;

architecture stc_testbench_arch of stc_testbench is

component stc is
generic( link_id: std_logic_vector(5 downto 0) := "000000"; ch_id: std_logic_vector(5 downto 0) := "000000" );
port(
    reset: in std_logic;

    slot_id: std_logic_vector(3 downto 0);
    crate_id: std_logic_vector(9 downto 0);
    detector_id: std_logic_vector(5 downto 0);
    version_id: std_logic_vector(5 downto 0);
    threshold: std_logic_vector(13 downto 0);

    aclk: in std_logic; -- AFE clock 62.500 MHz
    timestamp: in std_logic_vector(63 downto 0);
	afe_dat: in std_logic_vector(13 downto 0);
    enable: in std_logic;

    fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
    fifo_rden: in std_logic;
    fifo_ae: out std_logic;
    fifo_do: out std_logic_vector(31 downto 0);
    fifo_ko: out std_logic_vector( 3 downto 0)
  );
end component;

signal reset: std_logic := '1';
signal aclk: std_logic := '0';
signal timestamp: std_logic_vector(63 downto 0) := X"0000000000000000";
signal afe_dat: std_logic_vector(13 downto 0) := "00000001000000";
signal fclk: std_logic := '0';

constant threshold: std_logic_vector(13 downto 0) := "00000100000000";

begin

aclk <= not aclk after 8.000 ns; --  62.500 MHz
fclk <= not fclk after 4.158 ns; -- 120.237 MHz

reset <= '1', '0' after 96ns;

ts_proc: process 
begin 
    wait until falling_edge(aclk);
    timestamp <= std_logic_vector(unsigned(timestamp) + 1);
end process ts_proc;

waveform_proc: process
begin 

    -- establish baseline level mid scale ish

    afe_dat <= "10000000000000";
    wait for 1000ns;
    afe_dat <= "10000000000011";
    wait for 1000ns;
    afe_dat <= "10000000000001";
    wait for 1000ns;
    afe_dat <= "10000000000111";
    wait for 1000ns;
    afe_dat <= "10000000001111";
    wait for 1000ns;

    -- here's the fast pulse -- this is a positive pulse, but we should make this negative...

    wait until falling_edge(aclk);
    afe_dat <= "11111011100001";
    wait until falling_edge(aclk);
    afe_dat <= "11111010110111";
    wait until falling_edge(aclk);
    afe_dat <= "11111101011011";
    wait until falling_edge(aclk);
    afe_dat <= "10000001110101";

    -- return to baseline level 

    wait until falling_edge(aclk);
    afe_dat <= "10000000000000";
    wait;

end process waveform_proc;

DUT: stc
generic map( link_id => "000001", ch_id => "000011" )
port map(
    reset => reset,

    slot_id => "0000",
    crate_id => "0000000000",
    detector_id => "000000",
    version_id => "100000",
    threshold => threshold, -- abs trigger level = 256 counts over baseline

    aclk => aclk,
    timestamp => timestamp,
	afe_dat => afe_dat,
    enable => '1',

    fclk => fclk,
    fifo_rden => '0'
);

end stc_testbench_arch;
