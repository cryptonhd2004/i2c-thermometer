library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        CLK100MHZ : in    std_logic;                         -- nexys clk signal
        reset     : in    std_logic;                         -- btnC on nexys
        TMP_SDA   : inout std_logic;                         -- i2c sda on temp sensor
        TMP_SCL   : out   std_logic;                         -- i2c scl on temp sensor
        SEG       : out   std_logic_vector(6 downto 0);      -- 7 segments
        AN        : out   std_logic_vector(3 downto 0);      -- 4 anodes of 4 displays
        NAN       : out   std_logic_vector(3 downto 0);      -- 4 anodes always OFF
        LED       : out   std_logic_vector(7 downto 0)       -- leds = binary temp
    );
end entity top;

architecture rtl of top is

    signal sda_dir   : std_logic;                            -- směr SDA (diag)
    signal w_200kHz  : std_logic;                            -- 200 kHz clock
    signal w_data    : std_logic_vector(7 downto 0);         -- temp data from i2c_master

begin

    --------------------------------------------------------------------
    -- I2C master
    --------------------------------------------------------------------
    u_master : entity work.i2c_master
        port map (
            clk_200kHz => w_200kHz,
            reset      => reset,
            SDA        => TMP_SDA,
            temp_data  => w_data,
            SDA_dir    => sda_dir,
            SCL        => TMP_SCL
        );

    --------------------------------------------------------------------
    -- 200 kHz clock generator
    --------------------------------------------------------------------
    u_clkgen : entity work.clkgen_200kHz
        port map (
            clk_100MHz => CLK100MHZ,
            clk_200kHz => w_200kHz
        );

    --------------------------------------------------------------------
    -- 7-segment display controller
    --------------------------------------------------------------------
    u_seg7 : entity work.seg7
        port map (
            clk_100MHz => CLK100MHZ,
            temp_data  => w_data,
            SEG        => SEG,
            NAN        => NAN,
            AN         => AN
        );

    --------------------------------------------------------------------
    -- LEDs = binární teplota
    --------------------------------------------------------------------
    LED <= w_data;

end architecture rtl;