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

    type head_state_t is (
        IDLE,
        CALC_NEXT_HEAD_POS,
        CHECK_NEXT_HEAD_POS,
        CYCLE_WASTE,
        WASTE_CYCLE,
        CHECK_DEATH,
        SET_NEXT_HEAD,
        SET_BODY,
        DONE,
        DEATH
    );

    signal state_reg : head_state_t := IDLE;

    signal current_head_pos_reg : coordinate_t := (x => (others => '0'), y => (others => '0'));
    signal next_head_pos_reg    : coordinate_t := (x => (others => '0'), y => (others => '0'));
    signal move_dir_reg         : direction_t  := RIGHT;
    signal last_dir_reg         : direction_t  := RIGHT;
    signal wall_collision_reg   : std_ulogic   := '0';

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

    constant head_tile : game_tile := (
        is_tail  => '0',
        is_head  => '1',
        is_apple => '0',
        is_body  => '0',
        parent   => origin
    );

    signal body_tile_sig : game_tile := (
        is_tail  => '0',
        is_head  => '0',
        is_apple => '0',
        is_body  => '1',
        parent   => origin
    );

    function is_opposite(a : direction_t; b : direction_t) return boolean is
    begin
        return (a = UP and b = DOWN)
            or (a = DOWN and b = UP)
            or (a = LEFT and b = RIGHT)
            or (a = RIGHT and b = LEFT);
    end function;

begin

    state_reg_proc : process (clk)
        variable move_dir_v   : direction_t;
        variable next_pos_v   : coordinate_t;
        variable hit_wall_v   : std_ulogic;
        variable head_x_int_v : integer;
        variable head_y_int_v : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state_reg            <= IDLE;
                current_head_pos_reg <= origin;
                next_head_pos_reg    <= origin;
                move_dir_reg         <= RIGHT;
                last_dir_reg         <= RIGHT;
                wall_collision_reg   <= '0';
                body_tile_sig.parent <= origin;
            else
                case state_reg is
                    when IDLE =>
                        if run_head = '1' then
                            state_reg            <= CALC_NEXT_HEAD_POS;
                            current_head_pos_reg <= head_pos;
                        end if;

                    when CALC_NEXT_HEAD_POS =>
                        move_dir_v := direction;
                        if is_opposite(direction, last_dir_reg) then
                            move_dir_v := last_dir_reg;
                        end if;

                        move_dir_reg <= move_dir_v;

                        next_pos_v := current_head_pos_reg;
                        hit_wall_v := '0';
                        head_x_int_v := to_integer(unsigned(current_head_pos_reg.x));
                        head_y_int_v := to_integer(unsigned(current_head_pos_reg.y));

                        case move_dir_v is
                            when UP =>
                                if head_y_int_v = 0 then
                                    hit_wall_v := '1';
                                else
                                    next_pos_v.y := std_ulogic_vector(to_unsigned(head_y_int_v - 1, next_pos_v.y'length));
                                end if;

                            when DOWN =>
                                if head_y_int_v = integer(AREAHEIGHT) - 1 then
                                    hit_wall_v := '1';
                                else
                                    next_pos_v.y := std_ulogic_vector(to_unsigned(head_y_int_v + 1, next_pos_v.y'length));
                                end if;

                            when LEFT =>
                                if head_x_int_v = 0 then
                                    hit_wall_v := '1';
                                else
                                    next_pos_v.x := std_ulogic_vector(to_unsigned(head_x_int_v - 1, next_pos_v.x'length));
                                end if;

                            when RIGHT =>
                                if head_x_int_v = integer(AREAWIDTH) - 1 then
                                    hit_wall_v := '1';
                                else
                                    next_pos_v.x := std_ulogic_vector(to_unsigned(head_x_int_v + 1, next_pos_v.x'length));
                                end if;
                        end case;

                        next_head_pos_reg <= next_pos_v;
                        wall_collision_reg <= hit_wall_v;

                        body_tile_sig.parent <= next_pos_v;
                        state_reg <= CHECK_NEXT_HEAD_POS;

                    when CHECK_NEXT_HEAD_POS =>
                        state_reg <= CYCLE_WASTE;

                    when CYCLE_WASTE =>
                        state_reg <= WASTE_CYCLE;

                    when WASTE_CYCLE =>
                        state_reg <= CHECK_DEATH;

                    when CHECK_DEATH =>
                        if wall_collision_reg = '1' or tile_from_GA.is_body = '1' or tile_from_GA.is_tail = '1' or tile_from_GA.is_head = '1' then
                            state_reg <= DEATH;
                        else
                            state_reg <= SET_NEXT_HEAD;
                        end if;

                    when SET_NEXT_HEAD =>
                        state_reg <= SET_BODY;

                    when SET_BODY =>
                        last_dir_reg <= move_dir_reg;
                        state_reg    <= DONE;

                    when DONE =>
                        state_reg <= IDLE;

                    when DEATH =>
                        state_reg <= IDLE;
                end case;
            end if;
        end if;
    end process;

    outputs_proc : process (state_reg, current_head_pos_reg, next_head_pos_reg, body_tile_sig)
    begin
        tile_coord <= origin;
        set_tile   <= '0';
        tile_to_GA <= empty_tile;
        head_done  <= '0';
        head_death <= '0';

        case state_reg is
            when CHECK_NEXT_HEAD_POS | CYCLE_WASTE | WASTE_CYCLE | CHECK_DEATH =>
                tile_coord <= next_head_pos_reg;

            when SET_NEXT_HEAD =>
                tile_coord <= next_head_pos_reg;
                set_tile   <= '1';
                tile_to_GA <= head_tile;

            when SET_BODY =>
                tile_coord <= current_head_pos_reg;
                set_tile   <= '1';
                tile_to_GA <= body_tile_sig;

            when DONE =>
                head_done <= '1';

            when DEATH =>
                head_death <= '1';

            when others =>
                null;
        end case;
    end process;

end Behavioral;
