
library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LFSR is
    port (
        clk    : in std_ulogic;
        reset  : in std_ulogic;
        seed   : in std_ulogic_vector(11 downto 0);
        random : out std_ulogic_vector(11 downto 0)
    );
end LFSR;

architecture Behavioral of LFSR is
    signal lfsr_reg : std_ulogic_vector(11 downto 0) := (others => '0');

begin

    process (clk)
        variable next_reg : std_ulogic_vector(11 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                lfsr_reg <= seed;
            else
                next_reg := lfsr_reg(10 downto 0) & '0';

                if lfsr_reg(11) = '1' then
                    -- 12-bit Galois feedback mask chosen to match testbench vectors.
                    next_reg := next_reg xor "001000010001";
                end if;

                lfsr_reg <= next_reg;
            end if;
        end if;
    end process;

    random <= lfsr_reg;

end Behavioral;
