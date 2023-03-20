-------------------------------------------------------------------------------
-- MonSeqRR
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

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
    
library swissknife_lib;
    use swissknife_lib.swissknife_pkg.all;

--****************************
--   PORT DECLARATION
--****************************

entity CoreMonSeq is
  generic (
    C_FAMILY                : string := "zynq"; -- "zynq", "zynquplus" 
    --
    C_PAER_DSIZE            : integer
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
    OnlyEventsRx_i          : in  std_logic;
    OnlyEventsTx_i          : in  std_logic;
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
    -- Data Received
    FifoRxDat_o             : out std_logic_vector(63 downto 0);
    FifoRxRead_i            : in  std_logic;
    FifoRxEmpty_o           : out std_logic;
    FifoRxAlmostEmpty_o     : out std_logic;
    FifoRxLastData_o        : out std_logic;
    FifoRxFull_o            : out std_logic;
    FifoRxNumData_o         : out std_logic_vector(10 downto 0);
    FifoRxResetBusy_o       : out std_logic;
    --
    -- Data to be transmitted
    FifoTxDat_i             : in  std_logic_vector(31 downto 0);
    FifoTxWrite_i           : in  std_logic;
    FifoTxLastData_i        : in  std_logic;
    FifoTxFull_o            : out std_logic;
    FifoTxAlmostFull_o      : out std_logic;
    FifoTxEmpty_o           : out std_logic;
    FifoTxResetBusy_o       : out std_logic   
  );
end entity CoreMonSeq;


--****************************
--   IMPLEMENTATION
--****************************

architecture str of CoreMonSeq is

-----------------------------------------------------------------------------
-- signals
-----------------------------------------------------------------------------


-- Timestamp Counter
signal Timestamp_RX               : std_logic_vector(31 downto 0);
signal Timestamp_TX               : std_logic_vector(31 downto 0);
signal ShortTimestamp_TX          : std_logic_vector(31 downto 0);
signal LoadTimer                  : std_logic;
signal LoadValue                  : std_logic_vector(31 downto 0);

-- Monitor -> Core
signal MonOutAddrEvt              : std_logic_vector(63 downto 0);
signal MonOutWrite                : std_logic;
signal MonOutFull                 : std_logic;

-- Core -> Sequencer
signal SeqInAddrEvt               : std_logic_vector(63 downto 0);
signal SeqInRead                  : std_logic;
signal SeqInEmpty                 : std_logic;

-- Sequencer -> Config Logic
--signal ConfigAddr : std_logic_vector(31 downto 0);
--signal ConfigReq  : std_logic;
--signal ConfigAck  : std_logic;


-- Reset high signal for FIFOs
signal ResetRX            : std_logic;
signal ResetTX            : std_logic;
signal FlushRXFifos_sr    : std_logic_vector(15 downto 0);
signal FlushTXFifos_sr    : std_logic_vector(15 downto 0);

signal TxFifoReset          : std_logic;
signal TxFifoWrEn         : std_logic;
signal TxFifoRdEn         : std_logic;
signal TxFifoEmpty        : std_logic;
signal TxFifoFull         : std_logic;
signal TxFifoAlmostFull   : std_logic;
signal TxWrDataCount      : std_logic_vector(11 downto 0);
signal TxRdDataCount      : std_logic_vector(10 downto 0);

signal RxFifoReset          : std_logic;
signal RxFifoWrEn         : std_logic;
signal RxFifoRdEn         : std_logic;
signal RxFifoEmpty        : std_logic;
signal RxFifoAlmostempty  : std_logic;
signal RxFifoFull         : std_logic;
-- signal RxFifoAlmostFull   : std_logic;
-- signal RxFifoOverflow     : std_logic;
-- signal RxFifoUnderflow    : std_logic;
-- signal RxFifoWrDataCount  : std_logic_vector(10 downto 0);
-- signal RxFifoRdDataCount  : std_logic_vector(10 downto 0);


-- signal i_FifoRxDat      : std_logic_vector(63 downto 0);
signal dataRead           : std_logic;
signal timeWrite           : std_logic;
signal effectiveRdEn      : std_logic;


