-- ==============================================================================
-- DESCRIPTION:
-- Provides clock enables to FPGA fabric
-- ------------------------------------------
-- File        : time_machine.vhd
-- Revision    : 1.2
-- Author      : M. Casti
-- Date        : 19/03/2021
-- ==============================================================================
-- HISTORY (main changes) :
-- Revision 2.0:  12/11/2021 - M. Casti (IIT)
-- - Redesign of Reset Section
--
-- Revision 1.2:  19/03/2021 - M. Casti
-- - Output Reset RST_o fixed
-- - Added ASYNC attribute to reset synchronizers
--
-- Revision 1.1:  15/02/2021 - M. Casti
-- - Output Reset
-- - Added 10ms, 100ms, 1sec enable output
-- - Clock Period generic is REAL now
-- 
-- Revision 1.0:  04/05/2020 - M. Casti
-- - Initial release
-- 
-- ==============================================================================
-- WRITING STYLE 
-- 
-- INPUTs:    UPPERCASE followed by "_i"
-- OUTPUTs:   UPPERCASE followed by "_o"
-- BUFFERs:   UPPERCASE followed by "_b"
-- CONSTANTs: UPPERCASE followed by "_c"
-- GENERICs:  UPPERCASE followed by "_g"
-- 
-- ==============================================================================


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity time_machine is
  generic ( 
    CLK_PERIOD_NS_g           : real                   := 10.0;   -- Main Clock period
    CLR_POLARITY_g            : string                 := "HIGH"; -- Active "HIGH" or "LOW"
    ARST_LONG_PERSISTANCE_g   : integer range 0 to 31  := 16;     -- Persistance of Power-On reset (clock pulses)
    ARST_ULONG_DURATION_MS_g  : integer range 0 to 255 := 10;     -- Duration of Ultrra-Long Reset (ms)
    HAS_POR_g                 : boolean                := TRUE;   -- If TRUE a Power On Reset is generated 
    SIM_TIME_COMPRESSION_g    : boolean                := FALSE   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    );
  port (
    -- Clock in port
    CLK_i                     : in  std_logic;        -- Input Clock
    MCM_LOCKED_i              : in  std_logic := 'H'; -- Clock locked flag
    CLR_i                     : in  std_logic := 'L'; -- Polarity controlled Asyncronous Clear input
  
    -- Reset output
    ARST_o                    : out std_logic;        -- Active high asyncronous assertion, syncronous deassertion Reset output
    ARST_N_o                  : out std_logic;        -- Active low asyncronous assertion, syncronous deassertion Reset output 
    ARST_LONG_o               : out std_logic;	      -- Active high asyncronous assertion, syncronous deassertion Long Duration Reset output
    ARST_LONG_N_o             : out std_logic; 	      -- Active low asyncronous assertion, syncronous deassertion Long Duration Reset output 
    ARST_ULONG_o              : out std_logic;	      -- Active high asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output
    ARST_ULONG_N_o            : out std_logic;	      -- Active low asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output 
      
    -- Output ports for generated clock enables
    EN200NS_o                 : out std_logic;	      -- Clock enable every 200 ns
    EN1US_o                   : out std_logic;	      -- Clock enable every 1 us
    EN10US_o                  : out std_logic;	      -- Clock enable every 10 us
    EN100US_o                 : out std_logic;	      -- Clock enable every 100 us
    EN1MS_o                   : out std_logic;	      -- Clock enable every 1 ms
    EN10MS_o                  : out std_logic;	      -- Clock enable every 10 ms
    EN100MS_o                 : out std_logic;	      -- Clock enable every 100 ms
    EN1S_o                    : out std_logic 	      -- Clock enable every 1 s
    );
end time_machine;

architecture Behavioral of time_machine is

attribute ASYNC_REG : string;

-- Internal signals

-- -------------------------------------------------------------------------------------------------------------------------
-- Resets

-- Asynchronous reset with synchronous deassertion
function clr_pol(a : string) return std_logic is
begin
  if    a = "LOW"  then return '0';
  elsif a = "HIGH" then return '1';
  else report "Configuration not supported" severity failure; return '0';
  end if;
end function;

function has_por(a : boolean) return std_logic is
begin
  if    a = FALSE  then return '0';
  elsif a = TRUE then return '1';
  else report "Configuration not supported" severity failure; return '0';
  end if;
end function;

