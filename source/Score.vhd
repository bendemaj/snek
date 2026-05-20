----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 04/12/2026 05:43:50 PM
-- Design Name: Snake
-- Module Name: Score - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Count Scores for lifetime and apple intake / 7-Segment-Control
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

entity Score is
    port (
        clk          : in std_ulogic;
        slow_clk     : in std_ulogic;
        reset        : in std_ulogic;
        apple_placed : in std_ulogic;
        tick         : in std_ulogic;
        SEG          : out std_ulogic_vector (6 downto 0);
        DP           : out std_ulogic;
        AN           : out std_ulogic_vector (7 downto 0)
    );
end Score;

architecture Behavioral of Score is
    signal HEX        : std_ulogic_vector(3 downto 0);
    signal LED        : std_ulogic_vector(6 downto 0);
    signal applescore : gamescore;
    signal timescore  : gamescore;
    signal count      : std_ulogic_vector (2 downto 0);

    signal tick_d1         : std_ulogic;
    signal tick_d2         : std_ulogic;
    signal tick_rising     : std_ulogic;
    signal slow_clk_d1     : std_ulogic;
    signal slow_clk_d2     : std_ulogic;
    signal slow_clk_rising : std_ulogic;
    signal apple_d1        : std_ulogic;
    signal apple_d2        : std_ulogic;
    signal apple_falling   : std_ulogic;

begin
    --HEX-to-seven-segment decoder
    --   HEX:   in    STD_LOGIC_VECTOR (3 downto 0);
    --   LED:   out   STD_LOGIC_VECTOR (6 downto 0);
    --
    -- segment encoinputg
    --      0
    --     ---
    --  5 |   | 1
    --     ---   <- 6
    --  4 |   | 2
    --     ---
    --      3

    DP  <= '1';
    SEG <= LED;

    sync : process (clk)
    begin
        if rising_edge(clk) then
            tick_d1     <= tick;
            tick_d2     <= tick_d1;
            apple_d1    <= apple_placed;
            apple_d2    <= apple_d1;
            slow_clk_d1 <= slow_clk;
            slow_clk_d2 <= slow_clk_d1;
        end if;
    end process sync;

    tick_rising     <= tick_d1 and not tick_d2;
    slow_clk_rising <= slow_clk_d1 and not slow_clk_d2;
    apple_falling   <= not apple_d1 and apple_d2;

    scoreoutput : process (clk, reset)
    begin
        if reset = '1' then
            count <= "000";
        elsif rising_edge(clk) and slow_clk_rising = '1' then
            with count select
                AN <= "11111110" when "000",
                "11111101" when "001",
                "11111011" when "010",
                "11110111" when "011",
                "11101111" when "100",
                "11011111" when "101",
                "10111111" when "110",
                "01111111" when "111",
                "11111111" when others;
            with count select
                HEX <= applescore.a when "000",
                applescore.b when "001",
                applescore.c when "010",
                applescore.d when "011",
                timescore.a when "100",
                timescore.b when "101",
                timescore.c when "110",
                timescore.d when "111",
                "0000" when others;
            count <= std_ulogic_vector(unsigned(count) + 1);
        end if;
    end process scoreoutput;

    with HEX select
        LED <= "1111001" when "0001", --1
        "0100100" when "0010",        --2
        "0110000" when "0011",        --3
        "0011001" when "0100",        --4
        "0010010" when "0101",        --5
        "0000010" when "0110",        --6
        "1111000" when "0111",        --7
        "0000000" when "1000",        --8
        "0010000" when "1001",        --9
        "0001000" when "1010",        --A
        "0000011" when "1011",        --b
        "1000110" when "1100",        --C
        "0100001" when "1101",        --d
        "0000110" when "1110",        --E
        "0001110" when "1111",        --F
        "1000000" when others;        --0

    timescore_process : process (clk, reset)
    begin
        if reset = '1' then
            timescore.a <= (others => '0');
            timescore.b <= (others => '0');
            timescore.c <= (others => '0');
            timescore.d <= (others => '0');
        elsif rising_edge(clk) and tick_rising = '1' then
            if timescore.a = "1001" then
                timescore.a <= "0000";
                if timescore.b = "1001" then
                    timescore.b <= "0000";
                    if timescore.c = "1001" then
                        timescore.c <= "0000";
                        timescore.d <= std_ulogic_vector(unsigned(timescore.d) + 1);
                    else
                        timescore.c <= std_ulogic_vector(unsigned(timescore.c) + 1);
                    end if;
                else
                    timescore.b <= std_ulogic_vector(unsigned(timescore.b) + 1);
                end if;
            else
                timescore.a <= std_ulogic_vector(unsigned(timescore.a) + 1);
            end if;
        end if;
    end process timescore_process;

    applescore_process : process (clk, reset)
    begin
        if reset = '1' then
            applescore.a <= (others => '0');
            applescore.b <= (others => '0');
            applescore.c <= (others => '0');
            applescore.d <= (others => '0');
        elsif rising_edge(clk) and apple_falling = '1' then
            if applescore.a = "1001" then
                applescore.a <= "0000";
                if applescore.b = "1001" then
                    applescore.b <= "0000";
                    if applescore.c = "1001" then
                        applescore.c <= "0000";
                        applescore.d <= std_ulogic_vector(unsigned(applescore.d) + 1);
                    else
                        applescore.c <= std_ulogic_vector(unsigned(applescore.c) + 1);
                    end if;
                else
                    applescore.b <= std_ulogic_vector(unsigned(applescore.b) + 1);
                end if;
            else
                applescore.a <= std_ulogic_vector(unsigned(applescore.a) + 1);
            end if;
        end if;
    end process applescore_process;

end Behavioral;
