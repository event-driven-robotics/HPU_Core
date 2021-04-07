-------------------------------------------------------------------------------
-- neuserial_core
-------------------------------------------------------------------------------

-- ------------------------------------------------------------------------------
-- 
--  Revision 1.1:  07/25/2018
--  - Added SpiNNlink capabilities
--    (M. Casti - IIT)
--    
-- ------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;
    use HPU_lib.HPUComponents_pkg.all;

library neuserial_lib;
    use neuserial_lib.NSComponents_pkg.all;

library neuelab_lib;
    use neuelab_lib.NEComponents_pkg.all;

library datapath_lib;
    use datapath_lib.DPComponents_pkg.neuserial_PAER_arbiter;
	
library spinn_neu_if_lib;
	use spinn_neu_if_lib.spinn_neu_pkg.all;
	

--****************************
--   PORT DECLARATION
--****************************

entity neuserial_core is
  generic (
    -- -----------------------    
    -- PAER        
    C_RX_HAS_PAER             : boolean                       := true;
    C_RX_PAER_L_SENS_ID       : std_logic_vector(2 downto 0)  := "000";
    C_RX_PAER_R_SENS_ID       : std_logic_vector(2 downto 0)  := "000";
    C_RX_PAER_A_SENS_ID       : std_logic_vector(2 downto 0)  := "001";
    C_TX_HAS_PAER             : boolean                       := true;
    C_PAER_DSIZE              : natural range 1 to 29         := 24;
    -- -----------------------        
    -- HSSAER
    C_RX_HAS_HSSAER           : boolean                       := true;
    C_RX_HSSAER_N_CHAN        : natural range 1 to 4          := 3;
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
    C_TX_HSSAER_N_CHAN        : natural range 1 to 4          := 3;
    -- -----------------------        
    -- GTP
    C_RX_HAS_GTP              : boolean                       := true;
    C_GTP_RXUSRCLK2_PERIOD_NS : real                          := 6.4;        
    C_TX_HAS_GTP              : boolean                       := true;
    C_GTP_TXUSRCLK2_PERIOD_NS : real                          := 6.4;  
    C_GTP_DSIZE               : positive                      := 16;
    -- -----------------------                
    -- SPINNLINK
    C_RX_HAS_SPNNLNK          : boolean                       := true;
    C_TX_HAS_SPNNLNK          : boolean                       := true;
    C_PSPNNLNK_WIDTH      	  : natural range 1 to 32         := 32;
    -- -----------------------
    -- INTERCEPTION
    C_RX_LEFT_INTERCEPTION    : boolean                       := false;
    C_RX_RIGHT_INTERCEPTION   : boolean                       := false;
    C_RX_AUX_INTERCEPTION     : boolean                       := false;
    -- -----------------------
    -- SIMULATION
    C_SIM_TIME_COMPRESSION     : boolean                      := false   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    
    );
  port (
    --
    -- Clocks & Reset
    ---------------------
    -- Resets
    nRst                        : in  std_logic;
    -- System Clock domain
    Clk_i                       : in  std_logic;
    Timing_i                    : in  time_tick;
    -- HSSAER Clocks domain
    Clk_hs_p                    : in  std_logic;
    Clk_hs_n                    : in  std_logic;
    Clk_ls_p                    : in  std_logic;
    Clk_ls_n                    : in  std_logic;
    
    --
    -- TX Interface
    ---------------------
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
    
    --
    -- RX Left Interface
    ---------------------
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
                          
    --
    -- RX Right Interface
    ---------------------
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
                   
    --
    -- Aux Interface
    ---------------------
    -- Parallel AER
    AuxRx_PAER_Addr_i           : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    AuxRx_PAER_Req_i            : in  std_logic;
    AuxRx_PAER_Ack_o            : out std_logic;
    -- HSSAER channels 
    AuxRx_HSSAER_i              : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    -- GTP lines
    AuxRx_RxGtpMsg_o            : out std_logic_vector(7 downto 0);
    AuxRx_RxGtpMsgSrcRdy_o      : out std_logic;
    AuxRx_RxGtpMsgDstRdy_i      : in  std_logic;  
    AuxRx_RxGtpAlignRequest_o   : out std_logic;
    AuxRx_GTP_RxUsrClk2_i       : in  std_logic;
    AuxRx_GTP_SoftResetRx_o     : out  std_logic;                                          
    AuxRx_GTP_DataValid_o       : out std_logic;          
    AuxRx_GTP_Rxuserrdy_o       : out std_logic;              
    AuxRx_GTP_Rxdata_i          : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
    AuxRx_GTP_Rxchariscomma_i   : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    AuxRx_GTP_Rxcharisk_i       : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    AuxRx_GTP_Rxdisperr_i       : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    AuxRx_GTP_Rxnotintable_i    : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
    AuxRx_GTP_Rxbyteisaligned_i : in  std_logic;                                           
    AuxRx_GTP_Rxbyterealign_i   : in  std_logic;         
    AuxRx_GTP_PllLock_i         : in  std_logic;                                           
    AuxRx_GTP_PllRefclklost_i   : in  std_logic;   
    -- SpiNNaker Interface 
    AuxRx_SPNN_Data_i             : in  std_logic_vector(6 downto 0); 
    AuxRx_SPNN_Ack_o              : out std_logic;              
    
    --
    -- FIFOs interfaces
    ---------------------
    FifoCoreDat_o             : out std_logic_vector(31 downto 0);
    FifoCoreRead_i            : in  std_logic;
    FifoCoreEmpty_o           : out std_logic;
    FifoCoreAlmostEmpty_o     : out std_logic;
    FifoCoreBurstReady_o      : out std_logic;
    FifoCoreFull_o            : out std_logic;
    FifoCoreNumData_o         : out std_logic_vector(10 downto 0);
    
    --
    CoreFifoDat_i             : in  std_logic_vector(31 downto 0);
    CoreFifoWrite_i           : in  std_logic;
    CoreFifoFull_o            : out std_logic;
    CoreFifoAlmostFull_o      : out std_logic;
    CoreFifoEmpty_o           : out std_logic;
    
    -----------------------------------------------------------------------
    -- uController Interface
    ---------------------
    -- Control
    CleanTimer_i              : in  std_logic;
    FlushRXFifos_i            : in  std_logic;
    FlushTXFifos_i            : in  std_logic;        
    --TxEnable_i              : in  std_logic;
    --TxPaerFlushFifos_i      : in  std_logic;
    --LRxEnable_i             : in  std_logic;
    --RRxEnable_i             : in  std_logic;
    LRxPaerFlushFifos_i       : in  std_logic;
    RRxPaerFlushFifos_i       : in  std_logic;
    AuxRxPaerFlushFifos_i     : in  std_logic;
    FullTimestamp_i           : in  std_logic;
    
    -- Configurations
    DmaLength_i               : in  std_logic_vector(15 downto 0);
    RemoteLoopback_i          : in  std_logic;
    LocNearLoopback_i         : in  std_logic;
    LocFarLPaerLoopback_i     : in  std_logic;
    LocFarRPaerLoopback_i     : in  std_logic;
    LocFarAuxPaerLoopback_i   : in  std_logic;
    LocFarLSaerLoopback_i     : in  std_logic;
    LocFarRSaerLoopback_i     : in  std_logic;
    LocFarAuxSaerLoopback_i   : in  std_logic;
    LocFarSaerLpbkCfg_i       : in  t_XConCfg;
    LocFarSpnnLnkLoopbackSel_i : in  std_logic_vector(1 downto 0);
    
    TxPaerEn_i                : in  std_logic;
    TxHSSaerEn_i              : in  std_logic;
    TxGtpEn_i                 : in  std_logic;
    TxSpnnLnkEn_i             : in  std_logic;
    TxDestSwitch_i            : in  std_logic_vector(2 downto 0);
    --TxPaerIgnoreFifoFull_i  : in  std_logic;
    TxPaerReqActLevel_i       : in  std_logic;
    TxPaerAckActLevel_i       : in  std_logic;
    TxSaerChanEn_i            : in  std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
    --TxSaerChanCfg_i         : in  t_hssaerCfg_array(C_TX_HSSAER_N_CHAN-1 downto 0);
    
    -- TX Timestamp
    TxTSMode_i                : in  std_logic_vector(1 downto 0);
    TxTSTimeoutSel_i          : in  std_logic_vector(3 downto 0);
    TxTSRetrigCmd_i           : in  std_logic;
    TxTSRearmCmd_i            : in  std_logic;
    TxTSRetrigStatus_o        : out std_logic;
    TxTSTimeoutCounts_o       : out std_logic;
    TxTSMaskSel_i             : in  std_logic_vector(1 downto 0);
    
    --
    LRxPaerEn_i               : in  std_logic;
    RRxPaerEn_i               : in  std_logic;
    AuxRxPaerEn_i             : in  std_logic;
    LRxHSSaerEn_i             : in  std_logic;
    RRxHSSaerEn_i             : in  std_logic;
    AuxRxHSSaerEn_i           : in  std_logic;
    LRxGtpEn_i                : in  std_logic;
    RRxGtpEn_i                : in  std_logic;
    AuxRxGtpEn_i              : in  std_logic;
    LRxSpnnLnkEn_i            : in  std_logic;
    RRxSpnnLnkEn_i            : in  std_logic;
    AuxRxSpnnLnkEn_i          : in  std_logic;
    LRxSaerChanEn_i           : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerChanEn_i           : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    AuxRxSaerChanEn_i         : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RxPaerReqActLevel_i       : in  std_logic;
    RxPaerAckActLevel_i       : in  std_logic;
    RxPaerIgnoreFifoFull_i    : in  std_logic;
    RxPaerAckSetDelay_i       : in  std_logic_vector(7 downto 0);
    RxPaerSampleDelay_i       : in  std_logic_vector(7 downto 0);
    RxPaerAckRelDelay_i       : in  std_logic_vector(7 downto 0);
    
    -- Status
    WrapDetected_o            : out   std_logic;
    
    --TxPaerFifoEmpty_o       : out std_logic;
    TxSaerStat_o              : out t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
    
    LRxPaerFifoFull_o         : out std_logic;
    RRxPaerFifoFull_o         : out std_logic;
    AuxRxPaerFifoFull_o       : out std_logic;
    LRxSaerStat_o             : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerStat_o             : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerStat_o           : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    LRxGtpStat_o              : out t_RxGtpStat;
    RRxGtpStat_o              : out t_RxGtpStat;
    AUXRxGtpStat_o            : out t_RxGtpStat;
    TxSpnnlnkStat_o           : out t_TxSpnnlnkStat;
    LRxSpnnlnkStat_o          : out t_RxSpnnlnkStat;
    RRxSpnnlnkStat_o          : out t_RxSpnnlnkStat;
    AuxRxSpnnlnkStat_o        : out t_RxSpnnlnkStat;
    
    SpnnStartKey_i            : in  std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command key
    SpnnStopKey_i             : in  std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command key
    SpnnTxMask_i              : in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    SpnnRxMask_i              : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
    SpnnCtrl_i                : in  std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
    SpnnStatus_o              : out std_logic_vector(31 downto 0);  -- SpiNNaker Status Register  
    
    --
    -- INTERCEPTION
    ---------------------
    RRxData_o                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    RRxSrcRdy_o               : out std_logic;
    RRxDstRdy_i               : in  std_logic;
    RRxBypassData_i           : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    RRxBypassSrcRdy_i         : in  std_logic;
    RRxBypassDstRdy_o         : out std_logic;
    --
    LRxData_o                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    LRxSrcRdy_o               : out std_logic;
    LRxDstRdy_i               : in  std_logic;
    LRxBypassData_i           : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    LRxBypassSrcRdy_i         : in  std_logic;
    LRxBypassDstRdy_o         : out std_logic;
    --
    AuxRxData_o               : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    AuxRxSrcRdy_o             : out std_logic;
    AuxRxDstRdy_i             : in  std_logic;
    AuxRxBypassData_i         : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    AuxRxBypassSrcRdy_i       : in  std_logic;
    AuxRxBypassDstRdy_o       : out std_logic;        
    
    --
    -- LED drivers
    ---------------------
    LEDo_o                    : out std_logic;
    LEDr_o                    : out std_logic;
    LEDy_o                    : out std_logic;
    
    --
    -- DEBUG SIGNALS
    ---------------------
    DBG_dataOk                : out std_logic;
    
    DBG_din                   : out std_logic_vector(63 downto 0);     
    DBG_wr_en                 : out std_logic;  
    DBG_rd_en                 : out std_logic;     
    DBG_dout                  : out std_logic_vector(63 downto 0);          
    DBG_full                  : out std_logic;    
    DBG_almost_full           : out std_logic;    
    DBG_overflow              : out std_logic;       
    DBG_empty                 : out std_logic;           
    DBG_almost_empty          : out std_logic;    
    DBG_underflow             : out std_logic;     
    DBG_data_count            : out std_logic_vector(10 downto 0);
    DBG_CH0_DATA              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_CH0_SRDY              : out std_logic;   
    DBG_CH0_DRDY              : out std_logic;        
    DBG_CH1_DATA              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_CH1_SRDY              : out std_logic;   
    DBG_CH1_DRDY              : out std_logic;        
    DBG_CH2_DATA              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_CH2_SRDY              : out std_logic;   
    DBG_CH2_DRDY              : out std_logic;
    DBG_Timestamp_xD          : out std_logic_vector(31 downto 0);
    DBG_MonInAddr_xD          : out std_logic_vector(31 downto 0);
    DBG_MonInSrcRdy_xS        : out std_logic;
    DBG_MonInDstRdy_xS        : out std_logic;
    DBG_RESETFIFO             : out std_logic;
    DBG_src_rdy               : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_dst_rdy               : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_err                   : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);  
    DBG_run                   : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_RX                    : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_FIFO_0                : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_1                : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_2                : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_3                : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_4                : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)
    );
