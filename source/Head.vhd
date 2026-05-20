library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.local_types.all;

entity Head is
    generic (
        AREAWIDTH  : natural := 64;
        AREAHEIGHT : natural := 48
    );
    port (
        clk        : in std_ulogic;
        run_head   : in std_ulogic;
        head_done  : out std_ulogic;
        head_death : out std_ulogic;
        reset      : in std_ulogic;
        --gamearea manipulation/information interface
        tile_coord   : out coordinate_t;
        tile_from_GA : in game_tile;
        tile_to_GA   : out game_tile;
        set_tile     : out std_ulogic;
        --gamesstate information
        head_pos : in coordinate_t;
        --button direction
        direction : in direction_t
    );
end Head;

architecture Behavioral of Head is

end Behavioral;
