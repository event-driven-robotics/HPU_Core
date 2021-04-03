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
    
library GTP_lib;
  use GTP_lib.GTP_pkg.all;


entity hpu_tx_datapath is
  generic (
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
    -- uController Interface
    -- **********************************************

    -- Control signals
    -----------------------------
    -- EnableIP_i              : in  std_logic;
    -- PaerFlushFifos_i        : in  std_logic;

    -- Status signals
    -----------------------------
    --PaerFifoFull_o          : out std_logic;
    TxSaerStat_o            : out t_TxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    TxSpnnlnkStat_o         : out t_TxSpnnlnkStat;
    -- GTP Statistics        
    GtpTxDataRate_o         : out std_logic_vector(15 downto 0); -- Count per millisecond 
    GtpTxAlignRate_o        : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    GtpTxMsgRate_o          : out std_logic_vector(15 downto 0); -- Count per millisecond 
    GtpTxIdleRate_o         : out std_logic_vector(15 downto 0); -- Count per millisecond 
    GtpTxEventRate_o        : out std_logic_vector(15 downto 0); -- Count per millisecond 
    GtpTxMessageRate_o      : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    
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
    Spnn_offload_on_i       : in  std_logic;
    Spnn_offload_off_i      : in  std_logic;
    Spnn_tx_mask_i          : in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    Spnn_Offload_o          : out std_logic;
    Spnn_Link_Timeout_o     : out std_logic;
    Spnn_Link_Timeout_dis_i : in  std_logic;
    
    -- **********************************************
    -- Sequencer Interface
    -- **********************************************
    FromSeqDataIn_i         : in  std_logic_vector(C_INPUT_DSIZE-1 downto 0);
    FromSeqSrcRdy_i         : in  std_logic;
    FromSeqDstRdy_o         : out std_logic;
      
    -- **********************************************
    -- Destination interfaces
    -- **********************************************
    
    -- Parallel AER
    -- ----------------------------------------------
    PAER_Addr_o             : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_o              : out std_logic;
    PAER_Ack_i              : in  std_logic;

    -- HSSAER
    -- ----------------------------------------------
    HSSAER_Tx_o             : out std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP interface
    -- ----------------------------------------------
    TxGtpAutoAlign_i            : in  std_logic;
    TxGtpAlignRequest_i         : in  std_logic;
    TxGtpErrorInjection_i       : in  std_logic;
    -- Status
    TxGtpAlignFlag_o            : out std_logic;   -- Monitor out: sending align    

    -- GTP Wizard Interface
    -- Clock Ports
    GtpTxUsrClk2_i             : in  std_logic;   

    -- Reset FSM Control Ports
    SoftResetTx_o              : out  std_logic;                                          
    GtpDataValid_o             : out std_logic;    

    -- -----------
    -- Transmitter
    
    -- TX Initialization and Reset Ports
    GtpTxuserrdy_o             : out std_logic;                                           
    -- Transmit Ports - FPGA TX Interface Ports
    GtpTxdata_o                : out std_logic_vector(C_GTP_DSIZE-1 downto 0);            
    -- Transmit Ports - TX 8B/10B Encoder Ports
    GtpTxcharisk_o             : out std_logic_vector((C_GTP_DSIZE/8)-1 downto 0);        

    -- ------------ 
    -- Common ports
    GtpPllLock_i               : in  std_logic;                                           
    GtpPllRefclklost_i         : in  std_logic;          
        
    -- SpiNNlink
    -- ----------------------------------------------
    data_2of7_to_spinnaker_o    : out std_logic_vector(6 downto 0);
    ack_from_spinnaker_i        : in  std_logic

    -- **********************************************
    -- Debug signals
    -- **********************************************

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

signal i_selDest : std_logic_vector(1 downto 0);

signal i_PaerDstRdy             : std_logic;
signal i_HssaerDstRdy           : std_logic;
signal i_GtpDataDstRdy          : std_logic;
signal i_SpnnlnkDstRdy          : std_logic;

signal i_PaerSrcRdy             : std_logic;
signal i_HssaerSrcRdy           : std_logic;
signal i_GtpDataSrcRdy          : std_logic;
signal i_SpnnlnkSrcRdy          : std_logic;
    
signal i_MergedSrcRdy           : std_logic;
signal i_MergedDstRdy           : std_logic;
signal i_VectSrcRdy             : std_logic_vector(3 downto 0);
signal i_VectDstRdy             : std_logic_vector(3 downto 0);

signal i_data_2of7_to_spinnaker : std_logic_vector(6 downto 0);
signal i_ack_from_spinnaker     : std_logic;
signal i_iaer_addr              : std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
signal i_iaer_vld               : std_logic;
signal i_iaer_rdy               : std_logic;


-- GTP     
signal i_TxGtpPllAlarm        : std_logic;
signal i_TxGtpAutoAlign       : std_logic;
signal i_TxGtpErrorInjection  : std_logic;
signal i_TxGtpAlignFlag       : std_logic;

signal i_GtpTxDataRate        : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_GtpTxAlignRate       : std_logic_vector( 7 downto 0); -- Count per millisecond 
signal i_GtpTxMsgRate         : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_GtpTxIdleRate        : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_GtpTxEventRate       : std_logic_vector(15 downto 0); -- Count per millisecond 
signal i_GtpTxMessageRate     : std_logic_vector( 7 downto 0); -- Count per millisecond     

signal i_GtpTxData            : std_logic_vector(C_INPUT_DSIZE-1 downto 0);
signal i_GtpTxDataSrcRdy      : std_logic;
signal i_GtpTxDataDstRdy      : std_logic;
signal i_GtpTxMsg             : std_logic_vector( 7 downto 0);
signal i_GtpTxMsgSrcRdy       : std_logic;
signal i_GtpTxMsgDstRdy       : std_logic;  

-- signal i_SoftResetRx       : std_logic;
-- signal i_GtpDataValid      : std_logic;
-- signal i_GtpRxuserrdy      : std_logic;

    
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
             FromSeqDataIn_i(C_INPUT_DSIZE-1 downto C_INPUT_DSIZE-2);                  -- or from incoming data


i_PaerSrcRdy    <= FromSeqSrcRdy_i when (i_selDest = PAER_TX_SELECTED_c) else 
                   -- i_VectSrcRdy(0) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                   '0';
i_HssaerSrcRdy  <= FromSeqSrcRdy_i when (i_selDest = HSSAER_TX_SELECTED_c) else
                   -- i_VectSrcRdy(1) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                   '0';
i_SpnnlnkSrcRdy <= FromSeqSrcRdy_i when (i_selDest = SPINNAKER_TX_SELECTED_c) else
                   -- i_VectSrcRdy(2) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                   '0';
i_GtpDataSrcRdy <= FromSeqSrcRdy_i when (i_selDest = GTP_TX_SELECTED_c) else
                   -- i_VectSrcRdy(3) when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                   '0';


with i_selDest select  -- the Tx path 
  FromSeqDstRdy_o <= i_PaerDstRdy    when PAER_TX_SELECTED_c,
                     i_HssaerDstRdy  when HSSAER_TX_SELECTED_c,
                     i_SpnnlnkDstRdy when SPINNAKER_TX_SELECTED_c,
                     i_GtpDataDstRdy when GTP_TX_SELECTED_c,
                     -- i_MergedDstRdy   when (false),
                     '0'              when others; 

-- -----------
-- Merged path
i_MergedSrcRdy   <= FromSeqSrcRdy_i when (false) else -- NOTE: Insert the condition for mergedSrcRdy
                    '0';    

-- Composing i_VectDstRdy
i_VectDstRdy(conv_integer(unsigned(PAER_TX_SELECTED_c)))      <= i_PaerDstRdy;      
i_VectDstRdy(conv_integer(unsigned(HSSAER_TX_SELECTED_c)))    <= i_HssaerDstRdy;   
i_VectDstRdy(conv_integer(unsigned(SPINNAKER_TX_SELECTED_c))) <= i_SpnnlnkDstRdy;                         
i_VectDstRdy(conv_integer(unsigned(GTP_TX_SELECTED_c)))       <= i_GtpDataDstRdy;   

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

  ii_paer_nrst <= nRst and EnablePAER_i;        -- Modified from OR to AND logic - Maurizio Casti, 07/24/2018 
  
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
    InpDataxDI           => FromSeqDataIn_i,   -- in  std_ulogic_vector(internal_width-1 downto 0);
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

  ii_hssaer_nrst <= nRst or EnableHSSAER_i;
  
  
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
      PaerDataIn_i       => FromSeqDataIn_i,           -- in  std_logic_vector(C_IDATA_WIDTH-1 downto 0);
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
    
    i_synch_fifo : synch_fifo
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
    offload                      => Spnn_Offload_o,
    link_timeout                 => Spnn_Link_Timeout_o,
    link_timeout_dis             => Spnn_Link_Timeout_dis_i,
  
    -- input SpiNNaker link interface
    data_2of7_from_spinnaker     => (others => '0'), 
    ack_to_spinnaker             => open,
  
    -- output SpiNNaker link interface
    data_2of7_to_spinnaker       => data_2of7_to_spinnaker_o,
    ack_from_spinnaker           => ack_from_spinnaker_i,
  
    -- input AER device interface
    iaer_addr                    => FromSeqDataIn_i,
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
    tx_data_mask                 => Spnn_tx_mask_i,      -- in  std_logic_vector(31 downto 0);
    rx_data_mask                 => (others => '0'),     -- in  std_logic_vector(31 downto 0);
  
    -- Controls
    offload_off                  => Spnn_offload_off_i,  -- in  std_logic;
    offload_on                   => Spnn_offload_on_i,   -- in  std_logic;
  
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
  data_2of7_to_spinnaker_o <= (others => '0');
  -- Internal signals grounding
  i_SpnnlnkDstRdy <= '0';
  TxSpnnlnkStat_o.dump_mode <= '0';
  Spnn_Offload_o <= '0';
  Spnn_Link_Timeout_o <= '0';

end generate g_spinnlnk_false;


-------------------------------------------------------------
-- GTP Transmitter
-------------------------------------------------------------

i_TxGtpAutoAlign      <= '0';
i_TxGtpErrorInjection <= '0';

 
  GTP_MANAGER_RX_i : GTP_Manager 
    generic map( 
      USER_DATA_WIDTH_g         =>  C_INPUT_DSIZE,               -- Width of Data - Fabric side
      USER_MESSAGE_WIDTH_g      =>    8,                          -- Width of Message - Fabric side 
      GTP_DATA_WIDTH_g          =>  C_GTP_DSIZE,                  -- Width of Data - GTP side
      GTP_TXUSRCLK2_PERIOD_NS_g =>  C_GTP_TXUSRCLK2_PERIOD_NS,    -- TX GTP User clock period
      GTP_RXUSRCLK2_PERIOD_NS_g =>  C_GTP_RXUSRCLK2_PERIOD_NS,    -- RX GTP User clock period
      SIM_TIME_COMPRESSION_g    =>  C_SIM_TIME_COMPRESSION    -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
      )
    port map(
      
      -- COMMONs
      -- Bare Control ports
      CLK_i                   => Clk_i,  -- Input clock - Fabric side
      RST_N_i                 => nRst,      -- Asynchronous active low reset (clk clock)
      EN1S_i                  => En1Sec_i,  -- Enable @ 1 sec in clk domain 
  
      -- Status
      PLL_ALARM_o             => i_TxGtpPllAlarm,
      
      -- ---------------------------------------------------------------------------------------
      -- TX SIDE
  
      -- Control in
      TX_AUTO_ALIGN_i         => i_TxGtpAutoAlign,         -- Enables the "Auto alignment mode"
      TX_ALIGN_REQUEST_i      => TxGtpAlignRequest_i,      -- Align request from Receiver
      TX_ERROR_INJECTION_i    => i_TxGtpErrorInjection,    -- Error insertin (debug purpose)
      
      -- Status
      TX_GTP_ALIGN_FLAG_o     => i_TxGtpAlignFlag,         -- Monitor out: sending align
      
      -- Statistics
      TX_DATA_RATE_o          => i_GtpTxDataRate,
      TX_ALIGN_RATE_o         => i_GtpTxAlignRate,
      TX_MSG_RATE_o           => i_GtpTxMsgRate,
      TX_IDLE_RATE_o          => i_GtpTxIdleRate,
      TX_EVENT_RATE_o         => i_GtpTxEventRate,
      TX_MESSAGE_RATE_o       => i_GtpTxMessageRate,
  
    
      -- Data TX 
      TX_DATA_i               => FromSeqDataIn_i,
      TX_DATA_SRC_RDY_i       => i_GtpDataSrcRdy,
      TX_DATA_DST_RDY_o       => i_GtpDataDstRdy,
      -- Message TX                 
      TX_MSG_i                => (others => '0'),
      TX_MSG_SRC_RDY_i        => '0',
      TX_MSG_DST_RDY_o        => open,
  
      -- ---------------------------------------------------------------------------------------
      -- RX SIDE    
      
      -- Control out
      RX_ALIGN_REQUEST_o      => open,  
      
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
      GTP_TXUSRCLK2_i          => GtpTxUsrClk2_i,
      GTP_RXUSRCLK2_i          => '0',  
      
      -- Reset FSM Control Ports
      SOFT_RESET_TX_o          => SoftResetTx_o,                                             -- SYS_CLK      --
      SOFT_RESET_RX_o          => open,                                    -- SYS_CLK      --
      GTP_DATA_VALID_o         => GtpDataValid_o,
          
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
      GTP_RXUSERRDY_o          => GtpRxuserrdy_o,                                   -- ASYNC        --
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      GTP_RXDATA_i             => GtpRxdata_i,                                      -- RXUSRCLK2    --
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      GTP_RXCHARISCOMMA_i      => GtpRxchariscomma_i,                               -- RXUSRCLK2    --
      GTP_RXCHARISK_i          => GtpRxcharisk_i,                                   -- RXUSRCLK2    --
      GTP_RXDISPERR_i          => GtpRxdisperr_i,                                   -- RXUSRCLK2    --
      GTP_RXNOTINTABLE_i       => GtpRxnotintable_i,                                -- RXUSRCLK2    --
      -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
      GTP_RXBYTEISALIGNED_i    => GtpRxbyteisaligned_i,                            -- RXUSRCLK2    --
      GTP_RXBYTEREALIGN_i      => GtpRxbyterealign_i,                              -- RXUSRCLK2    --
      
      -- -------------------------------------------------------------------------    
      -- COMMON PORTS
      GTP_PLL_LOCK_i           => GtpPllLock_i,                                   -- ASYNC        --
      GTP_PLL_REFCLKLOST_i     => GtpPllRefclklost_i                              -- SYS_CLK      -- 
      );
     
  i_InPaerSrc(2).idx    <= i_GtpData;
  i_InPaerSrc(2).vld    <= i_GtpDataSrcRdy; 
  i_GtpDataDstRdy       <= i_InPaerDst(2).rdy;
  
  i_GtpMsgDstRdy        <= '0';
  
  RxGtpStat_o.pll_alarm <= i_PllAlarm;
  
  GtpRxDataRate_o       <= i_GtpRxDataRate; 
  GtpRxAlignRate_o      <= i_GtpRxAlignRate; 
  GtpRxMsgRate_o        <= i_GtpRxMsgRate; 
  GtpRxIdleRate_o       <= i_GtpRxIdleRate; 
  GtpRxEventRate_o      <= i_GtpRxEventRate; 
  GtpRxMessageRate_o    <= i_GtpRxMessageRate;     
  
  RxGtpAlignRequest_o   <= i_RxGtpAlignRequest;  
     
  SoftResetRx_o         <= i_SoftResetRx;  
  GtpDataValid_o        <= i_GtpDataValid;
  GtpRxuserrdy_o        <= i_GtpRxuserrdy;
  
end generate g_gtp_true;
  
  
g_gtp_false : if C_HAS_GTP = false generate

  -- Output signals passivation
  
  i_GtpDstRdy <= '1';
  
  i_InPaerSrc(2).idx <= (others => '0');
  i_InPaerSrc(2).vld <= '0';
  
  RxGtpStat_o.pll_alarm <= '0';
  
  GtpRxDataRate_o     <= (others => '0'); 
  GtpRxAlignRate_o    <= (others => '0'); 
  GtpRxMsgRate_o      <= (others => '0'); 
  GtpRxIdleRate_o     <= (others => '0'); 
  GtpRxEventRate_o    <= (others => '0'); 
  GtpRxMessageRate_o  <= (others => '0');     
  
  RxGtpAlignRequest_o <= '0';  
     
  SoftResetRx_o       <= '0';  
  GtpDataValid_o      <= '0';
  GtpRxuserrdy_o      <= '0';
  
end generate g_gtp_false;
    
end architecture str;
