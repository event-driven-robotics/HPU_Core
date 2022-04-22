-- ------------------------------------------------------------------------------
-- 
--  Revision 1.1:  01/04/2021
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
    
library spinn_neu_if_lib;
  use spinn_neu_if_lib.spinn_neu_pkg.all;
    
library GT_lib;
  use GT_lib.GT_pkg.all;


entity hpu_tx_datapath is
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
end entity hpu_tx_datapath;




architecture str of hpu_tx_datapath is

-- -------------------
-- Constants
constant PAER_TX_SELECTED_c       : std_logic_vector(1 downto 0) := "00";
constant HSSAER_TX_SELECTED_c     : std_logic_vector(1 downto 0) := "01";
constant SPINNAKER_TX_SELECTED_c  : std_logic_vector(1 downto 0) := "10";
constant GTP_TX_SELECTED_c        : std_logic_vector(1 downto 0) := "11";

-- -------------------
-- Signals
signal Rst             : std_logic;



signal i_PaerDstRdy             : std_logic;
signal i_PaerSrcRdy             : std_logic;

signal i_HssaerDstRdy           : std_logic;
signal i_HssaerSrcRdy           : std_logic;

signal i_SpnnlnkDstRdy          : std_logic;
signal i_SpnnlnkSrcRdy          : std_logic;

signal i_TxGtpDataDstRdy        : std_logic;
signal i_TxGtpDataSrcRdy        : std_logic;

signal i_selDest : std_logic_vector(1 downto 0);    
signal i_MergedSrcRdy           : std_logic;
signal i_MergedDstRdy           : std_logic;
signal i_VectSrcRdy             : std_logic_vector(3 downto 0);
signal i_VectDstRdy             : std_logic_vector(3 downto 0);


signal i_iaer_addr              : std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
signal i_iaer_vld               : std_logic;
signal i_iaer_rdy               : std_logic;


    
begin


Rst <= not nRst;

-- ----------------------------------------------------------------------
-- TX path selection

-- Route the Sequencer packet to one of the destination paths according
-- to the Destination Switch (TX_CTRL_REG[6:4]) or MSBits in Data:
--     00 => the packet is sent to the parallel AER interface
--     01 => the packet is sent to the HSSAER interface
--     10 => the packet is sent to the SpiNNlink interface
--     11 => the packet is sent to the GTP  interface

-- NOTE: GTP interface take place of "All interfaces" with HPU_Core 4.0 

i_selDest <= DestinationSwitch_i(1 downto 0) when (DestinationSwitch_i(2) = '1') else  -- Path selection from uP interface
             TxData_i(C_INPUT_DSIZE-1 downto C_INPUT_DSIZE-2);                         -- or from incoming data


i_PaerSrcRdy      <= TxDataSrcRdy_i when (i_selDest = PAER_TX_SELECTED_c) else 
                     -- i_VectSrcRdy(0) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                     '0';
i_HssaerSrcRdy    <= TxDataSrcRdy_i when (i_selDest = HSSAER_TX_SELECTED_c) else
                     -- i_VectSrcRdy(1) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                     '0';
i_SpnnlnkSrcRdy   <= TxDataSrcRdy_i when (i_selDest = SPINNAKER_TX_SELECTED_c) else
                     -- i_VectSrcRdy(2) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                     '0';
i_TxGtpDataSrcRdy <= TxDataSrcRdy_i when (i_selDest = GTP_TX_SELECTED_c) else
                     -- i_VectSrcRdy(3) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                     '0';


with i_selDest select  -- the Tx path 
  TxDataDstRdy_o  <= i_PaerDstRdy      when PAER_TX_SELECTED_c,
                     i_HssaerDstRdy    when HSSAER_TX_SELECTED_c,
                     i_SpnnlnkDstRdy   when SPINNAKER_TX_SELECTED_c,
                     i_TxGtpDataDstRdy when GTP_TX_SELECTED_c,
                     -- i_MergedDstRdy    when (false),
                     '0'               when others; 

-- -----------
-- Merged path
i_MergedSrcRdy   <= TxDataSrcRdy_i when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                    '0';    

-- Composing i_VectDstRdy
i_VectDstRdy(conv_integer(unsigned(PAER_TX_SELECTED_c)))      <= i_PaerDstRdy;      
i_VectDstRdy(conv_integer(unsigned(HSSAER_TX_SELECTED_c)))    <= i_HssaerDstRdy;   
i_VectDstRdy(conv_integer(unsigned(SPINNAKER_TX_SELECTED_c))) <= i_SpnnlnkDstRdy;                         
i_VectDstRdy(conv_integer(unsigned(GTP_TX_SELECTED_c)))       <= i_TxGtpDataDstRdy;   

