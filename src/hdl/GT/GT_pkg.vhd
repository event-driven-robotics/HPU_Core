------------------------------------------------------------------------
-- Package GTP_Components_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of components for GTP insertion
--   
--
------------------------------------------------------------------------

-- ------------------------------------------------------------------------------
-- 
--  Revision 1.0:  29/03/2021
--  - Initial Revision
--    (M. Casti - IIT)
--    
-- ------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

package components is

  component GT_enable_signal_cdc is
  port (
    CLEAR_N_i           : in     std_logic;                      -- System Reset 
    CLK_SOURCE_i        : in     std_logic;                      -- Origin Clock 
    CLK_DEST_i          : in     std_logic;                      -- Destination Clock
    EN_SIG_SOURCE_i     : in     std_logic;                      -- "Enable Signal" in origin clock domain 
    EN_SIG_DEST_o       : out    std_logic;                      -- "Enable Signal" in destination clock domain 
    EN_SIG_SHORT_DEST_o : out    std_logic := '0'                -- Derivation of "EN_SIG_DEST" in destination clock domain 
    );                                                           -- NOTE: Use EN_DEST if SIG_ORIGIN is a one clock duration enable to be transferred
  end component;

  component GT_Manager is
    generic ( 
      FAMILY_g                  : string                := "zynquplus"; -- "zynq", "zynquplus" 
      --
      USER_DATA_WIDTH_g         : integer range 0 to 64 := 32;    -- Width of Data - Fabric side
      USER_MESSAGE_WIDTH_g      : integer range 0 to 64 :=  8;    -- Width of Message - Fabric side 
      GT_DATA_WIDTH_g           : integer range 0 to 64 := 16;    -- Width of Data - GT side
      GT_TXUSRCLK2_PERIOD_NS_g  : real :=  6.4;                   -- TX GT User clock period
      GT_RXUSRCLK2_PERIOD_NS_g  : real :=  6.4;                   -- RX GT User clock period
      SIM_TIME_COMPRESSION_g    : in boolean := FALSE             -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
      );
    port (
      
      -- COMMONs
      -- Bare Control ports
      CLK_i                   : in  std_logic;   -- Input clock - Fabric side
      RST_N_i                 : in  std_logic;   -- Active low, asynchronous assertion, synchronous deassertion reset (CLK_i clock domain)
      EN1S_i                  : in  std_logic;   -- Enable @ 1 sec (CLK_i clock domain)
  
      -- Status
      PLL_ALARM_o             : out std_logic;
      
      -- ---------------------------------------------------------------------------------------
      -- TX SIDE
  
      -- Control in
      TX_AUTO_ALIGN_i         : in  std_logic;   -- Enables the "Auto alignment mode"
      TX_ALIGN_REQUEST_i      : in  std_logic;   -- Align request from Receiver (async)
      TX_ERROR_INJECTION_i    : in  std_logic;   -- Error insertion (not used, intended for debug purpose)
      
      -- Status and errors
      TX_GT_ALIGN_FLAG_o      : out std_logic;   -- Monitor out: sending align
      
      -- Statistics
      TX_DATA_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond
      TX_ALIGN_RATE_o         : out std_logic_vector( 7 downto 0); -- Count per millisecond
      TX_MSG_RATE_o           : out std_logic_vector(15 downto 0); -- Count per millisecond
      TX_IDLE_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond
      TX_EVENT_RATE_o         : out std_logic_vector(15 downto 0); -- Count per millisecond
      TX_MESSAGE_RATE_o       : out std_logic_vector( 7 downto 0); -- Count per millisecond
  
    
      -- Data TX 
      TX_DATA_i               : in  std_logic_vector(USER_DATA_WIDTH_g-1 downto 0); -- Data to be transmitted
      TX_DATA_SRC_RDY_i       : in  std_logic;  -- Handshake for data transmission: Source Ready
      TX_DATA_DST_RDY_o       : out std_logic;  -- Handshake for data transmission: Destination Ready
      -- Message TX
      TX_MSG_i                : in   std_logic_vector(USER_MESSAGE_WIDTH_g-1 downto 0); -- Message to be transmitted
      TX_MSG_SRC_RDY_i        : in   std_logic;  -- Handshake for message transmission: Source Ready     
      TX_MSG_DST_RDY_o        : out  std_logic;  -- Handshake for message transmission: Destination Ready
  
      -- ---------------------------------------------------------------------------------------
      -- RX SIDE    
      
      -- Control out
      RX_ALIGN_REQUEST_o      : out std_logic;  
      
      -- Status and errors
      RX_DISALIGNED_o         : out std_logic;   -- Monitor out: sending align
      
      -- Statistics        
      RX_DATA_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RX_ALIGN_RATE_o         : out std_logic_vector( 7 downto 0); -- Count per millisecond 
      RX_MSG_RATE_o           : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RX_IDLE_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RX_EVENT_RATE_o         : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RX_MESSAGE_RATE_o       : out std_logic_vector( 7 downto 0); -- Count per millisecond 
  
      -- Data RX 
      RX_DATA_o               : out std_logic_vector(USER_DATA_WIDTH_g-1 downto 0);
      RX_DATA_SRC_RDY_o       : out std_logic;
      RX_DATA_DST_RDY_i       : in  std_logic;
      -- Message RX
      RX_MSG_o                : out std_logic_vector(USER_MESSAGE_WIDTH_g-1 downto 0);
      RX_MSG_SRC_RDY_o        : out std_logic;
      RX_MSG_DST_RDY_i        : in  std_logic;    
      
          
    
      -- *****************************************************************************************
      -- Transceiver Interface for Serie 7 GTP
      -- *****************************************************************************************
      
      -- Clock Ports
      GTP_TXUSRCLK2_i          : in  std_logic;
      GTP_RXUSRCLK2_i          : in  std_logic;  
      
      -- Reset FSM Control Ports
      SOFT_RESET_TX_o          : out  std_logic;                                          -- SYS_CLK   --
      SOFT_RESET_RX_o          : out  std_logic;                                          -- SYS_CLK   --
      GTP_DATA_VALID_o         : out std_logic;                                           -- SYS_CLK   --
      
      -- -------------------------------------------------------------------------
      -- TRANSMITTER 
      --------------------- TX Initialization and Reset Ports --------------------
      GTP_TXUSERRDY_o          : out std_logic;                                           -- ASYNC     --
      ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
      GTP_TXDATA_o             : out std_logic_vector(15 downto 0);                       -- TXUSRCLK2 --
      ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
      GTP_TXCHARISK_o          : out std_logic_vector(1 downto 0);                        -- TXUSRCLK2 --
      
      -- -------------------------------------------------------------------------
      -- RECEIVER
      --------------------- RX Initialization and Reset Ports --------------------
      GTP_RXUSERRDY_o          : out std_logic;                                           -- ASYNC     --
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTP_RXDATA_i             : in  std_logic_vector(GT_DATA_WIDTH_g-1 downto 0);       -- RXUSRCLK2 --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTP_RXCHARISCOMMA_i      : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
      GTP_RXCHARISK_i          : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
      GTP_RXDISPERR_i          : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
      GTP_RXNOTINTABLE_i       : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTP_RXBYTEISALIGNED_i    : in  std_logic;                                           -- RXUSRCLK2 --
      GTP_RXBYTEREALIGN_i      : in  std_logic;                                           -- RXUSRCLK2 --
      
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS
      GTP_PLL_LOCK_i           : in  std_logic;                                           -- ASYNC     --
      GTP_PLL_REFCLKLOST_i     : in  std_logic;                                           -- SYS_CLK   -- 
  
  
  
      -- *****************************************************************************************
      -- Transceiver Interface for Ultrascale+ GTH
      -- ***************************************************************************************** 
      
      -- Clock Ports
  --  GTH_GTWIZ_USERCLK_TX_USRCLK2_i        : in std_logic_vector(0 downto 0);
      GTH_GTWIZ_USERCLK_RX_USRCLK2_i        : in std_logic_vector(0 downto 0);
      
      -- Reset FSM Control Ports
      GTH_GTWIZ_RESET_ALL_o                 : out std_logic_vector(0 downto 0);                        -- ASYNC     --
  
  
      -- -------------------------------------------------------------------------
      -- TRANSMITTER 
  
      -- TBD
  
      
      -- -------------------------------------------------------------------------
      -- RECEIVER
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTH_GTWIZ_USERDATA_RX_i               : in  std_logic_vector(GT_DATA_WIDTH_g-1 downto 0);       -- RXUSRCLK2 --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTH_RXCTRL2_i                         : in  std_logic_vector(7 downto 0);    -- (RXCHARISCOMMA)  -- RXUSRCLK2 --
      GTH_RXCTRL0_i                         : in  std_logic_vector(15 downto 0);   -- (RXCHARISK)      -- RXUSRCLK2 --
      GTH_RXCTRL1_i                         : in  std_logic_vector(15 downto 0);   -- (RXDISPERR)      -- RXUSRCLK2 --
      GTH_RXCTRL3_i                         : in  std_logic_vector(7 downto 0);    -- (RXNOTINTABLE)   -- RXUSRCLK2 --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTH_RXBYTEISALIGNED_i                 : in  std_logic_vector(0 downto 0);                        -- RXUSRCLK2 --
      GTH_RXBYTEREALIGN_i                   : in  std_logic_vector(0 downto 0);                        -- RXUSRCLK2 --
          
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS    
      GTH_QPLL_LOCK_i                       : in  std_logic_vector(0 downto 0);                        -- ASYNC     --
      GTH_QPLL_REFCLKLOST_i                 : in  std_logic_vector(0 downto 0)                         -- QPLL0LOCKDETCLK --
              
      );
  end component;
  
  component GT_time_machine is
    generic ( 
      CLK_PERIOD_NS_g         : real := 10.0;                   -- Main Clock period
      CLEAR_POLARITY_g        : string := "LOW";                -- Active "HIGH" or "LOW"
      PON_RESET_DURATION_MS_g : integer range 0 to 255 := 10;   -- Duration of Power-On reset  
      SIM_TIME_COMPRESSION_g  : in boolean := FALSE             -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
      );
    port (
      -- Clock in port
      CLK_i                   : in  std_logic;   -- Input clock @ 50 MHz,
      CLEAR_i                 : in  std_logic;   -- Asynchronous active low reset
    
      -- Output reset
      RESET_o                 : out std_logic;    -- Reset out (active high)
      RESET_N_o               : out std_logic;    -- Reset out (active low)
      PON_RESET_OUT_o         : out std_logic;	  -- Power on Reset out (active high)
      PON_RESET_N_OUT_o       : out std_logic;	  -- Power on Reset out (active low)
      
      -- Output ports for generated clock enables
      EN200NS_o               : out std_logic;	  -- Clock enable every 200 ns
      EN1US_o                 : out std_logic;	  -- Clock enable every 1 us
      EN10US_o                : out std_logic;	  -- Clock enable every 10 us
      EN100US_o               : out std_logic;	  -- Clock enable every 100 us
      EN1MS_o                 : out std_logic;	  -- Clock enable every 1 ms
      EN10MS_o                : out std_logic;	  -- Clock enable every 10 ms
      EN100MS_o               : out std_logic;	  -- Clock enable every 100 ms
      EN1S_o                  : out std_logic 	  -- Clock enable every 1 s
      );
  end component;
  
  component FIFO_GT_DATA_ZYNQ
    port (
      rst : in std_logic;
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      din : in std_logic_vector(31 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(31 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      valid : out std_logic
    );
  end component;
  
  component FIFO_GT_DATA_ZYNQUPLUS
    port (
      rst : in std_logic;
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      din : in std_logic_vector(31 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(31 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      valid : out std_logic
    );
  end component;
  
  component FIFO_GT_MSG_ZYNQ
    port (
      rst : in std_logic;
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      din : in std_logic_vector(7 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(7 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      valid : out std_logic
    );
  end component;
  
  component FIFO_GT_MSG_ZYNQUPLUS
    port (
      rst : in std_logic;
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      din : in std_logic_vector(7 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(7 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      valid : out std_logic
    );
  end component;
  

  

end package components;
