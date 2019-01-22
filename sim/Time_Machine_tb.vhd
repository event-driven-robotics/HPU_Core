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
--  File        : HPUcore_tb.vhd
--  Revision    : 1.0
--  Author      : M. Casti
--  Date        : 
-- ------------------------------------------------------------------------------
--  Description : Test Bench for "HPUcore" (SpiNNlink-AER)
--     
-- ==============================================================================
--  Revision history :
-- ==============================================================================
-- 
--  Revision 1.0:  07/19/2018
--  - Initial revision, based on tbench.vhd (F. Diotalevi)
--  (M. Casti - IIT)
-- 
-- ------------------------------------------------------------------------------

    
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_arith.all;
-- use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;

library HPU_lib;
        use HPU_lib.aer_pkg.all;
        use HPU_lib.HPUComponents_pkg.all;
 
entity time_machine_tb is
    generic (
        CLK_PERIOD                  : integer := 10;   -- CLK period [ns]
        C_S_AXI_DATA_WIDTH          : natural := 32;
        C_S_AXI_ADDR_WIDTH          : natural := 8;
        C_ENC_NUM_OF_STEPS          : natural := 1970; -- Limit of incremental encoder
        NUM_OF_TRANSMITTER          : integer := 32;
        NUM_OF_RECEIVER             : natural := 32;
        SPI_ADC_RES                 : natural := 12;
        
        NORANDOM_DMA                : natural := 0
        );
end time_machine_tb;
 
architecture behavior of time_machine_tb is 
 
 
component time_machine 
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
end component;	

signal clk_100          : std_logic;
signal clear_n          : std_logic;
signal resync_clear_n   : std_logic;  
signal init_reset       : std_logic; 
signal init_reset_n     : std_logic; 

signal en100ns_100      : std_logic;	
signal en1us_100        : std_logic;	
signal en10us_100       : std_logic;	
signal en100us_100      : std_logic;	
signal en1ms_100        : std_logic;
signal en10ms_100       : std_logic;	
signal en100ms_100      : std_logic;	
signal en1s_100         : std_logic;		


begin 


UUT : time_machine 
generic map( 
  SIM_TIME_COMPRESSION_g => FALSE,  -- Se "TRUE", la simulazione viene "compressa": i clock enable non seguono le tempistiche reali
  INIT_DELAY             => 32     -- Ritardo dal rilascio del reset all'impulso di "init"
  )
port map(
  -- Clock in port
  CLK_100M_i           => clk_100,  -- Ingresso 100 MHz
  -- Enable ports
  EN100NS_100_o        => en100ns_100, 	 -- Clock enable a 100 ns
  EN1US_100_o          => en1us_100,	 -- Clock enable a 1 us
  EN10US_100_o         => en10us_100,	 -- Clock enable a 10 us
  EN100US_100_o        => en100us_100,	 -- Clock enable a 100 us
  EN1MS_100_o          => en1ms_100,	 -- Clock enable a 1 ms
  EN10MS_100_o         => en10ms_100,	 -- Clock enable a 10 ms
  EN100MS_100_o        => en100ms_100,	 -- Clock enable a 100 ms
  EN1S_100_o           => en1s_100,	     -- Clock enable a 1 s
  -- Reset output port 
  RESYNC_CLEAR_N_o     => resync_clear_n,	 -- Clear resincronizzato
  INIT_RESET_100_o     => init_reset,	 	-- Reset sincrono a 32 colpi di clock dal Clear resincronizzato (logica positiva)
  INIT_RESET_N_100_o   => init_reset_n,	 	-- Reset sincrono a 32 colpi di clock dal Clear resincronizzato (logica negativa)
  -- Status and control signals
  CLEAR_N_i            => clear_n       -- Clear asincrono che reinizializza le macchine di timing
  );

 

		-- Stimulus process

Clock_Proc : process
    begin
        clk_100 <= '0';
        loop
            wait for 5 ns;
            clk_100 <= not clk_100;
        end loop;
end process Clock_Proc;

Reset_Proc : process
	begin
		clear_n <= '1';
		wait for 1235 ns;
		clear_n <= '0';
		wait for 256 ns;
		clear_n <= '1';
		wait;
end process Reset_Proc;


end;
