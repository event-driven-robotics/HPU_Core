-- ********************************************
-- Version 4.0 Rev 0:  
-- - GTP Interface
-- - Timestamp removable from data streaming
-- - AXI Stream dedicate clock domain
-- - Compatibility extended to zynquplus
--   (M. Casti - IIT)
-- 
-- ********************************************
-- Version 3.6 Rev 0:  28th, January 2021
-- - Added interception ports (for algorythm insertion)
-- - Updated the list of tags for externale sensor (IMU and Cochlea) - see AERSensorsMap.xlxs
-- - GUI renewed
--   (M. Casti - IIT)
-- 
-- ********************************************
-- Version 3.5 Rev 20:  20th, May 2020
-- - Added Synchronization Fifos to make independent the differential clocks with the Core clock
--   (F. Diotalevi - IIT)
-- 
-- ********************************************
-- Version 3.4 Rev 15:  22th, January 2019
-- - Absolute Timing Feature for Transmission 
-- - Changed some feature about START/STOP Command
-- - Added SpiNNlink Control Register and Status Register
--   (M. Casti - IIT)
-- 
-- ********************************************  
-- Version 3.3 Rev 3:  30th, October 2018
-- - DMA register (DMA_REG) has bit 0 fixed to 0.
--   It can be written only with even values.
--   (F. Diotalevi - IIT)
-- 
-- ********************************************
-- Version 3.2 Rev 3 - October 24th 2018
-- - Splitted FlushFifos in FlushRXFifo and FlushTXFifos. 
-- - Modifications in axistream module to premature end a burst transfer. 
-- - Added register that counts data in AXI stream bus. 
-- - Modified reset value of RX PAER Configuration register (RX_PAER_CFNG_REG). 
-- - Enlarged DMA length field to 16 bits.
--   (F. Diotalevi - IIT)
-- 
-- ********************************************
-- Version 3.1 Rev 5 - August 24th 2018
-- - Added the START/STOP and Data Mask Feature to SpiNNlink
--   (M. Casti - IIT)
-- 
-- ********************************************
-- Version 3.0 - August 9th 2018
-- - Added the SpiNNlink interface capability
--   (M. Casti - IIT)
-- 
-- ********************************************
-- Version 2.1 - June 15th 2018
-- - Enlarged to 24 the SSAER data transfer. 
-- - Different header coding.
--   (F. Diotalevi - IIT)
-- 
-- ********************************************
-- Version 2.0 - November 15th 2017
-- - Bug fixed for the HSSAER Channel Enable. 
-- - Added AUX Threshold Error register and AUX Rx Counter registers. 
-- - Some Fixes in HDL code.
--   (F. Diotalevi - IIT)
-- 
-- ********************************************
-- Version 1.1 - June 14th 2017
-- - Modified the AXIstream module and added some debug ports. Added Reset_DMA_stream bit into CTRL_REG.
--   (F. Diotalevi - IIT)
-- 
-- ********************************************
-- Version 1.0 - September 19th 2016
-- - First Release (DRAFT)
--   (F. Diotalevi - IIT)
-- 
-- ********************************************


library ieee;
    use ieee.std_logic_1164.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;
    use HPU_lib.HPUComponents_pkg.all;
    
library neuserial_lib;
    use neuserial_lib.NSComponents_pkg.all;

entity HPUCore is
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

  attribute MAX_FANOUT  : string;
  attribute SIGIS       : string;
  
--  attribute MAX_FANOUT of S_AXI_ACLK     : signal is "10000";
  attribute MAX_FANOUT of S_AXI_ARESETN  : signal is "10000";
--  attribute SIGIS      of S_AXI_ACLK     : signal is "Clk";
  attribute SIGIS      of S_AXI_ARESETN  : signal is "Rst";
  attribute SIGIS      of Interrupt_o    : signal is "Interrupt";

end entity HPUCore;



--****************************
--   IMPLEMENTATION
--****************************



architecture str of HPUCore is

-- -----------------------------------------------------------------------------
-- Constants

constant C_GTP_RXUSRCLK2_PERIOD_NS : real  := real(C_GTP_RXUSRCLK2_PERIOD_PS) / 1000.0; -- RXUSRCLK2 Period       -- Converted here to real because IP Packager doesn't support real generics 
constant C_GTP_TXUSRCLK2_PERIOD_NS : real  := real(C_GTP_TXUSRCLK2_PERIOD_PS) / 1000.0; -- TXUSRCLK2 Period       -- Converted here to real because IP Packager doesn't support real generics    
constant C_SYSCLK_PERIOD_NS        : real  := real(C_SYSCLK_PERIOD_PS) / 1000.0;        -- System Clock period    -- Converted here to real because IP Packager doesn't support real generics 
    
-- -----------------------------------------------------------------------------
-- Signals
signal clear_n                   : std_logic;
signal arst_n_clk_core           : std_logic;
signal arst_n_clk_axis           : std_logic;

signal i_dma_rxDataBuffer        : std_logic_vector(63 downto 0);
signal i_dma_readRxBuffer        : std_logic;
signal i_dma_rxBufferEmpty       : std_logic;

signal i_dma_txDataBuffer        : std_logic_vector(31 downto 0);
signal i_dma_writeTxBuffer       : std_logic;
signal i_dma_txBufferFull        : std_logic;

signal i_fifoCoreDat             : std_logic_vector(63 downto 0);
signal i_fifoCoreRead            : std_logic;
signal i_fifoCoreEmpty           : std_logic;
signal i_fifoCoreAlmostEmpty     : std_logic;
signal i_fifoCoreBurstReady      : std_logic;
signal i_fifoCoreFull            : std_logic;
signal i_fifoCoreNumData         : std_logic_vector(10 downto 0);

signal i_coreFifoDat             : std_logic_vector(31 downto 0);
signal i_coreFifoWrite           : std_logic;
signal i_coreFifoFull            : std_logic;
signal i_coreFifoAlmostFull      : std_logic;
signal i_coreFifoEmpty           : std_logic;

signal i_uP_spinnlnk_dump_mode   : std_logic;
signal i_uP_spinnlnk_parity_err  : std_logic;
signal i_uP_spinnlnk_rx_err      : std_logic;

signal i_uP_DMAIsRunning         : std_logic;
signal i_uP_enableDmaIf          : std_logic;
signal i_uP_OnlyEvents           : std_logic;
signal i_uP_resetstream          : std_logic;
signal i_uP_dmaLength            : std_logic_vector(15 downto 0);
signal i_uP_DMA_test_mode        : std_logic;
signal i_uP_fulltimestamp        : std_logic;

signal i_uP_readRxBuffer         : std_logic;
signal i_uP_rxDataBuffer         : std_logic_vector(31 downto 0);
signal i_uP_rxTimeBuffer         : std_logic_vector(31 downto 0);
signal i_up_rxFifoThresholdNumData : std_logic_vector(10 downto 0);
signal i_uP_rxBufferReady        : std_logic;
signal i_uP_rxBufferEmpty        : std_logic;
signal i_uP_rxBufferAlmostEmpty  : std_logic;
signal i_uP_rxBufferFull         : std_logic;
signal i_rxBufferNotEmpty        : std_logic;
signal i_uP_rxFifoDataAF         : std_logic;

signal i_uP_writeTxBuffer        : std_logic;
signal i_uP_txDataBuffer         : std_logic_vector(31 downto 0);
signal i_uP_txBufferEmpty        : std_logic;
signal i_uP_txBufferAlmostFull   : std_logic;
signal i_uP_txBufferFull         : std_logic;

signal i_uP_cleanTimer           : std_logic;
signal i_uP_flushRXFifos           : std_logic;
signal i_uP_flushTXFifos           : std_logic;
signal i_uP_LRxFlushFifos        : std_logic;
signal i_uP_RRxFlushFifos        : std_logic;
signal i_uP_AuxRxPaerFlushFifos  : std_logic;
signal i_up_TlastCnt             : std_logic_vector(31 downto 0);
signal i_up_TDataCnt             : std_logic_vector(31 downto 0);
signal i_up_TlastTO              : std_logic_vector(31 downto 0);
signal i_up_TlastTOwritten       : std_logic;
signal i_up_LatTlast             : std_logic;

