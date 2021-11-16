------------------------------------------------------------------------
-- Package DPComponents_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of components of the datapath
--
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;


package DPComponents_pkg is

    component AsyncStabilizer is
        generic (
            synchronizer      : boolean  := true;
            stabilizer_cycles : positive := 2
        );
        port (
            ClkxCI      : in  std_logic;
            RstxRBI     : in  std_logic;
            --
            RstValuexDI : in  std_logic;
            --
            InputxAI    : in  std_logic;
            OutputxDO   : out std_logic
        );
    end component AsyncStabilizer;

    
    component RegisterArray1 is
        generic (
            depth : natural  := 1
        );
        port (
            ClkxCI        : in  std_logic;
            RstxRBI       : in  std_logic;
            --
            ResetValuexDI : in  std_logic;
            --
            InputxDI      : in  std_logic;
            OutputxDO     : out std_logic
        );
    end component RegisterArray1;


    component ShiftRegFifo is
        generic (
            width           : positive;
            depth           : positive;
            full_fifo_reset : boolean := false;
            errorchecking   : boolean := true
        );
        port (
            ClockxCI        : in  std_logic;
            ResetxRBI       : in  std_logic;
            --
            InputxDI        : in  std_logic_vector(width-1 downto 0);
            WritexSI        : in  std_logic;
            AlmostFullxSO   : out std_logic;
            FullxSO         : out std_logic;
            OverflowxSO     : out std_logic;
            --
            OutputxDO       : out std_logic_vector(width-1 downto 0);
            ReadxSI         : in  std_logic;
            AlmostEmptyxSO  : out std_logic;
            EmptyxSO        : out std_logic;
            UnderflowxSO    : out std_logic;
            --
            LevelxDO        : out natural range 0 to depth
        );
    end component ShiftRegFifo;

    
    component ShiftRegFifoRROut is
        generic (
            width           : positive;
            depth           : positive := 4;
            full_fifo_reset : boolean  := true
        );
        port (
            ClockxCI        : in  std_logic;
            ResetxRBI       : in  std_logic;
            --              
            InpDataxDI      : in  std_logic_vector(width-1 downto 0);
            InpWritexSI     : in  std_logic;
            --              
            OutDataxDO      : out std_logic_vector(width-1 downto 0);
            OutSrcRdyxSO    : out std_logic;
            OutDstRdyxSI    : in  std_logic;
            --              
            EmptyxSO        : out std_logic;
            AlmostEmptyxSO  : out std_logic;
            AlmostFullxSO   : out std_logic;
            FullxSO         : out std_logic;
            OverflowxSO     : out std_logic
        );
    end component ShiftRegFifoRROut;


    component ShiftRegFifoRRInp is
        generic (
            width           : positive;
            depth           : positive := 4;
            full_fifo_reset : boolean  := false
        );

        port (
            ClockxCI       : in  std_logic;
            ResetxRBI      : in  std_logic;
            --
            InpDataxDI     : in  std_logic_vector(width-1 downto 0);
            InpSrcRdyxSI   : in  std_logic;
            InpDstRdyxSO   : out std_logic;
            --
            OutDataxDO     : out std_logic_vector(width-1 downto 0);
            OutReadxSI     : in  std_logic;
            --
            EmptyxSO       : out std_logic;
            AlmostEmptyxSO : out std_logic;
            AlmostFullxSO  : out std_logic;
            FullxSO        : out std_logic;
            UnderflowxSO   : out std_logic
        );
    end component ShiftRegFifoRRInp;


    component SimplePAERInputRRv2 is
        generic (
            paer_width               : positive := 16;
            internal_width           : positive := 32;
            --data_on_req_release      : boolean  := false;
            input_fifo_depth         : positive := 1
        );
        port (
            -- clk rst
            ClkxCI                   : in  std_logic;
            RstxRBI                  : in  std_logic;
            EnableIp                 : in  std_logic;
            FlushFifo                : in  std_logic;
            IgnoreFifoFull_i         : in  std_logic;
            aux_channel              : in  std_logic;


            -- parallel AER
            AerReqxAI                : in  std_logic;
            AerAckxSO                : out std_logic;
            AerDataxADI              : in  std_logic_vector(paer_width-1 downto 0);

            -- configuration
            AerHighBitsxDI           : in  std_logic_vector(internal_width-1-paer_width downto 0);
            --AerReqActiveLevelxDI     : in  std_logic;
            --AerAckActiveLevelxDI     : in  std_logic;
            CfgAckSetDelay_i         : in  std_logic_vector(7 downto 0);
            CfgSampleDelay_i         : in  std_logic_vector(7 downto 0);
            CfgAckRelDelay_i         : in  std_logic_vector(7 downto 0);
            -- output
            OutDataxDO               : out std_logic_vector(internal_width-1 downto 0);
            OutSrcRdyxSO             : out std_logic;
            OutDstRdyxSI             : in  std_logic;
            -- Fifo Full signal
            FifoFullxSO              : out std_logic;
            -- dbg
            dbg_dataOk               : out std_logic
        );
    end component SimplePAERInputRRv2;


    component SimplePAEROutputRR is
        generic (
            paer_width        : positive := 16;
            internal_width    : positive := 32;
            --ack_stable_cycles : natural  := 2;
            --req_delay_cycles  : natural  := 4;
            output_fifo_depth : positive := 1
        );
        port (
            -- clk rst
            ClkxCI  : in std_logic;
            RstxRBI : in std_logic;

            -- parallel AER 
            AerAckxAI  : in  std_logic;
            AerReqxSO  : out std_logic;
            AerDataxDO : out std_logic_vector(paer_width-1 downto 0);

            -- configuration
            AerReqActiveLevelxDI : in std_logic;
            AerAckActiveLevelxDI : in std_logic;

            -- output
            InpDataxDI   : in  std_logic_vector(internal_width-1 downto 0);
            InpSrcRdyxSI : in  std_logic;
            InpDstRdyxSO : out std_logic
        );
    end component SimplePAEROutputRR;


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

    
    component neuserial_PAER_arbiter is
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
    end component neuserial_PAER_arbiter;

    
    component neuserial_PAER_splitter is
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
    end component neuserial_PAER_splitter;


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

    
    component hssaer_paer_tx_wrapper is
        generic (
            dsize       : integer;
            int_dsize   : integer
        );
        port (
            nrst        : in  std_logic;
            clkp        : in  std_logic;
            clkn        : in  std_logic;
            keep_alive  : in  std_logic;

            ae          : in  std_logic_vector(int_dsize-1 downto 0);
            src_rdy     : in  std_logic;
            dst_rdy     : out std_logic;

            tx          : out std_logic;

            run         : out std_logic;
            last        : out std_logic
        );
    end component hssaer_paer_tx_wrapper;

    
    component hssaer_paer_rx_wrapper is
        generic (
            dsize       : integer;
            int_dsize   : integer
        );
        port (
            nrst        : in  std_logic;
            lsclkp      : in  std_logic;
            lsclkn      : in  std_logic;
            hsclkp      : in  std_logic;
            hsclkn      : in  std_logic;

            rx          : in  std_logic;

            ae          : out std_logic_vector(int_dsize-1 downto 0);
            src_rdy     : out std_logic;
            dst_rdy     : in  std_logic;

            higher_bits : in  std_logic_vector(int_dsize-1 downto dsize);
            err_ko      : out std_logic;
            err_rx      : out std_logic;
            err_to      : out std_logic;
            err_of      : out std_logic;
            int         : out std_logic;
            run         : out std_logic;

            aux_channel : in  std_logic
        );
    end component hssaer_paer_rx_wrapper;


    component SYNC_FIFO_32_16_ZYNQ
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


    component SYNC_FIFO_32_16_ZYNQUPLUS
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
    
    
end package DPComponents_pkg;



