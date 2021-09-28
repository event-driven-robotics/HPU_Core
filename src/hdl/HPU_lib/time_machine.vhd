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
    CLK_PERIOD_NS_g         : real := 10.0;                   -- Main Clock period
    CLEAR_POLARITY_g        : string := "LOW";                -- Active "HIGH" or "LOW"
    PON_RESET_DURATION_MS_g : integer range 0 to 255 := 10;   -- Duration of Power-On reset (ms)
    SIM_TIME_COMPRESSION_g  : in boolean := FALSE             -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    );
  port (
    -- Clock in port
    CLK_i                   : in  std_logic;   -- Input clock @ 50 MHz,
    CLEAR_i                 : in  std_logic;   -- Asynchronous active low reset
  
    -- Output reset
    RESET_o                 : out std_logic;    -- Reset out (active high)
    RESET_N_o               : out std_logic;    -- Reset out (active low)
    PON_RESET_OUT_o         : out std_logic;	  -- Power on Reset out (active high)
    PON_RESET_N_OUT_o       : out std_logic;	  -- Power on Reset out (active low)
    
    -- Output ports for generated clock enables
    EN200NS_o               : out std_logic;	  -- Clock enable every 200 ns
    EN1US_o                 : out std_logic;	  -- Clock enable every 1 us
    EN10US_o                : out std_logic;	  -- Clock enable every 10 us
    EN100US_o               : out std_logic;	  -- Clock enable every 100 us
    EN1MS_o                 : out std_logic;	  -- Clock enable every 1 ms
    EN10MS_o                : out std_logic;	  -- Clock enable every 10 ms
    EN100MS_o               : out std_logic;	  -- Clock enable every 100 ms
    EN1S_o                  : out std_logic 	  -- Clock enable every 1 s
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

constant CLR_POL_c    : std_logic := clr_pol(CLEAR_POLARITY_g); 

signal pp_rst_n, p_rst_n, rst_n : std_logic := '0';
attribute ASYNC_REG of pp_rst_n : signal is "TRUE";
attribute ASYNC_REG of p_rst_n  : signal is "TRUE";
attribute ASYNC_REG of rst_n    : signal is "TRUE";
signal pp_rst, p_rst, rst       : std_logic := '1';
attribute ASYNC_REG of pp_rst   : signal is "TRUE";
attribute ASYNC_REG of p_rst    : signal is "TRUE";
attribute ASYNC_REG of rst      : signal is "TRUE";

-- Power On Reset
signal pon_reset_cnt  : std_logic_vector(7 downto 0);
signal pon_reset      : std_logic := '1';
signal pon_reset_n    : std_logic := '0';  -- NOTE: it's important to initialize that signal to "1"

-- -------------------------------------------------------------------------------------------------------------------------
-- Counters

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

-- RST_N
process(CLK_i, CLEAR_i)
begin
  if (CLEAR_i = CLR_POL_c) then
    pp_rst_n  <= '0';
    p_rst_n   <= '0';
    rst_n     <= '0';
  elsif rising_edge(CLK_i) then
    pp_rst_n <= '1';
    p_rst_n  <= pp_rst_n;
    rst_n    <= p_rst_n;
  end if;
end process;  

-- RST
process(CLK_i, CLEAR_i)
begin
  if (CLEAR_i = CLR_POL_c) then
    pp_rst    <= '1';
    p_rst     <= '1';
    rst       <= '1';
  elsif rising_edge(CLK_i) then
    pp_rst   <= '0';
    p_rst    <= pp_rst;
    rst      <= p_rst;
  end if;
end process;  

-- ---------------------------------------------------------------------------------------------------
-- POWER ON RESET

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    pon_reset_cnt <= conv_std_logic_vector(PON_RESET_DURATION_MS_g, pon_reset_cnt'length);
    pon_reset     <= '1';
    pon_reset_n   <= '0';  -- NOTE: it's important to initialize that signal to "1"   
  elsif rising_edge(CLK_i) then
    if (en1ms = '1') then
      if (pon_reset_cnt = conv_std_logic_vector(0, pon_reset_cnt'length)) then
        pon_reset     <= '0';
        pon_reset_n   <= '1';  -- NOTE: it's important to initialize that signal to "1"
      else
        pon_reset_cnt <= pon_reset_cnt - 1;
      end if;
    end if;
  end if;
end process;  


-- -------------------------------------------------------------------------------------------------------------------------
-- CLOCK ENABLES



-- Enable @ 200 ns
en200ns_cnt_tc <= '1' when (en200ns_cnt = conv_std_logic_vector(EN200NS_CONSTANT_c, en200ns_cnt'length)) else '0'; 
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en200ns <= '0';
  elsif rising_edge(CLK_i) then
    en200ns <= p_en200ns;
  end if;
end process;  


-- -------------------------------------------------------------------------------------------------------
-- Enable @ 1 us
en1us_cnt_tc <= '1' when (en1us_cnt = conv_std_logic_vector(EN1US_CONSTANT_c ,en1us_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en1us <= '0';
  elsif rising_edge(CLK_i) then
    en1us <= p_en1us;
  end if;
end process;  
  

-- Enable @ 10 us
en10us_cnt_tc <= '1' when (en10us_cnt = conv_std_logic_vector(EN10US_CONSTANT_c ,en10us_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en10us <= '0';
  elsif rising_edge(CLK_i) then
    en10us <= p_en10us;
  end if;
end process;  
  

-- Enable @ 100 us
en100us_cnt_tc <= '1' when (en100us_cnt = conv_std_logic_vector(EN100US_CONSTANT_c ,en100us_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en100us <= '0';
  elsif rising_edge(CLK_i) then
    en100us <= p_en100us;
  end if;
end process;  
  
  
-- -------------------------------------------------------------------------------------------------------  
-- Enable @ 1  ms
en1ms_cnt_tc <= '1' when (en1ms_cnt = conv_std_logic_vector(EN1MS_CONSTANT_c, en1ms_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en1ms <= '0';
  elsif rising_edge(CLK_i) then
    en1ms <= p_en1ms;
  end if;
end process;  
  

-- Enable @ 10 ms
en10ms_cnt_tc <= '1' when (en10ms_cnt = conv_std_logic_vector(EN10MS_CONSTANT_c ,en10ms_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en10ms <= '0';
  elsif rising_edge(CLK_i) then
    en10ms <= p_en10ms;
  end if;
end process;  
  

-- Enable @ 100 us
en100ms_cnt_tc <= '1' when (en100ms_cnt = conv_std_logic_vector(EN100MS_CONSTANT_c ,en100ms_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en100ms <= '0';
  elsif rising_edge(CLK_i) then
    en100ms <= p_en100ms;
  end if;
end process;  
  
  
-- Enable @ 1  ms
en1s_cnt_tc <= '1' when (en1s_cnt = conv_std_logic_vector(EN1S_CONSTANT_c, en1s_cnt'length)) else '0';
process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
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

process(CLK_i, rst_n)
begin
  if (rst_n = '0') then
    en1s <= '0';
  elsif rising_edge(CLK_i) then
    en1s <= p_en1s;
  end if;
end process;  




-- ---------------------------------------------------------------------------------------------------
-- OUTPUTS

RESET_o           <= rst;
RESET_N_o         <= rst_n;
PON_RESET_OUT_o   <= pon_reset;
PON_RESET_N_OUT_o <= pon_reset_n;

EN200NS_o         <= en200ns;
EN1US_o           <= en1us;
EN10US_o          <= en10us;
EN100US_o         <= en100us;
EN1MS_o           <= en1ms;
EN10MS_o          <= en10ms;
EN100MS_o         <= en100ms;
EN1S_o            <= en1s;
  
end Behavioral;

