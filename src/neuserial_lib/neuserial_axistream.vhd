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

entity neuserial_axistream is
    generic (
        C_NUMBER_OF_INPUT_WORDS : natural := 2048;
        C_DEBUG                 : boolean := false
    );
    port (
        Clk                    : in  std_logic;
        nRst                   : in  std_logic;
        --                    
        DMA_test_mode_i        : in  std_logic;
        EnableAxistreamIf_i    : in  std_logic;
        DMA_is_running_o       : out std_logic;
        DmaLength_i            : in  std_logic_vector(10 downto 0);
        ResetStream_i          : in  std_logic;
        LatTlat_i              : in  std_logic;
        TlastCnt_o             : out std_logic_vector(31 downto 0);
        TlastTO_i              : in  std_logic_vector(31 downto 0);
        TDataCnt_o             : out std_logic_vector(31 downto 0);
        -- From Fifo to core/dma
        FifoCoreDat_i          : in  std_logic_vector(31 downto 0);
        FifoCoreRead_o         : out std_logic;
        FifoCoreEmpty_i        : in  std_logic;
        FifoCoreBurstReady_i   : in  std_logic;
        FifoCoreLastData_i     : in  std_logic;
        -- From core/dma to Fifo
        CoreFifoDat_o          : out std_logic_vector(31 downto 0);
        CoreFifoWrite_o        : out std_logic;
        CoreFifoFull_i         : in  std_logic;
        -- Axi Stream I/f
        S_AXIS_TREADY          : out std_logic;
        S_AXIS_TDATA           : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST           : in  std_logic;
        S_AXIS_TVALID          : in  std_logic;
        M_AXIS_TVALID          : out std_logic;
        M_AXIS_TDATA           : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST           : out std_logic;
        M_AXIS_TREADY          : in  std_logic;
        
        -- DBG
        DBG_data_written       : out std_logic;
        DBG_dma_burst_counter  : out std_logic_vector(10 downto 0);
        DBG_dma_test_mode      : out std_logic;
        DBG_dma_EnableDma      : out std_logic;
        DBG_dma_is_running     : out std_logic;
        DBG_dma_Length         : out std_logic_vector(10 downto 0);
        DBG_dma_nedge_run      : out std_logic
    );
end entity neuserial_axistream;

architecture rtl of neuserial_axistream is

    constant DUMMY_DATA : std_logic_vector(31 downto 0) := X"F0CACC1A";
-- ASM
        type state_type is (idle, waitfifo, readdata, timeval, dataval, premature_end); 
        signal state, next_state : state_type; 
    
    signal i_M_AXIS_TVALID  : std_logic;
    signal i_M_AXIS_TLAST   : std_logic;  
    signal counterData      : std_logic_vector(10 downto 0);
    signal i_DMA_running    : std_logic;
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
    signal i_timeexpired    : std_logic; 
    
  begin 
    enable_p : process (Clk)
    begin
        if (Clk'event and Clk = '1') then
            if (nRst = '0') then
                i_enable_ip <= '0';
            else
                if (ResetStream_i='1') then
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

   
-- ASM that manages the timing of the Shared Multiplier

   SYNC_PROC: process (Clk)
   begin
      if (Clk'event and Clk = '1') then
         if (nRst = '0') then
            state <= idle;
         else
            state <= next_state;
         end if;        
      end if;
   end process SYNC_PROC;
 
   NEXT_STATE_DECODE: process (state, i_enable_ip, FifoCoreEmpty_i, i_valid_read, EnableAxistreamIf_i,
                               i_valid_lastread, FifoCoreLastData_i, i_timeexpired)
   begin
      case (state) is
      
        when idle =>
            if (i_enable_ip = '1') then
                next_state <= waitfifo;
            else 
                next_state <= idle;
			end if;
			
        when waitfifo =>
            if (FifoCoreEmpty_i = '1') then
                next_state <= waitfifo;
            else
                next_state <= timeval;
            end if;
            
        when timeval =>
            if (i_valid_read = '1') then
                next_state <= dataval;
            else 
                next_state <= timeval;
            end if;
            
        when dataval =>
            if (EnableAxistreamIf_i = '0' and i_valid_lastread='1') then
                next_state <= idle;
            else
                if (i_valid_read = '1') then
                    if (FifoCoreLastData_i = '1') then
                        next_state <= waitfifo;
                    elsif (i_timeexpired = '1' and i_valid_lastread='0') then
                        next_state <= premature_end;
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
   M_AXIS_TDATA   <= DUMMY_DATA when (state = premature_end) else FifoCoreDat_i;

   FifoCoreRead_o   <= '0' when (state = premature_end) else i_valid_read;
   DMA_is_running_o <= i_enable_ip;
   
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
   
   -- Issue a premature end of a burst is the timeout expires and we have sent at least one data couple
   -- When no data have been received but the timeout expired, then sent the received data and then the dummy data
   tlasttimer_p : process (Clk)
   begin
      
       if (Clk'event and Clk = '1') then
        if (nRst = '0') then
             i_TlastTimer <= (others => '0');
             i_timeexpired <= '0';
        elsif (Clk'event and Clk = '1') then
           if (LatTlat_i='1') then
               if (i_valid_lastread='1') then
                   i_TlastTimer <= (others => '0');
                   i_timeexpired <= '0';
               elsif (i_TlastTimer/=TlastTO_i) then
                   i_TlastTimer <= i_TlastTimer + "01";
                   i_timeexpired <= '0';
                   if (i_valid_read='1') then
                   end if;
               else
                   i_timeexpired <= '1';
               end if;
           end if;
         end if;
       end if;
   end process tlasttimer_p;

   
   
-- For TX FIFO
    i_S_AXIS_TREADY  <= not(CoreFifoFull_i) and i_enable_ip;
    CoreFifoDat_o    <= S_AXIS_TDATA;
    CoreFifoWrite_o  <= (not(CoreFifoFull_i) and S_AXIS_TVALID) and i_enable_ip;
    S_AXIS_TREADY    <= i_S_AXIS_TREADY;

--    -- DEBUG
    
--    DBG_data_written <= i_M_AXIS_TVALID and M_AXIS_TREADY;


end architecture rtl;
-------------------------------------------------------------------------------
