--------------------------------------------------------------------------------
-- Company             : IIT
-- Engineer            : Maurizio Casti
-------------------------------------------------------------------------------- 
--==============================================================================
-- PRESENT REVISION
--==============================================================================
-- File        : time_machine.vhd
-- Revision    : 1.0
-- Author      : M. Casti
-- Date        : 
--------------------------------------------------------------------------------
-- Description :
--    Time Machine provides clocks, clock enables and resets to FPGA fabric
--==============================================================================
-- Revision history :
--==============================================================================
--
-- Revision 1.0:  05/11/2018
-- - Initial revision
-- (M. Casti - IIT)
--
-- ==============================================================================
-- 
-- LEGENDA e Stile di scrittura
-- 
-- INPUT:  UPPER CASE con suffisso _i
-- OUTPUT: UPPER CASE con suffisso _o
-- BUFFER: UPPERCASE con suffisso _b (non usato)
-- COSTANTI: UPPERCASE con suffisso _k
-- GENERICS: UPPERCASE con suffisso _g
-- 
-- ==============================================================================

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;


entity time_machine is
generic ( 
  SIM_TIME_COMPRESSION_g : boolean := FALSE; -- Se "TRUE", la simulazione viene "compressa": i clock enable non seguono le tempistiche reali
  INIT_DELAY             : natural := 32     -- Ritardo dal rilascio del reset all'impulso di "init"
  );
port (
  -- Clock in port
  CLK_100M_i           : in  std_logic;  -- Ingresso 100 MHz
  -- Enable ports
  EN100NS_100_o        : out std_logic;	-- Clock enable a 100 ns
  EN1US_100_o          : out std_logic;	-- Clock enable a 1 us
  EN10US_100_o         : out std_logic;	-- Clock enable a 10 us
  EN100US_100_o        : out std_logic;	-- Clock enable a 100 us
  EN1MS_100_o          : out std_logic;	-- Clock enable a 1 ms
  EN10MS_100_o         : out std_logic;	-- Clock enable a 10 ms
  EN100MS_100_o        : out std_logic;	-- Clock enable a 100 ms
  EN1S_100_o           : out std_logic;	-- Clock enable a 1 s
  -- Reset output port 
  RESYNC_CLEAR_N_o     : out std_logic; -- Clear resincronizzato
  INIT_RESET_100_o     : out std_logic;	-- Reset sincrono a 32 colpi di clock dal Clear resincronizzato (logica positiva)
  INIT_RESET_N_100_o   : out std_logic;	-- Reset sincrono a 32 colpi di clock dal Clear resincronizzato (logica negativa)
  -- Status and control signals
  CLEAR_N_i            : in  std_logic   -- Clear asincrono che reinizializza le macchine di timing
  );
end time_machine;

architecture Behavioral of time_machine is

-- Generazione delle costanti di tempo degli Enable
function scale_value (a : natural; b : boolean) return natural is
variable temp : natural;
begin
  case a is                                                               --                                                           FALSE      TRUE
    when 0 => if b then temp := 4; else temp := 9;  end if; return temp;  --   en100ns_period = clk_period * (temp + 1)        -->    100 ns     50 ns
    when 1 => if b then temp := 1; else temp := 9;  end if; return temp;  --   en1us_period   = en100ns_period * (temp + 1)    -->      1 us    100 ns
    when 2 => if b then temp := 4; else temp := 9;  end if; return temp;  --   en10us_period  = en1us_period * (temp + 1)      -->     10 us    500 ns
    when 3 => if b then temp := 1; else temp := 9;  end if; return temp;  --   en100us_period = en10us_period * (temp + 1)     -->    100 us      1 us
    when 4 => if b then temp := 9; else temp := 9;  end if; return temp;  --   en1ms_period   = en100us_period * (temp + 1)    -->      1 ms     10 us
    when 5 => if b then temp := 9; else temp := 9;  end if; return temp;  --   en10ms_period  = en1ms_period * (temp + 1)      -->     10 ms    100 us
    when 6 => if b then temp := 9; else temp := 9;  end if; return temp;  --   en100ms_period = en10ms_period * (temp + 1)     -->    100 ms      1 ms
    when 7 => if b then temp := 9; else temp := 9;  end if; return temp;  --   en1s_period    = en100ms_period * (temp + 1)    -->      1 s      10 ms
    when others => report "Configuration not supported" 
	               severity failure; 
				   return 0;
  end case;
end function;


-- Determinazione dell'ampiezza di bus
function bus_width (a : natural) return natural is
variable i : natural;
variable r : real;
begin
r := real(a);
i := 0;
while (r > 1.0) loop
  r := r/2.0;
  i := i + 1;
end loop;
return i;
end function;