-- translate_off
begin
    -- check the consistency of the generics
    assert (C_INTERNAL_DSIZE >= (C_PAER_DSIZE+3))
        report  "C_PAER_DSIZE should be at least " & string(integer'image(C_INTERNAL_DSIZE-4)) & "with current value" & CR &
                "of C_INTERNAL_DSIZE constant (see package aer_pkg)"
        severity failure;
-- translate_on
end entity neuserial_core;


--****************************
--   IMPLEMENTATION
--****************************

architecture str of neuserial_core is

    -----------------------------------------------------------------------------
    -- constants
    -----------------------------------------------------------------------------
    --
    -- this is the number of cycles the level on req has to be stable in order for
    -- a value change to be detected (and not interpreted as a possible glitch)
    --constant c_ReqStableCycles                      : positive := 31;
    --
    --constant c_SIFReqDelayCycles                    : natural  := 2;
    --constant c_SIFAckStableCycles                   : natural  := 3;
    --
    --constant c_DVS_SCX                              : boolean  := false;
    --
    constant c_TestEnableSequencerNoWait            : boolean  := false;
    constant c_TestEnableSequencerToMonitorLoopback : boolean  := false;
    constant c_EnableMonitorControlsSequencerToo    : boolean  := false;
    --
    --constant cTestEnableNoGaepButGenCounter        : boolean  := false;
    --constant c_LRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0000";
    --constant c_LRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0100";
    --constant c_LRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "1000";
    --constant c_RRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0001";
    --constant c_RRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0101";
    --constant c_RRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "1001";

    constant c_RIGHT_EYE : std_logic_vector(1 downto 0) := "01";
    constant c_LEFT_EYE  : std_logic_vector(1 downto 0) := "00";
    constant c_AUX1      : std_logic_vector(1 downto 0) := "10";
    constant c_PAER_SRC  : std_logic_vector(1 downto 0) := "00";
    constant c_SAER_SRC  : std_logic_vector(1 downto 0) := "01";
    constant c_GTP_SRC   : std_logic_vector(1 downto 0) := "10";

    -- This header coding comes from AERsensorsMap.xlsx (svn version r12867)
    constant C_EVENT_TYPE_ADDRESS   : std_logic := '0';
    constant C_EVENT_TYPE_TIMESTAMP : std_logic := '1';
    constant C_RESERVED             : std_logic_vector(C_INTERNAL_DSIZE-C_PAER_DSIZE-4-1 downto 0) := (others => '0');
    constant C_SRC_ID_CAMERA        : std_logic_vector(2 downto 0) := "000";
    constant C_SRC_ID_AUX_SKIN_SENS : std_logic_vector(2 downto 0) := "001";
    constant C_SRC_ID_OTHER_SENS    : std_logic_vector(2 downto 0) := "X1X";
    constant c_zero_vect : std_logic_vector(C_INTERNAL_DSIZE-C_PAER_DSIZE-4-1 downto 0) := (others => '0');

    constant c_LRxPaerHighBits    : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_PAER_L_SENS_ID;
    constant c_LRxSaerHighBits0   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER0_L_SENS_ID;
    constant c_LRxSaerHighBits1   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER1_L_SENS_ID;
    constant c_LRxSaerHighBits2   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER2_L_SENS_ID;
    constant c_LRxSaerHighBits3   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER3_L_SENS_ID;
    constant c_LRxGtpHighBits     : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & "111";                
    constant c_RRxPaerHighBits    : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_PAER_R_SENS_ID; 
    constant c_RRxSaerHighBits0   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER0_R_SENS_ID;
    constant c_RRxSaerHighBits1   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER1_R_SENS_ID;
    constant c_RRxSaerHighBits2   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER2_R_SENS_ID;
    constant c_RRxSaerHighBits3   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER3_R_SENS_ID;
    constant c_RRxGtpHighBits     : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & "111";               
    constant c_AuxRxPaerHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_PAER_A_SENS_ID; 
    constant c_AuxRxSaerHighBits0 : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER0_A_SENS_ID;
    constant c_AuxRxSaerHighBits1 : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER1_A_SENS_ID;
    constant c_AuxRxSaerHighBits2 : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER2_A_SENS_ID;
    constant c_AuxRxSaerHighBits3 : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_RX_SAER3_A_SENS_ID;
    constant c_AuxRxGtpHighBits   : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & "111";               


    -----------------------------------------------------------------------------
    -- types
    -----------------------------------------------------------------------------


    -----------------------------------------------------------------------------
    -- signals
    -----------------------------------------------------------------------------
	signal	Rst				 : std_logic;
	
    signal  i_rxMonSrc       : t_PaerSrc_array(2 downto 0);
    signal  i_rxMonDst       : t_PaerDst_array(2 downto 0);

    signal  i_txSeqData      : std_logic_vector(31 downto 0);
    signal  i_txSeqSrcRdy    : std_logic;
    signal  i_txSeqDstRdy    : std_logic;

    signal  i_rxMonData      : std_logic_vector(31 downto 0);
    signal  i_rxMonSrcRdy    : std_logic;
    signal  i_rxMonDstRdy    : std_logic;

    signal  i_seqData        : std_logic_vector(31 downto 0);
    signal  i_seqSrcRdy      : std_logic;
    signal  i_seqDstRdy      : std_logic;

    signal  i_monData        : std_logic_vector(31 downto 0);
    signal  i_monSrcRdy      : std_logic;
    signal  i_monDstRdy      : std_logic;

    signal  i_TxPaerAddr   : std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_TxPaerReq    : std_logic;
    signal  i_TxPaerAck    : std_logic;
    signal  ii_TxPaerReq   : std_logic;
    signal  ii_TxPaerAck   : std_logic;

    signal  i_LRxPaerAddr  : std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_LRxPaerReq   : std_logic;
    signal  i_LRxPaerAck   : std_logic;
    signal  ii_LRxPaerReq  : std_logic;
    signal  ii_LRxPaerAck  : std_logic;

    signal  i_RRxPaerAddr  : std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_RRxPaerReq   : std_logic;
    signal  i_RRxPaerAck   : std_logic;
    signal  ii_RRxPaerReq  : std_logic;
    signal  ii_RRxPaerAck  : std_logic;

    signal  i_AuxRxPaerAddr: std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_AuxRxPaerReq : std_logic;
    signal  i_AuxRxPaerAck : std_logic;
    signal  ii_AuxRxPaerReq: std_logic;
    signal  ii_AuxRxPaerAck: std_logic;

    signal  i_TxHssaer      : std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    signal  i_LRxHssaer     : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    signal  i_RRxHssaer     : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    signal  i_AuxRxHssaer   : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    
    signal  i_LRxData2of7FromSpinnaker          : std_logic_vector(6 downto 0);
    signal  i_LRxAckToSpinnaker                 : std_logic;
    signal  i_RRxData2of7FromSpinnaker          : std_logic_vector(6 downto 0);
    signal  i_RRxAckToSpinnaker                 : std_logic;
    signal  i_AuxRxData2of7FromSpinnaker        : std_logic_vector(6 downto 0);
    signal  i_AuxRxAckToSpinnaker               : std_logic;
    signal  i_TxData2of7ToSpinnaker            : std_logic_vector(6 downto 0);
    signal  i_TXAckFromSpinnaker               : std_logic;
    signal  i_Spnn_offload_on                   : std_logic;
    signal  i_Spnn_offload_off                  : std_logic;
    signal  i_Spnn_cmd_start                    : std_logic;
    signal  i_Spnn_cmd_stop                     : std_logic;

    signal  RRxData                             : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal  RRxSrcRdy                           : std_logic;
    signal  RRxDstRdy                           : std_logic;

    signal  LRxData                             : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal  LRxSrcRdy                           : std_logic;
    signal  LRxDstRdy                           : std_logic;

    signal  AuxRxData                           : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal  AuxRxSrcRdy                         : std_logic;
    signal  AuxRxDstRdy                         : std_logic;

--    for all : neuserial_loopback     use entity neuserial_lib.neuserial_loopback(beh);
--    for all : hpu_tx_datapath        use entity datapath_lib.hpu_tx_datapath(str);
--    for all : hpu_rx_datapath        use entity datapath_lib.hpu_rx_datapath(str);
--    for all : neuserial_PAER_arbiter use entity datapath_lib.neuserial_PAER_arbiter(rtl);
--    for all : CoreMonSeqRR           use entity neuelab_lib.CoreMonSeqRR(str);

-- GTP

-- 

signal i_TxGtpDataRate      : std_logic_vector(15 downto 0); 
signal i_TxGtpAlignRate     : std_logic_vector( 7 downto 0); 
signal i_TxGtpMsgRate       : std_logic_vector(15 downto 0); 
signal i_TxGtpIdleRate      : std_logic_vector(15 downto 0); 
signal i_TxGtpEventRate     : std_logic_vector(15 downto 0); 
signal i_TxGtpMessageRate   : std_logic_vector( 7 downto 0); 

-- GTP RX Left
signal i_LRxGtpDataRate     : std_logic_vector(15 downto 0);
signal i_LRxGtpAlignRate    : std_logic_vector( 7 downto 0);
signal i_LRxGtpMsgRate      : std_logic_vector(15 downto 0);
signal i_LRxGtpIdleRate     : std_logic_vector(15 downto 0);
signal i_LRxGtpEventRate    : std_logic_vector(15 downto 0);
signal i_LRxGtpMessageRate  : std_logic_vector( 7 downto 0);

-- GTP RX Right
signal i_RRxGtpDataRate     : std_logic_vector(15 downto 0);
signal i_RRxGtpAlignRate    : std_logic_vector( 7 downto 0);
signal i_RRxGtpMsgRate      : std_logic_vector(15 downto 0);
signal i_RRxGtpIdleRate     : std_logic_vector(15 downto 0);
signal i_RRxGtpEventRate    : std_logic_vector(15 downto 0);
signal i_RRxGtpMessageRate  : std_logic_vector( 7 downto 0);

-- GTP RX Aux
signal i_AuxRxGtpDataRate     : std_logic_vector(15 downto 0);
signal i_AuxRxGtpAlignRate    : std_logic_vector( 7 downto 0);
signal i_AuxRxGtpMsgRate      : std_logic_vector(15 downto 0);
signal i_AuxRxGtpIdleRate     : std_logic_vector(15 downto 0);
signal i_AuxRxGtpEventRate    : std_logic_vector(15 downto 0);
signal i_AuxRxGtpMessageRate  : std_logic_vector( 7 downto 0);

-- --------------
-- GTPTX




begin

Rst <= not nRst;

-- PAER Req and acknowledge polarity
--
Tx_PAER_Req_o    <= ii_TxPaerReq   xnor TxPaerReqActLevel_i;
ii_TxPaerAck     <= Tx_PAER_Ack_i  xnor TxPaerAckActLevel_i;

ii_LRxPaerReq    <= LRx_PAER_Req_i xnor RxPaerReqActLevel_i;
LRx_PAER_Ack_o   <= ii_LRxPaerAck  xnor RxPaerAckActLevel_i;

ii_RRxPaerReq    <= RRx_PAER_Req_i xnor RxPaerReqActLevel_i;
RRx_PAER_Ack_o   <= ii_RRxPaerAck  xnor RxPaerAckActLevel_i;

ii_AuxRxPaerReq  <= AuxRx_PAER_Req_i xnor RxPaerReqActLevel_i;
AuxRx_PAER_Ack_o <= ii_AuxRxPaerAck  xnor RxPaerAckActLevel_i;

------------------------
-- Local Far Loopback
------------------------

u_neuserial_loopback : neuserial_loopback
  generic map (
    C_PAER_DSIZE          => C_PAER_DSIZE,
    C_RX_HSSAER_N_CHAN    => C_RX_HSSAER_N_CHAN,
    C_TX_HSSAER_N_CHAN    => C_TX_HSSAER_N_CHAN
    )
  port map (
    Rx1PaerLpbkEn         => LocFarLPaerLoopback_i,      -- in  std_logic;
    Rx2PaerLpbkEn         => LocFarRPaerLoopback_i,      -- in  std_logic;
    Rx3PaerLpbkEn         => LocFarAuxPaerLoopback_i,    -- in  std_logic;
    Rx1SaerLpbkEn         => LocFarLSaerLoopback_i,      -- in  std_logic;
    Rx2SaerLpbkEn         => LocFarRSaerLoopback_i,      -- in  std_logic;
    Rx3SaerLpbkEn         => LocFarAuxSaerLoopback_i,    -- in  std_logic;
    XConSerCfg            => LocFarSaerLpbkCfg_i,        -- in  t_XConCfg;
    RxSpnnLnkLpbkEnSel    => LocFarSpnnLnkLoopbackSel_i, -- in  std_logic_vector(1 downto 0);
    
    -- Parallel AER
    ExtTxPAER_Addr_o      => Tx_PAER_Addr_o,             -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtTxPAER_Req_o       => ii_TxPaerReq,             -- out std_logic;
    ExtTxPAER_Ack_i       => ii_TxPaerAck,             -- in  std_logic;
    
    ExtRx1PAER_Addr_i     => LRx_PAER_Addr_i,            -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtRx1PAER_Req_i      => ii_LRxPaerReq,            -- in  std_logic;
    ExtRx1PAER_Ack_o      => ii_LRxPaerAck,            -- out std_logic;
    
    ExtRx2PAER_Addr_i     => RRx_PAER_Addr_i,            -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtRx2PAER_Req_i      => ii_RRxPaerReq,            -- in  std_logic;
    ExtRx2PAER_Ack_o      => ii_RRxPaerAck,            -- out std_logic;
    
    ExtRx3PAER_Addr_i     => AuxRx_PAER_Addr_i,          -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtRx3PAER_Req_i      => ii_AuxRxPaerReq,          -- in  std_logic;
    ExtRx3PAER_Ack_o      => ii_AuxRxPaerAck,          -- out std_logic;
    
    -- HSSAER
    ExtTxHSSAER_Tx_o      => Tx_HSSAER_o,                -- out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    ExtRx1HSSAER_Rx_i     => LRx_HSSAER_i,               -- in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    ExtRx2HSSAER_Rx_i     => RRx_HSSAER_i,               -- in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    ExtRx3HSSAER_Rx_i     => AuxRx_HSSAER_i,             -- in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    
    -- GTP interface
    --
    -- TBD signals to drive the GTP module
    --
    -- SpiNNlink interface
    ExtTx_data_2of7_to_spinnaker_o      => Tx_SPNN_Data_o,     -- out std_logic_vector(6 downto 0);
    ExtTx_ack_from_spinnaker_i          => Tx_SPNN_Ack_i,         -- in  std_logic;
    ExtRx1_data_2of7_from_spinnaker_i   => LRx_SPNN_Data_i,  -- in  std_logic_vector(6 downto 0); 
    ExtRx1_ack_to_spinnaker_o           => LRx_SPNN_Ack_o,          -- out std_logic;
    ExtRx2_data_2of7_from_spinnaker_i   => RRx_SPNN_Data_i,  -- in  std_logic_vector(6 downto 0); 
    ExtRx2_ack_to_spinnaker_o           => RRx_SPNN_Ack_o,          -- out std_logic;
    ExtRx3_data_2of7_from_spinnaker_i   => AuxRx_SPNN_Data_i,-- in  std_logic_vector(6 downto 0); 
    ExtRx3_ack_to_spinnaker_o           => AuxRx_SPNN_Ack_o,        -- out std_logic;
    
    
    -- Parallel AER 
    CoreTxPAER_Addr_i     => i_TxPaerAddr,             -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreTxPAER_Req_i      => i_TxPaerReq,              -- in  std_logic;
    CoreTxPAER_Ack_o      => i_TxPaerAck,              -- out std_logic;
    
    CoreRx1PAER_Addr_o    => i_LRxPaerAddr,            -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreRx1PAER_Req_o     => i_LRxPaerReq,             -- out std_logic;
    CoreRx1PAER_Ack_i     => i_LRxPaerAck,             -- in  std_logic;
    
    CoreRx2PAER_Addr_o    => i_RRxPaerAddr,            -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreRx2PAER_Req_o     => i_RRxPaerReq,             -- out std_logic;
    CoreRx2PAER_Ack_i     => i_RRxPaerAck,             -- in  std_logic;
    
    CoreRx3PAER_Addr_o    => i_AuxRxPaerAddr,          -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreRx3PAER_Req_o     => i_AuxRxPaerReq,           -- out std_logic;
    CoreRx3PAER_Ack_i     => i_AuxRxPaerAck,           -- in  std_logic;
    
    -- HSSAER
    CoreTxHSSAER_Tx_i     => i_TxHssaer,                -- in  std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    CoreRx1HSSAER_Rx_o    => i_LRxHssaer,               -- out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    CoreRx2HSSAER_Rx_o    => i_RRxHssaer,               -- out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    CoreRx3HSSAER_Rx_o    => i_AuxRxHssaer,             -- out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1)
    
    -- GTP interface
    --
    -- TBD signals to drive the GTP module
    --
    
    -- SpiNNlink interface
    CoreTx_data_2of7_to_spinnaker_i     => i_TxData2of7ToSpinnaker,     -- in  std_logic_vector(6 downto 0);
    CoreTx_ack_from_spinnaker_o         => i_TxAckFromSpinnaker,         -- out std_logic;
    CoreRx1_data_2of7_from_spinnaker_o  => i_LRxData2of7FromSpinnaker,  -- out std_logic_vector(6 downto 0); 
    CoreRx1_ack_to_spinnaker_i          => i_LRxAckToSpinnaker,          -- in  std_logic;
    CoreRx2_data_2of7_from_spinnaker_o  => i_RRxData2of7FromSpinnaker,  -- out std_logic_vector(6 downto 0); 
    CoreRx2_ack_to_spinnaker_i          => i_RRxAckToSpinnaker,          -- in  std_logic;
    CoreRx3_data_2of7_from_spinnaker_o  => i_AuxRxData2of7FromSpinnaker,-- out std_logic_vector(6 downto 0); 
    CoreRx3_ack_to_spinnaker_i          => i_AuxRxAckToSpinnaker         -- in  std_logic
    );

    