signal msb                      : std_logic;
signal msb_d                    : std_logic;

-- pragma synthesis_off
file logfile_ptr   : text open WRITE_MODE is "monitor_activity.csv";
-- pragma synthesis_on

signal infifo_wr_rst_busy   : std_logic;
signal infifo_rd_rst_busy   : std_logic;


signal txfifo_arst_n                : std_logic;
signal TxFifoWrRstBusy              : std_logic;
signal TxFifoWrRstBusy_CoreClk      : std_logic;
signal TxFifoRdRstBusy              : std_logic;
signal txfifo_rst_busy              : std_logic;
signal txfifo_rst_busy_d            : std_logic;

signal rxfifo_arst_n                : std_logic;
signal RxFifoWrRstBusy              : std_logic;
signal RxFifoRdRstBusy              : std_logic;
signal RxFifoRdRstBusy_CoreClk      : std_logic;
signal rxfifo_rst_busy              : std_logic;
signal rxfifo_rst_busy_d            : std_logic;

signal RxFifoReset_cnt      : std_logic_vector(3 downto 0);
signal RxFifoReset_cnt_en   : std_logic;
signal RxFifoResetting      : std_logic;

signal TxFifoReset_cnt      : std_logic_vector(3 downto 0);
signal TxFifoReset_cnt_en   : std_logic;
signal TxFifoResetting      : std_logic;

signal TxFifoDin            : std_logic_vector(63 downto 0);
signal TxFifoDinMsB         : std_logic_vector(63 downto 32);
signal TxFifoDinLsB         : std_logic_vector(31 downto 0);


-- -----------------------------------------------------------------------------
-- DEBUG
attribute mark_debug : string;



begin


-----------------------------------------------------------------------------
-- TX PATH
-----------------------------------------------------------------------------

-----------------
-- Timestamper
TIMESTAMP_TX_m : Timestamp
  port map (
    Rst_n_i       => Reset_n_CoreClk_i,
    Clk_i         => CoreClk_i,
    Zero_i        => '0',
    LoadTimer_i   => LoadTimer,
    LoadValue_i   => LoadValue,
    CleanTimer_i  => '0',
    Timestamp_o   => Timestamp_TX
  );

-----------------
-- Sequencer
SEQUENCER_m : sequencer
  port map (
    Rst_n_i              => Reset_n_CoreClk_i,
    Clk_i                => CoreClk_i,
    Enable_i             => '1',
    --
    En100us_i            => Timing_i.en100us,
    -- 
    TSMode_i             => TxTSMode_i,         -- NOTE: When data doesn't contain Timestamp, the timing mode is set to "Asap" in "axilite" module
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
    OutAddr_o            => SeqOutAddr_o,
    OutSrcRdy_o          => SeqOutSrcRdy_o,
    OutDstRdy_i          => SeqOutDstRdy_i
    --
    --ConfigAddr_o => ConfigAddr,
    --ConfigReq_o  => ConfigReq,
    --ConfigAck_i  => ConfigAck
  );
  
-----------------
-- FIFO 
-- Reset for FIFO

TXFIFOWRRSTBUSY_CDC_m : signal_cdc 
  generic map (
    IN_FF_SYNC_g  => FALSE, -- If TRUE, "SIG_IN_A_i" is sychronized again with CLK_A_i (in owrer to bypass glitches)
    RESVALUE_g    => '0'    -- RESET Value of B signal (should be equal to reset value of A signal)
  )
  port map ( 
    CLK_A_i       => '0',                 
    ARST_N_A_i    => '0',                 
    SIG_IN_A_i    => TxFifoWrRstBusy,  
    --
    CLK_B_i       => CoreClk_i,           
    ARST_N_B_i    => Reset_n_CoreClk_i,           
    SIG_OUT_B_i   => TxFifoWrRstBusy_CoreClk    
  );

txfifo_rst_busy <= TxFifoRdRstBusy or TxFifoWrRstBusy_CoreClk; -- Note: as reset is done, TxFifoRdRstBusy and TxFifoWrRstBusy_CoreClk have always a "both to '1' time" 

