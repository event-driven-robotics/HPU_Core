------------------------------------------------------------------------
-- Package HPUComponents_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of components used inside the
--   Head Processing Unit core
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
    use ieee.numeric_std.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;


package HPUComponents_pkg is

type time_tick is record
    en100ns               : std_logic;
    en1us                 : std_logic;
    en10us                : std_logic;
    en100us               : std_logic;
    en1ms                 : std_logic;
    en10ms                : std_logic;
    en100ms               : std_logic;
    en1s                  : std_logic;
    end record time_tick;

    component neuserial_core is
        generic (
            C_PAER_DSIZE            : natural range 1 to 29;
            C_RX_HAS_PAER           : boolean;
            C_RX_HAS_HSSAER         : boolean;
            C_RX_HSSAER_N_CHAN      : natural range 1 to 4;
            C_RX_HAS_GTP            : boolean;
            C_RX_HAS_SPNNLNK        : boolean;
            C_TX_HAS_PAER           : boolean;
            C_TX_HAS_HSSAER         : boolean;
            C_TX_HSSAER_N_CHAN      : natural range 1 to 4;
            C_TX_HAS_GTP            : boolean;
			C_TX_HAS_SPNNLNK        : boolean;
            C_PSPNNLNK_WIDTH        : natural range 1 to 32
        );
        port (
            --
            -- Clocks & Reset
            ---------------------
            nRst              : in  std_logic;
            Clk_core          : in  std_logic;
            ClkLS_p           : in  std_logic;
            ClkLS_n           : in  std_logic;
            ClkHS_p           : in  std_logic;
            ClkHS_n           : in  std_logic;
            
            --
            -- Enable per timing
            ---------------------
            Timing_i          : in  time_tick;
            
            --
            -- TX DATA PATH
            ---------------------
            -- Parallel AER
            Tx_PAER_Addr_o    : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
            Tx_PAER_Req_o     : out std_logic;
            Tx_PAER_Ack_i     : in  std_logic;
            -- HSSAER channels
            Tx_HSSAER_o       : out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
            -- GTP lines

            --
            -- RX Left DATA PATH
            ---------------------
            -- Parallel AER
            LRx_PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            LRx_PAER_Req_i    : in  std_logic;
            LRx_PAER_Ack_o    : out std_logic;
            -- HSSAER channels
            LRx_HSSAER_i      : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
            -- GTP lines

            --
            -- RX Right DATA PATH
            ---------------------
            -- Parallel AER
            RRx_PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            RRx_PAER_Req_i    : in  std_logic;
            RRx_PAER_Ack_o    : out std_logic;
            -- HSSAER channels
            RRx_HSSAER_i      : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
            -- GTP lines

            --
            -- Aux DATA PATH
            ---------------------
            -- Parallel AER
            AuxRx_PAER_Addr_i : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            AuxRx_PAER_Req_i  : in  std_logic;
            AuxRx_PAER_Ack_o  : out std_logic;
            -- HSSAER channels 
            AuxRx_HSSAER_i    : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            
            --
            -- SpiNNlink DATA PATH
            ---------------------
            -- input SpiNNaker link interface
            LRx_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
            LRx_ack_to_spinnaker_o           : out std_logic;
            RRx_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
            RRx_ack_to_spinnaker_o           : out std_logic;
            AuxRx_data_2of7_from_spinnaker_i : in  std_logic_vector(6 downto 0); 
            AuxRx_ack_to_spinnaker_o         : out std_logic;
            -- output SpiNNaker link interface
            Tx_data_2of7_to_spinnaker_o      : out std_logic_vector(6 downto 0);
            Tx_ack_from_spinnaker_i          : in  std_logic;
    
            --
            -- FIFOs interfaces
            ---------------------
            FifoCoreDat_o         : out std_logic_vector(31 downto 0);
            FifoCoreRead_i        : in  std_logic;
            FifoCoreEmpty_o       : out std_logic;
            FifoCoreAlmostEmpty_o : out std_logic;
            FifoCoreBurstReady_o  : out std_logic;
            FifoCoreFull_o        : out std_logic;
            FifoCoreNumData_o     : out std_logic_vector(10 downto 0);
            --
            CoreFifoDat_i         : in  std_logic_vector(31 downto 0);
            CoreFifoWrite_i       : in  std_logic;
            CoreFifoFull_o        : out std_logic;
            CoreFifoAlmostFull_o  : out std_logic;
            CoreFifoEmpty_o       : out std_logic;

            -----------------------------------------------------------------------
            -- uController Interface
            ---------------------
            -- Control
            CleanTimer_i            : in  std_logic;
            FlushRXFifos_i          : in  std_logic;
            FlushTXFifos_i          : in  std_logic;        
            --TxEnable_i              : in  std_logic;
            --TxPaerFlushFifos_i      : in  std_logic;
            --LRxEnable_i             : in  std_logic;
            --RRxEnable_i             : in  std_logic;
            LRxPaerFlushFifos_i     : in  std_logic;
            RRxPaerFlushFifos_i     : in  std_logic;
            AuxRxPaerFlushFifos_i   : in  std_logic;
            FullTimestamp_i         : in  std_logic;

            -- Configurations
            DmaLength_i             : in  std_logic_vector(15 downto 0);
            RemoteLoopback_i        : in  std_logic;
            LocNearLoopback_i       : in  std_logic;
            LocFarLPaerLoopback_i   : in  std_logic;
            LocFarRPaerLoopback_i   : in  std_logic;
            LocFarAuxPaerLoopback_i : in  std_logic;
            LocFarLSaerLoopback_i   : in  std_logic;
            LocFarRSaerLoopback_i   : in  std_logic;
            LocFarAuxSaerLoopback_i : in  std_logic;
            LocFarSaerLpbkCfg_i     : in  t_XConCfg;
            LocFarSpnnLnkLoopbackSel_i : in  std_logic_vector(1 downto 0);

            TxPaerEn_i              : in  std_logic;
            TxHSSaerEn_i            : in  std_logic;
            TxGtpEn_i               : in  std_logic;
            TxSpnnLnkEn_i           : in  std_logic;
            TxDestSwitch_i          : in  std_logic_vector(2 downto 0);
            --TxPaerIgnoreFifoFull_i  : in  std_logic;
            TxPaerReqActLevel_i     : in  std_logic;
            TxPaerAckActLevel_i     : in  std_logic;
            TxSaerChanEn_i          : in  std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
            --TxSaerChanCfg_i         : in  t_hssaerCfg_array(C_TX_HSSAER_N_CHAN-1 downto 0);

            -- TX Timestamp
            TxTSMode_i                     : in  std_logic_vector(1 downto 0);
            TxTSTimeoutSel_i               : in  std_logic_vector(3 downto 0);
            TxTSRetrigCmd_i                : in  std_logic;
            TxTSRearmCmd_i                 : in  std_logic;
            TxTSRetrigStatus_o             : out std_logic;
            TxTSTimeoutCounts_o            : out std_logic;
            TxTSMaskSel_i                  : in  std_logic_vector(1 downto 0);
            
            --
            LRxPaerEn_i             : in  std_logic;
            RRxPaerEn_i             : in  std_logic;
            AuxRxPaerEn_i           : in  std_logic;
            LRxHSSaerEn_i           : in  std_logic;
            RRxHSSaerEn_i           : in  std_logic;
            AuxRxHSSaerEn_i         : in  std_logic;
            LRxGtpEn_i              : in  std_logic;
            RRxGtpEn_i              : in  std_logic;
            AuxRxGtpEn_i            : in  std_logic;
            LRxSpnnLnkEn_i          : in  std_logic;
            RRxSpnnLnkEn_i          : in  std_logic;
            AuxRxSpnnLnkEn_i        : in  std_logic;
            LRxSaerChanEn_i         : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            RRxSaerChanEn_i         : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            AuxRxSaerChanEn_i       : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            RxPaerReqActLevel_i     : in  std_logic;
            RxPaerAckActLevel_i     : in  std_logic;
            RxPaerIgnoreFifoFull_i  : in  std_logic;
            RxPaerAckSetDelay_i     : in  std_logic_vector(7 downto 0);
            RxPaerSampleDelay_i     : in  std_logic_vector(7 downto 0);
            RxPaerAckRelDelay_i     : in  std_logic_vector(7 downto 0);

            -- Status
            WrapDetected_o          : out   std_logic;

            --TxPaerFifoFull_o        : out std_logic;
            TxSaerStat_o            : out t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);

            LRxPaerFifoFull_o       : out std_logic;
            RRxPaerFifoFull_o       : out std_logic;
            AuxRxPaerFifoFull_o     : out std_logic;
            LRxSaerStat_o           : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
            RRxSaerStat_o           : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
            AUXRxSaerStat_o         : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
            
            --
            -- SPiNNaker
            ---------------------        
            TxSpnnlnkStat_o         : out t_TxSpnnlnkStat;
            LRxSpnnlnkStat_o        : out t_RxSpnnlnkStat;
            RRxSpnnlnkStat_o        : out t_RxSpnnlnkStat;
            AuxRxSpnnlnkStat_o      : out t_RxSpnnlnkStat;
        
            Spnn_start_key_i        : in  std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command key
            Spnn_stop_key_i         : in  std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command key
            Spnn_tx_mask_i          : in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
            Spnn_rx_mask_i          : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
            Spnn_ctrl_i             : in  std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
            Spnn_status_o           : out std_logic_vector(31 downto 0);  -- SpiNNaker Status Register  
            
            --
            -- LED drivers
            ---------------------
            LEDo_o            : out std_logic;
            LEDr_o            : out std_logic;
            LEDy_o            : out std_logic;

            --
            -- DEBUG SIGNALS
            ---------------------
            DBG_dataOk        : out std_logic;
            
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
            DBG_CH0_DATA        : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_CH0_SRDY        : out std_logic;   
            DBG_CH0_DRDY        : out std_logic;        
            DBG_CH1_DATA        : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_CH1_SRDY        : out std_logic;   
            DBG_CH1_DRDY        : out std_logic;        
            DBG_CH2_DATA        : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_CH2_SRDY        : out std_logic;   
            DBG_CH2_DRDY        : out std_logic;        
            DBG_Timestamp_xD    : out std_logic_vector(31 downto 0);        
            DBG_MonInAddr_xD    : out std_logic_vector(31 downto 0);
            DBG_MonInSrcRdy_xS  : out std_logic;
            DBG_MonInDstRdy_xS  : out std_logic;
            DBG_RESETFIFO       : out std_logic;
            DBG_src_rdy         : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            DBG_dst_rdy         : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            DBG_err             : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);  
            DBG_run             : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            DBG_RX              : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
            DBG_FIFO_0          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_FIFO_1          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_FIFO_2          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_FIFO_3          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
            DBG_FIFO_4          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)                        
                
        );
    end component neuserial_core;


    component neuserial_axilite is
    generic (
            C_DATA_WIDTH : integer range 16 to 32;                  -- HPU_libs only when  C_DATA_WIDTH = 32 !!!
    C_ADDR_WIDTH : integer range  5 to 32;
    C_SLV_DWIDTH : integer := 32;                           -- HPU_libs only when  C_SLV_DWIDTH = 32 !!!
    -- HSSAER lines parameters
    C_RX_HAS_PAER              : boolean;
    C_RX_HAS_GTP               : boolean;
    C_RX_HAS_SPNNLNK           : boolean;
    C_RX_HAS_HSSAER            : boolean;
    C_RX_HSSAER_N_CHAN         : natural range 1 to 4;
    C_TX_HAS_PAER              : boolean;
    C_TX_HAS_GTP               : boolean;
    C_TX_HAS_SPNNLNK           : boolean;
    C_TX_HAS_HSSAER            : boolean;
    C_TX_HSSAER_N_CHAN         : natural range 1 to 4
);
port (
    -- ADD USER PORTS BELOW THIS LINE ------------------

    -- Interrupt
    -------------------------
    RawInterrupt_i                 : in  std_logic_vector(15 downto 0);
    InterruptLine_o                : out std_logic;

    -- RX Buffer Reg
    -------------------------
    ReadRxBuffer_o                 : out std_logic;
    RxDataBuffer_i                 : in  std_logic_vector(31 downto 0);
    RxTimeBuffer_i                 : in  std_logic_vector(31 downto 0);
    RxFifoThresholdNumData_o       : out std_logic_vector(10 downto 0);
    -- Tx Buffer Reg
    -------------------------
    WriteTxBuffer_o                : out std_logic;
    TxDataBuffer_o                 : out std_logic_vector(31 downto 0);

    
    -- Controls
    -------------------------
    DMA_is_running_i               : in  std_logic;
    EnableDMAIf_o                  : out std_logic;
    ResetStream_o                  : out std_logic;
    DmaLength_o                    : out std_logic_vector(15 downto 0);
    DMA_test_mode_o                : out std_logic;
    fulltimestamp_o                : out std_logic;

    CleanTimer_o                   : out std_logic;
    FlushRXFifos_o                 : out std_logic;
    FlushTXFifos_o                 : out std_logic;
    LatTlast_o                     : out std_logic;
    TlastCnt_i                     : in  std_logic_vector(31 downto 0);
    TDataCnt_i                     : in  std_logic_vector(31 downto 0);
    TlastTO_o                      : out std_logic_vector(31 downto 0);
    TlastTOwritten_o               : out std_logic;

    --TxEnable_o                     : out std_logic;
    --TxPaerFlushFifos_o             : out std_logic;
    --LRxEnable_o                    : out std_logic;
    --RRxEnable_o                    : out std_logic;
    LRxPaerFlushFifos_o            : out std_logic;
    RRxPaerFlushFifos_o            : out std_logic;
    AuxRxPaerFlushFifos_o          : out std_logic;

    -- Configurations
    -------------------------
    DefLocFarLpbk_i                : in  std_logic;
    DefLocNearLpbk_i               : in  std_logic;
    --EnableLoopBack_o               : out std_logic;
    RemoteLoopback_o               : out std_logic;
    LocNearLoopback_o              : out std_logic;
    LocFarLPaerLoopback_o          : out std_logic;
    LocFarRPaerLoopback_o          : out std_logic;
    LocFarAuxPaerLoopback_o        : out std_logic;
    LocFarLSaerLoopback_o          : out std_logic;
    LocFarRSaerLoopback_o          : out std_logic;
    LocFarAuxSaerLoopback_o        : out std_logic;
    LocFarSaerLpbkCfg_o            : out t_XConCfg;
    LocFarSpnnLnkLoopbackSel_o     : out  std_logic_vector(1 downto 0);
                                   
    --EnableIp_o                     : out std_logic;
                                   
    TxPaerEn_o                     : out std_logic;
    TxHSSaerEn_o                   : out std_logic;
    TxGtpEn_o                      : out std_logic;
    TxSpnnLnkEn_o                  : out std_logic;
    TxDestSwitch_o                 : out std_logic_vector(2 downto 0);
    --TxPaerIgnoreFifoFull_o         : out std_logic;
    TxPaerReqActLevel_o            : out std_logic;
    TxPaerAckActLevel_o            : out std_logic;
    TxSaerChanEn_o                 : out std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);