---------------------
-- TX path
---------------------

i_Spnn_offload_on  <= i_Spnn_cmd_stop or  SpnnCtrl_i(2);
i_Spnn_offload_off <= i_Spnn_cmd_start or SpnnCtrl_i(1);

u_tx_datapath : hpu_tx_datapath
  generic map (
    C_INPUT_DSIZE             => C_INTERNAL_DSIZE,
    C_PAER_DSIZE              => C_PAER_DSIZE,
    C_HAS_PAER                => C_TX_HAS_PAER,
    C_HAS_HSSAER              => C_TX_HAS_HSSAER,
    C_HSSAER_N_CHAN           => C_TX_HSSAER_N_CHAN,
    C_HAS_GTP                 => C_TX_HAS_GTP,
    C_GTP_DSIZE               => C_GTP_DSIZE,
    C_GTP_TXUSRCLK2_PERIOD_NS => C_GTP_TXUSRCLK2_PERIOD_NS, 
    C_GTP_RXUSRCLK2_PERIOD_NS => C_GTP_TXUSRCLK2_PERIOD_NS,             
    C_HAS_SPNNLNK             => C_TX_HAS_SPNNLNK,
    C_PSPNNLNK_WIDTH          => C_PSPNNLNK_WIDTH,
    C_SIM_TIME_COMPRESSION    => C_SIM_TIME_COMPRESSION
    )
  port map (
    -- **********************************************
    -- Barecontrol
    -- **********************************************
    -- Resets
    nRst                => nRst,                        
    -- System Clock domain
    Clk_i               => Clk_i,                          
    En1Sec_i            => timing_i.en1s,   
		-- HSSAER Clocks domain
		Clk_ls_p            => Clk_ls_p,                    
		Clk_ls_n            => Clk_ls_n,                    

    -- **********************************************
    -- uController Interface
    -- **********************************************

    -- Control signals
    -----------------------------
    -- EnableIp_i           => TxEnable_i,                
		-- PaerFlushFifos_i     => TxPaerFlushFifos_i,         
    TxGtpAlignRequest_i     => Tx_TxGtpAlignRequest_i,
    -- TxGtpAutoAlign_i        : in  std_logic;
    -- TxGtpErrorInjection_i   : in  std_logic;
    
    -- Monitor
    TxGtpAlignFlag_o        => Tx_TxGtpAlignFlag_o,   -- Monitor out: sending align    
    
    -- Status signals
    -----------------------------
    --PaerFifoFull_o       => TxPaerFifoEmpty_o,           -- out std_logic;
    TxSaerStat_o         => TxSaerStat_o,                -- out t_TxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    TxSpnnlnkStat_o      => TxSpnnlnkStat_o,             -- out t_TxSpnnlnkStat;
    -- GTP Statistics 
    TxGtpDataRate_o      => i_TxGtpDataRate,
    TxGtpAlignRate_o     => i_TxGtpAlignRate,
    TxGtpMsgRate_o       => i_TxGtpMsgRate,
    TxGtpIdleRate_o      => i_TxGtpIdleRate,
    TxGtpEventRate_o     => i_TxGtpEventRate,
    TxGtpMessageRate_o   => i_TxGtpMessageRate,
     
    -- Configuration signals
    -----------------------------
    --     
    -- Destination I/F configurations
    EnablePAER_i         => TxPaerEn_i,                  
    EnableHSSAER_i       => TxHSSaerEn_i,                
    EnableGTP_i          => TxGtpEn_i,                   
    EnableSPNNLNK_i      => TxSpnnLnkEn_i,
    DestinationSwitch_i  => TxDestSwitch_i,              
    -- PAER
    --PaerIgnoreFifoFull_i => TxPaerIgnoreFifoFull_i,    
    PaerReqActLevel_i    => '1',                         
    PaerAckActLevel_i    => '1',                         
    -- HSSAER
    HSSaerChanEn_i       => TxSaerChanEn_i,              
    --HSSAERChanCfg_i      => TxHSSaerChanCfg_i,         
    -- GTP
    --
    -- SpiNNaker
    -----------------------------
    SpnnOffloadOn_i       => i_Spnn_offload_on,          
    SpnnOffloadOff_i      => i_Spnn_offload_off,         
    SpnnTxMask_i          => SpnnTxMask_i,             
    SpnnOffload_o         => SpnnStatus_o(1),          
    SpnnLinkTimeout_o     => SpnnStatus_o(0),           
    SpnnLinkTimeoutDis_i  => SpnnCtrl_i(0),             
                  
    -- **********************************************
    -- Transmit Data Input
    -- **********************************************
    TxData_i                => i_txSeqData,              
    TxDataSrcRdy_i          => i_txSeqSrcRdy,            
    TxDataDstRdy_o          => i_txSeqDstRdy,            
    
    TxGtpMsg_i              => Tx_TxGtpMsg_i,
    TxGtpMsgSrcRdy_i        => Tx_TxGtpMsgSrcRdy_i,
    TxGtpMsgDstRdy_o        => Tx_TxGtpMsgDstRdy_o,
       
    -- **********************************************
    -- Destination interfaces
    -- **********************************************
    
    -- Parallel AER Interface
    -- ----------------------------------------------
    PAER_Addr_o             => i_TxPaerAddr,             
    PAER_Req_o              => i_TxPaerReq,              
    PAER_Ack_i              => i_TxPaerAck,              

    -- HSSAER Interface
    -- ----------------------------------------------
    HSSAER_Tx_o             => i_TxHssaer,               

    -- GTP Wizard Interface
    -- ----------------------------------------------
    GTP_TxUsrClk2_i         => Tx_GTP_TxUsrClk2_i,
    GTP_SoftResetTx_o       => Tx_GTP_SoftResetTx_o,       
    GTP_DataValid_o         => Tx_GTP_DataValid_o,
    GTP_Txuserrdy_o         => Tx_GTP_Txuserrdy_o,       
    GTP_Txdata_o            => Tx_GTP_Txdata_o,       
    GTP_Txcharisk_o         => Tx_GTP_Txcharisk_o,       
    GTP_PllLock_i           => Tx_GTP_PllLock_i,       
    GTP_PllRefclklost_i     => Tx_GTP_PllRefclklost_i,

    -- SpiNNlink Interface
    -- ----------------------------------------------
		SPNN_Data_o             => Tx_SPNN_Data_o,
		SPNN_Ack_i              => Tx_SPNN_Ack_i
    );
    
   
    
