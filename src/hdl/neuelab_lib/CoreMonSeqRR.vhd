-------------------------------------------------------------------------------
-- MonSeqRR
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    USE ieee.numeric_std.ALL;

-- pragma synthesis_off
-- the following are to write log file
library std;
    use std.textio.all;
    use ieee.std_logic_textio.all;
-- pragma synthesis_on

library neuelab_lib;
    use neuelab_lib.NEComponents_pkg.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;
    use HPU_lib.HPUComponents_pkg.all;

--****************************
--   PORT DECLARATION
--****************************

entity CoreMonSeqRR is
    generic (
        C_FAMILY                              : string := "zynq"; -- "zynq", "zynquplus" 
        --
        C_PAER_DSIZE                         : integer;
        TestEnableSequencerNoWait            : boolean;
        TestEnableSequencerToMonitorLoopback : boolean;
        EnableMonitorControlsSequencerToo    : boolean
    );
    port (
        ---------------------------------------------------------------------------
        -- clock and reset
        CoreClk_i               : in  std_logic;
        AxisClk_i               : in  std_logic;
        --
        Reset_n_CoreClk_i       : in  std_logic;
        Reset_n_AxisClk_i       : in  std_logic;
        --
        FlushRXFifos_i          : in  std_logic;
        FlushTXFifos_i          : in  std_logic;
        ---------------------------------------------------------------------------
        -- controls and settings
        -- ChipType_i         : in  std_logic;
        DmaLength_i             : in  std_logic_vector(15 downto 0);
        OnlyEvents_i            : in  std_logic;
        --
        ---------------------------------------------------------------------------
        -- Enable per timing
        Timing_i                : in  time_tick;
        --
        ---------------------------------------------------------------------------
        -- Input to Monitor     
        MonInAddr_i             : in  std_logic_vector(31 downto 0);
        MonInSrcRdy_i           : in  std_logic;
        MonInDstRdy_o           : out std_logic;
        --                      
        -- Output from Sequencer
        SeqOutAddr_o            : out std_logic_vector(31 downto 0);
        SeqOutSrcRdy_o          : out std_logic;
        SeqOutDstRdy_i          : in  std_logic;
        --
        ---------------------------------------------------------------------------
        -- Time stamper
        CleanTimer_i            : in  std_logic;
        WrapDetected_o          : out std_logic;
        FullTimestamp_i         : in  std_logic;  
        --                      
        EnableMonitor_i         : in  std_logic;
        CoreReady_i             : in  std_logic;
        ---------------------------------------------------------------------------
        -- TX Timestamp
        TxTSMode_i              : in  std_logic_vector(1 downto 0);
        TxTSTimeoutSel_i        : in  std_logic_vector(3 downto 0);
        TxTSRetrigCmd_i         : in  std_logic;
        TxTSRearmCmd_i          : in  std_logic;
        TxTSRetrigStatus_o      : out std_logic;
        TxTSTimeoutCounts_o     : out std_logic;
        TxTSMaskSel_i           : in  std_logic_vector(1 downto 0);
        --
        ---------------------------------------------------------------------------
        -- FIFO -> Core
        FifoCoreDat_o           : out std_logic_vector(31 downto 0);
        FifoCoreRead_i          : in  std_logic;
        FifoCoreEmpty_o         : out std_logic;
        FifoCoreAlmostEmpty_o   : out std_logic;
        FifoCoreLastData_o      : out std_logic;
        FifoCoreFull_o          : out std_logic;
        FifoCoreNumData_o       : out std_logic_vector(10 downto 0);
        --
        -- Core -> FIFO
        CoreFifoDat_i           : in  std_logic_vector(31 downto 0);
        CoreFifoWrite_i         : in  std_logic;
        CoreFifoFull_o          : out std_logic;
        CoreFifoAlmostFull_o    : out std_logic;
        CoreFifoEmpty_o         : out std_logic    
    );
end entity CoreMonSeqRR;


--****************************
--   IMPLEMENTATION
--****************************

architecture str of CoreMonSeqRR is

-----------------------------------------------------------------------------
-- signals
-----------------------------------------------------------------------------

