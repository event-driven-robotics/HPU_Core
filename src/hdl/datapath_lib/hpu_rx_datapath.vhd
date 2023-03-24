-- ------------------------------------------------------------------------------
-- 
--  Revision 1.2:  01/04/2021
--  - Added GTP capabilities
--    (M. Casti - IIT)
--    
-- ------------------------------------------------------------------------------
-- 
--  Revision 1.1:  25/07/2018
--  - Added SpiNNlink capabilities
--    (M. Casti - IIT)
--    
-- ------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

library HPU_lib;
  use HPU_lib.aer_pkg.all;

library datapath_lib;
  use datapath_lib.DPComponents_pkg.all;

-- library HPU_lib;
--   use HPU_lib.aer_pkg.C_INTERNAL_DSIZE;
    	
library spinn_neu_if_lib;
  use spinn_neu_if_lib.spinn_neu_pkg.all;
    
library GT_lib;
  use GT_lib.GT_pkg.all;

entity hpu_rx_datapath is
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
end entity hpu_rx_datapath;


architecture str of hpu_rx_datapath is


signal	Rst	     : std_logic;

signal i_InPaerSrc : t_PaerSrc_array(0 to 3);
signal i_InPaerDst : t_PaerDst_array(0 to 3);
signal i_RxSaerStat: t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
signal DBG_FIFO0 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
signal DBG_FIFO1 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
signal DBG_FIFO2 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
signal DBG_FIFO3 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
signal DBG_FIFO4 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);


-- -----------------------------------------------------------------------------
-- DEBUG
attribute mark_debug : string;

begin

Rst <= not nRst;

-------------------------------------------------------------
-- PAER Receiver
-------------------------------------------------------------

g_paer_true : if C_HAS_PAER = true generate

signal ii_paer_nrst : std_logic;

begin

  ii_paer_nrst <= nRst and EnablePAER_i;

  u_simplePAERInput : SimplePAERInputRRv2
    generic map (
      paer_width           => C_PAER_DSIZE,           -- positive := 16;
      internal_width       => C_INTERNAL_DSIZE,       -- positive := 32;
      --data_on_req_release  => c_DVS_SCX,              -- boolean  := false;
      input_fifo_depth     => 4                       -- positive := 1
      )
    port map (
      -- clk rst
      ClkxCI               => Clk_i,               -- in  std_logic;
      RstxRBI              => ii_paer_nrst,           -- in  std_logic;
      EnableIp             => EnablePAER_i,           -- in  std_logic;
      FlushFifo            => PaerFlushFifos_i,       -- in  std_logic;
      IgnoreFifoFull_i     => PaerIgnoreFifoFull_i,   -- in  std_logic;
      aux_channel          => Aux_Channel_i,          -- in  std_logic;
      
      -- parallel AER
      AerReqxAI            => PAER_Req_i,             -- in  std_logic;
      AerAckxSO            => PAER_Ack_o,             -- out std_logic;
      AerDataxADI          => PAER_Addr_i,            -- in  std_logic_vector(paer_width-1 downto 0);
      
      -- configuration
      AerHighBitsxDI       => RxPaerHighBits_i,       -- in  std_logic_vector(internal_width-1-paer_width downto 0);
      CfgAckSetDelay_i     => PaerAckSetDelay_i,      -- in  std_logic_vector(7 downto 0);
      CfgSampleDelay_i     => PaerSampleDelay_i,      -- in  std_logic_vector(7 downto 0);
      CfgAckRelDelay_i     => PaerAckRelDelay_i,      -- in  std_logic_vector(7 downto 0);
      
      -- output
      OutDataxDO           => i_InPaerSrc(0).idx,     -- out std_logic_vector(internal_width-1 downto 0);
      OutSrcRdyxSO         => i_InPaerSrc(0).vld,     -- out std_logic;
      OutDstRdyxSI         => i_InPaerDst(0).rdy,     -- in  std_logic;
      -- Fifo Full signal
      FifoFullxSO          => PaerFifoFull_o,         -- out std_logic;
      -- dbg
      dbg_dataOk           => dbg_PaerDataOk          -- out std_logic 
      );
end generate g_paer_true;

g_paer_false : if C_HAS_PAER = false generate
  -- Output signals passivation
  
  PAER_Ack_o <= PaerAckActLevel_i;
  
  i_InPaerSrc(0).idx <= (others => '0');
  i_InPaerSrc(0).vld <= '0';
  
  PaerFifoFull_o <= '0';
  dbg_PaerDataOk <= '0';

