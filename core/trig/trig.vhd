-- trig.vhd
-- an example of a very simple trigger algorithm for the DAPHNE self triggered mode
--
-- baseline, threshold, din are UNSIGNED 
--
-- this determination is very simple and requires only a few clock cycles
-- however, this module adds extra pipeline stages so that the overall latency 
-- is 64 clocks. this is done to allow for more advanced triggers.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity trig is
port(
    clock: in std_logic;
    din: in std_logic_vector(13 downto 0); -- raw AFE data
    threshold: in std_logic_vector(13 downto 0); -- trigger threshold relative to baseline
    baseline: in std_logic_vector(13 downto 0); -- average signal level computed over past 256 samples
    triggered: out std_logic
);
end trig;

architecture trig_arch of trig is

    signal din0, din1, din2: std_logic_vector(13 downto 0) := "00000000000000";
    signal absthresh: std_logic_vector(13 downto 0);
    signal triggered_i, triggered_dly32_i: std_logic;

begin

    trig_pipeline_proc: process(clock)
    begin
        if rising_edge(clock) then
            din0 <= din;
            din1 <= din0;
            din2 <= din1;
        end if;
    end process trig_pipeline_proc;

    -- user-specified threshold is RELATIVE to the calculated average baseline level

    absthresh <= std_logic_vector( unsigned(baseline) + unsigned(threshold) );

    triggered_i <= '1' when ( din2>absthresh and din1<absthresh and din0<absthresh ) else '0';

    -- add in some fake/synthetic latency, adjust it so total trigger latency is 64 clocks

    srlc32e_0_inst : srlc32e
    port map(
        clk => clock,
        ce  => '1',
        a   => "11111",
        d   => triggered_i,
        q   => open,
        q31 => triggered_dly32_i
    );

    srlc32e_1_inst : srlc32e
    port map(
        clk => clock,
        ce  => '1',
        a   => "11011",  -- adjust this delay to make overall latency = 64
        d   => triggered_dly32_i,
        q   => triggered,
        q31 => open
    );

end trig_arch;
