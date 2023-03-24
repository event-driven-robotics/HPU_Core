-------------------------------------------------------------------------------
-- Neuserial_AxiStream
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;


--****************************
--   PORT DECLARATION
--****************************

entity axistream is
    port (
        Clk                    : in  std_logic;
        nRst                   : in  std_logic;  -- NOTE: synchronous reset
        --                    
        DMA_test_mode_i        : in  std_logic;
        EnableAxistreamIf_i    : in  std_logic;
        OnlyEventsRx_i         : in  std_logic;
        OnlyEventsTx_i         : in  std_logic;
        DMA_is_running_o       : out std_logic;
        DmaLength_i            : in  std_logic_vector(15 downto 0);
        ResetStream_i          : in  std_logic;
        LatTlat_i              : in  std_logic;
        TlastCnt_o             : out std_logic_vector(31 downto 0);
        TlastTO_i              : in  std_logic_vector(31 downto 0);
        TlastTOwritten_i       : in  std_logic;
        TDataCnt_o             : out std_logic_vector(31 downto 0);
        -- From Fifo to core/dma
        FifoRxDat_i            : in  std_logic_vector(63 downto 0);
        FifoRxRead_o           : out std_logic;
        FifoRxEmpty_i          : in  std_logic;
        FifoRxLastData_i       : in  std_logic;
        FifoRxResetBusy_i      : in  std_logic;
        -- From core/dma to Fifo
        FifoTxDat_o            : out std_logic_vector(31 downto 0);
        FifoTxWrite_o          : out std_logic;
        FifoTxLastData_o       : out std_logic;
        FifoTxFull_i           : in  std_logic;
        FifoTxResetBusy_i      : in  std_logic;
        -- Axi Stream I/f
        S_AXIS_TREADY          : out std_logic;
        S_AXIS_TDATA           : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST           : in  std_logic;
        S_AXIS_TVALID          : in  std_logic;
        M_AXIS_TVALID          : out std_logic;
        M_AXIS_TDATA           : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST           : out std_logic;
        M_AXIS_TREADY          : in  std_logic
    );
end entity axistream;

architecture rtl of axistream is

    constant DUMMY_DATA : std_logic_vector(31 downto 0) := X"F0CACC1A";
-- ASM
        type state_type is (idle, waitfifo, readdata, timeval, dataval, premature_end); 
        signal state, next_state : state_type; 
    
    signal i_M_AXIS_TVALID  : std_logic;
    signal i_M_AXIS_TLAST   : std_logic;  
    signal counterData      : std_logic_vector(15 downto 0);
    signal i_TlastCntRx     : std_logic_vector(15 downto 0);
    signal i_TlastCntTx     : std_logic_vector(15 downto 0);
    signal i_valid_read     : std_logic;
    signal i_valid_write    : std_logic;
    signal i_valid_lastread : std_logic;
    signal i_S_AXIS_TREADY  : std_logic;
    signal i_TDataCntRx     : std_logic_vector(15 downto 0);
    signal i_TDataCntTx     : std_logic_vector(15 downto 0);
    signal i_enable_ip      : std_logic;
    signal i_TlastTimer     : std_logic_vector(31 downto 0);
--    signal i_TlastTimerLock : std_logic;   
    signal i_timeexpired    : std_logic; 
    signal counterTest      : std_logic_vector(31 downto 0);
--    signal i_sent_a_couple  : std_logic;
    signal i_sent_an_event  : std_logic;

-- -----------------------------------------------------------------------------
-- DEBUG
attribute mark_debug : string;

