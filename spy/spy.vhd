-- spy.vhd
-- DAPHNE spy buffer for one link AFE output, 4k deep
-- reset only resets the trigger logic, it does not erase the buffer contents
-- triggered on low to to high pulse, then writes next 4096 words into buffer, stops and waits for next trigger
-- add delay elements to produce 64 deep delay for fixed pretrigger
-- Jamieson Olsen <jamieson@fnal.gov>

-- port A = 4k x 16 (write) clock domain from afe front end
-- port B = 4k x 16 (read)  connected to gigabit ethernet interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

use work.daphne2_package.all;

entity spy is
port(

    clka:  in std_logic;  
    reset: in std_logic; -- reset sync to clka
    trig:  in std_logic; -- trigger pulse sync to clka
    dia:   in std_logic_vector(15 downto 0); -- data bus from AFE channel
    a_in:  in std_logic_vector(4 downto 0); -- shift register pre-trigger amount selector
    clkb:  in  std_logic;
    addrb: in  std_logic_vector(11 downto 0);
    dob:   out std_logic_vector(15 downto 0)

  );
end spy;

architecture spy_arch of spy is

    signal reset_reg: std_logic;
    signal addr_reg: std_logic_vector(11 downto 0);
    signal dia_reg, dia_q, dia_delayed:  std_logic_vector(15 downto 0);
    signal dia_q0, dia_q1, dia_q2, dia_q3, dia_q4:  std_logic_vector(15 downto 0);
    signal dia_q5, dia_q6, dia_q7, dia_q8, dia_q9:  std_logic_vector(15 downto 0);
    signal dia_q10, dia_q11, dia_q12, dia_q13, dia_q14:  std_logic_vector(15 downto 0);
    signal we_reg:   std_logic_vector(0 downto 0);

    type state_type is (rst, wait4trig, store, wait4done);
    signal state: state_type;

