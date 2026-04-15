library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clkgen_200kHz is
    port (
        clk_100MHz  : in  std_logic;
        clk_200kHz  : out std_logic
    );
end entity clkgen_200kHz;

architecture rtl of clkgen_200kHz is

    -- 100 MHz / 200 kHz / 2 = 250  → čítač 0..249
    signal counter : unsigned(7 downto 0) := (others => '0');
    signal clk_reg : std_logic := '1';

begin

    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if counter = to_unsigned(249, counter'length) then
                counter <= (others => '0');
                clk_reg <= not clk_reg;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    clk_200kHz <= clk_reg;

end architecture rtl;