signal i_uP_RemoteLpbk           : std_logic;
signal i_uP_LocalNearLpbk        : std_logic;
signal i_uP_LocalFarLPaerLpbk    : std_logic;
signal i_uP_LocalFarRPaerLpbk    : std_logic;
signal i_uP_LocalFarAuxPaerLpbk  : std_logic;
signal i_uP_LocalFarLSaerLpbk    : std_logic;
signal i_uP_LocalFarRSaerLpbk    : std_logic;
signal i_uP_LocalFarAuxSaerLpbk  : std_logic;
signal i_uP_LocalFarSaerLpbkCfg  : t_XConCfg; 
signal i_uP_LocalFarSpnnLnkLpbkSel : std_logic_vector(1 downto 0);
signal i_uP_TxPaerEn             : std_logic;
signal i_uP_TxHSSaerEn           : std_logic;
signal i_up_TxGtpEn              : std_logic;
signal i_up_TxSpnnLnkEn          : std_logic;
signal i_uP_TxDestSwitch         : std_logic_vector(2 downto 0);
signal i_uP_TxPaerReqActLevel    : std_logic;
signal i_uP_TxPaerAckActLevel    : std_logic;
signal i_uP_TxSaerChanEn         : std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_TxTSMode             : std_logic_vector(1 downto 0);
signal i_uP_TxTSTimeoutSel       : std_logic_vector(3 downto 0);
signal i_uP_TxTSRetrigCmd        : std_logic;
signal i_uP_TxTSRearmCmd         : std_logic;
signal i_uP_TxTSRetrigStatus     : std_logic;
signal i_uP_TxTSTimeoutCounts    : std_logic;
signal i_uP_TxTSMaskSel          : std_logic_vector(1 downto 0);    
signal i_uP_LRxPaerEn            : std_logic;
signal i_uP_RRxPaerEn            : std_logic;
signal i_uP_AUXRxPaerEn          : std_logic;
signal i_uP_LRxHSSaerEn          : std_logic;
signal i_uP_RRxHSSaerEn          : std_logic;
signal i_uP_AUXRxHSSaerEn        : std_logic;
signal i_up_LRxGtpEn             : std_logic;
signal i_up_RRxGtpEn             : std_logic;
signal i_up_AUXRxGtpEn           : std_logic;
signal i_up_LRxSpnnLnkEn         : std_logic;
signal i_up_RRxSpnnLnkEn         : std_logic;
signal i_up_AUXRxSpnnLnkEn         : std_logic;
signal i_uP_LRxSaerChanEn        : std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_RRxSaerChanEn        : std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_AUXRxSaerChanEn      : std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_RxPaerReqActLevel    : std_logic;
signal i_uP_RxPaerAckActLevel    : std_logic;
signal i_uP_RxPaerIgnoreFifoFull : std_logic;
signal i_uP_RxPaerAckSetDelay    : std_logic_vector(7 downto 0);
signal i_uP_RxPaerSampleDelay    : std_logic_vector(7 downto 0);
signal i_uP_RxPaerAckRelDelay    : std_logic_vector(7 downto 0);

signal i_uP_wrapDetected         : std_logic;
signal i_uP_txSaerStat           : t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_LRXPaerFifoFull      : std_logic;
signal i_uP_RRXPaerFifoFull      : std_logic;
signal i_uP_AuxRxPaerFifoFull    : std_logic;
signal i_uP_LRxSaerStat          : t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_RRxSaerStat          : t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
signal i_uP_AUXRxSaerStat        : t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);

signal i_uP_TxSpnnlnkStat        : t_TxSpnnlnkStat;
signal i_uP_LRxSpnnlnkStat       : t_RxSpnnlnkStat;
signal i_uP_RRxSpnnlnkStat       : t_RxSpnnlnkStat;
signal i_uP_AuxRxSpnnlnkStat     : t_RxSpnnlnkStat;
signal i_uP_SpnnStartKey         : std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command 
signal i_uP_SpnnStopKey          : std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command  
signal i_uP_SpnnTxMask           : std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
signal i_uP_SpnnRxMask           : std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
signal i_uP_SpnnCtrl             : std_logic_vector(31 downto 0);  -- SpiNNaker Control Register
signal i_uP_SpnnStatus           : std_logic_vector(31 downto 0);  -- SpiNNaker Status Register 

signal i_rawInterrupt            : std_logic_vector(15 downto 0);
signal i_interrupt               : std_logic;

signal shreg_aux0                : std_logic_vector (3 downto 0);
signal shreg_aux1                : std_logic_vector (3 downto 0);
signal shreg_aux2                : std_logic_vector (3 downto 0);

-- Signals for TimeMachine
signal resync_clear_n            : std_logic;  
signal timing_CoreClk            : time_tick;	    

signal i_FifoCoreLastData        : std_logic;

signal rrx_hssaer                : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
signal lrx_hssaer                : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
signal arx_hssaer                : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
signal tx_hssaer                 : std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);

signal DefLocFarLpbk             : std_logic := '0';
signal DefLocNearLpbk            : std_logic := '0';
    
 --   for all : neuserial_axilite  use entity neuserial_lib.neuserial_axilite(rtl);
 --   for all : neuserial_axistream  use entity neuserial_lib.neuserial_axistream(rtl);
 --   for all : neuserial_core  use entity neuserial_lib.neuserial_core(str);


begin


    Interrupt_o <= i_interrupt;


    -- Debug assignments --
    -----------------------
    DBG_rawi <= i_rawInterrupt;


    -- Reset generation --
    ----------------------
    clear_n  <= S_AXI_ARESETN and CLEAR_N_i;

TIME_MACHINE_CORECLK_m : time_machine 
  generic map(
  
    CLK_PERIOD_NS_g           => C_SYSCLK_PERIOD_NS,    -- Main Clock period
    CLR_POLARITY_g            => "LOW",                 -- Active "HIGH" or "LOW"
    ARST_LONG_PERSISTANCE_g   => 16,                    -- Persistance of Power-On reset (clock pulses)
    ARST_ULONG_DURATION_MS_g  => 10,                    -- Duration of Ultrra-Long Reset (ms)
    HAS_POR_g                 => TRUE,                  -- If TRUE a Power On Reset is generated 
    SIM_TIME_COMPRESSION_g    => C_SIM_TIME_COMPRESSION -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    )
  port map(
    -- Clock in port
    CLK_i                   => CLK_CORE_i,      -- Input clock,
    MCM_LOCKED_i            => '1',             -- Clock locked flag
    CLR_i                   => clear_n,          -- Polarity controlled Asyncronous Clear input

    -- Reset output
    ARST_o                  => open,            -- Active high asyncronous assertion, syncronous deassertion Reset output
    ARST_N_o                => arst_n_clk_core, -- Active low asyncronous assertion, syncronous deassertion Reset output 
    ARST_LONG_o             => open,            -- Active high asyncronous assertion, syncronous deassertion Long Duration Reset output
    ARST_LONG_N_o           => open,            -- Active low asyncronous assertion, syncronous deassertion Long Duration Reset output 
    ARST_ULONG_o            => open,            -- Active high asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output
    ARST_ULONG_N_o          => open,            -- Active low asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output 

    -- Output ports for generated clock enables
    EN200NS_o               => timing_CoreClk.en200ns,  -- Clock enable every 200 ns
    EN1US_o                 => timing_CoreClk.en1us,	  -- Clock enable every 1 us
    EN10US_o                => timing_CoreClk.en10us,	  -- Clock enable every 10 us
    EN100US_o               => timing_CoreClk.en100us,	-- Clock enable every 100 us
    EN1MS_o                 => timing_CoreClk.en1ms,	  -- Clock enable every 1 ms
    EN10MS_o                => timing_CoreClk.en10ms,	  -- Clock enable every 10 ms
    EN100MS_o               => timing_CoreClk.en100ms,	-- Clock enable every 100 ms
    EN1S_o                  => timing_CoreClk.en1s 	    -- Clock enable every 1 s
    );

