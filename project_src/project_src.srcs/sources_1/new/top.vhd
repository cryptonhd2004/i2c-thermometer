library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        CLK100MHZ : in    std_logic;
        reset     : in    std_logic;
        SW        : in    std_logic;
        TMP_SDA   : inout std_logic;
        TMP_SCL   : out   std_logic;
        SEG       : out   std_logic_vector(6 downto 0);
        DP        : out   std_logic;                         
        AN        : out   std_logic_vector(7 downto 0);      
        LED       : out   std_logic_vector(7 downto 0)       
    );
end entity top;

architecture rtl of top is
    signal sda_dir       : std_logic;
    signal w_ce_200kHz   : std_logic;
    
    signal w_data_raw    : std_logic_vector(15 downto 0); 
    signal w_celsius     : std_logic_vector(15 downto 0); 
    signal w_fahrenheit  : std_logic_vector(15 downto 0); 
    signal w_data_disp   : std_logic_vector(15 downto 0); 
begin

    u_clkgen : entity work.clk_en
        generic map ( G_MAX => 500 )
        port map ( clk => CLK100MHZ, rst => reset, ce => w_ce_200kHz );

    u_master : entity work.i2c_master
        port map ( clk => CLK100MHZ, ce => w_ce_200kHz, reset => reset,
                   SDA => TMP_SDA, temp_data => w_data_raw, SDA_dir => sda_dir, SCL => TMP_SCL );

    u_temp_conv : entity work.temp_conv
        port map ( temp_raw => w_data_raw, celsius_x100 => w_celsius, fahrenheit_x100 => w_fahrenheit );

    w_data_disp <= w_celsius when SW = '0' else w_fahrenheit;

    u_seg7 : entity work.seg7
        port map ( clk_100MHz => CLK100MHZ, data_x100 => w_data_disp, is_fahr => SW,
                   SEG => SEG, DP => DP, AN => AN );

    LED <= w_data_raw(14 downto 7);
    
end architecture rtl;