u_mergeRdy : merge_rdy
  generic map (
    N_CHAN        => 4
    )
  port map (
    nRst          => nRst,
    Clk           => Clk_i,
    
    InVld_i       => i_MergedSrcRdy,
    OutRdy_o      => i_MergedDstRdy,
    
    OutVldVect_o  => i_VectSrcRdy,
    InRdyVect_i   => i_VectDstRdy
    );

--===========================================================
-- DESTINATION PATHS
--===========================================================

-------------------------------------------------------------
-- PAER Transmitter
-------------------------------------------------------------

g_paer_true : if C_HAS_PAER = true generate

signal ii_paer_nrst : std_logic;

begin

  ii_paer_nrst <= nRst and EnablePAER_i;        -- Modified from OR to AND logic - Maurizio Casti, 24/07/2018 
  
  u_simplePAEROutput : SimplePAEROutputRR
  generic map (
    paer_width           => C_PAER_DSIZE,      -- positive := 16;
    internal_width       => C_INPUT_DSIZE,     -- positive := 32;
    --ack_stable_cycles    =>                    -- natural  := 2;
    --req_delay_cycles     =>                    -- natural  := 4;
    output_fifo_depth    => 2                  -- positive := 1
    )
  port map(
    -- clk rst
    ClkxCI               => Clk_i,          -- in std_ulogic;
    RstxRBI              => ii_paer_nrst,      -- in std_ulogic;
    
    -- parallel AER
    AerAckxAI            => PAER_Ack_i,        -- in  std_ulogic;
    AerReqxSO            => PAER_Req_o,        -- out std_ulogic;
    AerDataxDO           => PAER_Addr_o,       -- out std_ulogic_vector(paer_width-1 downto 0);
    
    -- configuration
    AerReqActiveLevelxDI => PaerReqActLevel_i, -- in std_ulogic;
    AerAckActiveLevelxDI => PaerAckActLevel_i, -- in std_ulogic;
    
    -- input
    InpDataxDI           => TxData_i,         -- in  std_ulogic_vector(internal_width-1 downto 0);
    InpSrcRdyxSI         => i_PaerSrcRdy,     -- in  std_ulogic;
    InpDstRdyxSO         => i_PaerDstRdy      -- out std_ulogic
    );

end generate g_paer_true;


g_paer_false : if C_HAS_PAER = false generate
  -- Output signals passivation
  PAER_Req_o  <= not PaerReqActLevel_i;
  PAER_Addr_o <= (others => '0');
  
  i_PaerDstRdy <= '0';

end generate g_paer_false;


-------------------------------------------------------------
-- HSSAER Transmitter
-------------------------------------------------------------

g_hssaer_true : if C_HAS_HSSAER = true generate

signal ii_hssaer_nrst : std_logic;
signal ii_tx_toSaerSrc : t_PaerSrc_array(0 to C_HSSAER_N_CHAN-1);
signal ii_tx_toSaerSrc_synched : t_PaerSrc_array(0 to C_HSSAER_N_CHAN-1);
signal ii_tx_toSaerDst : t_PaerDst_array(0 to C_HSSAER_N_CHAN-1);
signal ii_tx_toSaerDst_synched : t_PaerDst_array(0 to C_HSSAER_N_CHAN-1);
signal keep_alive : std_logic := '1'; -- As suggested by P.M.R.
signal reset_sych_fifo : std_logic;
signal synch_fifo_full :std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal synch_fifo_empty :std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal synch_fifo_wr_en : std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
signal synch_fifo_rd_en : std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);