function has_por_vect(a : boolean; b : integer; c : integer) return std_logic_vector is
begin
  if    a = FALSE  then return conv_std_logic_vector(0, c);
  elsif a = TRUE then return conv_std_logic_vector(b, c);
  else report "Configuration not supported" severity failure; return conv_std_logic_vector(0, c);
  end if;
end function;

constant CLR_POL_c    : std_logic := clr_pol(CLR_POLARITY_g); 

signal clear : std_logic;

signal pp_arst, p_arst, arst        : std_logic := has_por(HAS_POR_g);
  attribute ASYNC_REG of pp_arst    : signal is "TRUE";
  attribute ASYNC_REG of p_arst     : signal is "TRUE";
  attribute ASYNC_REG of arst       : signal is "TRUE";
signal pp_arst_n, p_arst_n, arst_n  : std_logic := not has_por(HAS_POR_g);
  attribute ASYNC_REG of pp_arst_n  : signal is "TRUE";
  attribute ASYNC_REG of p_arst_n   : signal is "TRUE";
  attribute ASYNC_REG of arst_n     : signal is "TRUE";

-- Long Reset
signal long_arst_cnt  : std_logic_vector(4 downto 0) := has_por_vect(HAS_POR_g, ARST_LONG_PERSISTANCE_g, 5);
signal long_arst      : std_logic := has_por(HAS_POR_g);
signal long_arst_n    : std_logic := not has_por(HAS_POR_g);

-- Ultra-Long Reset
signal ulong_arst_cnt  : std_logic_vector(7 downto 0) := has_por_vect(HAS_POR_g, ARST_ULONG_DURATION_MS_g, 8);
signal ulong_arst      : std_logic := has_por(HAS_POR_g);
signal ulong_arst_n    : std_logic := not has_por(HAS_POR_g);

-- -------------------------------------------------------------------------------------------------------------------------
-- Enable generation Counters

signal en200ns_cnt    : std_logic_vector(4 downto 0);  
signal en200ns_cnt_tc : std_logic;  
signal p_en200ns      : std_logic;  
signal en200ns        : std_logic;	

signal en1us_cnt      : std_logic_vector(2 downto 0);  
signal en1us_cnt_tc   : std_logic;  
signal p_en1us        : std_logic;  
signal en1us          : std_logic;	

signal en10us_cnt     : std_logic_vector(3 downto 0);  
signal en10us_cnt_tc  : std_logic;  
signal p_en10us       : std_logic;  
signal en10us         : std_logic;	

signal en100us_cnt    : std_logic_vector(3 downto 0);  
signal en100us_cnt_tc : std_logic;  
signal p_en100us      : std_logic;  
signal en100us        : std_logic;	

signal en1ms_cnt      : std_logic_vector(3 downto 0);  
signal en1ms_cnt_tc   : std_logic;  
signal p_en1ms        : std_logic;  
signal en1ms          : std_logic;	

signal en10ms_cnt     : std_logic_vector(3 downto 0);  
signal en10ms_cnt_tc  : std_logic;  
signal p_en10ms       : std_logic;  
signal en10ms         : std_logic;	

signal en100ms_cnt    : std_logic_vector(3 downto 0);  
signal en100ms_cnt_tc : std_logic;  
signal p_en100ms      : std_logic;  
signal en100ms        : std_logic;	

signal en1s_cnt       : std_logic_vector(3 downto 0);  
signal en1s_cnt_tc    : std_logic;  
signal p_en1s         : std_logic;  
signal en1s           : std_logic;	

-- -------------------------------------------------------------------------------------------------------------------------
-- Calculation of constants used in generation of Enables
function scale_value (a : natural; b : boolean; p : real) return natural is
constant BASE_COUNT_c : natural := natural ((200.0/p)-1.0);
variable temp : natural;
begin
  case a is                                                               --                                                                    FALSE      TRUE
    when 0 => if b then temp := 7; else temp := BASE_COUNT_c;  end if;    return temp;  --   en200ns_period = CLK_i_period * (temp + 1)    -->    200 ns     80 ns
    when 1 => if b then temp := 4; else temp :=            4;  end if;    return temp;  --   en1us_period   = en200ns_period * (temp + 1)  -->      1 us    400 ns
    when 2 => if b then temp := 1; else temp :=            9;  end if;    return temp;  --   en10us_period  = en1us_period * (temp + 1)    -->     10 us    800 ns
    when 3 => if b then temp := 1; else temp :=            9;  end if;    return temp;  --   en100us_period = en10us_period * (temp + 1)   -->    100 us   1.60 us
    when 4 => if b then temp := 1; else temp :=            9;  end if;    return temp;  --   en1ms_period   = en100us_period * (temp + 1)  -->      1 ms   3.20 us
    when 5 => if b then temp := 1; else temp :=            9;  end if;    return temp;  --   en10ms_period  = en1ms_period * (temp + 1)    -->     10 ms   6.40 us
    when 6 => if b then temp := 1; else temp :=            9;  end if;    return temp;  --   en100ms_period = en10ms_period * (temp + 1)  -->     100 ms   12.8 us
    when 7 => if b then temp := 1; else temp :=            9;  end if;    return temp;  --   en1s_period    = en100ms_period * (temp + 1)  -->      1  s   25.6 us
    when others => report "Configuration not supported" severity failure; return 0;
  end case;