begin

    -- input delay elements for fixed pre-trigger cascade two 32 bit shift registers

    gendelay: for i in 15 downto 0 generate

        srlc32e_0_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia(i),
            q => dia_q0(i),
            q31 => open   
        );

        srlc32e_1_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q0(i),
            q => dia_q1(i),
            q31 => open  
        );

        srlc32e_2_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q1(i),
            q => dia_q2(i),
            q31 => open  
        );

        srlc32e_3_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q2(i),
            q => dia_q3(i),
            q31 => open   
        );

        srlc32e_4_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q3(i),
            q => dia_q4(i),
            q31 => open   
        );

        srlc32e_5_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q4(i),
            q => dia_q5(i),
            q31 => open   
        );

        srlc32e_6_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q5(i),
            q => dia_q6(i),
            q31 => open   
        );

        srlc32e_7_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q6(i),
            q => dia_q7(i),
            q31 => open   
        );

        srlc32e_8_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q7(i),
            q => dia_q8(i),
            q31 => open   
        );

        srlc32e_9_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q8(i),
            q => dia_q9(i),
            q31 => open   
        );

        srlc32e_10_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q9(i),
            q => dia_q10(i),
            q31 => open   
        );

        srlc32e_11_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q10(i),
            q => dia_q11(i),
            q31 => open   
        );

        srlc32e_12_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q11(i),
            q => dia_q12(i),
            q31 => open   
        );

        srlc32e_13_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q12(i),
            q => dia_q13(i),
            q31 => open   
        );

        srlc32e_14_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q13(i),
            q => dia_q14(i),
            q31 => open   
        );
    
        srlc32e_15_inst : srlc32e
        port map(
            clk => clka,
            ce => '1',
            a => a_in,
            d => dia_q14(i),
            q => dia_delayed(i),
            q31 => open  
        );

    end generate gendelay;

    -- FSM to wait for trigger pulse and drive addr_reg (write pointer) and we_reg

    fsm_proc: process(clka)
    begin
        if rising_edge(clka) then

            reset_reg <= reset;

            if (reset_reg='1') then
                --dia_reg  <= X"0000";
                we_reg   <= "0";
                --addr_reg <= X"000";
                state    <= rst;
            else
                dia_reg <= dia_delayed;

                case state is
                    when rst =>
                        state <= wait4trig;
                    when wait4trig =>
                        if (trig='1') then
                            state <= store;
                            we_reg <= "1";
                        else
                            state <= wait4trig;
                            we_reg <= "0";
                            addr_reg <= X"000";
                        end if;
                    when store =>
                        if (addr_reg=X"FFF") then
                            state <= wait4done;
                            we_reg <= "0";
                        else
                            state <= store;
                            addr_reg <= std_logic_vector(unsigned(addr_reg) + 1);
                            we_reg <= "1";
                        end if;
                    when wait4done =>
                        if (trig='0') then
                            state <= wait4trig;
                        else
                            state <= wait4done;
                        end if;
                    when others => 
                        state <= rst;    
    
                end case;
            end if;
        end if;
    end process fsm_proc;

    -- instantiate four 18k true dual port blockrams to create a single 4k x 16 buffer
    -- port A driven by the trigger logic in this module, for writing
    -- port B is controlled by the GbE interface, for reading

    genbuffer: for i in 3 downto 0 generate

        ramb_inst: BRAM_TDP_MACRO -- true dual port blockram macro both ports are 4k x 4
        generic map (
            BRAM_SIZE => "18Kb", -- Target BRAM, "18Kb" or "36Kb"
            DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
            DOA_REG => 0, -- Optional port A output register (0 or 1)
            DOB_REG => 0, -- Optional port B output register (0 or 1)
            INIT_A => X"000000000", -- Initial values on A output port
            INIT_B => X"000000000", -- Initial values on B output port
            INIT_FILE => "NONE",
            READ_WIDTH_A => 4,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
            READ_WIDTH_B => 4,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
            SIM_COLLISION_CHECK => "NONE", -- Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
            SRVAL_A => X"000000000",   -- Set/Reset value for A port output   
            SRVAL_B => X"000000000",   -- Set/Reset value for B port output   
            WRITE_MODE_A => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
            WRITE_MODE_B => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
            WRITE_WIDTH_A => 4, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
            WRITE_WIDTH_B => 4  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
        )
        port map(
             CLKA   => clka,
             ADDRA  => addr_reg(11 downto 0),
             DIA    => dia_reg( ((i*4)+3) downto (i*4) ),
             ENA    => we_reg(0),
             RSTA   => '0',
             WEA    => we_reg,
             REGCEA => '1',
             DOA    => open,
    
             CLKB   => clkb,
             ADDRB  => addrb(11 downto 0),
             DIB    => "0000",
             ENB    => '1',
             RSTB   => '0',
             WEB    => "0",
             REGCEB => '1',
             DOB    => dob( ((i*4)+3) downto (i*4) )
            );

    end generate;

-- ramb16_sx_sy is a seriously old primitive, don't use it.

--    genbuffer: for i in 3 downto 0 generate
--        ramb_inst: ramb16_s4_s4 -- TDP blockram "older style" primitive both ports are 4k x 4
--        generic map (
--            SIM_COLLISION_CHECK => "NONE",
--            INIT_A => X"0",
--            INIT_B => X"0",
--            SRVAL_A => X"0",
--            SRVAL_B => X"0",
--            WRITE_MODE_A => "WRITE_FIRST",
--            WRITE_MODE_B => "WRITE_FIRST"
--        )
--        port map(
--             clka  => clka,
--             addra => addr_reg(11 downto 0),
--             dia   => dia_reg( ((i*4)+3) downto (i*4) ),
--             ena   => we_reg,
--             ssra  => '0',
--             wea   => we_reg,
--             clkb  => clkb,
--             addrb => addrb(11 downto 0),
--             dib   => "0000",
--             enb   => '1',
--             ssrb  => '0',
--             web   => '0',
--             dob   => dob( ((i*4)+3) downto (i*4) )
--            );
--    end generate;

end spy_arch;
