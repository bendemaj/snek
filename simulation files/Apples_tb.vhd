library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.local_types.all;

entity Apples_tb is
end Apples_tb;

architecture testbench of Apples_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant DUT_COUNT  : positive := 4;

    type coordinate_array_t is array (1 to DUT_COUNT) of coordinate_t;
    type tile_array_t is array (1 to DUT_COUNT) of game_tile;

    signal clk_sig          : std_ulogic := '0';
    signal reset_sig        : std_ulogic := '0';
    signal random_sig       : std_ulogic_vector(11 downto 0) := (others => '0');
    signal tile_coord_sig   : coordinate_array_t;
    signal tile_from_GA_sig : game_tile;
    signal tile_to_GA_sig   : tile_array_t;
    signal set_tile_sig     : std_ulogic_vector(1 to DUT_COUNT);
    signal run_apples_sig   : std_ulogic := '0';
    signal apples_done_sig  : std_ulogic_vector(1 to DUT_COUNT);
    signal apple_placed_sig : std_ulogic := '0';

    function coord(x : natural; y : natural) return coordinate_t is
        variable result : coordinate_t;
    begin
        result.x := std_ulogic_vector(to_unsigned(x, 6));
        result.y := std_ulogic_vector(to_unsigned(y, 6));
        return result;
    end function;

    function empty_tile return game_tile is
        variable result : game_tile;
    begin
        result.is_tail  := '0';
        result.is_head  := '0';
        result.is_apple := '0';
        result.is_body  := '0';
        result.parent   := coord(0, 0);
        return result;
    end function;

    function occupied_tile return game_tile is
        variable result : game_tile;
    begin
        result          := empty_tile;
        result.is_body  := '1';
        return result;
    end function;

    function apple_tile return game_tile is
        variable result : game_tile;
    begin
        result          := empty_tile;
        result.is_apple := '1';
        return result;
    end function;

