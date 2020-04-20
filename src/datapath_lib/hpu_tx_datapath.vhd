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
    use HPU_lib.aer_pkg.all;

library datapath_lib;
    use datapath_lib.DPComponents_pkg.all;
    
library spinn_neu_if_lib;
        use spinn_neu_if_lib.spinn_neu_pkg.all;



entity hpu_tx_datapath is
    generic (
    C_INPUT_DSIZE    : natural range 1 to 32 := 32;
    C_PAER_DSIZE     : positive              := 20;
    C_HAS_PAER       : boolean               := true;
    C_HAS_GTP        : boolean               := true;
    C_HAS_SPNNLNK    : boolean;
    C_PSPNNLNK_WIDTH : natural range 1 to 32 := 32;
    C_HAS_HSSAER     : boolean               := true;
    C_HSSAER_N_CHAN  : natural range 1 to 4  := 4
);
port (
    -- Clocks & Reset
    nRst                    : in  std_logic;
    Clk_core                : in  std_logic;
    Clk_ls_p                : in  std_logic;
    Clk_ls_n                : in  std_logic;

    -----------------------------
    -- uController Interface
    -----------------------------

    -- Control signals
    -----------------------------
    --EnableIP_i              : in  std_logic;
    --PaerFlushFifos_i        : in  std_logic;

    -- Status signals
    -----------------------------
    --PaerFifoFull_o          : out std_logic;
    TxSaerStat_o            : out t_TxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    TxSpnnlnkStat_o         : out t_TxSpnnlnkStat;
    
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
    
    -----------------------------
    -- Sequencer Interface
    -----------------------------
    FromSeqDataIn_i         : in  std_logic_vector(C_INPUT_DSIZE-1 downto 0);
    FromSeqSrcRdy_i         : in  std_logic;
    FromSeqDstRdy_o         : out std_logic;
      
    -----------------------------
    -- Destination interfaces
    -----------------------------
    -- Parallel AER
    PAER_Addr_o             : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    PAER_Req_o              : out std_logic;
    PAER_Ack_i              : in  std_logic;

    -- HSSAER
    HSSAER_Tx_o             : out std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    -- GTP interface
    --
    -- TBD signals to drive the GTP
    --

    -- SpiNNlink 
    data_2of7_to_spinnaker_o    : out std_logic_vector(6 downto 0);
    ack_from_spinnaker_i        : in  std_logic

    -----------------------------
    -- Debug signals
    -----------------------------

);
end entity hpu_tx_datapath;




architecture str of hpu_tx_datapath is

    signal Rst             : std_logic;
    
    signal i_selDest : std_logic_vector(1 downto 0);

    signal i_paer_DstRdy    : std_logic;
    signal i_hssaer_DstRdy  : std_logic;
    signal i_gtp_DstRdy     : std_logic;
    signal i_spnnlnk_DstRdy : std_logic;

    signal i_paer_SrcRdy    : std_logic;
    signal i_hssaer_SrcRdy  : std_logic;
    signal i_gtp_SrcRdy     : std_logic;
    signal i_spnnlnk_SrcRdy : std_logic;
        
    signal i_mergedSrcRdy   : std_logic;
    signal i_mergedDstRdy   : std_logic;
    signal i_vectSrcRdy     : std_logic_vector(2 downto 0);
    signal i_vectDstRdy     : std_logic_vector(2 downto 0);

    signal i_data_2of7_to_spinnaker    : std_logic_vector(6 downto 0);
    signal i_ack_from_spinnaker        : std_logic;
    signal i_iaer_addr                 : std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
    signal i_iaer_vld                  : std_logic;
    signal i_iaer_rdy                  : std_logic;

    
begin


	Rst <= not nRst;
	
    -- Route the Sequencer packet to one of the destination paths according
    -- to the Destination Switch (TX_CTRL_REG[6:4]) or MSBits in Data:
    --     00 => the packet is sent to the parallel AER interface
    --     01 => the packet is sent to the HSSAER interface
    --     10 => the packet is sent to the SpiNNlink interface ------------ it was: GTP driver interface
    --     11 => the packet is sent to all the interfaces: it is acknowledged
    --           only when all the interfaces have acknowledged the transfer
    i_selDest <= DestinationSwitch_i(1 downto 0) when (DestinationSwitch_i(2) = '1') else FromSeqDataIn_i(C_INPUT_DSIZE-1 downto C_INPUT_DSIZE-2);

    i_paer_SrcRdy    <= FromSeqSrcRdy_i when (i_selDest = "00") else 
                        i_vectSrcRdy(0) when (i_selDest = "11") else
                        '0';
    i_hssaer_SrcRdy  <= FromSeqSrcRdy_i when (i_selDest = "01") else
                        i_vectSrcRdy(1) when (i_selDest = "11") else
                        '0';
