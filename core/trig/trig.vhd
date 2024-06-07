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
    reset: in std_logic;
    enable: in std_logic;
    din: in std_logic_vector(13 downto 0); -- raw AFE data
    dout: out std_logic_vector(13 downto 0); -- Filtered AFE data
    adhoc: in std_logic_vector(7 downto 0); -- command value for adhoc trigger
    threshold: in std_logic_vector(13 downto 0); -- trigger threshold relative to baseline
    filter_output_selector: in std_logic_vector(1 downto 0);
    baseline: in std_logic_vector(13 downto 0); -- average signal level computed over past 256 samples
    triggered: out std_logic;
    trigsample: out std_logic_vector(13 downto 0); -- the sample that caused the trigger
    ti_trigger: in std_logic_vector(7 downto 0);
    ti_trigger_stbr: in std_logic
);
end trig;

architecture trig_arch of trig is

    signal din0, din1, din2: std_logic_vector(13 downto 0) := "00000000000000";
    signal dout_filter: std_logic_vector(15 downto 0);
    signal trig_thresh, trigsample_reg: std_logic_vector(13 downto 0);
    signal triggered_i, triggered_i_module, triggered_dly32_i: std_logic;

    component hpf_pedestal_recovery_filter_trigger is
    port(
        clk: in std_logic;
        reset: in std_logic;
        n_1_reset: in std_logic;
        enable: in std_logic;
        threshold_value: in std_logic_vector(31 downto 0);
        output_selector: in std_logic_vector(1 downto 0);
        trigger_ch_enable: in std_logic;
        baseline: in std_logic_vector(15 downto 0);
        x:  in std_logic_vector(15 downto 0);
        trigger_output: out std_logic;
        y: out std_logic_vector(15 downto 0)
    );
    end component;

begin

    trig_pipeline_proc: process(clock)
    begin
        if rising_edge(clock) then
            din0 <= din;  -- latest sample
            din1 <= din0; -- previous sample
            din2 <= din1; -- previous previous sample
        end if;
    end process trig_pipeline_proc;

    -- user-specified threshold is RELATIVE to the calculated average baseline level
    -- NOTE that the trigger pulse is NEGATIVE going! We want to SUBTRACT the relative 
    -- threshold from the calculated average baseline level.

    -- trig_thresh <= std_logic_vector( unsigned(baseline) - unsigned(threshold) );

    -- our super basic trigger condition is this: one sample ABOVE trig_thresh followed by two samples
    -- BELOW trig_thresh.

    filter_trigger_inst: hpf_pedestal_recovery_filter_trigger
    port map(
        clk => clock,
        reset => reset,
        n_1_reset => '0',
        enable => enable,
        threshold_value => (X"0000" & "00" & threshold),
        output_selector => filter_output_selector,
        trigger_ch_enable => enable,
        baseline => ("00" & baseline),
        x => ("00" & din),
        trigger_output => triggered_i_module,
        y => dout_filter
    );
    -- triggered_i <= '1' when ( ti_trigger=adhoc and ti_trigger_stbr='1' ) else '0';

    -- trigger goes between the adhoc conditions or the Milano self trigger condition
    triggered_i <= '1' when ( ( ti_trigger=adhoc and ti_trigger_stbr='1' ) or ( triggered_i_module = '1' ) ) else '0';
    
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

    -- capture the sample that caused the trigger 

    samplecap_proc: process(clock)
    begin
        if rising_edge(clock) then
            if (triggered_i='1') then
                trigsample_reg <= din0;
            end if;
        end if;    
    end process samplecap_proc;

    trigsample <= trigsample_reg;
    dout <= dout_filter(13 downto 0);

end trig_arch;
