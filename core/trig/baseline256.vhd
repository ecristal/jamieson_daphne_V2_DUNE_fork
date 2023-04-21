-- baseline256.vhd
-- compute average baseline level over 256 samples
-- note that after reset baseline will default to maximum (0x3FFF) until
-- 256 samples have been analyzed, then it will take on a 
-- regular real average value.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baseline256 is
port(
    clock: in  std_logic;
    reset: in  std_logic;
    din:   in  std_logic_vector(13 downto 0);
    baseline: out std_logic_vector(13 downto 0)
);
end baseline256;

architecture baseline_arch of baseline256 is

    signal baseline_reg: std_logic_vector(13 downto 0) := (others=>'1');
    signal sum_reg: std_logic_vector(21 downto 0) := (others=>'0');
    signal count_reg: std_logic_vector(7 downto 0) := X"00";

begin

    -- On each clock cycle add din to sum_reg. after 256 cycles, 
    -- copy sum_reg/256 into baseline_reg and clear sum_reg. repeat forever.

    process(clock)
    begin
        if rising_edge(clock) then
            if (reset='1') then
                count_reg <= X"00";
                sum_reg <= (others=>'0');
                baseline_reg <= (others=>'1');
            else
                count_reg <= std_logic_vector( unsigned(count_reg) + 1 );
                if (count_reg=X"FF") then
                    sum_reg <= "00000000" & din;
                    baseline_reg <= sum_reg(21 downto 8);
                else
                    sum_reg <= std_logic_vector( unsigned(sum_reg) + unsigned(din) );
                end if; 
            end if;
        end if;
    end process;

    baseline <= baseline_reg;

end baseline_arch;
