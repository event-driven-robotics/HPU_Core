------------------------------------------------------------------------
-- Package NSComponents_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of components used inside the
--   NeuSerial IP
--
------------------------------------------------------------------------

-- ------------------------------------------------------------------------------
-- 
--  Revision 1.1:  07/25/2018
--  - Added SpiNNlink capabilities
--    (M. Casti - IIT)
--    
-- ------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

library HPU_lib;
    use HPU_lib.HPUComponents_pkg.all;
    use HPU_lib.aer_pkg.all;
    use HPU_lib.aer_pkg.C_INTERNAL_DSIZE;

package NSComponents_pkg is


component hpu_rx_datapath is
  generic (
    C_FAMILY                  : string                        := "zynquplus"; -- "zynq", "zynquplus" 
    --
    C_OUTPUT_DSIZE             : natural range 1 to 32 := 32;
    C_PAER_DSIZE               : positive              := 20;
    C_HAS_PAER                 : boolean               := true;
    C_HAS_HSSAER               : boolean               := true;
    C_HSSAER_N_CHAN            : natural range 1 to 4  := 4;
    C_HAS_GTP                  : boolean               := true;
    C_GTP_DSIZE                : positive              := 16;
    C_GTP_TXUSRCLK2_PERIOD_NS  : real                  := 6.4; 
    C_GTP_RXUSRCLK2_PERIOD_NS  : real                  := 6.4; 
    C_HAS_SPNNLNK              : boolean               := true;
    C_PSPNNLNK_WIDTH           : natural range 1 to 32 := 32;
    C_SIM_TIME_COMPRESSION     : boolean               := false   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    );
port (
    -- **********************************************
    -- Barecontrol
    -- **********************************************
    -- Resets
    nRst                     : in  std_logic;
    -- System Clock domain
    Clk_i                    : in  std_logic;
    En1Sec_i                 : in  std_logic;
    -- HSSAER Clocks domain
    Clk_hs_p                 : in  std_logic;
    Clk_hs_n                 : in  std_logic;
    Clk_ls_p                 : in  std_logic;
    Clk_ls_n                 : in  std_logic;
 
 
    -- **********************************************
    -- Controls
    -- **********************************************
    --
    -- In case of aux channel the HPU header is 
    -- adapted to what received
    -- ----------------------------------------------
    Aux_Channel_i              : in  std_logic;  

    -- **********************************************
    -- uController Interface
    -- **********************************************

    -- Control input signals
    -- ----------------------------------------------
    PaerFlushFifos_i           : in  std_logic;
    
    -- Control output signals
    -- ----------------------------------------------    
    RxGtpAlignRequest_o        : out std_logic; 

    -- Status signals
    -- ----------------------------------------------
    PaerFifoFull_o             : out std_logic;
    RxSaerStat_o               : out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    RxGtpStat_o                : out t_RxGtpStat;
    RxSpnnlnkStat_o            : out t_RxSpnnlnkStat;
    
    -- GTP Statistics        
    RxGtpDataRate_o            : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpAlignRate_o           : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    RxGtpMsgRate_o             : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpIdleRate_o            : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpEventRate_o           : out std_logic_vector(15 downto 0); -- Count per millisecond 
    RxGtpMessageRate_o         : out std_logic_vector( 7 downto 0); -- Count per millisecond 

    -- Configuration signals
    -- ----------------------------------------------

    -- Source I/F configurations
    EnablePAER_i               : in  std_logic;
    EnableHSSAER_i             : in  std_logic;
    EnableGTP_i                : in  std_logic;
    EnableSPNNLNK_i            : in  std_logic;
    -- PAER
    RxPaerHighBits_i           : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    PaerReqActLevel_i          : in  std_logic;
    PaerAckActLevel_i          : in  std_logic;
    PaerIgnoreFifoFull_i       : in  std_logic;
    PaerAckSetDelay_i          : in  std_logic_vector(7 downto 0);
    PaerSampleDelay_i          : in  std_logic_vector(7 downto 0);
    PaerAckRelDelay_i          : in  std_logic_vector(7 downto 0);
    -- HSSAER
    RxSaerHighBits0_i          : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighBits1_i          : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighBits2_i          : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    RxSaerHighBits3_i          : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    HSSaerChanEn_i             : in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    -- GTP
    RxGtpHighBits_i            : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
    -- SpiNNaker
    SpnnStartKey_i           : in  std_logic_vector(31 downto 0);
    SpnnStopKey_i            : in  std_logic_vector(31 downto 0);
    SpnncmdStart_o           : out std_logic;
    SpnncmdStop_o            : out std_logic;
    SpnnRxMask_i             : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask
    SpnnKeysEnable_i         : in  std_logic;
    SpnnParityErr_o          : out std_logic;
    SpnnRxErr_o              : out std_logic;
            
            
    -- **********************************************
    -- Source Interfaces
    -- **********************************************
 
    -- Parallel AER interface
    -- ----------------------------------------------
    PAER_Addr_i                : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_i                 : in  std_logic;
    PAER_Ack_o                 : out std_logic;

    -- HSSAER interface
    -- ----------------------------------------------
    HSSAER_Rx_i                : in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP Wizard Interface
    -- ----------------------------------------------
    GTP_RxUsrClk2_i            : in  std_logic;   
    GTP_SoftResetRx_o          : out  std_logic;                                          
    GTP_DataValid_o            : out std_logic;                                           
    GTP_Rxuserrdy_o            : out std_logic;                                           
    GTP_Rxdata_i               : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);            
    GTP_Rxchariscomma_i        : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    GTP_Rxcharisk_i            : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    GTP_Rxdisperr_i            : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    GTP_Rxnotintable_i         : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    GTP_Rxbyteisaligned_i      : in  std_logic;                                           
    GTP_Rxbyterealign_i        : in  std_logic;                                           
    GTP_PllLock_i              : in  std_logic;                                           
    GTP_PllRefclklost_i        : in  std_logic;                                         

    -- SpiNNlink
    -- ----------------------------------------------
    SPNN_Data_i                : in  std_logic_vector(6 downto 0); 
    SPNN_Ack_o                 : out std_logic;


    -- **********************************************
    -- Received Data Output
    -- **********************************************
    RxData_o                   : out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
    RxDataSrcRdy_o             : out std_logic;
    RxDataDstRdy_i             : in  std_logic;

    RxGtpMsg_o                 : out std_logic_vector(7 downto 0);
    RxGtpMsgSrcRdy_o           : out std_logic;
    RxGtpMsgDstRdy_i           : in  std_logic;    
    
    
    -- **********************************************
    -- Debug signals
    -- **********************************************
    dbg_PaerDataOk             : out std_logic;
    DBG_src_rdy                : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    DBG_dst_rdy                : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    DBG_err                    : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);  
    DBG_run                    : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    DBG_RX                     : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);

    DBG_FIFO_0                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_1                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_2                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_3                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_4                 : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)            
    );
