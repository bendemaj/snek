----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 03/20/2026 02:28:52 PM
-- Design Name: Snake
-- Module Name: Buttons - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Handle Buttoninput
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

entity Buttons is
    port (
        clk            : in std_ulogic;
        tick           : in std_ulogic;
        reset          : in std_ulogic;
        button_up      : in std_ulogic;
        button_down    : in std_ulogic;
        button_left    : in std_ulogic;
        button_right   : in std_ulogic;
        direction      : out direction_t;
        button_pressed : out std_ulogic
    );
end Buttons;

architecture Behavioral of Buttons is

    -- direction calculation and buttonpress
    signal buttonpress       : std_ulogic;
    signal direction_reg     : direction_t;
    signal direction_pre_reg : direction_t;

    -- sync to clk
    signal tick_d1              : std_ulogic;
    signal tick_d2              : std_ulogic;
    signal tick_rising          : std_ulogic;
    signal button_up_d1         : std_ulogic;
    signal button_up_d2         : std_ulogic;
    signal button_up_rising     : std_ulogic;
    signal button_up_falling    : std_ulogic;
    signal button_down_d1       : std_ulogic;
    signal button_down_d2       : std_ulogic;
    signal button_down_rising   : std_ulogic;
    signal button_down_falling  : std_ulogic;
    signal button_left_d1       : std_ulogic;
    signal button_left_d2       : std_ulogic;
    signal button_left_rising   : std_ulogic;
    signal button_left_falling  : std_ulogic;
    signal button_right_d1      : std_ulogic;
    signal button_right_d2      : std_ulogic;
    signal button_right_rising  : std_ulogic;
    signal button_right_falling : std_ulogic;

    -- debouncing for buttons
    signal lockout_up    : std_ulogic            := '0';
    signal lockout_down  : std_ulogic            := '0';
    signal lockout_left  : std_ulogic            := '0';
    signal lockout_right : std_ulogic            := '0';
    signal counter_up    : unsigned(16 downto 0) := (others => '0');
    signal counter_down  : unsigned(16 downto 0) := (others => '0');
    signal counter_left  : unsigned(16 downto 0) := (others => '0');
    signal counter_right : unsigned(16 downto 0) := (others => '0');

begin

    sync_tick : process (clk)
    begin
        if rising_edge(clk) then
            tick_d1 <= tick;
            tick_d2 <= tick_d1;
        end if;
    end process sync_tick;

    tick_rising <= tick_d1 and not tick_d2;

    sync_buttons : process (clk)
    begin
        if rising_edge(clk) then
            button_up_d1    <= button_up;
            button_up_d2    <= button_up_d1;
            button_down_d1  <= button_down;
            button_down_d2  <= button_down_d1;
            button_left_d1  <= button_left;
            button_left_d2  <= button_left_d1;
            button_right_d1 <= button_right;
            button_right_d2 <= button_right_d1;
        end if;
    end process sync_buttons;

    button_up_rising    <= button_up_d1 and not button_up_d2;
    button_down_rising  <= button_down_d1 and not button_down_d2;
    button_left_rising  <= button_left_d1 and not button_left_d2;
    button_right_rising <= button_right_d1 and not button_right_d2;

    button_up_falling    <= not button_up_d1 and button_up_d2;
    button_down_falling  <= not button_down_d1 and button_down_d2;
    button_left_falling  <= not button_left_d1 and button_left_d2;
    button_right_falling <= not button_right_d1 and button_right_d2;

    debouncer : process (clk)
    begin
        if rising_edge(clk) then
            if button_up_falling = '1' then
                lockout_up <= '1';
                counter_up <= (others => '0');
            elsif counter_up = "1111111111111111" then
                lockout_up <= '0';
            else
                counter_up <= counter_up + 1;
            end if;
            if button_down_falling = '1' then
                lockout_down <= '1';
                counter_down <= (others => '0');
            elsif counter_down = "1111111111111111" then
                lockout_down <= '0';
            else
                counter_down <= counter_down + 1;
            end if;
            if button_left_falling = '1' then
                lockout_left <= '1';
                counter_left <= (others => '0');
            elsif counter_left = "1111111111111111" then
                lockout_left <= '0';
            else
                counter_left <= counter_left + 1;
            end if;
            if button_right_falling = '1' then
                lockout_right <= '1';
                counter_right <= (others => '0');
            elsif counter_right = "1111111111111111" then
                lockout_right <= '0';
            else
                counter_right <= counter_right + 1;
            end if;
        end if;
    end process debouncer;

    prepare_direction : process (clk)
    begin
        if rising_edge(clk) then
            if button_up_rising = '1' and lockout_up = '0' then
                direction_pre_reg <= UP;
            elsif button_down_rising = '1' and lockout_down = '0' then
                direction_pre_reg <= DOWN;
            elsif button_left_rising = '1' and lockout_left = '0' then
                direction_pre_reg <= LEFT;
            elsif button_right_rising = '1' and lockout_right = '0' then
                direction_pre_reg <= RIGHT;
            else
                direction_pre_reg <= direction_pre_reg;
            end if;
        end if;
    end process prepare_direction;

    buttonpress_process : process (clk, reset)
    begin
        if reset = '1' then
            buttonpress <= '0';
        elsif rising_edge(clk) then
            if button_up_rising = '1' or button_down_rising = '1' or button_left_rising = '1' or button_right_rising = '1' then
                buttonpress <= '1';
            end if;
        end if;
    end process buttonpress_process;

    direction_process : process (clk)
    begin
        if rising_edge(clk) then
            if tick_rising = '1' then
                direction_reg <= direction_pre_reg;
            end if;
        end if;
    end process direction_process;

    direction      <= direction_reg;
    button_pressed <= buttonpress;

end Behavioral;