---------------------
-- RX paths
---------------------

u_rx_left_datapath : hpu_rx_datapath
  generic map (
    C_OUTPUT_DSIZE            => C_INTERNAL_DSIZE,
    C_PAER_DSIZE              => C_PAER_DSIZE,
    C_HAS_PAER                => C_RX_HAS_PAER,
    C_HAS_HSSAER              => C_RX_HAS_HSSAER,
    C_HSSAER_N_CHAN           => C_RX_HSSAER_N_CHAN,
    C_HAS_GTP                 => C_RX_HAS_GTP,
    C_GTP_DSIZE               => C_GTP_DSIZE,
    C_GTP_TXUSRCLK2_PERIOD_NS => C_GTP_TXUSRCLK2_PERIOD_NS,
    C_GTP_RXUSRCLK2_PERIOD_NS => C_GTP_RXUSRCLK2_PERIOD_NS,
    C_HAS_SPNNLNK             => C_RX_HAS_SPNNLNK,
    C_PSPNNLNK_WIDTH          => C_PSPNNLNK_WIDTH,
    C_SIM_TIME_COMPRESSION    => C_SIM_TIME_COMPRESSION
    )
  port map (

    -- **********************************************
    -- Barecontrol
    -- **********************************************
    -- Resets
    nRst                 => nRst,                         -- in  std_logic;
    -- System Clock domain
    Clk_i                => Clk_i,                        -- in  std_logic;
    En1Sec_i             => timing_i.en1s,                -- : in  std_logic;
		-- HSSAER Clocks domain
		Clk_hs_p             => Clk_hs_p,                     -- in  std_logic;
		Clk_hs_n             => Clk_hs_n,                     -- in  std_logic;
    Clk_ls_p             => Clk_ls_p,                     -- in  std_logic;
    Clk_ls_n             => Clk_ls_n,                     -- in  std_logic;
 
 
    -- **********************************************
    -- Controls
    -- **********************************************
    --
    -- In case of aux channel the HPU header is 
    -- adapted to what received
    -- ----------------------------------------------
    Aux_Channel_i        => '0',

    -- **********************************************
    -- uController Interface
    -- **********************************************

    -- Control signals
    -- ----------------------------------------------
    PaerFlushFifos_i     => LRxPaerFlushFifos_i,         
    
    -- Control output signals
    -- ----------------------------------------------    
    RxGtpAlignRequest_o  => LRx_RxGtpAlignRequest_o, 

    -- Status signals
    -----------------------------
    PaerFifoFull_o       => LRxPaerFifoFull_o,           -- out std_logic;
    RxSaerStat_o         => LRxSaerStat_o,               -- out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    RxGtpStat_o          => LRxGtpStat_o,                -- out t_RxGtpStat;
    RxSpnnlnkStat_o      => LRxSpnnlnkStat_o,            -- out t_RxSpnnlnkStat;
        
    -- GTP Statistics        
    RxGtpDataRate_o      => i_LRxGtpDataRate,            -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpAlignRate_o     => i_LRxGtpAlignRate,           -- : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    RxGtpMsgRate_o       => i_LRxGtpMsgRate,             -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpIdleRate_o      => i_LRxGtpIdleRate,            -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpEventRate_o     => i_LRxGtpEventRate,           -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpMessageRate_o   => i_LRxGtpMessageRate,         -- : out std_logic_vector( 7 downto 0); -- Count per millisecond 

    -- Configuration signals
    -----------------------------
    --
    -- Source I/F configurations
    EnablePAER_i         => LRxPaerEn_i,                 -- in  std_logic;
    EnableHSSAER_i       => LRxHSSaerEn_i,               -- in  std_logic;
    EnableGTP_i          => LRxGtpEn_i,                  -- in  std_logic;
    EnableSPNNLNK_i      => LRxSpnnLnkEn_i,              -- in  std_logic;
    -- PAER
    RxPaerHighBits_i     => c_LRxPaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    PaerReqActLevel_i    => RxPaerReqActLevel_i,         -- in  std_logic;
    PaerAckActLevel_i    => RxPaerAckActLevel_i,         -- in  std_logic;
    PaerIgnoreFifoFull_i => RxPaerIgnoreFifoFull_i,      -- in  std_logic;
    PaerAckSetDelay_i    => RxPaerAckSetDelay_i,         -- in  std_logic_vector(7 downto 0);
    PaerSampleDelay_i    => RxPaerSampleDelay_i,         -- in  std_logic_vector(7 downto 0);
    PaerAckRelDelay_i    => RxPaerAckRelDelay_i,         -- in  std_logic_vector(7 downto 0);
    -- HSSAER
    RxSaerHighbits0_i    => c_LRxSaerHighBits0,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits1_i    => c_LRxSaerHighBits1,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits2_i    => c_LRxSaerHighBits2,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits3_i    => c_LRxSaerHighBits3,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    HSSaerChanEn_i       => LRxSaerChanEn_i,             -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    -- GTP
    RxGtpHighbits_i      => c_LRxGtpHighBits,            -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    -- SpiNNlink controls
    SpnnStartKey_i       => SpnnStartKey_i,            -- in  std_logic_vector(31 downto 0);
    SpnnStopKey_i        => SpnnStopKey_i,             -- in  std_logic_vector(31 downto 0);
    SpnnCmdStart_o       => open,                        -- out std_logic;
    SpnnCmdStop_o        => open,                        -- out std_logic;
    SpnnRxMask_i         => SpnnRxMask_i,              -- in  std_logic_vector(31 downto 0);
    SpnnKeysEnable_i     => SpnnCtrl_i(24),             -- in  std_logic;
    SpnnParityErr_o      => SpnnStatus_o(25),           -- out std_logic;
    SpnnRxErr_o          => SpnnStatus_o(24),           -- out std_logic; 

  
    -- **********************************************
    -- Source Interfaces
    -- **********************************************

    -- Parallel AER Interface
    -- ----------------------------------------------
    PAER_Addr_i          => i_LRxPaerAddr,               -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_i           => i_LRxPaerReq,                -- in  std_logic;
    PAER_Ack_o           => i_LRxPaerAck,                -- out std_logic;

    -- HSSAER Interface
    -- ----------------------------------------------
    HSSAER_Rx_i          => i_LRxHssaer,                -- in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP Wizard Interface
    -- ----------------------------------------------
    GTP_RxUsrClk2_i       => LRx_GTP_RxUsrClk2_i, 
    GTP_SoftResetRx_o     => LRx_GTP_SoftResetRx_o,                                
    GTP_DataValid_o       => LRx_GTP_DataValid_o,                                
    GTP_Rxuserrdy_o       => LRx_GTP_Rxuserrdy_o,                                      
    GTP_Rxdata_i          => LRx_GTP_Rxdata_i,            
    GTP_Rxchariscomma_i   => LRx_GTP_Rxchariscomma_i,      
    GTP_Rxcharisk_i       => LRx_GTP_Rxcharisk_i,          
    GTP_Rxdisperr_i       => LRx_GTP_Rxdisperr_i,          
    GTP_Rxnotintable_i    => LRx_GTP_Rxnotintable_i,       
    GTP_Rxbyteisaligned_i => LRx_GTP_Rxbyteisaligned_i,                           
    GTP_Rxbyterealign_i   => LRx_GTP_Rxbyterealign_i,                            
    GTP_PllLock_i         => LRx_GTP_PllLock_i,                                        
    GTP_PllRefclklost_i   => LRx_GTP_PllRefclklost_i,                                      

    -- SpiNNlink
    -- ----------------------------------------------
    SPNN_Data_i           => i_LRxData2of7FromSpinnaker,
    SPNN_Ack_o            => i_LRxAckToSpinnaker,


    -- **********************************************
    -- Received Data Output
    -- **********************************************
    RxData_o             => LRxData,               --  i_rxMonSrc(0).idx,      
    RxDataSrcRdy_o       => LRxSrcRdy,             --  i_rxMonSrc(0).vld,      
    RxDataDstRdy_i       => LRxDstRdy,             --  i_rxMonDst(0).rdy,      

    RxGtpMsg_o           => LRx_RxGtpMsg_o,
    RxGtpMsgSrcRdy_o     => LRx_RxGtpMsgSrcRdy_o,
    RxGtpMsgDstRdy_i     => LRx_RxGtpMsgDstRdy_i,
    
    
    -- **********************************************
    -- Debug signals
    -- **********************************************
    dbg_PaerDataOk       => open,                         -- out std_logic
    DBG_src_rdy          => open,
    DBG_dst_rdy          => open,
    DBG_err              => open, 
    DBG_run              => open,
    DBG_RX               => open,
    
    DBG_FIFO_0           => open,
    DBG_FIFO_1           => open,
    DBG_FIFO_2           => open,
    DBG_FIFO_3           => open,
    DBG_FIFO_4           => open                         
    );