end component;


component hpu_tx_datapath is
  generic (
    C_FAMILY                  : string                        := "zynquplus"; -- "zynq", "zynquplus" 
    --
    C_INPUT_DSIZE               : natural range 1 to 32 := 32;
    C_PAER_DSIZE                : positive              := 20;
    C_HAS_PAER                  : boolean               := true;
    C_HAS_HSSAER                : boolean               := true;
    C_HSSAER_N_CHAN             : natural range 1 to 4  := 4;
    C_HAS_GTP                   : boolean               := true;
    C_GTP_DSIZE                 : positive              := 16;
    C_GTP_TXUSRCLK2_PERIOD_NS   : real                  := 6.4; 
    C_GTP_RXUSRCLK2_PERIOD_NS   : real                  := 6.4; 
    C_HAS_SPNNLNK               : boolean               := true;
    C_PSPNNLNK_WIDTH            : natural range 1 to 32 := 32;
    C_SIM_TIME_COMPRESSION      : boolean               := false   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
    );
  port (
    -- **********************************************
    -- Barecontrol
    -- **********************************************
    -- Resets
    nRst                    : in  std_logic;
    -- System Clock domain
    Clk_i                   : in  std_logic;
    En1Sec_i                : in  std_logic;
    -- HSSAER Clocks domain
    Clk_ls_p                : in  std_logic;
    Clk_ls_n                : in  std_logic;

    -- **********************************************
    -- uController Interface
    -- **********************************************

    -- Control signals
    -----------------------------
    -- EnableIP_i              : in  std_logic;
    -- PaerFlushFifos_i        : in  std_logic;
    TxGtpAlignRequest_i     : in  std_logic;
    -- TxGtpAutoAlign_i        : in  std_logic;
    -- TxGtpErrorInjection_i   : in  std_logic;
    
    -- Monitor
    TxGtpAlignFlag_o        : out std_logic;   -- Monitor out: sending align    

    -- Status signals
    -----------------------------
    --PaerFifoFull_o          : out std_logic;
    TxSaerStat_o            : out t_TxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    TxSpnnlnkStat_o         : out t_TxSpnnlnkStat;
    -- GTP Statistics        
    TxGtpDataRate_o         : out std_logic_vector(15 downto 0); -- Count per millisecond 
    TxGtpAlignRate_o        : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    TxGtpMsgRate_o          : out std_logic_vector(15 downto 0); -- Count per millisecond 
    TxGtpIdleRate_o         : out std_logic_vector(15 downto 0); -- Count per millisecond 
    TxGtpEventRate_o        : out std_logic_vector(15 downto 0); -- Count per millisecond 
    TxGtpMessageRate_o      : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    
    -- Configuration signals
    -----------------------------
    --
    -- Destination I/F configurations
    EnablePAER_i            : in  std_logic;
    EnableHSSAER_i          : in  std_logic;
    EnableGTP_i             : in  std_logic;
    EnableSPNNLNK_i         : in  std_logic;
    DestinationSwitch_i     : in  std_logic_vector(2 downto 0);
    -- PAER
    --PaerIgnoreFifoFull_i    : in  std_logic;
    PaerReqActLevel_i       : in  std_logic;
    PaerAckActLevel_i       : in  std_logic;
    -- HSSAER
    HSSaerChanEn_i          : in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
    --HSSaerChanCfg_i         : in  t_hssaerCfg_array(C_HSSAER_N_CHAN-1 downto 0);
    -- GTP
    --
    -- SpiNNaker
    SpnnOffloadOn_i         : in  std_logic;
    SpnnOffloadOff_i        : in  std_logic;
    SpnnTxMask_i            : in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    SpnnOffload_o           : out std_logic;
    SpnnLinkTimeout_o       : out std_logic;
    SpnnLinkTimeoutDis_i    : in  std_logic;
    
    -- **********************************************
    -- Transmit Data Input
    -- **********************************************
    TxData_i                : in  std_logic_vector(C_INPUT_DSIZE-1 downto 0);
    TxDataSrcRdy_i          : in  std_logic;
    TxDataDstRdy_o          : out std_logic;
    
    TxGtpMsg_i              : in  std_logic_vector(7 downto 0);
    TxGtpMsgSrcRdy_i        : in  std_logic;
    TxGtpMsgDstRdy_o        : out std_logic;    
      
    -- **********************************************
    -- Destination interfaces
    -- **********************************************
    
    -- Parallel AER Interface
    -- ----------------------------------------------
    PAER_Addr_o             : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_o              : out std_logic;
    PAER_Ack_i              : in  std_logic;

    -- HSSAER Interface
    -- ----------------------------------------------
    HSSAER_Tx_o             : out std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP Wizard Interface
    -- ----------------------------------------------
    GTP_TxUsrClk2_i         : in  std_logic;   
    GTP_SoftResetTx_o       : out  std_logic;                                          
    GTP_DataValid_o         : out std_logic;    
    GTP_Txuserrdy_o         : out std_logic;                                           
    GTP_Txdata_o            : out std_logic_vector(C_GTP_DSIZE-1 downto 0);            
    GTP_Txcharisk_o         : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
    GTP_PllLock_i           : in  std_logic;                                           
    GTP_PllRefclklost_i     : in  std_logic;          
        
    -- SpiNNlink Interface
    -- ----------------------------------------------
    SPNN_Data_o             : out std_logic_vector(6 downto 0);
    SPNN_Ack_i              : in  std_logic
    );
