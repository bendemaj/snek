library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.local_types.all;

entity Apples_tb is
end Apples_tb;

architecture testbench of Apples_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk_sig          : std_ulogic := '0';
    signal reset_sig        : std_ulogic := '0';
    signal random_sig       : std_ulogic_vector(11 downto 0) := (others => '0');

    signal tile_coord_sig   : coordinate_t;
    signal tile_from_GA_sig : game_tile;
    signal tile_to_GA_sig   : game_tile;
    signal set_tile_sig     : std_ulogic;

    signal run_apples_sig   : std_ulogic := '0';
    signal apples_done_sig  : std_ulogic;
    signal apple_placed_sig : std_ulogic := '0';

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

    constant body_tile : game_tile := (
        is_tail  => '0',
        is_head  => '0',
        is_apple => '0',
        is_body  => '1',
        parent   => origin
    );

begin

    -- Change only this line to test r1, r2, r3 or r4.
    Apples_inst : entity work.Apples_r4
        generic map (
            AREAWIDTH  => 64,
            AREAHEIGHT => 48
        )
        port map (
            clk          => clk_sig,
            reset        => reset_sig,
            random       => random_sig,
            tile_coord   => tile_coord_sig,
            tile_from_GA => tile_from_GA_sig,
            tile_to_GA   => tile_to_GA_sig,
            set_tile     => set_tile_sig,
            run_apples   => run_apples_sig,
            apples_done  => apples_done_sig,
            apple_placed => apple_placed_sig
        );

    -- Clock generation
    clk_gen : process
    begin
        clk_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_sig <= '1';
        wait for CLK_PERIOD / 2;
    end process;


    stimulus : process
        variable saw_set_tile : boolean;
    begin

        ----------------------------------------------------------------
        -- Reset
        ----------------------------------------------------------------
        reset_sig        <= '1';
        run_apples_sig   <= '0';
        apple_placed_sig <= '0';
        random_sig       <= (others => '0');
        tile_from_GA_sig <= empty_tile;

        wait for CLK_PERIOD * 3;

        reset_sig <= '0';
        wait for CLK_PERIOD * 2;

        assert set_tile_sig = '0'
            report "After reset, set_tile should be 0"
            severity error;

        assert apples_done_sig = '0'
            report "After reset, apples_done should be 0"
            severity error;


        ----------------------------------------------------------------
        -- Test 1:
        -- run_apples = 0
        -- Apples should stay idle.
        ----------------------------------------------------------------
        report "Test 1: IDLE when run_apples = 0";

        run_apples_sig   <= '0';
        apple_placed_sig <= '0';
        tile_from_GA_sig <= empty_tile;
        random_sig       <= "000101000111"; -- x = 5, y = 7

        wait for CLK_PERIOD * 5;

        assert set_tile_sig = '0'
            report "Apples should not set a tile when run_apples = 0"
            severity error;

        assert apples_done_sig = '0'
            report "Apples should not be done when run_apples = 0"
            severity error;


        ----------------------------------------------------------------
        -- Test 2:
        -- apple_placed = 1
        -- If an apple already exists, module should go to DONE.
        -- It must NOT set a new apple.
        ----------------------------------------------------------------
        report "Test 2: apple already placed";

        reset_sig <= '1';
        wait for CLK_PERIOD * 2;
        reset_sig <= '0';
        wait for CLK_PERIOD;

        apple_placed_sig <= '1';
        run_apples_sig   <= '1';
        tile_from_GA_sig <= empty_tile;
        random_sig       <= "000101000111"; -- x = 5, y = 7

        saw_set_tile := false;

        for i in 0 to 10 loop
            wait for CLK_PERIOD;

            if set_tile_sig = '1' then
                saw_set_tile := true;
            end if;

            if apples_done_sig = '1' then
                exit;
            end if;
        end loop;

        assert saw_set_tile = false
            report "Apple already placed: module must not set a new apple"
            severity error;

        assert apples_done_sig = '1'
            report "Apple already placed: apples_done should become 1"
            severity error;

        run_apples_sig <= '0';
        wait for CLK_PERIOD * 3;


        ----------------------------------------------------------------
        -- Test 3:
        -- apple_placed = 0 and field is free.
        -- Apples should set one apple at the random position.
        ----------------------------------------------------------------
        report "Test 3: free field, apple should be placed";

        reset_sig <= '1';
        wait for CLK_PERIOD * 2;
        reset_sig <= '0';
        wait for CLK_PERIOD;

        apple_placed_sig <= '0';
        run_apples_sig   <= '1';
        tile_from_GA_sig <= empty_tile;

        -- random(11 downto 6) = 5
        -- random(5 downto 0)  = 7
        -- expected coordinate: x = 5, y = 7
        random_sig <= "000101000111";

        saw_set_tile := false;

        for i in 0 to 15 loop
            wait for CLK_PERIOD;

            if set_tile_sig = '1' then
                saw_set_tile := true;

                assert tile_coord_sig.x = "000101"
                    report "Wrong apple x coordinate"
                    severity error;

                assert tile_coord_sig.y = "000111"
                    report "Wrong apple y coordinate"
                    severity error;

                assert tile_to_GA_sig.is_apple = '1'
                    report "SETAPPLE should write an apple tile"
                    severity error;

                assert tile_to_GA_sig.is_head = '0'
                    report "Apple tile must not be head"
                    severity error;

                assert tile_to_GA_sig.is_body = '0'
                    report "Apple tile must not be body"
                    severity error;

                assert tile_to_GA_sig.is_tail = '0'
                    report "Apple tile must not be tail"
                    severity error;

                exit;
            end if;
        end loop;

        assert saw_set_tile = true
            report "Free field: module did not set an apple"
            severity error;

        -- After setting apple, apples_done should come shortly after.
        for i in 0 to 5 loop
            wait for CLK_PERIOD;
            if apples_done_sig = '1' then
                exit;
            end if;
        end loop;

        assert apples_done_sig = '1'
            report "After setting apple, apples_done should become 1"
            severity error;

        run_apples_sig <= '0';
        wait for CLK_PERIOD * 3;


        ----------------------------------------------------------------
        -- Test 4:
        -- apple_placed = 0 but field is occupied by body.
        -- Apples must NOT set an apple on that field.
        ----------------------------------------------------------------
        report "Test 4: occupied field, apple must not be placed";

        reset_sig <= '1';
        wait for CLK_PERIOD * 2;
        reset_sig <= '0';
        wait for CLK_PERIOD;

        apple_placed_sig <= '0';
        run_apples_sig   <= '1';
        tile_from_GA_sig <= body_tile;

        -- Same random position as before: x = 5, y = 7
        random_sig <= "000101000111";

        saw_set_tile := false;

        for i in 0 to 15 loop
            wait for CLK_PERIOD;

            if set_tile_sig = '1' then
                saw_set_tile := true;
            end if;
        end loop;

        assert saw_set_tile = false
            report "Occupied field: module must not set an apple"
            severity error;

        run_apples_sig <= '0';
        wait for CLK_PERIOD * 5;


        ----------------------------------------------------------------
        -- End simulation
        ----------------------------------------------------------------
        report "Apples testbench finished";
        std.env.stop;
        wait;

    end process;

end testbench;