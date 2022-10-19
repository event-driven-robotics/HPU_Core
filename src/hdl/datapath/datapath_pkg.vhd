library ieee;
    use ieee.std_logic_1164.all;

package constants is 
    
   constant C_INTERNAL_DSIZE : natural := 32;
   
end package constants;

-- -----------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    
library work;
  use work.constants.all;
          
package types is

-- PAER types

  type t_PaerSrc is record
      --idx : std_logic_vector(C_PAER_DSIZE-1 downto 0);
      idx : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      vld : std_logic;
  end record t_PaerSrc;

  type t_PaerSrc_array is array (natural range <>) of t_PaerSrc;

  type t_PaerDst is record
      rdy : std_logic;
  end record t_PaerDst;

  type t_PaerDst_array is array (natural range <>) of t_PaerDst;

  -- Configurations from uP

  type t_XConChanCfg is record
      zero    : std_logic;
      lpbk    : std_logic;
      idx     : natural range 0 to 3;
  end record t_XConChanCfg;

  type t_XConChanCfg_array is array (natural range <>) of t_XConChanCfg;

  type t_XConCfg is record
      rx1Cfg : t_XConChanCfg_array(0 to 3);
      rx2Cfg : t_XConChanCfg_array(0 to 3);
      rx3Cfg : t_XConChanCfg_array(0 to 3);
  end record t_XConCfg;
  --
  --type t_ArbiterCfg is record
  --    TODO : std_logic;
  --end record t_ArbiterCfg;
  --
  --type t_SplitterCfg is record
  --    TODO : std_logic;
  --end record t_SplitterCfg;

  -- Status to uP
  type t_TxSaerStat is record
      run  : std_logic;
      last : std_logic;
  end record t_TxSaerStat;

  type t_TxSaerStat_array is array (natural range <>) of t_TxSaerStat;

  type t_RxSaerStat is record
      err_ko : std_logic;
      err_rx : std_logic;
      err_to : std_logic;
      err_of : std_logic;
      int    : std_logic;
      run    : std_logic;
  end record t_RxSaerStat;

  type t_RxSaerStat_array is array (natural range <>) of t_RxSaerStat;

  type t_TxGtpStat is record
      pll_alarm           : std_logic;
      TxGtpEventRate      : std_logic_vector(15 downto 0); -- Count per millisecond 
      TxGtpMessageRate    : std_logic_vector( 7 downto 0); -- Count per millisecond 
  end record t_TxGtpStat;
  
  type t_TxGtpStat_array is array (natural range <>) of t_TxGtpStat;

  type t_RxGtpStat is record
      pll_alarm           : std_logic;
      rx_disaligned       : std_logic;
      RxGtpEventRate      : std_logic_vector(15 downto 0); -- Count per millisecond 
      RxGtpMessageRate    : std_logic_vector( 7 downto 0); -- Count per millisecond 
  end record t_RxGtpStat;
  
  type t_RxGtpStat_array is array (natural range <>) of t_RxGtpStat;
          
  type t_TxSpnnlnkStat is record
      dump_mode  : std_logic;
  end record t_TxSpnnlnkStat;

  type t_TxSpnnlnkStat_array is array (natural range <>) of t_TxSpnnlnkStat;

  type t_RxSpnnlnkStat is record
      parity_err : std_logic;
      rx_err     : std_logic;
  end record t_RxSpnnlnkStat;

  type t_RxSpnnlnkStat_array is array (natural range <>) of t_RxSpnnlnkStat;
  
  type SpnnCmd_type is record
      start_key : std_logic_vector(31 downto 0);
      stop_key  : std_logic_vector(31 downto 0);
  end record SpnnCmd_type;

  type t_RxErrStat is record
      cnt_ko : std_logic_vector(7 downto 0);
      cnt_rx : std_logic_vector(7 downto 0);
      cnt_to : std_logic_vector(7 downto 0);
      cnt_of : std_logic_vector(7 downto 0);
  end record t_RxErrStat;

  type t_RxErrStat_array is array (natural range <>) of t_RxErrStat;

