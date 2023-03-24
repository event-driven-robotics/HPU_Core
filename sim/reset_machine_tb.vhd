-- ------------------------------------------------------------------------------ 
--  Project Name        : 
--  Design Name         : 
--  Starting date:      : 
--  Target Devices      : 
--  Tool versions       : 
--  Project Description : 
-- ------------------------------------------------------------------------------
--  Company             : IIT - Italian Institute of Technology  
--  Engineer            : Maurizio Casti
-- ------------------------------------------------------------------------------ 
-- ==============================================================================
--  PRESENT REVISION
-- ==============================================================================
--  File        : reset_machine_tb.vhd
--  Revision    : 1.0
--  Author      : M. Casti
--  Date        : 
-- ------------------------------------------------------------------------------
--  Description : Test Bench for "reset_machine"
--     
-- ==============================================================================
--  Revision history :
-- ==============================================================================
--
--  Revision 1.0: 
--  - Initial revision
--  (M. Casti - IIT)
-- 
-- ------------------------------------------------------------------------------

    
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  -- use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_textio.all;

 
entity reset_machine_tb is
  generic (
    CLK_PERIOD_g                 : integer := 10   -- CLK period [ns]
  );
end reset_machine_tb;
 
architecture behavior of reset_machine_tb is 
 
 
component reset_machine 
  generic (
    CLR_POLARITY_g            : string                 := "HIGH"; -- Active "HIGH" or "LOW"
    ARST_LONG_PERSISTANCE_g   : integer range 0 to 31  := 16;     -- Persistance of Power-On reset (clock pulses)
    ARST_ULONG_DURATION_MS_g  : integer range 0 to 255 := 10;     -- Duration of Ultrra-Long Reset (ms)
    HAS_POR_g                 : boolean                := TRUE    -- If TRUE a Power On Reset is generated 
    );
  port ( 
    CLK_i                     : in  std_logic;        -- Input Clock
    EN1MS_i                   : in  std_logic;        -- tick @ 1ms (for ultra-long reset generation)
    MCM_LOCKED_i              : in  std_logic := 'H'; -- Clock locked flag
    CLR_i                     : in  std_logic := 'L'; -- Polarity controlled Asyncronous Clear input
  
    -- Reset output
    ARST_o                    : out std_logic;        -- Active high asyncronous assertion, syncronous deassertion Reset output
    ARST_N_o                  : out std_logic;        -- Active low asyncronous assertion, syncronous deassertion Reset output 
    ARST_LONG_o               : out std_logic;	      -- Active high asyncronous assertion, syncronous deassertion Long Duration Reset output
    ARST_LONG_N_o             : out std_logic; 	      -- Active low asyncronous assertion, syncronous deassertion Long Duration Reset output 
    ARST_ULONG_o              : out std_logic;	      -- Active high asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output
    ARST_ULONG_N_o            : out std_logic;	      -- Active low asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output 
    
    RST_o                     : out std_logic;        -- Active high Syncronous Reset output
    RST_N_o                   : out std_logic;        -- Active low Syncronous Reset output 
    RST_LONG_o                : out std_logic;	      -- Active high Syncronous Long Duration Reset output
    RST_LONG_N_o              : out std_logic; 	      -- Active low Syncronous Long Duration Reset output 
    RST_ULONG_o               : out std_logic;	      -- Active high Syncronous Ultra-Long Duration Reset output
    RST_ULONG_N_o             : out std_logic 	      -- Active low Syncronous Ultra-Long Duration Reset output 
    );
end component;	

signal clk_100          : std_logic;
signal clk_locked       : std_logic;
signal clear_n          : std_logic;
signal arst             : std_logic;  
signal arst_n           : std_logic; 
signal arst_long        : std_logic; 
signal arst_long_n      : std_logic; 
signal arst_ulong       : std_logic; 
signal arst_ulong_n     : std_logic; 
signal rst              : std_logic;  
signal rst_n            : std_logic; 
signal rst_long         : std_logic; 
signal rst_long_n       : std_logic; 
signal rst_ulong        : std_logic; 
signal rst_ulong_n      : std_logic; 
signal en1ms            : std_logic;
	


begin 


RESET_MACHINE_m : reset_machine 
generic map( 
  CLR_POLARITY_g            => "LOW",         -- Active "HIGH" or "LOW"
  ARST_LONG_PERSISTANCE_g   => 16,            -- Persistance of Power-On reset (clock pulses)
  ARST_ULONG_DURATION_MS_g  => 10,            -- Duration of Ultrra-Long Reset (ms)
  HAS_POR_g                 => TRUE           -- If TRUE a Power On Reset is generated 
  )
port map(
 -- Clock in port
  CLK_i                     => clk_100,       -- Input Clock
  EN1MS_i                   => en1ms,         -- Tick @ 1ms (for ultra-long reset generation)
  MCM_LOCKED_i              => clk_locked,    -- Clock locked flag
  CLR_i                     => clear_n,       -- Polarity controlled Asyncronous Clear input
  
  -- Reset output
  ARST_o                    => arst,          -- Active high asyncronous assertion, syncronous deassertion Reset output
  ARST_N_o                  => arst_n,        -- Active low asyncronous assertion, syncronous deassertion Reset output 
  ARST_LONG_o               => arst_long,     -- Active high asyncronous assertion, syncronous deassertion Long Duration Reset output
  ARST_LONG_N_o             => arst_long_n,   -- Active low asyncronous assertion, syncronous deassertion Long Duration Reset output 
  ARST_ULONG_o              => arst_ulong,    -- Active high asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output
  ARST_ULONG_N_o            => arst_ulong_n,  -- Active low asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output 
 
  RST_o                     => rst,           -- Active high Syncronous Reset output
  RST_N_o                   => rst_n,         -- Active low Syncronous Reset output 
  RST_LONG_o                => rst_long,      -- Active high Syncronous Long Duration Reset output
  RST_LONG_N_o              => rst_long_n,    -- Active low Syncronous Long Duration Reset output 
  RST_ULONG_o               => rst_ulong,     -- Active high Syncronous Ultra-Long Duration Reset output
  RST_ULONG_N_o             => rst_ulong_n    -- Active low Syncronous Ultra-Long Duration Reset output 
  );

 

-- Stimulus process 

Clock_Proc : process
begin
  clk_100 <= '0';
  loop
    wait for (CLK_PERIOD_g/2 * 1 ns); 
    clk_100 <= not clk_100;
  end loop;
end process Clock_Proc;

En1ms_Proc : process
begin
  en1ms <= '0';
  wait for (100000 * 1 ns);  
  loop
    en1ms <= '1'; 
    wait for CLK_PERIOD_g * 1 ns;
    en1ms <= '0';
    wait for ((100000 - CLK_PERIOD_g) * 1 ns);
  end loop;
end process En1ms_Proc;

Reset_Proc : process
	begin
	  clk_locked <= '1';
		clear_n <= '1';
		wait for 20 ms; 
		clear_n <= '0';
		wait for 256 ns;
		clear_n <= '1';
		wait for 20 ms;
		clear_n <= '0';
		wait for 2 ns;
		clear_n <= '1';
		wait;
end process Reset_Proc;


end;
