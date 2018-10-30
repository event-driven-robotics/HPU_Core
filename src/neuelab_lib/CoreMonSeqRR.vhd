-------------------------------------------------------------------------------
-- MonSeqRR
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

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


--****************************
--   PORT DECLARATION
--****************************

entity CoreMonSeqRR is
    generic (
        C_PAER_DSIZE                         : integer;
        TestEnableSequencerNoWait            : boolean;
        TestEnableSequencerToMonitorLoopback : boolean;
        EnableMonitorControlsSequencerToo    : boolean
    );
    port (
        ---------------------------------------------------------------------------
        -- clock and reset
        Reset_xRBI          : in  std_logic;
        CoreClk_xCI         : in  std_logic;
        FlushFifos_xSI      : in  std_logic;
        --ChipType_xSI        : in  std_logic;
        DmaLength_xDI       : in  std_logic_vector(10 downto 0);
        --
        ---------------------------------------------------------------------------
        -- Input to Monitor
        MonInAddr_xDI       : in  std_logic_vector(31 downto 0);
        MonInSrcRdy_xSI     : in  std_logic;
        MonInDstRdy_xSO     : out std_logic;
        --
        -- Output from Sequencer
        SeqOutAddr_xDO      : out std_logic_vector(31 downto 0);
        SeqOutSrcRdy_xSO    : out std_logic;
        SeqOutDstRdy_xSI    : in  std_logic;
        --
        ---------------------------------------------------------------------------
        -- Time stamper
        CleanTimer_xSI      : in  std_logic;
        WrapDetected_xSO    : out std_logic;
        FullTimestamp_i     : in  std_logic;  
        ---------------------------------------------------------------------------
        --
        EnableMonitor_xSI   : in  std_logic;
        CoreReady_xSI       : in  std_logic;
        --
        -- FIFO -> Core
        FifoCoreDat_xDO         : out std_logic_vector(31 downto 0);
        FifoCoreRead_xSI        : in  std_logic;
        FifoCoreEmpty_xSO       : out std_logic;
        FifoCoreAlmostEmpty_xSO : out std_logic;
        FifoCoreBurstReady_xSO  : out std_logic;
        FifoCoreFull_xSO        : out std_logic;
        FifoCoreNumData_o       : out std_logic_vector(10 downto 0);
        --
        -- Core -> FIFO
        CoreFifoDat_xDI         : in  std_logic_vector(31 downto 0);
        CoreFifoWrite_xSI       : in  std_logic;
        CoreFifoFull_xSO        : out std_logic;
        CoreFifoAlmostFull_xSO  : out std_logic;
        CoreFifoEmpty_xSO       : out std_logic;

        ---------------------------------------------------------------------------
        -- BiasGen Controller Output
        --
        --BiasFinished_xSO        : out std_logic;
        --ClockLow_xDI            : in  natural; -- 1   tick
        --LatchTime_xDI           : in  natural; -- 1   tick
        --SetupHold_xDI           : in  natural; -- 100 tick
        --PrescalerValue_xDI      : in  std_logic_vector(31 downto 0);
        --BiasProgPins_xDO        : out std_logic_vector(7 downto 0);
        ---------------------------------------------------------------------------
          -- Output neurons threshold
        --OutThresholdVal_xDI     : in  std_logic_vector(31 downto 0)

        DBG_din             : out std_logic_vector(63 downto 0);     
        DBG_wr_en           : out std_logic;  
        DBG_rd_en           : out std_logic;     
        DBG_dout            : out std_logic_vector(63 downto 0);          
        DBG_full            : out std_logic;    
        DBG_almost_full     : out std_logic;    
        DBG_overflow        : out std_logic;       
        DBG_empty           : out std_logic;           
        DBG_almost_empty    : out std_logic;    
        DBG_underflow       : out std_logic;     
        DBG_data_count      : out std_logic_vector(10 downto 0);
        DBG_Timestamp_xD    : out std_logic_vector(31 downto 0);
        DBG_MonInAddr_xD    : out std_logic_vector(31 downto 0);
        DBG_MonInSrcRdy_xS  : out std_logic;
        DBG_MonInDstRdy_xS  : out std_logic;
        DBG_RESETFIFO       : out std_logic
    
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
    signal EnableSequencer_xS : std_logic;

    -- Timestamp Counter
    signal EnableTimestampCounter_xS  : std_logic;
    signal EnableTimestampCounter_xSB : std_logic;
    signal Timestamp_xD               : std_logic_vector(31 downto 0);
    signal ShortTimestamp_xD          : std_logic_vector(31 downto 0);

    -- Monitor -> Core
    signal MonOutAddrEvt_xD     : std_logic_vector(63 downto 0);
    signal LiEnMonOutAddrEvt_xD : std_logic_vector(63 downto 0);
    signal MonOutWrite_xS       : std_logic;
    signal MonOutFull_xS        : std_logic;

    -- Core -> Sequencer
    signal SeqInAddrEvt_xD     : std_logic_vector(63 downto 0);
    signal LiEnSeqInAddrEvt_xD : std_logic_vector(63 downto 0);
    signal SeqInRead_xS        : std_logic;
    signal SeqInEmpty_xS       : std_logic;

    -- Sequencer -> Config Logic
    --signal ConfigAddr_xD : std_logic_vector(31 downto 0);
    --signal ConfigReq_xS  : std_logic;
    --signal ConfigAck_xS  : std_logic;

    -- Monitor Input
    signal MonInAddr_xD                   : std_logic_vector(31 downto 0);
    signal MonInSrcRdy_xS, MonInDstRdy_xS : std_logic;

    -- Sequencer Output
    signal SeqOutAddr_xD                    : std_logic_vector(31 downto 0);
    signal SeqOutSrcRdy_xS, SeqOutDstRdy_xS : std_logic;

    -- Reset high signal for FIFOs
    signal Reset_xR  : std_logic;

    --signal i_BGMonitorSel_xAS : std_logic;
    --signal i_BGAddrSel_xAS    : std_logic;
    --signal i_BGMonEn_xAS      : std_logic;
    --signal i_BGBiasOSel_xAS   : std_logic;
    --signal i_BGLatch_xASB     : std_logic;
    --signal i_BGClk_xAS        : std_logic;
    --signal i_BGBitIn_xAD      : std_logic;

    signal enableFifoWriting_xS  : std_logic;
    signal fifoWrDataCount_xD    : std_logic_vector(10 downto 0);
    signal i_fifoCoreDat_xD      : std_logic_vector(63 downto 0);
    signal dataRead_xS           : std_logic;
    signal effectiveRdEn_xS      : std_logic;
    
    
    signal i_FifoCoreEmpty_xSO : std_logic;
    signal i_FifoCoreAlmostEmpty_xSO : std_logic;
    signal MSB                 : std_logic;

    -- pragma synthesis_off
    file logfile_ptr   : text open WRITE_MODE is "monitor_activity.csv";
    -- pragma synthesis_on

    -----------------------------------------------------------------------------
    -- end of declarations
    -----------------------------------------------------------------------------

begin

    -----------------------------------------------------------------------------
    -- special reset for Fifo
    -----------------------------------------------------------------------------
    Reset_xR <=  not(Reset_xRBI) or FlushFifos_xSI;

    -----------------------------------------------------------------------------
    -- CoreReady_xSI, EnableMonitor_xSI, EnableTimestampCounter_xS
    -----------------------------------------------------------------------------

    -- timestamp counter -- run timestamp counter only if MonEn is active or
    -- the sequencer has pending data. otherwise we reset the counter to zero.
    EnableTimestampCounter_xS  <= (EnableMonitor_xSI and CoreReady_xSI) or not SeqInEmpty_xS;
    EnableTimestampCounter_xSB <= not EnableTimestampCounter_xS;

    -----------------------------------------------------------------------------
    -- enable sequencer controled by monitor:
    g_enseq : if EnableMonitorControlsSequencerToo generate
        EnableSequencer_xS <= EnableMonitor_xSI;
    end generate g_enseq;
    -----------------------------------------------------------------------------
    -- or not:
    g_no_enseq : if not EnableMonitorControlsSequencerToo generate
        EnableSequencer_xS <= '1';
    end generate g_no_enseq;


  -----------------------------------------------------------------------------
  -- Timestamp, Monitor, Sequencer
  -----------------------------------------------------------------------------

    u_Timestamp : Timestamp
        port map (
            Rst_xRBI       => Reset_xRBI,
            Clk_xCI        => CoreClk_xCI,
            Zero_xSI       => EnableTimestampCounter_xSB,
            CleanTimer_xSI => CleanTimer_xSI,
            Timestamp_xDO  => Timestamp_xD
        );

    u_TimestampWrapDetector: TimestampWrapDetector
        port map (
            Resetn         => Reset_xRBI,
            Clk            => CoreClk_xCI,
            MSB            => MSB, 
            WrapDetected   => WrapDetected_xSO
        );
        
    MSB <= Timestamp_xD(23) when FullTimestamp_i='0' else
           Timestamp_xD(31);

    u_MonitorRR : MonitorRR
        port map (
            Rst_xRBI       => Reset_xRBI,
            Clk_xCI        => CoreClk_xCI,
            FullTimestamp_i=> FullTimestamp_i,
            Timestamp_xDI  => Timestamp_xD,
            MonEn_xSAI     => EnableMonitor_xSI,
            --
            InAddr_xDI     => MonInAddr_xD,
            InSrcRdy_xSI   => MonInSrcRdy_xS,
            InDstRdy_xSO   => MonInDstRdy_xS,
            --
            OutAddrEvt_xDO => MonOutAddrEvt_xD,
            OutWrite_xSO   => MonOutWrite_xS,
            OutFull_xSI    => MonOutFull_xS
        );

ShortTimestamp_xD <= x"0000" & "000" & Timestamp_xD(12 downto 0);


    u_AEXSsequencerRR : AEXSsequencerRR
        generic map (
            TestEnableSequencerNoWait => TestEnableSequencerNoWait
        )
        port map (
            Rst_xRBI       => Reset_xRBI,
            Clk_xCI        => CoreClk_xCI,
            Enable_xSI     => EnableSequencer_xS,
            TSMode         => "01",
            --
            Timestamp_xDI  => ShortTimestamp_xD, --Timestamp_xD,
            --
            InAddrEvt_xDI  => SeqInAddrEvt_xD,
            InRead_xSO     => SeqInRead_xS,
            InEmpty_xSI    => SeqInEmpty_xS,
            --
            OutAddr_xDO    => SeqOutAddr_xD,
            OutSrcRdy_xSO  => SeqOutSrcRdy_xS,
            OutDstRdy_xSI  => SeqOutDstRdy_xS
            --
            --ConfigAddr_xDO => ConfigAddr_xD,
            --ConfigReq_xSO  => ConfigReq_xS,
            --ConfigAck_xSI  => ConfigAck_xS
        );


    -----------------------------------------------------------------------------
    -- monitor output / sequencer input wiring incl loopback test
    -----------------------------------------------------------------------------

    -- normal operation:
    g_loopback_disabled : if not TestEnableSequencerToMonitorLoopback generate
        MonInAddr_xD     <= MonInAddr_xDI;
        MonInSrcRdy_xS   <= MonInSrcRdy_xSI;
        MonInDstRdy_xSO  <= MonInDstRdy_xS;
        --
        SeqOutAddr_xDO   <= SeqOutAddr_xD;
        SeqOutSrcRdy_xSO <= SeqOutSrcRdy_xS;
        SeqOutDstRdy_xS  <= SeqOutDstRdy_xSI;
    end generate g_loopback_disabled;

    -- loopback test enabled:
    g_loopback_enabled : if TestEnableSequencerToMonitorLoopback generate
        -- disable sequencer output port & sink on monitor input port:
        SeqOutAddr_xDO   <= (others => '0');
        SeqOutSrcRdy_xSO <= '0';
        MonInDstRdy_xSO  <= '1';
        -- create loop:
        MonInAddr_xD     <= SeqOutAddr_xD;
        MonInSrcRdy_xS   <= SeqOutSrcRdy_xS;
        SeqOutDstRdy_xS  <= MonInDstRdy_xS;
    end generate g_loopback_enabled;


    -----------------------------------------------------------------------------
    -- bias Sequencer
    -----------------------------------------------------------------------------

    --u_BiasSerializer : BiasSerializer
    --    port map (
    --        resetn            => Reset_xRBI,
    --        clk               => CoreClk_xCI,
    --        chip_type         => ChipType_xSI,
    --        Data              => ConfigAddr_xD,
    --        Req               => ConfigReq_xS,
    --        Ack               => ConfigAck_xS,
    --        prescaler_value   => PrescalerValue_xDI,
    --        biasfinished      => BiasFinished_xSO,
    --        ClockLow          => ClockLow_xDI,
    --        LatchTime         => LatchTime_xDI,
    --        SetupHold         => SetupHold_xDI,
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
    --BiasProgPins_xDO <= '0' & i_BGMonitorSel_xAS & i_BGAddrSel_xAS & i_BGMonEn_xAS & i_BGBiasOSel_xAS & i_BGLatch_xASB & i_BGClk_xAS & i_BGBitIn_xAD;


    -----------------------------------------------------------------------------
    -- OUT - little-endian conversion and fifo
    -----------------------------------------------------------------------------

    -- timestamp
    SeqInAddrEvt_xD(39 downto 32) <= LiEnSeqInAddrEvt_xD(39 downto 32);
    SeqInAddrEvt_xD(47 downto 40) <= LiEnSeqInAddrEvt_xD(47 downto 40);
    SeqInAddrEvt_xD(55 downto 48) <= LiEnSeqInAddrEvt_xD(55 downto 48);
    SeqInAddrEvt_xD(63 downto 56) <= LiEnSeqInAddrEvt_xD(63 downto 56);
    -- address
    SeqInAddrEvt_xD( 7 downto  0) <= LiEnSeqInAddrEvt_xD( 7 downto  0);
    SeqInAddrEvt_xD(15 downto  8) <= LiEnSeqInAddrEvt_xD(15 downto  8);
    SeqInAddrEvt_xD(23 downto 16) <= LiEnSeqInAddrEvt_xD(23 downto 16);
    SeqInAddrEvt_xD(31 downto 24) <= LiEnSeqInAddrEvt_xD(31 downto 24);
    --
    u_Outfifo_32_2048_64 : Outfifo_32_2048_64
        port map (
            rst          => Reset_xR,    -- high-active reset
            wr_clk       => CoreClk_xCI,
            rd_clk       => CoreClk_xCI,
            din          => CoreFifoDat_xDI,
            wr_en        => CoreFifoWrite_xSI,
            rd_en        => SeqInRead_xS,
            dout         => LiEnSeqInAddrEvt_xD,
            full         => CoreFifoFull_xSO,
            almost_full  => CoreFifoAlmostFull_xSO,
            overflow     => open,
            empty        => SeqInEmpty_xS,
            almost_empty => open,
            underflow    => open
        );

    CoreFifoEmpty_xSO <= SeqInEmpty_xS;


    -----------------------------------------------------------------------------
    -- IN - No conversion and fifo
    -----------------------------------------------------------------------------

    -- to computer, timestamp
    LiEnMonOutAddrEvt_xD(39 downto 32) <= MonOutAddrEvt_xD(39 downto 32);
    LiEnMonOutAddrEvt_xD(47 downto 40) <= MonOutAddrEvt_xD(47 downto 40);
    LiEnMonOutAddrEvt_xD(55 downto 48) <= MonOutAddrEvt_xD(55 downto 48);
    LiEnMonOutAddrEvt_xD(63 downto 56) <= MonOutAddrEvt_xD(63 downto 56);
    -- to computer, address
    LiEnMonOutAddrEvt_xD( 7 downto  0) <= MonOutAddrEvt_xD( 7 downto  0);
    LiEnMonOutAddrEvt_xD(15 downto  8) <= MonOutAddrEvt_xD(15 downto  8);
    LiEnMonOutAddrEvt_xD(23 downto 16) <= MonOutAddrEvt_xD(23 downto 16);
    LiEnMonOutAddrEvt_xD(31 downto 24) <= MonOutAddrEvt_xD(31 downto 24);
    --

    u_Infifo_64_1024_32 : Infifo_64_1024_32
        port map (
            clk          => CoreClk_xCI,
            srst         => Reset_xR,    -- high-active reset
            din          => LiEnMonOutAddrEvt_xD,
            wr_en        => enableFifoWriting_xS,
            rd_en        => effectiveRdEn_xS,
            dout         => i_fifoCoreDat_xD,
            full         => MonOutFull_xS,
            almost_full  => DBG_almost_full,
            overflow     => DBG_overflow,
            empty        => i_FifoCoreEmpty_xSO,
            almost_empty => i_FifoCoreAlmostEmpty_xSO,
            underflow    => DBG_underflow,
            data_count   => fifoWrDataCount_xD
        );

    FifoCoreNumData_o <= fifoWrDataCount_xD;

    -- It's DmaLength_xDI/2 because of the FIFO is 64 bit and the reading is 32 bit wide
    FifoCoreBurstReady_xSO <= '1' when (fifoWrDataCount_xD >= ('0'&DmaLength_xDI(10 downto 1))) else '0';


    p_ReadDataTimeSel : process (CoreClk_xCI) is
        begin
        if (rising_edge(CoreClk_xCI)) then
            if (Reset_xRBI = '0') then
                dataRead_xS <= '0';
            else
                if (FifoCoreRead_xSI = '1') then
                    dataRead_xS <= not(dataRead_xS);
                end if;
            end if;
        end if;
    end process p_ReadDataTimeSel;

    FifoCoreDat_xDO  <= i_fifoCoreDat_xD(63 downto 32) when (dataRead_xS = '0') else  -- i.e. Time
                        i_fifoCoreDat_xD(31 downto  0);                               -- i.e. Data
    effectiveRdEn_xS <= FifoCoreRead_xSI when (dataRead_xS = '1') else '0';

    FifoCoreFull_xSO <= MonOutFull_xS;

    --enableFifoWriting_xS <= MonOutWrite_xS when (MonOutAddrEvt_xD(7 downto 0) >= OutThresholdVal_xDI(7 downto 0)) else '0';
    enableFifoWriting_xS <= MonOutWrite_xS;


    -----------------------------------------------------------------------------
    -----------------------------------------------------------------------------

    -- pragma synthesis_off
    p_log_file_writing : process
        variable v_buf_out: line;
    begin
        write(v_buf_out, string'("time,ChipId,IntfId,Address"));
        writeline(logfile_ptr, v_buf_out);
        loop
            wait until (rising_edge(CoreClk_xCI));
            if (MonOutWrite_xS = '1') then
                write(v_buf_out, now, right, 10); write(v_buf_out, string'(","));
                if (LiEnMonOutAddrEvt_xD(C_PAER_DSIZE) = '1') then
                    write(v_buf_out, string'("R,"));
                else
                    write(v_buf_out, string'("L,"));
                end if;
                 if (LiEnMonOutAddrEvt_xD(C_PAER_DSIZE-1 downto C_PAER_DSIZE-1-3) = "0000") then
                    write(v_buf_out, string'("TD,"));
                else
                    write(v_buf_out, string'("APS,"));
                end if;
               case (LiEnMonOutAddrEvt_xD(C_INTERNAL_DSIZE-1 downto C_INTERNAL_DSIZE-2)) is
                    when "00" => write(v_buf_out, string'("PAER,"));
                    when "01" => write(v_buf_out, string'("SAER,"));
                    when "10" => write(v_buf_out, string'("GTP,"));
                    when others => write(v_buf_out, string'("Unknown"));
                end case;
                hwrite(v_buf_out, LiEnMonOutAddrEvt_xD(C_PAER_DSIZE-1 downto 0));
                write(v_buf_out, string'(", "));
                hwrite(v_buf_out, LiEnMonOutAddrEvt_xD(63 downto 32));
                write(v_buf_out, string'(" ("));
                hwrite(v_buf_out, LiEnMonOutAddrEvt_xD(31 downto 0));
                write(v_buf_out, string'(")"));
                writeline(logfile_ptr, v_buf_out);
            end if;
        end loop;
    end process p_log_file_writing;
    -- pragma synthesis_on


DBG_din             <= LiEnMonOutAddrEvt_xD;   
DBG_wr_en           <= enableFifoWriting_xS;       
DBG_rd_en           <= effectiveRdEn_xS;       
DBG_dout            <= i_fifoCoreDat_xD;            
DBG_full            <= MonOutFull_xS;        
-- DBG_almost_full     <= DBG_almost_full; 
--DBG_overflow        <= DBG_overflow;      
DBG_empty           <= i_FifoCoreEmpty_xSO;            
DBG_almost_empty    <= i_FifoCoreAlmostEmpty_xSO;

FifoCoreEmpty_xSO   <= i_FifoCoreEmpty_xSO;
FifoCoreAlmostEmpty_xSO <= i_FifoCoreAlmostEmpty_xSO;

--DBG_underflow       <= DBG_underflow;   
DBG_data_count      <= fifoWrDataCount_xD;
DBG_Timestamp_xD   <= Timestamp_xD;
DBG_MonInAddr_xD   <= MonInAddr_xD;
DBG_MonInSrcRdy_xS <= MonInSrcRdy_xS;
DBG_MonInDstRdy_xS <= MonInDstRdy_xS;
DBG_RESETFIFO      <= Reset_xR;


end architecture str;

-------------------------------------------------------------------------------
