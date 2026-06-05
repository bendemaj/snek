library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity Gamelogic is
    port (
        clk            : in std_ulogic;
        tick           : in std_ulogic;
        button_pressed : in std_ulogic;
        reset          : in std_ulogic;

        run_reset      : out std_ulogic;
        run_init       : out std_ulogic;
        run_head       : out std_ulogic;
        run_tail       : out std_ulogic;
        run_apples     : out std_ulogic;

        reset_done     : in std_ulogic;
        init_done      : in std_ulogic;
        head_done      : in std_ulogic;
        tail_done      : in std_ulogic;
        apples_done    : in std_ulogic;
        head_death     : in std_ulogic
    );
end Gamelogic;

architecture Behavioral of Gamelogic is

    type state_t is (
        ST_RESET,
        ST_INIT,
        ST_INPUTWAIT,
        ST_IDLE,
        ST_HEAD,
        ST_TAIL,
        ST_APPLES,
        ST_DEATH
    );

    signal state_reg : state_t := ST_RESET;

    -- We save the old tick value here.
    -- This is used to detect a new tick.
    signal tick_last : std_ulogic := '0';

begin

    -- Main state machine
    state_proc : process(clk)
    begin
        if rising_edge(clk) then

            if reset = '1' then
                state_reg <= ST_RESET;
                tick_last <= '0';

            else
                case state_reg is

                    -- Reset module is active
                    when ST_RESET =>
                        if reset_done = '1' then
                            state_reg <= ST_INIT;
                        end if;

                    -- Init module is active
                    when ST_INIT =>
                        if init_done = '1' then
                            state_reg <= ST_INPUTWAIT;
                        end if;

                    -- Wait until player presses a button
                    when ST_INPUTWAIT =>
                        if button_pressed = '1' then
                            state_reg <= ST_IDLE;
                        end if;

                    -- Wait for a new game tick
                    when ST_IDLE =>
                        -- Start only when tick changes from 0 to 1
                        if tick = '1' and tick_last = '0' then
                            state_reg <= ST_HEAD;
                        end if;

                    -- Move/check snake head
                    when ST_HEAD =>
                        if head_death = '1' then
                            state_reg <= ST_DEATH;
                        elsif head_done = '1' then
                            state_reg <= ST_TAIL;
                        end if;

                    -- Move snake tail
                    when ST_TAIL =>
                        if tail_done = '1' then
                            state_reg <= ST_APPLES;
                        end if;

                    -- Check/place apples
                    when ST_APPLES =>
                        if apples_done = '1' then
                            state_reg <= ST_IDLE;
                        end if;

                    -- Game over, wait for reset
                    when ST_DEATH =>
                        state_reg <= ST_DEATH;

                end case;

                -- Save current tick for next clock cycle
                tick_last <= tick;
            end if;
        end if;
    end process;


    -- Output logic
    outputs_proc : process(state_reg)
    begin
        -- Default: all modules off
        run_reset  <= '0';
        run_init   <= '0';
        run_head   <= '0';
        run_tail   <= '0';
        run_apples <= '0';

        case state_reg is

            when ST_RESET =>
                run_reset <= '1';

            when ST_INIT =>
                run_init <= '1';

            when ST_HEAD =>
                run_head <= '1';

            when ST_TAIL =>
                run_tail <= '1';

            when ST_APPLES =>
                run_apples <= '1';

            -- INPUTWAIT, IDLE and DEATH have no active run signal
            when others =>
                null;

        end case;
    end process;

end Behavioral;