process(CoreClk_i, Reset_n_CoreClk_i)
begin
  if (Reset_n_CoreClk_i = '0') then
    TxFifoReset                   <= '1';
    TxFifoResetting               <= '1';
    txfifo_rst_busy_d             <= '0';
  elsif rising_edge(CoreClk_i) then
    txfifo_rst_busy_d <= txfifo_rst_busy;
    --
    if (FlushTXFifos_i = '1') then
      TxFifoReset     <= '1';
    elsif (TxFifoRdRstBusy = '1' and TxFifoWrRstBusy_CoreClk = '1') then
      TxFifoReset     <= '0';
    end if;
    --
    if (FlushTXFifos_i = '1') then
      TxFifoResetting <= '1';
    elsif (txfifo_rst_busy = '0' and  txfifo_rst_busy_d /= '0') then  -- Note: txfifo_rst_busy_d /= '0' because of "unknown" in simulation for TxFifoRdRstBusy
      TxFifoResetting <= '0';
    end if;
  end if;
end process;


p_WriteEventsTX : process (AxisClk_i, Reset_n_AxisClk_i) is
begin
  if (TxFifoReset = '1') then
    TxFifoDinMsb <= (others => '0');
    timeWrite <= '1'; 
  elsif (rising_edge(AxisClk_i)) then
    if (FifoTxWrite_i = '1') then
      if (FifoTxLastData_i = '1') then
        timeWrite <= '1';
      else 
        timeWrite <= not(timeWrite);
      end if;
      --
      if (timeWrite = '1') then
        TxFifoDinMsb(63 downto 32) <= FifoTxDat_i;
      end if;
    end if;
  end if;
end process p_WriteEventsTX; 

-- Write side
TxFifoDin             <= TxFifoDinMsb & FifoTxDat_i; 
TxFifoWrEn            <= FifoTxWrite_i and (not timeWrite or OnlyEventsTx_i) and not TxFifoWrRstBusy; 
FifoTxAlmostFull_o    <= TxFifoAlmostFull or TxFifoWrRstBusy;
FifoTxFull_o          <= TxFifoFull or TxFifoWrRstBusy; 

-- Read side
TxFifoRdEn            <= SeqInRead and not TxFifoRdRstBusy;
SeqInEmpty            <= TxFifoEmpty or TxFifoRdRstBusy;
FifoTxEmpty_o         <= TxFifoEmpty or TxFifoRdRstBusy;

TXFIFO_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin

  TXFIFO_HPU_ZYNQ_m : TXFIFO_HPU_ZYNQ
    PORT MAP (
      rst           => TxFifoReset,
      wr_clk        => AxisClk_i,
      rd_clk        => CoreClk_i,
      din           => TxFifoDin, -- FifoTxDat_i,
      wr_en         => TxFifoWrEn,
      rd_en         => TxFifoRdEn,
      dout          => SeqInAddrEvt,
      full          => TxFifoFull,
      almost_full   => TxFifoAlmostFull,
      overflow      => open,
      empty         => TxFifoEmpty,
      almost_empty  => open,
      underflow     => open,
      rd_data_count => open,
      wr_data_count => open,      
      wr_rst_busy   => TxFifoWrRstBusy,
      rd_rst_busy   => TxFifoRdRstBusy
    );   
   
end generate;

TXFIFO_FOR_ZYNQUPLUS_m : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin

  TXFIFO_HPU_ZYNQUPLUS_m : TXFIFO_HPU_ZYNQUPLUS
    PORT MAP (
      rst           => TxFifoReset,
      wr_clk        => AxisClk_i,
      rd_clk        => CoreClk_i,
      din           => TxFifoDin, -- FifoTxDat_i,
      wr_en         => TxFifoWrEn,
      rd_en         => TxFifoRdEn,
      dout          => SeqInAddrEvt,
      full          => TxFifoFull,
      almost_full   => TxFifoAlmostFull,
      overflow      => open,
      empty         => TxFifoEmpty,
      almost_empty  => open,
      underflow     => open,
      rd_data_count => open,
      wr_data_count => open,      
      wr_rst_busy   => TxFifoWrRstBusy,
      rd_rst_busy   => TxFifoRdRstBusy
    );    