end component hpu_tx_datapath;


component CoreMonSeqRR is
    generic (
        C_FAMILY                              : string := "zynq"; -- "zynq", "zynquplus" 
        --
        C_PAER_DSIZE                         : integer;
        TestEnableSequencerNoWait            : boolean;
        TestEnableSequencerToMonitorLoopback : boolean;
        EnableMonitorControlsSequencerToo    : boolean
    );
    port (
        ---------------------------------------------------------------------------
        -- clock and reset
        Reset_xRBI              : in  std_logic;
        CoreClk_xCI             : in  std_logic;
        AxisClk_xCI             : in  std_logic;
        --
        FlushRXFifos_xSI        : in  std_logic;
        FlushTXFifos_xSI        : in  std_logic;
        ---------------------------------------------------------------------------
        -- controls and settings
        -- ChipType_xSI         : in  std_logic;
        DmaLength_xDI           : in  std_logic_vector(15 downto 0);
        OnlyEvents_i            : in  std_logic;
        --
        ---------------------------------------------------------------------------
        -- Enable per timing
        Timing_xSI          : in  time_tick;
        --
        ---------------------------------------------------------------------------
        -- Input to Monitor
        MonInAddr_xDI           : in  std_logic_vector(31 downto 0);
        MonInSrcRdy_xSI         : in  std_logic;
        MonInDstRdy_xSO         : out std_logic;
        --
        -- Output from Sequencer
        SeqOutAddr_xDO          : out std_logic_vector(31 downto 0);
        SeqOutSrcRdy_xSO        : out std_logic;
        SeqOutDstRdy_xSI        : in  std_logic;
        --
        ---------------------------------------------------------------------------
        -- Time stamper
        CleanTimer_xSI          : in  std_logic;
        WrapDetected_xSO        : out std_logic;
        FullTimestamp_i         : in  std_logic;  
        --
        EnableMonitor_xSI       : in  std_logic;
        CoreReady_xSI           : in  std_logic;
        ---------------------------------------------------------------------------
        -- TX Timestamp
        TxTSMode_xDI            : in  std_logic_vector(1 downto 0);
        TxTSTimeoutSel_xDI      : in  std_logic_vector(3 downto 0);
        TxTSRetrigCmd_xSI       : in  std_logic;
        TxTSRearmCmd_xSI        : in  std_logic;
        TxTSRetrigStatus_xSO    : out std_logic;
        TxTSTimeoutCounts_xSO   : out std_logic;
        TxTSMaskSel_xSI         : in  std_logic_vector(1 downto 0);
        --
        ---------------------------------------------------------------------------
        -- FIFO -> Core
        FifoCoreDat_xDO         : out std_logic_vector(31 downto 0);
        FifoCoreRead_xSI        : in  std_logic;
        FifoCoreEmpty_xSO       : out std_logic;
        FifoCoreAlmostEmpty_xSO : out std_logic;
        FifoCoreBurstReady_xSO  : out std_logic;
        FifoCoreFull_xSO        : out std_logic;
        FifoCoreNumData_o       : out std_logic_vector(10 downto 0);
        --
        -- Core -> FIFO
        CoreFifoDat_xDI         : in  std_logic_vector(31 downto 0);
        CoreFifoWrite_xSI       : in  std_logic;
        CoreFifoFull_xSO        : out std_logic;
        CoreFifoAlmostFull_xSO  : out std_logic;
        CoreFifoEmpty_xSO       : out std_logic;

        ---------------------------------------------------------------------------
        -- BiasGen Controller Output
        --
        --BiasFinished_xSO        : out std_logic;
        --ClockLow_xDI            : in  natural; -- 1   tick
        --LatchTime_xDI           : in  natural; -- 1   tick
        --SetupHold_xDI           : in  natural; -- 100 tick
        --PrescalerValue_xDI      : in  std_logic_vector(31 downto 0);
        --BiasProgPins_xDO        : out std_logic_vector(7 downto 0);
        ---------------------------------------------------------------------------
          -- Output neurons threshold
        --OutThresholdVal_xDI     : in  std_logic_vector(31 downto 0)

        DBG_din             : out std_logic_vector(63 downto 0);     
        DBG_wr_en           : out std_logic;  
        DBG_rd_en           : out std_logic;     
        DBG_dout            : out std_logic_vector(63 downto 0);          
        DBG_full            : out std_logic;    
        DBG_almost_full     : out std_logic;    
        DBG_overflow        : out std_logic;       
        DBG_empty           : out std_logic;           
        DBG_almost_empty    : out std_logic;    
        DBG_underflow       : out std_logic;     
        DBG_data_count      : out std_logic_vector(10 downto 0);
        DBG_Timestamp_xD    : out std_logic_vector(31 downto 0);
        DBG_MonInAddr_xD    : out std_logic_vector(31 downto 0);
        DBG_MonInSrcRdy_xS  : out std_logic;
        DBG_MonInDstRdy_xS  : out std_logic;
        DBG_RESETFIFO       : out std_logic
    
    );