-- CoreReady / EnableMonitor
signal EnableSequencer : std_logic;

-- Timestamp Counter
signal EnableTimestampCounter_RX  : std_logic;
signal EnableTimestampCounter_RXB : std_logic;
signal EnableTimestampCounter_TX  : std_logic;
signal EnableTimestampCounter_TXB : std_logic;    
signal Timestamp_RX            : std_logic_vector(31 downto 0);
signal Timestamp_TX            : std_logic_vector(31 downto 0);
signal ShortTimestamp_TX       : std_logic_vector(31 downto 0);
signal LoadTimer               : std_logic;
signal LoadValue               : std_logic_vector(31 downto 0);

-- Monitor -> Core
signal MonOutAddrEvt     : std_logic_vector(63 downto 0);
signal LiEnMonOutAddrEvt : std_logic_vector(63 downto 0);
signal MonOutWrite       : std_logic;
signal MonOutFull        : std_logic;

-- Core -> Sequencer
signal SeqInAddrEvt     : std_logic_vector(63 downto 0);
signal LiEnSeqInAddrEvt : std_logic_vector(63 downto 0);
signal SeqInRead        : std_logic;
signal SeqInEmpty       : std_logic;

-- Sequencer -> Config Logic
--signal ConfigAddr : std_logic_vector(31 downto 0);
--signal ConfigReq  : std_logic;
--signal ConfigAck  : std_logic;

-- Monitor Input
signal MonInAddr                   : std_logic_vector(31 downto 0);
signal MonInSrcRdy, MonInDstRdy : std_logic;

-- Sequencer Output
signal SeqOutAddr                    : std_logic_vector(31 downto 0);
signal SeqOutSrcRdy, SeqOutDstRdy : std_logic;

-- Reset high signal for FIFOs
signal ResetRX            : std_logic;
signal ResetTX            : std_logic;
signal FlushRXFifos_sr    : std_logic_vector(15 downto 0);
signal FlushTXFifos_sr    : std_logic_vector(15 downto 0);

signal TxFifoWrEn         : std_logic;
signal TxFifoRdEn         : std_logic;
signal TxFifoEmpty        : std_logic;
signal TxFifoFull         : std_logic;
signal TxFifoAlmostFull   : std_logic;
signal TxWrDataCount      : std_logic_vector(11 downto 0);
signal TxRdDataCount      : std_logic_vector(10 downto 0);

signal RxFifoWrEn         : std_logic;
signal RxFifoRdEn         : std_logic;
signal RxFifoEmpty        : std_logic;
signal RxFifoAlmostempty  : std_logic;
signal RxFifoFull         : std_logic;
signal RxFifoAlmostFull   : std_logic;
signal RxFifoOverflow     : std_logic;
signal RxFifoUnderflow    : std_logic;
signal RxFifoWrDataCount  : std_logic_vector(10 downto 0);
signal RxFifoRdDataCount  : std_logic_vector(10 downto 0);

--signal i_BGMonitorSel_xAS : std_logic;
--signal i_BGAddrSel_xAS    : std_logic;
--signal i_BGMonEn_xAS      : std_logic;
--signal i_BGBiasOSel_xAS   : std_logic;
--signal i_BGLatch_xASB     : std_logic;
--signal i_BGClk_xAS        : std_logic;
--signal i_BGBitIn_xAD      : std_logic;

signal enableFifoWriting  : std_logic;
-- signal fifoWrDataCount    : std_logic_vector(10 downto 0);
signal i_fifoCoreDat      : std_logic_vector(63 downto 0);
signal dataRead           : std_logic;
signal effectiveRdEn      : std_logic;


signal i_FifoCoreEmpty_o : std_logic;
signal i_FifoCoreAlmostEmpty_o : std_logic;
signal MSB                 : std_logic;

-- pragma synthesis_off
file logfile_ptr   : text open WRITE_MODE is "monitor_activity.csv";
-- pragma synthesis_on

signal infifo_wr_rst_busy : std_logic;
signal infifo_rd_rst_busy : std_logic;

