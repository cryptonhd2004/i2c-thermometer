library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master_tb is
end entity i2c_master_tb;

architecture sim of i2c_master_tb is

    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0';
    signal SDA             : std_logic := 'Z';
    signal SDA_dir         : std_logic;
    signal SCL             : std_logic;
    signal temp_data       : std_logic_vector(7 downto 0);
    signal slave_drive_low : std_logic := '0';

begin

    uut : entity work.i2c_master
        port map (
            clk_200kHz => clk,
            reset      => reset,
            SDA        => SDA,
            temp_data  => temp_data,
            SDA_dir    => SDA_dir,
            SCL        => SCL
        );

    --------------------------------------------------------------------
    -- Clock: 2 ns perioda = 500 MHz simulační clock
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for 1 ns;
            clk <= '1'; wait for 1 ns;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Open-drain SDA: weak pull-up + slave driver
    --------------------------------------------------------------------
    SDA <= 'H';
    SDA <= '0' when slave_drive_low = '1' else 'Z';

    --------------------------------------------------------------------
    -- Reset + délka simulace
    --------------------------------------------------------------------
    stim_process : process
    begin
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 500000 ns;
        wait;
    end process;

    --------------------------------------------------------------------
    -- Slave model: 5 teplot, 50 ns rozestup
    --------------------------------------------------------------------
    slave_process : process

        procedure send_temp(
            constant tx_data : in std_logic_vector(15 downto 0)
        ) is
            variable bit_idx : integer;
        begin
            -- čekej na SCL falling edge kdy master přešel do read fáze
            loop
                wait until falling_edge(SCL);
                exit when SDA_dir = '0';
            end loop;

            -- ACK
            slave_drive_low <= '1';
            wait until rising_edge(SCL);
            wait until falling_edge(SCL);
            slave_drive_low <= '0';

            -- 16 bitů MSB první
            bit_idx := 15;
            while bit_idx >= 0 loop
                wait until falling_edge(SCL);
                if tx_data(bit_idx) = '0' then
                    slave_drive_low <= '1';
                else
                    slave_drive_low <= '0';
                end if;
                wait until rising_edge(SCL);
                bit_idx := bit_idx - 1;
            end loop;

            wait until falling_edge(SCL);
            slave_drive_low <= '0';
        end procedure;

        begin
        slave_drive_low <= '0';
        wait for 5000 ns;

        --  0 °C -> temp_data = 00000000
        send_temp("0000000000000000");
        wait for 50 ns;

        --  5 °C -> temp_data = 00000101
        send_temp("0000010100000000");
        wait for 50 ns;

        -- 10 °C -> temp_data = 00001010
        send_temp("0000101000000000");
        wait for 50 ns;

        -- 15 °C -> temp_data = 00001111
        send_temp("0000111100000000");
        wait for 50 ns;

        -- 20 °C -> temp_data = 00010100
        send_temp("0001010000000000");
        wait for 50 ns;

        -- 25 °C -> temp_data = 00011001
        send_temp("0001100100000000");
        wait for 50 ns;

        -- 30 °C -> temp_data = 00011110
        send_temp("0001111000000000");
        wait for 50 ns;

        -- 35 °C -> temp_data = 00100011
        send_temp("0010001100000000");
        wait for 50 ns;

        -- 37 °C -> temp_data = 00100101
        send_temp("0010010100000000");
        wait for 50 ns;

        -- 40 °C -> temp_data = 00101000
        send_temp("0010100000000000");
        wait for 50 ns;

        -- 45 °C -> temp_data = 00101101
        send_temp("0010110100000000");
        wait for 50 ns;

        -- 50 °C -> temp_data = 00110010
        send_temp("0011001000000000");
        wait for 50 ns;

        -- 55 °C -> temp_data = 00110111
        send_temp("0011011100000000");
        wait for 50 ns;

        -- 60 °C -> temp_data = 00111100
        send_temp("0011110000000000");
        wait for 50 ns;

        -- 65 °C -> temp_data = 01000001
        send_temp("0100000100000000");
        wait for 50 ns;

        -- 70 °C -> temp_data = 01000110
        send_temp("0100011000000000");
        wait for 50 ns;

        -- 75 °C -> temp_data = 01001011
        send_temp("0100101100000000");
        wait for 50 ns;

        -- 80 °C -> temp_data = 01010000
        send_temp("0101000000000000");
        wait for 50 ns;

        -- 90 °C -> temp_data = 01011010
        send_temp("0101101000000000");
        wait for 50 ns;

        -- 95 °C -> temp_data = 01011111
        send_temp("0101111100000000");

        wait;
    end process;

end architecture sim;