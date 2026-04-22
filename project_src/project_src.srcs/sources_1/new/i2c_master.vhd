library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    port (
        clk        : in    std_logic;  -- Systémové hodiny (100 MHz)
        ce         : in    std_logic;  -- Clock Enable pulzy (200 kHz)
        reset      : in    std_logic;
        SDA        : inout std_logic;
        temp_data  : out   std_logic_vector(7 downto 0);
        SDA_dir    : out   std_logic;
        SCL        : out   std_logic
    );
end entity i2c_master;

architecture rtl of i2c_master is

    constant SENSOR_ADDRESS_PLUS_READ : std_logic_vector(7 downto 0) := "10010111";

    type state_type is (
        POWER_UP, START,
        SEND_ADDR6, SEND_ADDR5, SEND_ADDR4, SEND_ADDR3, SEND_ADDR2, SEND_ADDR1, SEND_ADDR0,
        SEND_RW, REC_ACK,
        REC_MSB7, REC_MSB6, REC_MSB5, REC_MSB4, REC_MSB3, REC_MSB2, REC_MSB1, REC_MSB0,
        SEND_ACK,
        REC_LSB7, REC_LSB6, REC_LSB5, REC_LSB4, REC_LSB3, REC_LSB2, REC_LSB1, REC_LSB0,
        NACK
    );

    signal state_reg     : state_type := POWER_UP;

    signal scl_div_cnt   : unsigned(3 downto 0)  := (others => '0');
    signal scl_reg       : std_logic := '1';

    signal count         : unsigned(11 downto 0) := (others => '0');

    signal tMSB          : std_logic_vector(7 downto 0) := (others => '0');
    signal tLSB          : std_logic_vector(7 downto 0) := (others => '0');
    signal temp_data_reg : std_logic_vector(7 downto 0) := (others => '0');

    signal o_bit         : std_logic := '1';
    signal i_bit         : std_logic;
    signal sda_dir_int   : std_logic;

