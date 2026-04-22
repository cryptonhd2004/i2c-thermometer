library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_en is
    generic (
        -- Pro 100 MHz sys clk a 200 kHz CE: 100M / 200k = 500
        G_MAX : positive := 500
    );
    Port ( 
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        ce  : out STD_LOGIC
    );
end clk_en;

architecture Behavioral of clk_en is
    signal sig_cnt : integer range 0 to G_MAX-1 := 0;
begin
    process (clk) is
    begin
        if rising_edge(clk) then 
            if rst = '1' then     
                ce      <= '0';   
                sig_cnt <= 0;     
            elsif sig_cnt = G_MAX-1 then
                ce      <= '1';
                sig_cnt <= 0;
            else
                ce      <= '0';
                sig_cnt <= sig_cnt + 1;
            end if;
        end if;
    end process;
end Behavioral;