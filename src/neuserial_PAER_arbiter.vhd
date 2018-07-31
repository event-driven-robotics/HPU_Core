library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.aer_pkg.all;

library common_lib;
    use common_lib.utilities_pkg.all;

library datapath_lib;
    use datapath_lib.DPComponents_pkg.all;


entity neuserial_PAER_arbiter is
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
end entity neuserial_PAER_arbiter;


architecture rtl of neuserial_PAER_arbiter is

    signal i_rx_data    : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    signal i_rx_srcRdy  : std_logic;
    signal i_rx_dstRdy  : std_logic;
    
begin

    ---------------------------
    -- DATA SIZE CONVERSION
    ---------------------------
    g_DataWidthConv_GT : if (C_INTERNAL_DSIZE > C_ODATA_WIDTH) generate
        -- If the PAER size is greater than OutData size
        --   only the C_ODATA_WIDTH LSBs received are monitored (the MSBs will be discarded)
        PaerData_o <= i_rx_data(C_ODATA_WIDTH-1 downto 0);
    end generate g_DataWidthConv_GT;

    g_DataWidthConv_EQ : if (C_INTERNAL_DSIZE = C_ODATA_WIDTH) generate
        PaerData_o <= i_rx_data;
    end generate g_DataWidthConv_EQ;

    g_DataWidthConv_LT : if (C_INTERNAL_DSIZE < C_ODATA_WIDTH) generate
        -- If the PAER size is less than OutData size
        --   the MSBits sent to the monitor are always set to '0'
        PaerData_o(i_rx_data'high  downto 0)                <= i_rx_data;
        PaerData_o(C_ODATA_WIDTH-1 downto i_rx_data'high+1) <= (others => '0');
    end generate g_DataWidthConv_LT;

    PaerSrcRdy_o <= i_rx_srcRdy;
    i_rx_dstRdy  <= PaerDstRdy_i;


    ---------------------------
    -- BYPASS
    ---------------------------
    g_arb_bypass : if (C_NUM_CHAN = 1) generate
        i_rx_data                <= SplittedPaerSrc_i(0).idx;
        i_rx_srcRdy              <= SplittedPaerSrc_i(0).vld;
        SplittedPaerDst_o(0).rdy <= i_rx_dstRdy;
    end generate g_arb_bypass;


    ---------------------------
    -- ACTUAL ARBITER
    ---------------------------
    g_rx_arbiter : if C_NUM_CHAN > 1 generate

        constant c_IDX_WIDTH : natural := f_ceil_log2(C_NUM_CHAN);

        signal ii_reqVect    : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_notServedReq    : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_notServedReq_t1 : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_newPendingReq   : std_logic_vector(C_NUM_CHAN-1 downto 0);

        signal ii_dstRdy : std_logic_vector(C_NUM_CHAN-1 downto 0);
        
        signal ii_fifoPushVect : std_logic_vector(C_NUM_CHAN-1 downto 0);
        signal ii_fifoPop      : std_logic;
        signal ii_fifoEmpty    : std_logic;
        signal ii_fifoIdx      : std_logic_vector(c_IDX_WIDTH-1 downto 0);
        
        signal ii_mux_sel : natural range 0 to C_NUM_CHAN-1;

    
    begin

        p_aggregate_ch : process (SplittedPaerSrc_i, ii_dstRdy)
        begin
            for i in 0 to C_NUM_CHAN-1 loop
                ii_reqVect(i) <= SplittedPaerSrc_i(i).vld;
                SplittedPaerDst_o(i).rdy <= ii_dstRdy(i);
            end loop;
        end process p_aggregate_ch;


        -- Channel requests pending detection: detect a new pending request incoming on each channel
        ii_notServedReq <= ii_reqVect and not ii_dstRdy;
        p_pending_req : process (Clk)
        begin
            if (rising_edge(Clk)) then
                if (nRst = '0') then
                    ii_notServedReq_t1 <= (others => '0');
                else
                    ii_notServedReq_t1 <= ii_notServedReq;
                end if;
            end if;
        end process p_pending_req;
        
        ii_newPendingReq <= f_VectPosedgeDetect(ii_notServedReq, ii_notServedReq_t1);
        

        -- FIFO of all the pending channel requests: a request is pushed into the fifo when
        -- it was not served as soon as it came. The requests are popped when a transaction
        -- is completed on the merged bus

        ii_fifoPushVect <= ii_newPendingReq;
        ii_fifoPop <= i_rx_srcRdy and i_rx_dstRdy and not ii_fifoEmpty;

        
        u_req_fifo : req_fifo
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



        ii_mux_sel <= f_PriorityEncoder(ii_reqVect) when ii_fifoEmpty = '1' else to_integer(unsigned(ii_fifoIdx));

        
        p_demux_rdy : process (ii_mux_sel, i_rx_dstRdy)
        begin
            ii_dstRdy <= (others => '0');
            for i in 0 to C_NUM_CHAN-1 loop
                if (ii_mux_sel = i) then
                    ii_dstRdy(i) <= i_rx_dstRdy;
                end if;
            end loop;
        end process p_demux_rdy;

        i_rx_data   <= SplittedPaerSrc_i(ii_mux_sel).idx;
        i_rx_srcRdy <= SplittedPaerSrc_i(ii_mux_sel).vld;

    end generate g_rx_arbiter;


end architecture rtl;