end generate g_paer_false;


-------------------------------------------------------------
-- HSSAER Receiver
-------------------------------------------------------------

g_hssaer_true : if C_HAS_HSSAER = true generate

signal ii_hssaer_nrst : std_logic;
signal ii_rx_fromSaerSrc : t_PaerSrc_array(0 to C_HSSAER_N_CHAN-1);
signal ii_rx_fromSaerSrc_synched : t_PaerSrc_array(0 to C_HSSAER_N_CHAN-1);
signal ii_rx_fromSaerDst : t_PaerDst_array(0 to C_HSSAER_N_CHAN-1);
signal ii_rx_fromSaerDst_synched : t_PaerDst_array(0 to C_HSSAER_N_CHAN-1);
signal i_HSSAER_Rx : std_logic_vector(0 to C_HSSAER_N_CHAN-1);
signal synch_fifo_wr_en : std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal synch_fifo_rd_en : std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal synch_fifo_full : std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal synch_fifo_empty : std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal i_reset_synch_fifos : std_logic;

type RxSaerHighBits_t is array (0 to 3) of std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
signal RxSaerHighBits : RxSaerHighBits_t;

begin
    
  RxSaerHighBits(0) <= RxSaerHighBits0_i;
  RxSaerHighBits(1) <= RxSaerHighBits1_i;
  RxSaerHighBits(2) <= RxSaerHighBits2_i;
  RxSaerHighBits(3) <= RxSaerHighBits3_i;
  
  ii_hssaer_nrst <= nRst and EnableHSSAER_i;
  i_reset_synch_fifos <= not(ii_hssaer_nrst);
  
  g_hssaer_rx : for i in 0 to C_HSSAER_N_CHAN-1 generate
      --for all : hssaer_paer_rx use entity hssaer_lib.hssaer_paer_rx(module);
  begin
  
    u_paer2hssaer_rx : hssaer_paer_rx_wrapper
      generic map (
        dsize       => C_PAER_DSIZE,             -- positive;
        int_dsize   => C_INTERNAL_DSIZE          -- positive := 32
      )
      port map (
        nrst        => ii_hssaer_nrst,           -- in  std_logic;
        lsclkp      => Clk_ls_p,                 -- in  std_logic;
        lsclkn      => Clk_ls_n,                 -- in  std_logic;
        hsclkp      => Clk_hs_p,                 -- in  std_logic;
        hsclkn      => Clk_hs_n,                 -- in  std_logic;
    
        rx          => i_HSSAER_Rx(i),           -- in  std_logic;
    
        higher_bits => RxSaerHighBits(i),         -- in  std_logic_vector(int_dsize-1 downto dsize);
    
        ae          => ii_rx_fromSaerSrc(i).idx, -- out std_logic_vector(int_dsize-1 downto 0);
        src_rdy     => ii_rx_fromSaerSrc(i).vld, -- out std_logic;
        dst_rdy     => ii_rx_fromSaerDst_synched(i).rdy, -- in  std_logic;
    
        err_ko      => i_RxSaerStat(i).err_ko,   -- out std_logic;
        err_rx      => i_RxSaerStat(i).err_rx,   -- out std_logic;
        err_to      => i_RxSaerStat(i).err_to,   -- out std_logic;
        err_of      => i_RxSaerStat(i).err_of,   -- out std_logic;
        int         => i_RxSaerStat(i).int,      -- out std_logic;
        run         => i_RxSaerStat(i).run,       -- out std_logic;
    
        aux_channel => Aux_Channel_i             -- in  std_logic;
        );
    
FIFO_SAER_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
    FIFO_SAER_m : FIFO_SAER_ZYNQ
      port map (
        rst     => i_reset_synch_fifos,
        wr_clk  => Clk_ls_p,
        rd_clk  => Clk_i,
        din     => ii_rx_fromSaerSrc(i).idx,
        wr_en   => synch_fifo_wr_en(i),
        rd_en   => synch_fifo_rd_en(i),
        dout    => ii_rx_fromSaerSrc_synched(i).idx,
        full    => synch_fifo_full(i),
        empty   => synch_fifo_empty(i)
        );

end generate;    