-- -----------------------------------------------------------------------------

    
  begin 
    enable_p : process (Clk)
    begin
        if (Clk'event and Clk = '1') then
            if (nRst = '0') then
                i_enable_ip <= '0';
            else
                if (ResetStream_i='1') then
                    i_enable_ip <= '0';
                elsif (EnableAxistreamIf_i='0' and i_sent_an_event='0') then
                    i_enable_ip <= '0';
                else
                    if EnableAxistreamIf_i = '1' then
                        i_enable_ip <= '1';
                    -- The following is to finish the current burst regardless the Disable IP command from cpu
                    elsif (i_valid_lastread = '1') then
                        i_enable_ip <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process enable_p;

   -- Process counting data sent for closing correctly the tlast
   CountData_p: process (Clk)
   begin
      if (Clk'event and Clk = '1') then
         if (nRst = '0') then
            counterData <= (0 => '1', others => '0'); -- to 1
         else
            if ((counterData = DmaLength_i and i_valid_read='1') or (i_valid_lastread='1') )then
                counterData <= (0 => '1', others => '0');
            elsif (i_valid_read='1') then
                counterData <= counterData + "01";
            end if;
         end if;        
      end if;
   end process CountData_p;

-- At least a data couple has been sent when counterData>2
-- i_sent_a_couple <= '1' when counterData > std_logic_vector(to_unsigned(2,counterData'length)) else '0';


EVENT_SENT_PROC: process (Clk)
begin
   if (Clk'event and Clk = '1') then
      if (nRst = '0') then
         i_sent_an_event <= '0';
      else 
          if (i_valid_lastread='1') then
              i_sent_an_event <= '0';
          elsif (state=dataval and i_valid_read='1') then
              i_sent_an_event <= '1';
          end if;
      end if;        
   end if;
end process EVENT_SENT_PROC;


   
-- ASM that manages the timing of the Shared Multiplier

   SYNC_PROC: process (Clk)
   begin
      if (Clk'event and Clk = '1') then
         if (nRst = '0') then
            state <= idle;
         elsif (EnableAxistreamIf_i='0' and i_sent_an_event='0') then
            state <= idle;
         else
            state <= next_state;
         end if;        
      end if;
   end process SYNC_PROC;
 
   NEXT_STATE_DECODE: process (state, i_enable_ip, FifoRxEmpty_i, i_valid_read, EnableAxistreamIf_i,
                               i_valid_lastread, FifoRxLastData_i, i_timeexpired, DMA_test_mode_i, i_sent_an_event,
                               OnlyEventsRx_i, FifoRxResetBusy_i)
   begin
      case (state) is
      
        when idle =>
            if (i_enable_ip = '1') then
                next_state <= waitfifo;
            else 
                next_state <= idle;
			end if;
			
        when waitfifo =>
            if (i_timeexpired = '1' and i_sent_an_event='1') then
                next_state <= premature_end;
            elsif (FifoRxEmpty_i = '1' and DMA_test_mode_i = '0') then
                next_state <= waitfifo;
            elsif (OnlyEventsRx_i = '1') then
                next_state <= dataval;
            else
                next_state <= timeval;
            end if;
            
        when timeval =>
            if (i_valid_read = '1') then
                next_state <= dataval;
            elsif ((i_timeexpired = '1' and i_sent_an_event='1') or FifoRxResetBusy_i='1') then
                next_state <= premature_end;
            else 
                next_state <= timeval;
            end if;
            
        when dataval =>
            if (EnableAxistreamIf_i = '0' and i_valid_lastread = '1') then
                next_state <= idle;
            else
                if (i_valid_read = '1') then
                    if ((i_timeexpired = '1' and i_valid_lastread='0')  or FifoRxResetBusy_i='1') then
                        next_state <= premature_end;
                    elsif (FifoRxLastData_i = '1' and DMA_test_mode_i = '0') then
                        next_state <= waitfifo;
                    elsif (OnlyEventsRx_i = '1') then
                        next_state <= dataval;
                    else
                        next_state <= timeval;
                    end if;               
                else
                    next_state <= dataval;
                end if;
            end if; 
            
         when premature_end =>
            if (i_valid_lastread = '1') then
                next_state <= idle;
            else
                next_state <= premature_end;
            end if; 
                   
       when others =>
            next_state <= idle;
            
      end case;      
   end process NEXT_STATE_DECODE;

   i_M_AXIS_TVALID <= '1' when (state = timeval or state = dataval) else 
                      '1' when (state = premature_end) else '0';
   
   i_valid_read <= i_M_AXIS_TVALID and M_AXIS_TREADY;
   i_M_AXIS_TLAST <= '1' when (counterData = DmaLength_i and i_M_AXIS_TVALID = '1') else 
                     '1' when (state = premature_end) else '0';
   i_valid_lastread <= i_valid_read and i_M_AXIS_TLAST;
   M_AXIS_TVALID  <= i_M_AXIS_TVALID ;
   M_AXIS_TLAST   <= i_M_AXIS_TLAST;
   
   -- M_AXIS_TDATA   <= DUMMY_DATA when (state = premature_end) else 
   --                   FifoRxDat_i when (DMA_test_mode_i = '0') else
   --                   counterTest;

   M_AXIS_TDATA   <= DUMMY_DATA when (state = premature_end) else 
                     FifoRxDat_i (63 downto 32) when (DMA_test_mode_i = '0' and state = timeval) else
                     FifoRxDat_i (31 downto  0) when (DMA_test_mode_i = '0' and state = dataval) else
                     counterTest;

   -- FifoRxRead_o   <= '0' when (state = premature_end) else 
   --                     i_valid_read when (i_enable_ip = '1' and DMA_test_mode_i = '0') else
   --                     '0';
   
   FifoRxRead_o   <= '0' when (state = premature_end) else 
                       i_valid_read when (i_enable_ip = '1' and DMA_test_mode_i = '0' and state = dataval) else
                       '0';
     
   DMA_is_running_o <= i_enable_ip;
   
   -- Process counting data to be sent in test_mode
   counterTest_p: process (Clk)
   begin
      if (Clk'event and Clk = '1') then
         if (nRst = '0') then
            counterTest <= (others => '0'); 
         else
            if (i_valid_read='1' and DMA_test_mode_i = '1' and state /= premature_end) then
                counterTest <= counterTest + "01";
            end if;
         end if;        
      end if;
   end process counterTest_p;

   tlast_cnt_rx_p :  process (Clk)
     begin
        if (Clk'event and Clk = '1') then
           if (nRst = '0') then
              i_TlastCntRx <= (others => '0');
           else
              if (i_M_AXIS_TLAST = '1' and i_M_AXIS_TVALID = '1' and M_AXIS_TREADY ='1') then
                i_TlastCntRx <= i_TlastCntRx + "01";
              end if;
           end if;        
        end if;
     end process tlast_cnt_rx_p;
   
   tlast_cnt_tx_p :  process (Clk)
       begin
          if (Clk'event and Clk = '1') then
             if (nRst = '0') then
                i_TlastCntTx <= (others => '0');
             else
                if (S_AXIS_TLAST = '1' and S_AXIS_TVALID = '1' and i_S_AXIS_TREADY ='1') then
                  i_TlastCntTx <= i_TlastCntTx + "01";
                end if;
             end if;        
          end if;
       end process tlast_cnt_tx_p;
     
   TlastCnt_o <= i_TlastCntRx & i_TlastCntTx;
   
   
   i_valid_write <= i_S_AXIS_TREADY and S_AXIS_TVALID;

   tdata_cnt_rx_p :  process (Clk)
     begin
        if (Clk'event and Clk = '1') then
           if (nRst = '0') then
              i_TDataCntRx <= (others => '0');
           else
              if (i_valid_read ='1') then
                i_TDataCntRx <= i_TDataCntRx + "01";
              end if;
           end if;        
        end if;
     end process tdata_cnt_rx_p;
   
   tdata_cnt_tx_p :  process (Clk)
       begin
          if (Clk'event and Clk = '1') then
             if (nRst = '0') then
                i_TDataCntTx <= (others => '0');
             else
                if (i_valid_write ='1') then
                  i_TDataCntTx <= i_TDataCntTx + "01";
                end if;
             end if;        
          end if;
   end process tdata_cnt_tx_p;
     
   TDataCnt_o <= i_TDataCntRx & i_TDataCntTx;
   
--   -- Issue a premature end of a burst is the timeout expires and we have sent at least one data couple
--   -- When no data have been received but the timeout expired, then sent the received data and then the dummy data
--   tlasttimerlock_p : process (Clk)
--   begin
--   if (Clk'event and Clk = '1') then
--        if (nRst = '0' or i_enable_ip='0' or TlastTOwritten_i='1') then
--            i_TlastTimerLock <= '1';
--        elsif (LatTlat_i='1') then
--            if (i_valid_read='1') then
--                i_TlastTimerLock <= '0';
--            end if;
--        end if;
--       end if;
--   end process tlasttimerlock_p;
--
--   tlasttimer_p : process (Clk)
--   begin
--   if (Clk'event and Clk = '1') then
--        if (nRst = '0' or i_enable_ip='0' or TlastTOwritten_i='1') then
--            i_TlastTimer <= (others => '1');
--            i_timeexpired <= '0';
--        elsif (LatTlat_i='1') then
--            if (i_valid_lastread='1' or i_TlastTimerLock='1') then
--                i_TlastTimer <= TlastTO_i;
--                i_timeexpired <= '0';
--            elsif (i_TlastTimer/=x"00000000") then
--                i_TlastTimer <= i_TlastTimer - "01";
--                i_timeexpired <= '0';
--            else
--                i_timeexpired <= '1';
--            end if;
--        end if;
--       end if;
--   end process tlasttimer_p;





   -- Issue a premature end of a burst is the timeout expires and we have sent at least one data couple
   -- When no data have been received but the timeout expired, then sent the received data and then the dummy data
   tlasttimer_p : process (Clk)
   begin
      
       if (Clk'event and Clk = '1') then
        if (nRst = '0' or i_enable_ip='0' or TlastTOwritten_i='1') then
            i_TlastTimer <= (others => '0');
            i_timeexpired <= '0';
        elsif (LatTlat_i='1') then
            if (i_valid_lastread='1') then
                i_TlastTimer <= (others => '0');
                i_timeexpired <= '0';
            elsif (i_TlastTimer/=TlastTO_i) then
                i_TlastTimer <= i_TlastTimer + "01";
                i_timeexpired <= '0';
            else
                i_timeexpired <= '1';
            end if;
        end if;
       end if;
   end process tlasttimer_p;



   
-- For TX FIFO
    i_S_AXIS_TREADY  <= not(FifoTxFull_i) and i_enable_ip;
    FifoTxDat_o       <= S_AXIS_TDATA;
    FifoTxWrite_o     <= (not(FifoTxFull_i) and S_AXIS_TVALID) and i_enable_ip;
    FifoTxLastData_o  <= (not(FifoTxFull_i) and S_AXIS_TVALID and S_AXIS_TLAST) and i_enable_ip;
    S_AXIS_TREADY     <= i_S_AXIS_TREADY;

--    -- DEBUG


end architecture rtl;
-------------------------------------------------------------------------------
