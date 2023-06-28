-- inmux testbench for redirect register module in core
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

library unisim;
use unisim.vcomponents.all;

use work.daphne2_package.all;

entity inmux_testbench is
end inmux_testbench;

architecture inmux_testbench_arch of inmux_testbench is

component inmux is
port(
    clock: in std_logic;
    reset: in std_logic;
    we: in std_logic;
    addr: in std_logic_vector(3 downto 0);
    din: in std_logic_vector(5 downto 0);
    dout: out std_logic_vector(5 downto 0);
    afe_dat: in array_5x9x14_type; 
    data_out: out array_4x4x14_type;
    chid_out: out array_4x4x6_type
);
end component;

signal reset: std_logic := '1';
signal clock: std_logic := '0';
signal we: std_logic := '0';
signal addr: std_logic_vector(3 downto 0) := "0000";
signal din: std_logic_vector(5 downto 0) := "000000";
signal afe_dat: array_5x9x14_type;

begin

clock <= not clock after 8.000 ns; --  62.500 MHz
reset <= '1', '0' after 96ns;

gen_a: for a in 4 downto 0 generate
    gen_c: for c in 8 downto 0 generate
        afe_dat(a)(c) <= std_logic_vector( to_unsigned(10*a+c,14) );
    end generate gen_c;
end generate gen_a;

writereg_proc: process
begin 

    wait for 500ns;

    wait until falling_edge(clock);
    we <= '1';
    addr <= "0001";
    din <= "000111";
    
    wait until falling_edge(clock);
    we <= '0';
    addr <= "0000";
    din <= "000000";

    wait;

end process writereg_proc;

DUT: inmux
port map(
    reset => reset,
    clock => clock,
    we => we,
    addr => addr,
    din => din,
	afe_dat => afe_dat
);

end inmux_testbench_arch;