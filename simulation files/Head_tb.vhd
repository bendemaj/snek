----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 04/11/2026 03:42:35 PM
-- Design Name: Snake
-- Module Name: Head_tb - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Testbench for module head
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
use work.local_types.all;

entity Head_tb is
    --  Port ( );
end Head_tb;

architecture Testbench of Head_tb is

    constant CLK_PERIOD        : time      := 10 ns;
    signal clk_sig             : std_logic := '0';
    signal run_head_sig        : std_logic := '0';
    signal head_done_sig       : std_logic := '0';
    signal head_death_sig      : std_logic := '0';
    signal logic_reset_sig     : std_logic := '0';
    signal tile_coord_head_sig : coordinate_t;
    signal tile_from_GA_sig    : game_tile;
    signal tile_to_GA_sig      : game_tile;
    signal set_tile_sig        : std_ulogic;
    signal head_pos_out_sig    : coordinate_t;
    signal direction_sig       : direction_t;

    signal trigger_head : std_logic := '0';

    signal last_tile_coord_head_sig : coordinate_t;
    signal last_head_done_sig       : std_logic := '0';
    signal last_head_death_sig      : std_logic := '0';
    signal last_tile_to_GA_sig      : game_tile;
    signal last_set_tile_sig        : std_ulogic;

    signal empty_tile : game_tile;
    signal head_tile  : game_tile;
    signal body_tile  : game_tile;
    signal tail_tile  : game_tile;
    signal apple_tile : game_tile;
