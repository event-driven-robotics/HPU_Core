library ieee;
  use ieee.std_logic_1164.all;

library datapath;
  use datapath.constants.all;
  use datapath.types.all;
  use datapath.components.all;
  
library swissknife;
  use swissknife.types.all;
  
package components is

  component loopback is
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
  end component loopback;

  component neuserial_core is
    generic (
      -- -----------------------              
      -- GENERAL
      C_FAMILY                              : string                        := "zynq"; -- "zynq", "zynquplus" 
      -- -----------------------                
      -- PAER        
      C_RX_L_HAS_PAER                       : boolean                       := true;
      C_RX_R_HAS_PAER                       : boolean                       := true;
      C_RX_A_HAS_PAER                       : boolean                       := true;
      C_RX_PAER_L_SENS_ID                   : std_logic_vector(2 downto 0)  := "000";
      C_RX_PAER_R_SENS_ID                   : std_logic_vector(2 downto 0)  := "000";
      C_RX_PAER_A_SENS_ID                   : std_logic_vector(2 downto 0)  := "001";
      C_TX_HAS_PAER                         : boolean                       := true;
      C_PAER_DSIZE                          : natural range 1 to 29         := 24;
      -- -----------------------                    
      -- HSSAER
      C_RX_L_HAS_HSSAER                     : boolean                       := true;
      C_RX_R_HAS_HSSAER                     : boolean                       := true;
      C_RX_A_HAS_HSSAER                     : boolean                       := true;
      C_RX_HSSAER_N_CHAN                    : natural range 1 to 4          := 3;
      C_RX_SAER0_L_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";
      C_RX_SAER1_L_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";
      C_RX_SAER2_L_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";
      C_RX_SAER3_L_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";        
      C_RX_SAER0_R_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";
      C_RX_SAER1_R_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";
      C_RX_SAER2_R_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";
      C_RX_SAER3_R_SENS_ID                  : std_logic_vector(2 downto 0)  := "000";        
      C_RX_SAER0_A_SENS_ID                  : std_logic_vector(2 downto 0)  := "001";
      C_RX_SAER1_A_SENS_ID                  : std_logic_vector(2 downto 0)  := "001";
      C_RX_SAER2_A_SENS_ID                  : std_logic_vector(2 downto 0)  := "001";
      C_RX_SAER3_A_SENS_ID                  : std_logic_vector(2 downto 0)  := "001";
      C_TX_HAS_HSSAER                       : boolean                       := true;
      C_TX_HSSAER_N_CHAN                    : natural range 1 to 4          := 3;
      -- -----------------------                    
      -- GTP
      C_RX_L_HAS_GTP                        : boolean                       := true;
      C_RX_R_HAS_GTP                        : boolean                       := true;
      C_RX_A_HAS_GTP                        : boolean                       := true;
      C_GTP_RXUSRCLK2_PERIOD_NS             : real                          := 6.4;        
      C_TX_HAS_GTP                          : boolean                       := true;
      C_GTP_TXUSRCLK2_PERIOD_NS             : real                          := 6.4;  
      C_GTP_DSIZE                           : positive                      := 16;
      -- -----------------------                            
      -- SPINNLINK
      C_RX_L_HAS_SPNNLNK                    : boolean                       := true;
      C_RX_R_HAS_SPNNLNK                    : boolean                       := true;
      C_RX_A_HAS_SPNNLNK                    : boolean                       := true;
      C_TX_HAS_SPNNLNK                      : boolean                       := true;
      C_PSPNNLNK_WIDTH      	              : natural range 1 to 32         := 32;
      -- -----------------------            
      -- INTERCEPTION
      C_RX_L_INTERCEPTION                   : boolean                       := false;
      C_RX_R_INTERCEPTION                   : boolean                       := false;
      C_RX_A_INTERCEPTION                   : boolean                       := false;
      -- -----------------------
      -- SIMULATION
      C_SIM_TIME_COMPRESSION                : boolean                      := false   -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
      );
    port (
      --
      -- Clocks & Reset
      ---------------------
      -- System Clock domain
      CoreClk_i                             : in  std_logic;
      nRst_CoreClk_i                        : in  std_logic;
      Timing_i                              : in  time_tick;
      -- DMA Clock Domain
      AxisClk_i                             : in  std_logic;
      nRst_AxisClk_i                        : in  std_logic;
      -- HSSAER Clocks domain
      Clk_hs_p                              : in  std_logic;
      Clk_hs_n                              : in  std_logic;
      Clk_ls_p                              : in  std_logic;
      Clk_ls_n                              : in  std_logic;
      
      --
      -- TX Interface
      ---------------------
      -- Parallel AER
      Tx_PAER_Addr_o                        : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
      Tx_PAER_Req_o                         : out std_logic;
      Tx_PAER_Ack_i                         : in  std_logic;
      -- HSSAER channels
      Tx_HSSAER_o                           : out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
      -- GTP lines
      Tx_TxGtpMsg_i                         : in  std_logic_vector(7 downto 0);
      Tx_TxGtpMsgSrcRdy_i                   : in  std_logic;
      Tx_TxGtpMsgDstRdy_o                   : out std_logic;  
      Tx_TxGtpAlignRequest_i                : in  std_logic;
      Tx_TxGtpAlignFlag_o                   : out std_logic;
      Tx_GTP_TxUsrClk2_i                    : in  std_logic;   
      Tx_GTP_SoftResetTx_o                  : out  std_logic;                                          
      Tx_GTP_DataValid_o                    : out std_logic;    
      Tx_GTP_Txuserrdy_o                    : out std_logic;                                           
      Tx_GTP_Txdata_o                       : out std_logic_vector(C_GTP_DSIZE-1 downto 0);            
      Tx_GTP_Txcharisk_o                    : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      Tx_GTP_PllLock_i                      : in  std_logic;                                           
      Tx_GTP_PllRefclklost_i                : in  std_logic;         
      -- SpiNNaker Interface
      Tx_SPNN_Data_o                        : out std_logic_vector(6 downto 0);
      Tx_SPNN_Ack_i                         : in  std_logic; 
      
      --
      -- RX Left Interface
      ---------------------
      -- Parallel AER
      LRx_PAER_Addr_i                       : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
      LRx_PAER_Req_i                        : in  std_logic;
      LRx_PAER_Ack_o                        : out std_logic;
      -- HSSAER channels
      LRx_HSSAER_i                          : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
      -- GTP lines
      LRx_RxGtpMsg_o                        : out std_logic_vector(7 downto 0);
      LRx_RxGtpMsgSrcRdy_o                  : out std_logic;
      LRx_RxGtpMsgDstRdy_i                  : in  std_logic;  
      LRx_RxGtpAlignRequest_o               : out std_logic;
      LRx_GTP_RxUsrClk2_i                   : in  std_logic;
      LRx_GTP_SoftResetRx_o                 : out  std_logic;                                          
      LRx_GTP_DataValid_o                   : out std_logic;          
      LRx_GTP_Rxuserrdy_o                   : out std_logic;              
      LRx_GTP_Rxdata_i                      : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
      LRx_GTP_Rxchariscomma_i               : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      LRx_GTP_Rxcharisk_i                   : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      LRx_GTP_Rxdisperr_i                   : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      LRx_GTP_Rxnotintable_i                : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
      LRx_GTP_Rxbyteisaligned_i             : in  std_logic;                                           
      LRx_GTP_Rxbyterealign_i               : in  std_logic;         
      LRx_GTP_PllLock_i                     : in  std_logic;                                           
      LRx_GTP_PllRefclklost_i               : in  std_logic;      
      -- GTH lines 
      LRx_GTH_gtwiz_userclk_rx_usrclk2_i    : in std_logic_vector(0 downto 0);                
      LRx_GTH_gtwiz_reset_all_o             : out std_logic_vector(0 downto 0);               
      LRx_GTH_gtwiz_userdata_rx_i           : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);   
      LRx_GTH_Rxctrl2_i                     : in  std_logic_vector(7 downto 0);
      LRx_GTH_Rxctrl0_i                     : in  std_logic_vector(15 downto 0);
      LRx_GTH_Rxctrl1_i                     : in  std_logic_vector(15 downto 0);
      LRx_GTH_Rxctrl3_i                     : in  std_logic_vector(7 downto 0);
      LRx_GTH_Rxbyteisaligned_i             : in  std_logic_vector(0 downto 0);               
      LRx_GTH_Rxbyterealign_i               : in  std_logic_vector(0 downto 0);               
      LRx_GTH_Qpll_lock_i                   : in  std_logic_vector(0 downto 0);               
      LRx_GTH_Qpll_refclklost_i             : in  std_logic_vector(0 downto 0);               
    -- SpiNNaker Interface
      LRx_SPNN_Data_i                       : in  std_logic_vector(6 downto 0); 
      LRx_SPNN_Ack_o                        : out std_logic;
                            
      --
      -- RX Right Interface
      ---------------------
      -- Parallel AER
      RRx_PAER_Addr_i                       : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
      RRx_PAER_Req_i                        : in  std_logic;
      RRx_PAER_Ack_o                        : out std_logic;
      -- HSSAER channels
      RRx_HSSAER_i                          : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
      -- GTP lines
      RRx_RxGtpMsg_o                        : out std_logic_vector(7 downto 0);
      RRx_RxGtpMsgSrcRdy_o                  : out std_logic;
      RRx_RxGtpMsgDstRdy_i                  : in  std_logic;  
      RRx_RxGtpAlignRequest_o               : out std_logic;
      RRx_GTP_RxUsrClk2_i                   : in  std_logic;
      RRx_GTP_SoftResetRx_o                 : out  std_logic;                                          
      RRx_GTP_DataValid_o                   : out std_logic;          
      RRx_GTP_Rxuserrdy_o                   : out std_logic;              
      RRx_GTP_Rxdata_i                      : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
      RRx_GTP_Rxchariscomma_i               : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      RRx_GTP_Rxcharisk_i                   : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      RRx_GTP_Rxdisperr_i                   : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      RRx_GTP_Rxnotintable_i                : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
      RRx_GTP_Rxbyteisaligned_i             : in  std_logic;                                           
      RRx_GTP_Rxbyterealign_i               : in  std_logic;         
      RRx_GTP_PllLock_i                     : in  std_logic;                                           
      RRx_GTP_PllRefclklost_i               : in  std_logic;
      -- GTH lines 
      RRx_GTH_gtwiz_userclk_rx_usrclk2_i    : in std_logic_vector(0 downto 0);                
      RRx_GTH_gtwiz_reset_all_o             : out std_logic_vector(0 downto 0);               
      RRx_GTH_gtwiz_userdata_rx_i           : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);   
      RRx_GTH_Rxctrl2_i                     : in  std_logic_vector(7 downto 0);
      RRx_GTH_Rxctrl0_i                     : in  std_logic_vector(15 downto 0);
      RRx_GTH_Rxctrl1_i                     : in  std_logic_vector(15 downto 0);
      RRx_GTH_Rxctrl3_i                     : in  std_logic_vector(7 downto 0);
      RRx_GTH_Rxbyteisaligned_i             : in  std_logic_vector(0 downto 0);               
      RRx_GTH_Rxbyterealign_i               : in  std_logic_vector(0 downto 0);               
      RRx_GTH_Qpll_lock_i                   : in  std_logic_vector(0 downto 0);               
      RRx_GTH_Qpll_refclklost_i             : in  std_logic_vector(0 downto 0);  
      -- SpiNNaker Interface
      RRx_SPNN_Data_i                       : in  std_logic_vector(6 downto 0); 
      RRx_SPNN_Ack_o                        : out std_logic;
                    
      --
      -- Aux Interface
      ---------------------
      -- Parallel AER
      AuxRx_PAER_Addr_i                     : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
      AuxRx_PAER_Req_i                      : in  std_logic;
      AuxRx_PAER_Ack_o                      : out std_logic;
      -- HSSAER channels 
      AuxRx_HSSAER_i                        : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      -- GTP lines
      AuxRx_RxGtpMsg_o                      : out std_logic_vector(7 downto 0);
      AuxRx_RxGtpMsgSrcRdy_o                : out std_logic;
      AuxRx_RxGtpMsgDstRdy_i                : in  std_logic;  
      AuxRx_RxGtpAlignRequest_o             : out std_logic;
      AuxRx_GTP_RxUsrClk2_i                 : in  std_logic;
      AuxRx_GTP_SoftResetRx_o               : out  std_logic;                                          
      AuxRx_GTP_DataValid_o                 : out std_logic;          
      AuxRx_GTP_Rxuserrdy_o                 : out std_logic;              
      AuxRx_GTP_Rxdata_i                    : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);           
      AuxRx_GTP_Rxchariscomma_i             : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      AuxRx_GTP_Rxcharisk_i                 : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      AuxRx_GTP_Rxdisperr_i                 : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        
      AuxRx_GTP_Rxnotintable_i              : in  std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);            
      AuxRx_GTP_Rxbyteisaligned_i           : in  std_logic;                                           
      AuxRx_GTP_Rxbyterealign_i             : in  std_logic;         
      AuxRx_GTP_PllLock_i                   : in  std_logic;                                           
      AuxRx_GTP_PllRefclklost_i             : in  std_logic;
      -- GTH lines 
      AuxRx_GTH_gtwiz_userclk_rx_usrclk2_i  : in std_logic_vector(0 downto 0);                
      AuxRx_GTH_gtwiz_reset_all_o           : out std_logic_vector(0 downto 0);               
      AuxRx_GTH_gtwiz_userdata_rx_i         : in  std_logic_vector(C_GTP_DSIZE-1 downto 0);   
      AuxRx_GTH_Rxctrl2_i                   : in  std_logic_vector(7 downto 0);
      AuxRx_GTH_Rxctrl0_i                   : in  std_logic_vector(15 downto 0);
      AuxRx_GTH_Rxctrl1_i                   : in  std_logic_vector(15 downto 0);
      AuxRx_GTH_Rxctrl3_i                   : in  std_logic_vector(7 downto 0);
      AuxRx_GTH_Rxbyteisaligned_i           : in  std_logic_vector(0 downto 0);               
      AuxRx_GTH_Rxbyterealign_i             : in  std_logic_vector(0 downto 0);               
      AuxRx_GTH_Qpll_lock_i                 : in  std_logic_vector(0 downto 0);               
      AuxRx_GTH_Qpll_refclklost_i           : in  std_logic_vector(0 downto 0); 
      -- SpiNNaker Interface 
      AuxRx_SPNN_Data_i                     : in  std_logic_vector(6 downto 0); 
      AuxRx_SPNN_Ack_o                      : out std_logic;              
      
      --
      -- FIFOs interfaces
      ---------------------
      FifoRxDat_o                           : out std_logic_vector(63 downto 0);
      FifoRxRead_i                          : in  std_logic;
      FifoRxEmpty_o                         : out std_logic;
      FifoRxAlmostEmpty_o                   : out std_logic;
      FifoRxLastData_o                      : out std_logic;
      FifoRxFull_o                          : out std_logic;
      FifoRxNumData_o                       : out std_logic_vector(10 downto 0);
      FifoRxResetBusy_o                     : out std_logic;
      --
      FifoTxDat_i                           : in  std_logic_vector(31 downto 0);
      FifoTxWrite_i                         : in  std_logic;
      FifoTxLastData_i                      : in  std_logic; 
      FifoTxFull_o                          : out std_logic;
      FifoTxAlmostFull_o                    : out std_logic;
      FifoTxEmpty_o                         : out std_logic;
      FifoTxResetBusy_o                     : out std_logic;
      
      -----------------------------------------------------------------------
      -- uController Interface
      ---------------------
      -- Control
      CleanTimer_i                          : in  std_logic;
      FlushRXFifos_i                        : in  std_logic;
      FlushTXFifos_i                        : in  std_logic;        
      --TxEnable_i                          : in  std_logic;
      --TxPaerFlushFifos_i                  : in  std_logic;
      --LRxEnable_i                         : in  std_logic;
      --RRxEnable_i                         : in  std_logic;
      LRxPaerFlushFifos_i                   : in  std_logic;
      RRxPaerFlushFifos_i                   : in  std_logic;
      AuxRxPaerFlushFifos_i                 : in  std_logic;
      FullTimestamp_i                       : in  std_logic;
      
      -- Configurations
      DmaLength_i                           : in  std_logic_vector(15 downto 0);
      OnlyEventsRx_i                        : in  std_logic;
      OnlyEventsTx_i                        : in  std_logic;
      RemoteLoopback_i                      : in  std_logic;
      LocNearLoopback_i                     : in  std_logic;
      LocFarLPaerLoopback_i                 : in  std_logic;
      LocFarRPaerLoopback_i                 : in  std_logic;
      LocFarAuxPaerLoopback_i               : in  std_logic;
      LocFarLSaerLoopback_i                 : in  std_logic;
      LocFarRSaerLoopback_i                 : in  std_logic;
      LocFarAuxSaerLoopback_i               : in  std_logic;
      LocFarSaerLpbkCfg_i                   : in  t_XConCfg;
      LocFarSpnnLnkLoopbackSel_i            : in  std_logic_vector(1 downto 0);
      
      TxPaerEn_i                            : in  std_logic;
      TxHSSaerEn_i                          : in  std_logic;
      TxGtpEn_i                             : in  std_logic;
      TxSpnnLnkEn_i                         : in  std_logic;
      TxDestSwitch_i                        : in  std_logic_vector(2 downto 0);
      --TxPaerIgnoreFifoFull_i              : in  std_logic;
      TxPaerReqActLevel_i                   : in  std_logic;
      TxPaerAckActLevel_i                   : in  std_logic;
      TxSaerChanEn_i                        : in  std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
      --TxSaerChanCfg_i                     : in  t_hssaerCfg_array(C_TX_HSSAER_N_CHAN-1 downto 0);
      
      -- TX Timestamp
      TxTSMode_i                            : in  std_logic_vector(1 downto 0);
      TxTSTimeoutSel_i                      : in  std_logic_vector(3 downto 0);
      TxTSRetrigCmd_i                       : in  std_logic;
      TxTSRearmCmd_i                        : in  std_logic;
      TxTSRetrigStatus_o                    : out std_logic;
      TxTSTimeoutCounts_o                   : out std_logic;
      TxTSMaskSel_i                         : in  std_logic_vector(1 downto 0);
      
      --
      LRxPaerEn_i                           : in  std_logic;
      RRxPaerEn_i                           : in  std_logic;
      AuxRxPaerEn_i                         : in  std_logic;
      LRxHSSaerEn_i                         : in  std_logic;
      RRxHSSaerEn_i                         : in  std_logic;
      AuxRxHSSaerEn_i                       : in  std_logic;
      LRxGtpEn_i                            : in  std_logic;
      RRxGtpEn_i                            : in  std_logic;
      AuxRxGtpEn_i                          : in  std_logic;
      LRxSpnnLnkEn_i                        : in  std_logic;
      RRxSpnnLnkEn_i                        : in  std_logic;
      AuxRxSpnnLnkEn_i                      : in  std_logic;
      LRxSaerChanEn_i                       : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      RRxSaerChanEn_i                       : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      AuxRxSaerChanEn_i                     : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
      RxPaerReqActLevel_i                   : in  std_logic;
      RxPaerAckActLevel_i                   : in  std_logic;
      RxPaerIgnoreFifoFull_i                : in  std_logic;
      RxPaerAckSetDelay_i                   : in  std_logic_vector(7 downto 0);
      RxPaerSampleDelay_i                   : in  std_logic_vector(7 downto 0);
      RxPaerAckRelDelay_i                   : in  std_logic_vector(7 downto 0);
      
      -- Status
      WrapDetected_o                        : out std_logic;
      TxGtpStat_o                           : out t_TxGtpStat;
      
      --TxPaerFifoEmpty_o                   : out std_logic;
      TxSaerStat_o                          : out t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);
      
      LRxPaerFifoFull_o                     : out std_logic;
      RRxPaerFifoFull_o                     : out std_logic;
      AuxRxPaerFifoFull_o                   : out std_logic;
      LRxSaerStat_o                         : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
      RRxSaerStat_o                         : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
      AUXRxSaerStat_o                       : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
      LRxGtpStat_o                          : out t_RxGtpStat;
      RRxGtpStat_o                          : out t_RxGtpStat;
      AUXRxGtpStat_o                        : out t_RxGtpStat;
      TxSpnnlnkStat_o                       : out t_TxSpnnlnkStat;
      LRxSpnnlnkStat_o                      : out t_RxSpnnlnkStat;
      RRxSpnnlnkStat_o                      : out t_RxSpnnlnkStat;
      AuxRxSpnnlnkStat_o                    : out t_RxSpnnlnkStat;
      
      SpnnStartKey_i                        : in  std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command key
      SpnnStopKey_i                         : in  std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command key
      SpnnTxMask_i                          : in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
      SpnnRxMask_i                          : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
      SpnnCtrl_i                            : in  std_logic_vector(31 downto 0);  -- SpiNNaker Control register 
      SpnnStatus_o                          : out std_logic_vector(31 downto 0);  -- SpiNNaker Status Register  
      
      --
      -- INTERCEPTION
      ---------------------
      RRxData_o                             : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      RRxSrcRdy_o                           : out std_logic;
      RRxDstRdy_i                           : in  std_logic;
      RRxBypassData_i                       : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      RRxBypassSrcRdy_i                     : in  std_logic;
      RRxBypassDstRdy_o                     : out std_logic;
      --
      LRxData_o                             : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      LRxSrcRdy_o                           : out std_logic;
      LRxDstRdy_i                           : in  std_logic;
      LRxBypassData_i                       : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      LRxBypassSrcRdy_i                     : in  std_logic;
      LRxBypassDstRdy_o                     : out std_logic;
      --
      AuxRxData_o                           : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      AuxRxSrcRdy_o                         : out std_logic;
      AuxRxDstRdy_i                         : in  std_logic;
      AuxRxBypassData_i                     : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      AuxRxBypassSrcRdy_i                   : in  std_logic;
      AuxRxBypassDstRdy_o                   : out std_logic;        
      
      --
      -- LED drivers
      ---------------------
      LEDo_o                                : out std_logic;
      LEDr_o                                : out std_logic;
      LEDy_o                                : out std_logic
    );
  end component neuserial_core;

  
end package components;



