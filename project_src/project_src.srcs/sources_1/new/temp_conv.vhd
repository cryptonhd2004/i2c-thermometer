library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity temp_conv is
    port (
        temp_data  : in  std_logic_vector(7 downto 0);
        celsius    : out std_logic_vector(7 downto 0);
        fahrenheit : out std_logic_vector(7 downto 0)
    );
end entity temp_conv;

architecture rtl of temp_conv is
begin

    -- Celzius:  prepojime vstup priamo na vystup (pass-through)
    celsius <= temp_data;

    -- Fahrenheit: F = (C * 9) / 5 + 32
    -- funkcia resize => vysledok zrezany presne na 8 bitov
    fahrenheit <= std_logic_vector( resize( (unsigned(temp_data) * 9) / 5 + 32, 8 ) );

end architecture rtl;