begin

  ii_hssaer_nrst <= nRst and EnableHSSAER_i;        -- Modified from OR to AND logic - Maurizio Casti, 13/04/2022
  
  
  u_hssaer_tx_splitter : neuserial_PAER_splitter
    generic map (
      C_NUM_CHAN => C_HSSAER_N_CHAN,                   -- natural range 1 to 4 := 1;
      C_IDATA_WIDTH => C_INPUT_DSIZE                   -- positive
    )
    port map (
      Clk                => Clk_i,                     -- in  std_logic;
      nRst               => ii_hssaer_nrst,            -- in  std_logic;
      --
      ChEn_i             => HSSaerChanEn_i,            -- in  std_logic_vector(C_NUM_CHAN-1 downto 0);
      --
      PaerDataIn_i       => TxData_i,                  -- in  std_logic_vector(C_IDATA_WIDTH-1 downto 0);
      PaerSrcRdy_i       => i_HssaerSrcRdy,            -- in  std_logic;
      PaerDstRdy_o       => i_HssaerDstRdy,            -- out std_logic;
      --
      SplittedPaerSrc_o  => ii_tx_toSaerSrc,           -- out t_PaerSrc_array(0 to C_NUM_CHAN-1);
      SplittedPaerDst_i  => ii_tx_toSaerDst_synched    -- in  t_PaerDst_array(0 to C_NUM_CHAN-1)
    );
  
  
  g_hssaer_tx : for i in 0 to C_HSSAER_N_CHAN-1 generate
    --for all : hssaer_paer_tx use entity hssaer_lib.hssaer_paer_tx(module);
  begin

    reset_sych_fifo <= not(ii_hssaer_nrst);
    ii_tx_toSaerDst_synched(i).rdy <= not(synch_fifo_full(i));

FIFO_SAER_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
    FIFO_SAER_m : FIFO_SAER_ZYNQ
      port map (
        rst     => reset_sych_fifo,
        wr_clk  => Clk_i,
        rd_clk  => Clk_ls_p,
        din     => ii_tx_toSaerSrc(i).idx,
        wr_en   => synch_fifo_wr_en(i),
        rd_en   => synch_fifo_rd_en(i),
        dout    => ii_tx_toSaerSrc_synched(i).idx,
        full    => synch_fifo_full(i),
        empty   => synch_fifo_empty(i)
      );

end generate;    

FIFO_SAER_FOR_ZYNQUPLUS_gen : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin
   
    FIFO_SAER_m : FIFO_SAER_ZYNQUPLUS
      port map (
        rst     => reset_sych_fifo,
        wr_clk  => Clk_i,
        rd_clk  => Clk_ls_p,
        din     => ii_tx_toSaerSrc(i).idx,
        wr_en   => synch_fifo_wr_en(i),
        rd_en   => synch_fifo_rd_en(i),
        dout    => ii_tx_toSaerSrc_synched(i).idx,
        full    => synch_fifo_full(i),
        empty   => synch_fifo_empty(i)
      );

end generate;

    synch_fifo_wr_en(i) <= ii_tx_toSaerSrc(i).vld and not(synch_fifo_full(i));
    synch_fifo_rd_en(i) <= ii_tx_toSaerDst(i).rdy and not(synch_fifo_empty(i));
    
    ii_tx_toSaerSrc_synched(i).vld <= not(synch_fifo_empty(i));
       
    u_paer2hssaer_tx : hssaer_paer_tx_wrapper
      generic map (
        dsize       => C_PAER_DSIZE,        -- positive;
        int_dsize   => C_INTERNAL_DSIZE     -- positive := 32
        )
      port map (
        nrst        => ii_hssaer_nrst,                        -- in  std_logic;
        clkp        => Clk_ls_p,                              -- in  std_logic;
        clkn        => Clk_ls_n,                              -- in  std_logic;
        keep_alive  => keep_alive,                            -- in  std_logic;
        
        ae          => ii_tx_toSaerSrc_synched(i).idx,                -- in  std_logic_vector(int_dsize-1 downto 0);
        src_rdy     => ii_tx_toSaerSrc_synched(i).vld,                -- in  std_logic;
        dst_rdy     => ii_tx_toSaerDst(i).rdy,                -- out std_logic;
        
        tx          => HSSAER_Tx_o(i),                        -- out std_logic;
        
        run         => TxSaerStat_o(i).run,                   -- out std_logic;
        last        => TxSaerStat_o(i).last                   -- out std_logic
        );

  end generate g_hssaer_tx;

end generate g_hssaer_true;



g_hssaer_false : if C_HAS_HSSAER = false generate
  
  -- Output signals passivation
  i_HssaerDstRdy <= '0';
  
    g_hssaer_tx : for i in 0 to C_HSSAER_N_CHAN-1 generate
        HSSAER_Tx_o(i) <= '0';
        TxSaerStat_o(i).run  <= '0';
        TxSaerStat_o(i).last <= '0';
    end generate g_hssaer_tx;

end generate g_hssaer_false;


----------------------------------
-- SpiNNlink Transmitter
----------------------------------

g_spinnlnk_true : if C_HAS_SPNNLNK = true generate

