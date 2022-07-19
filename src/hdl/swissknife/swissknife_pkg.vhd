library ieee;
    use ieee.std_logic_1164.all;

------------------------------------------------------------------------
package types is

  type time_tick is record
    en200ns               : std_logic;
    en1us                 : std_logic;
    en10us                : std_logic;
    en100us               : std_logic;
    en1ms                 : std_logic;
    en10ms                : std_logic;
    en100ms               : std_logic;
    en1s                  : std_logic;
  end record time_tick;

end package types;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;

package components is

  component time_machine is
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
  end component;
  
  component signal_cdc is
    generic (
      IN_FF_SYNC_g    : boolean   := TRUE;  -- If TRUE, "SIG_IN_A_i" is sychronized again with CLK_A_i (in order to bypass glitches)
      RESVALUE_g      : std_logic := '0'    -- RESET Value of B signal (should be equal to reset value of A signal)
    );
    port ( 
      CLK_A_i     : in  std_logic := 'L';
      ARST_N_A_i  : in  std_logic := 'H';
      SIG_IN_A_i  : in  std_logic;
      --
      CLK_B_i     : in  std_logic;
      ARST_N_B_i  : in  std_logic;
      SIG_OUT_B_i : out std_logic    
    );
  end component;
  
  component enable_signal_cdc is
 port (
  CLEAR_N_i           : in     std_logic;                      -- System Reset 
  CLK_SOURCE_i        : in     std_logic;                      -- Origin Clock 
  CLK_DEST_i          : in     std_logic;                      -- Destination Clock
  EN_SIG_SOURCE_i     : in     std_logic;                      -- "Enable Signal" in origin clock domain 
  EN_SIG_DEST_o       : out    std_logic;                      -- "Enable Signal" in destination clock domain 
  EN_SIG_SHORT_DEST_o : out    std_logic := '0'                -- Derivation of "EN_SIG_DEST" in destination clock domain 
  );                                                           -- NOTE: Use EN_DEST if SIG_ORIGIN is a one clock duration enable to be transferred
end component;

end package components;