TIME_MACHINE_AXISCLK_m : time_machine 
  generic map(
  
    CLK_PERIOD_NS_g           => C_SYSCLK_PERIOD_NS,    -- Main Clock period
    CLR_POLARITY_g            => "LOW",                 -- Active "HIGH" or "LOW"
    ARST_LONG_PERSISTANCE_g   => 16,                    -- Persistance of Power-On reset (clock pulses)
    ARST_ULONG_DURATION_MS_g  => 10,                    -- Duration of Ultrra-Long Reset (ms)
    HAS_POR_g                 => TRUE,                  -- If TRUE a Power On Reset is generated 
    SIM_TIME_COMPRESSION_g    => C_SIM_TIME_COMPRESSION -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    )
  port map(
    -- Clock in port
    CLK_i                   => CLK_AXIS_i,      -- Input clock,
    MCM_LOCKED_i            => '1',             -- Clock locked flag
    CLR_i                   => clear_n,          -- Polarity controlled Asyncronous Clear input

    -- Reset output
    ARST_o                  => open,            -- Active high asyncronous assertion, syncronous deassertion Reset output
    ARST_N_o                => arst_n_clk_axis, -- Active low asyncronous assertion, syncronous deassertion Reset output 
    ARST_LONG_o             => open,            -- Active high asyncronous assertion, syncronous deassertion Long Duration Reset output
    ARST_LONG_N_o           => open,            -- Active low asyncronous assertion, syncronous deassertion Long Duration Reset output 
    ARST_ULONG_o            => open,            -- Active high asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output
    ARST_ULONG_N_o          => open,            -- Active low asyncronous assertion, syncronous deassertion Ultra-Long Duration Reset output 

    -- Output ports for generated clock enables
    EN200NS_o               => timing_CoreClk.en200ns,  -- Clock enable every 200 ns
    EN1US_o                 => timing_CoreClk.en1us,	  -- Clock enable every 1 us
    EN10US_o                => timing_CoreClk.en10us,	  -- Clock enable every 10 us
    EN100US_o               => timing_CoreClk.en100us,	-- Clock enable every 100 us
    EN1MS_o                 => timing_CoreClk.en1ms,	  -- Clock enable every 1 ms
    EN10MS_o                => timing_CoreClk.en10ms,	  -- Clock enable every 10 ms
    EN100MS_o               => timing_CoreClk.en100ms,	-- Clock enable every 100 ms
    EN1S_o                  => timing_CoreClk.en1s 	    -- Clock enable every 1 s
    );
    
------------------------------------------------------
-- NeuSerial AXI interfaces instantiation
------------------------------------------------------

i_rxBufferNotEmpty <= not(i_uP_rxBufferEmpty);

i_rawInterrupt <=  i_uP_rxFifoDataAF             &
                   i_uP_AuxRxPaerFifoFull        &
                   i_uP_RRXPaerFifoFull          &
                   i_uP_LRXPaerFifoFull          &
                   "00"                          &
                   i_rxBufferNotEmpty            &
                   i_uP_rxBufferReady            &
                   i_uP_wrapDetected             &
                   '0'                           &
                   i_uP_txBufferFull             &
                   i_uP_txBufferAlmostFull       &
                   i_uP_txBufferEmpty            &
                   i_uP_rxBufferFull             &
                   i_uP_rxBufferAlmostEmpty      &
                   i_uP_rxBufferEmpty            ;

DEFAULT_LOOPBACK_TRUE_gen: if C_HAS_DEFAULT_LOOPBACK = true generate
begin
    DefLocFarLpbk  <= DefLocFarLpbk_i;
    DefLocNearLpbk <= DefLocNearLpbk_i;
end generate;
DEFAULT_LOOPBACK_FALSE_gen: if C_HAS_DEFAULT_LOOPBACK = false generate
begin
    DefLocFarLpbk  <= '0';
    DefLocNearLpbk <= '0';
end generate;

