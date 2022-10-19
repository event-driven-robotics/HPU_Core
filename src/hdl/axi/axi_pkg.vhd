library ieee;
  use ieee.std_logic_1164.all;

library datapath;
  use datapath.constants.all;
  use datapath.types.all;
  use datapath.components.all;
  
library swissknife;
  use swissknife.types.all;
  
package components is

  component axilite is
    generic (
      C_DATA_WIDTH                    : integer range 16 to 32  := 32;   -- HPU_libs only when  C_DATA_WIDTH = 32 !!!
      C_ADDR_WIDTH                    : integer range  5 to 32  :=  8;
      C_SLV_DWIDTH                    : integer                 := 32;   -- HPU_libs only when  C_SLV_DWIDTH = 32 !!!
      C_RX_L_HAS_PAER                 : boolean                 := true;
      C_RX_R_HAS_PAER                 : boolean                 := true;
      C_RX_A_HAS_PAER                 : boolean                 := true;
      C_RX_L_HAS_HSSAER               : boolean                 := true;
      C_RX_R_HAS_HSSAER               : boolean                 := true;
      C_RX_A_HAS_HSSAER               : boolean                 := true;
      C_RX_HSSAER_N_CHAN              : natural range 1 to 4    := 4;
      C_RX_L_HAS_GTP                  : boolean                 := true;
      C_RX_R_HAS_GTP                  : boolean                 := true;
      C_RX_A_HAS_GTP                  : boolean                 := true;
      C_RX_L_HAS_SPNNLNK              : boolean                 := true;
      C_RX_R_HAS_SPNNLNK              : boolean                 := true;
      C_RX_A_HAS_SPNNLNK              : boolean                 := true;
      --
      C_TX_HAS_PAER                   : boolean                 := true;
      C_TX_HAS_HSSAER                 : boolean                 := true;
      C_TX_HSSAER_N_CHAN              : natural range 1 to 4    := 4;
      C_TX_HAS_GTP                    : boolean                 := true;
      C_TX_HAS_SPNNLNK                : boolean                 := true
      );
      port (
      
      -- Interrupt
      -------------------------
      RawInterrupt_i                  : in  std_logic_vector(15 downto 0);
      InterruptLine_o                 : out std_logic;
      
      -- RX Buffer Reg
      -------------------------
      ReadRxBuffer_o                  : out std_logic;
      RxDataBuffer_i                  : in  std_logic_vector(31 downto 0);
      RxTimeBuffer_i                  : in  std_logic_vector(31 downto 0);
      RxFifoThresholdNumData_o        : out std_logic_vector(10 downto 0);
      -- Tx Buffer Reg
      -------------------------
      WriteTxBuffer_o                 : out std_logic;
      TxDataBuffer_o                  : out std_logic_vector(31 downto 0);
      
      
      -- Controls
      -------------------------
      DMA_is_running_i                : in  std_logic;
      EnableDMAIf_o                   : out std_logic;
      ResetStream_o                   : out std_logic;
      DmaLength_o                     : out std_logic_vector(15 downto 0);
      DMA_test_mode_o                 : out std_logic;
      OnlyEventsRx_o                  : out std_logic;
      OnlyEventsTx_o                  : out std_logic;
      fulltimestamp_o                 : out std_logic;
      
      CleanTimer_o                    : out std_logic;
      FlushRXFifos_o                  : out std_logic;
      FlushTXFifos_o                  : out std_logic;
      LatTlast_o                      : out std_logic;
      TlastCnt_i                      : in  std_logic_vector(31 downto 0);
      TDataCnt_i                      : in  std_logic_vector(31 downto 0);
      TlastTO_o                       : out std_logic_vector(31 downto 0);
      TlastTOwritten_o                : out std_logic;
      
      --TxEnable_o                     : out std_logic;
      --TxPaerFlushFifos_o             : out std_logic;
      --LRxEnable_o                    : out std_logic;
      --RRxEnable_o                    : out std_logic;
      LRxPaerFlushFifos_o             : out std_logic;
      RRxPaerFlushFifos_o             : out std_logic;
      AuxRxPaerFlushFifos_o           : out std_logic;
      
      -- Configurations
      -------------------------
      DefLocFarLpbk_i                 : in  std_logic;
      DefLocNearLpbk_i                : in  std_logic;
      --EnableLoopBack_o               : out std_logic;
      RemoteLoopback_o                : out std_logic;
      LocNearLoopback_o               : out std_logic;
      LocFarLPaerLoopback_o           : out std_logic;
      LocFarRPaerLoopback_o           : out std_logic;
      LocFarAuxPaerLoopback_o         : out std_logic;
      LocFarLSaerLoopback_o           : out std_logic;
      LocFarRSaerLoopback_o           : out std_logic;
      LocFarAuxSaerLoopback_o         : out std_logic;
      LocFarSaerLpbkCfg_o             : out t_XConCfg;
      LocFarSpnnLnkLoopbackSel_o      : out  std_logic_vector(1 downto 0);
                                    
      --EnableIp_o                     : out std_logic;
                                    
      TxPaerEn_o                      : out std_logic;
      TxHSSaerEn_o                    : out std_logic;
      TxGtpEn_o                       : out std_logic;
      TxSpnnLnkEn_o                   : out std_logic;
      TxDestSwitch_o                  : out std_logic_vector(2 downto 0);
      --TxPaerIgnoreFifoFull_o         : out std_logic;
      TxPaerReqActLevel_o             : out std_logic;
      TxPaerAckActLevel_o             : out std_logic;
      TxSaerChanEn_o                  : out std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
      
      -- TX Timestamp
      TxTSMode_o                      : out std_logic_vector(1 downto 0);
      TxTSTimeoutSel_o                : out std_logic_vector(3 downto 0);
      TxTSRetrigCmd_o                 : out std_logic;
      TxTSRearmCmd_o                  : out std_logic;
      TxTSRetrigStatus_i              : in  std_logic;
      TxTSTimeoutCounts_i             : in  std_logic;
      TxTSMaskSel_o                   : out std_logic_vector(1 downto 0);
      
      --
      LRxPaerEn_o                     : out std_logic;
      RRxPaerEn_o                     : out std_logic;
      AUXRxPaerEn_o                   : out std_logic;
      LRxHSSaerEn_o                   : out std_logic;
      RRxHSSaerEn_o                   : out std_logic;
      AUXRxHSSaerEn_o                 : out std_logic;
      LRxGtpEn_o                      : out std_logic;
      RRxGtpEn_o                      : out std_logic;
      AUXRxGtpEn_o                    : out std_logic;
      LRxSpnnLnkEn_o                  : out std_logic;
      RRxSpnnLnkEn_o                  : out std_logic;
      AUXRxSpnnLnkEn_o                : out std_logic;
      LRxSaerChanEn_o                 : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      RRxSaerChanEn_o                 : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      AUXRxSaerChanEn_o               : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      RxPaerReqActLevel_o             : out std_logic;
      RxPaerAckActLevel_o             : out std_logic;
      RxPaerIgnoreFifoFull_o          : out std_logic;
      RxPaerAckSetDelay_o             : out std_logic_vector(7 downto 0);
      RxPaerSampleDelay_o             : out std_logic_vector(7 downto 0);
      RxPaerAckRelDelay_o             : out std_logic_vector(7 downto 0);
                                    
      -- Status                      
      -------------------------
      WrapDetected_i                  : in  std_logic;
      
      TxSaerStat_i                    : in  t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
      LRxSaerStat_i                   : in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
      RRxSaerStat_i                   : in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
      AUXRxSaerStat_i                 : in  t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
      TxGtpStat_i                     : in t_TxGtpStat;
      LRxGtpStat_i                    : in t_RxGtpStat;
      RRxGtpStat_i                    : in t_RxGtpStat;
      AUXRxGtpStat_i                  : in t_RxGtpStat;
      TxSpnnlnkStat_i                 : in  t_TxSpnnlnkStat;
      LRxSpnnlnkStat_i                : in  t_RxSpnnlnkStat;
      RRxSpnnlnkStat_i                : in  t_RxSpnnlnkStat;
      AuxRxSpnnlnkStat_i              : in  t_RxSpnnlnkStat;
                                    
      -- Spinnaker                     
      -------------------------
      Spnn_start_key_o                : out std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command 
      Spnn_stop_key_o                 : out std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command  
      Spnn_tx_mask_o                  : out std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
      Spnn_rx_mask_o                  : out std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
      Spnn_ctrl_o                     : out std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
      Spnn_status_i                   : in  std_logic_vector(31 downto 0);  -- SpiNNaker Status Register  
      
      -- DO NOT EDIT BELOW THIS LINE ---------------------
      -- Bus protocol ports, do not add to or delete
      -- Axi lite I-f
      S_AXI_ACLK                      : in  std_logic;
      S_AXI_ARESETN                   : in  std_logic;
      S_AXI_AWADDR                    : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
      S_AXI_AWVALID                   : in  std_logic;
      S_AXI_WDATA                     : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB                     : in  std_logic_vector(3 downto 0);
      S_AXI_WVALID                    : in  std_logic;
      S_AXI_BREADY                    : in  std_logic;
      S_AXI_ARADDR                    : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
      S_AXI_ARVALID                   : in  std_logic;
      S_AXI_RREADY                    : in  std_logic;
      S_AXI_ARREADY                   : out std_logic;
      S_AXI_RDATA                     : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP                     : out std_logic_vector(1 downto 0);
      S_AXI_RVALID                    : out std_logic;
      S_AXI_WREADY                    : out std_logic;
      S_AXI_BRESP                     : out std_logic_vector(1 downto 0);
      S_AXI_BVALID                    : out std_logic;
      S_AXI_AWREADY                   : out std_logic
      -- DO NOT EDIT ABOVE THIS LINE ---------------------
      );
  end component axilite;
  
  component axistream is
    port (
      Clk                    : in  std_logic;
      nRst                   : in  std_logic;
      --
      DMA_test_mode_i        : in  std_logic;
      EnableAxistreamIf_i    : in  std_logic;
      OnlyEventsRx_i         : in  std_logic;
      OnlyEventsTx_i         : in  std_logic;
      DMA_is_running_o       : out std_logic;
      DmaLength_i            : in  std_logic_vector(15 downto 0);
      ResetStream_i          : in  std_logic;
      LatTlat_i              : in  std_logic;
      TlastCnt_o             : out std_logic_vector(31 downto 0);
      TlastTO_i              : in  std_logic_vector(31 downto 0);
      TlastTOwritten_i       : in  std_logic;
      TDataCnt_o             : out std_logic_vector(31 downto 0);
      -- From Fifo to core/dma
      FifoRxDat_i            : in  std_logic_vector(63 downto 0);
      FifoRxRead_o           : out std_logic;
      FifoRxEmpty_i          : in  std_logic;
      FifoRxLastData_i       : in  std_logic;
      FifoRxResetBusy_i      : in  std_logic;
      -- From core/dma to Fifo
      FifoTxDat_o            : out std_logic_vector(31 downto 0);
      FifoTxWrite_o          : out std_logic;
      FifoTxLastData_o       : out std_logic;
      FifoTxFull_i           : in  std_logic;
      FifoTxResetBusy_i      : in  std_logic;
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
  end component axistream;

end package components;