signal rxfifo_wr_rst_busy : std_logic;
signal rxfifo_rd_rst_busy : std_logic;

signal txfifo_wr_rst_busy : std_logic;
signal txfifo_rd_rst_busy : std_logic;

-----------------------------------------------------------------------------
-- Debug attributes

attribute mark_debug : string;
-- INFIFO



begin

    -----------------------------------------------------------------------------
    -- special reset for Fifo
    -----------------------------------------------------------------------------
    p_ResetForFifo : process (CoreClk_i, Reset_n_CoreClk_i) is
        begin
        if (Reset_n_CoreClk_i = '0') then
            FlushRXFifos_sr <= (others => '1');
            FlushTXFifos_sr <= (others => '1');
        end if;
        if (rising_edge(CoreClk_i)) then
        
            if (FlushRXFifos_i = '1') then
                FlushRXFifos_sr <= (others => '1');
            else 
                FlushRXFifos_sr <= FlushRXFifos_sr(14 downto 0) & '0';
            end if;

            if (FlushTXFifos_i = '1') then
                FlushTXFifos_sr <= (others => '1');
            else 
                FlushTXFifos_sr <= FlushTXFifos_sr(14 downto 0) & '0';
            end if;
            
        end if;
    end process p_ResetForFifo;
    
    -- ResetRX <=  not(ResetBI) or FlushRXFifos_i;
    -- ResetTX <=  not(ResetBI) or FlushTXFifos_i;

    ResetRX <=  FlushRXFifos_sr(15);
    ResetTX <=  FlushTXFifos_sr(15);

    -----------------------------------------------------------------------------
    -- CoreReady_i, EnableMonitor_i, EnableTimestampCounter_RX, EnableTimestampCounter_TX
    -----------------------------------------------------------------------------

    -- timestamp counter -- run timestamp counter only if MonEn is active or
    -- the sequencer has pending data. otherwise we reset the counter to zero.
    EnableTimestampCounter_RX  <= (EnableMonitor_i and CoreReady_i) or not SeqInEmpty;
    EnableTimestampCounter_RXB <= not EnableTimestampCounter_RX;
    
    -----------------------------------------------------------------------------
    -- enable sequencer controled by monitor:
    g_enseq : if EnableMonitorControlsSequencerToo generate
        EnableSequencer <= EnableMonitor_i;
    end generate g_enseq;
    -----------------------------------------------------------------------------
    -- or not:
    g_no_enseq : if not EnableMonitorControlsSequencerToo generate
        EnableSequencer <= '1';
    end generate g_no_enseq;


  -----------------------------------------------------------------------------
  -- Timestamp, Monitor, Sequencer
  -----------------------------------------------------------------------------


    u_Timestamp_TX : Timestamp
        port map (
            Rst_n_i        => Reset_n_CoreClk_i,
            Clk_i          => CoreClk_i,
            Zero_i         => '0',
            LoadTimer_i    => LoadTimer,
            LoadValue_i    => LoadValue,
            CleanTimer_i   => '0',
            Timestamp_o    => Timestamp_TX
        );
        
    u_Timestamp_RX : Timestamp
        port map (
            Rst_n_i        => Reset_n_CoreClk_i,
            Clk_i          => CoreClk_i,
            Zero_i         => EnableTimestampCounter_RXB,
            LoadTimer_i    => '0',
            LoadValue_i    => (others => '0'),
            CleanTimer_i   => CleanTimer_i,
            Timestamp_o  => Timestamp_RX
        );

    u_TimestampWrapDetector_RX: TimestampWrapDetector
        port map (
            Reset_n_i      => Reset_n_CoreClk_i,
            Clk_i          => CoreClk_i,
            MSB_i          => MSB, 
            WrapDetected_o => WrapDetected_o
        );
        
    MSB <= Timestamp_RX(23) when FullTimestamp_i='0' else
           Timestamp_RX(31);

    u_MonitorRR : MonitorRR
        port map (
            Rst_n_i         => Reset_n_CoreClk_i,
            Clk_i           => CoreClk_i,
            FullTimestamp_i => FullTimestamp_i,
            Timestamp_i     => Timestamp_RX,
            MonEn_i         => EnableMonitor_i,
            --
            InAddr_i        => MonInAddr,
            InSrcRdy_i      => MonInSrcRdy,
            InDstRdy_o      => MonInDstRdy,
            --
            OutAddrEvt_o    => MonOutAddrEvt,
            OutWrite_o      => MonOutWrite,
            OutFull_i       => MonOutFull
        );

