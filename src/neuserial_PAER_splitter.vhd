library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.aer_pkg.all;

library common_lib;
    use common_lib.utilities_pkg.all;

library datapath_lib;
    use datapath_lib.DPComponents_pkg.all;


entity neuserial_PAER_splitter is
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
end entity neuserial_PAER_splitter;


architecture rtl of neuserial_PAER_splitter is

    signal i_tx_data    : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal i_tx_srcRdy  : std_logic;
    signal i_tx_dstRdy  : std_logic;

begin

    ---------------------------
    -- DATA SIZE CONVERSION
    ---------------------------
    g_DataWidthConv_GT : if (C_INTERNAL_DSIZE > C_IDATA_WIDTH) generate
        -- If the PAER size is greater than InData size
        --   the MSBs sent are set to '0'
        i_tx_data(C_IDATA_WIDTH-1 downto 0)            <= PaerDataIn_i;
        i_tx_data(i_tx_data'high downto C_IDATA_WIDTH) <= (others => '0');
    end generate g_DataWidthConv_GT;

    g_DataWidthConv_EQ : if (C_INTERNAL_DSIZE = C_IDATA_WIDTH) generate
        i_tx_data <= PaerDataIn_i;
    end generate g_DataWidthConv_EQ;

    g_DataWidthConv_LT : if (C_INTERNAL_DSIZE < C_IDATA_WIDTH) generate
        -- If the PAER size is less than InData size
        --   only the LSBs are sent to the serializer (the MSBs written in the FIFO will be discarded)
        i_tx_data <= PaerDataIn_i(i_tx_data'high downto 0);
    end generate g_DataWidthConv_LT;

    i_tx_srcRdy  <= PaerSrcRdy_i;
    PaerDstRdy_o <= i_tx_dstRdy;


    ---------------------------
    -- BYPASS
    ---------------------------
    g_split_bypass : if (C_NUM_CHAN = 1) generate
        SplittedPaerSrc_o(0).idx <= i_tx_data;
        SplittedPaerSrc_o(0).vld <= i_tx_srcRdy;
        i_tx_dstRdy              <= SplittedPaerDst_i(0).rdy;
    end generate g_split_bypass;


    ---------------------------
    -- ACTUAL SPLITTER
    ---------------------------
    g_tx_splitter : if C_NUM_CHAN > 1 generate

        constant c_IDX_WIDTH : natural := f_ceil_log2(C_NUM_CHAN);

        signal ii_rdyVect    : std_logic_vector(C_NUM_CHAN-1 downto 0);

        signal ii_notBusyChan    : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_notBusyChan_t1 : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_newFreeChan    : std_logic_vector(C_NUM_CHAN-1 downto 0);

        type data_array is array (C_NUM_CHAN-1 downto 0) of std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        signal ii_srcVld : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_srcIdx : data_array;

        signal ii_fifoPushVect : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_fifoPop      : std_logic;
        signal ii_fifoEmpty    : std_logic;
        signal ii_fifoIdx      : std_logic_vector(c_IDX_WIDTH-1 downto 0);

        signal ii_mux_sel : natural range 0 to C_NUM_CHAN-1;
        signal ii_mux_vld : std_logic;


    begin

        p_aggregate_ch : process (SplittedPaerDst_i, ii_srcVld, ii_srcIdx, ChEn_i)
        begin
            for i in 0 to C_NUM_CHAN-1 loop
                ii_rdyVect(i) <= SplittedPaerDst_i(i).rdy and ChEn_i(i);
                SplittedPaerSrc_o(i).vld <= ii_srcVld(i);
                SplittedPaerSrc_o(i).idx <= ii_srcIdx(i);
            end loop;
        end process p_aggregate_ch;


        -- Channel free detection: detect a new freeing of each channel
        ii_notBusyChan <= ii_rdyVect and not ii_srcVld;

        p_freeChan : process (Clk)
        begin
            if (rising_edge(Clk)) then
                if (nRst = '0') then
                    ii_notBusyChan_t1 <= (others => '0');
                else
                    ii_notBusyChan_t1 <= ii_notBusyChan;
                end if;
            end if;
        end process p_freeChan;

        ii_newFreeChan <= f_VectPosedgeDetect(ii_notBusyChan, ii_notBusyChan_t1);


        -- FIFO of all the free channels: a channel is pushed into the fifo when it becomes
        -- ready to serve a request, but no request is issued to it. The free channels are
        -- popped from the list when a transaction is completed on the merged bus

        ii_fifoPushVect <= ii_newFreeChan;
        ii_fifoPop <= i_tx_srcRdy and i_tx_dstRdy and not ii_fifoEmpty;


        u_chanFree_fifo : req_fifo
            generic map (
                C_DATA_WIDTH => C_NUM_CHAN,         -- Number of input request lines
                C_IDX_WIDTH  => c_IDX_WIDTH,        -- Width of the index bus in output (should be at least log2(C_DATA_WIDTH)
                C_FIFO_DEPTH => C_NUM_CHAN          -- Number of cells of the FIFO
            )
            port map (
                Clk          => Clk,                -- in  std_logic;
                nRst         => nRst,               -- in  std_logic;
                PreFill_i    => '0',                -- in  std_logic;
                Push_i       => ii_fifoPushVect,    -- in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
                Pop_i        => ii_fifoPop,         -- in  std_logic;
                Idx_o        => ii_fifoIdx,         -- out std_logic_vector(C_IDX_WIDTH-1 downto 0);
                Empty_o      => ii_fifoEmpty,       -- out std_logic;
                Full_o       => open,               -- out std_logic;
                Underflow_o  => open,               -- out std_logic;
                Overflow_o   => open                -- out std_logic
            );



        ii_mux_sel <= f_PriorityEncoder(ii_rdyVect) when ii_fifoEmpty = '1' else to_integer(unsigned(ii_fifoIdx));
        ii_mux_vld <= f_OR_reduction(ii_rdyVect)    when ii_fifoEmpty = '1' else '1';


        p_demux_rdy : process (ii_mux_vld, ii_mux_sel, i_tx_srcRdy, i_tx_data)
        begin
            for i in 0 to C_NUM_CHAN-1 loop
                if (ii_mux_vld = '1' and ii_mux_sel = i) then
                    ii_srcVld(i)             <= i_tx_srcRdy;
                    --SplittedPaerSrc_o(i).idx <= i_tx_data;
                    ii_srcIdx(i)             <= i_tx_data;
                else
                    ii_srcVld(i)             <= '0';
                    --SplittedPaerSrc_o(i).idx <= (others => '0');
                    ii_srcIdx(i)             <= (others => '0');
                end if;
            end loop;
        end process p_demux_rdy;

        i_tx_dstRdy <= SplittedPaerDst_i(ii_mux_sel).rdy when ii_mux_vld = '1' else '0';


    end generate g_tx_splitter;


end architecture rtl;

