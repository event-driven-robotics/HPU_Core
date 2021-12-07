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

    
library HPU_lib;
        use HPU_lib.aer_pkg.all;
        use HPU_lib.HPUComponents_pkg.all;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_arith.all;
-- use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.math_real.all;

library std;
use std.textio.all;

--  LIBRARY dut_lib;
--  use  dut_lib.all;

--  Uncomment the following library declaration if using
--  arithmetic functions with Signed or Unsigned values
--  USE ieee.numeric_std.ALL;
 
entity HPUcore_tb is
    generic (
        CLK_PERIOD                  : integer := 10;   -- CLK period [ns]
        C_S_AXI_DATA_WIDTH          : natural := 32;
        C_S_AXI_ADDR_WIDTH          : natural := 8;
        C_ENC_NUM_OF_STEPS          : natural := 1970; -- Limit of incremental encoder
        NUM_OF_TRANSMITTER          : integer := 32;
        NUM_OF_RECEIVER             : natural := 32;
        SPI_ADC_RES                 : natural := 12;
        C_GTP_DSIZE                 : natural := 16;
        NORANDOM_DMA                : natural := 0 
        );
end HPUcore_tb;
 
architecture behavior of HPUcore_tb is          
    
-- Clock generation constants   

constant CLK_CORE_FREQ_MHZ_c              : real := 100.0; -- MHz                
constant CLK_CORE_HALF_PERIOD_NS_c        : time := 5.0 ns;    

constant CLK_AXIS_FREQ_MHZ_c              : real := 160.0; -- MHz                
constant CLK_AXIS_HALF_PERIOD_NS_c        : time := 3.125 ns;

constant CLK_HSSAER_LS_FREQ_c             : real := 100.0; -- MHz                
constant CLK_HSSAER_LS_HALF_PERIOD_c      : time := 5.0 ns;

constant CLK_HSSAER_HS_FREQ_MHZ_c         : real := 300.0; -- MHz                    
constant CLK_HSSAER_HS_HALF_PERIOD_1_NS_c : time := 1.667 ns;  
constant CLK_HSSAER_HS_HALF_PERIOD_2_NS_c : time := 1.666 ns;
constant CLK_HSSAER_HS_HALF_PERIOD_3_NS_c : time := 1.667 ns;  
constant CLK_HSSAER_HS_HALF_PERIOD_4_NS_c : time := 1.666 ns;
constant CLK_HSSAER_HS_HALF_PERIOD_5_NS_c : time := 1.667 ns;  
constant CLK_HSSAER_HS_HALF_PERIOD_6_NS_c : time := 1.666 ns;    
 
-- constant F_HSCLK : real := 300.0; -- MHz
-- constant T_HSCLK : time := ((1.0/F_HSCLK)/2.0) * (1 us);
--  
-- constant F_LSCLK : real := 100.0; -- MHz
-- constant T_LSCLK : time := ((1.0/F_LSCLK)/2.0) * (1 us); 
 
-- --------------------------------------------------
--  Unit Under Test: HPUcore
-- --------------------------------------------------  
  
