-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : Fri, 17 Apr 2026 07:16:16 GMT
-- Request id : cfwk-fed377c2-69e1de406a50b

library ieee;
use ieee.std_logic_1164.all;

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

    constant TbPeriod : time := 1000 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : seg7
    port map (clk_100MHz => clk_100MHz,
              temp_data  => temp_data,
              SEG        => SEG,
              NAN        => NAN,
              AN         => AN);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk_100MHz is really your main clock signal
    clk_100MHz <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed
        temp_data <= (others => '0');

        -- ***EDIT*** Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_seg7 of tb_seg7 is
    for tb
    end for;
end cfg_tb_seg7;