AXILITE_m : axilite
  generic map (
    C_DATA_WIDTH                  => C_S_AXI_DATA_WIDTH,    -- HPU_libs only when  C_SLV_DWIDTH = 32 !!!
    C_ADDR_WIDTH                  => C_S_AXI_ADDR_WIDTH,
    C_SLV_DWIDTH                  => 32,                    -- HPU_libs only when  C_SLV_DWIDTH = 32 !!!
    C_RX_L_HAS_PAER               => C_RX_L_HAS_PAER,       -- boolean;
    C_RX_R_HAS_PAER               => C_RX_R_HAS_PAER,       -- boolean;
    C_RX_A_HAS_PAER               => C_RX_A_HAS_PAER,       -- boolean;
    C_RX_L_HAS_HSSAER             => C_RX_L_HAS_HSSAER,     -- boolean;
    C_RX_R_HAS_HSSAER             => C_RX_R_HAS_HSSAER,     -- boolean;
    C_RX_A_HAS_HSSAER             => C_RX_A_HAS_HSSAER,     -- boolean;
    C_RX_HSSAER_N_CHAN            => C_RX_HSSAER_N_CHAN,    -- natural range 1 to 4;
    C_RX_L_HAS_GTP                => C_RX_L_HAS_GTP,        -- boolean;
    C_RX_R_HAS_GTP                => C_RX_R_HAS_GTP,        -- boolean;
    C_RX_A_HAS_GTP                => C_RX_A_HAS_GTP,        -- boolean;
    C_RX_L_HAS_SPNNLNK            => C_RX_L_HAS_SPNNLNK,    -- boolean;
    C_RX_R_HAS_SPNNLNK            => C_RX_R_HAS_SPNNLNK,    -- boolean;
    C_RX_A_HAS_SPNNLNK            => C_RX_A_HAS_SPNNLNK,    -- boolean;
    --
    C_TX_HAS_PAER                 => C_TX_HAS_PAER,         -- boolean;
    C_TX_HAS_HSSAER               => C_TX_HAS_HSSAER,       -- boolean;
    C_TX_HSSAER_N_CHAN            => C_TX_HSSAER_N_CHAN,    -- natural range 1 to 4
    C_TX_HAS_GTP                  => C_TX_HAS_GTP,          -- boolean;
    C_TX_HAS_SPNNLNK              => C_TX_HAS_SPNNLNK       -- boolean;
    )
  port map (
    
    -- Interrupt
    -------------------------
    RawInterrupt_i                => i_rawInterrupt,                   -- in  std_logic_vector(15 downto 0);
    InterruptLine_o               => i_interrupt,                      -- out std_logic;
    
    -- RX Buffer Reg
    -------------------------
    ReadRxBuffer_o                => i_uP_readRxBuffer,                -- out std_logic;
    RxDataBuffer_i                => i_uP_rxDataBuffer,                -- in  std_logic_vector(31 downto 0);
    RxTimeBuffer_i                => i_uP_rxTimeBuffer,                -- in  std_logic_vector(31 downto 0);
    RxFifoThresholdNumData_o      => i_up_rxFifoThresholdNumData,      -- out std_logic_vector(10 downto 0);
    -- Tx Buffer Reg
    -------------------------
    WriteTxBuffer_o               => i_uP_writeTxBuffer,               -- out std_logic;
    TxDataBuffer_o                => i_uP_txDataBuffer,                -- out std_logic_vector(31 downto 0);
    
    
    -- Controls
    -------------------------
    DMA_is_running_i              => i_uP_DMAIsRunning,                -- in  std_logic;
    EnableDMAIf_o                 => i_uP_enableDmaIf,                 -- out std_logic;
    ResetStream_o                 => i_uP_resetstream,                 -- out std_logic;
    DmaLength_o                   => i_uP_dmaLength,                   -- out std_logic_vector(10 downto 0);
    DMA_test_mode_o               => i_uP_DMA_test_mode,               -- out std_logic;
    OnlyEvents_o                  => i_uP_OnlyEvents,                  -- out std_logic;
    fulltimestamp_o               => i_uP_fulltimestamp,               -- out std_logic;
    
    CleanTimer_o                  => i_uP_cleanTimer,              -- out std_logic;
    FlushRXFifos_o                => i_uP_flushRXFifos,              -- out std_logic;
    FlushTXFifos_o                => i_uP_flushTXFifos,            -- out std_logic;
    LatTlast_o                    => i_up_LatTlast,                -- out std_logic;
    TlastCnt_i                    => i_up_TlastCnt,                -- in  std_logic_vector(31 downto 0);
    TDataCnt_i                    => i_up_TDataCnt,                -- in  std_logic_vector(31 downto 0);
    TlastTO_o                     => i_up_TlastTO,                 -- out std_logic_vector(31 downto 0);
    TlastTOwritten_o              => i_up_TlastTOwritten,          -- out std_logic;
    --TxEnable_o                     => ,                             -- out std_logic;
    --TxPaerFlushFifos_o             => ,                             -- out std_logic;
    --LRxEnable_o                    => ,                             -- out std_logic;
    --RRxEnable_o                    => ,                             -- out std_logic;
    LRxPaerFlushFifos_o           => i_uP_LRxFlushFifos,           -- out std_logic;
    RRxPaerFlushFifos_o           => i_uP_RRxFlushFifos,           -- out std_logic;
    AuxRxPaerFlushFifos_o         => i_uP_AuxRxPaerFlushFifos,     -- out std_logic;
    
    -- Configurations
    -------------------------
    DefLocFarLpbk_i               => DefLocFarLpbk,                -- in  std_logic;
    DefLocNearLpbk_i              => DefLocNearLpbk,               -- in  std_logic;
    --EnableLoopBack_o               => i_uP_enableLoopBack,        -- out std_logic;
    RemoteLoopback_o              => i_uP_RemoteLpbk,              -- out std_logic;
    LocNearLoopback_o             => i_uP_LocalNearLpbk,           -- out std_logic;
    LocFarLPaerLoopback_o         => i_uP_LocalFarLPaerLpbk,       -- out std_logic;
    LocFarRPaerLoopback_o         => i_uP_LocalFarRPaerLpbk,       -- out std_logic;
    LocFarAuxPaerLoopback_o       => i_uP_LocalFarAuxPaerLpbk,     -- out std_logic;
    LocFarLSaerLoopback_o         => i_uP_LocalFarLSaerLpbk,       -- out std_logic;
    LocFarRSaerLoopback_o         => i_uP_LocalFarRSaerLpbk,       -- out std_logic;
    LocFarAuxSaerLoopback_o       => i_uP_LocalFarAuxSaerLpbk,     -- out std_logic;
    LocFarSaerLpbkCfg_o           => i_uP_LocalFarSaerLpbkCfg,     -- out t_XConCfg;
    LocFarSpnnLnkLoopbackSel_o    => i_uP_LocalFarSpnnLnkLpbkSel,  -- out  std_logic_vector(1 downto 0);
    
    --EnableIp_o                     => i_uP_enableIp,                -- out std_logic;
    
    TxPaerEn_o                    => i_uP_TxPaerEn,                -- out std_logic;
    TxHSSaerEn_o                  => i_uP_TxHSSaerEn,              -- out std_logic;
    TxGtpEn_o                     => i_up_TxGtpEn,                 -- out std_logic;
    TxSpnnLnkEn_o                 => i_uP_TxSpnnLnkEn,             -- out std_logic;
    TxDestSwitch_o                => i_uP_TxDestSwitch,            -- out std_logic_vector(2 downto 0);
    --TxPaerIgnoreFifoFull_o         => ,                             -- out std_logic;
    TxPaerReqActLevel_o           => i_uP_TxPaerReqActLevel,       -- out std_logic;
    TxPaerAckActLevel_o           => i_uP_TxPaerAckActLevel,       -- out std_logic;
    TxSaerChanEn_o                => i_uP_TxSaerChanEn,            -- out std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
    
    TxTSMode_o                    => i_uP_TxTSMode,                -- out std_logic_vector(1 downto 0);
    TxTSTimeoutSel_o              => i_uP_TxTSTimeoutSel,          -- out std_logic_vector(3 downto 0);
    TxTSRetrigCmd_o               => i_uP_TxTSRetrigCmd,           -- out std_logic;
    TxTSRearmCmd_o                => i_uP_TxTSRearmCmd,            -- out std_logic;
    TxTSRetrigStatus_i            => i_uP_TxTSRetrigStatus,        -- in  std_logic;
    TxTSTimeoutCounts_i           => i_uP_TxTSTimeoutCounts,       -- in  std_logic;
    TxTSMaskSel_o                 => i_uP_TxTSMaskSel,             -- out std_logic_vector(1 downto 0);
    
    LRxPaerEn_o                   => i_uP_LRxPaerEn,               -- out std_logic;
    RRxPaerEn_o                   => i_uP_RRxPaerEn,               -- out std_logic;
    AUXRxPaerEn_o                 => i_uP_AuxRxPaerEn,             -- out std_logic;
    LRxHSSaerEn_o                 => i_uP_LRxHSSaerEn,             -- out std_logic;
    RRxHSSaerEn_o                 => i_uP_RRxHSSaerEn,             -- out std_logic;
    AUXRxHSSaerEn_o               => i_uP_AuxRxHSSaerEn,           -- out std_logic;
    LRxGtpEn_o                    => i_up_LRxGtpEn,                -- out std_logic;
    RRxGtpEn_o                    => i_up_RRxGtpEn,                -- out std_logic;
    AUXRxGtpEn_o                  => i_up_AUXRxGtpEn,              -- out std_logic;
    LRxSpnnLnkEn_o                => i_uP_LRxSpnnLnkEn,            -- out std_logic
    RRxSpnnLnkEn_o                => i_uP_RRxSpnnLnkEn,            -- out std_logic;
    AUXRxSpnnLnkEn_o              => i_uP_AUXRxSpnnLnkEn,          -- out std_logic;
                                                                                                 
    LRxSaerChanEn_o               => i_uP_LRxSaerChanEn,           -- out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerChanEn_o               => i_uP_RRxSaerChanEn,           -- out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerChanEn_o             => i_uP_AUXRxSaerChanEn,         -- out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RxPaerReqActLevel_o           => i_uP_RxPaerReqActLevel,       -- out std_logic;
    RxPaerAckActLevel_o           => i_uP_RxPaerAckActLevel,       -- out std_logic;
    RxPaerIgnoreFifoFull_o        => i_uP_RxPaerIgnoreFifoFull,    -- out std_logic;
    RxPaerAckSetDelay_o           => i_uP_RxPaerAckSetDelay,       -- out std_logic_vector(7 downto 0);
    RxPaerSampleDelay_o           => i_uP_RxPaerSampleDelay,       -- out std_logic_vector(7 downto 0);
    RxPaerAckRelDelay_o           => i_uP_RxPaerAckRelDelay,       -- out std_logic_vector(7 downto 0);
    
    -- Status
    -------------------------
    WrapDetected_i                => i_uP_wrapDetected,            -- in  std_logic;
    
    TxSaerStat_i                  => i_uP_txSaerStat,              -- in  t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
    LRxSaerStat_i                 => i_uP_LRxSaerStat,             -- in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerStat_i                 => i_uP_RRxSaerStat,             -- in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerStat_i               => i_uP_AUXRxSaerStat,           -- in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    TxSpnnlnkStat_i               => i_uP_TxSpnnlnkStat,           -- in  t_TxSpnnlnkStat;
    LRxSpnnlnkStat_i              => i_uP_LRxSpnnlnkStat,          -- in  t_RxSpnnlnkStat;
    RRxSpnnlnkStat_i              => i_uP_RRxSpnnlnkStat,          -- in  t_RxSpnnlnkStat;
    AuxRxSpnnlnkStat_i            => i_uP_AuxRxSpnnlnkStat,        -- in  t_RxSpnnlnkStat;
        
    -- Spinnaker                     
    -------------------------                               
    Spnn_start_key_o              => i_uP_SpnnStartKey,            -- out std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command 
    Spnn_stop_key_o               => i_uP_SpnnStopKey,             -- out std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command  
    Spnn_tx_mask_o                => i_uP_SpnnTxMask,              -- out std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    Spnn_rx_mask_o                => i_uP_SpnnRxMask,              -- out std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
    Spnn_ctrl_o                   => i_uP_SpnnCtrl,                -- out std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
    Spnn_status_i                 => i_uP_SpnnStatus,              -- in  std_logic_vector(31 downto 0);  -- SpiNNaker Status Register  
    
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    -- Axi lite I-f
    S_AXI_ACLK                    => CLK_CORE_i,                       -- in  std_logic;
    S_AXI_ARESETN                 => S_AXI_ARESETN,                    -- in  std_logic;
    S_AXI_AWADDR                  => S_AXI_AWADDR,                     -- in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID                 => S_AXI_AWVALID,                    -- in  std_logic;
    S_AXI_WDATA                   => S_AXI_WDATA,                      -- in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB                   => S_AXI_WSTRB,                      -- in  std_logic_vector(3 downto 0);
    S_AXI_WVALID                  => S_AXI_WVALID,                     -- in  std_logic;
    S_AXI_BREADY                  => S_AXI_BREADY,                     -- in  std_logic;
    S_AXI_ARADDR                  => S_AXI_ARADDR,                     -- in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID                 => S_AXI_ARVALID,                    -- in  std_logic;
    S_AXI_RREADY                  => S_AXI_RREADY,                     -- in  std_logic;
    S_AXI_ARREADY                 => S_AXI_ARREADY,                    -- out std_logic;
    S_AXI_RDATA                   => S_AXI_RDATA,                      -- out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP                   => S_AXI_RRESP,                      -- out std_logic_vector(1 downto 0);
    S_AXI_RVALID                  => S_AXI_RVALID,                     -- out std_logic;
    S_AXI_WREADY                  => S_AXI_WREADY,                     -- out std_logic;
    S_AXI_BRESP                   => S_AXI_BRESP,                      -- out std_logic_vector(1 downto 0);
    S_AXI_BVALID                  => S_AXI_BVALID,                     -- out std_logic;
    S_AXI_AWREADY                 => S_AXI_AWREADY                     -- out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
    );

