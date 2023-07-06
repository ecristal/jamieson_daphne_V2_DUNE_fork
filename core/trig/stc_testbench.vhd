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


type state_type is (idle, dump);
signal state: state_type;

signal ae: std_logic;
signal rden: std_logic := '0';
signal d: std_logic_vector(31 downto 0);
signal k: std_logic_vector(3 downto 0);

file file_handler : text open write_mode is "output.txt";

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

    afe_dat <= std_logic_vector( to_unsigned(8000,14) );
    wait for 1000ns;
    afe_dat <= std_logic_vector( to_unsigned(8001,14) );
    wait for 1000ns;
    afe_dat <= std_logic_vector( to_unsigned(8002,14) );
    wait for 1000ns;
    afe_dat <= std_logic_vector( to_unsigned(8001,14) );
    wait for 1000ns;
    afe_dat <= std_logic_vector( to_unsigned(8000,14) );
    wait for 1000ns;

    for i in 1 to 100 loop
        wait until falling_edge(aclk);
        afe_dat <= std_logic_vector( to_unsigned(8000+i,14) );
    end loop;

    -- BOOM here's the pulse -- fast falling edge!

    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(5000,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(3000,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(2000,14) );
	
	-- now a slow rise back up to baseline....
	
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(5000,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(6000,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(6500,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(6800,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(7000,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(7200,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(7500,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(7700,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(7900,14) );
    wait until falling_edge(aclk);
    afe_dat <= std_logic_vector( to_unsigned(8000,14) );
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
    fifo_rden => rden,
    fifo_ae => ae,
    fifo_do => d,
    fifo_ko => k
);

-- wait until the output FIFO has an event, now pull it out and write to file

dump_proc: process(fclk)
variable row : line;
begin
    if rising_edge(fclk) then

        case(state) is

            when idle =>
                if (ae='1') then -- start reading...
                    state <= dump;
                    rden <= '1';
                else
                    state <= idle;
                end if;

            when dump =>
                if (k="0001" and d(7 downto 0)=X"DC") then -- this the EOF word, done reading from std output fifo
                    state <= idle;
                    rden <= '0';
                    hwrite(row, d); -- get that last line
                    writeline(file_handler, row);
                else
                    state <= dump;
                    hwrite(row, d);
                    writeline(file_handler, row);
                end if;

            when others =>
                state <= idle;

        end case;
    end if;
end process dump_proc;




end stc_testbench_arch;