end component CoreMonSeqRR;

    
component neuserial_loopback is
  generic (
    C_PAER_DSIZE          : natural;
    C_RX_HSSAER_N_CHAN    : natural range 1 to 4;
    C_TX_HSSAER_N_CHAN    : natural range 1 to 4
  );
  port (
    Rx1PaerLpbkEn       : in  std_logic;
    Rx2PaerLpbkEn       : in  std_logic;
    Rx3PaerLpbkEn       : in  std_logic;
    Rx1SaerLpbkEn       : in  std_logic;
    Rx2SaerLpbkEn       : in  std_logic;
    Rx3SaerLpbkEn       : in  std_logic;
    XConSerCfg          : in  t_XConCfg;
    RxSpnnLnkLpbkEnSel  : in  std_logic_vector(1 downto 0);
    
    -- Parallel AER
    ExtTxPAER_Addr_o    : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtTxPAER_Req_o     : out std_logic;
    ExtTxPAER_Ack_i     : in  std_logic;
    
    ExtRx1PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtRx1PAER_Req_i    : in  std_logic;
    ExtRx1PAER_Ack_o    : out std_logic;
    
    ExtRx2PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtRx2PAER_Req_i    : in  std_logic;
    ExtRx2PAER_Ack_o    : out std_logic;
    
    ExtRx3PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    ExtRx3PAER_Req_i    : in  std_logic;
    ExtRx3PAER_Ack_o    : out std_logic;
    
    -- HSSAER
    ExtTxHSSAER_Tx_o    : out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    ExtRx1HSSAER_Rx_i   : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    ExtRx2HSSAER_Rx_i   : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    ExtRx3HSSAER_Rx_i   : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    
    -- GTP interface
    --
    -- TBD signals to drive the GTP module
    --
    
    -- SpiNNlink interface
    ExtTx_data_2of7_to_spinnaker_o      : out std_logic_vector(6 downto 0);
    ExtTx_ack_from_spinnaker_i          : in  std_logic;
    ExtRx1_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
    ExtRx1_ack_to_spinnaker_o           : out std_logic;
    ExtRx2_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
    ExtRx2_ack_to_spinnaker_o           : out std_logic;
    ExtRx3_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
    ExtRx3_ack_to_spinnaker_o           : out std_logic;
    
    -- Parallel AER
    CoreTxPAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreTxPAER_Req_i    : in  std_logic;
    CoreTxPAER_Ack_o    : out std_logic;
    
    CoreRx1PAER_Addr_o  : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreRx1PAER_Req_o   : out std_logic;
    CoreRx1PAER_Ack_i   : in  std_logic;
    
    CoreRx2PAER_Addr_o  : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreRx2PAER_Req_o   : out std_logic;
    CoreRx2PAER_Ack_i   : in  std_logic;
    
    CoreRx3PAER_Addr_o  : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    CoreRx3PAER_Req_o   : out std_logic;
    CoreRx3PAER_Ack_i   : in  std_logic;
    
    -- HSSAER
    CoreTxHSSAER_Tx_i   : in  std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    CoreRx1HSSAER_Rx_o  : out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    CoreRx2HSSAER_Rx_o  : out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    CoreRx3HSSAER_Rx_o  : out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    
    -- GTP interface
    --
    -- TBD signals to drive the GTP module
    --
    
    -- SpiNNlink interface
    CoreTx_data_2of7_to_spinnaker_i      : in  std_logic_vector(6 downto 0);
    CoreTx_ack_from_spinnaker_o          : out std_logic;
    CoreRx1_data_2of7_from_spinnaker_o   : out std_logic_vector(6 downto 0); 
    CoreRx1_ack_to_spinnaker_i           : in  std_logic;
    CoreRx2_data_2of7_from_spinnaker_o   : out std_logic_vector(6 downto 0); 
    CoreRx2_ack_to_spinnaker_i           : in  std_logic;
    CoreRx3_data_2of7_from_spinnaker_o   : out std_logic_vector(6 downto 0); 
    CoreRx3_ack_to_spinnaker_i           : in  std_logic
    );