u_rx_right_datapath : hpu_rx_datapath
  generic map (
    C_OUTPUT_DSIZE            => C_INTERNAL_DSIZE,
    C_PAER_DSIZE              => C_PAER_DSIZE,
    C_HAS_PAER                => C_RX_HAS_PAER,
    C_HAS_HSSAER              => C_RX_HAS_HSSAER,
    C_HSSAER_N_CHAN           => C_RX_HSSAER_N_CHAN,
    C_HAS_GTP                 => C_RX_HAS_GTP,
    C_GTP_DSIZE               => C_GTP_DSIZE,
    C_GTP_TXUSRCLK2_PERIOD_NS => C_GTP_TXUSRCLK2_PERIOD_NS,
    C_GTP_RXUSRCLK2_PERIOD_NS => C_GTP_RXUSRCLK2_PERIOD_NS,
    C_HAS_SPNNLNK             => C_RX_HAS_SPNNLNK,
    C_PSPNNLNK_WIDTH          => C_PSPNNLNK_WIDTH,
    C_SIM_TIME_COMPRESSION    => C_SIM_TIME_COMPRESSION
    )
  port map (

    -- **********************************************
    -- Barecontrol
    -- **********************************************
    -- Resets
    nRst                 => nRst,                        -- in  std_logic;
    -- System Clock domain
    Clk_i                => Clk_i,                    -- in  std_logic;
    En1Sec_i             => timing_i.en1s,-- : in  std_logic;
		-- HSSAER Clocks domain
		Clk_hs_p             => Clk_hs_p,                     -- in  std_logic;
		Clk_hs_n             => Clk_hs_n,                     -- in  std_logic;
    Clk_ls_p             => Clk_ls_p,                     -- in  std_logic;
    Clk_ls_n             => Clk_ls_n,                     -- in  std_logic;
 
 
    -- **********************************************
    -- Controls
    -- **********************************************
    --
    -- In case of aux channel the HPU header is 
    -- adapted to what received
    -- ----------------------------------------------
    Aux_Channel_i        => '0',


    -- **********************************************
    -- uController Interface
    -- **********************************************

    -- Control signals
    -- ----------------------------------------------
    PaerFlushFifos_i     => RRxPaerFlushFifos_i,         -- in  std_logic;
    
    -- Control output signals
    -- ----------------------------------------------    
    RxGtpAlignRequest_o  => RRx_RxGtpAlignRequest_o, 

    -- Status signals
    -----------------------------
    PaerFifoFull_o       => RRxPaerFifoFull_o,           -- out std_logic;
    RxSaerStat_o         => RRxSaerStat_o,               -- out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    RxGtpStat_o          => RRxGtpStat_o,                -- out t_RxGtpStat;
    RxSpnnlnkStat_o      => RRxSpnnlnkStat_o,            -- out t_RxSpnnlnkStat;
    
    -- GTP Statistics        
    RxGtpDataRate_o      => i_RRxGtpDataRate,            -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpAlignRate_o     => i_RRxGtpAlignRate,           -- : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    RxGtpMsgRate_o       => i_RRxGtpMsgRate,             -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpIdleRate_o      => i_RRxGtpIdleRate,            -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpEventRate_o     => i_RRxGtpEventRate,           -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpMessageRate_o   => i_RRxGtpMessageRate,         -- : out std_logic_vector( 7 downto 0); -- Count per millisecond 

    -- Configuration signals
    -----------------------------
    --
    -- Source I/F configurations
    EnablePAER_i         => RRxPaerEn_i,                 -- in  std_logic;
    EnableHSSAER_i       => RRxHSSaerEn_i,               -- in  std_logic;
    EnableGTP_i          => RRxGtpEn_I,                  -- in  std_logic;
    EnableSPNNLNK_i      => RRxSpnnLnkEn_i,              -- in  std_logic;
    -- PAER
    RxPaerHighBits_i     => c_RRxPaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    PaerReqActLevel_i    => RxPaerReqActLevel_i,         -- in  std_logic;
    PaerAckActLevel_i    => RxPaerAckActLevel_i,         -- in  std_logic;
    PaerIgnoreFifoFull_i => RxPaerIgnoreFifoFull_i,      -- in  std_logic;
    PaerAckSetDelay_i    => RxPaerAckSetDelay_i,         -- in  std_logic_vector(7 downto 0);
    PaerSampleDelay_i    => RxPaerSampleDelay_i,         -- in  std_logic_vector(7 downto 0);
    PaerAckRelDelay_i    => RxPaerAckRelDelay_i,         -- in  std_logic_vector(7 downto 0);
    -- HSSAER
    RxSaerHighbits0_i    => c_RRxSaerHighBits0,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits1_i    => c_RRxSaerHighBits1,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits2_i    => c_RRxSaerHighBits2,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits3_i    => c_RRxSaerHighBits3,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    HSSaerChanEn_i       => RRxSaerChanEn_i,             -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    -- GTP
    RxGtpHighbits_i      => c_RRxGtpHighBits,            -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    -- SpiNNlink controls
    SpnnStartKey_i       => SpnnStartKey_i,            -- in  std_logic_vector(31 downto 0);
    SpnnStopKey_i        => SpnnStopKey_i,             -- in  std_logic_vector(31 downto 0);
    SpnnCmdStart_o       => open,                        -- out std_logic;
    SpnnCmdStop_o        => open,                        -- out std_logic;
    SpnnRxMask_i         => SpnnRxMask_i,              -- in  std_logic_vector(31 downto 0);
    SpnnKeysEnable_i     => SpnnCtrl_i(16),             -- in  std_logic;
    SpnnParityErr_o      => SpnnStatus_o(17),           -- out std_logic;
    SpnnRxErr_o          => SpnnStatus_o(16),           -- out std_logic;
                       
                        
    -- **********************************************
    -- Source Interfaces
    -- **********************************************

    -- Parallel AER Interface
    -- ----------------------------------------------
    PAER_Addr_i          => i_RRxPaerAddr,             -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_i           => i_RRxPaerReq,              -- in  std_logic;
    PAER_Ack_o           => i_RRxPaerAck,              -- out std_logic;

    -- HSSAER Interface
    -- ----------------------------------------------
    HSSAER_Rx_i          => i_RRxHssaer,                -- in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP Wizard Interface
    -- ----------------------------------------------
    GTP_RxUsrClk2_i       => RRx_GTP_RxUsrClk2_i,        
    GTP_SoftResetRx_o     => RRx_GTP_SoftResetRx_o,                           
    GTP_DataValid_o       => RRx_GTP_DataValid_o,                              
    GTP_Rxuserrdy_o       => RRx_GTP_Rxuserrdy_o,                                         
    GTP_Rxdata_i          => RRx_GTP_Rxdata_i,           
    GTP_Rxchariscomma_i   => RRx_GTP_Rxchariscomma_i,    
    GTP_Rxcharisk_i       => RRx_GTP_Rxcharisk_i,        
    GTP_Rxdisperr_i       => RRx_GTP_Rxdisperr_i,        
    GTP_Rxnotintable_i    => RRx_GTP_Rxnotintable_i,     
    GTP_Rxbyteisaligned_i => RRx_GTP_Rxbyteisaligned_i,                         
    GTP_Rxbyterealign_i   => RRx_GTP_Rxbyterealign_i,                          
    GTP_PllLock_i         => RRx_GTP_PllLock_i,                                      
    GTP_PllRefclklost_i   => RRx_GTP_PllRefclklost_i,                                    

    -- SpiNNlink
    -- ----------------------------------------------
    SPNN_Data_i           => i_RRxData2of7FromSpinnaker,
    SPNN_Ack_o            => i_RRxAckToSpinnaker,


    -- **********************************************
    -- Received Data Output
    -- **********************************************
    RxData_o             => RRxData,               -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);  i_rxMonSrc(1).idx,      
    RxDataSrcRdy_o       => RRxSrcRdy,             -- : out std_logic;                                      i_rxMonSrc(1).vld,      
    RxDataDstRdy_i       => RRxDstRdy,             -- : in  std_logic;                                      i_rxMonDst(1).rdy,      

    RxGtpMsg_o           => RRx_RxGtpMsg_o,
    RxGtpMsgSrcRdy_o     => RRx_RxGtpMsgSrcRdy_o,
    RxGtpMsgDstRdy_i     => RRx_RxGtpMsgDstRdy_i,   
       
        
    -- **********************************************
    -- Debug signals
    -- **********************************************
    dbg_PaerDataOk       => open,                         -- out std_logic
    DBG_src_rdy          => open,
    DBG_dst_rdy          => open,
    DBG_err              => open, 
    DBG_run              => open,
    DBG_RX               => open,
    
    DBG_FIFO_0           => open,
    DBG_FIFO_1           => open,
    DBG_FIFO_2           => open,
    DBG_FIFO_3           => open,
    DBG_FIFO_4           => open                         
    );


