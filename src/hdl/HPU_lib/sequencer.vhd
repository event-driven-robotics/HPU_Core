-------------------------------------------------------------------------------
-- Sequencer
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Enable_xSI
-------------------------------------------------------------------------------
-- if Enable_xSI is deasserted, we discard on fifo element per cycle to get rid
-- of unused fifo content.
--
-- why not reset the FIFO to clear it instantly instead of
-- consuming on event per cycle only..?
-- because this might cause massive trouble with the writing end
-- of the fifo (fx2if)...
-------------------------------------------------------------------------------


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;
    
--****************************
--   PORT DECLARATION
--****************************

entity sequencer is
    port (
        Rst_n_i             : in  std_logic;
        Clk_i               : in  std_logic;
        Enable_i            : in  std_logic;
        --                  
        En100us_i           : in  std_logic;
        --                  
        TSMode_i            : in  std_logic_vector(1 downto 0);
        TSTimeoutSel_i      : in  std_logic_vector(3 downto 0);
        TSMaskSel_i         : in  std_logic_vector(1 downto 0);
        --                  
        Timestamp_i         : in  std_logic_vector(31 downto 0);
        LoadTimer_o         : out std_logic;
        LoadValue_o         : out std_logic_vector(31 downto 0);
        TxTSRetrigCmd_i     : in  std_logic;
        TxTSRearmCmd_i      : in  std_logic;
        TxTSRetrigStatus_o  : out std_logic;
        TxTSTimeoutCounts_o : out std_logic;
        --                  
        InAddrEvt_i         : in  std_logic_vector(63 downto 0);
        InRead_o            : out std_logic;
        InEmpty_i           : in  std_logic;
        --                  
        OutAddr_o           : out std_logic_vector(31 downto 0);
        OutSrcRdy_o         : out std_logic;
        OutDstRdy_i         : in  std_logic
        --                  
        -- ConfigAddr_o     : out std_logic_vector(31 downto 0);
        -- ConfigReq_o      : out std_logic;
        -- ConfigAck_i      : in  std_logic
    );

end entity sequencer;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of sequencer is


  
    --type   state is (stIdle, stWaitDelta, stSend, stWait, stConfigReq, stConfigAck);
    type   state is (stIdle, stWaitDelta, stSend);
    signal State_xDP, State_xDN : state;

    signal Address_xDP, Address_xDN : std_logic_vector(31 downto 0);
    signal Delta_xDP, Delta_xDN     : unsigned(31 downto 0);
    
    signal NetxTime_xDP, NetxTime_xDN : unsigned(31 downto 0);
    signal LastTime_xDP, LastTime_xDN : unsigned(31 downto 0);
    signal NowTime_xDP, NowTime_xDN   : unsigned(31 downto 0);
    signal NmL_xDP, NmL_xDN           : unsigned(31 downto 0);
    signal NmA_xDP, NmA_xDN           : unsigned(31 downto 0);
    signal AmL_xDP, AmL_xDN           : unsigned(31 downto 0);
    signal combo                      : unsigned(2 downto 0);

        
    signal TimestampPrev_xD  : std_logic_vector(31 downto 0);
    signal timeout           : std_logic;
    signal TSTimeout_cnt     : unsigned(23 downto 0);
    signal TSTimeout_cnt_tcn : std_logic;
    signal TimestampMskd     : std_logic_vector(31 downto 0);
    signal TSMask            : std_logic_vector(31 downto 0);
    signal TSTimeoutEnable   : std_logic;
    
    type rom_array is array (0 to 15) of unsigned (23 downto 0);
    constant Timeout_Table : rom_array := ( conv_unsigned(      1_0, 24),  -- Address 0   :       1.0 ms
                                            conv_unsigned(      5_0, 24),  -- Address 1   :       5.0 ms
                                            conv_unsigned(     10_0, 24),  -- Address 2   :      10.0 ms
                                            conv_unsigned(     50_0, 24),  -- Address 3   :      50.0 ms
                                            conv_unsigned(    100_0, 24),  -- Address 4   :     100.0 ms
                                            conv_unsigned(    500_0, 24),  -- Address 5   :     500.0 ms
                                            conv_unsigned(   1000_0, 24),  -- Address 6   :    1000.0 ms
                                            conv_unsigned(   2500_0, 24),  -- Address 7   :    2500.0 ms
                                            conv_unsigned(   5000_0, 24),  -- Address 8   :    5000.0 ms
                                            conv_unsigned(  10000_0, 24),  -- Address 9   :   10000.0 ms
                                            conv_unsigned(  25000_0, 24),  -- Address A   :   25000.0 ms
                                            conv_unsigned(  50000_0, 24),  -- Address B   :   50000.0 ms
                                            conv_unsigned( 100000_0, 24),  -- Address C   :  100000.0 ms
                                            conv_unsigned( 250000_0, 24),  -- Address D   :  250000.0 ms
                                            conv_unsigned( 500000_0, 24),  -- Address E   :  500000.0 ms
                                            conv_unsigned(1000000_0, 24)   -- Address F   : 1000000.0 ms   -- NOTE: this selection DISABLES the timeout timer (see at "resync_timeout_counter" process)
                                            );

    signal timeout_sel   : integer range 0 to 15;
    signal timeout_value : unsigned (23 downto 0);
    signal SendPending   : std_logic; 
    signal SendPending_d : std_logic; 
    signal timeout_rearm : std_logic;
    signal StateIsIdle   : std_logic;
    signal StateIsWaitDelta   : std_logic;
    signal StateIsSend   : std_logic;
    