FIFO_SAER_FOR_ZYNQUPLUS_gen : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin
   
    FIFO_SAER_m : FIFO_SAER_ZYNQUPLUS
      port map (
        rst     => i_reset_synch_fifos,
        wr_clk  => Clk_ls_p,
        rd_clk  => Clk_i,
        din     => ii_rx_fromSaerSrc(i).idx,
        wr_en   => synch_fifo_wr_en(i),
        rd_en   => synch_fifo_rd_en(i),
        dout    => ii_rx_fromSaerSrc_synched(i).idx,
        full    => synch_fifo_full(i),
        empty   => synch_fifo_empty(i)
        );

end generate;

      
    synch_fifo_wr_en(i) <= ii_rx_fromSaerSrc(i).vld and not(synch_fifo_full(i));
    synch_fifo_rd_en(i) <= ii_rx_fromSaerDst(i).rdy and not(synch_fifo_empty(i));
    ii_rx_fromSaerSrc_synched(i).vld <= not(synch_fifo_empty(i));
    ii_rx_fromSaerDst_synched(i).rdy <= not(synch_fifo_full(i));
  
    p_debug_check : process (Clk_ls_p)
    begin
    if (rising_edge(Clk_ls_p)) then
      if (ii_hssaer_nrst = '0') then
        DBG_FIFO0 <= (others => '0');
        DBG_FIFO1 <= (others => '0');
        DBG_FIFO2 <= (others => '0');
        DBG_FIFO3 <= (others => '0');
        DBG_FIFO4 <= (others => '0');
      else
        if (ii_rx_fromSaerSrc(1).vld='1' and ii_rx_fromSaerDst(1).rdy='1')  then
          DBG_FIFO0 <= ii_rx_fromSaerSrc(1).idx;
          DBG_FIFO1 <= DBG_FIFO0;
          DBG_FIFO2 <= DBG_FIFO1;
          DBG_FIFO3 <= DBG_FIFO2;
          DBG_FIFO4 <= DBG_FIFO3;
        end if;
      end if;
    end if;
    end process p_debug_check;
  
    i_HSSAER_Rx(i) <= HSSAER_Rx_i(i) and HSSaerChanEn_i(i);
    
    DBG_src_rdy(i) <= ii_rx_fromSaerSrc(i).vld;
    DBG_dst_rdy(i) <= ii_rx_fromSaerDst(i).rdy;
    DBG_err(i)     <= i_RxSaerStat(i).err_ko or i_RxSaerStat(i).err_rx or i_RxSaerStat(i).err_to or i_RxSaerStat(i).err_of;
    DBG_run(i)     <= i_RxSaerStat(i).run;
    DBG_RX(i)      <= i_HSSAER_Rx(i);
    
    RxSaerStat_o(i) <= i_RxSaerStat(i);
  
  end generate g_hssaer_rx;

  u_hssaer_arbiter : neuserial_PAER_arbiter
    generic map (
      C_NUM_CHAN         => C_HSSAER_N_CHAN,    -- natural range 1 to 4
      C_ODATA_WIDTH      => C_INTERNAL_DSIZE    -- natural
      )
    port map (
      Clk                => Clk_i,           -- in  std_logic;
      nRst               => ii_hssaer_nrst,     -- in  std_logic;
      
      --ArbCfg_i           =>                     -- in  t_ArbiterCfg;
      
      SplittedPaerSrc_i  => ii_rx_fromSaerSrc_synched,  -- in  t_PaerSrc_array(0 to C_NUM_CHAN-1);
      SplittedPaerDst_o  => ii_rx_fromSaerDst,  -- out t_PaerDst_array(0 to C_NUM_CHAN-1);
      
      PaerData_o         => i_InPaerSrc(1).idx, -- out std_logic_vector(C_ODATA_WIDTH-1 downto 0);
      PaerSrcRdy_o       => i_InPaerSrc(1).vld, -- out std_logic;
      PaerDstRdy_i       => i_InPaerDst(1).rdy  -- in  std_logic
      );

end generate g_hssaer_true;


g_hssaer_false : if C_HAS_HSSAER = false generate
    -- Output signals passivation

  DBG_FIFO0 <= (others => '0');
  DBG_FIFO1 <= (others => '0');
  DBG_FIFO2 <= (others => '0');
  DBG_FIFO3 <= (others => '0');
  DBG_FIFO4 <= (others => '0');
  
  i_InPaerSrc(1).idx <= (others => '0');
  i_InPaerSrc(1).vld <= '0';
  
  g_hssaer_rx : for i in 0 to C_HSSAER_N_CHAN-1 generate
    RxSaerStat_o(i).err_ko <= '0';
    RxSaerStat_o(i).err_rx <= '0';
    RxSaerStat_o(i).err_to <= '0';
    RxSaerStat_o(i).err_of <= '0';
    RxSaerStat_o(i).int    <= '0';
    RxSaerStat_o(i).run    <= '0';
  end generate g_hssaer_rx;