ShortTimestamp_TX <= x"0000" & Timestamp_TX(15 downto 0);


    u_AEXSsequencerRR : AEXSsequencerRR
        port map (
            Rst_n_i              => Reset_n_CoreClk_i,
            Clk_i                => CoreClk_i,
            Enable_i             => EnableSequencer,
            --
            En100us_i            => Timing_i.en100us,
            -- 
            TSMode_i             => TxTSMode_i,
            TSTimeoutSel_i       => TxTSTimeoutSel_i,
            TSMaskSel_i          => TxTSMaskSel_i,
            --
            Timestamp_i          => Timestamp_TX,  
            LoadTimer_o          => LoadTimer,        
            LoadValue_o          => LoadValue,        
            TxTSRetrigCmd_i      => TxTSRetrigCmd_i,   
            TxTSRearmCmd_i       => TxTSRearmCmd_i,
            TxTSRetrigStatus_o   => TxTSRetrigStatus_o,
            TxTSTimeoutCounts_o  => TxTSTimeoutCounts_o,  
            --
            InAddrEvt_i          => SeqInAddrEvt,
            InRead_o             => SeqInRead,
            InEmpty_i            => SeqInEmpty,
            --
            OutAddr_o            => SeqOutAddr,
            OutSrcRdy_o          => SeqOutSrcRdy,
            OutDstRdy_i          => SeqOutDstRdy
            --
            --ConfigAddr_o => ConfigAddr,
            --ConfigReq_o  => ConfigReq,
            --ConfigAck_i  => ConfigAck
        );


    -----------------------------------------------------------------------------
    -- monitor output / sequencer input wiring incl loopback test
    -----------------------------------------------------------------------------

    -- normal operation:
    g_loopback_disabled : if not TestEnableSequencerToMonitorLoopback generate
        MonInAddr      <= MonInAddr_i;
        MonInSrcRdy    <= MonInSrcRdy_i;
        MonInDstRdy_o  <= MonInDstRdy;
        --
        SeqOutAddr_o   <= SeqOutAddr;
        SeqOutSrcRdy_o <= SeqOutSrcRdy;
        SeqOutDstRdy   <= SeqOutDstRdy_i;
    end generate g_loopback_disabled;

    -- loopback test enabled:
    g_loopback_enabled : if TestEnableSequencerToMonitorLoopback generate
        -- disable sequencer output port & sink on monitor input port:
        SeqOutAddr_o   <= (others => '0');
        SeqOutSrcRdy_o <= '0';
        MonInDstRdy_o  <= '1';
        -- create loop:
        MonInAddr      <= SeqOutAddr;
        MonInSrcRdy    <= SeqOutSrcRdy;
        SeqOutDstRdy   <= MonInDstRdy;
    end generate g_loopback_enabled;


    -----------------------------------------------------------------------------
    -- bias Sequencer
    -----------------------------------------------------------------------------

    --u_BiasSerializer : BiasSerializer
    --    port map (
    --        resetn            => ResetBI,
    --        clk               => CoreClk_i,
    --        chip_type         => ChipType_i,
    --        Data              => ConfigAddr,
    --        Req               => ConfigReq,
    --        Ack               => ConfigAck,
    --        prescaler_value   => PrescalerValueI,
    --        biasfinished      => BiasFinished_o,
    --        ClockLow          => ClockLowI,
    --        LatchTime         => LatchTimeI,
    --        SetupHold         => SetupHoldI,
    --        BGMonitorSel_xASO => i_BGMonitorSel_xAS,
    --        BGAddrSel_xASO    => i_BGAddrSel_xAS,
    --        BGMonEn_xASO      => i_BGMonEn_xAS,
    --        BGBiasOSel_xASO   => i_BGBiasOSel_xAS,
    --        BGLatch_xASBO     => i_BGLatch_xASB,
    --        BGClk_xASO        => i_BGClk_xAS,
    --        BGBitIn_xADO      => i_BGBitIn_xAD,
    --        BBitout           => '0'
    --    );
    --
    --BiasProgPins_o <= '0' & i_BGMonitorSel_xAS & i_BGAddrSel_xAS & i_BGMonEn_xAS & i_BGBiasOSel_xAS & i_BGLatch_xASB & i_BGClk_xAS & i_BGBitIn_xAD;


    -----------------------------------------------------------------------------
    -- OUT - little-endian conversion and fifo
    -----------------------------------------------------------------------------

    -- timestamp
    SeqInAddrEvt(39 downto 32) <= LiEnSeqInAddrEvt(39 downto 32);
    SeqInAddrEvt(47 downto 40) <= LiEnSeqInAddrEvt(47 downto 40);
    SeqInAddrEvt(55 downto 48) <= LiEnSeqInAddrEvt(55 downto 48);
    SeqInAddrEvt(63 downto 56) <= LiEnSeqInAddrEvt(63 downto 56);
    -- address
    SeqInAddrEvt( 7 downto  0) <= LiEnSeqInAddrEvt( 7 downto  0);
    SeqInAddrEvt(15 downto  8) <= LiEnSeqInAddrEvt(15 downto  8);
    SeqInAddrEvt(23 downto 16) <= LiEnSeqInAddrEvt(23 downto 16);
    SeqInAddrEvt(31 downto 24) <= LiEnSeqInAddrEvt(31 downto 24);
    --
    
