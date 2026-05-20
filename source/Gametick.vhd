----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 03/20/2026 02:28:52 PM
-- Design Name: Snake
-- Module Name: Gametick - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Create slower clock for Gamelogic
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
entity Gametick is
    port (
        clk  : in std_ulogic; --100 MHz * 10 = 1 GHz / 125 = 8 MHz / 125 = 64 kHz
        tick : out std_ulogic
    );
end Gametick;

architecture Behavioral of Gametick is

    signal counter : unsigned(12 downto 0) := (others => '0');
    signal tickgen : std_ulogic            := '0';
begin

    --Target: 10 Hz
    --Input 64 kHz
    --64 kHz / 10 Hz = 6400
    --Toggle every 3200 
    tick_process : process (clk)
    begin
        if rising_edge(clk) then
            if counter = 3199 then
                counter <= (others => '0');
                tickgen <= not tickgen;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process tick_process;

    tick <= tickgen;

end Behavioral;