end generate g_hssaer_false;

DBG_FIFO_0 <= DBG_FIFO0;
DBG_FIFO_1 <= DBG_FIFO1;
DBG_FIFO_2 <= DBG_FIFO2;
DBG_FIFO_3 <= DBG_FIFO3;
DBG_FIFO_4 <= DBG_FIFO4;


-------------------------------------------------------------
-- GTP Receiver
-------------------------------------------------------------

g_gtp_true : if C_HAS_GTP = true generate

-- Signals
signal ii_gtp_nrst            : std_logic;

signal i_RxGtpPllAlarm        : std_logic; 
signal i_RxGtpAlignRequest    : std_logic;
signal i_RxGtpDisaligned      : std_logic;

signal i_RxGtpDataRate        : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_RxGtpAlignRate       : std_logic_vector( 7 downto 0); -- Count per millisecond 
signal i_RxGtpMsgRate         : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_RxGtpIdleRate        : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_RxGtpEventRate       : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_RxGtpMessageRate     : std_logic_vector( 7 downto 0); -- Count per millisecond     

signal i_RxGtpData            : std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
signal i_RxGtpDataSrcRdy      : std_logic;
signal i_RxGtpMsg             : std_logic_vector(7 downto 0);
signal i_RxGtpMsgSrcRdy       : std_logic;

signal i_GtpSoftResetRx       : std_logic;
signal i_GtpDataValid         : std_logic;
signal i_GtpRxuserrdy         : std_logic;

signal i_gth_gtwiz_reset_all  : std_logic_vector(0 downto 0);  

