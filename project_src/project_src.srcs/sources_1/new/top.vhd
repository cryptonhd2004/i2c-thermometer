library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        CLK100MHZ : in    std_logic;                         -- nexys clk signal
        reset     : in    std_logic;                         -- btnC on nexys
        SW        : in    std_logic;                         -- switch pro vyber C/F (např. SW0)
        TMP_SDA   : inout std_logic;                         -- i2c sda on temp sensor
        TMP_SCL   : out   std_logic;                         -- i2c scl on temp sensor
        SEG       : out   std_logic_vector(6 downto 0);      -- 7 segments
        AN        : out   std_logic_vector(3 downto 0);      -- 4 anodes of 4 displays
        NAN       : out   std_logic_vector(3 downto 0);      -- 4 anodes always OFF
        LED       : out   std_logic_vector(7 downto 0)       -- leds = binary temp (always Celsius)
    );
end entity top;

architecture rtl of top is

    signal sda_dir       : std_logic;                            -- směr SDA (diag)
    signal w_ce_200kHz   : std_logic;                            -- 200 kHz clock enable pulzy
    
    -- Datové signály
    signal w_data_raw    : std_logic_vector(7 downto 0);         -- surová data z I2C
    signal w_celsius     : std_logic_vector(7 downto 0);         -- data v C
    signal w_fahrenheit  : std_logic_vector(7 downto 0);         -- data ve F
    signal w_data_disp   : std_logic_vector(7 downto 0);         -- data, která půjdou na displej

begin

    --------------------------------------------------------------------
    -- 200 kHz clock enable generator
    --------------------------------------------------------------------
    u_clkgen : entity work.clk_en
        generic map (
            G_MAX => 500  -- 100 MHz / 200 kHz
        )
        port map (
            clk => CLK100MHZ,
            rst => reset,
            ce  => w_ce_200kHz
        );

    --------------------------------------------------------------------
    -- I2C master
    --------------------------------------------------------------------
    u_master : entity work.i2c_master
        port map (
            clk        => CLK100MHZ,      
            ce         => w_ce_200kHz,    
            reset      => reset,
            SDA        => TMP_SDA,
            temp_data  => w_data_raw,     -- výstup surových dat
            SDA_dir    => sda_dir,
            SCL        => TMP_SCL
        );

    --------------------------------------------------------------------
    -- Temperature Converter (C to F)
    --------------------------------------------------------------------
    u_temp_conv : entity work.temp_conv
        port map (
            temp_data  => w_data_raw,
            celsius    => w_celsius,
            fahrenheit => w_fahrenheit
        );

    --------------------------------------------------------------------
    -- Multiplexor pro displej: Výběr C nebo F pomocí přepínače SW
    --------------------------------------------------------------------
    -- SW = '0' -> zobrazení v Celsiích
    -- SW = '1' -> zobrazení ve Fahrenheitech
    w_data_disp <= w_celsius when SW = '0' else w_fahrenheit;

    --------------------------------------------------------------------
    -- 7-segment display controller
    --------------------------------------------------------------------
      u_seg7 : entity work.seg7
        port map (
            clk_100MHz => CLK100MHZ,
            temp_data  => w_data_disp,
            is_fahr    => SW,               -- Přidáno sem!
            SEG        => SEG,
            NAN        => NAN,
            AN         => AN
        );

    --------------------------------------------------------------------
    -- LEDs = binární teplota
    --------------------------------------------------------------------
    -- LED diody necháváme vždy ukazovat surová data ze senzoru (Celsius)
    LED <= w_data_raw;

end architecture rtl;