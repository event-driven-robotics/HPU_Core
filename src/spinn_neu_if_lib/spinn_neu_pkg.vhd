------------------------------------------------------------------------
-- Package spinn_neu_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of components used inside the
--   spinn_neu_if unit
--
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package spinn_neu_pkg is

component spinn_neu_if
	generic (
		C_PSPNNLNK_WIDTH			: natural range 1 to 32 := 32
			);
	port (
		rst							: in  std_logic;
		clk_32						: in  std_logic;
		
		dump_mode					: out std_logic;
		parity_err					: out std_logic;
		rx_err						: out std_logic;
	
		-- input SpiNNaker link interface
		data_2of7_from_spinnaker 	: in  std_logic_vector(6 downto 0); 
		ack_to_spinnaker			: out std_logic;
	
		-- output SpiNNaker link interface
		data_2of7_to_spinnaker		: out std_logic_vector(6 downto 0);
		ack_from_spinnaker          : in  std_logic;
	
		-- input AER device interface
		iaer_addr 					: in  std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
		iaer_vld					: in  std_logic;
		iaer_rdy					: out std_logic;
	
		-- output AER device interface
		oaer_addr					: out std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
		oaer_vld					: out std_logic;
		oaer_rdy					: in  std_logic;
		
		dbg_rxstate					: out std_logic_vector(2 downto 0);
		dbg_txstate					: out std_logic_vector(1 downto 0);
		dbg_ipkt_vld				: out std_logic;
		dbg_ipkt_rdy				: out std_logic;
		dbg_opkt_vld				: out std_logic;
		dbg_opkt_rdy				: out std_logic
	); 
end component;


end package spinn_neu_pkg;