u_rx_aux_datapath : hpu_rx_datapath
  generic map (
    C_OUTPUT_DSIZE            => C_INTERNAL_DSIZE,
    C_PAER_DSIZE              => C_PAER_DSIZE,
    C_HAS_PAER                => C_RX_HAS_PAER,
    C_HAS_HSSAER              => C_RX_HAS_HSSAER,
    C_HSSAER_N_CHAN           => C_RX_HSSAER_N_CHAN,
    C_HAS_GTP                 => C_RX_HAS_GTP,
    C_GTP_DSIZE               => C_GTP_DSIZE,
    C_GTP_TXUSRCLK2_PERIOD_NS => C_GTP_TXUSRCLK2_PERIOD_NS,
    C_GTP_RXUSRCLK2_PERIOD_NS => C_GTP_RXUSRCLK2_PERIOD_NS,
    C_HAS_SPNNLNK             => C_RX_HAS_SPNNLNK,
    C_PSPNNLNK_WIDTH          => C_PSPNNLNK_WIDTH,
    C_SIM_TIME_COMPRESSION    => C_SIM_TIME_COMPRESSION
    )
  port map (

    -- **********************************************
    -- Barecontrol
    -- **********************************************
    -- Resets
    nRst                 => nRst,                         -- in  std_logic;
    -- System Clock domain
    Clk_i                => Clk_i,                        -- in  std_logic;
    En1Sec_i             => timing_i.en1s,                -- : in  std_logic;
		-- HSSAER Clocks domain
		Clk_hs_p             => Clk_hs_p,                     -- in  std_logic;
		Clk_hs_n             => Clk_hs_n,                     -- in  std_logic;
    Clk_ls_p             => Clk_ls_p,                     -- in  std_logic;
    Clk_ls_n             => Clk_ls_n,                     -- in  std_logic;
 
 
    -- **********************************************
    -- Controls
    -- **********************************************
    --
    -- In case of aux channel the HPU header is 
    -- adapted to what received
    -- ----------------------------------------------
    Aux_Channel_i        => '1',


    -- **********************************************
    -- uController Interface
    -- **********************************************

    -- Control signals
    -- ----------------------------------------------
    PaerFlushFifos_i     => AuxRxPaerFlushFifos_i,         -- in  std_logic;
    
    -- Control output signals
    -- ---------------------------------------------- 
    RxGtpAlignRequest_o  => AuxRx_RxGtpAlignRequest_o,            -- out std_logic;  
 
    -- Status signals
    -----------------------------
    PaerFifoFull_o       => AuxRxPaerFifoFull_o,           -- out std_logic;
    RxSaerStat_o         => AuxRxSaerStat_o,               -- out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    RxGtpStat_o          => AuxRxGtpStat_o,                -- out t_RxGtpStat;
    RxSpnnlnkStat_o      => AuxRxSpnnlnkStat_o,            -- out t_RxSpnnlnkStat;
    
    -- GTP Statistics        
    RxGtpDataRate_o      => i_AuxRxGtpDataRate,            -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpAlignRate_o     => i_AuxRxGtpAlignRate,           -- : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    RxGtpMsgRate_o       => i_AuxRxGtpMsgRate,             -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpIdleRate_o      => i_AuxRxGtpIdleRate,            -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpEventRate_o     => i_AuxRxGtpEventRate,           -- : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpMessageRate_o   => i_AuxRxGtpMessageRate,         -- : out std_logic_vector( 7 downto 0); -- Count per millisecond 

    -- Configuration signals
    -----------------------------
    --
    -- Source I/F configurations
    EnablePAER_i         => AuxRxPaerEn_i,                 -- in  std_logic;
    EnableHSSAER_i       => AuxRxHSSaerEn_i,               -- in  std_logic;
    EnableGTP_i          => AuxRxGtpEn_I,                  -- in  std_logic;
    EnableSPNNLNK_i      => AuxRxSpnnLnkEn_i,              -- in  std_logic;
    -- PAER
    RxPaerHighBits_i     => c_AuxRxPaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    PaerReqActLevel_i    => RxPaerReqActLevel_i,         -- in  std_logic;
    PaerAckActLevel_i    => RxPaerAckActLevel_i,         -- in  std_logic;
    PaerIgnoreFifoFull_i => RxPaerIgnoreFifoFull_i,      -- in  std_logic;
    PaerAckSetDelay_i    => RxPaerAckSetDelay_i,         -- in  std_logic_vector(7 downto 0);
    PaerSampleDelay_i    => RxPaerSampleDelay_i,         -- in  std_logic_vector(7 downto 0);
    PaerAckRelDelay_i    => RxPaerAckRelDelay_i,         -- in  std_logic_vector(7 downto 0);
    -- HSSAER
    RxSaerHighbits0_i    => c_AuxRxSaerHighBits0,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits1_i    => c_AuxRxSaerHighBits1,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits2_i    => c_AuxRxSaerHighBits2,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighbits3_i    => c_AuxRxSaerHighBits3,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    HSSaerChanEn_i       => AuxRxSaerChanEn_i,             -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    -- GTP
    RxGtpHighbits_i      => c_AuxRxGtpHighBits,            -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    -- SpiNNlink controls
    SpnnStartKey_i       => SpnnStartKey_i,            -- in  std_logic_vector(31 downto 0);
    SpnnStopKey_i        => SpnnStopKey_i,             -- in  std_logic_vector(31 downto 0);
    SpnnCmdStart_o       => open,                        -- out std_logic;
    SpnnCmdStop_o        => open,                        -- out std_logic;
    SpnnRxMask_i         => SpnnRxMask_i,              -- in  std_logic_vector(31 downto 0);
    SpnnKeysEnable_i     => SpnnCtrl_i(8),             -- in  std_logic;
    SpnnParityErr_o      => SpnnStatus_o(9),           -- out std_logic;
    SpnnRxErr_o          => SpnnStatus_o(8),           -- out std_logic;

             
    -- **********************************************
    -- Source Interfaces
    -- **********************************************

    -- Parallel AER Interface
    -- ----------------------------------------------
    PAER_Addr_i          => i_AuxRxPaerAddr,             -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_i           => i_AuxRxPaerReq,              -- in  std_logic;
    PAER_Ack_o           => i_AuxRxPaerAck,              -- out std_logic;

    -- HSSAER Interface
    -- ----------------------------------------------
    HSSAER_Rx_i          => i_AuxRxHssaer,                -- in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP Wizard Interface
    -- ----------------------------------------------
    GTP_RxUsrClk2_i       => AuxRx_GTP_RxUsrClk2_i,        
    GTP_SoftResetRx_o     => AuxRx_GTP_SoftResetRx_o,                           
    GTP_DataValid_o       => AuxRx_GTP_DataValid_o,                              
    GTP_Rxuserrdy_o       => AuxRx_GTP_Rxuserrdy_o,                                         
    GTP_Rxdata_i          => AuxRx_GTP_Rxdata_i,           
    GTP_Rxchariscomma_i   => AuxRx_GTP_Rxchariscomma_i,    
    GTP_Rxcharisk_i       => AuxRx_GTP_Rxcharisk_i,        
    GTP_Rxdisperr_i       => AuxRx_GTP_Rxdisperr_i,        
    GTP_Rxnotintable_i    => AuxRx_GTP_Rxnotintable_i,     
    GTP_Rxbyteisaligned_i => AuxRx_GTP_Rxbyteisaligned_i,                         
    GTP_Rxbyterealign_i   => AuxRx_GTP_Rxbyterealign_i,                          
    GTP_PllLock_i         => AuxRx_GTP_PllLock_i,                                      
    GTP_PllRefclklost_i   => AuxRx_GTP_PllRefclklost_i,                                        

    -- SpiNNlink
    -- ----------------------------------------------
    SPNN_Data_i           => i_AuxRxData2of7FromSpinnaker,
    SPNN_Ack_o            => i_AuxRxAckToSpinnaker,


    -- **********************************************
    -- Monitor interface
    -- **********************************************
    RxData_o             => AuxRxData,               -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);  i_rxMonSrc(2).idx,      
    RxDataSrcRdy_o       => AuxRxSrcRdy,             -- : out std_logic;                                      i_rxMonSrc(2).vld,      
    RxDataDstRdy_i       => AuxRxDstRdy,             -- : in  std_logic;                                      i_rxMonDst(2).rdy,      

    RxGtpMsg_o           => AuxRx_RxGtpMsg_o,
    RxGtpMsgSrcRdy_o     => AuxRx_RxGtpMsgSrcRdy_o,
    RxGtpMsgDstRdy_i     => AuxRx_RxGtpMsgDstRdy_i,  
       
        
    -- **********************************************
    -- Debug signals
    -- **********************************************
    dbg_PaerDataOk       => open,                         -- out std_logic
    DBG_src_rdy          => open,
    DBG_dst_rdy          => open,
    DBG_err              => open, 
    DBG_run              => open,
    DBG_RX               => open,
    
    DBG_FIFO_0           => open,
    DBG_FIFO_1           => open,
    DBG_FIFO_2           => open,
    DBG_FIFO_3           => open,
    DBG_FIFO_4           => open                         
    );



