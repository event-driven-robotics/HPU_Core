library ieee;
    use ieee.std_logic_1164.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;

library datapath_lib;
    use datapath_lib.DPComponents_pkg.all;

library HPU_lib;
    use HPU_lib.aer_pkg.C_INTERNAL_DSIZE;
    	
library spinn_neu_if_lib;
    use spinn_neu_if_lib.spinn_neu_pkg.all;

entity hpu_rx_datapath is
    generic (
        C_OUTPUT_DSIZE   : natural range 1 to 32 := 32;
        C_PAER_DSIZE     : positive              := 20;
        C_HAS_PAER       : boolean               := true;
        C_HAS_HSSAER     : boolean               := true;
        C_HSSAER_N_CHAN  : natural range 1 to 4  := 4;
        C_HAS_GTP        : boolean               := true;
        C_HAS_SPNNLNK    : boolean               := true;
        C_PSPNNLNK_WIDTH : natural range 1 to 32 := 32
    );
    port (
        nRst                    : in  std_logic;
        Clk_core                : in  std_logic;
        Clk_hs_p                : in  std_logic;
        Clk_hs_n                : in  std_logic;
        Clk_ls_p                : in  std_logic;
        Clk_ls_n                : in  std_logic;

        -----------------------------
        -- uController Interface
        -----------------------------

        -- Control signals
        -----------------------------
        PaerFlushFifos_i        : in  std_logic;

        -- Status signals
        -----------------------------
        PaerFifoFull_o          : out std_logic;
        RxSaerStat_o            : out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
        RxSpnnlnkStat_o         : out t_RxSpnnlnkStat;

        -- Configuration signals
        -----------------------------
        --
        -- Source I/F configurations
        EnablePAER_i            : in  std_logic;
        EnableHSSAER_i          : in  std_logic;
        EnableGTP_i             : in  std_logic;
        EnableSPNNLNK_i         : in  std_logic;
        -- PAER
        RxPaerHighBits_i        : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
        PaerReqActLevel_i       : in  std_logic;
        PaerAckActLevel_i       : in  std_logic;
        PaerIgnoreFifoFull_i    : in  std_logic;
        PaerAckSetDelay_i       : in  std_logic_vector(7 downto 0);
        PaerSampleDelay_i       : in  std_logic_vector(7 downto 0);
        PaerAckRelDelay_i       : in  std_logic_vector(7 downto 0);
        -- HSSAER
        RxSaerHighBits_i        : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
        HSSaerChanEn_i          : in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
        -- GTP
        RxGtpHighBits_i         : in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);

        -- SpiNNlink controls
        -----------------------------
        Spnn_cmd_start_key_i    : in  std_logic_vector(31 downto 0);
        Spnn_cmd_stop_key_i     : in  std_logic_vector(31 downto 0);
        Spnn_cmd_start_o        : out std_logic;
        Spnn_cmd_stop_o         : out std_logic;
        Spnn_rx_mask_i          : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
                
        -----------------------------
        -- Source Interfaces
        -----------------------------
        -- Parallel AER
        PAER_Addr_i             : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        PAER_Req_i              : in  std_logic;
        PAER_Ack_o              : out std_logic;

        -- HSSAER
        HSSAER_Rx_i             : in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

        -- GTP interface
        --
        -- TBD signals to drive the GTP
        --

        -- SpiNNlink
        data_2of7_from_spinnaker_i : in  std_logic_vector(6 downto 0); 
        ack_to_spinnaker_o         : out std_logic;

        -----------------------------
        -- Monitor interface
        -----------------------------
        ToMonDataIn_o           : out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
        ToMonSrcRdy_o           : out std_logic;
        ToMonDstRdy_i           : in  std_logic;

        -----------------------------
        -- In case of aux channel the HPU header is adapted to what received
        -----------------------------
        Aux_Channel_i           : in  std_logic;


        -----------------------------
        -- Debug signals
        -----------------------------
        dbg_PaerDataOk          : out std_logic;
        DBG_src_rdy             : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
        DBG_dst_rdy             : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
        DBG_err                 : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);  
        DBG_run                 : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
        DBG_RX                  : out std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);

        DBG_FIFO_0              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_1              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_2              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_3              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_4              : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)

    );
end entity hpu_rx_datapath;




