----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 05/07/2026 05:09:06 PM
-- Design Name: Snake
-- Module Name: VGA_tb - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Testbench for module VGA
-- 
-- Dependencies: 
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

entity VGA_tb is
    --  Port ( );
end VGA_tb;

architecture testbench of VGA_tb is
    constant CLK_PERIOD        : time      := 10 ns;
    signal clk_sig             : std_logic := '0';
    signal vga_clk_sig         : std_logic := '0';
    signal next_pix_x_sig      : std_ulogic_vector(9 downto 0);
    signal next_pix_y_sig      : std_ulogic_vector(9 downto 0);
    signal last_next_pix_x_sig : std_ulogic_vector(9 downto 0) := (others => '0');
    signal last_next_pix_y_sig : std_ulogic_vector(9 downto 0) := (others => '0');
    signal pix_col_sig         : color;
    signal last_pix_col_sig    : color;
    signal VGA_R               : std_ulogic_vector (3 downto 0);
    signal VGA_G               : std_ulogic_vector (3 downto 0);
    signal VGA_B               : std_ulogic_vector (3 downto 0);
    signal VGA_HS              : std_ulogic;
    signal VGA_VS              : std_ulogic;

begin

    VGA_inst : entity work.vga
        port map(
            --clk
            clk => clk_sig,
            --pixel input
            pxl_in => pix_col_sig,
            --pixel request
            next_pix_x => next_pix_x_sig,
            next_pix_y => next_pix_y_sig,
            --VGA Connector
            VGA_R  => VGA_R,
            VGA_G  => VGA_G,
            VGA_B  => VGA_B,
            VGA_HS => VGA_HS,
            VGA_VS => VGA_VS
        );

    clk_gen : process
    begin
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_sig     <= '1';
        vga_clk_sig <= '1';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_sig     <= '1';
        vga_clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
    end process;

    --   -- Stimulus Prozess
    stimulus : process
    begin
        -- Reset Phase
        pix_col_sig.red   <= "0010";
        pix_col_sig.green <= "0100";
        pix_col_sig.blue  <= "0001";
        wait for CLK_PERIOD * 4 * 10;
        pix_col_sig.red   <= "1010";
        pix_col_sig.green <= "1100";
        pix_col_sig.blue  <= "1001";
        wait for CLK_PERIOD * 4 * 646;
        assert VGA_HS = '1' report "Horizontal Sync not high" severity error;
        wait for CLK_PERIOD * 4;
        assert VGA_HS = '0' report "Horizontal Sync not gone low" severity error;
        wait for CLK_PERIOD * 4 * 95;
        assert VGA_HS = '0' report "Horizontal Sync low too short" severity error;
        wait for CLK_PERIOD * 4;
        assert VGA_HS = '1' report "Horizontal Sync low too long" severity error;
        wait for CLK_PERIOD * 4 * 46;
        assert unsigned(next_pix_y_sig) = 1 report "Vertical addition wrong" severity error;
        -- Simulation beenden
        wait for CLK_PERIOD * 10000;
        std.env.stop;
    end process;

    monitor : process (vga_clk_sig)
    begin
        if rising_edge(vga_clk_sig) then
            last_next_pix_x_sig <= next_pix_x_sig;
            last_next_pix_y_sig <= next_pix_y_sig;
            last_pix_col_sig    <= pix_col_sig;
            if UNSIGNED(next_pix_x_sig) < 640 and unsigned(next_pix_x_sig) > 0 then
                assert unsigned(next_pix_x_sig) = (unsigned(last_next_pix_x_sig) + 1) report "Addition not working" severity error;
                assert VGA_R = last_pix_col_sig.red and VGA_G = last_pix_col_sig.green and VGA_B = last_pix_col_sig.blue report "Wrong color to output" severity error;
            end if;
        end if;
    end process;

end testbench;
