-- ==============================================================================
-- DESCRIPTION:
-- Clock domain cross for enable signal
-- ------------------------------------------
-- File        : enable_signal_cdx.vhd
-- Revision    : 1.0
-- Author      : M. Casti
-- Date        : 23/03/2021
-- ==============================================================================
-- HISTORY (main changes) :
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

entity GTP_enable_signal_cdc is
 port (
  CLEAR_N_i           : in     std_logic;                      -- System Reset 
  CLK_SOURCE_i        : in     std_logic;                      -- Origin Clock 
  CLK_DEST_i          : in     std_logic;                      -- Destination Clock
  EN_SIG_SOURCE_i     : in     std_logic;                      -- "Enable Signal" in origin clock domain 
  EN_SIG_DEST_o       : out    std_logic;                      -- "Enable Signal" in destination clock domain 
  EN_SIG_SHORT_DEST_o : out    std_logic := '0'                -- Derivation of "EN_SIG_DEST" in destination clock domain 
  );                                                           -- NOTE: Use EN_DEST if SIG_ORIGIN is a one clock duration enable to be transferred
end entity;

architecture Behavioral of GTP_enable_signal_cdc is

signal rst_n_q1_clk_source : std_logic := '0';
signal rst_n_q2_clk_source : std_logic := '0';
signal rst_n_clk_source		 : std_logic := '0';

signal rst_n_q1_clk_dest   : std_logic := '0';
signal rst_n_q2_clk_dest   : std_logic := '0';
signal rst_n_clk_dest      : std_logic := '0';

signal req_clk_source      : std_logic := '0';
signal ack1_clk_source     : std_logic := '0';
signal ack2_clk_source     : std_logic := '0';

signal req1_clk_dest       : std_logic := '0';
signal req2_clk_dest       : std_logic := '0';
signal req3_clk_dest       : std_logic := '0';

attribute ASYNC_REG : string;   
attribute ASYNC_REG of rst_n_q1_clk_source : signal is "true";
attribute ASYNC_REG of rst_n_q2_clk_source : signal is "true";
attribute ASYNC_REG of rst_n_clk_source    : signal is "true";
attribute ASYNC_REG of rst_n_q1_clk_dest   : signal is "true";
attribute ASYNC_REG of rst_n_q2_clk_dest   : signal is "true";
attribute ASYNC_REG of rst_n_clk_dest      : signal is "true";
attribute ASYNC_REG of req_clk_source      : signal is "true";
attribute ASYNC_REG of ack1_clk_source     : signal is "true";
attribute ASYNC_REG of ack2_clk_source     : signal is "true";
attribute ASYNC_REG of req1_clk_dest       : signal is "true";
attribute ASYNC_REG of req2_clk_dest       : signal is "true";
attribute ASYNC_REG of req3_clk_dest       : signal is "true";

begin


-- EN_SIG_SOURCE_i,  Resynchronisation with CLK_DEST 

--                ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---
--  CLK_SOURCE ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

--                                  ------
--  EN_SIG_SOURCE      -------------      -------------------------------------------------------------------------------

--                                        -------------------------------
--  req                    ---------------                               ------------------------------------------------

--                                                          ------------------------------
--  ack1                  ----------------------------------                              -------------------------------

--                                                                -------------------------------
--  ack2               -------------------------------------------                               ------------------------

   
--               ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    ----
--  CLK_DEST ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    ----    --

--                                               -------------------------------- 
--  req1               --------------------------                                ----------------------------------------
   
--                                                        -------------------------------
--  req2               -----------------------------------                               --------------------------------

--                                                                --------------------------------
--  EN_SIG_DEST        -------------------------------------------                                ------------------------

--                                                                                                --------
--  EN_SIG_SHORT_DEST  ---------------------------------------------------------------------------        ---------------- 

----------------------------------------------------------------------------
-----------------     Reset Synchronization     ----------------------------
----------------------------------------------------------------------------

-- Reset Synch
synch_reset_clk_source:
process(CLEAR_N_i, CLK_SOURCE_i)
begin
	if (CLEAR_N_i = '0') then
		rst_n_q1_clk_source	<= '0';
		rst_n_q2_clk_source	<= '0';
		rst_n_clk_source    <= '0';
	elsif rising_edge(CLK_SOURCE_i) then
		rst_n_q1_clk_source	<= '1';
		rst_n_q2_clk_source	<= rst_n_q1_clk_source;
		rst_n_clk_source    <= rst_n_q2_clk_source;
	end if;
end process;

synch_reset_clk_dest:
process(CLEAR_N_i, CLK_DEST_i)
begin
	if (CLEAR_N_i = '0') then
		rst_n_q1_clk_dest <= '0';
		rst_n_q2_clk_dest <= '0';
		rst_n_clk_dest    <= '0';
	elsif rising_edge(CLK_DEST_i) then
		rst_n_q1_clk_dest <= '1';
		rst_n_q2_clk_dest <= rst_n_q1_clk_dest;
		rst_n_clk_dest    <= rst_n_q2_clk_dest;
	end if;
end process;


----------------------------------------------------------------------------
----------------- Toggleling between 2 clock domains -----------------------
----------------------------------------------------------------------------

Resync_Control_Input_proc1 : 
process(rst_n_clk_source, CLK_SOURCE_i)
begin
  if (rst_n_clk_source = '0') then  
    req_clk_source  <= '0';
    ack1_clk_source <= '0';
    ack2_clk_source <= '0';   
  elsif rising_edge(CLK_SOURCE_i) then
    if (EN_SIG_SOURCE_i = '1') then
      req_clk_source <= '1';
    elsif (ack2_clk_source = '1') then
      req_clk_source <= '0';
    end if;
    ack1_clk_source <= req2_clk_dest;
    ack2_clk_source <= ack1_clk_source;
  end if;
end process Resync_Control_Input_proc1;   
  
Resync_Control_Input_proc2 :
process(rst_n_clk_dest, CLK_DEST_i)
begin
  if (rst_n_clk_dest = '0') then
    req1_clk_dest       <= '0';
    req2_clk_dest       <= '0';
    req3_clk_dest       <= '0';
    EN_SIG_SHORT_DEST_o <= '0';
  elsif rising_edge(CLK_DEST_i) then
    req1_clk_dest       <= req_clk_source;
    req2_clk_dest       <= req1_clk_dest;
    req3_clk_dest       <= req2_clk_dest;
    EN_SIG_SHORT_DEST_o <= req2_clk_dest and not(req3_clk_dest);
   end if;
end process Resync_Control_Input_proc2; 

EN_SIG_DEST_o <= req3_clk_dest; 

end Behavioral;