begin

    --------------------------------------------------------------------
    -- SCL divider: 200 kHz -> 10 kHz (řízeno pomocí CE)
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            scl_div_cnt <= (others => '0');
            scl_reg     <= '0';
        elsif rising_edge(clk) then
            if ce = '1' then
                if scl_div_cnt = to_unsigned(9, scl_div_cnt'length) then
                    scl_div_cnt <= (others => '0');
                    scl_reg     <= not scl_reg;
                else
                    scl_div_cnt <= scl_div_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    SCL <= scl_reg;

    --------------------------------------------------------------------
    -- Main state machine (řízeno pomocí CE)
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= POWER_UP;
            count     <= (others => '0');
            o_bit     <= '1';
            tMSB      <= (others => '0');
            tLSB      <= (others => '0');
        elsif rising_edge(clk) then
            if ce = '1' then
                count <= count + 1;

                case state_reg is
                    when POWER_UP =>
                        if count = to_unsigned(1999, count'length) then
                            state_reg <= START;
                        end if;

                    when START =>
                        if count = to_unsigned(2004, count'length) then
                            o_bit <= '0';
                        elsif count = to_unsigned(2013, count'length) then
                            state_reg <= SEND_ADDR6;
                        end if;

                    when SEND_ADDR6 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(7);
                        if count = to_unsigned(2033, count'length) then
                            state_reg <= SEND_ADDR5;
                        end if;

                    when SEND_ADDR5 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(6);
                        if count = to_unsigned(2053, count'length) then
                            state_reg <= SEND_ADDR4;
                        end if;

                    when SEND_ADDR4 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(5);
                        if count = to_unsigned(2073, count'length) then
                            state_reg <= SEND_ADDR3;
                        end if;

                    when SEND_ADDR3 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(4);
                        if count = to_unsigned(2093, count'length) then
                            state_reg <= SEND_ADDR2;
                        end if;

                    when SEND_ADDR2 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(3);
                        if count = to_unsigned(2113, count'length) then
                            state_reg <= SEND_ADDR1;
                        end if;

                    when SEND_ADDR1 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(2);
                        if count = to_unsigned(2133, count'length) then
                            state_reg <= SEND_ADDR0;
                        end if;

                    when SEND_ADDR0 =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(1);
                        if count = to_unsigned(2153, count'length) then
                            state_reg <= SEND_RW;
                        end if;

                    when SEND_RW =>
                        o_bit <= SENSOR_ADDRESS_PLUS_READ(0);
                        if count = to_unsigned(2169, count'length) then
                            state_reg <= REC_ACK;
                        end if;

                    when REC_ACK =>
                        if count = to_unsigned(2189, count'length) then
                            state_reg <= REC_MSB7;
                        end if;

                    when REC_MSB7 =>
                        tMSB(7) <= i_bit;
                        if count = to_unsigned(2209, count'length) then
                            state_reg <= REC_MSB6;
                        end if;

                    when REC_MSB6 =>
                        tMSB(6) <= i_bit;
                        if count = to_unsigned(2229, count'length) then
                            state_reg <= REC_MSB5;
                        end if;

                    when REC_MSB5 =>
                        tMSB(5) <= i_bit;
                        if count = to_unsigned(2249, count'length) then
                            state_reg <= REC_MSB4;
                        end if;

                    when REC_MSB4 =>
                        tMSB(4) <= i_bit;
                        if count = to_unsigned(2269, count'length) then
                            state_reg <= REC_MSB3;
                        end if;

                    when REC_MSB3 =>
                        tMSB(3) <= i_bit;
                        if count = to_unsigned(2289, count'length) then
                            state_reg <= REC_MSB2;
                        end if;

                    when REC_MSB2 =>
                        tMSB(2) <= i_bit;
                        if count = to_unsigned(2309, count'length) then
                            state_reg <= REC_MSB1;
                        end if;

                    when REC_MSB1 =>
                        tMSB(1) <= i_bit;
                        if count = to_unsigned(2329, count'length) then
                            state_reg <= REC_MSB0;
                        end if;

                    when REC_MSB0 =>
                        o_bit   <= '0';
                        tMSB(0) <= i_bit;
                        if count = to_unsigned(2349, count'length) then
                            state_reg <= SEND_ACK;
                        end if;

                    when SEND_ACK =>
                        if count = to_unsigned(2369, count'length) then
                            state_reg <= REC_LSB7;
                        end if;

                    when REC_LSB7 =>
                        tLSB(7) <= i_bit;
                        if count = to_unsigned(2389, count'length) then
                            state_reg <= REC_LSB6;
                        end if;

                    when REC_LSB6 =>
                        tLSB(6) <= i_bit;
                        if count = to_unsigned(2409, count'length) then
                            state_reg <= REC_LSB5;
                        end if;

                    when REC_LSB5 =>
                        tLSB(5) <= i_bit;
                        if count = to_unsigned(2429, count'length) then
                            state_reg <= REC_LSB4;
                        end if;

                    when REC_LSB4 =>
                        tLSB(4) <= i_bit;
                        if count = to_unsigned(2449, count'length) then
                            state_reg <= REC_LSB3;
                        end if;

                    when REC_LSB3 =>
                        tLSB(3) <= i_bit;
                        if count = to_unsigned(2469, count'length) then
                            state_reg <= REC_LSB2;
                        end if;

                    when REC_LSB2 =>
                        tLSB(2) <= i_bit;
                        if count = to_unsigned(2489, count'length) then
                            state_reg <= REC_LSB1;
                        end if;

                    when REC_LSB1 =>
                        tLSB(1) <= i_bit;
                        if count = to_unsigned(2509, count'length) then
                            state_reg <= REC_LSB0;
                        end if;

                    when REC_LSB0 =>
                        o_bit   <= '1';
                        tLSB(0) <= i_bit;
                        if count = to_unsigned(2529, count'length) then
                            state_reg <= NACK;
                        end if;

                    when NACK =>
                        if count = to_unsigned(2559, count'length) then
                            count     <= (others => '0');
                            state_reg <= POWER_UP;
                        end if;

                end case;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Temperature output buffer (řízeno pomocí CE)
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if ce = '1' then
                if state_reg = NACK then
                    temp_data_reg <= tMSB(6 downto 0) & tLSB(7);
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- SDA direction and tri-state (kombinační logika)
    --------------------------------------------------------------------
    sda_dir_int <= '1' when (
                        state_reg = POWER_UP   or
                        state_reg = START      or
                        state_reg = SEND_ADDR6 or
                        state_reg = SEND_ADDR5 or
                        state_reg = SEND_ADDR4 or
                        state_reg = SEND_ADDR3 or
                        state_reg = SEND_ADDR2 or
                        state_reg = SEND_ADDR1 or
                        state_reg = SEND_ADDR0 or
                        state_reg = SEND_RW    or
                        state_reg = SEND_ACK   or
                        state_reg = NACK
                    ) else '0';

    SDA_dir <= sda_dir_int;
    SDA     <= o_bit when sda_dir_int = '1' else 'Z';
    i_bit   <= to_X01(SDA);

    temp_data <= temp_data_reg;

end architecture rtl;