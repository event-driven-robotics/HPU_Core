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
    FifoCoreDat_o           : out std_logic_vector(63 downto 0);
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
signal RxFifoAlmostFull   : std_logic;
signal RxFifoOverflow     : std_logic;
signal RxFifoUnderflow    : std_logic;
signal RxFifoWrDataCount  : std_logic_vector(10 downto 0);
signal RxFifoRdDataCount  : std_logic_vector(10 downto 0);


signal enableFifoWriting  : std_logic;
-- signal fifoWrDataCount    : std_logic_vector(10 downto 0);
signal i_fifoCoreDat      : std_logic_vector(63 downto 0);
signal dataRead           : std_logic;
signal effectiveRdEn      : std_logic;


signal i_FifoCoreEmpty_o        : std_logic;
signal i_FifoCoreAlmostEmpty_o  : std_logic;
signal msb                      : std_logic;
signal msb_d                    : std_logic;

-- pragma synthesis_off
file logfile_ptr   : text open WRITE_MODE is "monitor_activity.csv";
-- pragma synthesis_on

signal infifo_wr_rst_busy   : std_logic;
signal infifo_rd_rst_busy   : std_logic;

signal rxfifo_wr_rst_busy   : std_logic;
signal rxfifo_wr_rst_busy_d : std_logic;
signal rxfifo_rd_rst_busy   : std_logic;
signal rxfifo_rd_rst_busy_d : std_logic;

signal txfifo_wr_rst_busy   : std_logic;
signal txfifo_wr_rst_busy_d : std_logic;
signal txfifo_rd_rst_busy   : std_logic;
signal txfifo_rd_rst_busy_d : std_logic;


signal RxFifoReset_cnt      : std_logic_vector(3 downto 0);
signal RxFifoReset_cnt_en   : std_logic;
signal RxFifoResetting      : std_logic;

signal TxFifoReset_cnt      : std_logic_vector(3 downto 0);
signal TxFifoReset_cnt_en   : std_logic;
signal TxFifoResetting      : std_logic;