OUTFIFO_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
    u_OUTFIFO_32_2048_64_1024 : OUTFIFO_32_2048_64_1024_ZYNQ
        port map (
            rst          => ResetTX,    -- high-active reset
            wr_clk       => CoreClk_i,
            rd_clk       => CoreClk_i,
            din          => CoreFifoDat_i,
            wr_en        => CoreFifoWrite_i,
            rd_en        => SeqInRead,
            dout         => LiEnSeqInAddrEvt,
            full         => CoreFifoFull_o,
            almost_full  => CoreFifoAlmostFull_o,
            overflow     => open,
            empty        => SeqInEmpty,
            almost_empty => open,
            underflow    => open
        );

end generate;

OUTFIFO_FOR_ZYNQUPLUS : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin

  TxFifoWrEn              <= CoreFifoWrite_i and not txfifo_wr_rst_busy;
  CoreFifoFull_o          <= TxFifoFull or txfifo_wr_rst_busy;
  CoreFifoAlmostFull_o    <= TxFifoAlmostFull or txfifo_wr_rst_busy;  
  
  TxFifoRdEn              <= SeqInRead and not txfifo_rd_rst_busy;
  SeqInEmpty              <= TxFifoEmpty or txfifo_rd_rst_busy;



  TXFIFO_HPU_ZYNQUPLUS_i : TXFIFO_HPU_ZYNQUPLUS
    PORT MAP (
      rst           => ResetTX,
      wr_clk        => AxisClk_i,
      rd_clk        => CoreClk_i,
      din           => CoreFifoDat_i,
      wr_en         => TxFifoWrEn,
      rd_en         => TxFifoRdEn,
      dout          => LiEnSeqInAddrEvt,
      full          => TxFifoFull,
      almost_full   => TxFifoAlmostFull,
      overflow      => open,
      empty         => TxFifoEmpty,
      almost_empty  => open,
      underflow     => open,
      rd_data_count => open,
      wr_data_count => open,      
      wr_rst_busy   => txfifo_wr_rst_busy,
      rd_rst_busy   => txfifo_rd_rst_busy
    );
   