end component neuserial_loopback;


    --component neuserial_tx_splitter is
    --    generic (
    --        C_NUM_CHAN_SAER_TX : natural range 1 to 4 := 1
    --    );
    --    port (
    --        Clk                : in  std_logic;
    --        nRst               : in  std_logic;
    --        --
    --        SplitCfg           : in  t_SplitterCfg;
    --        --
    --        PaerDataIn         : in  std_logic_vector(31 downto 0);
    --        PaerSrcRdy         : in  std_logic;
    --        PaerDstRdy         : out std_logic;
    --        --
    --        SplittedPaerSrc    : out t_PaerSrc_array(0 to C_NUM_CHAN_SAER_TX-1);
    --        SplittedPaerDst    : in  t_PaerDst_array(0 to C_NUM_CHAN_SAER_TX-1)
    --    );
    --end component neuserial_tx_splitter;


    --component neuserial_rx_arbiter is
    --    generic (
    --        C_NUM_CHAN_SAER_RX : natural range 1 to 4 := 1
    --    );
    --    port (
    --        Clk                : in  std_logic;
    --        nRst               : in  std_logic;
    --
    --        ArbCfg             : in  t_ArbiterCfg;
    --
    --        PaerDataOut        : out std_logic_vector(31 downto 0);
    --        PaerSrcRdy         : out std_logic;
    --        PaerDstRdy         : in  std_logic;
    --
    --        MergedPaerSrc      : in  t_PaerSrc_array(0 to C_NUM_CHAN_SAER_RX-1);
    --        MergedPaerDst      : out t_PaerDst_array(0 to C_NUM_CHAN_SAER_RX-1)
    --    );
    --end component neuserial_rx_arbiter;


    --component neuserial_par_xcon is
    --    generic (
    --        C_NUM_CHAN_SAER_RX : natural range 1 to 4 := 1;
    --        C_NUM_CHAN_SAER_TX : natural range 1 to 4 := 1
    --    );
    --    port (
    --        XConParCfg         : in  t_XConCfg;
    --        -- Interfaces towards core
    --        Tx_FromCoreSrc     : in  t_PaerSrc_array(0 to C_NUM_CHAN_SAER_TX-1);
    --        Tx_FromCoreDst     : out t_PaerDst_array(0 to C_NUM_CHAN_SAER_TX-1);
    --        Rx_ToCoreSrc       : out t_PaerSrc_array(0 to C_NUM_CHAN_SAER_RX-1);
    --        Rx_ToCoreDst       : in  t_PaerDst_array(0 to C_NUM_CHAN_SAER_RX-1);
    --        -- Interfaces towards extern
    --        Tx_ToExtSrc        : out t_PaerSrc_array(0 to C_NUM_CHAN_SAER_TX-1);
    --        Tx_ToExtDst        : in  t_PaerDst_array(0 to C_NUM_CHAN_SAER_TX-1);
    --        Rx_FromExtSrc      : in  t_PaerSrc_array(0 to C_NUM_CHAN_SAER_RX-1);
    --        Rx_FromExtDst      : out t_PaerDst_array(0 to C_NUM_CHAN_SAER_RX-1)
    --    );
    --end component neuserial_par_xcon;


    --component neuserial_ser_xcon is
    --    generic (
    --        C_NUM_CHAN_SAER_RX  : natural range 1 to 4 := 1;
    --        C_NUM_CHAN_SAER_TX  : natural range 1 to 4 := 1
    --    );
    --    port (
    --        XConSerCfg                     : in  t_XConCfg;
    --        -- Interfaces towards core
    --        Tx_FromCore                    : in  std_logic_vector(0 to C_NUM_CHAN_SAER_TX-1);
    --        Rx_ToCore                      : out std_logic_vector(0 to C_NUM_CHAN_SAER_RX-1);
    --        -- Interfaces towards extern
    --        Tx_ToExt                       : out std_logic_vector(0 to C_NUM_CHAN_SAER_TX-1);
    --        Rx_FromExt                     : in  std_logic_vector(0 to C_NUM_CHAN_SAER_RX-1)
    --    );
    --end component neuserial_ser_xcon;

    
    --component serialize_req is
    --    generic (
    --        C_DATA_WIDTH : natural;         -- Number of input request lines
    --        C_IDX_WIDTH  : natural;         -- Width of the index bus in output (should be at least log2(C_DATA_WIDTH)
    --        C_FIFO_DEPTH : natural          -- Number of cells of the FIFO
    --    );
    --    port (
    --        Clk         : in  std_logic;
    --        nRst        : in  std_logic;
    --        ReqVect_i   : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --        Pop_i       : in  std_logic;
    --        Idx_o       : out std_logic_vector(C_IDX_WIDTH-1 downto 0);
    --        Empty_o     : out std_logic;
    --        Full_o      : out std_logic;
    --        Underflow_o : out std_logic;
    --        Overflow_o  : out std_logic
    --    );
    --end component serialize_req;


 end package NSComponents_pkg;