signal i_data_2of7_to_spinnaker : std_logic_vector(6 downto 0);
signal i_ack_from_spinnaker     : std_logic;

begin

u_tx_spinnlink_datapath : spinn_neu_if
  generic map (
    C_PSPNNLNK_WIDTH             => C_PSPNNLNK_WIDTH,
    C_HAS_TX                     => "true",
    C_HAS_RX                     => "false"
    )
  port map (
    rst                          => Rst,
    clk_32                       => Clk_i, 
    enable                       => EnableSPNNLNK_i,
    
    dump_mode                    => TxSpnnlnkStat_o.dump_mode,   
    parity_err                   => open,
    rx_err                       => open,
    offload                      => SpnnOffload_o,
    link_timeout                 => SpnnLinkTimeout_o,
    link_timeout_dis             => SpnnLinkTimeoutDis_i,
  
    -- input SpiNNaker link interface
    data_2of7_from_spinnaker     => (others => '0'), 
    ack_to_spinnaker             => open,
  
    -- output SpiNNaker link interface
    data_2of7_to_spinnaker       => SPNN_Data_o,
    ack_from_spinnaker           => SPNN_Ack_i,
  
    -- input AER device interface
    iaer_addr                    => TxData_i,
    iaer_vld                     => i_SpnnlnkSrcRdy,
    iaer_rdy                     => i_SpnnlnkDstRdy,
  
    -- output AER device interface
    oaer_addr                    => open,              -- out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
    oaer_vld                     => open,              -- out std_logic;                                  
    oaer_rdy                     => '0',               -- in  std_logic;                                  
  
    -- Command from SpiNNaker
    keys_enable                  => '0',                 -- in  std_logic;
    start_key                    => (others => '0'),     -- in  std_logic_vector(31 downto 0);
    stop_key                     => (others => '0'),     -- in  std_logic_vector(31 downto 0);
    cmd_start                    => open,                -- out std_logic;
    cmd_stop                     => open,                -- out std_logic;
      		   
    -- Settings
    tx_data_mask                 => SpnnTxMask_i,        -- in  std_logic_vector(31 downto 0);
    rx_data_mask                 => (others => '0'),     -- in  std_logic_vector(31 downto 0);
  
    -- Controls
    offload_off                  => SpnnOffloadOff_i,  -- in  std_logic;
    offload_on                   => SpnnOffloadOn_i,   -- in  std_logic;
  
    -- Debug Port           
    dbg_rxstate                  => open,
    dbg_txstate                  => open,
    dbg_ipkt_vld                 => open,
    dbg_ipkt_rdy                 => open,
    dbg_opkt_vld                 => open,
    dbg_opkt_rdy                 => open
    ); 
        
end generate g_spinnlnk_true;

g_spinnlnk_false : if C_HAS_SPNNLNK = false generate
  -- Output signals grounding
  SPNN_Data_o <= (others => '0');
  -- Internal signals grounding
  i_SpnnlnkDstRdy <= '0';
  TxSpnnlnkStat_o.dump_mode <= '0';
  SpnnOffload_o <= '0';
  SpnnLinkTimeout_o <= '0';

end generate g_spinnlnk_false;


-------------------------------------------------------------
-- GTP Transmitter
-------------------------------------------------------------

g_gtp_true : if C_HAS_GTP = true generate

signal ii_gtp_nrst            : std_logic;

signal i_TxGtpPllAlarm        : std_logic;
signal i_TxGtpAutoAlign       : std_logic;
signal i_TxGtpErrorInjection  : std_logic;
signal i_TxGtpAlignFlag       : std_logic;

signal i_TxGtpDataRate        : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_TxGtpAlignRate       : std_logic_vector( 7 downto 0); -- Count per millisecond 
signal i_TxGtpMsgRate         : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_TxGtpIdleRate        : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_TxGtpEventRate       : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_TxGtpMessageRate     : std_logic_vector( 7 downto 0); -- Count per millisecond     

-- signal i_TxGtpDataDstRdy      : std_logic;
signal i_TxGtpMsgDstRdy       : std_logic;  

signal i_GtpSoftResetTx       : std_logic;  
signal i_GtpDataValid         : std_logic;  
signal i_GtpTxUserrdy         : std_logic;  
signal i_GtpTxData            : std_logic_vector(C_GTP_DSIZE-1 downto 0);  
signal i_GtpTxCharIsK         : std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);

begin

i_TxGtpAutoAlign      <= '0';
i_TxGtpErrorInjection <= '0';