begin

  ii_gtp_nrst <= nRst and EnableGTP_i;

  GT_MANAGER_RX_i : GT_Manager 
    generic map( 
      FAMILY_g                  =>  C_FAMILY,
      --
      USER_DATA_WIDTH_g         =>  C_OUTPUT_DSIZE,               -- Width of Data - Fabric side
      USER_MESSAGE_WIDTH_g      =>  8,                            -- Width of Message - Fabric side 
      GT_DATA_WIDTH_g           =>  C_GTP_DSIZE,                  -- Width of Data - GTP side
      GT_TXUSRCLK2_PERIOD_NS_g  =>  C_GTP_TXUSRCLK2_PERIOD_NS,    -- TX GTP User clock period
      GT_RXUSRCLK2_PERIOD_NS_g  =>  C_GTP_RXUSRCLK2_PERIOD_NS,    -- RX GTP User clock period
      SIM_TIME_COMPRESSION_g    =>  C_SIM_TIME_COMPRESSION    -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
      )
    port map(
      
      -- COMMONs
      -- Bare Control ports
      CLK_i                   => Clk_i,       -- Input clock - Fabric side
      RST_N_i                 => ii_gtp_nrst, -- Asynchronous active low reset (clk clock)
      EN1S_i                  => En1Sec_i,    -- Enable @ 1 sec in clk domain 
  
      -- Status
      PLL_ALARM_o             => i_RxGtpPllAlarm,
      
      -- ---------------------------------------------------------------------------------------
      -- TX SIDE
  
      -- Control in
      TX_AUTO_ALIGN_i         => '0',   -- Enables the "Auto alignment mode"
      TX_ALIGN_REQUEST_i      => '0',   -- Align request from Receiver
      TX_ERROR_INJECTION_i    => '0',   -- Error insertin (debug purpose)
      
      -- Status
      TX_GT_ALIGN_FLAG_o      => open,   -- Monitor out: sending align
      
      -- Statistics
      TX_DATA_RATE_o          => open,
      TX_ALIGN_RATE_o         => open,
      TX_MSG_RATE_o           => open,
      TX_IDLE_RATE_o          => open,
      TX_EVENT_RATE_o         => open,
      TX_MESSAGE_RATE_o       => open,
  
    
      -- Data TX 
      TX_DATA_i               => (others => '0'),
      TX_DATA_SRC_RDY_i       => '0',
      TX_DATA_DST_RDY_o       => open,
      -- Message TX                 
      TX_MSG_i                => (others => '0'),
      TX_MSG_SRC_RDY_i        => '0',
      TX_MSG_DST_RDY_o        => open,
  
      -- ---------------------------------------------------------------------------------------
      -- RX SIDE    
      
      -- Control out
      RX_ALIGN_REQUEST_o      => i_RxGtpAlignRequest,  
      
      -- Status and errors
      RX_DISALIGNED_o         => i_RxGtpDisaligned,
      
      -- Statistics        
      RX_DATA_RATE_o          => i_RxGtpDataRate,
      RX_ALIGN_RATE_o         => i_RxGtpAlignRate, 
      RX_MSG_RATE_o           => i_RxGtpMsgRate, 
      RX_IDLE_RATE_o          => i_RxGtpIdleRate,
      RX_EVENT_RATE_o         => i_RxGtpEventRate,
      RX_MESSAGE_RATE_o       => i_RxGtpMessageRate,
  
      -- Data RX 
      RX_DATA_o               => i_InPaerSrc(2).idx,
      RX_DATA_SRC_RDY_o       => i_InPaerSrc(2).vld,
      RX_DATA_DST_RDY_i       => i_InPaerDst(2).rdy,
      -- Message RX
      RX_MSG_o                => i_RxGtpMsg,
      RX_MSG_SRC_RDY_o        => i_RxGtpMsgSrcRdy, 
      RX_MSG_DST_RDY_i        => RxGtpMsgDstRdy_i, 
      
          
     
      -- *****************************************************************************************
      -- Transceiver Interface for Serie 7 GTP
      -- *****************************************************************************************
                                                                                    -- Clock Domain --
      -- Clock Ports
      GTP_TXUSRCLK2_i          => '0',
      GTP_RXUSRCLK2_i          => GTP_RxUsrClk2_i,  
      
      -- Reset FSM Control Ports
      SOFT_RESET_TX_o          => open,                                             -- SYS_CLK      --
      SOFT_RESET_RX_o          => i_GtpSoftResetRx,                                    -- SYS_CLK      --
      GTP_DATA_VALID_o         => i_GtpDataValid,
          
      -- -------------------------------------------------------------------------
      -- TRANSMITTER 
      --------------------- TX Initialization and Reset Ports --------------------
      GTP_TXUSERRDY_o          => open,                                             -- ASYNC        --
      ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
      GTP_TXDATA_o             => open,                                             -- TXUSRCLK2    --
      ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
      GTP_TXCHARISK_o          => open,                                             -- TXUSRCLK2    --
      
      -- -------------------------------------------------------------------------
      -- RECEIVER
      --------------------- RX Initialization and Reset Ports --------------------
      GTP_RXUSERRDY_o          => i_GtpRxuserrdy,                                   -- ASYNC        --
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTP_RXDATA_i             => GTP_Rxdata_i,                                      -- RXUSRCLK2    --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTP_RXCHARISCOMMA_i      => GTP_Rxchariscomma_i,                               -- RXUSRCLK2    --
      GTP_RXCHARISK_i          => GTP_Rxcharisk_i,                                   -- RXUSRCLK2    --
      GTP_RXDISPERR_i          => GTP_Rxdisperr_i,                                   -- RXUSRCLK2    --
      GTP_RXNOTINTABLE_i       => GTP_Rxnotintable_i,                                -- RXUSRCLK2    --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTP_RXBYTEISALIGNED_i    => GTP_Rxbyteisaligned_i,                            -- RXUSRCLK2    --
      GTP_RXBYTEREALIGN_i      => GTP_Rxbyterealign_i,                              -- RXUSRCLK2    --
      
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS
      GTP_PLL_LOCK_i           => GTP_PllLock_i,                                    -- ASYNC        --
      GTP_PLL_REFCLKLOST_i     => GTP_PllRefclklost_i,                              -- SYS_CLK      -- 
 
 
 
      -- *****************************************************************************************
      -- Transceiver Interface for Ultrascale+ GTH
      -- ***************************************************************************************** 
       
      -- Clock Ports
      --  GTH_GTWIZ_USERCLK_TX_USRCLK2_i        : in std_logic_vector(0 downto 0);
      GTH_GTWIZ_USERCLK_RX_USRCLK2_i        => GTH_gtwiz_userclk_rx_usrclk2_i,
      
      -- Reset FSM Control Ports
      GTH_GTWIZ_RESET_ALL_o                 => i_gth_gtwiz_reset_all,               -- ASYNC     --


      -- -------------------------------------------------------------------------
      -- TRANSMITTER 

      -- TBD

      
      -- -------------------------------------------------------------------------
      -- RECEIVER
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTH_GTWIZ_USERDATA_RX_i               => GTH_gtwiz_userdata_rx_i,            -- RXUSRCLK2 --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTH_RXCTRL2_i                         => GTH_Rxctrl2_i,  -- (RXCHARISCOMMA)  -- RXUSRCLK2 --
      GTH_RXCTRL0_i                         => GTH_Rxctrl0_i,  -- (RXCHARISK)      -- RXUSRCLK2 --
      GTH_RXCTRL1_i                         => GTH_Rxctrl1_i,  -- (RXDISPERR)      -- RXUSRCLK2 --
      GTH_RXCTRL3_i                         => GTH_Rxctrl3_i,  -- (RXNOTINTABLE)   -- RXUSRCLK2 --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTH_RXBYTEISALIGNED_i                 => GTH_Rxbyteisaligned_i,              -- RXUSRCLK2 --
      GTH_RXBYTEREALIGN_i                   => GTH_Rxbyterealign_i,                -- RXUSRCLK2 --
          
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS    
      GTH_QPLL_LOCK_i                       => GTH_Qpll_lock_i,                    -- ASYNC     --
      GTH_QPLL_REFCLKLOST_i                 => GTH_Qpll_refclklost_i               -- QPLL0LOCKDETCLK --
             
    );  
  
  
  RxGtpAlignRequest_o       <= i_RxGtpAlignRequest;   
  RxGtpStat_o.pll_alarm     <= i_RxGtpPllAlarm;
  RxGtpStat_o.rx_disaligned <= i_RxGtpDisaligned;
  
  RxGtpDataRate_o           <= i_RxGtpDataRate; 
  RxGtpAlignRate_o          <= i_RxGtpAlignRate; 
  RxGtpMsgRate_o            <= i_RxGtpMsgRate; 
  RxGtpIdleRate_o           <= i_RxGtpIdleRate; 
  RxGtpEventRate_o          <= i_RxGtpEventRate; 
  RxGtpMessageRate_o        <= i_RxGtpMessageRate;   
  
  RxGtpMsg_o                <= i_RxGtpMsg;
  RxGtpMsgSrcRdy_o          <= i_RxGtpMsgSrcRdy;
     
  GTP_SoftResetRx_o         <= i_GtpSoftResetRx;  
  GTP_DataValid_o           <= i_GtpDataValid;
  GTP_Rxuserrdy_o           <= i_GtpRxuserrdy;
  
  GTH_gtwiz_reset_all_o     <= i_gth_gtwiz_reset_all;
  
