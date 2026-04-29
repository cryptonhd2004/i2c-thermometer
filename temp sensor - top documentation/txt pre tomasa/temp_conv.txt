library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity temp_conv is
    port (
        temp_raw       : in  std_logic_vector(15 downto 0);   
        celsius_x100   : out std_logic_vector(15 downto 0);   
        fahrenheit_x100: out std_logic_vector(15 downto 0)    
    );
end entity temp_conv;

architecture rtl of temp_conv is
    signal raw_int  : integer;
    signal temp_13b : integer;
    signal c_total  : integer;
begin
    raw_int <= to_integer(unsigned(temp_raw));
    temp_13b <= raw_int / 8;
    c_total <= (temp_13b * 625) / 100;
    
    celsius_x100 <= std_logic_vector(to_unsigned(c_total, 16));
    fahrenheit_x100 <= std_logic_vector(to_unsigned((c_total * 18) / 10 + 3200, 16));
end architecture rtl;