constant EN100ns_CONSTANT_k : natural := scale_value(0, SIM_TIME_COMPRESSION_g);
constant EN1US_CONSTANT_k   : natural := scale_value(1, SIM_TIME_COMPRESSION_g);
constant EN10US_CONSTANT_k  : natural := scale_value(2, SIM_TIME_COMPRESSION_g);
constant EN100US_CONSTANT_k : natural := scale_value(3, SIM_TIME_COMPRESSION_g);
constant EN1MS_CONSTANT_k   : natural := scale_value(4, SIM_TIME_COMPRESSION_g);
constant EN10MS_CONSTANT_k  : natural := scale_value(5, SIM_TIME_COMPRESSION_g);
constant EN100MS_CONSTANT_k : natural := scale_value(6, SIM_TIME_COMPRESSION_g);
constant EN1S_CONSTANT_k    : natural := scale_value(7, SIM_TIME_COMPRESSION_g);

constant INIT_DELAY_WIDTH   : natural := bus_width(INIT_DELAY-1); -- NOTA: si considera (INIT_DELAY - 1) perché l'impulso viene registrato, per cui si aggiunge un colpo di latenza

signal init_reset_cnt       : std_logic_vector(INIT_DELAY_WIDTH-1 downto 0) := conv_std_logic_vector(INIT_DELAY-1,INIT_DELAY_WIDTH);
signal init_reset_cnt_tcn   : std_logic;
signal init_reset_cnt_tcn_d : std_logic := '0';
signal init_reset           : std_logic := '0';
signal init_reset_n         : std_logic := '0';
 
signal p_resync_clear_n : std_logic := '0';   
signal resync_clear_n   : std_logic := '0';   