--Interceptions
---------------------

LEFT_INTERCEPTION_TRUE_gen: if C_RX_LEFT_INTERCEPTION = true generate
begin
    LRxData_o           <= LRxData;
    LRxSrcRdy_o         <= LRxSrcRdy;
    LRxDstRdy           <= LRxDstRdy_i;
    i_rxMonSrc(0).idx   <= LRxBypassData_i;
    i_rxMonSrc(0).vld   <= LRxBypassSrcRdy_i; 
    LRxBypassDstRdy_o   <= i_rxMonDst(0).rdy;
end generate;
LEFT_INTERCEPTION_FALSE_gen: if C_RX_LEFT_INTERCEPTION = false generate
begin
    i_rxMonSrc(0).idx   <= LRxData;
    i_rxMonSrc(0).vld   <= LRxSrcRdy; 
    LRxDstRdy           <= i_rxMonDst(0).rdy;
end generate;


RIGHT_INTERCEPTION_TRUE_gen: if C_RX_RIGHT_INTERCEPTION = true generate
begin
    RRxData_o           <= RRxData;
    RRxSrcRdy_o         <= RRxSrcRdy;
    RRxDstRdy           <= RRxDstRdy_i;
    i_rxMonSrc(1).idx   <= RRxBypassData_i;
    i_rxMonSrc(1).vld   <= RRxBypassSrcRdy_i; 
    RRxBypassDstRdy_o   <= i_rxMonDst(1).rdy;  
end generate;
RIGHT_INTERCEPTION_FALSE_gen: if C_RX_RIGHT_INTERCEPTION = false generate
begin
    i_rxMonSrc(1).idx   <= RRxData;
    i_rxMonSrc(1).vld   <= RRxSrcRdy; 
    RRxDstRdy           <= i_rxMonDst(1).rdy;
end generate;


AUX_INTERCEPTION_TRUE_gen: if C_RX_AUX_INTERCEPTION = true generate
begin
    AuxRxData_o         <= AuxRxData;
    AuxRxSrcRdy_o       <= AuxRxSrcRdy;
    AuxRxDstRdy         <= AuxRxDstRdy_i;
    i_rxMonSrc(2).idx   <= AuxRxBypassData_i;
    i_rxMonSrc(2).vld   <= AuxRxBypassSrcRdy_i; 
    AuxRxBypassDstRdy_o <= i_rxMonDst(2).rdy;  
end generate;
AUX_INTERCEPTION_FALSE_gen: if C_RX_AUX_INTERCEPTION = false generate
begin
    i_rxMonSrc(2).idx   <= AuxRxData;
    i_rxMonSrc(2).vld   <= AuxRxSrcRdy; 
    AuxRxDstRdy         <= i_rxMonDst(2).rdy;
end generate;

