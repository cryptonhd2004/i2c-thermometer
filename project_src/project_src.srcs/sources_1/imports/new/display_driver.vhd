library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7 is
    port (
        clk_100MHz : in  std_logic;                          -- Nexys A7 clock
        temp_data  : in  std_logic_vector(7 downto 0);       -- hodnota na zobrazeni
        is_fahr    : in  std_logic;                          -- '1' = vypiš F, '0' = vypiš C
        SEG        : out std_logic_vector(6 downto 0);       -- segmenty (active low)
        NAN        : out std_logic_vector(3 downto 0);       -- nepouzite, all off
        AN         : out std_logic_vector(3 downto 0)        -- 4 anody (active low)
    );
end entity seg7;

architecture rtl of seg7 is

    signal tens  : integer range 0 to 9 := 0;
    signal ones  : integer range 0 to 9 := 0;

    -- Definice segmentu (CA CB CC CD CE CF CG) - Active Low
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
    
    -- Speciální znaky
    constant DEG   : std_logic_vector(6 downto 0) := "0011100";  -- Znak stupně (°)
    constant C_SEG : std_logic_vector(6 downto 0) := "0110001";  -- Písmeno C
    constant F_SEG : std_logic_vector(6 downto 0) := "0111000";  -- Písmeno F
    constant BLANK : std_logic_vector(6 downto 0) := "1111111";  -- Zhasnuto

    -- Multiplexovani anod
    signal anode_select : unsigned(1 downto 0) := "00";
    signal anode_timer  : unsigned(16 downto 0) := (others => '0');

    signal seg_reg : std_logic_vector(6 downto 0) := (others => '1');
    signal an_reg  : std_logic_vector(3 downto 0) := (others => '1');

begin

    --------------------------------------------------------------------
    -- BCD převod (0 az 99)
    --------------------------------------------------------------------
    process(temp_data)
        variable t_int : integer range 0 to 255;
    begin
        t_int := to_integer(unsigned(temp_data));
        
        if t_int >= 99 then
            tens <= 9;
            ones <= 9;
        else
            -- Pro hodnoty 0-99 si syntezator snadno vytvoří ROM tabulku
            tens <= t_int / 10;
            ones <= t_int mod 10;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Digit refresh timer (1 ms na digit, 4 ms cely cyklus)
    --------------------------------------------------------------------
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if anode_timer = 99_999 then          -- 100 000 × 10 ns = 1 ms
                anode_timer  <= (others => '0');  
                anode_select <= anode_select + 1;
            else
                anode_timer <= anode_timer + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Anode selection (ktora cifra je zapnutá) - Active low pro Nexys
    --------------------------------------------------------------------
    process(anode_select)
    begin
        case anode_select is
            when "00" => an_reg <= "1110";  -- AN(0) - Úplne vpravo
            when "01" => an_reg <= "1101";  -- AN(1) 
            when "10" => an_reg <= "1011";  -- AN(2) 
            when "11" => an_reg <= "0111";  -- AN(3) - Najviac vľavo (z našich 4)
            when others => an_reg <= "1111";
        end case;
    end process;

    --------------------------------------------------------------------
    -- Segment dekoder podla zvoleneho digitu (OPRAVENÉ PORADIE)
    --------------------------------------------------------------------
    process(anode_select, ones, tens, is_fahr)
    begin
        case anode_select is

            -- Pozice 3 (AN3 - vľavo): Desiatky teploty
            when "11" =>
                if tens = 0 then
                    seg_reg <= BLANK;
                else
                    case tens is
                        when 1 => seg_reg <= ONE;
                        when 2 => seg_reg <= TWO;
                        when 3 => seg_reg <= THREE;
                        when 4 => seg_reg <= FOUR;
                        when 5 => seg_reg <= FIVE;
                        when 6 => seg_reg <= SIX;
                        when 7 => seg_reg <= SEVEN;
                        when 8 => seg_reg <= EIGHT;
                        when 9 => seg_reg <= NINE;
                        when others => seg_reg <= BLANK;
                    end case;
                end if;

            -- Pozice 2 (AN2): Jednotky teploty
            when "10" =>
                case ones is
                    when 0 => seg_reg <= ZERO;
                    when 1 => seg_reg <= ONE;
                    when 2 => seg_reg <= TWO;
                    when 3 => seg_reg <= THREE;
                    when 4 => seg_reg <= FOUR;
                    when 5 => seg_reg <= FIVE;
                    when 6 => seg_reg <= SIX;
                    when 7 => seg_reg <= SEVEN;
                    when 8 => seg_reg <= EIGHT;
                    when 9 => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            -- Pozice 1 (AN1): Symbol stupnu
            when "01" =>
                seg_reg <= DEG;

            -- Pozice 0 (AN0 - úplne vpravo): Jednotka (C nebo F)
            when "00" =>
                if is_fahr = '1' then
                    seg_reg <= F_SEG;
                else
                    seg_reg <= C_SEG;
                end if;

            when others =>
                seg_reg <= BLANK;

        end case;
    end process;

    -- Výstupy
    SEG <= seg_reg;
    AN  <= an_reg;
    NAN <= "1111";  -- Další 4 anody na Nexys 100T vypnuté (Active Low)

end architecture rtl;