end generate g_gtp_true;
  
  
g_gtp_false : if C_HAS_GTP = false generate

  -- Output signals passivation
  
  i_InPaerSrc(2).idx        <= (others => '0');
  i_InPaerSrc(2).vld        <= '0';
  
  RxGtpAlignRequest_o       <= '0';  
  RxGtpStat_o.pll_alarm     <= '0';
  RxGtpStat_o.rx_disaligned <= '0';
  
  RxGtpDataRate_o           <= (others => '0'); 
  RxGtpAlignRate_o          <= (others => '0'); 
  RxGtpMsgRate_o            <= (others => '0'); 
  RxGtpIdleRate_o           <= (others => '0'); 
  RxGtpEventRate_o          <= (others => '0'); 
  RxGtpMessageRate_o        <= (others => '0');     

  RxGtpMsg_o                <= (others => '0');
  RxGtpMsgSrcRdy_o          <= '0';
  
  GTP_SoftResetRx_o         <= '0';  
  GTP_DataValid_o           <= '0';
  GTP_Rxuserrdy_o           <= '0';
  
  GTH_gtwiz_reset_all_o     <= "0";
  
end generate g_gtp_false;
    
    
----------------------------------
-- SpiNNlink receiver
----------------------------------

g_spinnlnk_true : if C_HAS_SPNNLNK = true generate

signal i_SpnnParityErr : std_logic;
signal i_SpnnRxErr     : std_logic;
    