end function;

constant EN200NS_CONSTANT_c : natural := scale_value(0, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN1US_CONSTANT_c   : natural := scale_value(1, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN10US_CONSTANT_c  : natural := scale_value(2, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN100US_CONSTANT_c : natural := scale_value(3, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN1MS_CONSTANT_c   : natural := scale_value(4, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN10MS_CONSTANT_c  : natural := scale_value(5, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN100MS_CONSTANT_c : natural := scale_value(6, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);
constant EN1S_CONSTANT_c    : natural := scale_value(7, SIM_TIME_COMPRESSION_g, CLK_PERIOD_NS_g);

begin


-- ---------------------------------------------------------------------------------------------------
-- RESET DEASSERTION SYNCRONIZATION

clear <= not MCM_LOCKED_i or (CLR_i xnor CLR_POL_c);

process(CLK_i, clear)
begin
  if (clear = '1') then
    pp_arst_n  <= '0';
    p_arst_n   <= '0';
    arst_n     <= '0';
    
    pp_arst    <= '1';
    p_arst     <= '1';
    arst       <= '1';   
    
  elsif rising_edge(CLK_i) then
    pp_arst_n <= '1';
    p_arst_n  <= pp_arst_n;
    arst_n    <= p_arst_n;
 
    pp_arst   <= '0';
    p_arst    <= pp_arst;
    arst      <= p_arst;   
 
  end if;
end process;  



-- ---------------------------------------------------------------------------------------------------
-- LONG RESET

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    long_arst_cnt <= conv_std_logic_vector(ARST_LONG_PERSISTANCE_g-1, long_arst_cnt'length);
    long_arst     <= '1';
    long_arst_n   <= '0';  
  elsif rising_edge(CLK_i) then
    if (long_arst_cnt = conv_std_logic_vector(0, long_arst_cnt'length)) then
      long_arst     <= '0';
      long_arst_n   <= '1';
    else
      long_arst_cnt <= long_arst_cnt - 1;
    end if;
  end if;
end process; 



-- ---------------------------------------------------------------------------------------------------
-- ULTRA-LONG RESET

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    ulong_arst_cnt <= conv_std_logic_vector(ARST_ULONG_DURATION_MS_g-1, ulong_arst_cnt'length);
    ulong_arst     <= '1';
    ulong_arst_n   <= '0'; 
  elsif rising_edge(CLK_i) then
    if (en1ms = '1') then
      if (ulong_arst_cnt = conv_std_logic_vector(0, ulong_arst_cnt'length)) then
        ulong_arst     <= '0';
        ulong_arst_n   <= '1';  
      else
        ulong_arst_cnt <= ulong_arst_cnt - 1;
      end if;
    end if;
  end if;
end process;  


-- -------------------------------------------------------------------------------------------------------------------------
-- CLOCK ENABLES



-- Enable @ 200 ns
en200ns_cnt_tc <= '1' when (en200ns_cnt = conv_std_logic_vector(EN200NS_CONSTANT_c, en200ns_cnt'length)) else '0'; 
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en200ns_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (en200ns_cnt_tc = '1') then
      en200ns_cnt <= (others => '0');  
    else 
      en200ns_cnt <= en200ns_cnt + 1;
    end if;
  end if;
end process; 

p_en200ns <= en200ns_cnt_tc;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en200ns <= '0';
  elsif rising_edge(CLK_i) then
    en200ns <= p_en200ns;
  end if;
end process;  


-- -------------------------------------------------------------------------------------------------------
-- Enable @ 1 us
en1us_cnt_tc <= '1' when (en1us_cnt = conv_std_logic_vector(EN1US_CONSTANT_c ,en1us_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en1us_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en200ns = '1') then
      if (en1us_cnt_tc = '1') then 
        en1us_cnt <= (others => '0');  
      else 
        en1us_cnt <= en1us_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en1us <= en1us_cnt_tc and p_en200ns;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en1us <= '0';
  elsif rising_edge(CLK_i) then
    en1us <= p_en1us;
  end if;
end process;  
  

-- Enable @ 10 us
en10us_cnt_tc <= '1' when (en10us_cnt = conv_std_logic_vector(EN10US_CONSTANT_c ,en10us_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en10us_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en1us = '1') then
      if (en10us_cnt_tc = '1') then 
        en10us_cnt <= (others => '0');  
      else 
        en10us_cnt <= en10us_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en10us <= en10us_cnt_tc and p_en1us;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en10us <= '0';
  elsif rising_edge(CLK_i) then
    en10us <= p_en10us;
  end if;
end process;  
  

-- Enable @ 100 us
en100us_cnt_tc <= '1' when (en100us_cnt = conv_std_logic_vector(EN100US_CONSTANT_c ,en100us_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en100us_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en10us = '1') then
      if (en100us_cnt_tc = '1') then 
        en100us_cnt <= (others => '0');  
      else 
        en100us_cnt <= en100us_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en100us <= en100us_cnt_tc and p_en10us;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en100us <= '0';
  elsif rising_edge(CLK_i) then
    en100us <= p_en100us;
  end if;
end process;  
  
  
-- -------------------------------------------------------------------------------------------------------  
-- Enable @ 1  ms
en1ms_cnt_tc <= '1' when (en1ms_cnt = conv_std_logic_vector(EN1MS_CONSTANT_c, en1ms_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en1ms_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en100us = '1') then
      if (en1ms_cnt_tc = '1') then 
        en1ms_cnt <= (others => '0');  
      else 
        en1ms_cnt <= en1ms_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en1ms <= en1ms_cnt_tc and p_en100us;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en1ms <= '0';
  elsif rising_edge(CLK_i) then
    en1ms <= p_en1ms;
  end if;
end process;  
  

-- Enable @ 10 ms
en10ms_cnt_tc <= '1' when (en10ms_cnt = conv_std_logic_vector(EN10MS_CONSTANT_c ,en10ms_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en10ms_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en1ms = '1') then
      if (en10ms_cnt_tc = '1') then 
        en10ms_cnt <= (others => '0');  
      else 
        en10ms_cnt <= en10ms_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en10ms <= en10ms_cnt_tc and p_en1ms;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en10ms <= '0';
  elsif rising_edge(CLK_i) then
    en10ms <= p_en10ms;
  end if;
end process;  
  

-- Enable @ 100 us
en100ms_cnt_tc <= '1' when (en100ms_cnt = conv_std_logic_vector(EN100MS_CONSTANT_c ,en100ms_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en100ms_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en10ms = '1') then
      if (en100ms_cnt_tc = '1') then 
        en100ms_cnt <= (others => '0');  
      else 
        en100ms_cnt <= en100ms_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en100ms <= en100ms_cnt_tc and p_en10ms;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en100ms <= '0';
  elsif rising_edge(CLK_i) then
    en100ms <= p_en100ms;
  end if;
end process;  
  
  
-- Enable @ 1  ms
en1s_cnt_tc <= '1' when (en1s_cnt = conv_std_logic_vector(EN1S_CONSTANT_c, en1s_cnt'length)) else '0';
process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en1s_cnt <= (others => '0');
  elsif rising_edge(CLK_i) then
    if (p_en100ms = '1') then
      if (en1s_cnt_tc = '1') then 
        en1s_cnt <= (others => '0');  
      else 
        en1s_cnt <= en1s_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en1s <= en1s_cnt_tc and p_en100ms;

process(CLK_i, arst_n)
begin
  if (arst_n = '0') then
    en1s <= '0';
  elsif rising_edge(CLK_i) then
    en1s <= p_en1s;
  end if;
end process;  



-- ---------------------------------------------------------------------------------------------------
-- OUTPUTS

ARST_o          <= arst;
ARST_N_o        <= arst_n;
ARST_LONG_o     <= long_arst;
ARST_LONG_N_o   <= long_arst_n;
ARST_ULONG_o    <= ulong_arst;
ARST_ULONG_N_o  <= ulong_arst_n;

EN200NS_o         <= en200ns;
EN1US_o           <= en1us;
EN10US_o          <= en10us;
EN100US_o         <= en100us;
EN1MS_o           <= en1ms;
EN10MS_o          <= en10ms;
EN100MS_o         <= en100ms;
EN1S_o            <= en1s;
  
end Behavioral;