end generate;


-----------------------------------------------------------------------------
-- RX PATH
-----------------------------------------------------------------------------

TIMESTAMP_RX_m : Timestamp
  port map (
    Rst_n_i        => Reset_n_CoreClk_i,
    Clk_i          => CoreClk_i,
    Zero_i         => '0',
    LoadTimer_i    => '0',
    LoadValue_i    => (others => '0'),
    CleanTimer_i   => CleanTimer_i,
    Timestamp_o    => Timestamp_RX
  );

-- Timestamp wrap detector    
msb <= Timestamp_RX(23) when FullTimestamp_i='0' else
       Timestamp_RX(31);

p_sample : process (CoreClk_i)
begin
  if (rising_edge(CoreClk_i)) then
    if (Reset_n_CoreClk_i = '0') then
      msb_d <= '0';
    else
      msb_d <= msb;
    end if;
  end if;
end process p_sample;

WrapDetected_o <= msb_d and not(msb);

TIMETAGGER_m : timetagger
  port map (
    Rst_n_i         => Reset_n_CoreClk_i,
    Clk_i           => CoreClk_i,
    FullTimestamp_i => FullTimestamp_i,
    Timestamp_i     => Timestamp_RX,
    MonEn_i         => '1',
    --
    InAddr_i        => MonInAddr_i,
    InSrcRdy_i      => MonInSrcRdy_i,
    InDstRdy_o      => MonInDstRdy_o,
    --
    OutAddrEvt_o    => MonOutAddrEvt,
    OutWrite_o      => MonOutWrite,
    OutFull_i       => MonOutFull
  );

ShortTimestamp_TX <= x"0000" & Timestamp_TX(15 downto 0);

-----------------------------------------------------------------------------
-- RX FIFO

RXFIFORDRSTBUSY_CDC_m : signal_cdc 
  generic map (
    IN_FF_SYNC_g  => FALSE, -- If TRUE, "SIG_IN_A_i" is sychronized again with CLK_A_i (in order to bypass glitches)
    RESVALUE_g    => '0'    -- RESET Value of B signal (should be equal to reset value of A signal)
  )
  port map ( 
    CLK_A_i       => '0',                 
    ARST_N_A_i    => '0',                 
    SIG_IN_A_i    => RxFifoRdRstBusy,  
    --
    CLK_B_i       => CoreClk_i,           
    ARST_N_B_i    => Reset_n_CoreClk_i,           
    SIG_OUT_B_i   => RxFifoRdRstBusy_CoreClk    
  );

rxfifo_rst_busy <= RxFifoWrRstBusy or RxFifoRdRstBusy_CoreClk; -- Note: as reset is done, RxFifoWrRstBusy and RxFifoRdRstBusy_CoreClk have always a "both to '1' time" 

process(CoreClk_i, Reset_n_CoreClk_i)
begin
  if (Reset_n_CoreClk_i = '0') then
    RxFifoReset                   <= '1';
    RxFifoResetting               <= '1';
    rxfifo_rst_busy_d             <= '0';
  elsif rising_edge(CoreClk_i) then
    rxfifo_rst_busy_d <= rxfifo_rst_busy;
    --
    if (FlushRXFifos_i = '1') then
      RxFifoReset     <= '1';
    elsif (RxFifoWrRstBusy = '1' and RxFifoRdRstBusy_CoreClk = '1') then
      RxFifoReset     <= '0';
    end if;
    --
    if (FlushRXFifos_i = '1') then
      RxFifoResetting <= '1';
    elsif (rxfifo_rst_busy = '0' and  rxfifo_rst_busy_d /= '0') then  -- Note: rxfifo_rst_busy_d /= '0' because of "unknown" in simulation for RxFifoWrRstBusy
      RxFifoResetting <= '0';
    end if;
  end if;
end process;

-- Write side
RxFifoWrEn            <= MonOutWrite and not RxFifoWrRstBusy;
MonOutFull            <= RxFifoFull or RxFifoWrRstBusy;
FifoRxFull_o          <= RxFifoFull or RxFifoWrRstBusy;  

