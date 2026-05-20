----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 05/06/2026 03:24:20 PM
-- Design Name: Snake
-- Module Name: LFSR_tb - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Testbench for the LFSR Module
-- 
-- Dependencies: Snake project
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 1.0 - First working version
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.local_types.all;

entity LFSR_tb is
    --  Port ( );
end LFSR_tb;

architecture testbench of LFSR_tb is
    constant CLK_PERIOD    : time      := 10 ns;
    signal clk_sig         : std_logic := '0';
    signal logic_reset_sig : std_logic := '0';
    signal past_rst        : std_logic := '0';
    signal seed_sig        : std_ulogic_vector(11 downto 0);
    signal random_sig      : std_ulogic_vector(11 downto 0);
    signal random_sig_past : std_ulogic_vector(11 downto 0) := (others => '0');
    signal started         : std_logic                      := '0';
begin

    LFSR_inst : entity work.LFSR
        port map(
            clk    => clk_sig,
            reset  => logic_reset_sig,
            seed   => seed_sig,
            random => random_sig
        );

    clk_gen : process
    begin
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        started <= '1';
    end process;

    --   -- Stimulus Prozess
    stimulus : process
    begin
        -- Reset Phase
        logic_reset_sig <= '1';
        seed_sig        <= "000000000100";
        wait for CLK_PERIOD * 5;
        wait for 0 ns;
        logic_reset_sig <= '0';
        -- Test Phase
        report "Begin Test, seed: 000000000100";
        wait for CLK_PERIOD;
        assert random_sig = "000000000100" report "Wrong Value Step 1" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000000001000" report "Wrong Value Step 2" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000000010000" report "Wrong Value Step 3" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000000100000" report "Wrong Value Step 4" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000001000000" report "Wrong Value Step 5" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000010000000" report "Wrong Value Step 6" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000100000000" report "Wrong Value Step 7" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "001000000000" report "Wrong Value Step 8" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "010000000000" report "Wrong Value Step 9" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "100000000000" report "Wrong Value Step 10" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "001000010001" report "Wrong Value Step 11" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "010000100010" report "Wrong Value Step 12" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "100001000100" report "Wrong Value Step 13" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "001010011001" report "Wrong Value Step 14" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "010100110010" report "Wrong Value Step 15" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "101001100100" report "Wrong Value Step 16" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "011011011001" report "Wrong Value Step 17" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "110110110010" report "Wrong Value Step 18" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "100101110101" report "Wrong Value Step 19" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000011111011" report "Wrong Value Step 20" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000111110110" report "Wrong Value Step 21" severity error;
        report "End Test, seed: 000000000100";

        report "Begin Test, reset, seed: 001010011101";
        wait for CLK_PERIOD;
        seed_sig <= "001010011101";
        wait for 0 ns; -- Force Delta Step for past_rst to correctly assign
        logic_reset_sig <= '1';
        wait for CLK_PERIOD * 5;
        wait for 0 ns; -- Force Delta Step for past_rst to correctly assign
        logic_reset_sig <= '0';

        report "Begin Test, seed: 001010011101";
        wait for CLK_PERIOD;
        assert random_sig = "001010011101" report "Wrong Value Step 1" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "010100111010" report "Wrong Value Step 2" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "101001110100" report "Wrong Value Step 3" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "011011111001" report "Wrong Value Step 4" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "110111110010" report "Wrong Value Step 5" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "100111110101" report "Wrong Value Step 6" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000111111011" report "Wrong Value Step 7" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "001111110110" report "Wrong Value Step 8" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "011111101100" report "Wrong Value Step 9" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "111111011000" report "Wrong Value Step 10" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "110110100001" report "Wrong Value Step 11" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "100101010011" report "Wrong Value Step 12" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000010110111" report "Wrong Value Step 13" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000101101110" report "Wrong Value Step 14" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "001011011100" report "Wrong Value Step 15" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "010110111000" report "Wrong Value Step 16" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "101101110000" report "Wrong Value Step 17" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "010011110001" report "Wrong Value Step 18" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "100111100010" report "Wrong Value Step 19" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "000111010101" report "Wrong Value Step 20" severity error;
        wait for CLK_PERIOD;
        assert random_sig = "001110101010" report "Wrong Value Step 21" severity error;
        report "End Test, seed: 001010011101";

        wait for CLK_PERIOD * 50;

        -- Simulation beenden
        wait for CLK_PERIOD * 10;
        std.env.stop;
    end process;

    monitor : process (clk_sig)
    begin
        if rising_edge(clk_sig) then
            random_sig_past <= random_sig;
            past_rst        <= logic_reset_sig;
            -- Expect value to immediately reset but get the first random value only one clock after reset is gone
            if (logic_reset_sig = '1' or past_rst = '1') and started = '1' then
                assert random_sig = seed_sig report "Reset wrong: " & integer'image(to_integer(unsigned(random_sig))) & " should be: " & integer'image(to_integer(unsigned(seed_sig))) severity error;
            else
                assert random_sig /= seed_sig report "Random might be wrong: " & integer'image(to_integer(unsigned(random_sig))) & " should not be seed: " & integer'image(to_integer(unsigned(seed_sig))) severity warning;
                assert random_sig /= random_sig_past report "Random wrong: " & integer'image(to_integer(unsigned(random_sig))) & " did not change from: " & integer'image(to_integer(unsigned(random_sig_past))) severity error;
            end if;
        end if;
    end process;

end testbench;

-- LFSR REFERENCE WEBSITE: https://www.omnicalculator.com/math/linear-feedback-shift-register

-- FOR SEED: 000000000100
-- Message: 000000000100 at step 0
-- Message: 000000001000 at step 1
-- Message: 000000010000 at step 2
-- Message: 000000100000 at step 3
-- Message: 000001000000 at step 4
-- Message: 000010000000 at step 5
-- Message: 000100000000 at step 6
-- Message: 001000000000 at step 7
-- Message: 010000000000 at step 8
-- Message: 100000000000 at step 9
-- Message: 001000010001 at step 10
-- Message: 010000100010 at step 11
-- Message: 100001000100 at step 12
-- Message: 001010011001 at step 13
-- Message: 010100110010 at step 14
-- Message: 101001100100 at step 15
-- Message: 011011011001 at step 16
-- Message: 110110110010 at step 17
-- Message: 100101110101 at step 18
-- Message: 000011111011 at step 19
-- Message: 000111110110 at step 20

-- FOR SEED: 001010011101
-- Message: 001010011101 at step 0
-- Message: 010100111010 at step 1
-- Message: 101001110100 at step 2
-- Message: 011011111001 at step 3
-- Message: 110111110010 at step 4
-- Message: 100111110101 at step 5
-- Message: 000111111011 at step 6
-- Message: 001111110110 at step 7
-- Message: 011111101100 at step 8
-- Message: 111111011000 at step 9
-- Message: 110110100001 at step 10
-- Message: 100101010011 at step 11
-- Message: 000010110111 at step 12
-- Message: 000101101110 at step 13
-- Message: 001011011100 at step 14
-- Message: 010110111000 at step 15
-- Message: 101101110000 at step 16
-- Message: 010011110001 at step 17
-- Message: 100111100010 at step 18
-- Message: 000111010101 at step 19
-- Message: 001110101010 at step 20