end package types;

-- -----------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    
library work;
  use work.constants.all;
  use work.types.all;

package components is

  component hpu_rx_datapath is
    generic (
      C_FAMILY                        : string                := "zynquplus"; -- "zynq", "zynquplus" 
      --
      C_OUTPUT_DSIZE                  : natural range 1 to 32 := 32;
      C_PAER_DSIZE                    : positive              := 20;
      C_HAS_PAER                      : boolean               := true;
      C_HAS_HSSAER                    : boolean               := true;
      C_HSSAER_N_CHAN                 : natural range 1 to 4  := 4;
      C_HAS_GTP                       : boolean               := true;
      C_GTP_DSIZE                     : positive              := 16;
      C_GTP_TXUSRCLK2_PERIOD_NS       : real                  := 6.4; 
      C_GTP_RXUSRCLK2_PERIOD_NS       : real                  := 6.4; 
      C_HAS_SPNNLNK                   : boolean               := true;
      C_PSPNNLNK_WIDTH                : natural range 1 to 32 := 32;
      C_SIM_TIME_COMPRESSION          : boolean               := false   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
      );
  port (
      -- **********************************************
      -- Barecontrol
      -- **********************************************
      -- Resets
      nRst                            : in  std_logic;
      -- System Clock domain
      Clk_i                           : in  std_logic;
      En1Sec_i                        : in  std_logic;
      -- HSSAER Clocks domain
      Clk_hs_p                        : in  std_logic;
      Clk_hs_n                        : in  std_logic;
      Clk_ls_p                        : in  std_logic;
      Clk_ls_n                        : in  std_logic;
  
  
      -- **********************************************
      -- Controls
      -- **********************************************
      --
      -- In case of aux channel the HPU header is 
      -- adapted to what received
      -- ----------------------------------------------
      Aux_Channel_i                   : in  std_logic;  
  
      -- **********************************************
      -- uController Interface
      -- **********************************************
  
      -- Control input signals
      -- ----------------------------------------------
      PaerFlushFifos_i                : in  std_logic;
      
      -- Control output signals
      -- ----------------------------------------------    
      RxGtpAlignRequest_o             : out std_logic; 
  
      -- Status signals
      -- ----------------------------------------------
      PaerFifoFull_o                  : out std_logic;
      RxSaerStat_o                    : out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
      RxGtpStat_o                     : out t_RxGtpStat;
      RxSpnnlnkStat_o                 : out t_RxSpnnlnkStat;
      
      -- GTP Statistics        
      RxGtpDataRate_o                 : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RxGtpAlignRate_o                : out std_logic_vector( 7 downto 0); -- Count per millisecond 
      RxGtpMsgRate_o                  : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RxGtpIdleRate_o                 : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RxGtpEventRate_o                : out std_logic_vector(15 downto 0); -- Count per millisecond 
      RxGtpMessageRate_o              : out std_logic_vector( 7 downto 0); -- Count per millisecond 
  
      -- Configuration signals
      -- ----------------------------------------------
  
      -- Source I/F configurations
      EnablePAER_i                    : in  std_logic;
      EnableHSSAER_i                  : in  std_logic;
      EnableGTP_i                     : in  std_logic;
      EnableSPNNLNK_i                 : in  std_logic;
      -- PAER
      RxPaerHighBits_i                : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
      PaerReqActLevel_i               : in  std_logic;
      PaerAckActLevel_i               : in  std_logic;
      PaerIgnoreFifoFull_i            : in  std_logic;
      PaerAckSetDelay_i               : in  std_logic_vector(7 downto 0);
      PaerSampleDelay_i               : in  std_logic_vector(7 downto 0);
      PaerAckRelDelay_i               : in  std_logic_vector(7 downto 0);
      -- HSSAER
      RxSaerHighBits0_i               : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
      RxSaerHighBits1_i               : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
      RxSaerHighBits2_i               : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
      RxSaerHighBits3_i               : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
      HSSaerChanEn_i                  : in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
      -- GTP
      RxGtpHighBits_i                 : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
      -- SpiNNaker
      SpnnStartKey_i                  : in  std_logic_vector(31 downto 0);
      SpnnStopKey_i                   : in  std_logic_vector(31 downto 0);
      SpnncmdStart_o                  : out std_logic;
      SpnncmdStop_o                   : out std_logic;
      SpnnRxMask_i                    : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask
      SpnnKeysEnable_i                : in  std_logic;
      SpnnParityErr_o                 : out std_logic;
      SpnnRxErr_o                     : out std_logic;
              
              
      -- **********************************************
      -- Source Interfaces
      -- **********************************************
  
      -- Parallel AER interface
      -- ----------------------------------------------
      PAER_Addr_i                     : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
      PAER_Req_i                      : in  std_logic;
      PAER_Ack_o                      : out std_logic;
  
      -- HSSAER interface
      -- ----------------------------------------------
      HSSAER_Rx_i                     : in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);
  
      -- GTP Wizard Interface
      -- ----------------------------------------------
      GTP_RxUsrClk2_i                 : in  std_logic;   
      GTP_SoftResetRx_o               : out  std_logic;                                          
      GTP_DataValid_o                 : out std_logic;                                           
      GTP_Rxuserrdy_o                 : out std_logic;                                           
      GTP_Rxdata_i                    : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);            
      GTP_Rxchariscomma_i             : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      GTP_Rxcharisk_i                 : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      GTP_Rxdisperr_i                 : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      GTP_Rxnotintable_i              : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      GTP_Rxbyteisaligned_i           : in  std_logic;                                           
      GTP_Rxbyterealign_i             : in  std_logic;                                           
      GTP_PllLock_i                   : in  std_logic;                                           
      GTP_PllRefclklost_i             : in  std_logic;                                         
  
      -- GTH Wizard Interface
      -- ----------------------------------------------
      GTH_gtwiz_userclk_rx_usrclk2_i  : in std_logic_vector(0 downto 0);
      GTH_gtwiz_reset_all_o           : out std_logic_vector(0 downto 0);                        -- ASYNC     --    GTH_Gtwiz_userdata_rx_i    : in  std_logic_vector(GT_DATA_WIDTH_g-1 downto 0);       -- RXUSRCLK2 --
      GTH_gtwiz_userdata_rx_i         : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);    
      GTH_Rxctrl2_i                   : in  std_logic_vector(7 downto 0);    -- (RXCHARISCOMMA)  -- RXUSRCLK2 --
      GTH_Rxctrl0_i                   : in  std_logic_vector(15 downto 0);   -- (RXCHARISK)      -- RXUSRCLK2 --
      GTH_Rxctrl1_i                   : in  std_logic_vector(15 downto 0);   -- (RXDISPERR)      -- RXUSRCLK2 --
      GTH_Rxctrl3_i                   : in  std_logic_vector(7 downto 0);    -- (RXNOTINTABLE)   -- RXUSRCLK2 --
      GTH_Rxbyteisaligned_i           : in  std_logic_vector(0 downto 0);                        -- RXUSRCLK2 --
      GTH_Rxbyterealign_i             : in  std_logic_vector(0 downto 0);                        -- RXUSRCLK2 --
      GTH_Qpll_lock_i                 : in  std_logic_vector(0 downto 0);                        -- ASYNC     --
      GTH_Qpll_refclklost_i           : in  std_logic_vector(0 downto 0);                        -- QPLL0LOCKDETCL    
      
      -- SpiNNlink
      -- ----------------------------------------------
      SPNN_Data_i                     : in  std_logic_vector(6 downto 0); 
      SPNN_Ack_o                      : out std_logic;
  
  
      -- **********************************************
      -- Received Data Output
      -- **********************************************
      RxData_o                        : out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
      RxDataSrcRdy_o                  : out std_logic;
      RxDataDstRdy_i                  : in  std_logic;
  
      RxGtpMsg_o                      : out std_logic_vector(7 downto 0);
      RxGtpMsgSrcRdy_o                : out std_logic;
      RxGtpMsgDstRdy_i                : in  std_logic;    
      
      
      -- **********************************************
      -- Debug signals
      -- **********************************************
      dbg_PaerDataOk                  : out std_logic;
      DBG_src_rdy                     : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
      DBG_dst_rdy                     : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
      DBG_err                         : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);  
      DBG_run                         : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
      DBG_RX                          : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
  
      DBG_FIFO_0                      : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      DBG_FIFO_1                      : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      DBG_FIFO_2                      : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      DBG_FIFO_3                      : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      DBG_FIFO_4                      : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)            
      );
  end component hpu_rx_datapath;

  component hpu_tx_datapath is
    generic (
      C_FAMILY                    : string                := "zynquplus"; -- "zynq", "zynquplus" 
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

  component merge_rdy is
      generic (
          N_CHAN        : natural := 4
      );                
      port (            
          nRst          : in  std_logic;
          Clk           : in  std_logic;
                        
          InVld_i       : in  std_logic;
          OutRdy_o      : out std_logic;
                        
          OutVldVect_o  : out std_logic_vector(N_CHAN-1 downto 0);
          InRdyVect_i   : in  std_logic_vector(N_CHAN-1 downto 0)
      );
  end component merge_rdy;
  
  component PAER_arbiter is
      generic (
          C_NUM_CHAN         : natural range 1 to 4 := 2;
          C_ODATA_WIDTH      : natural
      );
      port (
          Clk                : in  std_logic;
          nRst               : in  std_logic;
  
          --ArbCfg_i           : in  t_ArbiterCfg;
  
          SplittedPaerSrc_i  : in  t_PaerSrc_array(0 to C_NUM_CHAN-1);
          SplittedPaerDst_o  : out t_PaerDst_array(0 to C_NUM_CHAN-1);
  
          PaerData_o         : out std_logic_vector(C_ODATA_WIDTH-1 downto 0);
          PaerSrcRdy_o       : out std_logic;
          PaerDstRdy_i       : in  std_logic
      );
  end component PAER_arbiter;
  
  component PAER_splitter is
      generic (
          C_NUM_CHAN         : natural range 1 to 4 := 2;
          C_IDATA_WIDTH      : natural
      );
      port (
          Clk                : in  std_logic;
          nRst               : in  std_logic;
          --
          ChEn_i             : in  std_logic_vector(C_NUM_CHAN-1 downto 0);
          --               
          PaerDataIn_i       : in  std_logic_vector(C_IDATA_WIDTH-1 downto 0);
          PaerSrcRdy_i       : in  std_logic;
          PaerDstRdy_o       : out std_logic;
          --               
          SplittedPaerSrc_o  : out t_PaerSrc_array(0 to C_NUM_CHAN-1);
          SplittedPaerDst_i  : in  t_PaerDst_array(0 to C_NUM_CHAN-1)
      );
  end component PAER_splitter;
  
  component req_fifo is
      generic (
          C_DATA_WIDTH : natural;         -- Number of input request lines
          C_IDX_WIDTH  : natural;         -- Width of the index bus in output (should be at least log2(C_DATA_WIDTH)
          C_FIFO_DEPTH : natural          -- Number of cells of the FIFO
      );
      port (
          Clk         : in  std_logic;
          nRst        : in  std_logic;
          PreFill_i   : in  std_logic;
          Push_i      : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
          Pop_i       : in  std_logic;
          Idx_o       : out std_logic_vector(C_IDX_WIDTH-1 downto 0);
          Empty_o     : out std_logic;
          Full_o      : out std_logic;
          Underflow_o : out std_logic;
          Overflow_o  : out std_logic
      );
  end component req_fifo;
  
  component FIFO_SAER_ZYNQ
    port (
      rst : in std_logic;
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      din : in std_logic_vector(31 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(31 downto 0);
      full : out std_logic;
      empty : out std_logic
    );
  end component;
  
  component FIFO_SAER_ZYNQUPLUS
    port (
      rst : in std_logic;
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      din : in std_logic_vector(31 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(31 downto 0);
      full : out std_logic;
      empty : out std_logic
    );
  end component;

end package components;
