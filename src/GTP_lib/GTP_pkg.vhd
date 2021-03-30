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

package GTP_pkg is

-- ------------------------------------------------------------------------------
-- COMPONENTS

component GTP_Manager is
  generic ( 
    USER_DATA_WIDTH_g         : integer range 0 to 64 := 32;    -- Width of Data - Fabric side
    USER_MESSAGE_WIDTH_g      : integer range 0 to 64 :=  8;    -- Width of Message - Fabric side 
    GTP_DATA_WIDTH_g          : integer range 0 to 64 := 16;    -- Width of Data - GTP side
    GTP_TXUSRCLK2_PERIOD_NS_g : real := 6.4;                    -- TX GTP User clock period
    GTP_RXUSRCLK2_PERIOD_NS_g : real := 6.4;                    -- RX GTP User clock period
    SIM_TIME_COMPRESSION_g    : in boolean := FALSE             -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    );
  port (
    
    -- COMMONs
    -- Bare Control ports
    CLK_i                   : in  std_logic;   -- Input clock - Fabric side
    RST_N_i                 : in  std_logic;   -- Asynchronous active low reset (clk clock)
    EN1S_i                  : in  std_logic;   -- Enable @ 1 sec in clk domain 

    -- Status
    PLL_ALARM_o             : out std_logic;
    
    -- ---------------------------------------------------------------------------------------
    -- TX SIDE

    -- Control in
    TX_AUTO_ALIGN_i         : in  std_logic;   -- Enables the "Auto alignment mode"
    TX_ALIGN_REQUEST_i      : in  std_logic;   -- Align request from Receiver
    TX_ERROR_INJECTION_i    : in  std_logic;   -- Error insertin (debug purpose)
    
    -- Status
    TX_GTP_ALIGN_FLAG_o     : out std_logic;   -- Monitor out: sending align
    
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
    -- GTP Interface    
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
    GTP_RXDATA_i             : in  std_logic_vector(GTP_DATA_WIDTH_g-1 downto 0);       -- RXUSRCLK2 --
    ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
    GTP_RXCHARISCOMMA_i      : in  std_logic_vector((GTP_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
    GTP_RXCHARISK_i          : in  std_logic_vector((GTP_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
    GTP_RXDISPERR_i          : in  std_logic_vector((GTP_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
    GTP_RXNOTINTABLE_i       : in  std_logic_vector((GTP_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 -- 
    -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
    GTP_RXBYTEISALIGNED_i      : in  std_logic;                                         -- RXUSRCLK2 --
    GTP_RXBYTEREALIGN_i        : in  std_logic;                                         -- RXUSRCLK2 --
    
    -- -------------------------------------------------------------------------    
    -- COMMON PORTS
    GTP_PLL_LOCK_i           : in  std_logic;                                           -- ASYNC     --
    GTP_PLL_REFCLKLOST_i     : in  std_logic                                            -- SYS_CLK   -- 
             
    );
end component;








end package GTP_pkg;
