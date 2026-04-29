library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7_tb is
-- Testbench nemá porty
end entity seg7_tb;

architecture behavior of seg7_tb is

    -- Signály pre pripojenie k modulu
    signal clk_100MHz_sig : std_logic := '0';
    signal data_x100_sig  : std_logic_vector(15 downto 0) := (others => '0');
    signal is_fahr_sig    : std_logic := '0';
    signal seg_sig        : std_logic_vector(6 downto 0);
    signal dp_sig         : std_logic;
    signal an_sig         : std_logic_vector(7 downto 0);

    -- Konštanta pre 100 MHz hodiny (1 takt = 10 ns)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Inštanciácia modulu displeja
    UUT: entity work.seg7
        port map (
            clk_100MHz => clk_100MHz_sig,
            data_x100  => data_x100_sig,
            is_fahr    => is_fahr_sig,
            SEG        => seg_sig,
            DP         => dp_sig,
            AN         => an_sig
        );

    -- Generátor 100 MHz hodinového signálu
    clk_process: process
    begin
        clk_100MHz_sig <= '0';
        wait for CLK_PERIOD / 2;
        clk_100MHz_sig <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Generovanie testovacích hodnôt
    stimulus_process: process
    begin
        -- ---------------------------------------------------------
        -- TEST 1: Zobrazenie 25.00 °C (Celzius)
        -- ---------------------------------------------------------
        data_x100_sig <= std_logic_vector(to_unsigned(2500, 16));
        is_fahr_sig   <= '0';
        -- Musíme počkať aspoň 10 milisekúnd, aby sa na displeji 
        -- vystriedalo všetkých 8 cifier (každá svieti 1 ms)
        wait for 10 ms;

        -- ---------------------------------------------------------
        -- TEST 2: Zobrazenie 77.00 °F (Fahrenheit)
        -- ---------------------------------------------------------
        data_x100_sig <= std_logic_vector(to_unsigned(7700, 16));
        is_fahr_sig   <= '1';
        wait for 10 ms;

        -- ---------------------------------------------------------
        -- TEST 3: Zobrazenie 100.50 °C (Trojciferná teplota)
        -- ---------------------------------------------------------
        data_x100_sig <= std_logic_vector(to_unsigned(10050, 16));
        is_fahr_sig   <= '0';
        wait for 10 ms;

        -- Koniec simulácie
        wait;
    end process;

end architecture behavior;