begin
       
  SpnnParityErr_o <= i_SpnnParityErr;
  SpnnRxErr_o     <= i_SpnnRxErr;
  
  RxSpnnlnkStat_o.parity_err <= i_SpnnParityErr;
  RxSpnnlnkStat_o.rx_err <= i_SpnnRxErr;
  
  u_spinnlink_rx : spinn_neu_if
    generic map (
      C_PSPNNLNK_WIDTH           => C_PSPNNLNK_WIDTH,
      C_HAS_TX                   => "false",
      C_HAS_RX                   => "true"
      )
    port map (
      rst                        => Rst,
      clk_32                     => Clk_i, -- 100 MHz Clock
      enable                     => EnableSPNNLNK_i,
      
      dump_mode                  => open,    
      parity_err                 => i_SpnnParityErr,
      rx_err                     => i_SpnnRxErr,
      offload                    => open,
      link_timeout               => open,
      link_timeout_dis           => '1',
  
      -- input SpiNNaker link interface
      data_2of7_from_spinnaker   => SPNN_Data_i, 
      ack_to_spinnaker           => SPNN_Ack_o,
  
      -- output SpiNNaker link interface
      data_2of7_to_spinnaker     => open,
      ack_from_spinnaker         => '0',
  
      -- input AER device interface
      iaer_addr                  => (others => '0'),
      iaer_vld                   => '0',
      iaer_rdy                   => open,
  
      -- output AER device interface
      oaer_addr                  => i_InPaerSrc(3).idx,           -- out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
      oaer_vld                   => i_InPaerSrc(3).vld,           -- out std_logic;                                  
      oaer_rdy                   => i_InPaerDst(3).rdy,           -- in  std_logic;                                  
  
      -- Command from SpiNNaker
      keys_enable                => SpnnKeysEnable_i,           -- in  std_logic;
      start_key                  => SpnnStartKey_i,             -- in  std_logic_vector(31 downto 0);
      stop_key                   => SpnnStopKey_i,              -- in  std_logic_vector(31 downto 0);
      cmd_start                  => SpnnCmdStart_o,             -- out std_logic;
      cmd_stop                   => SpnnCmdStop_o,              -- out std_logic;
  
      -- Settings
      tx_data_mask               => (others => '0'),              -- in  std_logic_vector(31 downto 0);
      rx_data_mask               => SpnnRxMask_i,               -- in  std_logic_vector(31 downto 0);
      
      -- Controls
      offload_off                => '0',                          -- in  std_logic;
      offload_on                 => '0',                          -- in  std_logic;
  
      -- Debug Port                
      dbg_rxstate                => open,
      dbg_txstate                => open,
      dbg_ipkt_vld               => open,
      dbg_ipkt_rdy               => open,
      dbg_opkt_vld               => open,
      dbg_opkt_rdy               => open
      ); 
     
 end generate g_spinnlnk_true;

g_spinnlnk_false : if C_HAS_SPNNLNK = FALSE generate
begin    

   SpnnParityErr_o    <= '0';
   SpnnRxErr_o        <= '0';
   
   SPNN_Ack_o         <= '0';
   
   RxSpnnlnkStat_o.parity_err <= '0';
   RxSpnnlnkStat_o.rx_err     <= '0';

   i_InPaerSrc(3).idx <= (others => '0'); 
   i_InPaerSrc(3).vld <= '0'; 
   
   SpnnCmdStart_o     <= '0';
   SpnnCmdStop_o      <= '0';

end generate g_spinnlnk_false;
       
--===========================================================
-- ARBITER amongst all the possible channel
--===========================================================

u_rx_arbiter : neuserial_PAER_arbiter
  generic map (
    C_NUM_CHAN         => 4,                  -- natural range 1 to 4;
    C_ODATA_WIDTH      => C_OUTPUT_DSIZE      -- natural
    )
  port map (
    Clk                => Clk_i,           -- in  std_logic;
    nRst               => nRst,               -- in  std_logic;
    
    --ArbCfg_i           =>                     -- in  t_ArbiterCfg;
    
    SplittedPaerSrc_i  => i_InPaerSrc,        -- in  t_PaerSrc_array(0 to C_NUM_CHAN);
    SplittedPaerDst_o  => i_InPaerDst,        -- out t_PaerDst_array(0 to C_NUM_CHAN);
    
    PaerData_o         => RxData_o,           -- out std_logic_vector(C_ODATA_WIDTH-1 downto 0);
    PaerSrcRdy_o       => RxDataSrcRdy_o,     -- out std_logic;
    PaerDstRdy_i       => RxDataDstRdy_i      -- in  std_logic
    );


end architecture str;