ii_gtp_nrst <= nRst and EnableGTP_i;
 
  GT_MANAGER_TX_i : GT_Manager 
    generic map( 
      FAMILY_g                  =>  C_FAMILY,
      --
      USER_DATA_WIDTH_g         =>  C_INPUT_DSIZE,               -- Width of Data - Fabric side
      USER_MESSAGE_WIDTH_g      =>    8,                          -- Width of Message - Fabric side 
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
      PLL_ALARM_o             => i_TxGtpPllAlarm,
      
      -- ---------------------------------------------------------------------------------------
      -- TX SIDE
  
      -- Control in
      TX_AUTO_ALIGN_i         => i_TxGtpAutoAlign,         -- Enables the "Auto alignment mode"
      TX_ALIGN_REQUEST_i      => TxGtpAlignRequest_i,      -- Align request from Receiver
      TX_ERROR_INJECTION_i    => i_TxGtpErrorInjection,    -- Error insertin (debug purpose)
      
      -- Status
      TX_GT_ALIGN_FLAG_o      => i_TxGtpAlignFlag,         -- Monitor out: sending align
      
      -- Statistics
      TX_DATA_RATE_o          => i_TxGtpDataRate,
      TX_ALIGN_RATE_o         => i_TxGtpAlignRate,
      TX_MSG_RATE_o           => i_TxGtpMsgRate,
      TX_IDLE_RATE_o          => i_TxGtpIdleRate,
      TX_EVENT_RATE_o         => i_TxGtpEventRate,
      TX_MESSAGE_RATE_o       => i_TxGtpMessageRate,
  
    
      -- Data TX 
      TX_DATA_i               => TxData_i,
      TX_DATA_SRC_RDY_i       => i_TxGtpDataSrcRdy, 
      TX_DATA_DST_RDY_o       => i_TxGtpDataDstRdy,
      -- Message TX                 
      TX_MSG_i                => TxGtpMsg_i,
      TX_MSG_SRC_RDY_i        => TxGtpMsgSrcRdy_i,
      TX_MSG_DST_RDY_o        => i_TxGtpMsgDstRdy,
  
      -- ---------------------------------------------------------------------------------------
      -- RX SIDE    
      
      -- Control out
      RX_ALIGN_REQUEST_o      => open,  
      
      -- Status and errors
      RX_DISALIGNED_o         => open,
      
      -- Statistics     
      RX_DATA_RATE_o          => open,
      RX_ALIGN_RATE_o         => open, 
      RX_MSG_RATE_o           => open, 
      RX_IDLE_RATE_o          => open,
      RX_EVENT_RATE_o         => open,
      RX_MESSAGE_RATE_o       => open,
  
      -- Data RX 
      RX_DATA_o               => open,
      RX_DATA_SRC_RDY_o       => open,
      RX_DATA_DST_RDY_i       => '0',
      -- Message RX
      RX_MSG_o                => open,
      RX_MSG_SRC_RDY_o        => open, 
      RX_MSG_DST_RDY_i        => '0', 
      
          
     
      -- *****************************************************************************************
      -- GTP Interface    
      -- *****************************************************************************************
                                                                                          -- Clock Domain --
      -- Clock Ports
      GTP_TXUSRCLK2_i          => GTP_TxUsrClk2_i,
      GTP_RXUSRCLK2_i          => '0',  
      
      -- Reset FSM Control Ports
      SOFT_RESET_TX_o          => i_GtpSoftResetTx,                                       -- SYS_CLK      --
      SOFT_RESET_RX_o          => open,                                                   -- SYS_CLK      --
      GTP_DATA_VALID_o         => i_GtpDataValid,
          
      -- -------------------------------------------------------------------------
      -- TRANSMITTER 
      --------------------- TX Initialization and Reset Ports --------------------
      GTP_TXUSERRDY_o          => i_GtpTxUserrdy,                                         -- ASYNC        --
      ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
      GTP_TXDATA_o             => i_GtpTxData,                                            -- TXUSRCLK2    --
      ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
      GTP_TXCHARISK_o          => i_GtpTxCharIsK,                                                   -- TXUSRCLK2    --
      
      -- -------------------------------------------------------------------------
      -- RECEIVER
      --------------------- RX Initialization and Reset Ports --------------------
      GTP_RXUSERRDY_o          => open,                                   -- ASYNC        --
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTP_RXDATA_i             => (others => '0'),                                        -- RXUSRCLK2    --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTP_RXCHARISCOMMA_i      => (others => '0'),                                        -- RXUSRCLK2    --
      GTP_RXCHARISK_i          => (others => '0'),                                        -- RXUSRCLK2    --
      GTP_RXDISPERR_i          => (others => '0'),                                        -- RXUSRCLK2    --
      GTP_RXNOTINTABLE_i       => (others => '0'),                                        -- RXUSRCLK2    --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTP_RXBYTEISALIGNED_i    => '0',                                                    -- RXUSRCLK2    --
      GTP_RXBYTEREALIGN_i      => '0',                                                    -- RXUSRCLK2    --
      
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS
      GTP_PLL_LOCK_i           => GTP_PllLock_i,                                          -- ASYNC        --
      GTP_PLL_REFCLKLOST_i     => GTP_PllRefclklost_i,                                    -- SYS_CLK      -- 
 
 
 
      -- *****************************************************************************************
      -- Transceiver Interface for Ultrascale+ GTH
      -- ***************************************************************************************** 
       
      -- Clock Ports
      --  GTH_GTWIZ_USERCLK_TX_USRCLK2_i        : in std_logic_vector(0 downto 0);
      GTH_GTWIZ_USERCLK_RX_USRCLK2_i        => "0",
      
      -- Reset FSM Control Ports
      GTH_GTWIZ_RESET_ALL_o                 => open,               -- ASYNC     --


      -- -------------------------------------------------------------------------
      -- TRANSMITTER 

      -- TBD

      
      -- -------------------------------------------------------------------------
      -- RECEIVER
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTH_GTWIZ_USERDATA_RX_i               => (others => '0'),            -- RXUSRCLK2 --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTH_RXCTRL2_i                         => (others => '0'),  -- (RXCHARISCOMMA)  -- RXUSRCLK2 --
      GTH_RXCTRL0_i                         => (others => '0'),  -- (RXCHARISK)      -- RXUSRCLK2 --
      GTH_RXCTRL1_i                         => (others => '0'),  -- (RXDISPERR)      -- RXUSRCLK2 --
      GTH_RXCTRL3_i                         => (others => '0'),  -- (RXNOTINTABLE)   -- RXUSRCLK2 --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTH_RXBYTEISALIGNED_i                 => "0",             -- RXUSRCLK2 --
      GTH_RXBYTEREALIGN_i                   => "0",             -- RXUSRCLK2 --
          
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS    
      GTH_QPLL_LOCK_i                       => "0",              -- ASYNC     --
      GTH_QPLL_REFCLKLOST_i                 => "0"               -- QPLL0LOCKDETCLK --
             
    );  

  TxGtpAlignFlag_o        <= i_TxGtpAlignFlag;
  
  TxGtpDataRate_o         <= i_TxGtpDataRate;
  TxGtpAlignRate_o        <= i_TxGtpAlignRate;
  TxGtpMsgRate_o          <= i_TxGtpMsgRate;
  TxGtpIdleRate_o         <= i_TxGtpIdleRate;
  TxGtpEventRate_o        <= i_TxGtpEventRate;
  TxGtpMessageRate_o      <= i_TxGtpMessageRate;
  
  TxGtpMsgDstRdy_o        <= i_TxGtpMsgDstRdy;
  
  GTP_SoftResetTx_o       <= i_GtpSoftResetTx;
  GTP_DataValid_o         <= i_GtpDataValid;
  GTP_Txuserrdy_o         <= i_GtpTxUserrdy;
  GTP_Txdata_o            <= i_GtpTxData;
  GTP_Txcharisk_o         <= i_GtpTxCharIsK;
  
end generate g_gtp_true;
  
  
g_gtp_false : if C_HAS_GTP = false generate

  TxGtpAlignFlag_o        <= '0';
  
  TxGtpDataRate_o         <= (others => '0');
  TxGtpAlignRate_o        <= (others => '0');
  TxGtpMsgRate_o          <= (others => '0');
  TxGtpIdleRate_o         <= (others => '0');
  TxGtpEventRate_o        <= (others => '0');
  TxGtpMessageRate_o      <= (others => '0');
  
  TxGtpMsgDstRdy_o        <= '0';
  
  GTP_SoftResetTx_o       <= '0';
  GTP_DataValid_o         <= '0';
  GTP_Txuserrdy_o         <= '0';
  GTP_Txdata_o            <= (others => '0');
  GTP_Txcharisk_o         <= (others => '0');
  
end generate g_gtp_false;
    
end architecture str;