--    u_OUTFIFO_32_2048_64_1024 : OUTFIFO_32_2048_64_1024_ZYNQUPLUS
--        port map (
--            rst          => ResetTX,    -- high-active reset
--            wr_clk       => CoreClk_i,
--            rd_clk       => CoreClk_i,
--            din          => CoreFifoDatI,
--            wr_en        => CoreFifoWrite_i,
--            rd_en        => SeqInRead,
--            dout         => LiEnSeqInAddrEvt,
--            full         => CoreFifoFull_o,
--            almost_full  => CoreFifoAlmostFull_o,
--            overflow     => open,
--            empty        => SeqInEmpty,
--            almost_empty => open,
--            underflow    => open
--        );

end generate;

    


    CoreFifoEmpty_o <= SeqInEmpty;


    -----------------------------------------------------------------------------
    -- IN - No conversion and fifo
    -----------------------------------------------------------------------------

    -- to computer, timestamp
    LiEnMonOutAddrEvt(39 downto 32) <= MonOutAddrEvt(39 downto 32);
    LiEnMonOutAddrEvt(47 downto 40) <= MonOutAddrEvt(47 downto 40);
    LiEnMonOutAddrEvt(55 downto 48) <= MonOutAddrEvt(55 downto 48);
    LiEnMonOutAddrEvt(63 downto 56) <= MonOutAddrEvt(63 downto 56);
    -- to computer, address
    LiEnMonOutAddrEvt( 7 downto  0) <= MonOutAddrEvt( 7 downto  0);
    LiEnMonOutAddrEvt(15 downto  8) <= MonOutAddrEvt(15 downto  8);
    LiEnMonOutAddrEvt(23 downto 16) <= MonOutAddrEvt(23 downto 16);
    LiEnMonOutAddrEvt(31 downto 24) <= MonOutAddrEvt(31 downto 24);
    --

INFIFO_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
    u_INFIFO_64_1024 : INFIFO_64_1024_ZYNQ
        port map (
            clk          => CoreClk_i,
            srst         => ResetRX,    -- high-active reset
            din          => LiEnMonOutAddrEvt,
            wr_en        => enableFifoWriting,
            rd_en        => effectiveRdEn,
            dout         => i_fifoCoreDat,
            full         => MonOutFull,
            almost_full  => open,
            overflow     => open,
            empty        => i_FifoCoreEmpty_o,
            almost_empty => i_FifoCoreAlmostEmpty_o,
            underflow    => open,
            data_count   => RxFifoWrDataCount
        );

end generate;

INFIFO_FOR_ZYNQUPLUS : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin

  RxFifoWrEn                <= enableFifoWriting and not rxfifo_wr_rst_busy;
  MonOutFull                <= RxFifoFull or rxfifo_wr_rst_busy;
  
  RxFifoRdEn                <= effectiveRdEn and not rxfifo_rd_rst_busy;
  i_FifoCoreEmpty_o         <= RxFifoEmpty or rxfifo_rd_rst_busy;
  i_FifoCoreAlmostEmpty_o   <= RxFifoAlmostEmpty or rxfifo_rd_rst_busy;
  
  RXFIFO_HPU_ZYNQUPLUS_i : RXFIFO_HPU_ZYNQUPLUS
    PORT MAP (
      rst           => ResetRX,
      wr_clk        => CoreClk_i,
      rd_clk        => AxisClk_i,
      din           => LiEnMonOutAddrEvt,
      wr_en         => RxFifoWrEn,
      rd_en         => RxFifoRdEn,
      dout          => i_fifoCoreDat,
      full          => RxFifoFull,
      almost_full   => RxFifoAlmostFull,
      overflow      => RxFifoOverflow,
      empty         => RxFifoEmpty,
      almost_empty  => RxFifoAlmostEmpty,
      underflow     => RxFifoUnderflow,
      rd_data_count => RxFifoRdDataCount,
      wr_data_count => RxFifoWrDataCount,
      wr_rst_busy   => rxfifo_wr_rst_busy,
      rd_rst_busy   => rxfifo_rd_rst_busy
        );
    
