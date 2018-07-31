--------------------------------------------------------------------------------
-- AsyncStabilizer
-------------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity AsyncStabilizer is
  generic (
    synchronizer      : boolean  := true;
    stabilizer_cycles : positive := 2
    );
  port (
    ClkxCI      : in  std_logic;
    RstxRBI     : in  std_logic;
    --
    RstValuexDI : in  std_logic;
    --
    InputxAI    : in  std_logic;
    OutputxDO   : out std_logic
    );

end AsyncStabilizer;

-------------------------------------------------------------------------------

architecture rtl of AsyncStabilizer is

  signal InputxAA, InputxD, InputPrevxD : std_logic;

  signal OutputxD : std_logic;

  signal StableCyclesxDP, StableCyclesxDN : natural range 0 to stabilizer_cycles;
  
begin

  -----------------------------------------------------------------------------

  g_synchronizer : if synchronizer generate
    
    p_sync : process (ClkxCI, RstValuexDI, RstxRBI)
    begin
      if RstxRBI = '0' then             -- asynchronous reset (active low)
        InputPrevxD <= RstValuexDI;
        InputxD     <= RstValuexDI;
        InputxAA    <= RstValuexDI;
      elsif ClkxCI'event and ClkxCI = '1' then  -- rising clock edge
        InputPrevxD <= InputxD;
        InputxD     <= InputxAA;
        InputxAA    <= InputxAI;
      end if;
    end process p_sync;
    
  end generate g_synchronizer;

  g_n_synchronizer : if not synchronizer generate

    p_n_sync : process (ClkxCI, RstValuexDI, RstxRBI)
    begin
      if RstxRBI = '0' then             -- asynchronous reset (active low)
        InputPrevxD <= RstValuexDI;
      elsif ClkxCI'event and ClkxCI = '1' then  -- rising clock edge
        InputPrevxD <= InputxAI;
      end if;
    end process p_n_sync;

    InputxD <= InputxAI;
    
  end generate g_n_synchronizer;

  -----------------------------------------------------------------------------

  p_stab_memless : process (InputPrevxD, InputxD, StableCyclesxDP)
  begin
    if InputxD = InputPrevxD then
      -- stable
      if StableCyclesxDP >= stabilizer_cycles then
        -- clamp
        StableCyclesxDN <= StableCyclesxDP;
      else
        -- increment
        StableCyclesxDN <= StableCyclesxDP + 1;
      end if;
    else
      -- edge -> unstable
      StableCyclesxDN <= 0;
    end if;
  end process p_stab_memless;

  p_stab_memzing : process (ClkxCI, RstValuexDI, RstxRBI)
  begin
    if RstxRBI = '0' then               -- asynchronous reset (active low)
      StableCyclesxDP <= 0;

      OutputxD <= RstValuexDI;
      
    elsif ClkxCI'event and ClkxCI = '1' then  -- rising clock edge
      StableCyclesxDP <= StableCyclesxDN;

      if StableCyclesxDP = stabilizer_cycles and InputPrevxD = InputxD then
        OutputxD <= InputxD;
      end if;
      
    end if;
  end process p_stab_memzing;

  -----------------------------------------------------------------------------
  -- output alias wiring
  OutputxDO <= OutputxD;

end rtl;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
