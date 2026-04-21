library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Pridane pre pracu s to_unsigned

entity tb_seg7 is
end tb_seg7;

architecture tb of tb_seg7 is

    component seg7
        port (clk_100MHz : in std_logic;
              temp_data  : in std_logic_vector (7 downto 0);
              SEG        : out std_logic_vector (6 downto 0);
              NAN        : out std_logic_vector (3 downto 0);
              AN         : out std_logic_vector (3 downto 0));
    end component;

    signal clk_100MHz : std_logic;
    signal temp_data  : std_logic_vector (7 downto 0);
    signal SEG        : std_logic_vector (6 downto 0);
    signal NAN        : std_logic_vector (3 downto 0);
    signal AN         : std_logic_vector (3 downto 0);

    -- 100 MHz clock -> perioda je 10 ns
    constant TbPeriod : time := 10 ns; 
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : seg7
    port map (clk_100MHz => clk_100MHz,
              temp_data  => temp_data,
              SEG        => SEG,
              NAN        => NAN,
              AN         => AN);

    -- Generovanie 100 MHz hodinoveho signalu
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk_100MHz <= TbClock;

    stimuli : process
    begin
        -- Inicializacia
        temp_data <= (others => '0');
        wait for 100 * TbPeriod; -- kratky reset cas

        -- TEST 1: Teplota 25 stupnov
        -- Prevod integer cisla na 8-bitovy std_logic_vector
        temp_data <= std_logic_vector(to_unsigned(25, 8));
        
        -- Cakame 5 milisekund (5 000 000 ns). 
        -- Pripomenutie: Cely cyklus prepnutia vsetkych 4 cifier vo tvojom kode trva 4 ms.
        wait for 5 ms;

        -- TEST 2: Teplota 8 stupnov (overenie zobrazenia nuly na desiatkach)
        temp_data <= std_logic_vector(to_unsigned(8, 8));
        wait for 5 ms;

        -- TEST 3: Teplota 99 stupnov (maximalna dvojciferna hodnota)
        temp_data <= std_logic_vector(to_unsigned(99, 8));
        wait for 5 ms;

        -- Ukoncenie simulacie
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

configuration cfg_tb_seg7 of tb_seg7 is
    for tb
    end for;
end cfg_tb_seg7;