component HPUCore is
  generic (
    -- -----------------------    
    -- GENERAL
    C_FAMILY                  : string                        := "zynquplus"; -- "zynq", "zynquplus" 
    -- -----------------------    
    -- PAER        
    C_RX_L_HAS_PAER           : boolean                       := true;
    C_RX_R_HAS_PAER           : boolean                       := true;
    C_RX_A_HAS_PAER           : boolean                       := true;
    C_RX_PAER_L_SENS_ID       : std_logic_vector(2 downto 0)  := "000";
    C_RX_PAER_R_SENS_ID       : std_logic_vector(2 downto 0)  := "000";
    C_RX_PAER_A_SENS_ID       : std_logic_vector(2 downto 0)  := "001";
    C_TX_HAS_PAER             : boolean                       := true;
    C_PAER_DSIZE              : natural range 1 to 29         := 24;
    -- -----------------------        
    -- HSSAER
    C_RX_L_HAS_HSSAER         : boolean                       := true;
    C_RX_R_HAS_HSSAER         : boolean                       := true;
    C_RX_A_HAS_HSSAER         : boolean                       := true;
    C_RX_HSSAER_N_CHAN        : natural range 1 to 4          := 4;
    C_RX_SAER0_L_SENS_ID      : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER1_L_SENS_ID      : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER2_L_SENS_ID      : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER3_L_SENS_ID      : std_logic_vector(2 downto 0)  := "000";        
    C_RX_SAER0_R_SENS_ID      : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER1_R_SENS_ID      : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER2_R_SENS_ID      : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER3_R_SENS_ID      : std_logic_vector(2 downto 0)  := "000";        
    C_RX_SAER0_A_SENS_ID      : std_logic_vector(2 downto 0)  := "001";
    C_RX_SAER1_A_SENS_ID      : std_logic_vector(2 downto 0)  := "001";
    C_RX_SAER2_A_SENS_ID      : std_logic_vector(2 downto 0)  := "001";
    C_RX_SAER3_A_SENS_ID      : std_logic_vector(2 downto 0)  := "001";
    C_TX_HAS_HSSAER           : boolean                       := true;
    C_TX_HSSAER_N_CHAN        : natural range 1 to 4          := 4;
    -- -----------------------        
    -- GTP
    C_RX_L_HAS_GTP            : boolean                       := true;
    C_RX_R_HAS_GTP            : boolean                       := true;
    C_RX_A_HAS_GTP            : boolean                       := true;
--    C_GTP_RXUSRCLK2_PERIOD_NS : real                          := 6.4;        
    C_GTP_RXUSRCLK2_PERIOD_PS : positive                      := 6400;        -- Positive (integer) because IP Packager doesn't support real generics 
    C_TX_HAS_GTP              : boolean                       := true;
--    C_GTP_TXUSRCLK2_PERIOD_NS : real                          := 6.4;  
    C_GTP_TXUSRCLK2_PERIOD_PS : positive                      := 6400;        -- Positive (integer) because IP Packager doesn't support real generics    
    C_GTP_DSIZE               : positive                      := 16;
    -- -----------------------                
    -- SPINNLINK
    C_RX_L_HAS_SPNNLNK        : boolean                       := true;
    C_RX_R_HAS_SPNNLNK        : boolean                       := true;
    C_RX_A_HAS_SPNNLNK        : boolean                       := true;
    C_TX_HAS_SPNNLNK          : boolean                       := true;
    C_PSPNNLNK_WIDTH      	  : natural range 1 to 32         := 32;
    -- -----------------------
    -- INTERCEPTION
    C_RX_L_INTERCEPTION       : boolean                       := true;
    C_RX_R_INTERCEPTION       : boolean                       := true;
    C_RX_A_INTERCEPTION       : boolean                       := true;
    -- -----------------------
    -- CORE
--    C_SYSCLK_PERIOD_NS        : real                          := 10.0;           -- System Clock period
    C_SYSCLK_PERIOD_PS        : positive                      := 10000;          -- Positive (integer) because IP Packager doesn't support real generics 
    C_HAS_DEFAULT_LOOPBACK    : boolean                       := true;
    -- -----------------------
    -- BUS PROTOCOL PARAMETERS
    C_S_AXI_ADDR_WIDTH        : integer                       := 8;             -- AXI4 Lite Slave Address width: size of AXI4 Lite Address bus
    C_S_AXI_DATA_WIDTH        : integer                       := 32;            -- AXI4 Lite Slave Data width:    size of AXI4 Lite Data bus
    C_SLV_DWIDTH              : integer                       := 32;            -- Slave interface data bus width
    -- -----------------------
    -- SIMULATION
    C_SIM_TIME_COMPRESSION     : boolean                      := false   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    );
  port (
    
    -- SYNC Resetn
    CLEAR_N_i                   : in  std_logic := 'X';    -- Asynchronous Clear
    
    -- Main Core Clock 
    CLK_CORE_i                  : in  std_logic;
    
    -- AXI Stream Clock
    CLK_AXIS_i                  : in  std_logic;
    
    -- Clocks for HSSAER interface
    CLK_HSSAER_LS_P_i           : in  std_logic := '0'; -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
    CLK_HSSAER_LS_N_i           : in  std_logic := '1'; -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
    CLK_HSSAER_HS_P_i           : in  std_logic := '0'; -- 300 Mhz clock p it must 3x HSSAER_ClkLS
    CLK_HSSAER_HS_N_i           : in  std_logic := '1'; -- 300 Mhz clock p it must 3x HSSAER_ClkLS


    --============================================
    -- Tx Interface
    --============================================
    
    -- Parallel AER
    Tx_PAER_Addr_o              : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    Tx_PAER_Req_o               : out std_logic;
    Tx_PAER_Ack_i               : in  std_logic;
    -- HSSAER channels
    Tx_HSSAER_o                 : out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    -- GTP lines
    Tx_TxGtpMsg_i               : in  std_logic_vector(7 downto 0);
    Tx_TxGtpMsgSrcRdy_i         : in  std_logic;
    Tx_TxGtpMsgDstRdy_o         : out std_logic;  
    Tx_TxGtpAlignRequest_i      : in  std_logic;
    Tx_TxGtpAlignFlag_o         : out std_logic;
    Tx_GTP_TxUsrClk2_i          : in  std_logic;   
    Tx_GTP_SoftResetTx_o        : out  std_logic;                                          
    Tx_GTP_DataValid_o          : out std_logic;    
    Tx_GTP_Txuserrdy_o          : out std_logic;                                           
    Tx_GTP_Txdata_o             : out std_logic_vector(C_GTP_DSIZE-1 downto 0);            
    Tx_GTP_Txcharisk_o          : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    Tx_GTP_PllLock_i            : in  std_logic;                                           
    Tx_GTP_PllRefclklost_i      : in  std_logic;         
    -- SpiNNaker Interface
    Tx_SPNN_Data_o              : out std_logic_vector(6 downto 0);
    Tx_SPNN_Ack_i               : in  std_logic; 


    --============================================
    -- Rx Left Interface
    --============================================
    
    -- Parallel AER
    LRx_PAER_Addr_i             : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    LRx_PAER_Req_i              : in  std_logic;
    LRx_PAER_Ack_o              : out std_logic;
    -- HSSAER channels
    LRx_HSSAER_i                : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    -- GTP lines
    LRx_RxGtpMsg_o              : out std_logic_vector(7 downto 0);
    LRx_RxGtpMsgSrcRdy_o        : out std_logic;
    LRx_RxGtpMsgDstRdy_i        : in  std_logic;  
    LRx_RxGtpAlignRequest_o     : out std_logic;
    LRx_GTP_RxUsrClk2_i         : in  std_logic;
    LRx_GTP_SoftResetRx_o       : out  std_logic;                                          
    LRx_GTP_DataValid_o         : out std_logic;          
    LRx_GTP_Rxuserrdy_o         : out std_logic;              
    LRx_GTP_Rxdata_i            : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
    LRx_GTP_Rxchariscomma_i     : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    LRx_GTP_Rxcharisk_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    LRx_GTP_Rxdisperr_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    LRx_GTP_Rxnotintable_i      : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
    LRx_GTP_Rxbyteisaligned_i   : in  std_logic;                                           
    LRx_GTP_Rxbyterealign_i     : in  std_logic;         
    LRx_GTP_PllLock_i           : in  std_logic;                                           
    LRx_GTP_PllRefclklost_i     : in  std_logic;   
    -- SpiNNaker Interface
    LRx_SPNN_Data_i             : in  std_logic_vector(6 downto 0); 
    LRx_SPNN_Ack_o              : out std_logic;
    
    
    --============================================
    -- Rx Right Interface
    --============================================

    -- Parallel AER
    RRx_PAER_Addr_i             : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    RRx_PAER_Req_i              : in  std_logic;
    RRx_PAER_Ack_o              : out std_logic;
    -- HSSAER channels
    RRx_HSSAER_i               : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    -- GTP lines
    RRx_RxGtpMsg_o              : out std_logic_vector(7 downto 0);
    RRx_RxGtpMsgSrcRdy_o        : out std_logic;
    RRx_RxGtpMsgDstRdy_i        : in  std_logic;  
    RRx_RxGtpAlignRequest_o    : out std_logic;
    RRx_GTP_RxUsrClk2_i         : in  std_logic;
    RRx_GTP_SoftResetRx_o          : out  std_logic;                                          
    RRx_GTP_DataValid_o         : out std_logic;          
    RRx_GTP_Rxuserrdy_o         : out std_logic;              
    RRx_GTP_Rxdata_i            : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
    RRx_GTP_Rxchariscomma_i     : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    RRx_GTP_Rxcharisk_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    RRx_GTP_Rxdisperr_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    RRx_GTP_Rxnotintable_i      : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
    RRx_GTP_Rxbyteisaligned_i   : in  std_logic;                                           
    RRx_GTP_Rxbyterealign_i     : in  std_logic;         
    RRx_GTP_PllLock_i           : in  std_logic;                                           
    RRx_GTP_PllRefclklost_i     : in  std_logic;   
    -- SpiNNaker Interface
    RRx_SPNN_Data_i             : in  std_logic_vector(6 downto 0); 
    RRx_SPNN_Ack_o              : out std_logic;
   
   
    --============================================
    -- Rx auxiliary Interface
    --============================================
    
    -- Parallel AER
    ARx_PAER_Addr_i             : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ARx_PAER_Req_i              : in  std_logic;
    ARx_PAER_Ack_o              : out std_logic;
    -- HSSAER channels 
    ARx_HSSAER_i                : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    -- GTP lines
    ARx_RxGtpMsg_o              : out std_logic_vector(7 downto 0);
    ARx_RxGtpMsgSrcRdy_o        : out std_logic;
    ARx_RxGtpMsgDstRdy_i        : in  std_logic;  
    ARx_RxGtpAlignRequest_o     : out std_logic;
    ARx_GTP_RxUsrClk2_i         : in  std_logic;
    ARx_GTP_SoftResetRx_o       : out  std_logic;                                          
    ARx_GTP_DataValid_o         : out std_logic;          
    ARx_GTP_Rxuserrdy_o         : out std_logic;              
    ARx_GTP_Rxdata_i            : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
    ARx_GTP_Rxchariscomma_i     : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    ARx_GTP_Rxcharisk_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    ARx_GTP_Rxdisperr_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    ARx_GTP_Rxnotintable_i      : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
    ARx_GTP_Rxbyteisaligned_i   : in  std_logic;                                           
    ARx_GTP_Rxbyterealign_i     : in  std_logic;         
    ARx_GTP_PllLock_i           : in  std_logic;                                           
    ARx_GTP_PllRefclklost_i     : in  std_logic;   
    -- SpiNNaker Interface 
    ARx_SPNN_Data_i             : in  std_logic_vector(6 downto 0); 
    ARx_SPNN_Ack_o              : out std_logic;  
    
    
    --============================================
    -- Interception
    --============================================
    RRxData_o               : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    RRxSrcRdy_o             : out std_logic;
    RRxDstRdy_i             : in  std_logic;
    RRxBypassData_i         : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    RRxBypassSrcRdy_i       : in  std_logic;
    RRxBypassDstRdy_o       : out std_logic;
    --
    LRxData_o               : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    LRxSrcRdy_o             : out std_logic;
    LRxDstRdy_i             : in  std_logic;
    LRxBypassData_i         : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    LRxBypassSrcRdy_i       : in  std_logic;
    LRxBypassDstRdy_o       : out std_logic;
    --
    AuxRxData_o             : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    AuxRxSrcRdy_o           : out std_logic;
    AuxRxDstRdy_i           : in  std_logic;
    AuxRxBypassData_i       : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    AuxRxBypassSrcRdy_i     : in  std_logic;
    AuxRxBypassDstRdy_o     : out std_logic;               
        
    --============================================
    -- Configuration interface
    --============================================
    DefLocFarLpbk_i   : in  std_logic;
    DefLocNearLpbk_i  : in  std_logic;
    
    --============================================
    -- Processor interface
    --============================================
    Interrupt_o       : out std_logic;
    
    -- Debug signals interface
    DBG_dataOk        : out std_logic;
    DBG_rawi          : out std_logic_vector(15 downto 0);
    DBG_data_written  : out std_logic;
    DBG_dma_burst_counter : out std_logic_vector(10 downto 0);
    DBG_dma_test_mode      : out std_logic;
    DBG_dma_EnableDma      : out std_logic;
    DBG_dma_is_running     : out std_logic;
    DBG_dma_Length         : out std_logic_vector(10 downto 0);
    DBG_dma_nedge_run      : out std_logic;
    
    
    -- ADD USER PORTS ABOVE THIS LINE ------------------
    
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete  
    -- Axi lite I/f                                                                                                                                          
--    S_AXI_ACLK        : in  std_logic;                                           --  AXI4LITE slave: Clock                                           
    S_AXI_ARESETN     : in  std_logic;                                             --  AXI4LITE slave: Reset                                         
    S_AXI_AWADDR      : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);       --  AXI4LITE slave: Write address                                 
    S_AXI_AWVALID     : in  std_logic;                                             --  AXI4LITE slave: Write address valid                           
    S_AXI_WDATA       : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);       --  AXI4LITE slave: Write data                                    
    S_AXI_WSTRB       : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);   --  AXI4LITE slave: Write strobe                                  
    S_AXI_WVALID      : in  std_logic;                                             --  AXI4LITE slave: Write data valid                              
    S_AXI_BREADY      : in  std_logic;                                             --  AXI4LITE slave: Response ready                                
    S_AXI_ARADDR      : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);       --  AXI4LITE slave: Read address                                  
    S_AXI_ARVALID     : in  std_logic;                                             --  AXI4LITE slave: Read address valid                            
    S_AXI_RREADY      : in  std_logic;                                             --  AXI4LITE slave: Read data ready                               
    S_AXI_ARREADY     : out std_logic;                                             --  AXI4LITE slave: read addres ready                             
    S_AXI_RDATA       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);       --  AXI4LITE slave: Read data                                     
    S_AXI_RRESP       : out std_logic_vector(1 downto 0);                          --  AXI4LITE slave: Read data response                            
    S_AXI_RVALID      : out std_logic;                                             --  AXI4LITE slave: Read data valid                               
    S_AXI_WREADY      : out std_logic;                                             --  AXI4LITE slave: Write data ready                              
    S_AXI_BRESP       : out std_logic_vector(1 downto 0);                          --  AXI4LITE slave: Response                                      
    S_AXI_BVALID      : out std_logic;                                             --  AXI4LITE slave: Resonse valid                                 
    S_AXI_AWREADY     : out std_logic;                                             --  AXI4LITE slave: Wrte address ready                            
    -- Axi Stream I/f                                                              
    S_AXIS_TREADY     : out std_logic;                                             --  Stream I/f: Ready to accept data in                           
    S_AXIS_TDATA      : in  std_logic_vector(31 downto 0);                         --  Stream I/f: Data in                                           
    S_AXIS_TLAST      : in  std_logic;                                             --  Stream I/f: Optional data in qualifier                        
    S_AXIS_TVALID     : in  std_logic;                                             --  Stream I/f: Data in is valid                                  
    M_AXIS_TVALID     : out std_logic;                                             --  Stream I/f: Data out is valid                                 
    M_AXIS_TDATA      : out std_logic_vector(31 downto 0);                         --  Stream I/f: Data Out                                          
    M_AXIS_TLAST      : out std_logic;                                             --  Stream I/f: Optional data out qualifier                       
    M_AXIS_TREADY     : in  std_logic                                              --  Stream I/f: Connected slave device is ready to accept data out
    );