begin

    empty_tile.is_tail  <= '0';
    empty_tile.is_head  <= '0';
    empty_tile.is_apple <= '0';
    empty_tile.is_body  <= '0';
    empty_tile.parent.y <= "000000";
    empty_tile.parent.x <= "000000";
    head_tile.is_head   <= '1';
    head_tile.is_tail   <= '0';
    head_tile.is_apple  <= '0';
    head_tile.is_body   <= '0';
    head_tile.parent.y  <= "000000";
    head_tile.parent.x  <= "000000";
    body_tile.is_head   <= '0';
    body_tile.is_tail   <= '0';
    body_tile.is_apple  <= '0';
    body_tile.is_body   <= '1';
    tail_tile.is_tail   <= '1';
    tail_tile.is_head   <= '0';
    tail_tile.is_apple  <= '0';
    tail_tile.is_body   <= '0';
    tail_tile.parent.y  <= "000000";
    tail_tile.parent.x  <= "000000";
    apple_tile.is_apple <= '1';
    apple_tile.is_tail  <= '0';
    apple_tile.is_head  <= '0';
    apple_tile.is_body  <= '0';
    apple_tile.parent.y <= "000000";
    apple_tile.parent.x <= "000000";

    Head_inst : entity work.Head
        generic map(
            AREAHEIGHT => 48,
            AREAWIDTH  => 64
        )
        port map(
            clk        => clk_sig,       --: in std_ulogic;
            run_head   => run_head_sig,  --: in std_ulogic;
            head_done  => head_done_sig, --: out std_ulogic;
            head_death => head_death_sig,
            reset      => logic_reset_sig,
            --gamearea manipulation/information interface
            tile_coord   => tile_coord_head_sig, --: out coordinate;
            tile_from_GA => tile_from_GA_sig,    --: in game_tile;
            tile_to_GA   => tile_to_GA_sig,      --: out game_tile;
            --get_tile   => get_tile_sig,   --: out std_ulogic;
            set_tile => set_tile_sig, --: out std_ulogic;
            --gamesstate information
            head_pos => head_pos_out_sig, --: in coordinate;
            --button direction
            direction => direction_sig--, --: in buttondir--;
            -- debug_last_dir => debug_last_dir_sig
        );

    clk_gen : process
    begin
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
    end process;

    -- 0. In a the beninging                                                    >> IDLE
    -- 1. Calculate next head postition                                         >> CALC_NEXT_HEAD_POS
    -- 2. Check next head position (wall) | request tile next head position     >> CHECK_NEXT_HEAD_POS
    -- 3. wait                                                                  >> CYCLE_WASTE
    -- 4. wait                                                                  >> WASTE_CYCLE
    -- 5. Check death at next head position                                     >> CHECK_DEATH
    -- 6. Write Next Head Position                                              >> SET_NEXT_HEAD
    -- 7. Write Last Head Position as body                                      >> SET_BODY
    -- 8. Set Done sig                                                          >> DONE
    -- Ferner liefen:                                                           >> DEATH

    kickoff_head : process (head_done_sig, head_death_sig, trigger_head)
    begin
        if run_head_sig = '0' and trigger_head = '1' then
            run_head_sig <= '1';
        elsif run_head_sig = '1' and head_death_sig = '1' then
            run_head_sig <= '0';
        elsif run_head_sig = '1' and head_done_sig = '1' then
            run_head_sig <= '0';
        else
            run_head_sig <= run_head_sig;
        end if;
    end process;

    --   -- Stimulus Prozess
    stimulus : process
    begin
        -- Reset Phase
        wait for 0 ns;
        logic_reset_sig  <= '1';
        tile_from_GA_sig <= empty_tile;
        wait for CLK_PERIOD * 5;
        logic_reset_sig <= '0';
        -- Should still be in reset state
        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" and set_tile_sig = '0' and tile_to_GA_sig = empty_tile and head_done_sig = '0' and head_death_sig = '0' report "Reset not in Reset State" severity error;
        wait for CLK_PERIOD * 5;
        -- should be in IDLE state
        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" and set_tile_sig = '0' and tile_to_GA_sig = empty_tile and head_done_sig = '0' and head_death_sig = '0' report "Not in IDLE state" severity error;
        wait for CLK_PERIOD * 5;

        -- Test valid RIGHT
        report "Test: Valid RIGHT";
        body_tile.parent.x <= "001101";
        body_tile.parent.y <= "010101";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= body_tile;
        direction_sig      <= RIGHT;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";
        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test valid RIGHT eating apple
        report "Test: Valid RIGHT eating apple";
        body_tile.parent.x <= "001101";
        body_tile.parent.y <= "010101";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= body_tile;
        direction_sig      <= RIGHT;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";
        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= apple_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test invalid LEFT after RIGHT
        report "Test: invalid LEFT after RIGHT";
        body_tile.parent.x <= "001101";
        body_tile.parent.y <= "010101";
        wait for 0ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= body_tile;
        direction_sig      <= LEFT;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";
        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = "001101" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test valid DOWN
        report "Test: Valid DOWN";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010110";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= body_tile;
        direction_sig      <= DOWN;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test invalid UP after DOWN
        report "Test: invalid UP after DOWN";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010110";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= body_tile;
        direction_sig      <= UP;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test valid LEFT
        report "Test: Valid LEFT";
        body_tile.parent.x <= "001011";
        body_tile.parent.y <= "010101";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= body_tile;
        direction_sig      <= LEFT;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test invalid RIGHT after LEFT
        report "Test: invalid RIGHT after LEFT";
        body_tile.parent.x <= "001011";
        body_tile.parent.y <= "010101";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= RIGHT;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test valid UP
        report "Test: Valid UP";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= UP;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test invalid DOWN (after UP)
        report "Test: invalid DOWN after UP";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= DOWN;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= empty_tile;
        wait until set_tile_sig = '1' for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            if tile_to_GA_sig = head_tile then
                assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                wait until tile_to_GA_sig = body_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = body_tile then
                    assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timeout - not setting body_tile after head_tile has been set" severity failure;
                end if;
            else
                assert tile_coord_head_sig.x = "001100" and tile_coord_head_sig.y = "010101" report "Writing body to wrong position" severity error;
                assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                assert tile_to_GA_sig = body_tile report "Not a body tile" severity error;
                wait until tile_to_GA_sig = head_tile for 50 * CLK_PERIOD;
                if tile_to_GA_sig = head_tile then
                    assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Writing head to wrong position" severity error;
                    assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
                    assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
                else
                    report "Testbench Timout - not setting head_tile after body_tile has been set" severity failure;
                end if;
            end if;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;
        wait until head_done_sig = '1';

        assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
        assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
        assert head_death_sig = '0' report "Death and done are not possible at the same time" severity error;

        wait for CLK_PERIOD * 10;

        -- Test DEATH by BODY
        report "Test: DEATH by BODY";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= UP;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= body_tile;
        wait until (set_tile_sig = '1' or head_death_sig = '1') for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            report "Setting tile even though snake should die" severity error;
        elsif head_death_sig = '1' then
            assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
            assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
            assert head_done_sig = '0' report "Death and done are not possible at the same time" severity error;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;

        wait for CLK_PERIOD * 10;
        -- Test DEATH by TAIL
        report "Test: DEATH by TAIL";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait for 0 ns;
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= UP;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";

        wait until tile_coord_head_sig.x /= "000000" and tile_coord_head_sig.y /= "000000";
        trigger_head <= '0';
        assert tile_coord_head_sig.x = body_tile.parent.x and tile_coord_head_sig.y = body_tile.parent.y report "Wrong coordinate for next head position" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = empty_tile report "tile_to_GA not empty for check" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        last_tile_coord_head_sig <= tile_coord_head_sig;
        last_head_done_sig       <= head_done_sig;
        last_head_death_sig      <= head_death_sig;
        last_tile_to_GA_sig      <= tile_to_GA_sig;
        last_set_tile_sig        <= set_tile_sig;
        wait for CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        wait for 0.1 * CLK_PERIOD;
        assert tile_coord_head_sig = last_tile_coord_head_sig report "Coordinate changed during read operation" severity error;
        assert set_tile_sig = '0' report "Setting tile without checking" severity error;
        assert tile_to_GA_sig = last_tile_to_GA_sig report "tile_to_GA changed during read operation" severity error;
        assert head_done_sig = '0' report "Head cannot be done during pos check" severity error;
        assert head_death_sig = '0' report "Head cannot die during pos check" severity error;
        wait for 0.9 * CLK_PERIOD;
        tile_from_GA_sig <= tail_tile;
        wait until (set_tile_sig = '1' or head_death_sig = '1') for 50 * CLK_PERIOD;
        if set_tile_sig = '1' then
            report "Setting tile even though snake should die" severity error;
        elsif head_death_sig = '1' then
            assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
            assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
            assert head_done_sig = '0' report "Death and done are not possible at the same time" severity error;
        else
            report "Testbench Timeout - never setting tile" severity failure;
        end if;

        wait for CLK_PERIOD * 10;

        -- Test DEATH by WALL (x overflow)
        report "Test: DEATH by WALL (x overflow)";
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= RIGHT;
        head_pos_out_sig.x <= "111111";
        head_pos_out_sig.y <= "010101";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";

        wait until head_death_sig = '1' for 50 * CLK_PERIOD;
        if head_death_sig = '1' then
            assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
            assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
            assert head_done_sig = '0' report "Death and done are not possible at the same time" severity error;
        else
            report "Testbench Timeout - Snake did not die" severity failure;
        end if;

        wait for CLK_PERIOD * 10;

        -- Set last direction to left by actually turning left
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= LEFT;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "010101";
        body_tile.parent.x <= "001011";
        body_tile.parent.y <= "010101";
        wait for CLK_PERIOD * 11;
        trigger_head <= '0';
        wait for CLK_PERIOD * 10;

        -- Test DEATH by WALL (y overflow)
        report "Test: DEATH by WALL (y overflow)";
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= DOWN;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "101111";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait until head_death_sig = '1' for 50 * CLK_PERIOD;
        if head_death_sig = '1' then
            assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
            assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
            assert head_done_sig = '0' report "Death and done are not possible at the same time" severity error;
        else
            report "Testbench Timeout - Snake did not die" severity failure;
        end if;
        wait for CLK_PERIOD * 10;

        -- Test DEATH by WALL (x underflow)
        report "Test: DEATH by WALL (x underflow)";
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= LEFT;
        head_pos_out_sig.x <= "000000";
        head_pos_out_sig.y <= "010101";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait until head_death_sig = '1' for 50 * CLK_PERIOD;
        if head_death_sig = '1' then
            assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
            assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
            assert head_done_sig = '0' report "Death and done are not possible at the same time" severity error;
        else
            report "Testbench Timeout - Snake did not die" severity failure;
        end if;
        wait for CLK_PERIOD * 10;

        -- Test DEATH by WALL (y underflow)
        report "Test: DEATH by WALL (y underflow)";
        trigger_head       <= '1';
        tile_from_GA_sig   <= empty_tile;
        direction_sig      <= UP;
        head_pos_out_sig.x <= "001100";
        head_pos_out_sig.y <= "000000";
        body_tile.parent.x <= "001100";
        body_tile.parent.y <= "010100";
        wait until head_death_sig = '1' for 50 * CLK_PERIOD;
        if head_death_sig = '1' then
            assert tile_coord_head_sig.x = "000000" and tile_coord_head_sig.y = "000000" report "Position should be empty in/after done" severity error;
            assert tile_to_GA_sig = empty_tile report "Should send empty tile during done state";
            assert head_done_sig = '0' report "Death and done are not possible at the same time" severity error;
        else
            report "Testbench Timeout - Snake did not die" severity failure;
        end if;

        wait for CLK_PERIOD * 10;

        -- Simulation beenden
        wait for CLK_PERIOD * 10;
        std.env.stop;
    end process;

    -- monitor : process (clk_sig)
    -- begin
    --     -- assert direction_sig = LEFT report "T'was left" severity warning;
    -- end process;
end Testbench;
