library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7 is
    port (
        clk_100MHz : in  std_logic;
        data_x100  : in  std_logic_vector(15 downto 0);  
        is_fahr    : in  std_logic;
        SEG        : out std_logic_vector(6 downto 0);
        DP         : out std_logic;                      
        AN         : out std_logic_vector(7 downto 0)
    );
end entity seg7;

architecture rtl of seg7 is
    signal hundreds   : integer range 0 to 9;
    signal tens       : integer range 0 to 9;
    signal ones       : integer range 0 to 9;
    signal tenths     : integer range 0 to 9;
    signal hundredths : integer range 0 to 9;

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
    constant DEG   : std_logic_vector(6 downto 0) := "0011100";
    constant C_SEG : std_logic_vector(6 downto 0) := "0110001";
    constant F_SEG : std_logic_vector(6 downto 0) := "0111000";
    constant BLANK : std_logic_vector(6 downto 0) := "1111111";

    signal anode_select : unsigned(2 downto 0) := "000";
    signal anode_timer  : unsigned(16 downto 0) := (others => '0');
    signal seg_reg : std_logic_vector(6 downto 0) := BLANK;
    signal an_reg  : std_logic_vector(7 downto 0) := (others => '1');

begin
    process(data_x100)
        variable val : integer;
    begin
        val := to_integer(unsigned(data_x100));
        hundreds   <= (val / 10000) mod 10;
        tens       <= (val / 1000) mod 10;
        ones       <= (val / 100) mod 10;
        tenths     <= (val / 10) mod 10;
        hundredths <= val mod 10;
    end process;

    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if anode_timer = 99_999 then
                anode_timer  <= (others => '0');
                anode_select <= anode_select + 1;
            else
                anode_timer <= anode_timer + 1;
            end if;
        end if;
    end process;

    process(anode_select)
    begin
        DP <= '1'; 
        case anode_select is
            when "000" => an_reg <= "11111110"; 
            when "001" => an_reg <= "11111101"; 
            when "010" => an_reg <= "11111011"; 
            when "011" => an_reg <= "11110111"; 
            when "100" => an_reg <= "11101111"; DP <= '0'; 
            when "101" => an_reg <= "11011111"; 
            when "110" => an_reg <= "10111111"; 
            when others => an_reg <= "11111111";
        end case;
    end process;

    process(anode_select, hundredths, tenths, ones, tens, hundreds, is_fahr)
        function decode(digit: integer) return std_logic_vector is
        begin
            case digit is
                when 0 => return ZERO; when 1 => return ONE; when 2 => return TWO; when 3 => return THREE;
                when 4 => return FOUR; when 5 => return FIVE; when 6 => return SIX; when 7 => return SEVEN;
                when 8 => return EIGHT;when 9 => return NINE; when others => return BLANK;
            end case;
        end function;
    begin
        case anode_select is
            when "000" => if is_fahr='1' then seg_reg <= F_SEG; else seg_reg <= C_SEG; end if;
            when "001" => seg_reg <= DEG;
            when "010" => seg_reg <= decode(hundredths);
            when "011" => seg_reg <= decode(tenths);
            when "100" => seg_reg <= decode(ones);
            when "101" => if hundreds = 0 and tens = 0 then seg_reg <= BLANK; else seg_reg <= decode(tens); end if;
            when "110" => if hundreds = 0 then seg_reg <= BLANK; else seg_reg <= decode(hundreds); end if;
            when others => seg_reg <= BLANK;
        end case;
    end process;

    SEG <= seg_reg;
    AN  <= an_reg;
end architecture rtl;