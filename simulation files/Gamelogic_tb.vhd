----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 05/06/2026 05:54:30 PM
-- Design Name: Snake
-- Module Name: Gamelogic_tb - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: Testbench for the Main Statemachine (Gamelogic)
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

entity Gamelogic_tb is
    --  Port ( );
end Gamelogic_tb;

architecture testbench of Gamelogic_tb is
    constant CLK_PERIOD       : time      := 10 ns;
    signal clk_sig            : std_logic := '0';
    signal tick_sig           : std_logic := '0';
    signal button_pressed_sig : std_logic := '0';
    signal logic_reset_sig    : std_logic := '0';
    signal past_rst           : std_logic := '0';
    signal run_reset_sig      : std_ulogic;
    signal run_init_sig       : std_ulogic;
    signal run_head_sig       : std_ulogic;
    signal run_tail_sig       : std_ulogic;
    signal run_apples_sig     : std_ulogic;
    signal reset_done_sig     : std_ulogic;
    signal init_done_sig      : std_ulogic;
    signal head_done_sig      : std_ulogic;
    signal tail_done_sig      : std_ulogic;
    signal apples_done_sig    : std_ulogic;
    signal head_death_sig     : std_ulogic;
begin

    Gamelogic_inst : entity work.Gamelogic
        port map(
            clk            => clk_sig,
            tick           => tick_sig,
            button_pressed => button_pressed_sig,
            reset          => logic_reset_sig,
            run_reset      => run_reset_sig,
            run_init       => run_init_sig,
            run_head       => run_head_sig,
            run_tail       => run_tail_sig,
            run_apples     => run_apples_sig,
            reset_done     => reset_done_sig,
            init_done      => init_done_sig,
            head_done      => head_done_sig,
            tail_done      => tail_done_sig,
            apples_done    => apples_done_sig,
            head_death     => head_death_sig
        );

    clk_gen : process
    begin
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
    end process;

    --   -- Stimulus Prozess
    stimulus : process
    begin
        -- Reset Phase
        logic_reset_sig <= '1';
        head_done_sig   <= '0';
        head_death_sig  <= '0';
        tail_done_sig   <= '0';
        apples_done_sig <= '0';
        init_done_sig   <= '0';
        reset_done_sig  <= '0';
        wait for CLK_PERIOD * 5;
        wait for 0 ns;
        logic_reset_sig <= '0';
        -- Test Phase
        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '1' and run_init_sig = '0' report "Reset not in Reset State" severity error;

        wait for CLK_PERIOD;
        reset_done_sig <= '1';
        wait for CLK_PERIOD;
        reset_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '1' report "Not in init state after reset done" severity error;

        wait for CLK_PERIOD;
        init_done_sig <= '1';
        wait for CLK_PERIOD;
        init_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in empty state after init done" severity error;

        wait for CLK_PERIOD * 10;

        button_pressed_sig <= '1';

        wait for CLK_PERIOD * 1;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in empty state after button pressed - should wait for tick" severity error;

        wait for CLK_PERIOD;

        tick_sig <= '1';

        wait for CLK_PERIOD * 2; -- Two clock cycles for synchroniser

        assert run_head_sig = '1' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in head state after idle tick" severity error;

        wait for CLK_PERIOD;
        head_done_sig <= '1';
        wait for CLK_PERIOD;
        head_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '1' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in tail state after head done" severity error;

        wait for CLK_PERIOD;
        tail_done_sig <= '1';
        wait for CLK_PERIOD;
        tail_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '1' and run_reset_sig = '0' and run_init_sig = '0' report "Not in apples state after tail done" severity error;

        wait for CLK_PERIOD;
        apples_done_sig <= '1';
        wait for CLK_PERIOD;
        apples_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in idle state after apples done" severity error;

        wait for CLK_PERIOD * 10;

        tick_sig <= '0';
        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in empty state after button pressed - should wait for tick" severity error;

        wait for CLK_PERIOD * 20;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in empty state after button pressed - should wait for tick" severity error;

        wait for CLK_PERIOD;

        tick_sig <= '1';

        wait for CLK_PERIOD * 2; -- Two clock cycles for synchroniser

        assert run_head_sig = '1' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in head state after idle tick" severity error;
        wait for CLK_PERIOD * 50;

        wait for CLK_PERIOD;
        head_death_sig <= '1';
        wait for CLK_PERIOD;
        head_death_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in Death state after Head Death" severity error;

        -- CHECK RESET ONCE MORE

        wait for CLK_PERIOD * 10;
        wait for 0 ns;
        logic_reset_sig <= '1';
        wait for CLK_PERIOD;
        wait for 0 ns;
        logic_reset_sig <= '0';
        -- Test Phase
        wait for CLK_PERIOD;
        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '1' and run_init_sig = '0' report "Reset not in Reset State" severity error;

        wait for CLK_PERIOD;
        reset_done_sig <= '1';
        wait for CLK_PERIOD;
        reset_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '1' report "Not in init state after reset done" severity error;

        wait for CLK_PERIOD;
        init_done_sig <= '1';
        wait for CLK_PERIOD;
        init_done_sig <= '0';
        wait for CLK_PERIOD;

        assert run_head_sig = '0' and run_tail_sig = '0' and run_apples_sig = '0' and run_reset_sig = '0' and run_init_sig = '0' report "Not in empty state after init done" severity error;
        -- Simulation beenden
        wait for CLK_PERIOD * 10;
        std.env.stop;
    end process;

    monitor : process (clk_sig)
    begin
        if rising_edge(clk_sig) then
            if run_head_sig = '1' then
                assert run_tail_sig = '0' report "More than one run signal high! (head/tail)" severity error;
                assert run_apples_sig = '0' report "More than one run signal high! (head/apples)" severity error;
                assert run_reset_sig = '0' report "More than one run signal high! (head/reset)" severity error;
                assert run_init_sig = '0' report "More than one run signal high! (head/init)" severity error;
            elsif run_tail_sig = '1' then
                assert run_apples_sig = '0' report "More than one run signal high! (tail/apples)" severity error;
                assert run_reset_sig = '0' report "More than one run signal high! (tail/reset)" severity error;
                assert run_init_sig = '0' report "More than one run signal high! (tail/init)" severity error;
            elsif run_apples_sig = '1' then
                assert run_reset_sig = '0' report "More than one run signal high! (apples/reset)" severity error;
                assert run_init_sig = '0' report "More than one run signal high! (apples/init)" severity error;
            elsif run_reset_sig = '1' then
                assert run_init_sig = '0' report "More than one run signal high! (reset/init)" severity error;
            end if;
        end if;
    end process;

end testbench;