--        ToMonDataIn_o        => RRxData_o,               -- : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);  i_rxMonSrc(1).idx, 
--        ToMonSrcRdy_o        => RRxSrcRdy_o,             -- : out std_logic;                                      i_rxMonSrc(1).vld, 
--        ToMonDstRdy_i        => RRxDstRdy_i,             -- : in  std_logic;                                      i_rxMonDst(1).rdy, 
       
--        RRxData_o               : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
--        RRxSrcRdy_o             : out std_logic;
--        RRxDstRdy_i             : in  std_logic;
--        RRxBypassData_i         : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
--        RRxBypassSrcRdy_i       : in  std_logic;
--        RRxBypassDstRdy_o       : out std_logic;
--        --
--        LRxData_o               : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
--        LRxSrcRdy_o             : out std_logic;
--        LRxDstRdy_i             : in  std_logic;
--        LRxBypassData_i         : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
--        LRxBypassSrcRdy_i       : in  std_logic;
--        LRxBypassDstRdy_o       : out std_logic;
--        --
--        AuxRxData_o             : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
--        AuxRxSrcRdy_o           : out std_logic;
--        AuxRxDstRdy_i           : in  std_logic;
--        AuxRxBypassData_i       : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
--        AuxRxBypassSrcRdy_i     : in  std_logic;
--        AuxRxBypassDstRdy_o     : out std_logic;            
        

    u_RxArbiter : neuserial_PAER_arbiter
        generic map (
            C_NUM_CHAN     => 3,
            C_ODATA_WIDTH  => 32
        )
        port map (
            Clk                => Clk_i,                  -- in  std_logic;
            nRst               => nRst,                      -- in  std_logic;

            SplittedPaerSrc_i  => i_rxMonSrc,                -- in  t_PaerSrc_array(0 to C_NUM_CHAN-1);
            SplittedPaerDst_o  => i_rxMonDst,                -- out t_PaerDst_array(0 to C_NUM_CHAN-1);

            PaerData_o         => i_rxMonData,               -- out std_logic_vector(31 downto 0);
            PaerSrcRdy_o       => i_rxMonSrcRdy,             -- out std_logic;
            PaerDstRdy_i       => i_rxMonDstRdy              -- in  std_logic
        );


   
    ---------------------
    -- Loopbacks
    ---------------------

    -- Local Near and Remote Loopback

    i_monData   <= i_seqData   when LocNearLoopback_i = '1' else
                   i_rxMonData;
    i_monSrcRdy <= i_seqSrcRdy when LocNearLoopback_i = '1' else
                   i_rxMonSrcRdy;

    i_seqDstRdy <= i_monDstRdy when LocNearLoopback_i = '1' else
                   '1'         when RemoteLoopback_i  = '1' else
                   i_txSeqDstRdy;

    i_rxMonDstRdy <= i_txSeqDstRdy when RemoteLoopback_i  = '1' else
                     '1'           when LocNearLoopback_i = '1' else
                     i_monDstRdy;

    i_txSeqData   <= i_rxMonData   when RemoteLoopback_i = '1' else
                     i_seqData;
    i_txSeqSrcRdy <= i_rxMonSrcRdy when RemoteLoopback_i = '1' else
                     i_seqSrcRdy;


    -------------------------------
    -- Sequencer & Monitor core
    -------------------------------

    u_CoreMonSeqRR : CoreMonSeqRR
        generic map (
            C_PAER_DSIZE                         => C_PAER_DSIZE,
            TestEnableSequencerNoWait            => c_TestEnableSequencerNoWait,
            TestEnableSequencerToMonitorLoopback => c_TestEnableSequencerToMonitorLoopback,
            EnableMonitorControlsSequencerToo    => c_EnableMonitorControlsSequencerToo
        )
        port map (
            Reset_xRBI              => nRst,                     -- in  std_logic;
            CoreClk_xCI             => Clk_i,                 -- in  std_logic;
            --
            FlushRXFifos_xSI        => FlushRXFifos_i,           -- in  std_logic;
            FlushTXFifos_xSI        => FlushTXFifos_i,           -- in  std_logic;
            --ChipType_xSI            => ChipType,                 -- in  std_logic;
            DmaLength_xDI           => DmaLength_i,              -- in  std_logic_vector(15 downto 0);
            --
            Timing_xSI              => timing_i,                 -- in  time_tick;
            --
            MonInAddr_xDI           => i_monData,                -- in  std_logic_vector(31 downto 0);
            MonInSrcRdy_xSI         => i_monSrcRdy,              -- in  std_logic;
            MonInDstRdy_xSO         => i_monDstRdy,              -- out std_logic;
            --
            SeqOutAddr_xDO          => i_seqData,                -- out std_logic_vector(31 downto 0);
            SeqOutSrcRdy_xSO        => i_seqSrcRdy,              -- out std_logic;
            SeqOutDstRdy_xSI        => i_seqDstRdy,              -- in  std_logic;
            -- Time stamper
            CleanTimer_xSI          => CleanTimer_i,             -- in  std_logic;
            WrapDetected_xSO        => WrapDetected_o,           -- out std_logic;
            FullTimestamp_i         => FullTimestamp_i,          -- in  std_logic;  
            --
            EnableMonitor_xSI       => '1',                      -- in  std_logic;
            CoreReady_xSI           => '1',                      -- in  std_logic;
            --
            TxTSMode_xDI            => TxTSMode_i,               -- in  std_logic_vector(1 downto 0);
            TxTSTimeoutSel_xDI      => TxTSTimeoutSel_i,         -- in  std_logic_vector(3 downto 0);
            TxTSRetrigCmd_xSI       => TxTSRetrigCmd_i,          -- in  std_logic;
            TxTSRearmCmd_xSI        => TxTSRearmCmd_i,           -- in  std_logic;
            TxTSRetrigStatus_xSO    => TxTSRetrigStatus_o,       -- out std_logic;
            TxTSTimeoutCounts_xSO   => TxTSTimeoutCounts_o,      -- out std_logic;
            TxTSMaskSel_xSI         => TxTSMaskSel_i,            -- in  std_logic_vector(1 downto 0);
            --
            FifoCoreDat_xDO         => FifoCoreDat_o,            -- out std_logic_vector(31 downto 0);
            FifoCoreRead_xSI        => FifoCoreRead_i,           -- in  std_logic;
            FifoCoreEmpty_xSO       => FifoCoreEmpty_o,          -- out std_logic;
            FifoCoreAlmostEmpty_xSO => FifoCoreAlmostEmpty_o,    -- out std_logic;
            FifoCoreBurstReady_xSO  => FifoCoreBurstReady_o,     -- out std_logic;
            FifoCoreFull_xSO        => FifoCoreFull_o,           -- out std_logic;
            FifoCoreNumData_o       => FifoCoreNumData_o,        -- out std_logic_vector(10 downto 0);
            --
            CoreFifoDat_xDI         => CoreFifoDat_i,            -- in  std_logic_vector(31 downto 0);
            CoreFifoWrite_xSI       => CoreFifoWrite_i,          -- in  std_logic;
            CoreFifoFull_xSO        => CoreFifoFull_o,           -- out std_logic;
            CoreFifoAlmostFull_xSO  => CoreFifoAlmostFull_o,     -- out std_logic;
            CoreFifoEmpty_xSO       => CoreFifoEmpty_o,          -- out std_logic;
            --
            --BiasFinished_xSO        => BiasFinished,             -- out std_logic;
            --ClockLow_xDI            => ClockLow,                 -- in  natural;
            --LatchTime_xDI           => LatchTime,                -- in  natural;
            --SetupHold_xDI           => SetupHold,                -- in  natural;
            --PrescalerValue_xDI      => PrescalerValue,           -- in  std_logic_vector(31 downto 0);
            --BiasProgPins_xDO        => i_BiasProgPins_xD,        -- out std_logic_vector(7 downto 0);
            ---------------------------------------------------------------------------
            -- Output neurons threshold
            --OutThresholdVal_xDI     => OutThresholdVal           -- in  std_logic_vector(31 downto 0)
            DBG_din             => DBG_din,   
            DBG_wr_en           => DBG_wr_en,       
            DBG_rd_en           => DBG_rd_en,       
            DBG_dout            => DBG_dout,            
            DBG_full            => DBG_full,        
            DBG_almost_full     => DBG_almost_full, 
            DBG_overflow        => DBG_overflow,      
            DBG_empty           => DBG_empty,            
            DBG_almost_empty    => DBG_almost_empty,
            DBG_underflow       => DBG_underflow,   
            DBG_data_count      => DBG_data_count,
            DBG_Timestamp_xD    => DBG_Timestamp_xD,
            DBG_MonInAddr_xD    => DBG_MonInAddr_xD, 
            DBG_MonInSrcRdy_xS  => DBG_MonInSrcRdy_xS,
            DBG_MonInDstRdy_xS  => DBG_MonInDstRdy_xS,
            DBG_RESETFIFO       => DBG_RESETFIFO
 
 
        );




    -----------------------------------------------------------------------------
    -- LEDs
    -----------------------------------------------------------------------------
    LEDo_o <= '1';
    LEDr_o <= '1';
    LEDy_o <= '1';
    
    DBG_CH0_DATA <= i_rxMonSrc(0).idx;
    DBG_CH0_SRDY <= i_rxMonSrc(0).vld;
    DBG_CH0_DRDY <= i_rxMonDst(0).rdy;

    DBG_CH1_DATA <= i_rxMonSrc(1).idx;
    DBG_CH1_SRDY <= i_rxMonSrc(1).vld;
    DBG_CH1_DRDY <= i_rxMonDst(1).rdy;

    DBG_CH2_DATA <= i_rxMonSrc(2).idx;
    DBG_CH2_SRDY <= i_rxMonSrc(2).vld;
    DBG_CH2_DRDY <= i_rxMonDst(2).rdy;
    


end architecture str;

-------------------------------------------------------------------------------
