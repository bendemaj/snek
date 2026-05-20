
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

end Behavioral;