-- TX Timestamp
    TxTSMode_o                     : out std_logic_vector(1 downto 0);
    TxTSTimeoutSel_o               : out std_logic_vector(3 downto 0);
    TxTSRetrigCmd_o                : out std_logic;
    TxTSRearmCmd_o                 : out std_logic;
    TxTSRetrigStatus_i             : in  std_logic;
    TxTSTimeoutCounts_i            : in  std_logic;
    TxTSMaskSel_o                  : out std_logic_vector(1 downto 0);

--
    LRxPaerEn_o                    : out std_logic;
    RRxPaerEn_o                    : out std_logic;
    AUXRxPaerEn_o                  : out std_logic;
    LRxHSSaerEn_o                  : out std_logic;
    RRxHSSaerEn_o                  : out std_logic;
    AUXRxHSSaerEn_o                : out std_logic;
    LRxGtpEn_o                     : out std_logic;
    RRxGtpEn_o                     : out std_logic;
    AUXRxGtpEn_o                   : out std_logic;
    LRxSpnnLnkEn_o                 : out std_logic;
    RRxSpnnLnkEn_o                 : out std_logic;
    AUXRxSpnnLnkEn_o               : out std_logic;
    LRxSaerChanEn_o                : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerChanEn_o                : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerChanEn_o              : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    RxPaerReqActLevel_o            : out std_logic;
    RxPaerAckActLevel_o            : out std_logic;
    RxPaerIgnoreFifoFull_o         : out std_logic;
    RxPaerAckSetDelay_o            : out std_logic_vector(7 downto 0);
    RxPaerSampleDelay_o            : out std_logic_vector(7 downto 0);
    RxPaerAckRelDelay_o            : out std_logic_vector(7 downto 0);
                                   
    -- Status                      
    -------------------------
    WrapDetected_i                 : in  std_logic;

    TxSaerStat_i                   : in  t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
    LRxSaerStat_i                  : in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSaerStat_i                  : in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSaerStat_i                : in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    TxSpnnlnkStat_i                : in  t_TxSpnnlnkStat;
    LRxSpnnlnkStat_i               : in  t_RxSpnnlnkStat;
    RRxSpnnlnkStat_i               : in  t_RxSpnnlnkStat;
    AuxRxSpnnlnkStat_i             : in  t_RxSpnnlnkStat;
                                   
    -- Spinnaker                     
    -------------------------
    Spnn_start_key_o               : out std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command 
    Spnn_stop_key_o                : out std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command  
    Spnn_tx_mask_o                 : out std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    Spnn_rx_mask_o                 : out std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
    Spnn_ctrl_o                    : out std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
    Spnn_status_i                  : in  std_logic_vector(31 downto 0);  -- SpiNNaker Status Register  
    
    -- DEBUG
    -------------------------
    DBG_CTRL_reg                   : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DBG_ctrl_rd                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);

    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    -- Axi lite I-f
    S_AXI_ACLK                     : in  std_logic;
    S_AXI_ARESETN                  : in  std_logic;
    S_AXI_AWADDR                   : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID                  : in  std_logic;
    S_AXI_WDATA                    : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB                    : in  std_logic_vector(3 downto 0);
    S_AXI_WVALID                   : in  std_logic;
    S_AXI_BREADY                   : in  std_logic;
    S_AXI_ARADDR                   : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID                  : in  std_logic;
    S_AXI_RREADY                   : in  std_logic;
    S_AXI_ARREADY                  : out std_logic;
    S_AXI_RDATA                    : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP                    : out std_logic_vector(1 downto 0);
    S_AXI_RVALID                   : out std_logic;
    S_AXI_WREADY                   : out std_logic;
    S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
    S_AXI_BVALID                   : out std_logic;
    S_AXI_AWREADY                  : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
        );
    end component neuserial_axilite;


    component neuserial_axistream is
        generic (
            C_NUMBER_OF_INPUT_WORDS : natural := 2048;
            C_DEBUG                 : boolean := false
        );
        port (
            Clk                    : in  std_logic;
            nRst                   : in  std_logic;
            --
            DMA_test_mode_i        : in  std_logic;
            EnableAxistreamIf_i    : in  std_logic;
            DMA_is_running_o       : out std_logic;
            DmaLength_i            : in  std_logic_vector(15 downto 0);
            ResetStream_i          : in  std_logic;
            LatTlat_i              : in  std_logic;
            TlastCnt_o             : out std_logic_vector(31 downto 0);
            TlastTO_i              : in  std_logic_vector(31 downto 0);
            TlastTOwritten_i       : in  std_logic;
            TDataCnt_o             : out std_logic_vector(31 downto 0);
            -- From Fifo to core/dma
            FifoCoreDat_i          : in  std_logic_vector(31 downto 0);
            FifoCoreRead_o         : out std_logic;
            FifoCoreEmpty_i        : in  std_logic;
            FifoCoreBurstReady_i   : in  std_logic;
            FifoCoreLastData_i     : in  std_logic;
            -- From core/dma to Fifo
            CoreFifoDat_o          : out std_logic_vector(31 downto 0);
            CoreFifoWrite_o        : out std_logic;
            CoreFifoFull_i         : in  std_logic;
            -- Axi Stream I/f
            S_AXIS_TREADY          : out std_logic;
            S_AXIS_TDATA           : in  std_logic_vector(31 downto 0);
            S_AXIS_TLAST           : in  std_logic;
            S_AXIS_TVALID          : in  std_logic;
            M_AXIS_TVALID          : out std_logic;
            M_AXIS_TDATA           : out std_logic_vector(31 downto 0);
            M_AXIS_TLAST           : out std_logic;
            M_AXIS_TREADY          : in  std_logic

        );
    end component neuserial_axistream;


    component time_machine is
       generic ( 
            SIM_TIME_COMPRESSION_g : boolean := FALSE; -- Se "TRUE", la simulazione viene "compressa": i clock enable non seguono le tempistiche reali
            INIT_DELAY             : natural := 32     -- Ritardo dal rilascio del reset all'impulso di "init"
            );
       port (
            -- Clock in port
            CLK_100M_i           : in  std_logic;  -- Ingresso 100 MHz
            -- Enable ports
            EN100NS_100_o        : out std_logic;	-- Clock enable a 100 ns
            EN1US_100_o          : out std_logic;	-- Clock enable a 1 us
            EN10US_100_o         : out std_logic;	-- Clock enable a 10 us
            EN100US_100_o        : out std_logic;	-- Clock enable a 100 us
            EN1MS_100_o          : out std_logic;	-- Clock enable a 1 ms
            EN10MS_100_o         : out std_logic;	-- Clock enable a 10 ms
            EN100MS_100_o        : out std_logic;	-- Clock enable a 100 ms
            EN1S_100_o           : out std_logic;	-- Clock enable a 1 s
            -- Reset output port 
            RESYNC_CLEAR_N_o     : out std_logic; -- Clear resincronizzato
            INIT_RESET_100_o     : out std_logic;	-- Reset sincrono a 32 colpi di clock dal Clear resincronizzato (logica positiva)
            INIT_RESET_N_100_o   : out std_logic;	-- Reset sincrono a 32 colpi di clock dal Clear resincronizzato (logica negativa)
            -- Status and control signals
            CLEAR_N_i            : in  std_logic   -- Clear asincrono che reinizializza le macchine di timing
            );
       end component;
       
       
end package HPUComponents_pkg;
