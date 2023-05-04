-- testbench for the 4 channel DAPHNE streaming core design
-- free running timestamp and each channel is a two bit id and 12 bit counter
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

use work.daphne2_package.all;

entity dstr4_testbench is
end dstr4_testbench;

architecture dstr4_testbench_arch of dstr4_testbench is

component dstr4 is
generic( link_id: std_logic_vector(5 downto 0) := "000000" );
port(
    reset: in std_logic; -- async reset from uC
    mclk: in std_logic; -- master clock 62.5MHz
    slot_id:     std_logic_vector(3 downto 0);
    crate_id: std_logic_vector(9 downto 0);
    detector_id:   std_logic_vector(5 downto 0);
    version_id: std_logic_vector(5 downto 0);
    timestamp: in std_logic_vector(63 downto 0);
    afe_dat: in array_4x14_type; -- four AFE ADC channels
    ch_id: in array_4x6_type; -- the channel ID number    fclk: in std_logic; -- transmit clock to FELIX 120.xxx MHz
    fclk: in std_logic; -- transmit clock to FELIX 120.237 MHz 
    dout: out std_logic_vector(31 downto 0);
    kout: out std_logic_vector(3 downto 0)	
  );
end component;

signal reset: std_logic := '1';

signal mclk: std_logic := '0';
signal timestamp: std_logic_vector(63 downto 0) := X"0000000000000000";
signal dat:  std_logic_vector(11 downto 0)     := X"000";
signal afe_dat0: std_logic_vector(13 downto 0) := "00000000000000";
signal afe_dat1: std_logic_vector(13 downto 0) := "00000000000000";
signal afe_dat2: std_logic_vector(13 downto 0) := "00000000000000";
signal afe_dat3: std_logic_vector(13 downto 0) := "00000000000000";

signal fclk: std_logic := '0';
signal kout: std_logic_vector(3 downto 0);
signal dout: std_logic_vector(31 downto 0);

constant slot_id: std_logic_vector(3 downto 0) := "0000";
constant crate_id: std_logic_vector(9 downto 0) := "0000000000";
constant detector_id: std_logic_vector(5 downto 0) := "000000";
constant version_id: std_logic_vector(5 downto 0) := "100000";

type sender_fsm_type is (rst, idle, sof, hdr0, hdr1, hdr2, hdr3, hdr4, dat0, dat1, dat2, dat3, dat4, dat5, dat6, trailer, eof);
signal state: sender_fsm_type := rst;

file outfile, raw_outfile: text;

begin

mclk <= not mclk after 8.000 ns; --  62.500 MHz
fclk <= not fclk after 4.158 ns; -- 120.237 MHz

reset <= '1', '0' after 96ns;

process
begin 
    wait until falling_edge(mclk);
    timestamp <= std_logic_vector(unsigned(timestamp) + 1);
    dat       <= std_logic_vector(unsigned(dat) + 1);
    afe_dat0  <= "00" & dat;
    afe_dat1  <= "01" & dat;
    afe_dat2  <= "10" & dat;
    afe_dat3  <= "11" & dat;
end process;

DUT: dstr4
generic map ( link_id => "000000" )
port map(
    reset => reset,
    mclk => mclk,
    timestamp => timestamp,
    slot_id => slot_id,
    crate_id => crate_id,
    detector_id => detector_id,
    version_id => version_id,
    ch_id(0) => "000000", 
    ch_id(1) => "000001", 
    ch_id(2) => "000010",
    ch_id(3) => "001001",
	afe_dat(0) => afe_dat0,
	afe_dat(1) => afe_dat1,
	afe_dat(2) => afe_dat2,
	afe_dat(3) => afe_dat3,
    fclk => fclk,
    kout => kout,
    dout => dout
);

-- unpack and dump the output to console

file_open(outfile, "output.txt", write_mode);
file_open(raw_outfile, "raw_output.txt", write_mode);

process -- pretty print the output record to file...
    variable oline, rawline: line;
    variable framecount: integer;
    variable d0: std_logic_vector(31 downto 0);
    variable d1: std_logic_vector(31 downto 0);
    variable d2: std_logic_vector(31 downto 0);
    variable d3: std_logic_vector(31 downto 0);
    variable d4: std_logic_vector(31 downto 0);
    variable d5: std_logic_vector(31 downto 0);
    variable d6: std_logic_vector(31 downto 0);
    variable dvec: std_logic_vector(223 downto 0);

begin
    wait until falling_edge(fclk);

    hwrite(rawline, dout); -- simple hex dump to file...
    writeline(raw_outfile, rawline);

    case state is
        when rst =>
            if (kout="0001" and dout=X"000000BC") then
                state <= idle;
            end if;
        when idle =>
            if (kout="0001" and dout=X"0000003C") then
                write(oline, "SOF: ");
                hwrite(oline, dout);
                writeline(outfile, oline);
                state <= hdr0;
            else
                write(oline, "IDLE");
                writeline(outfile, oline); 
            end if;
        when hdr0 =>
            write(oline, "Header0: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= hdr1;
        when hdr1 =>
            write(oline, "Header1: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= hdr2;
        when hdr2 =>
            write(oline, "Header2: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= hdr3;
        when hdr3 =>
            write(oline, "Header3: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= hdr4;
        when hdr4 =>
            write(oline, "Header4: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= dat0;
            framecount := 0;
        when dat0 =>
            d0 := dout;
            state <= dat1;
        when dat1 =>
            d1 := dout;
            state <= dat2;
        when dat2 =>
            d2 := dout;
            state <= dat3;
        when dat3 =>
            d3 := dout;
            state <= dat4;
        when dat4 =>
            d4 := dout;
            state <= dat5;
        when dat5 =>
            d5 := dout;
            state <= dat6;
        when dat6 =>
            d6 := dout;
            dvec := d6 & d5 & d4 & d3 & d2 & d1 & d0;
            for i in 15 downto 0 loop
                hwrite(oline, "00" & dvec((i*14)+13 downto i*14));
                write(oline, " ");
            end loop;
            writeline(outfile, oline);
            if (framecount=15) then
                state <= trailer;
            else
                state <= dat0;
                framecount := integer(framecount+1);
            end if;
        when trailer =>
            write(oline, "Trailer: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= eof;
        when eof =>
            write(oline, "EOF: ");
            hwrite(oline, dout);
            writeline(outfile, oline);
            state <= idle;
        when others => 
            state <= rst;
    end case;

end process;

end dstr4_testbench_arch;
