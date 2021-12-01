------------------------------------------------------------------------
-- Package swissknife_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of constants and types used in the
--   SwissKnife Library
--
------------------------------------------------------------------------

-- USAGE
-- Insert following lines in destination code:

-- library swissknife_lib;
--    use ieee.swissknife_pkg.all;

------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;


package swissknife_pkg is

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

end package swissknife_pkg;
