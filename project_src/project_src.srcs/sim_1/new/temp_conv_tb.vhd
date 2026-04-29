library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity temp_conv_tb is
-- Testbench nemá žiadne vstupy ani výstupy
end entity temp_conv_tb;

architecture behavior of temp_conv_tb is

    -- Signály pre pripojenie k testovanému modulu
    signal sig_temp_raw        : std_logic_vector(15 downto 0) := (others => '0');
    signal sig_celsius_x100    : std_logic_vector(15 downto 0);
    signal sig_fahrenheit_x100 : std_logic_vector(15 downto 0);

begin

    -- Inštanciácia testovaného modulu (UUT - Unit Under Test)
    UUT: entity work.temp_conv
        port map (
            temp_raw        => sig_temp_raw,
            celsius_x100    => sig_celsius_x100,
            fahrenheit_x100 => sig_fahrenheit_x100
        );

    -- Proces na generovanie testovacích hodnôt (stimulus)
    stimulus_process: process
    begin
        -- ---------------------------------------------------------
        -- TEST 1: Teplota 0.00 °C
        -- ---------------------------------------------------------
        sig_temp_raw <= x"0000"; 
        wait for 20 ns;
        -- Očakávaný výstup: celsius = 0, fahrenheit = 3200 (32.00 °F)
        
        -- ---------------------------------------------------------
        -- TEST 2: Izbová teplota 25.00 °C
        -- ---------------------------------------------------------
        -- Senzor vráti hodnotu 400 (400 * 0.0625 = 25.00).
        -- Dáta sú posunuté o 3 bity vľavo, čiže 400 * 8 = 3200, čo je HEX 0x0C80.
        sig_temp_raw <= x"0C80"; 
        wait for 20 ns;
        -- Očakávaný výstup: celsius = 2500, fahrenheit = 7700 (77.00 °F)

        -- ---------------------------------------------------------
        -- TEST 3: Bod varu 100.50 °C
        -- ---------------------------------------------------------
        -- Senzor vráti hodnotu 1608 (1608 * 0.0625 = 100.50).
        -- 1608 * 8 = 12864, čo je HEX 0x3240.
        sig_temp_raw <= x"3240"; 
        wait for 20 ns;
        -- Očakávaný výstup: celsius = 10050, fahrenheit = 21290 (212.90 °F)
        
        -- ---------------------------------------------------------
        -- TEST 4: Teplota 23.43 °C (otestovanie desatinných miest)
        -- ---------------------------------------------------------
        -- Senzor vráti hodnotu 375 (375 * 0.0625 = 23.4375).
        -- 375 * 8 = 3000, čo je HEX 0x0BB8.
        sig_temp_raw <= x"0BB8";
        wait for 20 ns;
        -- Očakávaný výstup: celsius = 2343, fahrenheit = 7417 (74.17 °F)

        -- Zastavenie simulácie
        wait;
    end process;

end architecture behavior;