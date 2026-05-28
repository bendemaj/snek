library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity Gamelogic is
    port (
        clk            : in std_ulogic; --100 MHz * 10 = 1 GHz / 125 = 8 MHz / 125 = 64 kHz
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
        ST_IDLE,
        ST_HEAD,
        ST_TAIL,
        ST_APPLES
    );

    signal state_reg : state_t := ST_RESET;

    signal tick_sync_ff1 : std_ulogic := '0';
    signal tick_sync_ff2 : std_ulogic := '0';
    signal tick_sync_d   : std_ulogic := '0';
    signal tick_rise     : std_ulogic := '0';

begin

    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tick_sync_ff1 <= '0';
                tick_sync_ff2 <= '0';
                tick_sync_d   <= '0';
                tick_rise     <= '0';
            else
                tick_sync_ff1 <= tick;
                tick_sync_ff2 <= tick_sync_ff1;
                tick_sync_d   <= tick_sync_ff2;
                tick_rise     <= tick_sync_ff2 and not tick_sync_d;
            end if;
        end if;
    end process;

    state_proc : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state_reg <= ST_RESET;
            else
                case state_reg is
                    when ST_RESET =>
                        if reset_done = '1' then
                            state_reg <= ST_INIT;
                        end if;

                    when ST_INIT =>
                        if init_done = '1' then
                            state_reg <= ST_IDLE;
                        end if;

                    when ST_IDLE =>
                        if button_pressed = '1' and tick_rise = '1' then
                            state_reg <= ST_HEAD;
                        end if;

                    when ST_HEAD =>
                        if head_death = '1' then
                            state_reg <= ST_IDLE;
                        elsif head_done = '1' then
                            state_reg <= ST_TAIL;
                        end if;

                    when ST_TAIL =>
                        if tail_done = '1' then
                            state_reg <= ST_APPLES;
                        end if;

                    when ST_APPLES =>
                        if apples_done = '1' then
                            state_reg <= ST_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    outputs_proc : process (state_reg)
    begin
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

            when others =>
                null;
        end case;
    end process;

end Behavioral;