--    i_gtp_SrcRdy    <= FromSeqSrcRdy_i when (i_selDest = "10") else
--                       i_vectSrcRdy(2) when (i_selDest = "11") else
--                       '0';
    i_spnnlnk_SrcRdy <= FromSeqSrcRdy_i when (i_selDest = "10") else
                        i_vectSrcRdy(2) when (i_selDest = "11") else
                        '0';

    -- Select the Tx path in charge of generating the Acknowledge to the Rx channels
    with i_selDest select
        FromSeqDstRdy_o <= i_paer_DstRdy    when "00",
                           i_hssaer_DstRdy  when "01",
                           i_spnnlnk_DstRdy when "10",   -- it was: i_gtp_DstRdy    when "10",
                           i_mergedDstRdy   when others;


    i_mergedSrcRdy <= FromSeqSrcRdy_i when (i_selDest = "11") else '0';
    i_vectDstRdy <= i_spnnlnk_DstRdy & i_hssaer_DstRdy & i_paer_DstRdy;   -- it was: i_gtp_DstRdy & i_hssaer_DstRdy & i_paer_DstRdy;
    
    u_mergeRdy : merge_rdy
        generic map (
            N_CHAN        => 3
        )
        port map (
            nRst          => nRst,
            Clk           => Clk_core,
            
            InVld_i       => i_mergedSrcRdy,
            OutRdy_o      => i_mergedDstRdy,
            
            OutVldVect_o  => i_vectSrcRdy,
            InRdyVect_i   => i_vectDstRdy
        );

    --===========================================================
    -- DESTINATION PATHS
    --===========================================================

    -------------------------------------------------------------
    -- PAER Driver
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
                ClkxCI               => Clk_core,          -- in std_ulogic;
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
                InpSrcRdyxSI         => i_paer_SrcRdy,     -- in  std_ulogic;
                InpDstRdyxSO         => i_paer_DstRdy      -- out std_ulogic
            );

    end generate g_paer_true;


    g_paer_false : if C_HAS_PAER = false generate
        -- Output signals passivation
        PAER_Req_o  <= not PaerReqActLevel_i;
        PAER_Addr_o <= (others => '0');

        i_paer_DstRdy <= '0';

    end generate g_paer_false;


    -------------------------------------------------------------
    -- HSSAER Driver
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
                Clk                => Clk_core,                  -- in  std_logic;
                nRst               => ii_hssaer_nrst,            -- in  std_logic;
                --
                ChEn_i             => HSSaerChanEn_i,            -- in  std_logic_vector(C_NUM_CHAN-1 downto 0);
                --
                PaerDataIn_i       => FromSeqDataIn_i,           -- in  std_logic_vector(C_IDATA_WIDTH-1 downto 0);
                PaerSrcRdy_i       => i_hssaer_SrcRdy,           -- in  std_logic;
                PaerDstRdy_o       => i_hssaer_DstRdy,           -- out std_logic;
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
          PORT MAP (
            rst => reset_sych_fifo,
            wr_clk => Clk_core,
            rd_clk => Clk_ls_p,
            din => ii_tx_toSaerSrc(i).idx,
            wr_en => synch_fifo_wr_en(i),
            rd_en => synch_fifo_rd_en(i),
            dout => ii_tx_toSaerSrc_synched(i).idx,
            full => synch_fifo_full(i),
            empty => synch_fifo_empty(i)
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
        i_hssaer_DstRdy <= '0';

        g_hssaer_tx : for i in 0 to C_HSSAER_N_CHAN-1 generate
            HSSAER_Tx_o(i) <= '0';
            TxSaerStat_o(i).run  <= '0';
            TxSaerStat_o(i).last <= '0';
        end generate g_hssaer_tx;

    end generate g_hssaer_false;



    -------------------------------------------------------------
    -- GTP Driver
    -------------------------------------------------------------

    g_gtp_true : if C_HAS_GTP = true generate

        i_gtp_DstRdy <= '1';   -- TBD

    end generate g_gtp_true;


    g_gtp_false : if C_HAS_GTP = false generate
    
        -- Output signals passivation
        i_gtp_DstRdy <= '1';

    end generate g_gtp_false;
    
        

    ----------------------------------
    -- SpiNNlink Driver
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
            clk_32                       => Clk_core, -- 100 MHz Clock
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
            iaer_vld                     => i_spnnlnk_SrcRdy,
            iaer_rdy                     => i_spnnlnk_DstRdy,
    
        -- output AER device interface
            oaer_addr                    => open,           -- out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
            oaer_vld                     => open,           -- out std_logic;                                  
            oaer_rdy                     => '0',            -- in  std_logic;                                  

        -- Command from SpiNNaker
            keys_enable                => '0',              -- in  std_logic;
            start_key                  => (others => '0'),  -- in  std_logic_vector(31 downto 0);
            stop_key                   => (others => '0'),  -- in  std_logic_vector(31 downto 0);
            cmd_start                  => open,             -- out std_logic;
            cmd_stop                   => open,             -- out std_logic;
            		   
            -- Settings
            tx_data_mask               => Spnn_tx_mask_i,   -- in  std_logic_vector(31 downto 0);
            rx_data_mask               => (others => '0'),  -- in  std_logic_vector(31 downto 0);
        
        -- Controls
            offload_off                => Spnn_offload_off_i,  -- in  std_logic;
            offload_on                 => Spnn_offload_on_i,   -- in  std_logic;

        -- Debug Port           
            dbg_rxstate                => open,
            dbg_txstate                => open,
            dbg_ipkt_vld               => open,
            dbg_ipkt_rdy               => open,
            dbg_opkt_vld               => open,
            dbg_opkt_rdy               => open
            ); 
            
    end generate g_spinnlnk_true;

    g_spinnlnk_false : if C_HAS_SPNNLNK = false generate
        -- Output signals grounding
        data_2of7_to_spinnaker_o <= (others => '0');
        -- Internal signals grounding
        i_spnnlnk_DstRdy <= '0';
        TxSpnnlnkStat_o.dump_mode <= '0';
        Spnn_Offload_o <= '0';
        Spnn_Link_Timeout_o <= '0';

    end generate g_spinnlnk_false;
    
end architecture str;