begin
    Apples_r1_inst : entity work.Apples_r1
        port map(
            clk          => clk_sig,
            reset        => reset_sig,
            random       => random_sig,
            tile_coord   => tile_coord_sig(1),
            tile_from_GA => tile_from_GA_sig,
            tile_to_GA   => tile_to_GA_sig(1),
            set_tile     => set_tile_sig(1),
            run_apples   => run_apples_sig,
            apples_done  => apples_done_sig(1),
            apple_placed => apple_placed_sig
        );

    Apples_r2_inst : entity work.Apples_r2
        port map(
            clk          => clk_sig,
            reset        => reset_sig,
            random       => random_sig,
            tile_coord   => tile_coord_sig(2),
            tile_from_GA => tile_from_GA_sig,
            tile_to_GA   => tile_to_GA_sig(2),
            set_tile     => set_tile_sig(2),
            run_apples   => run_apples_sig,
            apples_done  => apples_done_sig(2),
            apple_placed => apple_placed_sig
        );

    Apples_r3_inst : entity work.Apples_r3
        port map(
            clk          => clk_sig,
            reset        => reset_sig,
            random       => random_sig,
            tile_coord   => tile_coord_sig(3),
            tile_from_GA => tile_from_GA_sig,
            tile_to_GA   => tile_to_GA_sig(3),
            set_tile     => set_tile_sig(3),
            run_apples   => run_apples_sig,
            apples_done  => apples_done_sig(3),
            apple_placed => apple_placed_sig
        );

    Apples_r4_inst : entity work.Apples_r4
        port map(
            clk          => clk_sig,
            reset        => reset_sig,
            random       => random_sig,
            tile_coord   => tile_coord_sig(4),
            tile_from_GA => tile_from_GA_sig,
            tile_to_GA   => tile_to_GA_sig(4),
            set_tile     => set_tile_sig(4),
            run_apples   => run_apples_sig,
            apples_done  => apples_done_sig(4),
            apple_placed => apple_placed_sig
        );

    clk_gen : process
    begin
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stimulus : process
        type boolean_array_t is array (1 to DUT_COUNT) of boolean;
        variable passed : boolean_array_t := (others => true);

        procedure mark_failed(dut : positive; msg : string) is
        begin
            if passed(dut) then
                report "Apples_r" & integer'image(dut) & " first failure: " & msg severity warning;
            end if;
            passed(dut) := false;
        end procedure;

        procedure expect_coord(dut : positive; expected : coordinate_t; msg : string) is
        begin
            if tile_coord_sig(dut) /= expected then
                mark_failed(dut, msg & " expected coord x="
                    & integer'image(to_integer(unsigned(expected.x))) & " y="
                    & integer'image(to_integer(unsigned(expected.y))) & " got x="
                    & integer'image(to_integer(unsigned(tile_coord_sig(dut).x))) & " y="
                    & integer'image(to_integer(unsigned(tile_coord_sig(dut).y))));
            end if;
        end procedure;

        procedure expect_common(
            expected_coord : coordinate_t;
            expected_set   : std_ulogic;
            expected_done  : std_ulogic;
            expected_tile  : game_tile;
            msg            : string
        ) is
        begin
            for dut in 1 to DUT_COUNT loop
                expect_coord(dut, expected_coord, msg);
                if set_tile_sig(dut) /= expected_set then
                    mark_failed(dut, msg & " expected set_tile=" & std_ulogic'image(expected_set)
                        & " got " & std_ulogic'image(set_tile_sig(dut)));
                end if;
                if apples_done_sig(dut) /= expected_done then
                    mark_failed(dut, msg & " expected apples_done=" & std_ulogic'image(expected_done)
                        & " got " & std_ulogic'image(apples_done_sig(dut)));
                end if;
                if tile_to_GA_sig(dut) /= expected_tile then
                    mark_failed(dut, msg & " unexpected tile_to_GA");
                end if;
            end loop;
        end procedure;

        procedure pulse_run is
        begin
            run_apples_sig <= '1';
            wait until rising_edge(clk_sig);
            wait for 1 ns;
            run_apples_sig <= '0';
        end procedure;

        procedure tick is
        begin
            wait until rising_edge(clk_sig);
            wait for 1 ns;
        end procedure;

        procedure reset_duts is
        begin
            reset_sig        <= '1';
            run_apples_sig   <= '0';
            apple_placed_sig <= '0';
            tile_from_GA_sig <= empty_tile;
            random_sig       <= (others => '0');
            wait for CLK_PERIOD * 2;
            wait for 1 ns;
            reset_sig <= '0';
            tick;
            expect_common(coord(0, 0), '0', '0', empty_tile, "after reset");
        end procedure;

    begin
        reset_duts;

        report "Test 1: apple_placed=1 must skip directly from CHECKPOS to DONE";
        random_sig       <= "000011000101";
        apple_placed_sig <= '1';
        tile_from_GA_sig <= empty_tile;
        pulse_run;
        expect_common(coord(0, 0), '0', '0', empty_tile, "CHECKPOS with existing apple");
        tick;
        expect_common(coord(0, 0), '0', '1', empty_tile, "DONE after existing apple");
        tick;
        expect_common(coord(0, 0), '0', '0', empty_tile, "IDLE after existing apple done");

        report "Test 2: free random tile must be probed for four cycles, then written once";
        reset_duts;
        random_sig       <= "000111001001";
        apple_placed_sig <= '0';
        tile_from_GA_sig <= empty_tile;
        pulse_run;
        expect_common(coord(0, 0), '0', '0', empty_tile, "CHECKPOS before placement");
        tick;
        expect_common(coord(7, 9), '0', '0', empty_tile, "GETPOS");
        tick;
        expect_common(coord(7, 9), '0', '0', empty_tile, "WAIT1");
        tick;
        expect_common(coord(7, 9), '0', '0', empty_tile, "WAIT2");
        tick;
        expect_common(coord(7, 9), '0', '0', empty_tile, "TESTPOS");
        tick;
        expect_common(coord(7, 9), '1', '0', apple_tile, "SETAPPLE");
        tick;
        expect_common(coord(0, 0), '0', '1', empty_tile, "DONE after placement");

        report "Test 3: occupied tile must retry with a new random position";
        reset_duts;
        random_sig       <= "000010000011";
        apple_placed_sig <= '0';
        tile_from_GA_sig <= empty_tile;
        pulse_run;
        tick;
        expect_common(coord(2, 3), '0', '0', empty_tile, "first GETPOS");
        tick;
        tick;
        tile_from_GA_sig <= occupied_tile;
        tick;
        expect_common(coord(2, 3), '0', '0', empty_tile, "occupied TESTPOS");
        random_sig       <= "001100001101";
        tile_from_GA_sig <= empty_tile;
        tick;
        expect_common(coord(0, 0), '0', '0', empty_tile, "retry CHECKPOS");
        tick;
        expect_common(coord(12, 13), '0', '0', empty_tile, "retry GETPOS");
        tick;
        tick;
        tick;
        tick;
        expect_common(coord(12, 13), '1', '0', apple_tile, "SETAPPLE after retry");
        tick;
        expect_common(coord(0, 0), '0', '1', empty_tile, "DONE after retry");

        for dut in 1 to DUT_COUNT loop
            if passed(dut) then
                report "Apples_r" & integer'image(dut) & " matches apples_fsm_description.pdf" severity note;
            else
                report "Apples_r" & integer'image(dut) & " does not match apples_fsm_description.pdf" severity note;
            end if;
        end loop;

        assert passed(3) report "Expected Apples_r3 to pass" severity error;
        assert not passed(1) report "Expected Apples_r1 to fail" severity error;
        assert not passed(2) report "Expected Apples_r2 to fail" severity error;
        assert not passed(4) report "Expected Apples_r4 to fail" severity error;

        std.env.stop;
    end process;

end testbench;