--    attribute MAX_FANOUT  : string;
--    attribute SIGIS       : string;
--
--    attribute MAX_FANOUT of S_AXI_ACLK     : signal is "10000";
--    attribute MAX_FANOUT of S_AXI_ARESETN  : signal is "10000";
--    attribute SIGIS      of S_AXI_ACLK     : signal is "Clk";
--    attribute SIGIS      of S_AXI_ARESETN  : signal is "Rst";
--    attribute SIGIS      of Interrupt_o    : signal is "Interrupt";

end component;

-- --------------------------------------------------
--  AXI Lite Emulator
-- --------------------------------------------------	
component axi4lite_bfm_v00 
  generic(
		limit : integer := 1000;
		NORANDOM_DMA : integer := 0;
    SPI_ADC_RES : integer := 24;
    NUM_OF_RECEIVER    : natural := 32;
    AXI4LM_CMD_FILE    : string        := "AXI4LM_bfm.cmd";  -- Command file name
    AXI4LM_LOG_FILE    : string        := "AXI4LM_bfm.log"   -- Log file name
		);
  port ( -- AXI Slave
    S_AXI_ACLK : in  STD_LOGIC;
    S_AXI_ARESETN : in  STD_LOGIC;
    S_AXI_AWVALID : out  STD_LOGIC;
    S_AXI_AWREADY : in  STD_LOGIC;
    S_AXI_AWADDR : out  STD_LOGIC_VECTOR (31 downto 0);
    S_AXI_WVALID : out  STD_LOGIC;
    S_AXI_WREADY : in  STD_LOGIC;
    S_AXI_WDATA : out  STD_LOGIC_VECTOR (31 downto 0);
    S_AXI_WSTRB : out  STD_LOGIC_VECTOR (3 downto 0);
    S_AXI_BVALID : in  STD_LOGIC;
    S_AXI_BREADY : out  STD_LOGIC;
    S_AXI_BRESP : in  STD_LOGIC_VECTOR (1 downto 0);
    S_AXI_ARVALID : inout  STD_LOGIC;
    S_AXI_ARREADY : in  STD_LOGIC;
    S_AXI_ARADDR : out  STD_LOGIC_VECTOR (31 downto 0);
    S_AXI_RVALID : in  STD_LOGIC;
    S_AXI_RREADY : out  STD_LOGIC;
    S_AXI_RDATA : in  STD_LOGIC_VECTOR (31 downto 0);
    S_AXI_RRESP : in  STD_LOGIC_VECTOR (1 downto 0);
    -- AXI Stream
    M_AXIS_ACLK    : in  std_logic;
    M_AXIS_TVALID  : in  std_logic;
    M_AXIS_TLAST   : in  std_logic;
    M_AXIS_TDATA   : in  std_logic_vector (31 downto 0);
    M_AXIS_TREADY  : out std_logic;
    S_AXIS_ACLK    : in  std_logic;
    S_AXIS_TREADY  : in  std_logic;
    S_AXIS_TDATA   : out std_logic_vector(31 downto 0);
    S_AXIS_TLAST   : out std_logic;
    S_AXIS_TVALID  : out std_logic;
    -- AXI Master
    M_AXI_ACLK : in  STD_LOGIC;
    M_AXI_AWADDR   : in  std_logic_vector(31 downto 0);
    M_AXI_AWLEN    : in  std_logic_vector(7 downto 0); 
    M_AXI_AWSIZE   : in  std_logic_vector(2 downto 0);
    M_AXI_AWBURST  : in  std_logic_vector(1 downto 0);
    M_AXI_AWCACHE  : in  std_logic_vector(3 downto 0);
    M_AXI_AWVALID  : in  std_logic; 
    M_AXI_AWREADY  : out std_logic; 
    --       master interface write data
    M_AXI_WDATA    : in  std_logic_vector(31 downto 0); 
    M_AXI_WSTRB    : in  std_logic_vector(3 downto 0);
    M_AXI_WLAST    : in  std_logic;  
    M_AXI_WVALID   : in  std_logic;   
    M_AXI_WREADY   : out std_logic;  
    --       master interface write response
    M_AXI_BRESP    : out std_logic_vector(1 downto 0); 
    M_AXI_BVALID   : out std_logic;   
    M_AXI_BREADY   : in  std_logic;
    
    start_dmas     : out std_logic;
    dma_done       : in  std_logic;
    
    ocp_o          : out std_logic;
    ext_fault_o    : out std_logic;
    
    interrupt  	: in std_logic;
    start        : in std_logic
  );
end component;

-- --------------------------------------------------
--  PLL
-- --------------------------------------------------	
component PLL
	generic(
		SYSCLK_PERIOD               : integer := 10;
        SD_PERIOD                   : integer := 50;
		SWEEP                       : integer := 0
		);
	port(
		rst_in	                    : in  std_logic; 	-- Reset in
		rst_out	                    : out std_logic;	-- Reset out
		SYS_CLK	                    : out std_logic;  	-- Clock
        sd_rst_out                  : out std_logic;    -- Reset out
        SD_CLK                      : out std_logic     -- Clock 
	);
end component ;

-- --------------------------------------------------
--  SpiNNaker Emulator
-- --------------------------------------------------	
component SpiNNaker_Emulator 
    generic (
        HAS_ID       : string;
        ID           : natural;
        HAS_TX       : string;
        TX_FILE      : string;
        HAS_RX       : string;
        RX_FILE      : string
        ); 
		port (
		
  		-- SpiNNaker link asynchronous output interface
  		Lout         : out std_logic_vector(6 downto 0);
  		LoutAck      : in std_logic;
  		
  		-- SpiNNaker link asynchronous input interface
  		Lin          : in std_logic_vector(6 downto 0);
  		LinAck       : out std_logic;
  		
  		-- Control interface
  		enable       : in std_logic; 
  		rst          : in std_logic
  		);
end component ;

-- --------------------------------------------------
--  AER Device Emulator
-- --------------------------------------------------	
component AER_Device_Emulator 
	port (

		-- AER Device asynchronous output interface
		AERout		: out std_logic_vector(23 downto 0);
		AERoutReq	: out std_logic;
		AERoutAck	: in std_logic;

		-- AER Device asynchronous input interface
		AERin		: in std_logic_vector(23 downto 0);
		AERinReq    : in std_logic;
		AERinAck    : out std_logic;
  
		-- Control interface
		enable		: in std_logic;
		rst			: in std_logic
  );
end component ;

component GTP_Emulator is
  generic (
    C_GTP_RXUSRCLK2_PERIOD_NS : real                          := 6.4;        
    C_GTP_TXUSRCLK2_PERIOD_NS : real                          := 6.4;  
    C_GTP_DSIZE               : positive                      := 16 
    );
  port (
    -- GTP interface
    RxGtpAlignRequest_i    : in  std_logic;
    TxGtpAlignRequest_o    : out std_logic;
    -- 
    GTP_RxUsrClk2_o        : out std_logic;                                      
    GTP_TxUsrClk2_o        : out std_logic;                                      
    GTP_SoftResetRx_i      : in  std_logic;                                     
    GTP_SoftResetTx_i      : in  std_logic;                                     
    GTP_DataValid_i        : in  std_logic;                                      
    --
    GTP_Rxuserrdy_i        : in  std_logic;                                      
    GTP_Rxdata_o           : out std_logic_vector(C_GTP_DSIZE-1 downto 0);       
    GTP_Rxchariscomma_o    : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxcharisk_o        : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxdisperr_o        : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxnotintable_o     : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxbyteisaligned_o  : out std_logic;                                      
    GTP_Rxbyterealign_o    : out std_logic;    
    --
    GTP_Txuserrdy_i        : in  std_logic;                                           
    GTP_Txdata_i           : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);            
    GTP_Txcharisk_i        : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0); 
    --                                  
    GTP_PllLock_o          : out std_logic;                                      
    GTP_PllRefclklost_o    : out std_logic
    );
