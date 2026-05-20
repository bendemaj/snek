----------------------------------------------------------------------------------
-- Company: ICT
-- Engineer: Daniel Fabian & Ulrich Paleček
-- 
-- Create Date: 03/18/2026 06:01:13 PM
-- Design Name: Snake
-- Module Name: top - Behavioral
-- Project Name: Snake
-- Target Devices: Nexys 4 DDR & Nexys A7 100T
-- Tool Versions: Vivado 2020+
-- Description: top module, kinda the nervous system of the snake
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
library UNISIM;
use UNISIM.VComponents.all;
use work.local_types.all;

entity top is
    generic (
        AREAWIDTH  : natural := 16;
        AREAHEIGHT : natural := 12
    );
    port (
        --clk
        clk : in std_ulogic;
        --VGA Connector
        VGA_R  : out std_ulogic_vector (3 downto 0);
        VGA_G  : out std_ulogic_vector (3 downto 0);
        VGA_B  : out std_ulogic_vector (3 downto 0);
        VGA_HS : out std_ulogic;
        VGA_VS : out std_ulogic;
        --Buttons
        BTNC : in std_ulogic;
        BTNU : in std_ulogic;
        BTND : in std_ulogic;
        BTNL : in std_ulogic;
        BTNR : in std_ulogic;
        -- LEDs and Switches
        LED : out std_ulogic_vector (11 downto 0);
        SW  : in std_ulogic_vector (11 downto 0);
        -- 7-Segment-Display
        SEG : out std_ulogic_vector (6 downto 0);
        DP  : out std_ulogic;
        AN  : out std_ulogic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is

    -- Clock and Reset
    signal pre_tick_clk : std_ulogic;
    signal tick         : std_ulogic;
    signal clk_fb       : std_ulogic;
    signal logic_reset  : std_ulogic := '0';

    -- VGA
    signal next_pix_x_sig : std_ulogic_vector(9 downto 0);
    signal next_pix_y_sig : std_ulogic_vector(9 downto 0);
    signal pix_col_sig    : color;

    -- Buttons
    signal direction_sig      : direction_t;
    signal button_pressed_sig : std_ulogic;

    -- Gamearea
    signal apple_placed_sig : std_ulogic;
    signal head_pos_out_sig : coordinate_t;
    signal tail_pos_out_sig : coordinate_t;

    -- Gamelogic
    signal run_reset_sig   : std_ulogic;
    signal run_init_sig    : std_ulogic;
    signal run_head_sig    : std_ulogic;
    signal run_tail_sig    : std_ulogic;
    signal run_apples_sig  : std_ulogic;
    signal reset_done_sig  : std_ulogic;
    signal init_done_sig   : std_ulogic;
    signal head_done_sig   : std_ulogic;
    signal tail_done_sig   : std_ulogic;
    signal apples_done_sig : std_ulogic;
    signal head_death_sig  : std_ulogic;

    -- BEGIN Signals for GameAreaMUX
    signal tile_coord_sig   : coordinate_t;
    signal tile_from_GA_sig : game_tile;
    signal tile_to_GA_sig   : game_tile;
    signal set_tile_sig     : std_ulogic;

    signal head_access           : GameAreaInterface;
    signal tile_coord_head_sig   : coordinate_t;
    signal tile_from_GA_head_sig : game_tile;
    signal tile_to_GA_head_sig   : game_tile;
    signal set_tile_head_sig     : std_ulogic;

    signal tail_access           : GameAreaInterface;
    signal tile_coord_tail_sig   : coordinate_t;
    signal tile_from_GA_tail_sig : game_tile;
    signal tile_to_GA_tail_sig   : game_tile;
    signal set_tile_tail_sig     : std_ulogic;

    signal apples_access           : GameAreaInterface;
    signal tile_coord_apples_sig   : coordinate_t;
    signal tile_from_GA_apples_sig : game_tile;
    signal tile_to_GA_apples_sig   : game_tile;
    signal set_tile_apples_sig     : std_ulogic;

    signal random_sig : std_ulogic_vector(11 downto 0);

    signal init_access           : GameAreaInterface;
    signal tile_coord_init_sig   : coordinate_t;
    signal tile_from_GA_init_sig : game_tile;
    signal tile_to_GA_init_sig   : game_tile;
    signal set_tile_init_sig     : std_ulogic;

    signal reset_access           : GameAreaInterface;
    signal tile_coord_reset_sig   : coordinate_t;
    signal tile_from_GA_reset_sig : game_tile;
    signal tile_to_GA_reset_sig   : game_tile;
    signal set_tile_reset_sig     : std_ulogic;

    signal selectable_ports : GameAreaInterfaceVector(4 downto 0);
    signal GameAreaPort     : GameAreaInterface;
    signal port_selection   : std_ulogic_vector(4 downto 0);
    -- END Signals for GameAreaMUX

begin

    -- Display LFSR-seed-switches on LEDs
    LED <= SW;

    -- Connet Reset to Button
    logic_reset <= BTNC;

    -- BEGIN Signals for GameAreaMUX
    tile_coord_sig   <= GameAreaPort.tile_coord;
    tile_from_GA_sig <= GameAreaPort.tile_from_GA;
    tile_to_GA_sig   <= GameAreaPort.tile_to_GA;
    set_tile_sig     <= GameAreaPort.set_tile;

    head_access.tile_coord   <= tile_coord_head_sig;
    head_access.tile_from_GA <= tile_from_GA_head_sig;
    head_access.tile_to_GA   <= tile_to_GA_head_sig;
    head_access.set_tile     <= set_tile_head_sig;

    tail_access.tile_coord   <= tile_coord_tail_sig;
    tail_access.tile_from_GA <= tile_from_GA_tail_sig;
    tail_access.tile_to_GA   <= tile_to_GA_tail_sig;
    tail_access.set_tile     <= set_tile_tail_sig;

    apples_access.tile_coord   <= tile_coord_apples_sig;
    apples_access.tile_from_GA <= tile_from_GA_apples_sig;
    apples_access.tile_to_GA   <= tile_to_GA_apples_sig;
    apples_access.set_tile     <= set_tile_apples_sig;

    init_access.tile_coord   <= tile_coord_init_sig;
    init_access.tile_from_GA <= tile_from_GA_init_sig;
    init_access.tile_to_GA   <= tile_to_GA_init_sig;
    init_access.set_tile     <= set_tile_init_sig;

    reset_access.tile_coord   <= tile_coord_reset_sig;
    reset_access.tile_from_GA <= tile_from_GA_reset_sig;
    reset_access.tile_to_GA   <= tile_to_GA_reset_sig;
    reset_access.set_tile     <= set_tile_reset_sig;

    selectable_ports(0) <= head_access;
    selectable_ports(1) <= tail_access;
    selectable_ports(2) <= apples_access;
    selectable_ports(3) <= init_access;
    selectable_ports(4) <= reset_access;

    port_selection(0) <= run_head_sig;
    port_selection(1) <= run_tail_sig;
    port_selection(2) <= run_apples_sig;
    port_selection(3) <= run_init_sig;
    port_selection(4) <= run_reset_sig;
    -- END Signals for GameAreaMUX

    GameArea_inst : entity work.GameArea
        generic map(
            AREAHEIGHT => AREAHEIGHT,
            AREAWIDTH  => AREAWIDTH
        )
        port map(
            clk          => clk,
            next_pix_x   => next_pix_x_sig,
            next_pix_y   => next_pix_y_sig,
            pix_col      => pix_col_sig,
            rst_game     => logic_reset,
            tile_coord   => tile_coord_sig,
            tile_from_GA => tile_from_GA_sig,
            tile_to_GA   => tile_to_GA_sig,
            set_tile     => set_tile_sig,
            head_pos_out => head_pos_out_sig,
            tail_pos_out => tail_pos_out_sig,
            apple_placed => apple_placed_sig
        );

    Gametick_inst : entity work.Gametick
        port map(
            clk  => pre_tick_clk,
            tick => tick
        );

    Gamelogic_inst : entity work.Gamelogic
        port map(
            clk            => clk,
            tick           => tick,
            button_pressed => button_pressed_sig,
            reset          => logic_reset,
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

    Score_inst : entity work.Score
        port map(
            clk          => clk,
            slow_clk     => pre_tick_clk,
            reset        => logic_reset,
            apple_placed => apple_placed_sig,
            tick         => head_done_sig,
            SEG          => SEG,
            DP           => DP,
            AN           => AN
        );

    Buttons_inst : entity work.Buttons
        port map(
            clk            => clk,
            tick           => tick,
            reset          => logic_reset,
            button_up      => BTNU,
            button_down    => BTND,
            button_left    => BTNL,
            button_right   => BTNR,
            direction      => direction_sig,
            button_pressed => button_pressed_sig
        );

    Head_inst : entity work.Head
        generic map(
            AREAHEIGHT => AREAHEIGHT,
            AREAWIDTH  => AREAWIDTH
        )
        port map(
            clk        => clk,           --: in std_ulogic;
            run_head   => run_head_sig,  --: in std_ulogic;
            head_done  => head_done_sig, --: out std_ulogic;
            head_death => head_death_sig,
            reset      => logic_reset,
            --gamearea manipulation/information interface
            tile_coord   => tile_coord_head_sig,   --: out coordinate;
            tile_from_GA => tile_from_GA_head_sig, --: in game_tile;
            tile_to_GA   => tile_to_GA_head_sig,   --: out game_tile;
            set_tile     => set_tile_head_sig,     --: out std_ulogic;
            --gamesstate information
            head_pos => head_pos_out_sig, --: in coordinate;
            --button direction
            direction => direction_sig --: in direction--;
        );

    Tail_inst : entity work.Tail
        port map(
            clk        => clk,
            start_tail => run_tail_sig,
            tail_done  => tail_done_sig,
            reset      => logic_reset,
            --gamearea manipulation/information interface
            tile_coord   => tile_coord_tail_sig,
            tile_from_GA => tile_from_GA_tail_sig,
            tile_to_GA   => tile_to_GA_tail_sig,
            set_tile     => set_tile_tail_sig,
            --gamesstate information
            tail_pos     => tail_pos_out_sig,
            apple_placed => apple_placed_sig
        );
    Apples_inst : entity work.Apples
        generic map(
            AREAHEIGHT => AREAHEIGHT,
            AREAWIDTH  => AREAWIDTH
        )
        port map(
            clk    => clk,
            reset  => logic_reset,
            random => random_sig,
            --gamearea manipulation/information interface
            tile_coord   => tile_coord_apples_sig,
            tile_from_GA => tile_from_GA_apples_sig,
            tile_to_GA   => tile_to_GA_apples_sig,
            set_tile     => set_tile_apples_sig,
            --gamesstate information
            run_apples   => run_apples_sig,
            apples_done  => apples_done_sig,
            apple_placed => apple_placed_sig

        );

    LFSR_inst : entity work.LFSR
        port map(
            clk    => clk,
            reset  => logic_reset,
            seed   => SW,
            random => random_sig
        );

    Init_inst : entity work.init
        port map(
            clk        => clk,
            start_init => run_init_sig,
            init_done  => init_done_sig,
            reset      => logic_reset,
            --gamearea manipulation/information interface
            tile_coord   => tile_coord_init_sig,
            tile_from_GA => tile_from_GA_init_sig,
            tile_to_GA   => tile_to_GA_init_sig,
            set_tile     => set_tile_init_sig
        );
    Reset_inst : entity work.reset
        port map(
            clk         => clk,
            start_reset => run_reset_sig,
            reset_done  => reset_done_sig,
            reset       => logic_reset,
            --gamearea manipulation/information interface
            tile_coord   => tile_coord_reset_sig,
            tile_from_GA => tile_from_GA_reset_sig,
            tile_to_GA   => tile_to_GA_reset_sig,
            set_tile     => set_tile_reset_sig

        );

    GameAreaMux_inst : entity work.GameAreaMux
        generic map(NumInterfaces => 5)
        port map(
            GameAreaPort  => GameAreaPort,
            SelectionPort => selectable_ports,
            Selection     => port_selection
        );

    -- work.vga, work.vga_testpattern
    VGA_inst : entity work.vga
        port map(
            --clk
            clk => clk,
            --pixel input
            pxl_in => pix_col_sig,
            --pixel request
            next_pix_x => next_pix_x_sig,
            next_pix_y => next_pix_y_sig,
            --VGA Connector
            VGA_R  => VGA_R,
            VGA_G  => VGA_G,
            VGA_B  => VGA_B,
            VGA_HS => VGA_HS,
            VGA_VS => VGA_VS
        );

    -- MMCME2_BASE: Base Mixed Mode Clock Manager
    --              Artix-7
    -- Xilinx HDL Language Template, version 2025.2

    MMCME2_BASE_inst : MMCME2_BASE
    generic map(
        BANDWIDTH       => "OPTIMIZED", -- Jitter programming (OPTIMIZED, HIGH, LOW)
        CLKFBOUT_MULT_F => 10.0,        -- Multiply value for all CLKOUT (2.000-64.000).
        CLKFBOUT_PHASE  => 0.0,         -- Phase offset in degrees of CLKFB (-360.000-360.000).
        CLKIN1_PERIOD   => 0.0,         -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        CLKOUT1_DIVIDE   => 10,
        CLKOUT2_DIVIDE   => 1,
        CLKOUT3_DIVIDE   => 1,
        CLKOUT4_DIVIDE   => 125,
        CLKOUT5_DIVIDE   => 1,
        CLKOUT6_DIVIDE   => 125,
        CLKOUT0_DIVIDE_F => 1.0, -- Divide amount for CLKOUT0 (1.000-128.000).
        -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKOUT1_DUTY_CYCLE => 0.5,
        CLKOUT2_DUTY_CYCLE => 0.5,
        CLKOUT3_DUTY_CYCLE => 0.5,
        CLKOUT4_DUTY_CYCLE => 0.5,
        CLKOUT5_DUTY_CYCLE => 0.5,
        CLKOUT6_DUTY_CYCLE => 0.5,
        -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        CLKOUT0_PHASE   => 0.0,
        CLKOUT1_PHASE   => 0.0,
        CLKOUT2_PHASE   => 0.0,
        CLKOUT3_PHASE   => 0.0,
        CLKOUT4_PHASE   => 0.0,
        CLKOUT5_PHASE   => 0.0,
        CLKOUT6_PHASE   => 0.0,
        CLKOUT4_CASCADE => TRUE, -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        DIVCLK_DIVIDE   => 1,    -- Master division value (1-106)
        REF_JITTER1     => 0.0,  -- Reference input jitter in UI (0.000-0.999).
        STARTUP_WAIT    => FALSE -- Delays DONE until MMCM is locked (FALSE, TRUE)
    )
    port map(
        -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
        --CLKOUT0  => CLKOUT0,     -- 1-bit output: CLKOUT0
        --CLKOUT0B => CLKOUT0B,    -- 1-bit output: Inverted CLKOUT0
        --CLKOUT1  => CLKOUT1,     -- 1-bit output: CLKOUT1
        --CLKOUT1B => CLKOUT1B,    -- 1-bit output: Inverted CLKOUT1
        --CLKOUT2 => CLKOUT2, -- 1-bit output: CLKOUT2
        --CLKOUT2B => CLKOUT2B,    -- 1-bit output: Inverted CLKOUT2
        --CLKOUT3  => CLKOUT3,     -- 1-bit output: CLKOUT3
        --CLKOUT3B => CLKOUT3B,    -- 1-bit output: Inverted CLKOUT3
        CLKOUT4 => pre_tick_clk, -- 1-bit output: CLKOUT4
        --CLKOUT5  => CLKOUT5,     -- 1-bit output: CLKOUT5
        --CLKOUT6  => CLKOUT6,     -- 1-bit output: CLKOUT6
        -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
        CLKFBOUT => clk_fb, -- 1-bit output: Feedback clock
        --CLKFBOUTB => CLKFBOUTB, -- 1-bit output: Inverted CLKFBOUT
        -- Status Ports: 1-bit (each) output: MMCM status ports
        --LOCKED => LOCKED, -- 1-bit output: LOCK
        -- Clock Inputs: 1-bit (each) input: Clock input
        CLKIN1 => clk, -- 1-bit input: Clock
        -- Control Ports: 1-bit (each) input: MMCM control ports
        PWRDWN => '0', -- 1-bit input: Power-down
        RST    => '0', -- 1-bit input: Reset
        -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
        CLKFBIN => clk_fb -- 1-bit input: Feedback clock
    );

    -- End of MMCME2_BASE_inst instantiation
end Behavioral;
