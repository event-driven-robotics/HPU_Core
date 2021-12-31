----------------------------------------------------------------------
----                                                              ----
---- AXI Lite NeuSerial Interface IP Core                         ----
----                                                              ----
----                                                              ----
---- To Do:                                                       ----
---- -                                                            ----
----                                                              ----
---- Author(s):                                                   ----
---- - Francesco Diotalevi, Istituto Italiano di Tecnologia       ----
---- - Gaetano de Robertis, Istituto Italiano di Tecnologia       ----
---- Modifications by:                                            ----
---- - Maurizio Casti, Istituto Italiano di Tecnologia            ----
----                                                              ----
----------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;

library common_lib;
    use common_lib.utilities_pkg.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;


--****************************
--   PORT DECLARATION
--****************************

entity axilite is
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

    attribute MAX_FANOUT : string;
    attribute SIGIS : string;
    attribute MAX_FANOUT of S_AXI_ACLK     : signal is "10000";
    attribute MAX_FANOUT of S_AXI_ARESETN  : signal is "10000";
    attribute SIGIS of S_AXI_ACLK          : signal is "Clk";
    attribute SIGIS of S_AXI_ARESETN       : signal is "Rst";

end entity axilite;


--****************************
--   IMPLEMENTATION
--****************************

architecture rtl of axilite is

    constant cVer   : string(3 downto 1) := "HPU";
    constant cMAJOR : std_logic_vector(3 downto 0) :="0100";
    constant cMINOR : std_logic_vector(3 downto 0) :="0000";

    constant c_zero_vect : std_logic_vector(31 downto 0) := (others => '0');

    constant C_RX_HAS_ALMOST_ONE_PAER     : boolean :=  C_RX_L_HAS_PAER or
                                                        C_RX_R_HAS_PAER or
                                                        C_RX_A_HAS_PAER;
                                                  
    constant C_RX_HAS_ALMOST_ONE_HSSAER   : boolean :=  C_RX_L_HAS_HSSAER or
                                                        C_RX_R_HAS_HSSAER or
                                                        C_RX_A_HAS_HSSAER;                                              

    constant C_RX_HAS_ALMOST_ONE_GTP      : boolean :=  C_RX_L_HAS_GTP or
                                                        C_RX_R_HAS_GTP or
                                                        C_RX_A_HAS_GTP;
                                                  
    constant C_RX_HAS_ALMOST_ONE_SPNNLNK  : boolean :=  C_RX_L_HAS_SPNNLNK or
                                                        C_RX_R_HAS_SPNNLNK or
                                                        C_RX_A_HAS_SPNNLNK;             
    ----------------------------------------------------------------------------
    -- AXI4 Lite internal signals
    ----------------------------------------------------------------------------

    ---------------------------------
    -- read response
    signal  axi_rresp : std_logic_vector(1 downto 0);
    ---------------------------------
    -- write response
    signal  axi_bresp : std_logic_vector(1 downto 0);
    ---------------------------------
    -- write address acceptance
    signal  axi_awready : std_logic;
    ---------------------------------
    -- write data acceptance
    signal  axi_wready : std_logic;
    ---------------------------------
    -- write response valid
    signal  axi_bvalid : std_logic;
    ---------------------------------
    -- read data valid
    signal  axi_rvalid : std_logic;
    ---------------------------------
    -- write address
    signal  axi_awaddr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    ---------------------------------
    -- read address valid
    signal  axi_araddr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    ---------------------------------
    -- read data
    signal  axi_rdata : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    ---------------------------------
    -- read address acceptance
    signal  axi_arready : std_logic;

    ----------------------------------------------------------------------------
    -- Slave register read enable
    signal  slvRegRden : std_logic;
    ----------------------------------------------------------------------------
    -- Slave register write enable
    signal  slvRegWren : std_logic;
    ----------------------------------------------------------------------------
    -- register read data
    signal  regDataOut : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- Signals for user logic slave model s/w accessible register
    ----------------------------------------------------------------------------
    signal  i_CTRL_reg            : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_LPBK_CNFG_reg       : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_RXData_reg          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_RXTime_reg          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TXData_reg          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_DMA_reg             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_RAWSTAT_reg         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_IRQ_reg             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_MSK_reg             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_BiasTime_reg        : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_WRAPTime_reg        : unsigned(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_PRESCVal_reg        : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_OutNeuronsThr_reg   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_RX_ERR_reg   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_RX_MSK_reg   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RX_CTRL_reg         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TX_CTRL_reg         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RX_CNFG_reg         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TX_CNFG_reg         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_FIFOTHRESH_reg      : std_logic_vector(C_SLV_DWIDTH-1  downto 0);
    signal  i_LPBK_CNFG_AUX_reg   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_AUX_CTRL_reg        : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_AUX_RX_ERR_reg  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_AUX_RX_MSK_reg  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_AUX_RX_ERR_CNT_reg : t_RxErrStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    signal  i_HSSAER_AUX_RX_ERR_THR_reg : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_SPNN_START_KEY_reg  : std_logic_vector (31 downto 0);
    signal  i_SPNN_STOP_KEY_reg   : std_logic_vector (31 downto 0);    
    signal  i_SPNN_TX_MASK_reg    : std_logic_vector (31 downto 0);
    signal  i_SPNN_RX_MASK_reg    : std_logic_vector (31 downto 0);
    signal  i_SPNN_CTRL_reg       : std_logic_vector (31 downto 0);
    
    signal  i_CTRL_rd             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_LPBK_CNFG_rd        : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RXData_rd           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RXTime_rd           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TXData_rd           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_DMA_rd              : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RAWSTAT_rd          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_IRQ_rd              : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_MSK_rd              : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_BiasTime_rd         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_WRAPTime_rd         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_PRESCVal_rd         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_OutNeuronsThr_rd    : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_STAT_rd      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_RX_ERR_rd    : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_RX_MSK_rd    : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RX_CTRL_rd          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TX_CTRL_rd          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RX_CNFG_rd          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TX_CNFG_rd          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_IP_CONFIG_rd        : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_FIFOTHRESH_rd       : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_LPBK_CNFG_AUX_rd    : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_ID_rd               : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_AUX_CTRL_rd         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_AUX_RX_ERR_rd: std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_AUX_RX_MSK_rd: std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_HSSAER_AUX_RX_ERR_CNT_rd : t_RxErrStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
    signal  i_readRxErrCnt : std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    signal  i_HSSAER_AUX_RX_ERR_THR_rd : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_SPNN_START_KEY_rd   : std_logic_vector (31 downto 0);
    signal  i_SPNN_STOP_KEY_rd    : std_logic_vector (31 downto 0);
    signal  i_SPNN_TX_MASK_rd     : std_logic_vector (31 downto 0);
    signal  i_SPNN_RX_MASK_rd     : std_logic_vector (31 downto 0);
    signal  i_SPNN_CTRL_rd        : std_logic_vector (31 downto 0);
    signal  i_SPNN_STATUS_rd      : std_logic_vector (31 downto 0);
    signal  i_TlastCnt_rd         : std_logic_vector (31 downto 0);
    signal  i_TDataCnt_rd         : std_logic_vector (31 downto 0);
    signal  i_TlastTO_rd          : std_logic_vector (31 downto 0);


    signal  i_rawHSSaerErr  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_rawAUXHSSaerErr : std_logic_vector(C_SLV_DWIDTH-1 downto 0);

    signal  i_LocFarRPaerLoopback  : std_logic;
    signal  i_LocFarLPaerLoopback  : std_logic;
    signal  i_LocFarAuxPaerLoopback: std_logic;
    signal  i_LocFarRSaerLoopback  : std_logic;
    signal  i_LocFarLSaerLoopback  : std_logic;
    signal  i_LocFarAuxSaerLoopback: std_logic;
    signal  i_LocNearLoopback      : std_logic;
    signal  i_RemoteLoopback       : std_logic;
    signal  i_LocFarSpnnLnkLoopbackSel : std_logic_vector (1 downto 0);
    -- signal  i_ChipType             : std_logic;
    signal  i_fulltimestamp        : std_logic;
    signal  i_ResetStream          : std_logic;
    -- signal  i_TxEnable             : std_logic;
    -- signal  i_RRxEnable            : std_logic;
    -- signal  i_LRxEnable            : std_logic;
    -- signal  i_BG_PowerDown         : std_logic;
    -- signal  i_TxPaerFlushFifos     : std_logic;
    signal  i_RRxPaerFlushFifos    : std_logic;
    signal  i_LRxPaerFlushFifos    : std_logic;
    signal  i_AuxRxPaerFlushFifos  : std_logic;
    signal  i_FlushRXFifos           : std_logic;
    signal  i_FlushTXFifos           : std_logic;
    signal  i_LatTlast             : std_logic;
    -- signal  i_EnableLoopBack       : std_logic;
    signal  i_interruptEnable      : std_logic;
    signal  i_EnableDmaIf          : std_logic;
    -- signal  i_EnableIp             : std_logic;


    signal  i_LocFarSaerLpbkCfg    : t_XConCfg;


    signal  i_TxDataBuffer         : std_logic_vector(31 downto 0);


    signal  i_DmaLength            : std_logic_vector(15 downto 0);
 
    signal i_OnlyEventsRx          : std_logic;
    signal i_OnlyEventsTx          : std_logic;

    -- signal  i_LatchTime            : natural range 0 to 255;
    -- signal  i_ClockLowTime         : natural range 0 to 127;
    -- signal  i_SetupHold            : natural range 0 to 63;


    signal  i_cleanTimer    : std_logic;


    -- signal  i_PrescalerValue       : std_logic_vector(31 downto 0);


    -- signal  i_OutThresholdVal      : std_logic_vector(31 downto 0);


    signal  i_glbl_err             : std_logic_vector(19 downto 16);
    signal  i_glbl_err_msk         : std_logic_vector(19 downto 16);

    signal i_aux_err_cnt : std_logic_vector(3 downto 0); -- There are 4 contributors for errors... ko, rx, to and of
    signal i_aux_err_cnt_msk : std_logic_vector(3 downto 0); -- There are 4 contributors for errors... ko, rx, to and of

    signal  i_RRxSaerChanEn  : std_logic_vector(3 downto 0);
    signal  i_RRxSpnnLnkEn   : std_logic;
    signal  i_RRxGtpEn       : std_logic;
    signal  i_RRxPaerEn      : std_logic;
    signal  i_RRxHSSaerEn    : std_logic;
    signal  i_LRxSaerChanEn  : std_logic_vector(3 downto 0);
    signal  i_LRxSpnnLnkEn   : std_logic;
    signal  i_LRxGtpEn       : std_logic;
    signal  i_LRxPaerEn      : std_logic;
    signal  i_LRxHSSaerEn    : std_logic;


    signal  i_RxPaerAckRelDelay    : std_logic_vector(7 downto 0);
    signal  i_RxPaerAckSetDelay    : std_logic_vector(7 downto 0);
    signal  i_RxPaerSampleDelay    : std_logic_vector(7 downto 0);
    signal  i_RxPaerIgnoreFifoFull : std_logic;
    signal  i_RxPaerAckActLevel    : std_logic;
    signal  i_RxPaerReqActLevel    : std_logic;


    signal  i_TxSaerChanEn  : std_logic_vector(3 downto 0);
    signal  i_TxSpnnLnkEn   : std_logic;
    signal  i_TxGtpEn       : std_logic;
    signal  i_TxPaerEn      : std_logic;
    signal  i_TxHSSaerEn    : std_logic;
    
    signal  i_TxTSMode         : std_logic_vector(1 downto 0);
    signal  i_TxTSTimeoutSel   : std_logic_vector(3 downto 0);
    signal  i_TxTSRetrigCmd    : std_logic;
    signal  i_TxTSRearmCmd     : std_logic;
    signal  i_TxTSRetrigStatus : std_logic;
    signal  i_TxTSMaskSel      : std_logic_vector(1 downto 0);   
    
    signal  i_TxDestSwitch  : std_logic_vector(2 downto 0);

    signal  i_TxPaerAckActLevel    : std_logic;
    signal  i_TxPaerReqActLevel    : std_logic;

    signal  i_AUXRxSaerChanEn  : std_logic_vector(3 downto 0);
    signal  i_AUXRxSpnnLnkEn   : std_logic;
    signal  i_AUXRxGtpEn       : std_logic;
    signal  i_AUXRxPaerEn      : std_logic;
    signal  i_AUXRxHSSaerEn    : std_logic;
    signal  i_rawInterrupt     : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_SpnnLnk_err      : std_logic_vector(26 downto 20);

    signal  i_TlastTO          : std_logic_vector(31 downto 0);
    signal  i_TlastTowritten   : std_logic;

begin


    -- SpiNNlink errors
    i_SpnnLnk_err <=    AuxRxSpnnlnkStat_i.rx_err       & 
                        RRxSpnnlnkStat_i.rx_err         & 
                        LRxSpnnlnkStat_i.rx_err         &
                        AuxRxSpnnlnkStat_i.parity_err   &
                        AuxRxSpnnlnkStat_i.parity_err   &
                        AuxRxSpnnlnkStat_i.parity_err   &
                        TxSpnnlnkStat_i.dump_mode       ; 
                        
    -- i_rawInterrupt is used in IRQ_reg
    i_rawInterrupt <= c_zero_vect(31 downto 27) & i_SpnnLnk_err & i_glbl_err_msk & RawInterrupt_i;


    ReadRxBuffer_o <= axi_arready when (unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)) = 2 or unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)) = 3) else
                    '0';

    RxFifoThresholdNumData_o <= i_FIFOTHRESH_reg(10 downto 0);
    
    Spnn_start_key_o     <= i_SPNN_START_KEY_reg;
    Spnn_stop_key_o      <= i_SPNN_STOP_KEY_reg;
    Spnn_tx_mask_o       <= i_SPNN_TX_MASK_reg;
    Spnn_rx_mask_o       <= i_SPNN_RX_MASK_reg;
    Spnn_ctrl_o          <= i_SPNN_CTRL_reg;

    p_hssaer_rx_err : process (LRxSaerStat_i, RRxSaerStat_i)
    begin
        i_rawHSSaerErr <= (others => '0');
        if (C_RX_L_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_rawHSSaerErr( 0+4*i+0) <= LRxSaerStat_i(i).err_ko;
                i_rawHSSaerErr( 0+4*i+1) <= LRxSaerStat_i(i).err_rx;
                i_rawHSSaerErr( 0+4*i+2) <= LRxSaerStat_i(i).err_to;
                i_rawHSSaerErr( 0+4*i+3) <= LRxSaerStat_i(i).err_of;
            end loop;
        end if;
        if (C_RX_R_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_rawHSSaerErr(16+4*i+0) <= RRxSaerStat_i(i).err_ko;
                i_rawHSSaerErr(16+4*i+1) <= RRxSaerStat_i(i).err_rx;
                i_rawHSSaerErr(16+4*i+2) <= RRxSaerStat_i(i).err_to;
                i_rawHSSaerErr(16+4*i+3) <= RRxSaerStat_i(i).err_of;
            end loop;
        end if;
    end process p_hssaer_rx_err;

   p_hssaer_aux_rx_err : process (AUXRxSaerStat_i)
    begin
        i_rawAUXHSSaerErr <= (others => '0');
        if (C_RX_A_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_rawAUXHSSaerErr( 0+4*i+0) <= AUXRxSaerStat_i(i).err_ko;
                i_rawAUXHSSaerErr( 0+4*i+1) <= AUXRxSaerStat_i(i).err_rx;
                i_rawAUXHSSaerErr( 0+4*i+2) <= AUXRxSaerStat_i(i).err_to;
                i_rawAUXHSSaerErr( 0+4*i+3) <= AUXRxSaerStat_i(i).err_of;
            end loop;
        end if;
    end process p_hssaer_aux_rx_err;

    ----------------------------------------------------------------------------
    --I/O Connections assignments

    ----------------------------------------------------------------------------
    --Write Address Ready (AWREADY)
    S_AXI_AWREADY <= axi_awready;

    ----------------------------------------------------------------------------
    --Write Data Ready(WREADY)
    S_AXI_WREADY  <= axi_wready;

    ----------------------------------------------------------------------------
    --Write Response (BResp)and response valid (BVALID)
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BVALID  <= axi_bvalid;

    ----------------------------------------------------------------------------
    --Read Address Ready(AREADY)
    S_AXI_ARREADY <= axi_arready;

    ----------------------------------------------------------------------------
    --Read and Read Data (RDATA), Read Valid (RVALID) and Response (RRESP)
    S_AXI_RDATA   <= axi_rdata;
    S_AXI_RVALID  <= axi_rvalid;
    S_AXI_RRESP   <= axi_rresp;


    ----------------------------------------------------------------------------
    -- Implement axi_awready generation
    --
    --  axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    --  S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    --  de-asserted when reset is low.
    p_awready_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_awready <= '0';
            else
                if (axi_awready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                    axi_awready <= '1';
                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process p_awready_gen;


    ----------------------------------------------------------------------------
    -- Implement axi_awaddr latching
    --
    --  This process is used to latch the address when both
    --  S_AXI_AWVALID and S_AXI_WVALID are valid.

    p_awaddr_latch : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_awaddr <= (others => '0');
            else
                if (axi_awready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                    axi_awaddr <= S_AXI_AWADDR;
                end if;
            end if;
        end if;
    end process p_awaddr_latch;


    ----------------------------------------------------------------------------
    -- Implement axi_wready generation
    --
    --  axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    --  S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
    --  de-asserted when reset is low.

    p_wready_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_wready <= '0';
            else
                if (axi_wready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                    ----------------------------------------------------------------------------
                    -- slave is ready to accept write data when
                    -- there is a valid write address and write data
                    -- on the write address and data bus. This design
                    -- expects no outstanding transactions.
                    axi_wready <= '1';
                else
                    axi_wready <= '0';

                end if;
            end if;
        end if;
    end process p_wready_gen;



    ----------------------------------------------------------------------------
    -- Implement memory mapped register select and write logic generation
    --
    -- The write data is accepted and written to memory mapped
    -- registers (CTRL_reg, slv_reg1, RXData_reg, RXTime_reg) when axi_wready,
    -- S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    -- select byte enables of slave registers while writing.
    -- These registers are cleared when reset (active low) is applied.
    --
    -- Slave register write enable is asserted when valid address and data are available
    -- and the slave is ready to accept the write address and write data.

    slvRegWren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID;

    p_write : process (S_AXI_ACLK)
        variable v_IRQ_reg           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        variable v_IRQAUXCNT_reg     : std_logic_vector(C_SLV_DWIDTH-1 downto 28);
        variable v_HSSAER_RX_ERR_reg : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        variable v_HSSAER_AUX_RX_ERR_reg : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                i_CTRL_reg          <= ( 8     => '1',
                                        25     => DefLocNearLpbk_i,
                                        30     => DefLocFarLpbk_i,
                                        31     => DefLocFarLpbk_i,
                                        others => '0');
                i_LPBK_CNFG_reg     <= (others => '0');
                -- i_RXData_reg        <= (others => '0');          -- (RO  - Read only register)
                -- i_RXTime_reg        <= (others => '0');          -- (RO  - Read only register)
                i_TXData_reg        <= (others => '0');
                i_DMA_reg           <= (8 => '1', others => '0');
                -- i_RAWSTAT_reg       <= (others => '0');          -- (RO  - Read only register)
                i_IRQ_reg           <= (others => '0');             -- (RWC - Clear-On-Write register)
                i_MSK_reg           <= (others => '0');
                -- i_BiasTime_reg      <= X"00640101";              -- Reserved
                i_WRAPTime_reg      <= (others => '0');             -- (RWC - Clear-On-Write register)
                -- i_PRESCVal_reg      <= X"0001E848";              -- Reserved
                -- i_OutNeuronsThr_reg <= (others => '0');          -- Reserved
                -- i_HSSAER_STAT_reg   <= (others => '0');          -- (RO  - Read only register)
                i_HSSAER_RX_ERR_reg   <= (others => '0');
                i_HSSAER_RX_MSK_reg   <= (others => '0');
                i_RX_CTRL_reg       <= (others => '0');
                i_TX_CTRL_reg       <= (others => '0');
                i_RX_CNFG_reg       <= ( 25 => '1', 8 => '1',others => '0');
                i_TX_CNFG_reg       <= (others => '0');
                i_FIFOTHRESH_reg    <= (others => '0');
                i_LPBK_CNFG_AUX_reg <= (others => '0');
                i_AUX_CTRL_reg      <= (others => '0');
                i_HSSAER_AUX_RX_ERR_reg <= (others => '0');
                i_HSSAER_AUX_RX_MSK_reg <= (others => '0');
                i_HSSAER_AUX_RX_ERR_THR_reg <= X"10_10_10_10";
                i_SPNN_START_KEY_reg <= x"80000000";
                i_SPNN_STOP_KEY_reg  <= x"40000000";
                i_SPNN_TX_MASK_reg   <= x"00FFFFFF";
                i_SPNN_RX_MASK_reg   <= x"00FFFFFF";
                i_SPNN_CTRL_reg      <= x"00000000";

                WriteTxBuffer_o <= '0';
                i_cleanTimer  <= '0';
                
                i_TlastTO <= X"00010000";
                i_TlastTowritten <= '0';

            else
                WriteTxBuffer_o <= '0';

                -- Wrapping counter register
                if (WrapDetected_i = '1') then
                    --i_WRAPTime_reg <= std_logic_vector(to_unsigned(to_integer(unsigned(i_WRAPTime_reg))+1,32));
                    i_WRAPTime_reg <= i_WRAPTime_reg+1;
                end if;
                i_cleanTimer <= '0';     -- i_WRAPTime_reg cleared on write

                -- Ctrl register
                i_CTRL_reg( 4) <= '0';      -- FlushRXFifos_o          (WO: monostable)
                i_CTRL_reg( 5) <= '0';      -- LRxPaerFlushFifos_o     (WO: monostable)
                i_CTRL_reg( 6) <= '0';      -- RRxPaerFlushFifos_o     (WO: monostable)
                i_CTRL_reg( 7) <= '0';      -- AuxRxPaerFlushFifos_o   (WO: monostable)
                i_CTRL_reg( 8) <= '0';      -- FlushTXFifos_o          (WO: monostable)
                i_CTRL_reg(12) <= '0';      -- ResetStream_o           (WO: monostable)
				
                i_TX_CTRL_reg(14) <= '0';   -- TxTSRetrigCmd_o        (Cleared after Write)
				        i_TX_CTRL_reg(15) <= '0';   -- TxTSRearmCmd_o         (Cleared after Write)
				        i_SPNN_CTRL_reg(1) <= '0';  -- Force START Command    (Cleared after Write)
				        i_SPNN_CTRL_reg(2) <= '0';  -- Force STOP Command     (Cleared after Write)
				
                -- TlastTO register
                i_TlastTowritten <= '0';

                -- IRQ Register
                -- Update the value of the IRQ
                v_IRQ_reg := i_IRQ_reg;
                for i in 31 downto 0 loop
                    v_IRQ_reg(i) := v_IRQ_reg(i) or (i_rawInterrupt(i) and i_MSK_reg(i));
                end loop;

                v_HSSAER_RX_ERR_reg := i_HSSAER_RX_ERR_reg;
                for i in 31 downto 0 loop
                    v_HSSAER_RX_ERR_reg(i) := v_HSSAER_RX_ERR_reg(i) or i_rawHSSaerErr(i); -- and i_HSSAER_RX_MSK_reg(i));
                end loop;

                v_HSSAER_AUX_RX_ERR_reg := i_HSSAER_AUX_RX_ERR_reg;
                for i in 31 downto 0 loop
                    v_HSSAER_AUX_RX_ERR_reg(i) := i_HSSAER_AUX_RX_ERR_reg(i) or i_rawAUXHSSaerErr(i);
                end loop;

                if (slvRegWren = '1') then
                    case (to_integer(unsigned(axi_awaddr(C_ADDR_WIDTH-1 downto 2)))) is
                        when  0 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_CTRL_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when  1 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_LPBK_CNFG_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                     -- when  2 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_RXData_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                     -- when  3 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_RXTime_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when  4 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_TXData_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                    WriteTxBuffer_o <= '1';
                                end if;
                            end loop;
                        when  5 =>
                            -- DMA_reg can be written only if CTRL_reg(1)='0', i.e. if the DMAIf is disabled
                            if (i_CTRL_reg(1)='0') then
                                for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                    if (S_AXI_WSTRB(byte_index) = '1') then
                                        i_DMA_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                    end if;
                                end loop;
                            end if;
                     -- when  6 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_RAWSTAT_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when  7 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    v_IRQ_reg(byte_index*8+7 downto byte_index*8) := v_IRQ_reg(byte_index*8+7 downto byte_index*8) and (not(S_AXI_WDATA(byte_index*8+7 downto byte_index*8)));
                                end if;
                            end loop;
                        when  8 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_MSK_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                     -- when  9 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_BiasTime_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when 10 =>
                            -- Any writing actvity clear the WRAPTime_reg
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_WRAPTime_reg <= (others => '0');
                                    i_cleanTimer <= '1';
                                end if;
                            end loop;
                     -- when 11 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_PRESCVal_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                     -- when 12 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_OutNeuronsThr_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                     -- when 13 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_HSSAER_STAT_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when 14 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    v_HSSAER_RX_ERR_reg(byte_index*8+7 downto byte_index*8) := v_HSSAER_RX_ERR_reg(byte_index*8+7 downto byte_index*8) and (not(S_AXI_WDATA(byte_index*8+7 downto byte_index*8)));
                                end if;
                            end loop;
                        when 15 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_HSSAER_RX_MSK_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when 16 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_RX_CTRL_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when 17 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_TX_CTRL_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when 18 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_RX_CNFG_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when 19 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_TX_CNFG_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                     -- when 20 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_IP_CONFIG_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when 21 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_FIFOTHRESH_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when 22 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_LPBK_CNFG_AUX_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                     -- ID register
                     -- when 23 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_ID_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when 24 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_AUX_CTRL_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                    -- AUX_RX_ERR register
                             -- when 25 =>
                             --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                             --         if (S_AXI_WSTRB(byte_index) = '1') then
                             --             i_HSSAER_AUX_RX_ERR_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                             --         end if;
                             --     end loop;
                        when 26 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_HSSAER_AUX_RX_MSK_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;

                        -- i_HSSAER_AUX_RX_ERR_THR_reg
                        when 27 =>
                           for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                   i_HSSAER_AUX_RX_ERR_THR_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                           end loop;

                       -- i_HSSAER_AUX_CH0_ERR_CNT_reg Read Only register
                       -- when 28 =>

                       -- i_HSSAER_AUX_CH1_ERR_CNT_reg Read Only register
                       -- when 29 =>

                       -- i_HSSAER_AUX_CH2_ERR_CNT_reg Read Only register
                       -- when 30 =>

                       -- i_HSSAER_AUX_CH3_ERR_CNT_reg Read Only register
                       -- when 31 =>
 
                       -- i_SPNN_START_KEY_reg
                       when 32 =>
                          for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                               if (S_AXI_WSTRB(byte_index) = '1') then
                                  i_SPNN_START_KEY_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                               end if;
                          end loop;      

                       -- i_SPNN_STOP_KEY_reg
                       when 33 =>
                          for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                               if (S_AXI_WSTRB(byte_index) = '1') then
                                  i_SPNN_STOP_KEY_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                               end if;
                          end loop;                 

                       -- i_SPNN_TX_MASK_reg
                       when 34 =>
                           for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                               if (S_AXI_WSTRB(byte_index) = '1') then
                                  i_SPNN_TX_MASK_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                               end if;
                           end loop;  
                           
                       -- i_SPNN_RX_MASK_reg
                       when 35 =>
                           for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                               if (S_AXI_WSTRB(byte_index) = '1') then
                                  i_SPNN_RX_MASK_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                               end if;
                           end loop;  
                           
                       -- i_SPNN_CTRL_reg
                       when 36 =>
                           for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                               if (S_AXI_WSTRB(byte_index) = '1') then
                                  i_SPNN_CTRL_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                               end if;
                           end loop;  
                           
                       -- i_SPNN_STATUS_reg Read Only register
                       -- when 37 =>
                                                      
                       -- i_TlastTO_reg
                       when 40 =>
                           for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                               if (S_AXI_WSTRB(byte_index) = '1') then
                                  i_TlastTO(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                  i_TlastTowritten <= '1';
                               end if;
                           end loop;  

                        -- i_TlastCnt_reg Read Only Register
                        -- when 41 =>

                        -- i_TDataCnt_reg Read Only Register
                        -- when 42 =>
                        
                        when others => null;

                    end case;
                end if;
                i_IRQ_reg <= v_IRQ_reg;
                i_HSSAER_RX_ERR_reg <= v_HSSAER_RX_ERR_reg;
                i_HSSAER_AUX_RX_ERR_reg <= v_HSSAER_AUX_RX_ERR_reg;
             end if;
        end if;
    end process p_write;


    ----------------------------------------------------------------------------
    -- Implement write response logic generation
    --
    --  The write response and response valid signals are asserted by the slave
    --  when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    --  This marks the acceptance of address and indicates the status of
    --  write transaction.

    p_bresp_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_bvalid  <= '0';
                axi_bresp   <= "00";
            else
                if (axi_awready='1' and S_AXI_AWVALID='1' and axi_bvalid='0' and axi_wready='1' and S_AXI_WVALID='1') then
                    -- indicates a valid write response is available
                    axi_bvalid <= '1';
                    axi_bresp  <= "00"; -- 'OKAY' response
                else
                    if (S_AXI_BREADY='1' and axi_bvalid='1') then
                        --check if bready is asserted while bvalid is high)
                        --(there is a possibility that bready is always asserted high)
                        axi_bvalid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process p_bresp_gen;


    ----------------------------------------------------------------------------
    -- Implement axi_arready generation
    --
    --  axi_arready is asserted for one S_AXI_ACLK clock cycle when
    --  S_AXI_ARVALID is asserted. axi_awready is
    --  de-asserted when reset (active low) is asserted.
    --  The read address is also latched when S_AXI_ARVALID is
    --  asserted. axi_araddr is reset to zero on reset assertion.

    p_arready_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_arready <= '0';
                axi_araddr  <= (others => '0');
            else
                if (axi_arready='0' and S_AXI_ARVALID='1') then
                    -- indicates that the slave has acceped the valid read address
                    axi_arready <= '1';
                    axi_araddr  <= S_AXI_ARADDR;
                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process p_arready_gen;


    ----------------------------------------------------------------------------
    -- Implement memory mapped register select and read logic generation
    --
    --  axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    --  S_AXI_ARVALID and axi_arready are asserted. The slave registers
    --  data are available on the axi_rdata bus at this instance. The
    --  assertion of axi_rvalid marks the validity of read data on the
    --  bus and axi_rresp indicates the status of read transaction.axi_rvalid
    --  is deasserted on reset (active low). axi_rresp and axi_rdata are
    --  cleared to zero on reset (active low).

    p_rresp_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_rvalid <= '0';
                axi_rresp  <= (others => '0');
            else
                if (axi_arready='1' and S_AXI_ARVALID='1' and axi_rvalid='0') then
                    -- Valid read data is available at the read data bus
                    axi_rvalid <= '1';
                    axi_rresp  <= (others => '0'); -- 'OKAY' response
                elsif (axi_rvalid='1' and S_AXI_RREADY='1') then
                    -- Read data is accepted by the master
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process p_rresp_gen;

    ----------------------------------------------------------------------------
    -- Slave register read enable is asserted when valid address is available
    -- and the slave is ready to accept the read address.
    slvRegRden <= axi_arready and S_AXI_ARVALID and not(axi_rvalid);

    p_read_mux : process (S_AXI_ARESETN, axi_araddr,
                          i_CTRL_rd, i_LPBK_CNFG_rd, i_RXData_rd, i_RXTime_rd, i_TXData_rd, i_DMA_rd, i_RAWSTAT_rd,
                          i_IRQ_rd, i_MSK_rd, --i_BiasTime_rd,
                          i_WRAPTime_rd, --i_PRESCVal_rd, i_OutNeuronsThr_rd,
                          i_HSSAER_STAT_rd, i_HSSAER_RX_ERR_rd, i_HSSAER_RX_MSK_rd,
                          i_RX_CTRL_rd, i_TX_CTRL_rd, i_RX_CNFG_rd, i_TX_CNFG_rd,
                          i_IP_CONFIG_rd, i_FIFOTHRESH_rd, i_LPBK_CNFG_AUX_rd, i_ID_rd, i_AUX_CTRL_rd,
                          i_HSSAER_AUX_RX_ERR_rd, i_HSSAER_AUX_RX_MSK_rd,
                          i_readRxErrCnt, i_HSSAER_AUX_RX_ERR_THR_rd, i_HSSAER_AUX_RX_ERR_CNT_rd,
                          i_SPNN_START_KEY_rd, i_SPNN_STOP_KEY_rd, i_SPNN_TX_MASK_rd, i_SPNN_RX_MASK_rd,
                          i_SPNN_CTRL_rd, i_SPNN_STATUS_rd,
                          i_TlastCnt_rd, i_TDataCnt_rd, i_TlastTO_rd)
    begin
        if (S_AXI_ARESETN = '0') then
            regDataOut <= (others => '0');
        else
            case (to_integer(unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)))) is
                when  0 => regDataOut  <= i_CTRL_rd;
                when  1 => regDataOut  <= i_LPBK_CNFG_rd;
                when  2 => regDataOut  <= i_RXData_rd;
                when  3 => regDataOut  <= i_RXTime_rd;
                when  4 => regDataOut  <= i_TXData_rd;
                when  5 => regDataOut  <= i_DMA_rd;
                when  6 => regDataOut  <= i_RAWSTAT_rd;
                when  7 => regDataOut  <= i_IRQ_rd;
                when  8 => regDataOut  <= i_MSK_rd;
--                 when  9 => regDataOut  <= i_BiasTime_rd;
                when 10 => regDataOut  <= i_WRAPTime_rd;
--                 when 11 => regDataOut  <= i_PRESCVal_rd;
--                 when 12 => regDataOut  <= i_OutNeuronsThr_rd;
                when 13 => regDataOut  <= i_HSSAER_STAT_rd;
                when 14 => regDataOut  <= i_HSSAER_RX_ERR_rd;
                when 15 => regDataOut  <= i_HSSAER_RX_MSK_rd;
                when 16 => regDataOut  <= i_RX_CTRL_rd;
                when 17 => regDataOut  <= i_TX_CTRL_rd;
                when 18 => regDataOut  <= i_RX_CNFG_rd;
                when 19 => regDataOut  <= i_TX_CNFG_rd;
                when 20 => regDataOut  <= i_IP_CONFIG_rd;
                when 21 => regDataOut  <= i_FIFOTHRESH_rd;
                when 22 => regDataOut  <= i_LPBK_CNFG_AUX_rd;

                when 23 => regDataOut  <= i_ID_rd;
                when 24 => regDataOut  <= i_AUX_CTRL_rd;
                when 25 => regDataOut  <= i_HSSAER_AUX_RX_ERR_rd;
                when 26 => regDataOut  <= i_HSSAER_AUX_RX_MSK_rd;

                when 27 => regDataOut  <= i_HSSAER_AUX_RX_ERR_THR_rd;
                when 28 => if (C_RX_HSSAER_N_CHAN>=1) then
                              regDataOut <= i_HSSAER_AUX_RX_ERR_CNT_rd(0).cnt_of & i_HSSAER_AUX_RX_ERR_CNT_rd(0).cnt_to & i_HSSAER_AUX_RX_ERR_CNT_rd(0).cnt_rx  & i_HSSAER_AUX_RX_ERR_CNT_rd(0).cnt_ko ;
                           else
                              regDataOut  <= (others => '0');
                           end if;
                when 29 => if (C_RX_HSSAER_N_CHAN>=2) then
                              regDataOut <= i_HSSAER_AUX_RX_ERR_CNT_rd(1).cnt_of & i_HSSAER_AUX_RX_ERR_CNT_rd(1).cnt_to & i_HSSAER_AUX_RX_ERR_CNT_rd(1).cnt_rx  & i_HSSAER_AUX_RX_ERR_CNT_rd(1).cnt_ko ;
                           else
                              regDataOut  <= (others => '0');
                           end if;
                when 30 => if (C_RX_HSSAER_N_CHAN>=3) then
                              regDataOut <= i_HSSAER_AUX_RX_ERR_CNT_rd(2).cnt_of & i_HSSAER_AUX_RX_ERR_CNT_rd(2).cnt_to & i_HSSAER_AUX_RX_ERR_CNT_rd(2).cnt_rx  & i_HSSAER_AUX_RX_ERR_CNT_rd(2).cnt_ko ;
                           else
                              regDataOut  <= (others => '0');
                           end if;
                when 31 => if (C_RX_HSSAER_N_CHAN>=4) then
                              regDataOut <= i_HSSAER_AUX_RX_ERR_CNT_rd(3).cnt_of & i_HSSAER_AUX_RX_ERR_CNT_rd(3).cnt_to & i_HSSAER_AUX_RX_ERR_CNT_rd(3).cnt_rx  & i_HSSAER_AUX_RX_ERR_CNT_rd(3).cnt_ko ;
                           else
                              regDataOut  <= (others => '0');
                           end if;
                           
                when 32 => regDataOut  <= i_SPNN_START_KEY_rd;
                when 33 => regDataOut  <= i_SPNN_STOP_KEY_rd;
                when 34 => regDataOut  <= i_SPNN_TX_MASK_rd;
                when 35 => regDataOut  <= i_SPNN_RX_MASK_rd;                
                when 36 => regDataOut  <= i_SPNN_CTRL_rd;
                when 37 => regDataOut  <= i_SPNN_STATUS_rd;
           --   when 38 => Available     
           --   when 39 => Available   
                when 40 => regDataOut  <= i_TlastTO_rd;
                when 41 => regDataOut  <= i_TlastCnt_rd;
                when 42 => regDataOut  <= i_TDataCnt_rd;

               when others  => regDataOut  <= x"BAB0BAB0";
            end case;
        end if;
    end process p_read_mux;

    -- This process is used to clear the CNTs AUX err registers
    process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                i_readRxErrCnt <= (others => '0');
            else
                i_readRxErrCnt <= (others => '0');
                for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                    if (slvRegRden='1') then
                        if (to_integer(unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)))=(28+i)) then
                            i_readRxErrCnt(i)<= '1';
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    p_read_data : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_rdata <= (others => '0');
            else
                ----------------------------------------------------------------------------
                -- When there is a valid read address (S_AXI_ARVALID) with
                -- acceptance of read address by the slave (axi_arready),
                -- output the read dada
                if (axi_arready='1' and S_AXI_ARVALID= '1' and axi_rvalid='0') then
                    axi_rdata <= regDataOut;     -- register read data
                end if;
            end if;
        end if;
    end process p_read_data;


    -- ------------------------------------------------------------------------
    -- Control register
    -- ------------------------------------------------------------------------
    -- CTRL_reg - R/W
    --

    i_LocFarRPaerLoopback  <= i_CTRL_reg(31) when C_RX_R_HAS_PAER and C_TX_HAS_PAER else '0';
    i_LocFarLPaerLoopback  <= i_CTRL_reg(30) when C_RX_L_HAS_PAER and C_TX_HAS_PAER else '0';
    i_LocFarRSaerLoopback  <= i_CTRL_reg(29) when C_RX_R_HAS_HSSAER and C_TX_HAS_HSSAER else '0';
    i_LocFarLSaerLoopback  <= i_CTRL_reg(28) when C_RX_L_HAS_HSSAER and C_TX_HAS_HSSAER else '0';
    i_LocFarAUXPaerLoopback<= i_CTRL_reg(27) when C_RX_A_HAS_PAER and C_TX_HAS_PAER else '0';
    i_LocFarAUXSaerLoopback<= i_CTRL_reg(26) when C_RX_A_HAS_HSSAER and C_TX_HAS_HSSAER else '0';
    i_LocNearLoopback      <= i_CTRL_reg(25);
    i_RemoteLoopback       <= i_CTRL_reg(24);
    i_LocFarSpnnLnkLoopbackSel <= i_CTRL_reg(23 downto 22) when C_RX_HAS_ALMOST_ONE_SPNNLNK and C_TX_HAS_SPNNLNK else "00";
 --                        <= i_CTRL_reg(21);                               -- Available        
 --                        <= i_CTRL_reg(20);                               -- Available     
 --                        <= i_CTRL_reg(19);                               -- Available     
 --                        <= i_CTRL_reg(18);                               -- Available     
 --                        <= i_CTRL_reg(17);                               -- Available     
 -- i_ChipType             <= i_CTRL_reg(16);                               -- Reserved for back compatibility with neuelab
    i_fulltimestamp        <= i_CTRL_reg(15);
    i_OnlyEventsTx         <= i_CTRL_reg(14);                               -- Available     
    i_OnlyEventsRx         <= i_CTRL_reg(13);                                
    i_ResetStream          <= i_CTRL_reg(12);
 -- i_TxEnable             <= i_CTRL_reg(11) when C_TX_HAS_PAER else '0';   -- Reserved for future use
 -- i_RRxEnable            <= i_CTRL_reg(10) when C_RX_HAS_PAER else '0';   -- Reserved for future use
    i_LatTlast             <= i_CTRL_reg(9);
    i_FlushTXFifos         <= i_CTRL_reg(8);
    i_AuxRxPaerFlushFifos  <= i_CTRL_reg(7)  when C_RX_A_HAS_PAER else '0';
    i_RRxPaerFlushFifos    <= i_CTRL_reg(6)  when C_RX_R_HAS_PAER else '0';
    i_LRxPaerFlushFifos    <= i_CTRL_reg(5)  when C_RX_L_HAS_PAER else '0';
    i_FlushRXFifos         <= i_CTRL_reg(4);
 -- i_EnableLoopBack       <= i_CTRL_reg(3);                                -- Reserved for back compatibility with neuelab
    i_interruptEnable      <= i_CTRL_reg(2);
    i_EnableDmaIf          <= i_CTRL_reg(1);
 -- i_EnableIp             <= i_CTRL_reg(0);                                -- Reserved for back compatibility with neuelab

    i_CTRL_rd <=    i_LocFarRPaerLoopback      &
                    i_LocFarLPaerLoopback      &
                    i_LocFarRSaerLoopback      &
                    i_LocFarLSaerLoopback      &
                    i_LocFarAUXPaerLoopback    &
                    i_LocFarAUXSaerLoopback    &
                    i_LocNearLoopback          &
                    i_RemoteLoopback           &
                    i_LocFarSpnnLnkLoopbackSel &
                    c_zero_vect(21 downto 17)  &
                    c_zero_vect(16)            &   -- Reserved for back compatibility with neuelab
                    i_fulltimestamp            &
                    i_OnlyEventsTx             &
                    i_OnlyEventsRx             &  
                    i_ResetStream              &
                    c_zero_vect(11 downto 10)  &                  
                    i_LatTlast                 &
                    i_FlushTXFifos             &
                    i_AuxRxPaerFlushFifos      &
                    i_RRxPaerFlushFifos        &
                    i_LRxPaerFlushFifos        &
                    i_FlushRXFifos             &
                    c_zero_vect(3)             &   -- Reserved for back compatibility with neuelab
                    i_interruptEnable          &
                    i_EnableDmaIf              &
                    DMA_is_running_i           ;

    LocFarRPaerLoopback_o      <= i_LocFarRPaerLoopback;
    LocFarLPaerLoopback_o      <= i_LocFarLPaerLoopback;
    LocFarAuxPaerLoopback_o    <= i_LocFarAUXPaerLoopback;
    LocFarRSaerLoopback_o      <= i_LocFarRSaerLoopback;
    LocFarLSaerLoopback_o      <= i_LocFarLSaerLoopback;
    LocFarAuxSaerLoopback_o    <= i_LocFarAUXSaerLoopback;
    LocNearLoopback_o          <= i_LocNearLoopback;
    RemoteLoopback_o           <= i_RemoteLoopback;
    LocFarSpnnLnkLoopbackSel_o <= i_LocFarSpnnLnkLoopbackSel;
 -- ChipType_o                 <= i_ChipType;                      -- Reserved for back compatibility with neuelab
    fulltimestamp_o            <= i_fulltimestamp;
    ResetStream_o              <= i_ResetStream;
 -- TxEnable_o                 <= i_TxEnable;                      -- Reserved for future use
 -- RRxEnable_o                <= i_RRxEnable;                     -- Reserved for future use
 -- LRxEnable_o                <= i_LRxEnable;                     -- Reserved for future use
 -- BG_PowerDown_o             <= i_BG_PowerDown;                  -- Reserved for back compatibility with neuelab
 -- TxPaerFlushFifos_o         <= i_TxPaerFlushFifos;              -- Reserved for future use
    RRxPaerFlushFifos_o        <= i_RRxPaerFlushFifos;
    LRxPaerFlushFifos_o        <= i_LRxPaerFlushFifos;
    AuxRxPaerFlushFifos_o      <= i_AuxRxPaerFlushFifos;
    FlushRXFifos_o             <= i_FlushRXFifos;
    FlushTXFifos_o             <= i_FlushTXFifos;
 -- EnableLoopBack_o           <= i_EnableLoopBack;                -- Reserved for back compatibility with neuelab
    EnableDmaIf_o              <= i_EnableDmaIf;
    LatTlast_o                 <= i_LatTlast;


    -- ------------------------------------------------------------------------
    -- Loopback Configuration register
    -- ------------------------------------------------------------------------
    -- LPBK_CNFG_reg - R/W
    --

    g_lpbk_cnfg_reg : for i in 0 to C_RX_HSSAER_N_CHAN-1 generate
        i_LocFarSaerLpbkCfg.rx1Cfg(i).lpbk <= i_LPBK_CNFG_reg(4*i+3);
        i_LocFarSaerLpbkCfg.rx1Cfg(i).zero <= i_LPBK_CNFG_reg(4*i+2);
        i_LocFarSaerLpbkCfg.rx1Cfg(i).idx  <= to_integer(unsigned(i_LPBK_CNFG_reg(4*i+1 downto 4*i)));

        i_LocFarSaerLpbkCfg.rx2Cfg(i).lpbk <= i_LPBK_CNFG_reg(16+4*i+3);
        i_LocFarSaerLpbkCfg.rx2Cfg(i).zero <= i_LPBK_CNFG_reg(16+4*i+2);
        i_LocFarSaerLpbkCfg.rx2Cfg(i).idx  <= to_integer(unsigned(i_LPBK_CNFG_reg(16+4*i+1 downto 16+4*i)));

        i_LocFarSaerLpbkCfg.rx3Cfg(i).lpbk <= i_LPBK_CNFG_AUX_reg(4*i+3);
        i_LocFarSaerLpbkCfg.rx3Cfg(i).zero <= i_LPBK_CNFG_AUX_reg(4*i+2);
        i_LocFarSaerLpbkCfg.rx3Cfg(i).idx  <= to_integer(unsigned(i_LPBK_CNFG_AUX_reg(4*i+1 downto 4*i)));
    end generate g_lpbk_cnfg_reg;

    p_lpbk_cnfg_rd : process (i_LocFarSaerLpbkCfg)
    begin
        i_LPBK_CNFG_rd <= (others => '0');
        i_LPBK_CNFG_AUX_rd <= (others => '0');
        if (C_RX_L_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_LPBK_CNFG_rd(4*i+3)                   <= i_LocFarSaerLpbkCfg.rx1Cfg(i).lpbk;
                i_LPBK_CNFG_rd(4*i+2)                   <= i_LocFarSaerLpbkCfg.rx1Cfg(i).zero;
                i_LPBK_CNFG_rd(4*i+1 downto 4*i)        <= std_logic_vector(to_unsigned(i_LocFarSaerLpbkCfg.rx1Cfg(i).idx,2));
            end loop;
        end if;
        if (C_RX_R_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_LPBK_CNFG_rd(16+4*i+3)                <= i_LocFarSaerLpbkCfg.rx2Cfg(i).lpbk;
                i_LPBK_CNFG_rd(16+4*i+2)                <= i_LocFarSaerLpbkCfg.rx2Cfg(i).zero;
                i_LPBK_CNFG_rd(16+4*i+1 downto 16+4*i)  <= std_logic_vector(to_unsigned(i_LocFarSaerLpbkCfg.rx2Cfg(i).idx,2));
            end loop;
        end if;
        if (C_RX_A_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_LPBK_CNFG_AUX_rd(4*i+3)               <= i_LocFarSaerLpbkCfg.rx3Cfg(i).lpbk;
                i_LPBK_CNFG_AUX_rd(4*i+2)               <= i_LocFarSaerLpbkCfg.rx3Cfg(i).zero;
                i_LPBK_CNFG_AUX_rd(4*i+1 downto 4*i)    <= std_logic_vector(to_unsigned(i_LocFarSaerLpbkCfg.rx3Cfg(i).idx,2));
            end loop;
        end if;
    end process p_lpbk_cnfg_rd;

    LocFarSaerLpbkCfg_o <= i_LocFarSaerLpbkCfg;


    -- ------------------------------------------------------------------------
    -- RX Buffer
    -- ------------------------------------------------------------------------
    -- RXData_reg - Data Buffer R/O
    --

    i_RXData_rd <= RxDataBuffer_i;


    -- RXTime_reg - Time Buffer R/O
    --

    i_RXTime_rd <= RxTimeBuffer_i;


    -- ------------------------------------------------------------------------
    -- TX Buffer
    -- ------------------------------------------------------------------------
    -- TXData_reg - Data Buffer R/W
    --

    i_TxDataBuffer <= i_TXData_reg;

    i_TXData_rd <= i_TxDataBuffer;

    TxDataBuffer_o <= i_TxDataBuffer;


    -- ------------------------------------------------------------------------
    -- DMA I/f
    -- ------------------------------------------------------------------------
    -- DMA_reg - DMA Interface register R/W
    --

    -- The bit 0 is always zero, this means that only even number of data are
    i_DmaLength <= i_DMA_reg(15 downto 1)&'0';

    i_DMA_rd <= c_zero_vect(31 downto 17) & i_DMA_reg(16) &
                i_DmaLength(15 downto 1)&'0';

    DmaLength_o <= i_DmaLength;

    DMA_test_mode_o <= i_DMA_reg(16);


    -- ------------------------------------------------------------------------
    -- RX Timestamp ON/OFF
    -- ------------------------------------------------------------------------
    OnlyEventsRx_o <= i_OnlyEventsRx;
    OnlyEventsTx_o <= i_OnlyEventsTx;

    -- ------------------------------------------------------------------------
    -- RAW Status register
    -- ------------------------------------------------------------------------
    -- RAWSTAT_reg - Raw Int reg R/O
    --

    i_RAWSTAT_rd(15 downto 0)  <= RawInterrupt_i               ;
    i_RAWSTAT_rd(19 downto 16) <= i_glbl_err                   ;
    i_RAWSTAT_rd(26 downto 20) <= i_SpnnLnk_err                ;
    i_RAWSTAT_rd(31 downto 27) <= (others => '0');

    -- ------------------------------------------------------------------------
    -- IRQ Interrupt register
    -- ------------------------------------------------------------------------
    -- IRQ_reg - Irq reg R/WC
    --

    i_IRQ_rd <= i_IRQ_reg                         ;

    p_intr_gen : process (i_IRQ_rd, i_interruptEnable)
        variable v_intr : std_logic;
    begin
        v_intr := '0';
        for i in 0 to 31 loop
            v_intr := v_intr or i_IRQ_rd(i);
        end loop;
        InterruptLine_o <= v_intr and i_interruptEnable;
    end process p_intr_gen;


    -- ------------------------------------------------------------------------
    -- IMASK Interrupt Mask register
    -- ------------------------------------------------------------------------
    -- MSK_reg - Interrupt Mask register R/W
    --

    i_MSK_rd <= i_MSK_reg;


--     -- ------------------------------------------------------------------------
--     -- BIASTIME_REG  Bias Timing Register
--     -- ------------------------------------------------------------------------
--     -- BiasTime_reg - Bias Timing Register R/W
--     --
--
--     i_LatchTime     <= to_integer(unsigned(i_BiasTime_reg(23 downto 16)));
--     i_ClockLowTime  <= to_integer(unsigned(i_BiasTime_reg(15 downto  8)));
--     i_SetupHold     <= to_integer(unsigned(i_BiasTime_reg( 6 downto  0)));
--
--     i_BiasTime_rd <= c_zero_vect(31 downto 24)                       &
--                      std_logic_vector(to_unsigned(i_LatchTime,8))    &
--                      std_logic_vector(to_unsigned(i_ClockLowTime,8)) &
--                      c_zero_vect(7)                                  &
--                      std_logic_vector(to_unsigned(i_SetupHold,7)     ;
--
--     SetupHold_o     <= i_SetupHold;
--     ClockLowTime_o  <= i_ClockLowTime;
--     LatchTime_o     <= i_LatchTime;


    -- ------------------------------------------------------------------------
    -- WRAPCounter_REG  Timestamp wrapping counter
    -- ------------------------------------------------------------------------
    -- WRAPTime_reg - Timestamp wrapping counter R/WC
    --

    i_WRAPTime_rd <= std_logic_vector(i_WRAPTime_reg);
    CleanTimer_o <= i_cleanTimer;


--     -- ------------------------------------------------------------------------
--     -- PRVAL_REG  Prescaler value
--     -- ------------------------------------------------------------------------
--     -- PRESCVal_reg - Prescaler value R/W
--     --
--
--     i_PrescalerValue <= i_PRESCVal_reg;
--
--     i_PRESCVal_rd <= i_PrescalerValue;
--
--     PrescalerValue_o <= i_PrescalerValue;


--     -- ------------------------------------------------------------------------
--     -- OutNeuronsThr_REG  It set the threshold of the output neurons
--     -- as soon as a spiking neuron is >= the threshold, an intterupt is raised
--     -- ------------------------------------------------------------------------
--     -- OutNeuronsThr_REG - R/W
--     --
--
--     i_OutThresholdVal <= i_OutNeuronsThr_reg;
--
--     i_OutNeuronsThr_rd <= i_OutThresholdVal;
--
--     OutThresholdVal_o <= i_OutThresholdVal;


    -- ------------------------------------------------------------------------
    -- HSSAER status register
    -- ------------------------------------------------------------------------
    -- HSSAER_STAT - HSSAER status register R/O
    --

    p_hssaer_stat : process (LRxSaerStat_i, RRxSaerStat_i, TxSaerStat_i, AUXRxSaerStat_i)
    begin
        i_HSSAER_STAT_rd <= (others => '0');
        if (C_RX_L_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_HSSAER_STAT_rd( 0+i) <= LRxSaerStat_i(i).run;
            end loop;
        end if;
        if (C_RX_R_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_HSSAER_STAT_rd( 8+i) <= RRxSaerStat_i(i).run;
            end loop;
        end if;
        if (C_RX_A_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                i_HSSAER_STAT_rd(24+i) <= AUXRxSaerStat_i(i).run;
            end loop;
        end if;
        if (C_TX_HAS_HSSAER) then
            for i in 0 to C_TX_HSSAER_N_CHAN-1 loop
                i_HSSAER_STAT_rd(16+i) <= TxSaerStat_i(i).run;
            end loop;
        end if;
    end process p_hssaer_stat;


    -- ------------------------------------------------------------------------
    -- HSSAER Error register
    -- ------------------------------------------------------------------------
    -- HSSAER_RX_ERR_reg - HSSAER RX error collector R/WC
    --

    i_HSSAER_RX_ERR_rd <= i_HSSAER_RX_ERR_reg;
    i_HSSAER_AUX_RX_ERR_rd <= i_HSSAER_AUX_RX_ERR_reg;

    p_glbl_hssaer_rx_err : process (i_HSSAER_RX_ERR_reg, i_aux_err_cnt, i_aux_err_cnt_msk, i_HSSAER_RX_MSK_reg)
        variable v_glbl_err_ko, v_glbl_err_ko_msk : std_logic;
        variable v_glbl_err_of, v_glbl_err_of_msk : std_logic;
        variable v_glbl_err_rx, v_glbl_err_rx_msk : std_logic;
        variable v_glbl_err_to, v_glbl_err_to_msk : std_logic;
    begin
        v_glbl_err_ko := '0'; v_glbl_err_ko_msk := '0';
        v_glbl_err_of := '0'; v_glbl_err_of_msk := '0';
        v_glbl_err_rx := '0'; v_glbl_err_rx_msk := '0';
        v_glbl_err_to := '0'; v_glbl_err_to_msk := '0';
        if (C_RX_HAS_ALMOST_ONE_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                v_glbl_err_ko := v_glbl_err_ko or (i_HSSAER_RX_ERR_reg(4*i+0)) or (i_HSSAER_RX_ERR_reg(16+4*i+0)) or i_aux_err_cnt(0);
                v_glbl_err_rx := v_glbl_err_rx or (i_HSSAER_RX_ERR_reg(4*i+1)) or (i_HSSAER_RX_ERR_reg(16+4*i+1)) or i_aux_err_cnt(1);
                v_glbl_err_to := v_glbl_err_to or (i_HSSAER_RX_ERR_reg(4*i+2)) or (i_HSSAER_RX_ERR_reg(16+4*i+2)) or i_aux_err_cnt(2);
                v_glbl_err_of := v_glbl_err_of or (i_HSSAER_RX_ERR_reg(4*i+3)) or (i_HSSAER_RX_ERR_reg(16+4*i+3)) or i_aux_err_cnt(3);

                v_glbl_err_ko_msk := v_glbl_err_ko_msk or (i_HSSAER_RX_ERR_reg(4*i+0) and i_HSSAER_RX_MSK_reg(4*i+0)) or (i_HSSAER_RX_ERR_reg(16+4*i+0) and i_HSSAER_RX_MSK_reg(16+4*i+0)) or (i_aux_err_cnt(0) and i_aux_err_cnt_msk(0));
                v_glbl_err_rx_msk := v_glbl_err_rx_msk or (i_HSSAER_RX_ERR_reg(4*i+1) and i_HSSAER_RX_MSK_reg(4*i+1)) or (i_HSSAER_RX_ERR_reg(16+4*i+1) and i_HSSAER_RX_MSK_reg(16+4*i+1)) or (i_aux_err_cnt(1) and i_aux_err_cnt_msk(1));
                v_glbl_err_to_msk := v_glbl_err_to_msk or (i_HSSAER_RX_ERR_reg(4*i+2) and i_HSSAER_RX_MSK_reg(4*i+2)) or (i_HSSAER_RX_ERR_reg(16+4*i+2) and i_HSSAER_RX_MSK_reg(16+4*i+2)) or (i_aux_err_cnt(2) and i_aux_err_cnt_msk(2));
                v_glbl_err_of_msk := v_glbl_err_of_msk or (i_HSSAER_RX_ERR_reg(4*i+3) and i_HSSAER_RX_MSK_reg(4*i+3)) or (i_HSSAER_RX_ERR_reg(16+4*i+3) and i_HSSAER_RX_MSK_reg(16+4*i+3)) or (i_aux_err_cnt(3) and i_aux_err_cnt_msk(3));
            end loop;
        end if;

        i_glbl_err <= v_glbl_err_of & v_glbl_err_to & v_glbl_err_rx & v_glbl_err_ko;
        i_glbl_err_msk <= v_glbl_err_of_msk & v_glbl_err_to_msk & v_glbl_err_rx_msk & v_glbl_err_ko_msk;
    end process p_glbl_hssaer_rx_err;


    -- ------------------------------------------------------------------------
    -- HSSAER Error Mask register
    -- ------------------------------------------------------------------------
    -- HSSAER_RX_MSK_reg - HSSAER Rx error mask register R/W
    --

    i_HSSAER_RX_MSK_rd <= i_HSSAER_RX_MSK_reg;

    -- ------------------------------------------------------------------------
    -- Rx Datapath Control register
    -- ------------------------------------------------------------------------
    -- RX_CTRL_reg - R/W

    i_RRxSaerChanEn  <= i_RX_CTRL_reg(27 downto 24)   when C_RX_R_HAS_HSSAER    else (others => '0');
    i_RRxSpnnLnkEn   <= i_RX_CTRL_reg(19)             when C_RX_R_HAS_SPNNLNK   else '0';
    i_RRxGtpEn       <= i_RX_CTRL_reg(18)             when C_RX_R_HAS_GTP       else '0';
    i_RRxPaerEn      <= i_RX_CTRL_reg(17)             when C_RX_R_HAS_PAER      else '0';
    i_RRxHSSaerEn    <= i_RX_CTRL_reg(16)             when C_RX_R_HAS_HSSAER    else '0';
    i_LRxSaerChanEn  <= i_RX_CTRL_reg(11 downto  8)   when C_RX_L_HAS_HSSAER    else (others => '0');
    i_LRxSpnnLnkEn   <= i_RX_CTRL_reg(3)              when C_RX_L_HAS_SPNNLNK   else '0';
    i_LRxGtpEn       <= i_RX_CTRL_reg(2)              when C_RX_L_HAS_GTP       else '0';
    i_LRxPaerEn      <= i_RX_CTRL_reg(1)              when C_RX_L_HAS_PAER      else '0';
    i_LRxHSSaerEn    <= i_RX_CTRL_reg(0)              when C_RX_L_HAS_HSSAER    else '0';

    i_RX_CTRL_rd <= c_zero_vect(31 downto 28) &
                    i_RRxSaerChanEn           &
                    c_zero_vect(23 downto 20) &
                    i_RRxSpnnLnkEn            &
                    i_RRxGtpEn                &
                    i_RRxPaerEn               &
                    i_RRxHSSaerEn             &
                    c_zero_vect(15 downto 12) &
                    i_LRxSaerChanEn           &
                    c_zero_vect( 7 downto  4) &
                    i_LRxSpnnLnkEn            &
                    i_LRxGtpEn                &
                    i_LRxPaerEn               &
                    i_LRxHSSaerEn             ;

    RRxSaerChanEn_o <= i_RRxSaerChanEn(C_RX_HSSAER_N_CHAN-1 downto 0);
    RRxSpnnLnkEn_o  <= i_RRxSpnnLnkEn;
    RRxGtpEn_o      <= i_RRxGtpEn;
    RRxPaerEn_o     <= i_RRxPaerEn;
    RRxHSSaerEn_o   <= i_RRxHSSaerEn;
    LRxSaerChanEn_o <= i_LRxSaerChanEn(C_RX_HSSAER_N_CHAN-1 downto 0);
    LRxSpnnLnkEn_o  <= i_LRxSpnnLnkEn;
    LRxGtpEn_o      <= i_LRxGtpEn;
    LRxPaerEn_o     <= i_LRxPaerEn;
    LRxHSSaerEn_o   <= i_LRxHSSaerEn;


    -- ------------------------------------------------------------------------
    -- Rx Datapath Configuration register
    -- ------------------------------------------------------------------------
    -- RX_CNFG_reg - R/W

    i_RxPaerAckRelDelay    <= i_RX_CNFG_reg(31 downto 24)   when C_RX_HAS_ALMOST_ONE_PAER else (others => '0');
    i_RxPaerAckSetDelay    <= i_RX_CNFG_reg(23 downto 16)   when C_RX_HAS_ALMOST_ONE_PAER else (others => '0');
    i_RxPaerSampleDelay    <= i_RX_CNFG_reg(15 downto  8)   when C_RX_HAS_ALMOST_ONE_PAER else (others => '0');
    i_RxPaerIgnoreFifoFull <= i_RX_CNFG_reg(4)              when C_RX_HAS_ALMOST_ONE_PAER else '0';
    i_RxPaerAckActLevel    <= i_RX_CNFG_reg(1)              when C_RX_HAS_ALMOST_ONE_PAER else '0';
    i_RxPaerReqActLevel    <= i_RX_CNFG_reg(0)              when C_RX_HAS_ALMOST_ONE_PAER else '0';

    i_RX_CNFG_rd <= i_RxPaerAckRelDelay       &
                    i_RxPaerAckSetDelay       &
                    i_RxPaerSampleDelay       &
                    c_zero_vect( 7 downto  5) &
                    i_RxPaerIgnoreFifoFull    &
                    c_zero_vect( 3 downto  2) &
                    i_RxPaerAckActLevel       &
                    i_RxPaerReqActLevel       ;

    RxPaerAckRelDelay_o    <= i_RxPaerAckRelDelay;
    RxPaerAckSetDelay_o    <= i_RxPaerAckSetDelay;
    RxPaerSampleDelay_o    <= i_RxPaerSampleDelay;
    RxPaerIgnoreFifoFull_o <= i_RxPaerIgnoreFifoFull;
    RxPaerAckActLevel_o    <= i_RxPaerAckActLevel;
    RxPaerReqActLevel_o    <= i_RxPaerReqActLevel;


    -- ------------------------------------------------------------------------
    -- Tx Datapath Control register
    -- ------------------------------------------------------------------------
    i_TxTSMaskSel     <= i_TX_CTRL_reg(21 downto 20);
    i_TxTSTimeoutSel  <= i_TX_CTRL_reg(19 downto 16);
    i_TxTSRearmCmd    <= i_TX_CTRL_reg(15); -- **** NOTE: Cleared after Write
    i_TxTSRetrigCmd   <= i_TX_CTRL_reg(14); -- **** NOTE: Cleared after Write
    i_TxTSMode        <= i_TX_CTRL_reg(13 downto 12)   when (i_OnlyEventsTx = '0') else "01"; -- When data doesn't contain Timestamp, the timing mode is set to "Asap"
    i_TxSaerChanEn    <= i_TX_CTRL_reg(11 downto  8)   when C_TX_HAS_HSSAER  else (others => '0');
--                    <= i_TX_CTRL_reg(7);               -- Available   
    i_TxDestSwitch    <= i_TX_CTRL_reg(6 downto 4)     when (C_TX_HAS_HSSAER or C_TX_HAS_SPNNLNK or C_TX_HAS_GTP or C_TX_HAS_PAER) else "000";
    i_TxSpnnLnkEn     <= i_TX_CTRL_reg(3)              when C_TX_HAS_SPNNLNK else '0';
    i_TxGtpEn         <= i_TX_CTRL_reg(2)              when C_TX_HAS_GTP     else '0';
    i_TxPaerEn        <= i_TX_CTRL_reg(1)              when C_TX_HAS_PAER    else '0';
    i_TxHSSaerEn      <= i_TX_CTRL_reg(0)              when C_TX_HAS_HSSAER  else '0';

    i_TX_CTRL_rd <= c_zero_vect(31 downto 22)    &
                    i_TxTSMaskSel(1 downto 0)    &
                    i_TxTSTimeoutSel(3 downto 0) &
                    TxTSTimeoutCounts_i          &
                    TxTSRetrigStatus_i           &   -- From input
                    i_TxTSMode                   &
                    i_TxSaerChanEn               &
                    c_zero_vect(7)               &
                    i_TxDestSwitch               &
                    i_TxSpnnLnkEn                &
                    i_TxGtpEn                    &
                    i_TxPaerEn                   &
                    i_TxHSSaerEn                 ;

    TxSaerChanEn_o <= i_TxSaerChanEn(C_TX_HSSAER_N_CHAN-1 downto 0);
    TxDestSwitch_o <= i_TxDestSwitch;
    TxSpnnLnkEn_o  <= i_TxSpnnLnkEn;
    TxGtpEn_o      <= i_TxGtpEn;
    TxPaerEn_o     <= i_TxPaerEn;
    TxHSSaerEn_o   <= i_TxHSSaerEn;
    
     
    TxTSTimeoutSel_o <= i_TxTSTimeoutSel;   
    TxTSRetrigCmd_o  <= i_TxTSRetrigCmd; 
    TxTSRearmCmd_o   <= i_TxTSRearmCmd;  
    TxTSMode_o       <= i_TxTSMode;  
    TxTSMaskSel_o    <= i_TxTSMaskSel;
    -- ------------------------------------------------------------------------
    -- Tx Datapath Configuration register
    -- ------------------------------------------------------------------------
    -- TX_CNFG_reg - R/W

    i_TxPaerAckActLevel    <= i_TX_CNFG_reg(1) when C_TX_HAS_PAER else '0';
    i_TxPaerReqActLevel    <= i_TX_CNFG_reg(0) when C_TX_HAS_PAER else '0';

    i_TX_CNFG_rd <= c_zero_vect(31 downto  5) &
                    c_zero_vect(4)            &                   -- Reserved for future use
                    c_zero_vect( 3 downto  2) &
                    i_TxPaerAckActLevel       &
                    i_TxPaerReqActLevel       ;

    --TxPaerIgnoreFifoFull_o <= i_TxPaerIgnoreFifoFull;         -- Reserved for future use
    TxPaerAckActLevel_o    <= i_TxPaerAckActLevel;
    TxPaerReqActLevel_o    <= i_TxPaerReqActLevel;


    -- ------------------------------------------------------------------------
    -- IP_CONFIG Register
    -- ------------------------------------------------------------------------
    -- IP_CONFIG_rd - R/O

    i_IP_CONFIG_rd <= c_zero_vect(31 downto 16)                              &
                      c_zero_vect(15 downto 14)                              &
                      std_logic_vector(to_unsigned(C_TX_HSSAER_N_CHAN-1,2))  &
                      To_StdLogic(C_TX_HAS_SPNNLNK)                          &
                      To_StdLogic(C_TX_HAS_GTP)                              &
                      To_StdLogic(C_TX_HAS_PAER)                             &
                      To_StdLogic(C_TX_HAS_HSSAER)                           &
                      c_zero_vect(15 downto 14)                              &
                      std_logic_vector(to_unsigned(C_RX_HSSAER_N_CHAN-1,2))  &
                      To_StdLogic(C_RX_HAS_ALMOST_ONE_SPNNLNK)               &
                      To_StdLogic(C_RX_HAS_ALMOST_ONE_GTP)                   &
                      To_StdLogic(C_RX_HAS_ALMOST_ONE_PAER)                  &
                      To_StdLogic(C_RX_HAS_ALMOST_ONE_HSSAER)                ;


    -- ------------------------------------------------------------------------
    -- FIFO Threshold register
    -- ------------------------------------------------------------------------
    -- i_FIFOTHRESH_rd r/w

    i_FIFOTHRESH_rd <= c_zero_vect(31 downto 11)                              &
                       i_FIFOTHRESH_reg(10 downto 0)                          ;

    -- ------------------------------------------------------------------------
    -- ID Register
    -- ------------------------------------------------------------------------
    -- ID_rd - R/O

    i_ID_rd <= std_logic_vector(to_unsigned(natural(character'pos(cVer(3))), 8)) &
               std_logic_vector(to_unsigned(natural(character'pos(cVer(2))), 8)) &
               std_logic_vector(to_unsigned(natural(character'pos(cVer(1))), 8)) &
               cMAJOR                                                            &
               cMINOR                                                            ;


    -- ------------------------------------------------------------------------
    -- AUX Datapath Control register
    -- ------------------------------------------------------------------------
    -- AUX_CTRL_reg - R/W

    i_AUXRxSaerChanEn  <= i_AUX_CTRL_reg(11 downto  8)   when C_RX_A_HAS_HSSAER  else (others => '0');
    i_AUXRxSpnnLnkEn   <= i_AUX_CTRL_reg(3)              when C_RX_A_HAS_SPNNLNK else '0';
    i_AUXRxGtpEn       <= i_AUX_CTRL_reg(2)              when C_RX_A_HAS_GTP     else '0';
    i_AUXRxPaerEn      <= i_AUX_CTRL_reg(1)              when C_RX_A_HAS_PAER    else '0';
    i_AUXRxHSSaerEn    <= i_AUX_CTRL_reg(0)              when C_RX_A_HAS_HSSAER  else '0';

    i_AUX_CTRL_rd <= c_zero_vect(31 downto 12) &
                     i_AUXRxSaerChanEn         &
                     c_zero_vect( 7 downto  4) &
                     i_AUXRxSpnnLnkEn          &
                     i_AUXRxGtpEn              &
                     i_AUXRxPaerEn             &
                     i_AUXRxHSSaerEn           ;

    AUXRxSaerChanEn_o <= i_AUXRxSaerChanEn(C_RX_HSSAER_N_CHAN-1 downto 0);
    AUXRxSpnnLnkEn_o  <= i_AUXRxSpnnLnkEn; 
    AUXRxGtpEn_o      <= i_AUXRxGtpEn;
    AUXRxPaerEn_o     <= i_AUXRxPaerEn;
    AUXRxHSSaerEn_o   <= i_AUXRxHSSaerEn;

    -- ------------------------------------------------------------------------
    -- AUX HSSAER Error Mask register
    -- ------------------------------------------------------------------------
    -- HSSAER_AUX_RX_MSK_reg - HSSAER AUX Rx error mask register R/W
    --

    i_HSSAER_AUX_RX_MSK_rd <= i_HSSAER_AUX_RX_MSK_reg;

    -- ------------------------------------------------------------------------
    -- AUX HSSAER Error Counter Threshold register
    -- ------------------------------------------------------------------------
    -- HSSAER_AUX_RX_ERR_THR_reg - HSSAER AUX Rx Counter Error Threshold R/W
    --

    i_HSSAER_AUX_RX_ERR_THR_rd <= i_HSSAER_AUX_RX_ERR_THR_reg;

    -- ------------------------------------------------------------------------
    -- AUX HSSAER Error Counter CH0, CH1, CH2, CH3 register
    -- ------------------------------------------------------------------------
    --

    p_hssaer_aux_rx_err_cnt : process (S_AXI_ACLK)
     begin
       if (rising_edge(S_AXI_ACLK)) then
          if (S_AXI_ARESETN = '0') then
               for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                 i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_ko <= (others => '0');
                 i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_rx <= (others => '0');
                 i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_to <= (others => '0');
                 i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_of <= (others => '0');
               end loop;
          else
                 for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                   if (i_readRxErrCnt(i)='1') then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_ko  <= (others => '0');
                   elsif (AUXRxSaerStat_i(i).err_ko='1' and to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_ko))/=255) then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_ko  <= i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_ko + "01";
                   end if;

                   if (i_readRxErrCnt(i)='1') then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_rx  <= (others => '0');
                   elsif (AUXRxSaerStat_i(i).err_rx='1' and to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_rx))/=255) then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_rx  <= i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_rx + "01";
                   end if;

                   if (i_readRxErrCnt(i)='1') then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_to  <= (others => '0');
                   elsif (AUXRxSaerStat_i(i).err_to='1' and to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_to))/=255) then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_to  <= i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_to + "01";
                   end if;

                   if (i_readRxErrCnt(i)='1') then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_of  <= (others => '0');
                   elsif (AUXRxSaerStat_i(i).err_of='1' and to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_of))/=255) then
                      i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_of  <= i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_of + "01";
                   end if;
                 end loop;
          end if;
        end if;
     end process p_hssaer_aux_rx_err_cnt;

    i_HSSAER_AUX_RX_ERR_CNT_rd <= i_HSSAER_AUX_RX_ERR_CNT_reg;


    p_aux_err : process (i_HSSAER_AUX_RX_ERR_CNT_reg, i_HSSAER_AUX_RX_ERR_THR_reg, i_HSSAER_AUX_RX_MSK_reg)
        variable v_err_ko, v_err_ko_msk : std_logic;
        variable v_err_of, v_err_of_msk : std_logic;
        variable v_err_rx, v_err_rx_msk : std_logic;
        variable v_err_to, v_err_to_msk : std_logic;
    begin
        v_err_ko := '0'; v_err_ko_msk := '0';
        v_err_of := '0'; v_err_of_msk := '0';
        v_err_rx := '0'; v_err_rx_msk := '0';
        v_err_to := '0'; v_err_to_msk := '0';
        if (C_RX_A_HAS_HSSAER) then
            for i in 0 to C_RX_HSSAER_N_CHAN-1 loop
                if ( to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_ko)) >= to_integer(unsigned(i_HSSAER_AUX_RX_ERR_THR_reg(7  downto  0))) ) then
                  v_err_ko := v_err_ko or '1';
                  v_err_ko_msk := v_err_ko and i_HSSAER_AUX_RX_MSK_reg(4*i+0);
                else
                  v_err_ko := v_err_ko;
                  v_err_ko_msk := v_err_ko_msk;
                end if;

                if ( to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_rx)) >= to_integer(unsigned(i_HSSAER_AUX_RX_ERR_THR_reg(15 downto  8))) ) then
                  v_err_rx := v_err_rx or '1';
                  v_err_rx_msk := v_err_rx and i_HSSAER_AUX_RX_MSK_reg(4*i+1);
                else
                  v_err_rx := v_err_rx;
                  v_err_rx_msk := v_err_rx_msk;
                end if;
                
                if ( to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_to)) >= to_integer(unsigned(i_HSSAER_AUX_RX_ERR_THR_reg(23 downto 16))) ) then
                  v_err_to := v_err_to or '1';
                  v_err_to_msk := v_err_to and i_HSSAER_AUX_RX_MSK_reg(4*i+2);
                else
                  v_err_to := v_err_to;
                  v_err_to_msk := v_err_to_msk;
                end if;
                
                if ( to_integer(unsigned(i_HSSAER_AUX_RX_ERR_CNT_reg(i).cnt_of)) >= to_integer(unsigned(i_HSSAER_AUX_RX_ERR_THR_reg(31 downto 24))) ) then
                  v_err_of := v_err_of or '1';
                  v_err_of_msk := v_err_of and i_HSSAER_AUX_RX_MSK_reg(4*i+3);
                else
                  v_err_of := v_err_of;
                  v_err_of_msk := v_err_of_msk;
                end if;
            end loop;
        else    
           v_err_ko := '0';
           v_err_ko_msk := '0';
           v_err_rx := '0';
           v_err_rx_msk := '0';
           v_err_to := '0';
           v_err_to_msk := '0';
           v_err_of := '0';
           v_err_of_msk := '0';
        end if;

        i_aux_err_cnt <= v_err_of & v_err_to & v_err_rx & v_err_ko;
        i_aux_err_cnt_msk <= v_err_of_msk & v_err_to_msk & v_err_rx_msk & v_err_ko_msk;
    
    end process p_aux_err;


    -- ------------------------------------------------------------------------
    -- SpiNNaker START Key Command
    -- ------------------------------------------------------------------------
    -- i_SPNN_START_KEY_rd r/w

    i_SPNN_START_KEY_rd <= i_SPNN_START_KEY_reg;
    
    
    -- ------------------------------------------------------------------------
    -- SpiNNaker STOP Key Command
    -- ------------------------------------------------------------------------
    -- i_SPNN_STOP_KEY_rd r/w

    i_SPNN_STOP_KEY_rd <= i_SPNN_STOP_KEY_reg;
            
    
    -- ------------------------------------------------------------------------
    -- SpiNNaker TX Data Mask Command
    -- ------------------------------------------------------------------------
    -- i_SPNN_TX_MASK_rd r/w

    i_SPNN_TX_MASK_rd <= i_SPNN_TX_MASK_reg;  
              
    
    -- ------------------------------------------------------------------------
    -- SpiNNaker RX Data Mask Command
    -- ------------------------------------------------------------------------
    -- i_SPNN_RX_MASK_rd r/w

    i_SPNN_RX_MASK_rd <= i_SPNN_RX_MASK_reg;

    -- ------------------------------------------------------------------------
    -- SpiNNaker Control Register
    -- ------------------------------------------------------------------------
    -- i_SPNN_CTRL_rd r/w

    i_SPNN_CTRL_rd <= i_SPNN_CTRL_reg;

    -- ------------------------------------------------------------------------
    -- SpiNNaker Status Register
    -- ------------------------------------------------------------------------
    -- i_SPNN_STATUS_rd r/w

    i_SPNN_STATUS_rd <= SPNN_STATUS_i;

    -- ------------------------------------------------------------------------
    -- Tlast TimeOut register
    -- ------------------------------------------------------------------------
    i_TlastTO_rd <= i_TlastTO;
    TlastTO_o <= i_TlastTO;
    TlastTOwritten_o <= i_TlastTowritten;

    -- ------------------------------------------------------------------------
    -- Tlast Counter register
    -- ------------------------------------------------------------------------
    i_TlastCnt_rd <= TlastCnt_i;

    -- ------------------------------------------------------------------------
    -- TData Counter register
    -- ------------------------------------------------------------------------
    i_TDataCnt_rd <= TDataCnt_i;




end architecture rtl;

----------------------------------------------------------------------
