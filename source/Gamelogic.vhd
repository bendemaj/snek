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

end Behavioral;