architecture str of hpu_rx_datapath is

    signal i_InPaerSrc : t_PaerSrc_array(0 to 3);
    signal i_InPaerDst : t_PaerDst_array(0 to 3);
    signal i_RxSaerStat: t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
    signal DBG_FIFO0 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal DBG_FIFO1 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal DBG_FIFO2 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal DBG_FIFO3 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal DBG_FIFO4 : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    
    signal	Rst	     : std_logic;

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
                ClkxCI               => Clk_core,               -- in  std_logic;
                RstxRBI              => ii_paer_nrst,           -- in  std_logic;
                EnableIp             => EnablePAER_i,           -- in  std_logic;
                FlushFifo            => PaerFlushFifos_i,       -- in  std_logic;
                IgnoreFifoFull_i     => PaerIgnoreFifoFull_i,   -- in  std_logic;

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
        signal ii_rx_fromSaerDst : t_PaerDst_array(0 to C_HSSAER_N_CHAN-1);
        signal i_HSSAER_Rx : std_logic_vector(0 to C_HSSAER_N_CHAN-1);

    begin

        ii_hssaer_nrst <= nRst and EnableHSSAER_i;

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

                    higher_bits => RxSaerHighBits_i,         -- in  std_logic_vector(int_dsize-1 downto dsize);

                    ae          => ii_rx_fromSaerSrc(i).idx, -- out std_logic_vector(int_dsize-1 downto 0);
                    src_rdy     => ii_rx_fromSaerSrc(i).vld, -- out std_logic;
                    dst_rdy     => ii_rx_fromSaerDst(i).rdy, -- in  std_logic;

                    err_ko      => i_RxSaerStat(i).err_ko,   -- out std_logic;
                    err_rx      => i_RxSaerStat(i).err_rx,   -- out std_logic;
                    err_to      => i_RxSaerStat(i).err_to,   -- out std_logic;
                    err_of      => i_RxSaerStat(i).err_of,   -- out std_logic;
                    int         => i_RxSaerStat(i).int,      -- out std_logic;
                    run         => i_RxSaerStat(i).run,       -- out std_logic;

                    aux_channel => Aux_Channel_i             -- in  std_logic;
                );

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
                Clk                => Clk_core,           -- in  std_logic;
                nRst               => ii_hssaer_nrst,     -- in  std_logic;

                --ArbCfg_i           =>                     -- in  t_ArbiterCfg;

                SplittedPaerSrc_i  => ii_rx_fromSaerSrc,  -- in  t_PaerSrc_array(0 to C_NUM_CHAN-1);
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

        i_InPaerSrc(2).idx <= (others => '0');
        i_InPaerSrc(2).vld <= '0';

    end generate g_gtp_true;


    g_gtp_false : if C_HAS_GTP = false generate
        -- Output signals passivation

        i_InPaerSrc(2).idx <= (others => '0');
        i_InPaerSrc(2).vld <= '0';


    end generate g_gtp_false;
    
    ----------------------------------
    -- SpiNNlink receiver
    ----------------------------------

    g_spinnlnk_true : if C_HAS_SPNNLNK = true generate
    
    begin
       
       u_spinnlink_rx : spinn_neu_if
           generic map (
               C_PSPNNLNK_WIDTH       => C_PSPNNLNK_WIDTH,
               C_HAS_TX               => "false",
               C_HAS_RX               => "true"
               )
           port map (
           rst                        => Rst,
           clk_32                     => Clk_core, -- 100 MHz Clock
           enable                     => EnableSPNNLNK_i,
           
           dump_mode                  => open,    
           parity_err                 => RxSpnnlnkStat_o.parity_err,
           rx_err                     => RxSpnnlnkStat_o.rx_err,
       
           -- input SpiNNaker link interface
           data_2of7_from_spinnaker   => data_2of7_from_spinnaker_i, 
           ack_to_spinnaker           => ack_to_spinnaker_o,
       
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
           cmd_start_key              => Spnn_cmd_start_key_i,         -- in  std_logic_vector(31 downto 0);
           cmd_stop_key               => Spnn_cmd_stop_key_i,          -- in  std_logic_vector(31 downto 0);
           cmd_start                  => Spnn_cmd_start_o,             -- out std_logic;
           cmd_stop                   => Spnn_cmd_stop_o,              -- out std_logic;
           tx_data_mask               => (others => '0'),              -- in  std_logic_vector(31 downto 0);
           rx_data_mask               => Spnn_rx_mask_i,               -- in  std_logic_vector(31 downto 0);
           
           -- Controls
           dump_off                   => '0',                          -- in  std_logic;
           dump_on                    => '0',                          -- in  std_logic;

           -- Debug Port                
           dbg_rxstate                => open,
           dbg_txstate                => open,
           dbg_ipkt_vld               => open,
           dbg_ipkt_rdy               => open,
           dbg_opkt_vld               => open,
           dbg_opkt_rdy               => open
               ); 
   
    end generate g_spinnlnk_true;


    --===========================================================
    -- ARBITER amongst all the possible channel
    --===========================================================

    u_rx_arbiter : neuserial_PAER_arbiter
        generic map (
            C_NUM_CHAN         => 4,                  -- natural range 1 to 4;
            C_ODATA_WIDTH      => C_OUTPUT_DSIZE      -- natural
        )
        port map (
            Clk                => Clk_core,           -- in  std_logic;
            nRst               => nRst,               -- in  std_logic;

            --ArbCfg_i           =>                     -- in  t_ArbiterCfg;

            SplittedPaerSrc_i  => i_InPaerSrc,        -- in  t_PaerSrc_array(0 to C_NUM_CHAN);
            SplittedPaerDst_o  => i_InPaerDst,        -- out t_PaerDst_array(0 to C_NUM_CHAN);

            PaerData_o         => ToMonDataIn_o,      -- out std_logic_vector(C_ODATA_WIDTH-1 downto 0);
            PaerSrcRdy_o       => ToMonSrcRdy_o,      -- out std_logic;
            PaerDstRdy_i       => ToMonDstRdy_i       -- in  std_logic
        );


end architecture str;