signal en100ns_cnt      : std_logic_vector(bus_width(EN100ns_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en100ns_cnt_tc   : std_logic;  
signal p_en100ns        : std_logic;  
signal en100ns_100      : std_logic;	

signal en1us_cnt        : std_logic_vector(bus_width(EN1us_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en1us_cnt_tc     : std_logic;  
signal p_en1us          : std_logic;  
signal en1us_100        : std_logic;	

signal en10us_cnt       : std_logic_vector(bus_width(EN10us_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en10us_cnt_tc    : std_logic;  
signal p_en10us         : std_logic;  
signal en10us_100       : std_logic;	

signal en100us_cnt      : std_logic_vector(bus_width(EN100us_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en100us_cnt_tc   : std_logic;  
signal p_en100us        : std_logic;  
signal en100us_100      : std_logic;	

signal en1ms_cnt        : std_logic_vector(bus_width(EN1ms_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en1ms_cnt_tc     : std_logic;  
signal p_en1ms          : std_logic;  
signal en1ms_100        : std_logic;	

signal en10ms_cnt       : std_logic_vector(bus_width(EN10ms_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en10ms_cnt_tc    : std_logic;  
signal p_en10ms         : std_logic;  
signal en10ms_100       : std_logic;	

signal en100ms_cnt      : std_logic_vector(bus_width(EN100ms_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en100ms_cnt_tc   : std_logic;  
signal p_en100ms        : std_logic;  
signal en100ms_100      : std_logic;	

signal en1s_cnt         : std_logic_vector(bus_width(EN1s_CONSTANT_k)-1 downto 0) := (others => '0');  
signal en1s_cnt_tc      : std_logic;  
signal p_en1s           : std_logic;  
signal en1s_100         : std_logic;	





begin


-- --------------------------------------------------------------------------------------------------- 	
-- Gestione e sincronizzazione del clear 
process(CLK_100M_i, CLEAR_N_i)
begin
  if (CLEAR_N_i = '0') then
    p_resync_clear_n <= '0';                  -- Asserzione asincrona
    resync_clear_n   <= '0';
  elsif rising_edge(CLK_100M_i) then
    p_resync_clear_n <= '1';                  -- Deasserzione sincrona, con
	resync_clear_n   <= p_resync_clear_n;     -- doppio flip-flop anti metastabilità
  end if;
end process;

-- --------------------------------------------------------------------------------------------------- 	
-- INIT RESET Machine

init_reset_cnt_tcn <= '1' when init_reset_cnt = conv_std_logic_vector(0,INIT_DELAY_WIDTH) else '0';
process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    init_reset_cnt <= conv_std_logic_vector(INIT_DELAY-1,INIT_DELAY_WIDTH);
  elsif rising_edge(CLK_100M_i) then
    init_reset_cnt_tcn_d <= init_reset_cnt_tcn;
    init_reset   <= init_reset_cnt_tcn and not init_reset_cnt_tcn_d;
    init_reset_n <= not (init_reset_cnt_tcn and not init_reset_cnt_tcn_d);
    if (init_reset_cnt_tcn = '0') then
      init_reset_cnt <= init_reset_cnt - 1; 
    end if; 
  end if;                                                              
end process; 

-- ---------------------------------------------------------------------------------------------------
-- CLOCK ENABLES

-- Enable a 100 ns
en100ns_cnt_tc <= '1' when (en100ns_cnt = conv_std_logic_vector(en100ns_CONSTANT_k, en100ns_cnt'length)) else '0'; 
process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en100ns_cnt <= (others => '0');
  elsif rising_edge(CLK_100M_i) then
    if (en100ns_cnt_tc = '1') then
      en100ns_cnt <= (others => '0');  
    else 
      en100ns_cnt <= en100ns_cnt + 1;
    end if;
  end if;
end process; 

p_en100ns <= en100ns_cnt_tc;

process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en100ns_100 <= '0';
  elsif rising_edge(CLK_100M_i) then
    en100ns_100 <= p_en100ns;
  end if;
end process;  


-- Enable a 1 us
en1us_cnt_tc <= '1' when (en1us_cnt = conv_std_logic_vector(EN1US_CONSTANT_k, en1us_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en1us_cnt <= (others => '0');
  elsif rising_edge(CLK_100M_i) then
    if (p_en100ns = '1') then
      if (en1us_cnt_tc = '1') then 
        en1us_cnt <= (others => '0');  
      else 
        en1us_cnt <= en1us_cnt + 1;
      end if;
	end if;
  end if;
end process; 

p_en1us <= en1us_cnt_tc and p_en100ns;

process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en1us_100 <= '0';
  elsif rising_edge(CLK_100M_i) then
    en1us_100 <= p_en1us;
  end if;
end process;  
  

-- Enable a 10 us
en10us_cnt_tc <= '1' when (en10us_cnt = conv_std_logic_vector(EN10US_CONSTANT_k ,en10us_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en10us_cnt <= (others => '0');
  elsif rising_edge(CLK_100M_i) then
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

process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en10us_100 <= '0';
  elsif rising_edge(CLK_100M_i) then
    en10us_100 <= p_en10us;
  end if;
end process;  
  

-- Enable a 100 us
en100us_cnt_tc <= '1' when (en100us_cnt = conv_std_logic_vector(EN100US_CONSTANT_k ,en100us_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en100us_cnt <= (others => '0');
  elsif rising_edge(CLK_100M_i) then
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

process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en100us_100 <= '0';
  elsif rising_edge(CLK_100M_i) then
    en100us_100 <= p_en100us;
  end if;
end process;  
  
  
-- Enable a 1  ms
en1ms_cnt_tc <= '1' when (en1ms_cnt = conv_std_logic_vector(EN1MS_CONSTANT_k, en1ms_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en1ms_cnt <= (others => '0');
  elsif rising_edge(CLK_100M_i) then
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

process(CLK_100M_i, resync_clear_n)
begin
  if (resync_clear_n = '0') then
    en1ms_100 <= '0';
  elsif rising_edge(CLK_100M_i) then
    en1ms_100 <= p_en1ms;
  end if;
end process;  
  

-- Enable a 10 ms
en10ms_cnt_tc <= '1' when (en10ms_cnt = conv_std_logic_vector(EN10MS_CONSTANT_k ,en10ms_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
if (resync_clear_n = '0') then
  en10ms_cnt <= (others => '0');
elsif rising_edge(CLK_100M_i) then
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

process(CLK_100M_i, resync_clear_n)
begin
if (resync_clear_n = '0') then
  en10ms_100 <= '0';
elsif rising_edge(CLK_100M_i) then
  en10ms_100 <= p_en10ms;
end if;
end process;  


-- Enable a 100 ms
en100ms_cnt_tc <= '1' when (en100ms_cnt = conv_std_logic_vector(EN100MS_CONSTANT_k ,en100ms_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
if (resync_clear_n = '0') then
  en100ms_cnt <= (others => '0');
elsif rising_edge(CLK_100M_i) then
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

process(CLK_100M_i, resync_clear_n)
begin
if (resync_clear_n = '0') then
  en100ms_100 <= '0';
elsif rising_edge(CLK_100M_i) then
  en100ms_100 <= p_en100ms;
end if;
end process;  


-- Enable a 1  s
en1s_cnt_tc <= '1' when (en1s_cnt = conv_std_logic_vector(EN1S_CONSTANT_k, en1s_cnt'length)) else '0';
process(CLK_100M_i, resync_clear_n)
begin
if (resync_clear_n = '0') then
  en1s_cnt <= (others => '0');
elsif rising_edge(CLK_100M_i) then
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

process(CLK_100M_i, resync_clear_n)
begin
if (resync_clear_n = '0') then
  en1s_100 <= '0';
elsif rising_edge(CLK_100M_i) then
  en1s_100 <= p_en1s;
end if;
end process; 
  

  

  


-- ---------------------------------------------------------------------------------------------------
-- USCITE

EN100NS_100_o       <= en100ns_100;
EN1US_100_o         <= en1us_100;
EN10US_100_o        <= en10us_100;
EN100US_100_o       <= en100us_100;
EN1MS_100_o         <= en1ms_100;
EN10MS_100_o        <= en10ms_100;
EN100MS_100_o       <= en100ms_100;
EN1S_100_o          <= en1s_100;

INIT_RESET_100_o    <= init_reset;
INIT_RESET_N_100_o  <= init_reset_n;

RESYNC_CLEAR_N_o    <= resync_clear_n;
  
end Behavioral;