end component;

 

signal i_clk                    : std_logic;
signal i_resetn, i_reset        : std_logic;

-- Spinnaker
signal data_from_SPNN_L    : std_logic_vector(6 downto 0); 
signal ack_to_SPNN_L       : std_logic;
signal data_from_SPNN_R    : std_logic_vector(6 downto 0); 
signal ack_to_SPNN_R       : std_logic;
signal data_from_SPNN_A    : std_logic_vector(6 downto 0); 
signal ack_to_SPNN_A       : std_logic;
signal data_to_SPNN        : std_logic_vector(6 downto 0);
signal ack_from_SPNN       : std_logic;


--AER
signal data_from_AER_L			: std_logic_vector(23 downto 0);
signal req_from_AER_L			: std_logic;
signal ack_to_AER_L				: std_logic;
signal data_to_AER_L			: std_logic_vector(23 downto 0);
signal req_to_AER_L    			: std_logic;
signal ack_from_AER_L     		: std_logic;
signal AER_device_enable_L		: std_logic;
signal SPNN_device_enable_L     : std_logic;
signal SPNN_device_reset_L		: std_logic;

signal data_from_AER_R			: std_logic_vector(23 downto 0);
signal req_from_AER_R			: std_logic;
signal ack_to_AER_R				: std_logic;
signal data_to_AER_R			: std_logic_vector(23 downto 0);
signal req_to_AER_R    			: std_logic;
signal ack_from_AER_R     		: std_logic;
signal AER_device_enable_R		: std_logic;
signal SPNN_device_enable_R     : std_logic;
signal SPNN_device_reset_R  	: std_logic;

signal data_from_AER_Aux		: std_logic_vector(23 downto 0);
signal req_from_AER_Aux			: std_logic;
signal ack_to_AER_Aux			: std_logic;
signal data_to_AER_Aux			: std_logic_vector(23 downto 0);
signal req_to_AER_Aux    		: std_logic;
signal ack_from_AER_Aux     	: std_logic;
signal AER_device_enable_Aux	: std_logic;
signal SPNN_device_enable_Aux   : std_logic;
signal SPNN_device_reset_Aux	: std_logic;
 
signal data_from_AER_Tx			: std_logic_vector(23 downto 0);
signal req_from_AER_Tx			: std_logic;
signal ack_to_AER_Tx			: std_logic;
signal data_to_AER_Tx			: std_logic_vector(23 downto 0);
signal req_to_AER_Tx    		: std_logic;
signal ack_from_AER_Tx     		: std_logic;
signal AER_device_enable_Tx		: std_logic;
signal SPNN_device_enable_Tx    : std_logic;
signal SPNN_device_reset_Tx	    : std_logic;

-- Clocks
signal ClkCore              		: std_logic;
signal ClkAxis              		: std_logic;
signal HSSAER_ClkLS_p           : std_logic;
signal HSSAER_ClkLS_n           : std_logic;
signal HSSAER_ClkHS_p           : std_logic;
signal HSSAER_ClkHS_n           : std_logic;

-- AXI
signal s_axi_aclk               : std_logic;
signal s_axi_aresetn            : std_logic;
signal s_axi_awaddr             : std_logic_vector(31 downto 0);
signal s_axi_awvalid            : std_logic;
signal s_axi_wdata              : std_logic_vector(31 downto 0);
signal s_axi_wstrb              : std_logic_vector(3 downto 0);
signal s_axi_wvalid             : std_logic;
signal s_axi_bready             : std_logic;
signal s_axi_araddr             : std_logic_vector(31 downto 0);
signal s_axi_arvalid            : std_logic;
signal s_axi_rready             : std_logic;
signal s_axi_arready            : std_logic;
signal s_axi_rdata              : std_logic_vector(31 downto 0);
signal s_axi_rresp              : std_logic_vector(1 downto 0);
signal s_axi_rvalid             : std_logic;
signal s_axi_wready             : std_logic;
signal s_axi_bresp              : std_logic_vector(1 downto 0);
signal s_axi_bvalid             : std_logic;
signal s_axi_awready            : std_logic;
signal s_axis_tready            : std_logic;
signal s_axis_tdata             : std_logic_vector(31 downto 0);
signal s_axis_tlast             : std_logic;
signal s_axis_tvalid            : std_logic;
signal m_axis_tvalid            : std_logic;
signal m_axis_tdata             : std_logic_vector(31 downto 0);
signal m_axis_tlast             : std_logic;
signal m_axis_tready            : std_logic;
signal m_axi_araddr             : std_logic_vector(31 downto 0);
signal m_axi_arlen              : std_logic_vector( 7 downto 0);
signal m_axi_arsize             : std_logic_vector( 2 downto 0);
signal m_axi_arburst            : std_logic_vector( 1 downto 0);
signal m_axi_arcache            : std_logic_vector( 3 downto 0);
signal m_axi_arvalid            : std_logic;
signal m_axi_arready            : std_logic;
signal m_axi_rdata              : std_logic_vector(31 downto 0);  
signal m_axi_rresp              : std_logic_vector( 1 downto 0);  
signal m_axi_rlast              : std_logic;                      
signal m_axi_rvalid             : std_logic;                      
signal m_axi_rready             : std_logic;                      
signal m_axi_awaddr             : std_logic_vector(31 downto 0);
signal m_axi_awlen              : std_logic_vector(7 downto 0);
signal m_axi_awsize             : std_logic_vector(2 downto 0);
signal m_axi_awburst            : std_logic_vector(1 downto 0);
signal m_axi_awvalid            : std_logic;
signal m_axi_awready            : std_logic;
signal m_axi_wdata              : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal m_axi_wstrb              : std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
signal m_axi_wlast              : std_logic; 
signal m_axi_wvalid             : std_logic;
signal m_axi_wready             : std_logic;
signal m_axi_bresp              : std_logic_vector(1 downto 0);
signal m_axi_bvalid             : std_logic;
signal m_axi_bready             : std_logic;
signal m_axi_awcache            : std_logic_vector(3 downto 0);

signal i_start                  : std_logic;
signal i_rst_in                 : std_logic := '0';
signal i_Interrupt              : std_logic := '0';

signal i_en                     : std_logic;

signal tx                       : std_logic_vector(NUM_OF_TRANSMITTER-1 downto 0 );

signal start_dmas               : std_logic;
signal dma_done                 : std_logic;
signal i_Async_reset            : std_logic;
signal i_vr1_i                  : std_logic_vector (7 downto 0);
signal i_vr2_i                  : std_logic_vector (7 downto 0);
signal i_vr3_i                  : std_logic_vector (7 downto 0);
signal pwmap                    : std_logic;
signal pwman                    : std_logic;
signal pwmbp                    : std_logic;
signal pwmbn                    : std_logic;
signal pwmcp                    : std_logic;
signal pwmcn                    : std_logic;

-- encoder
signal i_FromSpeed              : real;
signal i_ToSpeed                : real := 10000.0;
signal i_SpeedInDeltaTime       : time := 3 ms;
signal i_encoder_A, i_encoder_B, i_encoder_Index, i_encoder_Home : std_logic;
signal i_encoder_encoder_A, i_encoder_encoder_B, i_encoder_encoder_Index, i_encoder_encoder_Home : std_logic;

-- SD
signal i_sd_resetn              : std_logic;
signal i_sd_clk                 : std_logic;
signal clk_sd                   : std_logic;
signal resetn_sd                : std_logic;
signal current_sd               : std_logic_vector(2 downto 0);

-- current
signal i_ocp                    : std_logic;
signal i_ext_fault              : std_logic;

-- VDClink
signal i_vdclink_data_sd        : std_logic;
signal i_vdclink_clk_sd         : std_logic;

-- GTP
 
signal GTP_PllLock                 : std_logic;                                      
signal GTP_PllRefclklost           : std_logic; 
 
-- Tx
signal Tx_TxGtpMsg                 : std_logic_vector(7 downto 0);
signal Tx_TxGtpMsgSrcRdy           : std_logic;
signal Tx_TxGtpMsgDstRdy           : std_logic;  
signal Tx_TxGtpAlignRequest        : std_logic;
signal Tx_TxGtpAlignFlag           : std_logic;
signal Tx_GTP_TxUsrClk2            : std_logic;   
signal Tx_GTP_SoftResetTx          : std_logic;                                          
signal Tx_GTP_DataValid            : std_logic;    
signal Tx_GTP_Txuserrdy            : std_logic;                                           
signal Tx_GTP_Txdata               : std_logic_vector(C_GTP_DSIZE-1 downto 0);            
signal Tx_GTP_Txcharisk            : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
signal Tx_GTP_PllLock              : std_logic;                                           
signal Tx_GTP_PllRefclklost        : std_logic;  

