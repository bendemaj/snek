----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 03/20/2026 11:36:18 AM
-- Design Name: Snake
-- Module Name: types - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Typedefinitions for Snake Project
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
package local_types is
    type color is record
        red   : std_ulogic_vector(3 downto 0);
        green : std_ulogic_vector(3 downto 0);
        blue  : std_ulogic_vector(3 downto 0);
    end record color;

    type coordinate_t is record
        x : std_ulogic_vector(5 downto 0);
        y : std_ulogic_vector(5 downto 0);
    end record coordinate_t;

    type game_tile is record
        is_tail  : std_ulogic;
        is_head  : std_ulogic;
        is_apple : std_ulogic;
        is_body  : std_ulogic;
        parent   : coordinate_t;
    end record game_tile;

    type GameAreaInterface is record
        tile_coord   : coordinate_t;
        tile_from_GA : game_tile;
        tile_to_GA   : game_tile;
        set_tile     : std_ulogic;
    end record GameAreaInterface;

    type GameAreaInterfaceVector is array (natural range <>) of GameAreaInterface;

    type direction_t is (UP, DOWN, LEFT, RIGHT);

    type gamescore is record
        a : std_ulogic_vector(3 downto 0);
        b : std_ulogic_vector(3 downto 0);
        c : std_ulogic_vector(3 downto 0);
        d : std_ulogic_vector(3 downto 0);
    end record gamescore;
end package;