--     u_INFIFO_64_1024 : INFIFO_64_1024_ZYNQUPLUS
--         port map (
--             clk          => CoreClk_i,
--             srst         => ResetRX,    -- high-active reset
--             din          => LiEnMonOutAddrEvt,
--             wr_en        => enableFifoWriting,
--             rd_en        => effectiveRdEn,
--             dout         => i_fifoCoreDat,
--             full         => MonOutFull,
--             almost_full  => DBG_almost_full,
--             overflow     => DBG_overflow,
--             empty        => i_FifoCoreEmpty_o,
--             almost_empty => i_FifoCoreAlmostEmpty_o,
--             underflow    => DBG_underflow,
--             data_count   => fifoWrDataCount,
--             wr_rst_busy  => infifo_wr_rst_busy,
--             rd_rst_busy  => infifo_rd_rst_busy
--         );

end generate;


    FifoCoreNumData_o <= RxFifoRdDataCount;
    
    p_ReadDataTimeSel : process (AxisClk_i, Reset_n_AxisClk_i) is
        begin
            if (Reset_n_AxisClk_i = '0') then
                dataRead <= '0';
            elsif (rising_edge(AxisClk_i)) then
                if (OnlyEvents_i = '1') then
                    dataRead <= '1';
                elsif (FifoCoreRead_i = '0') then
                    dataRead <= '0';
                else
                    dataRead <= not(dataRead);
              end if;
            end if;
        end process p_ReadDataTimeSel;

    FifoCoreDat_o      <= i_fifoCoreDat(63 downto 32) when (dataRead = '0') else     -- i.e. Timestamp
                         i_fifoCoreDat(31 downto  0);                                -- i.e. Event
    effectiveRdEn      <=  '0' when (dataRead = '0') else FifoCoreRead_i;

    FifoCoreFull_o     <= MonOutFull;
    FifoCoreLastData_o <= RxFifoAlmostEmpty and not RxFifoEmpty;

    --enableFifoWriting <= MonOutWrite when (MonOutAddrEvt(7 downto 0) >= OutThresholdValI(7 downto 0)) else '0';
    enableFifoWriting <= MonOutWrite;


    -----------------------------------------------------------------------------
    -----------------------------------------------------------------------------

    -- pragma synthesis_off
    p_log_file_writing : process
        variable v_buf_out: line;
    begin
        write(v_buf_out, string'("time,ChipId,IntfId,Address"));
        writeline(logfile_ptr, v_buf_out);
        loop
            wait until (rising_edge(CoreClk_i));
            if (MonOutWrite = '1') then
                write(v_buf_out, now, right, 10); write(v_buf_out, string'(","));
                if (LiEnMonOutAddrEvt(C_PAER_DSIZE) = '1') then
                    write(v_buf_out, string'("R,"));
                else
                    write(v_buf_out, string'("L,"));
                end if;
                 if (LiEnMonOutAddrEvt(C_PAER_DSIZE-1 downto C_PAER_DSIZE-1-3) = "0000") then
                    write(v_buf_out, string'("TD,"));
                else
                    write(v_buf_out, string'("APS,"));
                end if;
               case (LiEnMonOutAddrEvt(C_INTERNAL_DSIZE-1 downto C_INTERNAL_DSIZE-2)) is
                    when "00" => write(v_buf_out, string'("PAER,"));
                    when "01" => write(v_buf_out, string'("SAER,"));
                    when "10" => write(v_buf_out, string'("GTP,"));
                    when others => write(v_buf_out, string'("Unknown"));
                end case;
                hwrite(v_buf_out, LiEnMonOutAddrEvt(C_PAER_DSIZE-1 downto 0));
                write(v_buf_out, string'(", "));
                hwrite(v_buf_out, LiEnMonOutAddrEvt(63 downto 32));
                write(v_buf_out, string'(" ("));
                hwrite(v_buf_out, LiEnMonOutAddrEvt(31 downto 0));
                write(v_buf_out, string'(")"));
                writeline(logfile_ptr, v_buf_out);
            end if;
        end loop;
    end process p_log_file_writing;
    -- pragma synthesis_on


FifoCoreEmpty_o       <= i_FifoCoreEmpty_o;
FifoCoreAlmostEmpty_o <= i_FifoCoreAlmostEmpty_o;




end architecture str;

-------------------------------------------------------------------------------