-- Left
signal LRx_RxGtpMsg               : std_logic_vector(7 downto 0);
signal LRx_RxGtpMsgSrcRdy         : std_logic;
signal LRx_RxGtpMsgDstRdy         : std_logic;  
signal LRx_RxGtpAlignRequest      : std_logic;
signal LRx_GTP_RxUsrClk2          : std_logic;                                      
signal LRx_GTP_SoftResetRx        : std_logic;                                     
signal LRx_GTP_DataValid          : std_logic;                                      
signal LRx_GTP_Rxuserrdy          : std_logic;                                      
signal LRx_GTP_Rxdata             : std_logic_vector(C_GTP_DSIZE-1 downto 0);       
signal LRx_GTP_Rxchariscomma      : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal LRx_GTP_Rxcharisk          : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal LRx_GTP_Rxdisperr          : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal LRx_GTP_Rxnotintable       : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal LRx_GTP_Rxbyteisaligned    : std_logic;                                      
signal LRx_GTP_Rxbyterealign      : std_logic;                                      
signal LRx_GTP_PllLock            : std_logic;                                      
signal LRx_GTP_PllRefclklost      : std_logic; 

-- Right
signal RRx_RxGtpMsg               : std_logic_vector(7 downto 0);
signal RRx_RxGtpMsgSrcRdy         : std_logic;
signal RRx_RxGtpMsgDstRdy         : std_logic;  
signal RRx_RxGtpAlignRequest      : std_logic;
signal RRx_GTP_RxUsrClk2          : std_logic;                                      
signal RRx_GTP_SoftResetRx        : std_logic;                                     
signal RRx_GTP_DataValid          : std_logic;                                      
signal RRx_GTP_Rxuserrdy          : std_logic;                                      
signal RRx_GTP_Rxdata             : std_logic_vector(C_GTP_DSIZE-1 downto 0);       
signal RRx_GTP_Rxchariscomma      : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal RRx_GTP_Rxcharisk          : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal RRx_GTP_Rxdisperr          : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal RRx_GTP_Rxnotintable       : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal RRx_GTP_Rxbyteisaligned    : std_logic;                                      
signal RRx_GTP_Rxbyterealign      : std_logic;                                      
signal RRx_GTP_PllLock            : std_logic;                                      
signal RRx_GTP_PllRefclklost      : std_logic; 

-- Aux
signal ARx_RxGtpMsg               : std_logic_vector(7 downto 0);
signal ARx_RxGtpMsgSrcRdy         : std_logic;
signal ARx_RxGtpMsgDstRdy         : std_logic;  
signal ARx_RxGtpAlignRequest      : std_logic;
signal ARx_GTP_RxUsrClk2          : std_logic;                                      
signal ARx_GTP_SoftResetRx        : std_logic;                                     
signal ARx_GTP_DataValid          : std_logic;                                      
signal ARx_GTP_Rxuserrdy          : std_logic;                                      
signal ARx_GTP_Rxdata             : std_logic_vector(C_GTP_DSIZE-1 downto 0);       
signal ARx_GTP_Rxchariscomma      : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal ARx_GTP_Rxcharisk          : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal ARx_GTP_Rxdisperr          : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal ARx_GTP_Rxnotintable       : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
signal ARx_GTP_Rxbyteisaligned    : std_logic;                                      
signal ARx_GTP_Rxbyterealign      : std_logic;                                      
signal ARx_GTP_PllLock            : std_logic;                                      
signal ARx_GTP_PllRefclklost      : std_logic; 

 
-- 
signal M_Axis_TREADY_HPU        : std_logic;

file logfile_ptr      : text open WRITE_MODE is "RX_FIFO.csv";

begin 

-- ************************************************************************************************************************

-- --------------------------------------------------
-- Clock Generator
-- --------------------------------------------------	
-- PLL_i : PLL
-- 	generic map(
-- 		SYSCLK_PERIOD        => CLK_PERIOD,
--         SD_PERIOD            => 50,
-- 		SWEEP                => 0
-- 		)
-- 	port map( 
-- 		rst_in	             => i_rst_in,
-- 		rst_out	             => i_resetn,
-- 		SYS_CLK	             => i_clk,
--         sd_rst_out           => i_sd_resetn,
--         SD_CLK               => i_sd_clk
-- 	);


-- --------------------------------------------------
-- SpiNNaker Emulator
-- --------------------------------------------------	
L_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 1,
    HAS_TX     => "false",
    TX_FILE    => "../../../../../sim/Data_To_L.txt",
    HAS_RX     => "false",
    RX_FILE    => ""
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => data_from_SPNN_L, 
	LoutAck    => ack_to_SPNN_L,
	
	-- SpiNNaker link asynchronous input interface
	Lin        => (others => '0'),
	LinAck     => open,
	
	-- Control interface
	enable     => SPNN_device_enable_L,
	rst        => SPNN_device_reset_L -- i_reset
	);

R_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 2,
    HAS_TX     => "false",
    TX_FILE    => "../../../../../sim/Data_To_R.txt",
    HAS_RX     => "false",
    RX_FILE    => ""
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => data_from_SPNN_R,
	LoutAck    => ack_to_SPNN_R,   
	
	-- SpiNNaker link asynchronous input interface
	Lin        => (others => '0'),
	LinAck     => open,
	
	-- Control interface
	enable     => SPNN_device_enable_R,
	rst        => SPNN_device_reset_R -- i_reset
	);

AUX_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 3,
    HAS_TX     => "true",
    TX_FILE    => "../../../../../sim/Data_To_AUX.txt",
    HAS_RX     => "false",
    RX_FILE    => "u"
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => data_from_SPNN_A,
	LoutAck    => ack_to_SPNN_A,
	
	-- SpiNNaker link asynchronous input interface
	Lin        => (others => '0'),
	LinAck     => open,
	
	-- Control interface
	enable     => SPNN_device_enable_Aux,
	rst        => SPNN_device_reset_Aux -- i_reset
	);


TX_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 0,
    HAS_TX     => "false",
    TX_FILE    => "",
    HAS_RX     => "true",
    RX_FILE    => "Data_From_TX.txt"
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => open,
	LoutAck    => '0',
	
	-- SpiNNaker link asynchronous input interface
	Lin        => data_to_SPNN,
	LinAck     => ack_from_SPNN,
	
	-- Control interface
	enable     => SPNN_device_enable_Tx,
	rst        => SPNN_device_reset_Tx -- i_reset
	);


-- --------------------------------------------------
-- AXI lite Emulator
-- --------------------------------------------------
AXI_EMULATOR_i : axi4lite_bfm_v00
	generic map (
        NORANDOM_DMA => NORANDOM_DMA
        )
	port map (				
        S_AXI_ACLK      => ClkCore,
        S_AXI_ARESETN   => i_resetn,
        S_AXI_AWVALID   => s_axi_awvalid,
        S_AXI_AWREADY   => s_axi_awready,
        S_AXI_AWADDR    => s_axi_awaddr,
        S_AXI_WVALID    => s_axi_wvalid,
        S_AXI_WREADY    => s_axi_wready,
        S_AXI_WDATA     => s_axi_wdata,
        S_AXI_WSTRB     => s_axi_wstrb,
        S_AXI_BVALID    => s_axi_bvalid,
        S_AXI_BREADY    => s_axi_bready,
        S_AXI_BRESP     => s_axi_bresp,
        S_AXI_ARVALID   => s_axi_arvalid,
        S_AXI_ARREADY   => s_axi_arready,
        S_AXI_ARADDR    => s_axi_araddr,
        S_AXI_RVALID    => s_axi_rvalid,
        S_AXI_RREADY    => s_axi_rready,
        S_AXI_RDATA     => s_axi_rdata,
        S_AXI_RRESP     => s_axi_rresp,
        -- AXI Stream
        M_AXIS_ACLK     => ClkAxis,
        M_Axis_TVALID   => m_axis_tvalid,
        M_Axis_TLAST    => m_axis_tlast,
        M_Axis_TDATA    => m_axis_tdata,
        M_Axis_TREADY   => m_axis_tready,
        S_AXIS_ACLK     => ClkAxis,
        S_AXIS_TREADY   => s_axis_tready,
        S_AXIS_TDATA    => s_axis_tdata,
        S_AXIS_TLAST    => s_axis_tlast,
        S_AXIS_TVALID   => s_axis_tvalid,
        -- Axi master
        M_AXI_ACLK      => HSSAER_ClkLS_p,
        M_AXI_AWADDR    => m_axi_awaddr,
        M_AXI_AWLEN     => m_axi_awlen,
        M_AXI_AWSIZE    => m_axi_awsize,
        M_AXI_AWBURST   => m_axi_awburst,
        M_AXI_AWCACHE   => m_axi_awcache,
        M_AXI_AWVALID   => m_axi_awvalid,
        M_AXI_AWREADY   => m_axi_awready,
        --       master interface write data
        M_AXI_WDATA     => m_axi_wdata,
        M_AXI_WSTRB     => m_axi_wstrb,
        M_AXI_WLAST     => m_axi_wlast,
        M_AXI_WVALID    => m_axi_wvalid,
        M_AXI_WREADY    => m_axi_wready,
        --       master interface write response
        M_AXI_BRESP     => m_axi_bresp,
        M_AXI_BVALID    => m_axi_bvalid,
        M_AXI_BREADY    => m_axi_bready,
        
        start_dmas      => start_dmas,
        dma_done        => dma_done,
        
        ocp_o           => i_ocp,
        ext_fault_o     => i_ext_fault,
        
        
        interrupt       => i_Interrupt,
        start           => i_start
        );

