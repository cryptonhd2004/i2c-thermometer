library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7 is
    port (
        clk_100MHz : in  std_logic;                          -- Nexys A7 clock
        temp_data  : in  std_logic_vector(7 downto 0);       -- z i2c_master
        SEG        : out std_logic_vector(6 downto 0);       -- segmenty (active low)
        NAN        : out std_logic_vector(3 downto 0);       -- nepouzite, all off
        AN         : out std_logic_vector(3 downto 0)        -- 4 anody
    );
end entity seg7;

architecture rtl of seg7 is

    -- Binary to BCD (desitaky, jednotky)
    signal tens  : unsigned(3 downto 0);
    signal ones  : unsigned(3 downto 0);

    -- Vypis jednotlivych cislic
    constant ZERO  : std_logic_vector(6 downto 0) := "0000001";
    constant ONE   : std_logic_vector(6 downto 0) := "1001111";
    constant TWO   : std_logic_vector(6 downto 0) := "0010010";
    constant THREE : std_logic_vector(6 downto 0) := "0000110";
    constant FOUR  : std_logic_vector(6 downto 0) := "1001100";
    constant FIVE  : std_logic_vector(6 downto 0) := "0100100";
    constant SIX   : std_logic_vector(6 downto 0) := "0100000";
    constant SEVEN : std_logic_vector(6 downto 0) := "0001111";
    constant EIGHT : std_logic_vector(6 downto 0) := "0000000";
    constant NINE  : std_logic_vector(6 downto 0) := "0000100";
    constant DEG   : std_logic_vector(6 downto 0) := "0011100";  -- °
    constant C_SEG : std_logic_vector(6 downto 0) := "0110001";  -- C

    -- anode control
    signal anode_select : unsigned(1 downto 0) := (others => '0');
    signal anode_timer  : unsigned(16 downto 0) := (others => '0');

    signal seg_reg : std_logic_vector(6 downto 0) := (others => '1');
    signal an_reg  : std_logic_vector(3 downto 0) := (others => '1');

begin

    --------------------------------------------------------------------
    -- Binary -> desiatky, jednotky
    --------------------------------------------------------------------
    tens <= resize(unsigned(temp_data) / 10, 4);
    ones <= resize(unsigned(temp_data) mod 10, 4);

    --------------------------------------------------------------------
    -- Digit refresh timer (1 ms na digit, 4 ms cely cyklus)
    --------------------------------------------------------------------
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if anode_timer = to_unsigned(99_999, anode_timer'length) then
                anode_timer  <= (others => '0');  -- 100 000 × 10 ns = 1 ms
                anode_select <= anode_select + 1;
            else
                anode_timer <= anode_timer + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Anode selection (ktora cifra je zapnutá)
    --------------------------------------------------------------------
    process(anode_select)
    begin
        case anode_select is
            when "00" => an_reg <= "1110";  -- jednotky 
            when "01" => an_reg <= "1101";  -- desiatky
            when "10" => an_reg <= "1011";  -- stovky (°)
            when "11" => an_reg <= "0111";  -- tisicky (C)
            when others =>
                an_reg <= "1111";
        end case;
    end process;

    --------------------------------------------------------------------
    -- Segment dekoder podla zvoleneho digitu
    --------------------------------------------------------------------
    process(anode_select, ones, tens)
    begin
        case anode_select is

            -- tisicky: C
            when "11" =>
                seg_reg <= C_SEG;

            -- stovky:  symbol stupnov
            when "10" =>
                seg_reg <= DEG;

            -- desiatky teploty
            when "01" =>
                case tens is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= "1111111";
                end case;

            -- jednotky teploty
            when "00" =>
                case ones is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= "1111111";
                end case;

            when others =>
                seg_reg <= "1111111";

        end case;
    end process;

    -- výstupy
    SEG <= seg_reg;
    AN  <= an_reg;
    NAN <= (others => '1');  -- 4 anody „NAN" vypnuté (4'hF)

end architecture rtl;