-----------------------------------------------------------------------------
-- Debug attributes
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
TxFifoReset_cnt_en <= '1' when (TxFifoReset_cnt /= conv_std_logic_vector(0, TxFifoReset_cnt'length)) else '0';

process(CoreClk_i, Reset_n_CoreClk_i)
begin
  if (Reset_n_CoreClk_i = '0') then
    TxFifoReset_cnt <= (others => '1');
    TxFifoReset     <= '1';
  elsif rising_edge(CoreClk_i) then
    if (FlushTxFifos_i = '1') then
      TxFifoReset_cnt <= (others => '1');
    elsif (TxFifoReset_cnt_en = '1') then
      TxFifoReset_cnt <= TxFifoReset_cnt - 1;
    end if;
    TxFifoReset <= TxFifoReset_cnt_en; 
  end if;
end process;

TXFIFO_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
  OUTFIFO_32_2048_64_1024_m : OUTFIFO_32_2048_64_1024_ZYNQ
    port map (
      rst          => ResetTX,    -- high-active reset
      wr_clk       => CoreClk_i,
      rd_clk       => CoreClk_i,
      din          => CoreFifoDat_i,
      wr_en        => CoreFifoWrite_i,
      rd_en        => SeqInRead,
      dout         => SeqInAddrEvt,
      full         => CoreFifoFull_o,
      almost_full  => CoreFifoAlmostFull_o,
      overflow     => open,
      empty        => SeqInEmpty,
      almost_empty => open,
      underflow    => open
    );
    
end generate;

TXFIFO_FOR_ZYNQUPLUS_m : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin

  TxFifoWrEn              <= CoreFifoWrite_i and not txfifo_wr_rst_busy;
  CoreFifoFull_o          <= TxFifoFull or txfifo_wr_rst_busy;
  CoreFifoAlmostFull_o    <= TxFifoAlmostFull or txfifo_wr_rst_busy;  
  
  TxFifoRdEn              <= SeqInRead and not txfifo_rd_rst_busy;
  SeqInEmpty              <= TxFifoEmpty or txfifo_rd_rst_busy;



  TXFIFO_HPU_ZYNQUPLUS_m : TXFIFO_HPU_ZYNQUPLUS
    PORT MAP (
      rst           => TxFifoReset,
      wr_clk        => AxisClk_i,
      rd_clk        => CoreClk_i,
      din           => CoreFifoDat_i,
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





CoreFifoEmpty_o <= SeqInEmpty;




-----------------------------------------------------------------------------
-- RX FIFO

-- Reset for FIFO
-- RxFifoReset_cnt_en <= '1' when (RxFifoReset_cnt /= conv_std_logic_vector(0, RxFifoReset_cnt'length)) else '0';
-- 
-- process(CoreClk_i, Reset_n_CoreClk_i)
-- begin
--   if (Reset_n_CoreClk_i = '0') then
--     RxFifoReset_cnt <= (others => '1');
--     RxFifoReset     <= '1';
--   elsif rising_edge(CoreClk_i) then
--     if (FlushRXFifos_i = '1') then
--       RxFifoReset_cnt <= (others => '1');
--     elsif (RxFifoReset_cnt_en = '1') then
--       RxFifoReset_cnt <= RxFifoReset_cnt - 1;
--     end if;
--     RxFifoReset <= RxFifoReset_cnt_en; 
--   end if;
-- end process;

process(CoreClk_i, Reset_n_CoreClk_i)
begin
  if (Reset_n_CoreClk_i = '0') then
    RxFifoReset     <= '1';
    RxFifoResetting <= '1';
  elsif rising_edge(CoreClk_i) then
    if (FlushRXFifos_i = '1') then
      RxFifoReset     <= '1';
    elsif (rxfifo_rd_rst_busy = '1' and rxfifo_rd_rst_busy_d = '0') then
      RxFifoReset     <= '0';
    end if;
    --
    if (FlushRXFifos_i = '1') then
      RxFifoResetting <= '1';
    elsif (rxfifo_rd_rst_busy = '0' and rxfifo_rd_rst_busy_d = '1') then
      RxFifoReset     <= '0';
    end if;
  end if;
end process;

RXFIFO_FOR_ZYNQ : if C_FAMILY = "zynq"  generate -- "zynq", "zynquplus" 
begin
   
  u_INFIFO_64_1024 : INFIFO_64_1024_ZYNQ
    port map (
      clk          => CoreClk_i,
      srst         => ResetRX,    -- high-active reset
      din          => MonOutAddrEvt,
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

RXFIFO_FOR_ZYNQUPLUS : if C_FAMILY = "zynquplus"  generate -- "zynq", "zynquplus" 
begin

  RxFifoWrEn                <= MonOutWrite and not rxfifo_wr_rst_busy;
  MonOutFull                <= RxFifoFull or rxfifo_wr_rst_busy;
  
  RxFifoRdEn                <= effectiveRdEn and not rxfifo_rd_rst_busy;
  i_FifoCoreEmpty_o         <= RxFifoEmpty or rxfifo_rd_rst_busy;
  i_FifoCoreAlmostEmpty_o   <= RxFifoAlmostEmpty or rxfifo_rd_rst_busy;
  
  RXFIFO_HPU_ZYNQUPLUS_i : RXFIFO_HPU_ZYNQUPLUS
    PORT MAP (
      rst           => RxFifoReset,
      wr_clk        => CoreClk_i,
      rd_clk        => AxisClk_i,
      din           => MonOutAddrEvt,
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

-- p_ReadDataTimeSel : process (AxisClk_i, Reset_n_AxisClk_i) is
-- begin
--   if (Reset_n_AxisClk_i = '0') then
--     dataRead <= '0';
--   elsif (rising_edge(AxisClk_i)) then
--     if (OnlyEvents_i = '1') then
--       dataRead <= '1';
--     elsif (FifoCoreRead_i = '0') then
--       dataRead <= '0';
--     else
--       dataRead <= not(dataRead);
--     end if;
--   end if;
-- end process p_ReadDataTimeSel;

-- p_ReadDataTimeSel : process (AxisClk_i, Reset_n_AxisClk_i) is
-- begin
--   if (Reset_n_AxisClk_i = '0') then
--     dataRead <= '0';
--   elsif (rising_edge(AxisClk_i)) then
--     if (FifoCoreRead_i = '1') then
--       dataRead <= not(dataRead);
--     end if;
--   end if;
-- end process p_ReadDataTimeSel;

-- FifoCoreDat_o      <= i_fifoCoreDat(63 downto 32) when (dataRead = '0') else      -- i.e. Timestamp
--                       i_fifoCoreDat(31 downto  0);                                -- i.e. Event

FifoCoreDat_o      <=  i_fifoCoreDat;    
                      
-- effectiveRdEn      <=  '0' when (dataRead = '0') else FifoCoreRead_i;
effectiveRdEn      <=  FifoCoreRead_i;

FifoCoreFull_o     <= MonOutFull;
FifoCoreLastData_o <= RxFifoAlmostEmpty and not RxFifoEmpty;

--enableFifoWriting <= MonOutWrite when (MonOutAddrEvt(7 downto 0) >= OutThresholdValI(7 downto 0)) else '0';
enableFifoWriting <= MonOutWrite;

FifoCoreEmpty_o       <= i_FifoCoreEmpty_o;
FifoCoreAlmostEmpty_o <= i_FifoCoreAlmostEmpty_o;

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