-- --------------------------------------------------
-- AER Device Emulators
-- --------------------------------------------------
L_AER_DEVICE_EMULATOR_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_L,
		AERoutReq	=> req_from_AER_L,
		AERoutAck	=> ack_to_AER_L,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_L,
		AERinReq    => req_to_AER_L,
		AERinAck    => ack_from_AER_L,

		-- Control interface
		enable		=> AER_device_enable_L,
		rst			=> i_reset
); 

R_AER_DEVICE_EMULATOR_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_R,
		AERoutReq	=> req_from_AER_R,
		AERoutAck	=> ack_to_AER_R,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_R,
		AERinReq    => req_to_AER_R,
		AERinAck    => ack_from_AER_R,

		-- Control interface
		enable		=> AER_device_enable_R,
		rst			=> i_reset
); 

AUX_AER_DEVICE_EMULATOR_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_Aux,
		AERoutReq	=> req_from_AER_Aux,
		AERoutAck	=> ack_to_AER_Aux,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_Aux,
		AERinReq    => req_to_AER_Aux,
		AERinAck    => ack_from_AER_Aux,

		-- Control interface
		enable		=> AER_device_enable_Aux,
		rst			=> i_reset
); 

AER_DEVICE_EMULATOR_Tx_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_Tx,
		AERoutReq	=> req_from_AER_Tx,
		AERoutAck	=> ack_to_AER_Tx,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_Tx,
		AERinReq    => req_to_AER_Tx,
		AERinAck    => ack_from_AER_Tx, 

		-- Control interface
		enable		=> AER_device_enable_Tx,
		rst			=> i_reset
); 

GTP_DEVICE_EMULATOR_i : GTP_Emulator 
  generic map(
    C_GTP_RXUSRCLK2_PERIOD_NS => 6.4,        
    C_GTP_TXUSRCLK2_PERIOD_NS => 6.4,  
    C_GTP_DSIZE               => 16 
    )
  port map(
    -- GTP interface
    RxGtpAlignRequest_i    => LRx_RxGtpAlignRequest,  -- : in  std_logic;
    TxGtpAlignRequest_o    => Tx_TxGtpAlignRequest,
    -- 
    GTP_RxUsrClk2_o        => LRx_GTP_RxUsrClk2,       -- : out std_logic;   
    GTP_TxUsrClk2_o        => Tx_GTP_TxUsrClk2,
    GTP_SoftResetRx_i      => LRx_GTP_SoftResetRx,     -- : in  std_logic;                                     
    GTP_SoftResetTx_i      => Tx_GTP_SoftResetTx,     -- : in  std_logic;                                     
    GTP_DataValid_i        => LRx_GTP_DataValid,       -- : in  std_logic;        
    --                              
    GTP_Rxuserrdy_i        => LRx_GTP_Rxuserrdy,       -- : in  std_logic;                                      
    GTP_Rxdata_o           => LRx_GTP_Rxdata,          -- : out std_logic_vector(C_GTP_DSIZE-1 downto 0);       
    GTP_Rxchariscomma_o    => LRx_GTP_Rxchariscomma,   -- : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxcharisk_o        => LRx_GTP_Rxcharisk,       -- : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxdisperr_o        => LRx_GTP_Rxdisperr,       -- : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxnotintable_o     => LRx_GTP_Rxnotintable,    -- : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);   
    GTP_Rxbyteisaligned_o  => LRx_GTP_Rxbyteisaligned, -- : out std_logic;                                      
    GTP_Rxbyterealign_o    => LRx_GTP_Rxbyterealign,   -- : out std_logic;       
    --
    GTP_Txuserrdy_i        => Tx_GTP_Txuserrdy, 
    GTP_Txdata_i           => Tx_GTP_Txdata, 
    GTP_Txcharisk_i        => Tx_GTP_Txcharisk,
    --                               
    GTP_PllLock_o          => GTP_PllLock,         -- : out std_logic;                                      
    GTP_PllRefclklost_o    => GTP_PllRefclklost    -- : out std_logic
    );


-- --------------------------------------------------
--  Unit Under Test: HPUcore
-- --------------------------------------------------

LRx_GTP_PllLock         <= GTP_PllLock;
LRx_GTP_PllRefclklost   <= GTP_PllRefclklost;
RRx_GTP_PllLock         <= GTP_PllLock;
RRx_GTP_PllRefclklost   <= GTP_PllRefclklost;
ARx_GTP_PllLock         <= GTP_PllLock;
ARx_GTP_PllRefclklost   <= GTP_PllRefclklost;
Tx_GTP_PllLock          <= GTP_PllLock;
Tx_GTP_PllRefclklost    <= GTP_PllRefclklost;