AXISTREAM_m : axistream
  port map (
    Clk                            => CLK_AXIS_i,                       -- in  std_logic;
    nRst                           => arst_n_clk_core,                  -- in  std_logic;
    --
    DMA_test_mode_i                => i_uP_DMA_test_mode,               -- in  std_logic;
    EnableAxistreamIf_i            => i_uP_enableDmaIf,                 -- in  std_logic;
    OnlyEvents_i                   => i_uP_OnlyEvents,                  -- in  std_logic;
    DMA_is_running_o               => i_uP_DMAIsRunning,                -- out std_logic;
    DmaLength_i                    => i_uP_dmaLength,                   -- in  std_logic_vector(15 downto 0);
    ResetStream_i                  => i_uP_resetstream,                 -- in  std_logic;
    LatTlat_i                      => i_up_LatTlast,                    -- in  std_logic;
    TlastCnt_o                     => i_up_TlastCnt,                    -- out std_logic_vector(31 downto 0);
    TlastTO_i                      => i_up_TlastTO,                     -- in  std_logic_vector(31 downto 0);
    TlastTOwritten_i               => i_up_TlastTOwritten,              -- in  std_logic;
    TDataCnt_o                     => i_up_TDataCnt,                    -- out std_logic_vector(31 downto 0);
    -- From Fifo to core/dma
    FifoCoreDat_i                  => i_dma_rxDataBuffer,               -- in  std_logic_vector(63 downto 0);
    FifoCoreRead_o                 => i_dma_readRxBuffer,               -- out std_logic;
    FifoCoreEmpty_i                => i_dma_rxBufferEmpty,              -- in  std_logic;
    FifoCoreLastData_i             => i_FifoCoreLastData,               -- in  std_logic;
    -- From core/dma to Fifo
    CoreFifoDat_o                  => i_dma_txDataBuffer,               -- out std_logic_vector(31 downto 0);
    CoreFifoWrite_o                => i_dma_writeTxBuffer,              -- out std_logic;
    CoreFifoFull_i                 => i_dma_txBufferFull,               -- in  std_logic;
    -- Axi Stream I/f
    S_AXIS_TREADY                  => S_AXIS_TREADY,                    -- out std_logic;
    S_AXIS_TDATA                   => S_AXIS_TDATA,                     -- in  std_logic_vector(31 downto 0);
    S_AXIS_TLAST                   => S_AXIS_TLAST,                     -- in  std_logic;
    S_AXIS_TVALID                  => S_AXIS_TVALID,                    -- in  std_logic;
    M_AXIS_TVALID                  => M_AXIS_TVALID,                    -- out std_logic;
    M_AXIS_TDATA                   => M_AXIS_TDATA,                     -- out std_logic_vector(31 downto 0);
    M_AXIS_TLAST                   => M_AXIS_TLAST,                     -- out std_logic;
    M_AXIS_TREADY                  => M_AXIS_TREADY                      -- in  std_logic
    );

-- i_FifoCoreLastData <= '1' when i_fifoCoreNumData="00000000001" else '0';

-- Muxing AXI-Lite and AXI-Stream Fifo interfaces --
----------------------------------------------------

i_uP_rxFifoDataAF                <= '1' when (i_fifoCoreNumData >= i_up_rxFifoThresholdNumData) else '0';
i_uP_rxDataBuffer                <= i_fifoCoreDat(31 downto 0);
i_uP_rxTimeBuffer                <= i_fifoCoreDat(63 downto 32);
i_uP_rxBufferReady               <= i_fifoCoreBurstReady;
i_uP_rxBufferEmpty               <= i_fifoCoreEmpty;
i_uP_rxBufferAlmostEmpty         <= i_fifoCoreAlmostEmpty;
i_uP_rxBufferFull                <= i_fifoCoreFull;

i_dma_rxDataBuffer               <= i_fifoCoreDat;
i_dma_rxBufferEmpty              <= i_fifoCoreEmpty;

i_fifoCoreRead                   <= i_dma_readRxBuffer  when (i_uP_DMAIsRunning='1') else
                                    i_uP_readRxBuffer;


i_uP_txBufferEmpty               <= i_coreFifoEmpty;
i_uP_txBufferAlmostFull          <= i_coreFifoAlmostFull;
i_uP_txBufferFull                <= i_coreFifoFull;

i_dma_txBufferFull               <= i_coreFifoFull;

i_coreFifoDat                    <= i_dma_txDataBuffer  when (i_uP_DMAIsRunning='1') else
                                    i_uP_txDataBuffer;
i_coreFifoWrite                  <= i_dma_writeTxBuffer when (i_uP_DMAIsRunning='1') else
                                    i_uP_writeTxBuffer;



-- -----------------------------------------------------------------------------
-- NeuSerial core instantiation
-- -----------------------------------------------------------------------------

-- Explixciting HSSAER bus tap connection (due to different definitions TO, DOWNTO)

rx_hssaer_bus : for i in 0 to C_RX_HSSAER_N_CHAN-1 generate
  rrx_hssaer(i)    <= RRx_HSSAER_i(i);
  lrx_hssaer(i)    <= LRx_HSSAER_i(i);
  arx_hssaer(i)    <= ARx_HSSAER_i(i);
end generate;

tx_hssaer_bus : for i in 0 to C_TX_HSSAER_N_CHAN-1 generate
  Tx_HSSAER_o(i)   <= tx_hssaer(i);    
end generate;