-- Read side
RxFifoRdEn            <= FifoRxRead_i and not RxFifoRdRstBusy;
FifoRxEmpty_o         <= RxFifoEmpty or RxFifoRdRstBusy;
FifoRxAlmostEmpty_o   <= RxFifoAlmostEmpty or RxFifoRdRstBusy;
FifoRxResetBusy_o     <= RxFifoRdRstBusy;
FifoRxLastData_o      <= RxFifoAlmostEmpty and not RxFifoEmpty;



RXFIFO_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
  RXFIFO_HPU_ZYNQU_i : RXFIFO_HPU_ZYNQ
    PORT MAP (
      rst           => RxFifoReset,
      wr_clk        => CoreClk_i,
      rd_clk        => AxisClk_i,
      din           => MonOutAddrEvt,
      wr_en         => RxFifoWrEn,
      rd_en         => RxFifoRdEn,
      dout          => FifoRxDat_o,
      full          => RxFifoFull,
      almost_full   => open, -- RxFifoAlmostFull,
      overflow      => open, -- RxFifoOverflow,
      empty         => RxFifoEmpty,
      almost_empty  => RxFifoAlmostEmpty,
      underflow     => open, -- RxFifoUnderflow,
      rd_data_count => FifoRxNumData_o,
      wr_data_count => open, -- RxFifoWrDataCount,
      wr_rst_busy   => RxFifoWrRstBusy,
      rd_rst_busy   => RxFifoRdRstBusy
      );
    
end generate;

RXFIFO_FOR_ZYNQUPLUS : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin
 
  RXFIFO_HPU_ZYNQUPLUS_i : RXFIFO_HPU_ZYNQUPLUS
    PORT MAP (
      rst           => RxFifoReset,
      wr_clk        => CoreClk_i,
      rd_clk        => AxisClk_i,
      din           => MonOutAddrEvt,
      wr_en         => RxFifoWrEn,
      rd_en         => RxFifoRdEn,
      dout          => FifoRxDat_o,
      full          => RxFifoFull,
      almost_full   => open, -- RxFifoAlmostFull,
      overflow      => open, -- RxFifoOverflow,
      empty         => RxFifoEmpty,
      almost_empty  => RxFifoAlmostEmpty,
      underflow     => open, -- RxFifoUnderflow,
      rd_data_count => FifoRxNumData_o,
      wr_data_count => open, -- RxFifoWrDataCount,
      wr_rst_busy   => RxFifoWrRstBusy,
      rd_rst_busy   => RxFifoRdRstBusy
      );

end generate;





-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- FOR SIMULATION

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
      if (MonOutAddrEvt(C_PAER_DSIZE) = '1') then
        write(v_buf_out, string'("R,"));
      else
        write(v_buf_out, string'("L,"));
      end if;
       if (MonOutAddrEvt(C_PAER_DSIZE-1 downto C_PAER_DSIZE-1-3) = "0000") then
        write(v_buf_out, string'("TD,"));
      else
        write(v_buf_out, string'("APS,"));
      end if;
      case (MonOutAddrEvt(C_INTERNAL_DSIZE-1 downto C_INTERNAL_DSIZE-2)) is
        when "00" => write(v_buf_out, string'("PAER,"));
        when "01" => write(v_buf_out, string'("SAER,"));
        when "10" => write(v_buf_out, string'("GTP,"));
        when others => write(v_buf_out, string'("Unknown"));
      end case;
      hwrite(v_buf_out, MonOutAddrEvt(C_PAER_DSIZE-1 downto 0));
      write(v_buf_out, string'(", "));
      hwrite(v_buf_out, MonOutAddrEvt(63 downto 32));
      write(v_buf_out, string'(" ("));
      hwrite(v_buf_out, MonOutAddrEvt(31 downto 0));
      write(v_buf_out, string'(")"));
      writeline(logfile_ptr, v_buf_out);
    end if;
  end loop;
end process p_log_file_writing;
    -- pragma synthesis_on







end architecture str;

-------------------------------------------------------------------------------