HPUCORE_i : HPUCore    
    generic map (
        -- -----------------------    
        -- GENERAL
        C_FAMILY                    => "zynquplus", -- "zynq", "zynquplus"  
        -- ----------------------- 
        -- PAER        
        C_RX_L_HAS_PAER             => true, 
        C_RX_R_HAS_PAER             => false, 
        C_RX_A_HAS_PAER             => false, 
        C_RX_PAER_L_SENS_ID         => "000",
        C_RX_PAER_R_SENS_ID         => "000",
        C_RX_PAER_A_SENS_ID         => "001",
        C_TX_HAS_PAER               => true,
        C_PAER_DSIZE                => 24,   
        -- -----------------------        
        -- HSSAER
        C_RX_L_HAS_HSSAER           => false, 
        C_RX_R_HAS_HSSAER           => false, 
        C_RX_A_HAS_HSSAER           => false, 
        C_RX_HSSAER_N_CHAN          => 3,
        C_RX_SAER0_L_SENS_ID        => "000",
        C_RX_SAER1_L_SENS_ID        => "000",
        C_RX_SAER2_L_SENS_ID        => "000",
        C_RX_SAER3_L_SENS_ID        => "000",        
        C_RX_SAER0_R_SENS_ID        => "000",
        C_RX_SAER1_R_SENS_ID        => "000",
        C_RX_SAER2_R_SENS_ID        => "000",
        C_RX_SAER3_R_SENS_ID        => "000",        
        C_RX_SAER0_A_SENS_ID        => "001",
        C_RX_SAER1_A_SENS_ID        => "001",
        C_RX_SAER2_A_SENS_ID        => "001",
        C_RX_SAER3_A_SENS_ID        => "001",
        C_TX_HAS_HSSAER             => false,
        C_TX_HSSAER_N_CHAN          => 3,
        -- -----------------------        
        -- GTP
        C_RX_L_HAS_GTP              => false,
        C_RX_R_HAS_GTP              => false,
        C_RX_A_HAS_GTP              => false,
        -- C_GTP_RXUSRCLK2_PERIOD_NS   => 6.4,     
        C_GTP_RXUSRCLK2_PERIOD_PS   => 6400,     
        C_TX_HAS_GTP                => false,
        -- C_GTP_TXUSRCLK2_PERIOD_NS   => 6.4, 
        C_GTP_TXUSRCLK2_PERIOD_PS   => 6400,   
        C_GTP_DSIZE                 => C_GTP_DSIZE,
        -- -----------------------                
        -- SPINNLINK
        C_RX_L_HAS_SPNNLNK          => false, 
        C_RX_R_HAS_SPNNLNK          => false, 
        C_RX_A_HAS_SPNNLNK          => false, 
        C_TX_HAS_SPNNLNK            => false,
        C_PSPNNLNK_WIDTH		        => 32,
        -- -----------------------
        -- INTERCEPTION
        C_RX_L_INTERCEPTION         => false,
        C_RX_R_INTERCEPTION         => false,
        C_RX_A_INTERCEPTION         => false,
        -- -----------------------
        -- CORE
        --C_SYSCLK_PERIOD_NS          => 10.0,               
        C_SYSCLK_PERIOD_PS          => 10000,               
        C_HAS_DEFAULT_LOOPBACK      => false,
        -- -----------------------
        -- BUS PROTOCOL PARAMETERS
        C_S_AXI_DATA_WIDTH          => C_S_AXI_DATA_WIDTH,		
        C_S_AXI_ADDR_WIDTH          => C_S_AXI_ADDR_WIDTH,		
        C_SLV_DWIDTH                => 32,
        -- -----------------------
        -- SIMULATION
        C_SIM_TIME_COMPRESSION      => true
    )
    port map(

        -- SYNC Resetn
        CLEAR_N_i        			      => i_resetn,
        
        -- Main Core Clock 
        CLK_CORE_i                  => ClkCore,
        
        -- AXI Stream Clock
        CLK_AXIS_i                  => ClkAxis,

        -- Clocks for HSSAER interface
        CLK_HSSAER_LS_P_i 			    => HSSAER_ClkLS_p, -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
        CLK_HSSAER_LS_N_i 			    => HSSAER_ClkLS_n, -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
        CLK_HSSAER_HS_P_i 			    => HSSAER_ClkHS_p, -- 300 Mhz clock p it must 3x HSSAER_ClkLS
        CLK_HSSAER_HS_N_i 			    => HSSAER_ClkHS_n, -- 300 Mhz clock p it must 3x HSSAER_ClkLS


        --============================================
        -- Tx Interface
        --============================================

        -- Parallel AER
        Tx_PAER_Addr_o            	=> data_to_AER_Tx,
        Tx_PAER_Req_o             	=> req_to_AER_Tx,
        Tx_PAER_Ack_i             	=> ack_from_AER_Tx,
        -- HSSAER channels
        Tx_HSSAER_o               	=> open,
        -- GTP lines
        Tx_TxGtpMsg_i               => Tx_TxGtpMsg,
        Tx_TxGtpMsgSrcRdy_i         => Tx_TxGtpMsgSrcRdy,
        Tx_TxGtpMsgDstRdy_o         => Tx_TxGtpMsgDstRdy,
        Tx_TxGtpAlignRequest_i      => Tx_TxGtpAlignRequest,
        Tx_TxGtpAlignFlag_o         => Tx_TxGtpAlignFlag,
        Tx_GTP_TxUsrClk2_i          => Tx_GTP_TxUsrClk2,
        Tx_GTP_SoftResetTx_o        => Tx_GTP_SoftResetTx,
        Tx_GTP_DataValid_o          => Tx_GTP_DataValid,
        Tx_GTP_Txuserrdy_o          => Tx_GTP_Txuserrdy,
        Tx_GTP_Txdata_o             => Tx_GTP_Txdata,
        Tx_GTP_Txcharisk_o          => Tx_GTP_Txcharisk,
        Tx_GTP_PllLock_i            => Tx_GTP_PllLock,
        Tx_GTP_PllRefclklost_i      => Tx_GTP_PllRefclklost,
        -- SpiNNaker Interface      
        Tx_SPNN_Data_o              => data_to_SPNN,  --   : out std_logic_vector(6 downto 0);
        Tx_SPNN_Ack_i               => ack_from_SPNN,      --   : in  std_logic;


        --============================================
        -- Rx Left Interface
        --============================================

        -- Parallel AER
        LRx_PAER_Addr_i           	=> data_from_AER_L,
        LRx_PAER_Req_i            	=> req_from_AER_L,
        LRx_PAER_Ack_o            	=> ack_to_AER_L,
        -- HSSAER channels
        LRx_HSSAER_i              	=> (others=> '0'),
        -- GTP lines
        LRx_RxGtpMsg_o              => LRx_RxGtpMsg,              
        LRx_RxGtpMsgSrcRdy_o        => LRx_RxGtpMsgSrcRdy,        
        LRx_RxGtpMsgDstRdy_i        => LRx_RxGtpMsgDstRdy,        
        LRx_RxGtpAlignRequest_o     => LRx_RxGtpAlignRequest,
        LRx_GTP_RxUsrClk2_i         => LRx_GTP_RxUsrClk2,
        LRx_GTP_SoftResetRx_o       => LRx_GTP_SoftResetRx,
        LRx_GTP_DataValid_o         => LRx_GTP_DataValid,
        LRx_GTP_Rxuserrdy_o         => LRx_GTP_Rxuserrdy,
        LRx_GTP_Rxdata_i            => LRx_GTP_Rxdata,
        LRx_GTP_Rxchariscomma_i     => LRx_GTP_Rxchariscomma,
        LRx_GTP_Rxcharisk_i         => LRx_GTP_Rxcharisk,
        LRx_GTP_Rxdisperr_i         => LRx_GTP_Rxdisperr,
        LRx_GTP_Rxnotintable_i      => LRx_GTP_Rxnotintable,
        LRx_GTP_Rxbyteisaligned_i   => LRx_GTP_Rxbyteisaligned,
        LRx_GTP_Rxbyterealign_i     => LRx_GTP_Rxbyterealign,
        LRx_GTP_PllLock_i           => LRx_GTP_PllLock,
        LRx_GTP_PllRefclklost_i     => LRx_GTP_PllRefclklost,
        -- SpiNNaker Interface 
        LRx_SPNN_Data_i             => data_from_SPNN_L,  --   : out std_logic_vector(6 downto 0);
        LRx_SPNN_Ack_o              => ack_to_SPNN_L,      --   : in  std_logic;        

        --============================================
        -- Rx Right Interface
        --============================================

        -- Parallel AER
        RRx_PAER_Addr_i           	=> data_from_AER_R,
        RRx_PAER_Req_i            	=> req_from_AER_R,
        RRx_PAER_Ack_o            	=> ack_to_AER_R,
        -- HSSAER channels
        RRx_HSSAER_i              	=> (others=> '0'),
        -- GTP lines
        RRx_RxGtpMsg_o              => RRx_RxGtpMsg,              
        RRx_RxGtpMsgSrcRdy_o        => RRx_RxGtpMsgSrcRdy,        
        RRx_RxGtpMsgDstRdy_i        => RRx_RxGtpMsgDstRdy,        
        RRx_RxGtpAlignRequest_o     => RRx_RxGtpAlignRequest,
        RRx_GTP_RxUsrClk2_i         => RRx_GTP_RxUsrClk2,
        RRx_GTP_SoftResetRx_o       => RRx_GTP_SoftResetRx,
        RRx_GTP_DataValid_o         => RRx_GTP_DataValid,
        RRx_GTP_Rxuserrdy_o         => RRx_GTP_Rxuserrdy,
        RRx_GTP_Rxdata_i            => RRx_GTP_Rxdata,
        RRx_GTP_Rxchariscomma_i     => RRx_GTP_Rxchariscomma,
        RRx_GTP_Rxcharisk_i         => RRx_GTP_Rxcharisk,
        RRx_GTP_Rxdisperr_i         => RRx_GTP_Rxdisperr,
        RRx_GTP_Rxnotintable_i      => RRx_GTP_Rxnotintable,
        RRx_GTP_Rxbyteisaligned_i   => RRx_GTP_Rxbyteisaligned,
        RRx_GTP_Rxbyterealign_i     => RRx_GTP_Rxbyterealign,
        RRx_GTP_PllLock_i           => RRx_GTP_PllLock,
        RRx_GTP_PllRefclklost_i     => RRx_GTP_PllRefclklost,
        -- SpiNNaker Interface 
        RRx_SPNN_Data_i             => data_from_SPNN_R,  --   : out std_logic_vector(6 downto 0);
        RRx_SPNN_Ack_o              => ack_to_SPNN_R,      --   : in  std_logic;        

        --============================================
        -- Rx Auxiliary Interface
        --============================================ 

        -- Parallel AER 
        ARx_PAER_Addr_i           	=> data_from_AER_Aux,
        ARx_PAER_Req_i            	=> req_from_AER_Aux,
        ARx_PAER_Ack_o            	=> ack_to_AER_Aux,
        -- HSSAER channels
        ARx_HSSAER_i              	=> (others=> '0'),
        -- GTP lines
        ARx_RxGtpMsg_o              => ARx_RxGtpMsg,              
        ARx_RxGtpMsgSrcRdy_o        => ARx_RxGtpMsgSrcRdy,        
        ARx_RxGtpMsgDstRdy_i        => ARx_RxGtpMsgDstRdy,        
        ARx_RxGtpAlignRequest_o     => ARx_RxGtpAlignRequest,
        ARx_GTP_RxUsrClk2_i         => ARx_GTP_RxUsrClk2,
        ARx_GTP_SoftResetRx_o       => ARx_GTP_SoftResetRx,
        ARx_GTP_DataValid_o         => ARx_GTP_DataValid,
        ARx_GTP_Rxuserrdy_o         => ARx_GTP_Rxuserrdy,
        ARx_GTP_Rxdata_i            => ARx_GTP_Rxdata,
        ARx_GTP_Rxchariscomma_i     => ARx_GTP_Rxchariscomma,
        ARx_GTP_Rxcharisk_i         => ARx_GTP_Rxcharisk,
        ARx_GTP_Rxdisperr_i         => ARx_GTP_Rxdisperr,
        ARx_GTP_Rxnotintable_i      => ARx_GTP_Rxnotintable,
        ARx_GTP_Rxbyteisaligned_i   => ARx_GTP_Rxbyteisaligned,
        ARx_GTP_Rxbyterealign_i     => ARx_GTP_Rxbyterealign,
        ARx_GTP_PllLock_i           => ARx_GTP_PllLock,
        ARx_GTP_PllRefclklost_i     => ARx_GTP_PllRefclklost,
        -- SpiNNaker Interface 
        ARx_SPNN_Data_i             => data_from_SPNN_A,  --   : out std_logic_vector(6 downto 0);
        ARx_SPNN_Ack_o              => ack_to_SPNN_A,      --   : in  std_logic;         
        
        --============================================
        -- Interception
        --============================================
        RRxData_o                    => open, -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        RRxSrcRdy_o                  => open, -- : out std_logic;
        RRxDstRdy_i                  => '0', -- : in  std_logic;
        RRxBypassData_i              => (others => '0'), -- : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        RRxBypassSrcRdy_i            => '0' , -- : in  std_logic;
        RRxBypassDstRdy_o            => open, -- : out std_logic;
        -- 
        LRxData_o                    => open, -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        LRxSrcRdy_o                  => open, -- : out std_logic;
        LRxDstRdy_i                  => '0', -- : in  std_logic;
        LRxBypassData_i              => (others => '0'), -- : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        LRxBypassSrcRdy_i            => '0', -- : in  std_logic;
        LRxBypassDstRdy_o            => open, -- : out std_logic;
        -- 
        AuxRxData_o                  => open, -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        AuxRxSrcRdy_o                => open, -- : out std_logic;
        AuxRxDstRdy_i                => '0', -- : in  std_logic;
        AuxRxBypassData_i            => (others => '0'), -- : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        AuxRxBypassSrcRdy_i          => '0', -- : in  std_logic;
        AuxRxBypassDstRdy_o          => open, -- : out std_logic;               
            
        --============================================
        -- Configuration interface
        --============================================
        DefLocFarLpbk_i   			=> '0',
        DefLocNearLpbk_i  			=> '0',

        --============================================
        -- Processor interface
        --============================================
        Interrupt_o       			=> open,

        -- Debug signals interface
        DBG_dataOk        			=> open,
        DBG_rawi          			=> open,
        DBG_data_written  			=> open,
        DBG_dma_burst_counter 		=> open,
        DBG_dma_test_mode      		=> open,
        DBG_dma_EnableDma      		=> open,
        DBG_dma_is_running     		=> open,
        DBG_dma_Length         		=> open,
        DBG_dma_nedge_run      		=> open,
                                    

        -- ADD USER PORTS ABOVE THIS LINE ------------------

        -- DO NOT EDIT BELOW THIS LINE ---------------------
        -- Bus protocol ports, do not add to or delete
        -- Axi lite I/f
--        S_AXI_ACLK        			=> HSSAER_ClkLS_p,
        S_AXI_ARESETN     			=> i_resetn,
        S_AXI_AWADDR      			=> s_axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto 0),
        S_AXI_AWVALID     			=> s_axi_awvalid,
        S_AXI_WDATA       			=> s_axi_wdata,
        S_AXI_WSTRB       			=> s_axi_wstrb,
        S_AXI_WVALID      			=> s_axi_wvalid,
        S_AXI_BREADY      			=> s_axi_bready,
        S_AXI_ARADDR      			=> s_axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto 0),
        S_AXI_ARVALID     			=> s_axi_arvalid,
        S_AXI_RREADY      			=> s_axi_rready,
        S_AXI_ARREADY     			=> s_axi_arready,
        S_AXI_RDATA       			=> s_axi_rdata,
        S_AXI_RRESP       			=> s_axi_rresp,
        S_AXI_RVALID      			=> s_axi_rvalid,
        S_AXI_WREADY      			=> s_axi_wready,
        S_AXI_BRESP       			=> s_axi_bresp,
        S_AXI_BVALID      			=> s_axi_bvalid,
        S_AXI_AWREADY     			=> s_axi_awready,
        -- Axi Stream I/f
        S_AXIS_TREADY     			=>  s_axis_tready, -- open,			  -- : out std_logic;
        S_AXIS_TDATA      			=>  s_axis_tdata,  -- (others => '0'),	  -- : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST      			=>  s_axis_tlast,  -- '0',				  -- : in  std_logic;
        S_AXIS_TVALID     			=>  s_axis_tvalid, -- '0',				  -- : in  std_logic;
        M_AXIS_TVALID     			=>  m_axis_tvalid, -- open, 			  -- : out std_logic;
        M_AXIS_TDATA      			=>  m_axis_tdata,  -- open, 			  -- : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST      			=>  m_axis_tlast,  -- open, 			  -- : out std_logic;
        M_AXIS_TREADY     			=>  M_Axis_TREADY_HPU
    );


