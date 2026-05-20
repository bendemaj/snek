----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 03/20/2026 02:28:52 PM
-- Design Name: Snake
-- Module Name: GameAreaMux - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Multiplex the Gamearea Interface
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

entity GameAreaMux is
    generic (
        NumInterfaces : natural := 1
    );

    port (
        GameAreaPort  : inout GameAreaInterface;
        SelectionPort : inout GameAreaInterfaceVector(NumInterfaces - 1 downto 0);
        Selection     : in std_ulogic_vector(NumInterfaces - 1 downto 0)

    );
end GameAreaMux;

architecture Behavioral of GameAreaMux is

    -- Default/idle values for the GameArea bus
    constant origin : coordinate_t := (
        x => (others => '0'),
        y => (others => '0')
    );

    constant empty_tile : game_tile := (
        is_tail  => '0',
        is_head  => '0',
        is_apple => '0',
        is_body  => '0',
        parent   => origin
    );

begin

    mux_proc : process (Selection, SelectionPort)
    begin
        GameAreaPort.tile_coord <= origin;
        GameAreaPort.tile_to_GA <= empty_tile;
        GameAreaPort.set_tile   <= '0';

        for i in 0 to NumInterfaces - 1 loop
            if Selection(i) = '1' then
                GameAreaPort.tile_coord <= SelectionPort(i).tile_coord;
                GameAreaPort.tile_to_GA <= SelectionPort(i).tile_to_GA;
                GameAreaPort.set_tile   <= SelectionPort(i).set_tile;
            end if;
        end loop;
    end process mux_proc;

    outputs : for i in 0 to NumInterfaces - 1 generate

        SelectionPort(i).tile_from_GA <= GameAreaPort.tile_from_GA when Selection(i) = '1'
    else
        empty_tile;
    end generate;
end Behavioral;
