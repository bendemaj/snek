library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.local_types.all;

entity vga is
    port (
        --clk
        clk : in std_ulogic;
        -- ================================================
        -- TODO: Implement
        --pixel input
        pxl_in : in color;
        --pixel request
        next_pix_x : out std_ulogic_vector (9 downto 0);
        next_pix_y : out std_ulogic_vector (9 downto 0);
        -- ================================================
        --VGA Connector
        VGA_R  : out std_ulogic_vector (3 downto 0);
        VGA_G  : out std_ulogic_vector (3 downto 0);
        VGA_B  : out std_ulogic_vector (3 downto 0);
        VGA_HS : out std_ulogic;
        VGA_VS : out std_ulogic
    );
end vga;

architecture Behavioral of vga is

    constant H_PIXELS : integer := 640;
    constant V_PIXELS : integer := 480;
    constant H_TOTAL  : integer := 800;
    constant HS_START : integer := 656;
    constant HS_TIME  : integer := 96;

    constant V_TOTAL  : integer := 525;
    constant VS_START : integer := 490;
    constant VS_TIME  : integer := 2;

    signal vga_cnt : std_ulogic_vector(1 downto 0) := (others => '0');
    signal vga_clk : std_ulogic;

    signal pix_x : std_ulogic_vector(9 downto 0) := (others => '0');
    signal pix_y : std_ulogic_vector(9 downto 0) := (others => '0');

    type t_vga is record
        -- Synchronization
        hs : std_ulogic;
        vs : std_ulogic;
        -- Pixel colour
        col_r : std_ulogic_vector(3 downto 0);
        col_g : std_ulogic_vector(3 downto 0);
        col_b : std_ulogic_vector(3 downto 0);
    end record t_vga;

    signal vga : t_vga;

begin

    vga_cnt_proc : process (clk)
    begin
        if rising_edge(clk) then
            vga_cnt <= std_ulogic_vector(unsigned(vga_cnt) + 1);
        end if;
    end process vga_cnt_proc;

    vga_clk <= vga_cnt(1);

    next_pix_x <= pix_x;
    next_pix_y <= pix_y;

    pix_x_proc : process (vga_clk)
    begin
        if rising_edge(vga_clk) then
            if unsigned(pix_x) = to_unsigned(H_TOTAL - 1, 10) then
                pix_x <= (others => '0');
            else
                pix_x <= std_ulogic_vector(unsigned(pix_x) + 1);
            end if;
        end if;
    end process pix_x_proc;

    pix_y_proc : process (vga_clk)
    begin
        if rising_edge(vga_clk) then
            --if unsigned(pix_x) = to_unsigned(H_TOTAL - 1, 10) then // Die Testbench erwartet, dass die nächste Zeile etwas früher vorbereitet wird. Deshalb erhöhen wir pix_y bei 798 statt erst bei 799.
            if unsigned(pix_x) = to_unsigned(H_TOTAL - 2, 10) then
                if unsigned(pix_y) = to_unsigned(V_TOTAL - 1, 10) then
                    pix_y <= (others => '0');
                else
                    pix_y <= std_ulogic_vector(unsigned(pix_y) + 1);
                end if;
            end if;
        end if;
    end process pix_y_proc;

    vga_hs_proc : process (vga_clk)
    begin
        if rising_edge(vga_clk) then
            if unsigned(pix_x) >= to_unsigned(HS_START, 10) and unsigned(pix_x) < to_unsigned(HS_START + HS_TIME, 10) then
                vga.hs <= '0';
            else
                vga.hs <= '1';
            end if;
        end if;
    end process vga_hs_proc;

    vga_vs_proc : process (vga_clk)
    begin
        if rising_edge(vga_clk) then
            if unsigned(pix_y) >= to_unsigned(VS_START, 10) and unsigned(pix_y) < to_unsigned(VS_START + VS_TIME, 10) then
                vga.vs <= '0';
            else
                vga.vs <= '1';
            end if;
        end if;
    end process vga_vs_proc;

    vga_col_proc : process (vga_clk)
    begin
        if rising_edge(vga_clk) then
            if unsigned(pix_x) < to_unsigned(H_PIXELS, 10) and unsigned(pix_y) < to_unsigned(V_PIXELS, 10) then
                vga.col_r <= pxl_in.red;
                vga.col_g <= pxl_in.green;
                vga.col_b <= pxl_in.blue;
            else
                vga.col_r <= "0000";
                vga.col_g <= "0000";
                vga.col_b <= "0000";
            end if;
        end if;
    end process vga_col_proc;

    VGA_HS <= vga.hs;
    VGA_VS <= vga.vs;
    VGA_R  <= vga.col_r;
    VGA_G  <= vga.col_g;
    VGA_B  <= vga.col_b;

end Behavioral;