-- s_axis_tready <= '1';  
 

i_resetn <= not i_reset; 

		-- Stimulus process
    
i_rst_in    <= '0', '1' after 150 ns;
i_en        <= '0', '1' after 300 ns;
i_FromSpeed <= 0.0, 2000.0 after 400 ns;

Reset_Proc : process
	begin
		i_reset <= '0';
		wait for 1 us;
		i_reset <= '1';
		wait for 1 us;
		wait until (HSSAER_ClkLS_p'event and HSSAER_ClkLS_p='1');
		i_reset <= '0';
		wait;
end process Reset_Proc;

Start_Proc : process
	begin
		i_start <= '0';
		wait for 10 us;
		wait until (HSSAER_ClkLS_p'event and HSSAER_ClkLS_p='1');
		i_start <= '1';
		wait;
end process Start_Proc;

Enable_AER_Proc : process
	begin
		AER_device_enable_L   <= '1';
		AER_device_enable_R   <= '1';
		AER_device_enable_Aux <= '1';
		AER_device_enable_Tx  <= '1';

		wait for 30 us;
		AER_device_enable_L   <= '1';
		AER_device_enable_R   <= '1';
		AER_device_enable_Aux <= '1';
		AER_device_enable_Tx  <= '1';
		wait;
end process Enable_AER_Proc;

Enable_SPNN_Proc : process
	begin
		SPNN_device_reset_L    <= '1';
		SPNN_device_reset_R    <= '1';
		SPNN_device_reset_Aux  <= '1';
		SPNN_device_reset_Tx   <= '1';
		
		SPNN_device_enable_L   <= '0';
    SPNN_device_enable_R   <= '0';
    SPNN_device_enable_Tx  <= '0';
    SPNN_device_enable_Aux <= '0';
 
		wait;
end process Enable_SPNN_Proc;

Axis_HPU_proc : process
	variable seed1, seed2 : positive;
    variable rand:real;
    variable int_rand: integer;

	begin
    l1: loop
        M_Axis_TREADY_HPU   <= '1';
        uniform(seed1, seed2, rand);
        int_rand:= 3*integer(trunc(rand*15.0));

    	if (int_rand>0) then
            for i in 0 to int_rand loop
                wait until (ClkAxis'event and ClkAxis='1');
            end loop;
        end if;
        wait until (ClkAxis'event and ClkAxis='1');

		M_Axis_TREADY_HPU   <= '0';
        uniform(seed1, seed2, rand);
        int_rand:= 4*integer(trunc(rand*15.0));

        if (int_rand>0) then
            for i in 0 to int_rand loop
                wait until (ClkAxis'event and ClkAxis='1');
            end loop;
        end if;
        wait until (ClkAxis'event and ClkAxis='1');
    end loop;
--		wait for 2000 us;
--		M_Axis_TREADY_HPU   <= '0';
		wait;
end process Axis_HPU_proc;

log_file_writing : process
   variable v_buf_out: line;
begin
    loop
        wait until ClkAxis'event and ClkAxis='1';
        if (M_Axis_TREADY_HPU='1' and m_axis_tvalid='1') then
            write (v_buf_out, now);write (v_buf_out, string'(", "));
            hwrite (v_buf_out, m_axis_tdata);
            if (m_axis_tlast='1') then
                write (v_buf_out, string'(" TLAST"));
            end if;
            writeline (logfile_ptr, v_buf_out); 
        end if;
    end loop;
end process log_file_writing;   



-- ---------------------------------------------
-- CLOCKs

Core_Clock_Proc : process
	begin
		ClkCore <= '0';
    wait for CLK_CORE_HALF_PERIOD_NS_c;
		loop
			ClkCore <= not ClkCore;
			wait for CLK_CORE_HALF_PERIOD_NS_c;
		end loop;
end process Core_Clock_Proc;

Axis_Clock_Proc : process
	begin
		ClkAxis <= '0';
    wait for CLK_AXIS_HALF_PERIOD_NS_c;
		loop
			ClkAxis <= not ClkAxis;
			wait for CLK_AXIS_HALF_PERIOD_NS_c;
		end loop;
end process Axis_Clock_Proc;

LS_Clock_Proc : process
	begin
		HSSAER_ClkLS_p <= '0';
		HSSAER_ClkLS_n <= '1';
--		wait until i_resetn='1';
    wait for CLK_HSSAER_LS_HALF_PERIOD_c;
		loop
			HSSAER_ClkLS_p <= not HSSAER_ClkLS_p;
			HSSAER_ClkLS_n <= not HSSAER_ClkLS_n;
			wait for CLK_HSSAER_LS_HALF_PERIOD_c;
		end loop;
end process LS_Clock_Proc;

HS_Clock_Proc : process
	begin
		HSSAER_ClkHS_p <= '0';
		HSSAER_ClkHS_n <= '1';
--		wait until i_resetn='1';
		loop
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for CLK_HSSAER_HS_HALF_PERIOD_1_NS_c;
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for CLK_HSSAER_HS_HALF_PERIOD_2_NS_c;
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for CLK_HSSAER_HS_HALF_PERIOD_3_NS_c;
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for CLK_HSSAER_HS_HALF_PERIOD_4_NS_c;
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for CLK_HSSAER_HS_HALF_PERIOD_5_NS_c;
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for CLK_HSSAER_HS_HALF_PERIOD_6_NS_c;			
		end loop;
end process HS_Clock_Proc;



END;
