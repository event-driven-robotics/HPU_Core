--------------------------------------------------------------------------------
-- RegisterArray1
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity RegisterArray1 is
  generic (
    depth : natural  := 1
    );
  port (
    ClkxCI        : in  std_logic;
    RstxRBI       : in  std_logic;
    --
    ResetValuexDI : in  std_logic;
    --
    InputxDI      : in  std_logic;
    OutputxDO     : out std_logic
    );

end RegisterArray1;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture rtl of RegisterArray1 is

  type   t_register_array is array (depth-1 downto 0) of std_logic;
  signal RegsxD : t_register_array;
  
begin

  g_nz_depth : if depth /= 0 generate
    
    p_regs : process (ClkxCI, ResetValuexDI, RstxRBI)
    begin
      if RstxRBI = '0' then             -- asynchronous reset (active low)

        RegsxD <= (others => ResetValuexDI);
        
      elsif ClkxCI'event and ClkxCI = '1' then  -- rising clock edge

        RegsxD(depth - 1)          <= InputxDI;
        RegsxD(depth - 2 downto 0) <= RegsxD(depth - 1 downto 1);
        
      end if;
    end process p_regs;

    OutputxDO <= RegsxD(0);
    
  end generate g_nz_depth;

  -----------------------------------------------------------------------------

  g_z_depth : if depth = 0 generate

    OutputxDO <= InputxDI;
    
  end generate g_z_depth;
  
end rtl;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
