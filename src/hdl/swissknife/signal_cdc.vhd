library IEEE;
  use IEEE.std_logic_1164.all;

entity signal_cdc is
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
end signal_cdc;

architecture Behavioral of signal_cdc is

attribute ASYNC_REG : string;

signal sig_a               : std_logic;

signal sig_b_meta    : std_logic;
attribute ASYNC_REG of sig_b_meta  : signal is "true";
signal sig_b_sync    : std_logic;
attribute ASYNC_REG of sig_b_sync  : signal is "true";
signal sig_b         : std_logic;
attribute ASYNC_REG of sig_b       : signal is "true";


begin

SYNC_A_STAGE_gen : if (IN_FF_SYNC_g) generate

  process(CLK_A_i, ARST_N_A_i)
  begin
    if (ARST_N_A_i = '0') then 
      sig_a <= RESVALUE_g;
    elsif rising_edge(CLK_A_i) then
      sig_a <= SIG_IN_A_i;
    end if;
  end process;

end generate;

DIRECT_gen : if (not IN_FF_SYNC_g) generate
  
  sig_a <= SIG_IN_A_i;

end generate;


process(CLK_B_i, ARST_N_B_i)
begin
  if (ARST_N_B_i = '0') then 
    sig_b_meta  <= RESVALUE_g;
    sig_b_sync  <= RESVALUE_g;
    sig_b       <= RESVALUE_g;
  elsif rising_edge(CLK_B_i) then
    sig_b_meta  <= sig_a;
    sig_b_sync  <= sig_b_meta;
    sig_b       <= sig_b_sync;
  end if;
end process;

SIG_OUT_B_i <= sig_b;

end Behavioral;