NEUSERIAL_CORE_m : neuserial_core
  generic map (
    -- -----------------------    
    -- GENERIC
    C_FAMILY                 => C_FAMILY,
    -- -----------------------    
    -- PAER        
    C_RX_L_HAS_PAER           => C_RX_L_HAS_PAER,           -- : boolean                       := true;
    C_RX_R_HAS_PAER           => C_RX_R_HAS_PAER,           -- : boolean                       := true;
    C_RX_A_HAS_PAER           => C_RX_A_HAS_PAER,           -- : boolean                       := true;
    C_RX_PAER_L_SENS_ID       => C_RX_PAER_L_SENS_ID,       -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_PAER_R_SENS_ID       => C_RX_PAER_R_SENS_ID,       -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_PAER_A_SENS_ID       => C_RX_PAER_A_SENS_ID,       -- : std_logic_vector(2 downto 0)  := "001";
    C_TX_HAS_PAER             => C_TX_HAS_PAER,             -- : boolean                       := true;
    C_PAER_DSIZE              => C_PAER_DSIZE,              -- : natural range 1 to 29         := 24;
    -- -----------------------       
    -- HSSAER                 
    C_RX_L_HAS_HSSAER         => C_RX_L_HAS_HSSAER,         -- : boolean                       := true;
    C_RX_R_HAS_HSSAER         => C_RX_R_HAS_HSSAER,         -- : boolean                       := true;
    C_RX_A_HAS_HSSAER         => C_RX_A_HAS_HSSAER,         -- : boolean                       := true;
    C_RX_HSSAER_N_CHAN        => C_RX_HSSAER_N_CHAN,        -- : natural range 1 to 4          := 3;
    C_RX_SAER0_L_SENS_ID      => C_RX_SAER0_L_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER1_L_SENS_ID      => C_RX_SAER1_L_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER2_L_SENS_ID      => C_RX_SAER2_L_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER3_L_SENS_ID      => C_RX_SAER3_L_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";        
    C_RX_SAER0_R_SENS_ID      => C_RX_SAER0_R_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER1_R_SENS_ID      => C_RX_SAER1_R_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER2_R_SENS_ID      => C_RX_SAER2_R_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";
    C_RX_SAER3_R_SENS_ID      => C_RX_SAER3_R_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "000";        
    C_RX_SAER0_A_SENS_ID      => C_RX_SAER0_A_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "001";
    C_RX_SAER1_A_SENS_ID      => C_RX_SAER1_A_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "001";
    C_RX_SAER2_A_SENS_ID      => C_RX_SAER2_A_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "001";
    C_RX_SAER3_A_SENS_ID      => C_RX_SAER3_A_SENS_ID,      -- : std_logic_vector(2 downto 0)  := "001";
    C_TX_HAS_HSSAER           => C_TX_HAS_HSSAER,           -- : boolean                       := true;
    C_TX_HSSAER_N_CHAN        => C_TX_HSSAER_N_CHAN,        -- : natural range 1 to 4          := 3;
    -- -----------------------        
    -- GTP                    
    C_RX_L_HAS_GTP            => C_RX_L_HAS_GTP,            -- boolean;
    C_RX_R_HAS_GTP            => C_RX_R_HAS_GTP,            -- boolean;
    C_RX_A_HAS_GTP            => C_RX_A_HAS_GTP,            -- boolean;
    C_GTP_RXUSRCLK2_PERIOD_NS => C_GTP_RXUSRCLK2_PERIOD_NS, -- : real                          := 6.4;        
    C_TX_HAS_GTP              => C_TX_HAS_GTP,              -- : boolean                       := true;
    C_GTP_TXUSRCLK2_PERIOD_NS => C_GTP_TXUSRCLK2_PERIOD_NS, -- : real                          := 6.4;  
    C_GTP_DSIZE               => C_GTP_DSIZE,               -- : positive                      := 16;
    -- -----------------------                
    -- SPINNLINK              
    C_RX_L_HAS_SPNNLNK        => C_RX_L_HAS_SPNNLNK,          -- : boolean                       := true;
    C_RX_R_HAS_SPNNLNK        => C_RX_R_HAS_SPNNLNK,          -- : boolean                       := true;
    C_RX_A_HAS_SPNNLNK        => C_RX_A_HAS_SPNNLNK,          -- : boolean                       := true;
    C_TX_HAS_SPNNLNK          => C_TX_HAS_SPNNLNK,            -- : boolean                       := true;
    C_PSPNNLNK_WIDTH      	  => C_PSPNNLNK_WIDTH,            -- : natural range 1 to 32         := 32;
    -- ----------------------- 
    -- INTERCEPTION            
    C_RX_L_INTERCEPTION       => C_RX_L_INTERCEPTION,         -- : boolean                       := false;
    C_RX_R_INTERCEPTION       => C_RX_R_INTERCEPTION,         -- : boolean                       := false;
    C_RX_A_INTERCEPTION       => C_RX_A_INTERCEPTION,         -- : boolean                       := false;
    -- -----------------------
    -- SIMULATION
    C_SIM_TIME_COMPRESSION    => C_SIM_TIME_COMPRESSION     -- : boolean                       := false;   
    )
  port map (
    --
    -- Clocks & Reset
    ---------------------
    -- System Clock domain
    CoreClk_i                   => CLK_CORE_i,                   -- in  std_logic;
    nRst_CoreClk_i              => arst_n_clk_core,              -- in  std_logic;
    Timing_i                    => timing_CoreClk,               -- in  time_tick;
    -- DMA Clock Domain
    AxisClk_i                   => CLK_AXIS_i,                   --     in  std_logic;
    nRst_AxisClk_i              => arst_n_clk_axis,               --     in  std_logic;

    -- HSSAER Clocks domain
    Clk_hs_p                    => CLK_HSSAER_HS_P_i,               -- in  std_logic;
    Clk_hs_n                    => CLK_HSSAER_HS_N_i,               -- in  std_logic;
    Clk_ls_p                    => CLK_HSSAER_LS_P_i,               -- in  std_logic;
    Clk_ls_n                    => CLK_HSSAER_LS_N_i,               -- in  std_logic;
    
    --
    -- TX Interface
    ---------------------
    -- Parallel AER
     Tx_PAER_Addr_o             => Tx_PAER_Addr_o,               -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
     Tx_PAER_Req_o              => Tx_PAER_Req_o,                -- out std_logic;
     Tx_PAER_Ack_i              => Tx_PAER_Ack_i,                -- in  std_logic;
     -- HSSAER channels         
     Tx_HSSAER_o                => tx_hssaer,                    -- out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
     -- GTP lines               
     Tx_TxGtpMsg_i              => Tx_TxGtpMsg_i,
     Tx_TxGtpMsgSrcRdy_i        => Tx_TxGtpMsgSrcRdy_i,
     Tx_TxGtpMsgDstRdy_o        => Tx_TxGtpMsgDstRdy_o,
     Tx_TxGtpAlignRequest_i     => Tx_TxGtpAlignRequest_i,
     Tx_TxGtpAlignFlag_o        => Tx_TxGtpAlignFlag_o,
     Tx_GTP_TxUsrClk2_i         => Tx_GTP_TxUsrClk2_i, 
     Tx_GTP_SoftResetTx_o       => Tx_GTP_SoftResetTx_o,
     Tx_GTP_DataValid_o         => Tx_GTP_DataValid_o,
     Tx_GTP_Txuserrdy_o         => Tx_GTP_Txuserrdy_o,
     Tx_GTP_Txdata_o            => Tx_GTP_Txdata_o,
     Tx_GTP_Txcharisk_o         => Tx_GTP_Txcharisk_o,
     Tx_GTP_PllLock_i           => Tx_GTP_PllLock_i,
     Tx_GTP_PllRefclklost_i     => Tx_GTP_PllRefclklost_i, 
     -- SpiNNaker Interface     
     Tx_SPNN_Data_o             => Tx_SPNN_Data_o,
     Tx_SPNN_Ack_i              => Tx_SPNN_Ack_i,
    
    --                      
    -- RX Left Interface    
    ---------------------   
    -- Parallel AER         
    LRx_PAER_Addr_i             => LRx_PAER_Addr_i,              
    LRx_PAER_Req_i              => LRx_PAER_Req_i,               
    LRx_PAER_Ack_o              => LRx_PAER_Ack_o,               
    -- HSSAER channels          
    LRx_HSSAER_i                => lrx_hssaer,                   
    -- GTP lines                    -- GTP interface          
    LRx_RxGtpMsg_o              => LRx_RxGtpMsg_o,               
    LRx_RxGtpMsgSrcRdy_o        => LRx_RxGtpMsgSrcRdy_o,         
    LRx_RxGtpMsgDstRdy_i        => LRx_RxGtpMsgDstRdy_i,         
    LRx_RxGtpAlignRequest_o     => LRx_RxGtpAlignRequest_o,      
    LRx_GTP_RxUsrClk2_i         => LRx_GTP_RxUsrClk2_i,          
    LRx_GTP_SoftResetRx_o       => LRx_GTP_SoftResetRx_o,            
    LRx_GTP_DataValid_o         => LRx_GTP_DataValid_o,          
    LRx_GTP_Rxuserrdy_o         => LRx_GTP_Rxuserrdy_o,          
    LRx_GTP_Rxdata_i            => LRx_GTP_Rxdata_i,                
    LRx_GTP_Rxchariscomma_i     => LRx_GTP_Rxchariscomma_i,          
    LRx_GTP_Rxcharisk_i         => LRx_GTP_Rxcharisk_i,              
    LRx_GTP_Rxdisperr_i         => LRx_GTP_Rxdisperr_i,              
    LRx_GTP_Rxnotintable_i      => LRx_GTP_Rxnotintable_i,               
    LRx_GTP_Rxbyteisaligned_i   => LRx_GTP_Rxbyteisaligned_i,        
    LRx_GTP_Rxbyterealign_i     => LRx_GTP_Rxbyterealign_i,      
    LRx_GTP_PllLock_i           => LRx_GTP_PllLock_i,                
    LRx_GTP_PllRefclklost_i     => LRx_GTP_PllRefclklost_i,      
    -- SpiNNaker Interface      
    LRx_SPNN_Data_i             => LRx_SPNN_Data_i,
    LRx_SPNN_Ack_o              => LRx_SPNN_Ack_o,   
     
    --
    -- RX Right DATA PATH
    ---------------------   
    -- Parallel AER         
    RRx_PAER_Addr_i             => RRx_PAER_Addr_i,              
    RRx_PAER_Req_i              => RRx_PAER_Req_i,               
    RRx_PAER_Ack_o              => RRx_PAER_Ack_o,               
    -- HSSAER channels          
    RRx_HSSAER_i                => rrx_hssaer,                   
    -- GTP lines                    -- GTP interface          
    RRx_RxGtpMsg_o              => RRx_RxGtpMsg_o,               
    RRx_RxGtpMsgSrcRdy_o        => RRx_RxGtpMsgSrcRdy_o,         
    RRx_RxGtpMsgDstRdy_i        => RRx_RxGtpMsgDstRdy_i,         
    RRx_RxGtpAlignRequest_o     => RRx_RxGtpAlignRequest_o,      
    RRx_GTP_RxUsrClk2_i         => RRx_GTP_RxUsrClk2_i,          
    RRx_GTP_SoftResetRx_o       => RRx_GTP_SoftResetRx_o,            
    RRx_GTP_DataValid_o         => RRx_GTP_DataValid_o,          
    RRx_GTP_Rxuserrdy_o         => RRx_GTP_Rxuserrdy_o,          
    RRx_GTP_Rxdata_i            => RRx_GTP_Rxdata_i,                
    RRx_GTP_Rxchariscomma_i     => RRx_GTP_Rxchariscomma_i,          
    RRx_GTP_Rxcharisk_i         => RRx_GTP_Rxcharisk_i,              
    RRx_GTP_Rxdisperr_i         => RRx_GTP_Rxdisperr_i,              
    RRx_GTP_Rxnotintable_i      => RRx_GTP_Rxnotintable_i,               
    RRx_GTP_Rxbyteisaligned_i   => RRx_GTP_Rxbyteisaligned_i,        
    RRx_GTP_Rxbyterealign_i     => RRx_GTP_Rxbyterealign_i,      
    RRx_GTP_PllLock_i           => RRx_GTP_PllLock_i,                
    RRx_GTP_PllRefclklost_i     => RRx_GTP_PllRefclklost_i,      
    -- SpiNNaker Interface      
    RRx_SPNN_Data_i             => RRx_SPNN_Data_i,
    RRx_SPNN_Ack_o              => RRx_SPNN_Ack_o,  
               
    --
    -- Aux DATA PATH
    ---------------------   
    -- Parallel AER         
    AuxRx_PAER_Addr_i           => ARx_PAER_Addr_i,              
    AuxRx_PAER_Req_i            => ARx_PAER_Req_i,               
    AuxRx_PAER_Ack_o            => ARx_PAER_Ack_o,               
    -- HSSAER channels          
    AuxRx_HSSAER_i              => arx_hssaer,                   
    -- GTP lines                  -- GTP interface          
    AuxRx_RxGtpMsg_o            => ARx_RxGtpMsg_o,               
    AuxRx_RxGtpMsgSrcRdy_o      => ARx_RxGtpMsgSrcRdy_o,         
    AuxRx_RxGtpMsgDstRdy_i      => ARx_RxGtpMsgDstRdy_i,         
    AuxRx_RxGtpAlignRequest_o   => ARx_RxGtpAlignRequest_o,      
    AuxRx_GTP_RxUsrClk2_i       => ARx_GTP_RxUsrClk2_i,          
    AuxRx_GTP_SoftResetRx_o     => ARx_GTP_SoftResetRx_o,            
    AuxRx_GTP_DataValid_o       => ARx_GTP_DataValid_o,          
    AuxRx_GTP_Rxuserrdy_o       => ARx_GTP_Rxuserrdy_o,          
    AuxRx_GTP_Rxdata_i          => ARx_GTP_Rxdata_i,                
    AuxRx_GTP_Rxchariscomma_i   => ARx_GTP_Rxchariscomma_i,          
    AuxRx_GTP_Rxcharisk_i       => ARx_GTP_Rxcharisk_i,              
    AuxRx_GTP_Rxdisperr_i       => ARx_GTP_Rxdisperr_i,              
    AuxRx_GTP_Rxnotintable_i    => ARx_GTP_Rxnotintable_i,               
    AuxRx_GTP_Rxbyteisaligned_i => ARx_GTP_Rxbyteisaligned_i,        
    AuxRx_GTP_Rxbyterealign_i   => ARx_GTP_Rxbyterealign_i,      
    AuxRx_GTP_PllLock_i         => ARx_GTP_PllLock_i,                
    AuxRx_GTP_PllRefclklost_i   => ARx_GTP_PllRefclklost_i,      
    -- SpiNNaker Interface      
    AuxRx_SPNN_Data_i           => ARx_SPNN_Data_i,
    AuxRx_SPNN_Ack_o            => ARx_SPNN_Ack_o, 

    
    --
    -- FIFOs interfaces
    ---------------------
    FifoCoreDat_o           => i_fifoCoreDat,                -- out std_logic_vector(63 downto 0);
    FifoCoreRead_i          => i_fifoCoreRead,               -- in  std_logic;
    FifoCoreEmpty_o         => i_fifoCoreEmpty,              -- out std_logic;
    FifoCoreAlmostEmpty_o   => i_fifoCoreAlmostEmpty,        -- out std_logic;
    FifoCoreLastData_o      => i_fifoCoreLastData, 
    FifoCoreFull_o          => i_fifoCoreFull,               -- out std_logic;
    FifoCoreNumData_o       => i_fifoCoreNumData,            -- out std_logic_vector(10 downto 0);
    --
    CoreFifoDat_i           => i_coreFifoDat,                -- in  std_logic_vector(31 downto 0);
    CoreFifoWrite_i         => i_coreFifoWrite,              -- in  std_logic;
    CoreFifoFull_o          => i_coreFifoFull,               -- out std_logic;
    CoreFifoAlmostFull_o    => i_coreFifoAlmostFull,         -- out std_logic;
    CoreFifoEmpty_o         => i_coreFifoEmpty,              -- out std_logic;
    
    -----------------------------------------------------------------------
    -- uController Interface
    ---------------------
    -- Control
    CleanTimer_i            => i_uP_cleanTimer,              -- in  std_logic;
    FlushRXFifos_i          => i_uP_flushRXFifos,              -- in  std_logic;
    FlushTXFifos_i          => i_uP_flushTXFifos,              -- in  std_logic;
    --TxEnable_i              => ,                             -- in  std_logic;
    --TxPaerFlushFifos_i      => ,                             -- in  std_logic;
    --LRxEnable_i             => ,                             -- in  std_logic;
    --RRxEnable_i             => ,                             -- in  std_logic;
    LRxPaerFlushFifos_i     => i_uP_LRxFlushFifos,           -- in  std_logic;
    RRxPaerFlushFifos_i     => i_uP_RRxFlushFifos,           -- in  std_logic;
    AuxRxPaerFlushFifos_i   => i_uP_AuxRxPaerFlushFifos,      -- in  std_logic;
    FullTimestamp_i         => i_uP_fulltimestamp,           -- in  std_logic;
    
    
    -- Configurations
    DmaLength_i             => i_uP_dmaLength,               -- in  std_logic_vector(15 downto 0);
    OnlyEvents_i            => i_uP_OnlyEvents,              -- in  std_logic;
    RemoteLoopback_i        => i_uP_RemoteLpbk,              -- in  std_logic;
    LocNearLoopback_i       => i_uP_LocalNearLpbk,           -- in  std_logic;
    LocFarLPaerLoopback_i   => i_uP_LocalFarLPaerLpbk,       -- in  std_logic;
    LocFarRPaerLoopback_i   => i_uP_LocalFarRPaerLpbk,       -- in  std_logic;
    LocFarAuxPaerLoopback_i => i_uP_LocalFarAuxPaerLpbk,     -- in  std_logic;
    LocFarLSaerLoopback_i   => i_uP_LocalFarLSaerLpbk,       -- in  std_logic;
    LocFarRSaerLoopback_i   => i_uP_LocalFarRSaerLpbk,       -- in  std_logic;
    LocFarAuxSaerLoopback_i => i_uP_LocalFarAuxSaerLpbk,     -- in  std_logic;
    LocFarSaerLpbkCfg_i     => i_uP_LocalFarSaerLpbkCfg,     -- in  t_XConCfg;
    LocFarSpnnLnkLoopbackSel_i => i_uP_LocalFarSpnnLnkLpbkSel, -- in  std_logic_vector(1 downto 0);
    
    TxPaerEn_i              => i_uP_TxPaerEn,                -- in  std_logic;
    TxHSSaerEn_i            => i_uP_TxHSSaerEn,              -- in  std_logic;
    TxGtpEn_i               => i_up_TxGtpEn,                 -- in  std_logic;
    TxSpnnLnkEn_i           => i_up_TxSpnnLnkEn,             -- in  std_logic;
    TxDestSwitch_i          => i_uP_TxDestSwitch,            -- in  std_logic_vector(2 downto 0);
    --TxPaerIgnoreFifoFull_i  => ,                             -- in  std_logic;
    TxPaerReqActLevel_i     => i_uP_TxPaerReqActLevel,       -- in  std_logic;
    TxPaerAckActLevel_i     => i_uP_TxPaerAckActLevel,       -- in  std_logic;
    TxSaerChanEn_i          => i_uP_TxSaerChanEn,            -- in  std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
    --TxSaerChanCfg_i         => ,                             -- in  t_hssaerCfg_array(C_TX_HSSAER_N_CHAN-1 downto 0);
    
    TxTSMode_i              => i_uP_TxTSMode,                -- in  std_logic_vector(1 downto 0);
    TxTSTimeoutSel_i        => i_uP_TxTSTimeoutSel,          -- in  std_logic_vector(3 downto 0);
    TxTSRetrigCmd_i         => i_uP_TxTSRetrigCmd,           -- in  std_logic;
    TxTSRearmCmd_i          => i_uP_TxTSRearmCmd,            -- in  std_logic;
    TxTSRetrigStatus_o      => i_uP_TxTSRetrigStatus,        -- out std_logic;
    TxTSTimeoutCounts_o     => i_uP_TxTSTimeoutCounts,       -- out std_logic;
    TxTSMaskSel_i           => i_uP_TxTSMaskSel,             -- in  std_logic_vector(1 downto 0);
    
    LRxPaerEn_i             => i_uP_LRxPaerEn,               -- in  std_logic;
    RRxPaerEn_i             => i_uP_RRxPaerEn,               -- in  std_logic;
    AuxRxPaerEn_i           => i_uP_AuxRxPaerEn,             -- in  std_logic;
    LRxHSSaerEn_i           => i_uP_LRxHSSaerEn,             -- in  std_logic;
    RRxHSSaerEn_i           => i_uP_RRxHSSaerEn,             -- in  std_logic;
    AuxRxHSSaerEn_i         => i_uP_AuxRxHSSaerEn,           -- in  std_logic;
    LRxGtpEn_i              => i_up_LRxGtpEn,                -- in  std_logic;
    RRxGtpEn_i              => i_up_RRxGtpEn,                -- in  std_logic;
    AuxRxGtpEn_i            => i_up_AuxRxGtpEn,              -- in  std_logic;
    LRxSpnnLnkEn_i          => i_uP_LRxSpnnLnkEn,            -- in  std_logic;
    RRxSpnnLnkEn_i          => i_uP_RRxSpnnLnkEn,            -- in  std_logic;
    AuxRxSpnnLnkEn_i        => i_uP_AuxRxSpnnLnkEn,          -- in  std_logic;
    LRxSaerChanEn_i         => i_uP_LRxSaerChanEn,           -- in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerChanEn_i         => i_uP_RRxSaerChanEn,           -- in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerChanEn_i       => i_uP_AUXRxSaerChanEn,         -- in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RxPaerReqActLevel_i     => i_uP_RxPaerReqActLevel,       -- in  std_logic;
    RxPaerAckActLevel_i     => i_uP_RxPaerAckActLevel,       -- in  std_logic;
    RxPaerIgnoreFifoFull_i  => i_uP_RxPaerIgnoreFifoFull,    -- in  std_logic;
    RxPaerAckSetDelay_i     => i_uP_RxPaerAckSetDelay,       -- in  std_logic_vector(7 downto 0);
    RxPaerSampleDelay_i     => i_uP_RxPaerSampleDelay,       -- in  std_logic_vector(7 downto 0);
    RxPaerAckRelDelay_i     => i_uP_RxPaerAckRelDelay,       -- in  std_logic_vector(7 downto 0);
    
    -- Status
    WrapDetected_o          => i_uP_wrapDetected,            -- out std_logic;
    
    --TxPaerFifoEmpty_o       => i_uP_TxPaerFifoEmpty,         -- out std_logic;
    TxSaerStat_o            => i_uP_txSaerStat,              -- out t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
    
    LRxPaerFifoFull_o       => i_uP_LRxPaerFifoFull,         -- out std_logic;
    RRxPaerFifoFull_o       => i_uP_RRxPaerFifoFull,         -- out std_logic;
    AuxRxPaerFifoFull_o     => i_uP_AuxRxPaerFifoFull,       -- out std_logic;
    LRxSaerStat_o           => i_uP_LRxSaerStat,             -- out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerStat_o           => i_uP_RRxSaerStat,             -- out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerStat_o         => i_uP_AUXRxSaerStat,           -- out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    LRxGtpStat_o            => open, -- : out t_RxGtpStat;
    RRxGtpStat_o            => open, -- : out t_RxGtpStat;
    AUXRxGtpStat_o          => open, -- : out t_RxGtpStat;
    TxSpnnlnkStat_o         => i_uP_TxSpnnlnkStat,           -- out t_TxSpnnlnkStat;
    LRxSpnnlnkStat_o        => i_uP_LRxSpnnlnkStat,          -- out t_RxSpnnlnkStat;
    RRxSpnnlnkStat_o        => i_uP_RRxSpnnlnkStat,          -- out t_RxSpnnlnkStat;
    AuxRxSpnnlnkStat_o      => i_uP_AuxRxSpnnlnkStat,        -- out t_RxSpnnlnkStat;
    
    SpnnStartKey_i          => i_uP_SpnnStartKey,            -- in  std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command 
    SpnnStopKey_i           => i_uP_SpnnStopKey,             -- in  std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command  
    SpnnTxMask_i            => i_uP_SpnnTxMask,              -- in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    SpnnRxMask_i            => i_uP_SpnnRxMask,              -- in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
    SpnnCtrl_i              => i_uP_SpnnCtrl,                -- in  std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
    SpnnStatus_o            => i_uP_SpnnStatus,              -- out std_logic_vector(31 downto 0);  -- SpiNNaker Status Register           
    
    --
    -- INTERCEPTION
    ---------------------
    RRxData_o               => RRxData_o,                   -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    RRxSrcRdy_o             => RRxSrcRdy_o,                 -- : out std_logic;
    RRxDstRdy_i             => RRxDstRdy_i,                 -- : in  std_logic;
    RRxBypassData_i         => RRxBypassData_i,             -- : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    RRxBypassSrcRdy_i       => RRxBypassSrcRdy_i,           -- : in  std_logic;
    RRxBypassDstRdy_o       => RRxBypassDstRdy_o,           -- : out std_logic;
    --
    LRxData_o               => LRxData_o,                   -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    LRxSrcRdy_o             => LRxSrcRdy_o,                 -- : out std_logic;
    LRxDstRdy_i             => LRxDstRdy_i,                 -- : in  std_logic;
    LRxBypassData_i         => LRxBypassData_i,             -- : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    LRxBypassSrcRdy_i       => LRxBypassSrcRdy_i,           -- : in  std_logic;
    LRxBypassDstRdy_o       => LRxBypassDstRdy_o,           -- : out std_logic;
    --
    AuxRxData_o             => AuxRxData_o,                 -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    AuxRxSrcRdy_o           => AuxRxSrcRdy_o,               -- : out std_logic;
    AuxRxDstRdy_i           => AuxRxDstRdy_i,               -- : in  std_logic;
    AuxRxBypassData_i       => AuxRxBypassData_i,           -- : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    AuxRxBypassSrcRdy_i     => AuxRxBypassSrcRdy_i,         -- : in  std_logic;
    AuxRxBypassDstRdy_o     => AuxRxBypassDstRdy_o,         -- : out std_logic;        
    
    --
    -- LED drivers
    ---------------------
    LEDo_o                  => open,                         -- out std_logic;
    LEDr_o                  => open,                         -- out std_logic;
    LEDy_o                  => open                          -- out std_logic;
    
  );

    process (CLK_HSSAER_LS_P_i) is
        begin
        if (rising_edge(CLK_HSSAER_LS_P_i)) then
            shreg_aux0 <= shreg_aux0(2 downto 0)& ARx_HSSAER_i(0);
            shreg_aux1 <= shreg_aux1(2 downto 0)& ARx_HSSAER_i(1);
            shreg_aux2 <= shreg_aux2(2 downto 0)& ARx_HSSAER_i(2);
        end if;
    end process ;


end architecture str;
