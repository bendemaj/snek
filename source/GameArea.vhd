----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 03/20/2026 02:28:52 PM
-- Design Name: Snake
-- Module Name: GameArea - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Handle the GameArea
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

entity GameArea is
  generic (
    AREAWIDTH  : natural := 64;
    AREAHEIGHT : natural := 48;
    VGAx       : natural := 640;
    VGAy       : natural := 480
  );
  port (
    --clk just because
    clk : in std_ulogic;
    --interface for vga
    next_pix_x : in std_ulogic_vector (9 downto 0);
    next_pix_y : in std_ulogic_vector (9 downto 0);
    pix_col    : out color;
    --signal for reset
    rst_game : in std_ulogic;
    --gamearea manipulation/information interface
    tile_coord   : in coordinate_t;
    tile_from_GA : out game_tile;
    tile_to_GA   : in game_tile;
    set_tile     : in std_ulogic;
    --gamesstate information
    head_pos_out : out coordinate_t;
    tail_pos_out : out coordinate_t;
    apple_placed : out std_ulogic
  );
end GameArea;

architecture Behavioral of GameArea is
  signal head_pos         : coordinate_t;
  signal tail_pos         : coordinate_t;
  signal apple_pos        : coordinate_t;
  signal sig_apple_placed : std_ulogic;
  signal vga_tile_x       : std_ulogic_vector(5 downto 0);
  signal vga_tile_y       : std_ulogic_vector(5 downto 0);
  signal vga_tile         : game_tile;

begin

  head_pos_out <= head_pos;
  tail_pos_out <= tail_pos;
  apple_placed <= sig_apple_placed;

  vga_tile_x <= std_ulogic_vector(to_unsigned((to_integer(unsigned(next_pix_x)) * AREAWIDTH) / VGAx, 6));
  vga_tile_y <= std_ulogic_vector(to_unsigned((to_integer(unsigned(next_pix_y)) * AREAHEIGHT) / VGAy, 6));

  game_tiles : entity work.Game_tile_storage
    port map(
      clk   => clk,
      reset => rst_game,
      --interface for VGA read
      VGA_coord.x  => vga_tile_x,
      VGA_coord.y  => vga_tile_y,
      VGA_Tile_out => vga_tile,
      --interface for read/write
      tile_coord   => tile_coord,
      set_tile     => set_tile,
      tile_to_GA   => tile_to_GA,
      tile_from_GA => tile_from_GA--;

    );

  tile_process : process (clk)
  begin
    if rising_edge(clk) then
      if set_tile = '1' and rst_game = '0' then
        if tile_to_GA.is_tail = '1' and set_tile = '1' then
          tail_pos.x <= tile_coord.x;
          tail_pos.y <= tile_coord.y;
        elsif tile_to_GA.is_head = '1' and set_tile = '1' then
          head_pos.x <= tile_coord.x;
          head_pos.y <= tile_coord.y;
          if tile_coord.x = apple_pos.x and tile_coord.y = apple_pos.y then
            sig_apple_placed <= '0';
          end if;
        elsif tile_to_GA.is_apple = '1' and set_tile = '1' then
          apple_pos.x      <= tile_coord.x;
          apple_pos.y      <= tile_coord.y;
          sig_apple_placed <= '1';
        end if;
      end if;
    end if;
  end process tile_process;

  vga_out : process (clk)
  begin
    if rising_edge(clk) then

      if vga_tile.is_head = '1' then
        pix_col.red   <= "0000";
        pix_col.green <= "1111";
        pix_col.blue  <= "0000";
      elsif vga_tile.is_tail = '1' then
        pix_col.red   <= "0000";
        pix_col.green <= "0000";
        pix_col.blue  <= "1111";
      elsif vga_tile.is_apple = '1' then
        pix_col.red   <= "1111";
        pix_col.green <= "0000";
        pix_col.blue  <= "0000";
      elsif vga_tile.is_body = '1' then
        pix_col.red   <= "1111";
        pix_col.green <= "1111";
        pix_col.blue  <= "1111";
      else
        pix_col.red   <= "0010";
        pix_col.green <= "0010";
        pix_col.blue  <= "0010";

      end if;

    end if;

  end process vga_out;

end Behavioral;
