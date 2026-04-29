library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master_tb is
end entity i2c_master_tb;

architecture sim of i2c_master_tb is

    signal clk             : std_logic := '0';
    signal ce              : std_logic := '0';
    signal reset           : std_logic := '0';
    signal SDA             : std_logic := 'Z';
    signal SDA_dir         : std_logic;
    signal SCL             : std_logic;
    signal temp_data       : std_logic_vector(15 downto 0); -- Rozšířeno na 16 bitů
    signal slave_drive_low : std_logic := '0';

begin

    uut : entity work.i2c_master
        port map (
            clk        => clk,
            ce         => ce,
            reset      => reset,
            SDA        => SDA,
            temp_data  => temp_data,
            SDA_dir    => SDA_dir,
            SCL        => SCL
        );

    --------------------------------------------------------------------
    -- Clock: 100 MHz (perioda 10 ns) pro Nexys A7
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Clock Enable: 200 kHz (1 pulz každých 500 taktů 100MHz hodin)
    --------------------------------------------------------------------
    ce_process : process
        variable cnt : integer := 0;
    begin
        while true loop
            wait until rising_edge(clk);
            if cnt = 499 then
                ce  <= '1';
                cnt := 0;
            else
                ce  <= '0';
                cnt := cnt + 1;
            end if;
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
        wait for 100 ns;
        reset <= '0';
        
        -- POZOR: 1 I2C cyklus (POWER_UP až NACK) trvá cca 12.8 ms!
        -- Odeslání 20 teplot potřebuje 20 * 12.8 = cca 256 ms.
        wait for 300 ms; 
        
        report "Simulace uspesne ukoncena." severity note;
        wait;
    end process;

    --------------------------------------------------------------------
    -- Slave model: Odpovídá na čtení od mastera
    --------------------------------------------------------------------
    slave_process : process

        procedure send_temp(
            constant tx_data : in std_logic_vector(15 downto 0)
        ) is
        begin
            -- Čekej na SCL falling edge kdy master přešel do read fáze
            loop
                wait until falling_edge(SCL);
                exit when SDA_dir = '0';
            end loop;

            -- ACK od slave (po přijetí adresy)
            slave_drive_low <= '1';
            wait until falling_edge(SCL);
            slave_drive_low <= '0';

            -- Odeslání MSB bajtu (8 bitů)
            for bit_idx in 15 downto 8 loop
                if tx_data(bit_idx) = '0' then
                    slave_drive_low <= '1';
                else
                    slave_drive_low <= '0';
                end if;
                wait until falling_edge(SCL);
            end loop;

            -- Master odesílá ACK, slave musí uvolnit sběrnici a počkat 1 takt!
            slave_drive_low <= '0';
            wait until falling_edge(SCL);

            -- Odeslání LSB bajtu (8 bitů)
            for bit_idx in 7 downto 0 loop
                if tx_data(bit_idx) = '0' then
                    slave_drive_low <= '1';
                else
                    slave_drive_low <= '0';
                end if;
                wait until falling_edge(SCL);
            end loop;
            
            -- Uvolnění sběrnice před stavem NACK
            slave_drive_low <= '0';
        end procedure;

    begin
        slave_drive_low <= '0';
        wait for 5000 ns;

        -- Stimuly upravené pro formát senzoru ADT7420
        -- Vypočet: (Stupně * 16) * 8 = Hodnota převedená do binární soustavy.
        -- Příklad: 25.0 °C  --> (25 * 16) * 8 = 3200 (binárně "0000110010000000")
        -- Příklad: 25.5 °C  --> (25.5 * 16) * 8 = 3264 (binárně "0000110011000000")

        --  0 °C -> temp_data = 0000000000000000
        send_temp("0000000000000000");
        wait for 50 ns;

        --  5 °C -> temp_data = 0000001010000000
        send_temp("0000001010000000");
        wait for 50 ns;

        -- 10 °C -> temp_data = 0000010100000000
        send_temp("0000010100000000");
        wait for 50 ns;

        -- 15 °C -> temp_data = 0000011110000000
        send_temp("0000011110000000");
        wait for 50 ns;

        -- 20 °C -> temp_data = 0000101000000000
        send_temp("0000101000000000");
        wait for 50 ns;

        -- 25 °C -> temp_data = 0000110010000000
        send_temp("0000110010000000");
        wait for 50 ns;
        
        -- 25.5 °C -> temp_data = 0000110011000000
        send_temp("0000110011000000");
        wait for 50 ns;

        -- 30 °C -> temp_data = 0000111100000000
        send_temp("0000111100000000");
        wait for 50 ns;

        -- 35 °C -> temp_data = 0001000110000000
        send_temp("0001000110000000");
        wait for 50 ns;

        -- 37.25 °C -> temp_data = 0001001010100000
        send_temp("0001001010100000");
        wait for 50 ns;

        -- 40 °C -> temp_data = 0001010000000000
        send_temp("0001010000000000");
        wait for 50 ns;

        -- 45 °C -> temp_data = 0001011010000000
        send_temp("0001011010000000");
        wait for 50 ns;

        -- 50 °C -> temp_data = 0001100100000000
        send_temp("0001100100000000");
        wait for 50 ns;

        -- 55 °C -> temp_data = 0001101110000000
        send_temp("0001101110000000");
        wait for 50 ns;

        -- 60 °C -> temp_data = 0001111000000000
        send_temp("0001111000000000");
        wait for 50 ns;

        -- 65 °C -> temp_data = 0010000010000000
        send_temp("0010000010000000");
        wait for 50 ns;

        -- 70 °C -> temp_data = 0010001100000000
        send_temp("0010001100000000");
        wait for 50 ns;

        -- 75 °C -> temp_data = 0010010110000000
        send_temp("0010010110000000");
        wait for 50 ns;

        -- 80 °C -> temp_data = 0010100000000000
        send_temp("0010100000000000");
        wait for 50 ns;

        -- 90 °C -> temp_data = 0010110100000000
        send_temp("0010110100000000");
        wait for 50 ns;

        -- 95.75 °C -> temp_data = 0010111111100000
        send_temp("0010111111100000");

        wait;
    end process;

end architecture sim;