begin

    TimestampMskd <= Timestamp_i and TSMask;
    
    NmL_xDN <= NetxTime_xDN            + unsigned(not std_logic_vector(LastTime_xDN)) + 1;
    NmA_xDN <= NetxTime_xDN            + unsigned(not TimestampMskd);
    AmL_xDN <= unsigned(TimestampMskd) + unsigned(not std_logic_vector(LastTime_xDN)) + 1;
    combo   <= NmL_xDN(31) & NmA_xDN(31) & AmL_xDN(31);

    -- wiring
    OutAddr_o    <= Address_xDP;
    --ConfigAddr_xDO <= Address_xDP;

    --p_next : process (Address_xDN, Address_xDP, ConfigAck_xSI, Delta_xDN, Delta_xDP,
    p_next : process (Address_xDP, Delta_xDN, Delta_xDP,
                      Enable_i, InAddrEvt_i, InEmpty_i, OutDstRdy_i,
                      State_xDP, TimestampPrev_xD, TimestampMskd,
                      NetxTime_xDP, NetxTime_xDN, combo, LastTime_xDP, TSTimeout_cnt_tcn,
                      TSMode_i, TSMask, timeout
                      )
    begin

        -- defaults
        State_xDN    <= State_xDP;
        Address_xDN  <= Address_xDP;
        Delta_xDN    <= Delta_xDP;
        
        NetxTime_xDN <= NetxTime_xDP;
        LastTime_xDN <= LastTime_xDP;

        InRead_o     <= '0';
        OutSrcRdy_o  <= '0';
        
        LoadTimer_o  <= '0';
        SendPending  <= '0';

        --ConfigReq_xSO <= '0';

        case (State_xDP) is
            when stIdle =>

                if (Enable_i = '1') then

                    if (InEmpty_i = '0') then
                        Delta_xDN   <= unsigned(InAddrEvt_i(63 downto 32));
                        Address_xDN <= InAddrEvt_i(31 downto 0);
                        InRead_o    <= '1';
                        
                        NetxTime_xDN <= unsigned(InAddrEvt_i(63 downto 32) and TSMask);
                        LastTime_xDN <= NetxTime_xDP;

                        if (TSMode_i = "00") then  -- Old Mode (Delta Time)
                            -- if Delta_xDN is not zero we go to the stWaitDelta state, otherwise we send now...
                            if (Delta_xDN /= 0) then
                                State_xDN <= stWaitDelta;
                            else
                                -- address or config..?
                                --if (Address_xDN(31) = '0') then
                                    State_xDN <= stSend;
                                --else
                                --    State_xDN <= stConfigReq;
                                --end if;
                            end if;
                         
                         elsif (TSMode_i = "01") then  -- (Send immediatly)
                             
                             State_xDN <= stSend;
                            
                         elsif (TSMode_i = "10") then  -- (Absolute Time)
                             
                             if ((combo = 0 or combo = 6 or combo = 5) and timeout = '0') then
                                 State_xDN <= stWaitDelta;
                             else 
                                 State_xDN <= stSend;
                                 LoadTimer_o <= timeout;
                             end if;
                         
                         else 
                             State_xDN <= stIdle;
                         end if;
                        
                    end if;

                else
                    -- not Enable_xSI
                    -- discard pending sequencer data if not enabled:
                    InRead_o <= not InEmpty_i;
                end if;
            
            when stWaitDelta =>

                if (Enable_i = '1') then
                    if (TSMode_i = "00") then  -- Old Mode (Delta Time)
                        -- already zero? transmit or keep counting
                        if (Delta_xDP = 0) then
                            -- address or config..?
                            --if (Address_xDP(31) = '0') then
                                State_xDN <= stSend;
                            --else
                            --    State_xDN <= stConfigReq;
                            --end if;                    
                        else
                            if (TimestampPrev_xD /= TimestampMskd) then
                                Delta_xDN <= Delta_xDP - 1;
                            end if;
                        end if;
                    
                    elsif (TSMode_i = "01") then  
                    
                        State_xDN <= stIdle;
                    
                    elsif (TSMode_i = "10") then 
                        if (unsigned(TimestampMskd) = NetxTime_xDN) then
                            State_xDN <= stSend;
                        else 
                            State_xDN <= stWaitDelta;
                        end if;
                    
                    else
                        State_xDN <= stIdle;
                        
                    end if;
                else
                    -- not Enable_xSI
                    State_xDN <= stIdle;
                end if;
            
            when stSend =>

                SendPending   <= '1';
                OutSrcRdy_o   <= '1';
                
                if (OutDstRdy_i = '1') then
            --        State_xDN <= stWait; -- ADDED -=FD=-
            --    end if; -- ADDED -=FD=-
            --
            --when stWait => -- ADDED -=FD=-
            --    -- Wait that the request has been acknowledged
            --    
            --    if (OutDstRdy_xSI = '0') then -- ADDED -=FD=-
                    State_xDN <= stIdle; 
                end if; 

            --when stConfigReq =>
            --
            --    -- set REQ, wait for ACK
            --    ConfigReq_xSO <= '1';
            --    if (ConfigAck_xSI = '0') then
            --        -- stay
            --    else
            --        State_xDN <= stConfigAck;
            --    end if;
            --
            --when stConfigAck =>
            --
            --    -- clear REQ, wait for ACK clear
            --    if (ConfigAck_xSI = '1') then
            --        -- stay
            --    else
            --        State_xDN <= stIdle;
            --    end if;

            when others => null;
          
        end case;
        
    end process p_next;

    -----------------------------------------------------------------------------

    p_state : process (Clk_i, Rst_n_i)
    begin
        if (Rst_n_i = '0') then               -- asynchronous reset (active low)
            State_xDP        <= stIdle;
            Address_xDP      <= (others => '0');
            Delta_xDP        <= (others => '0');
            TimestampPrev_xD <= (others => '0');
            
            NetxTime_xDP     <= (others => '0');
            LastTime_xDP     <= (others => '0');
            NmL_xDP          <= (others => '0');
            NmA_xDP          <= (others => '0');
            AmL_xDP          <= (others => '0');
            
            SendPending_d    <= '0';
            
          
        elsif (rising_edge(Clk_i)) then  -- rising clock edge
            State_xDP        <= State_xDN;
            Address_xDP      <= Address_xDN;
            Delta_xDP        <= Delta_xDN;
            TimestampPrev_xD <= TimestampMskd;
            
            NetxTime_xDP     <= NetxTime_xDN;
            LastTime_xDP     <= LastTime_xDN;
            NmL_xDP          <= NmL_xDN;
            NmA_xDP          <= NmA_xDN;
            AmL_xDP          <= AmL_xDN;      
            
            SendPending_d    <= SendPending;      
          
        end if;
    end process p_state;
    
    -----------------------------------------------------------------------------
    -- RESYNC
    
    LoadValue_o <= std_logic_vector(NetxTime_xDN);                                                -- Value to be forced in TimeStamp TX
    timeout_rearm <= not SendPending and SendPending_d;                                             -- Timeout counter rearm signal
    TSTimeout_cnt_tcn <= '1' when (TSTimeout_cnt = conv_unsigned(0, TSTimeout_cnt'length)) else '0'; -- Terminal Count, at Zero

    TxTSRetrigStatus_o <= timeout;                                                                 -- Reply of Timeout internal signal
    timeout_sel <= conv_integer(unsigned(TSTimeoutSel_i));                                         -- Timeout value selector
    timeout_value <= Timeout_Table(timeout_sel);                                                     -- Timeout value frome table
    timeout <=  TSTimeout_cnt_tcn;                                                                   -- Timeout internal signal
    TSTimeoutEnable <= '0' when (TSTimeoutSel_i = x"F") else '1';
    StateIsIdle <= '1' when (State_xDP = stIdle) else '0';
    StateIsWaitDelta <= '1' when (State_xDP = stWaitDelta) else '0';
    StateIsSend <= '1' when (State_xDP = stSend) else '0';
    
        resync_timeout_counter : process (Clk_i, Rst_n_i)
        begin
            if (Rst_n_i = '0') then           -- asynchronous reset (active low)
                TSTimeout_cnt        <= conv_unsigned(0, TSTimeout_cnt'length);
                TxTSTimeoutCounts_o  <= '0';
                
            elsif (rising_edge(Clk_i)) then  -- rising clock edge
                if (TxTSRetrigCmd_i = '1') then
                    TSTimeout_cnt  <= conv_unsigned(0, TSTimeout_cnt'length);
                elsif (timeout_rearm = '1' or StateIsIdle = '0' or TxTSRearmCmd_i = '1' or TSTimeoutEnable = '0') then
                    TSTimeout_cnt  <= timeout_value;
                elsif (En100us_i = '1' and TSTimeout_cnt_tcn = '0' and InEmpty_i = '1') then
                    TSTimeout_cnt  <= TSTimeout_cnt - 1;
                end if;    
                
                TxTSTimeoutCounts_o <= StateIsIdle and TSTimeoutEnable and not TSTimeout_cnt_tcn and InEmpty_i; 
              
            end if;
        end process resync_timeout_counter;


    ----------------------------------------------------------------------------
    -- Implement TX Timestamp Mask value selection

    p_TSMask : process (Clk_i, Rst_n_i)
    begin
        if (Rst_n_i = '0') then
                TSMask <= (others => '0');
            
        elsif (rising_edge(Clk_i)) then
            case TSMaskSel_i is 
                when "00"    => TSMask <= x"000FFFFF";
                when "01"    => TSMask <= x"00FFFFFF";
                when "10"    => TSMask <= x"0FFFFFFF";
                when "11"    => TSMask <= x"FFFFFFFF";
                when others  => TSMask <= x"FFFFFFFF";
            end case;
        end if;
    end process p_TSMask;       
     
end architecture beh;

