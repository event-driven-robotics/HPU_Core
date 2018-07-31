-------------------------------------------------------------------------------
-- AEXSsequencerRR
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
    use ieee.numeric_std.all;

    
--****************************
--   PORT DECLARATION
--****************************

entity AEXSsequencerRR is
    generic (
        TestEnableSequencerNoWait : boolean
    );
    port (
        Rst_xRBI       : in  std_logic;
        Clk_xCI        : in  std_logic;
        Enable_xSI     : in  std_logic;
        --
        Timestamp_xDI  : in  std_logic_vector(31 downto 0);
        --
        InAddrEvt_xDI  : in  std_logic_vector(63 downto 0);
        InRead_xSO     : out std_logic;
        InEmpty_xSI    : in  std_logic;
        --
        OutAddr_xDO    : out std_logic_vector(31 downto 0);
        OutSrcRdy_xSO  : out std_logic;
        OutDstRdy_xSI  : in  std_logic
        --
        --ConfigAddr_xDO : out std_logic_vector(31 downto 0);
        --ConfigReq_xSO  : out std_logic;
        --ConfigAck_xSI  : in  std_logic
    );

end entity AEXSsequencerRR;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of AEXSsequencerRR is
  
    --type   state is (stIdle, stWaitDelta, stSend, stWait, stConfigReq, stConfigAck);
    type   state is (stIdle, stWaitDelta, stSend);
    signal State_xDP, State_xDN : state;

    signal Address_xDP, Address_xDN : std_logic_vector(31 downto 0);
    signal Delta_xDP, Delta_xDN     : unsigned(31 downto 0);

    signal TimestampPrev_xD : std_logic_vector(31 downto 0);
  
begin

    -- wiring
    OutAddr_xDO    <= Address_xDP;
    --ConfigAddr_xDO <= Address_xDP;

    --p_next : process (Address_xDN, Address_xDP, ConfigAck_xSI, Delta_xDN, Delta_xDP,
    p_next : process (Address_xDP, Delta_xDN, Delta_xDP,
                      Enable_xSI, InAddrEvt_xDI, InEmpty_xSI, OutDstRdy_xSI,
                      State_xDP, TimestampPrev_xD, Timestamp_xDI)
    begin

        -- defaults
        State_xDN   <= State_xDP;
        Address_xDN <= Address_xDP;
        Delta_xDN   <= Delta_xDP;

        InRead_xSO    <= '0';
        OutSrcRdy_xSO <= '0';

        --ConfigReq_xSO <= '0';

        case (State_xDP) is
            when stIdle =>

                if (Enable_xSI = '1') then

                    if (InEmpty_xSI = '0') then
                        Delta_xDN   <= unsigned(InAddrEvt_xDI(63 downto 32));
                        Address_xDN <= InAddrEvt_xDI(31 downto 0);
                        InRead_xSO  <= '1';

                        -- if we have a zero ISI or TestEnableSequencerNoWait
                        -- we go to the stWaitDelta state, otherwise we send now...
                        if (Delta_xDN /= 0 and not TestEnableSequencerNoWait) then
                            State_xDN <= stWaitDelta;
                        else
                            -- address or config..?
                            --if (Address_xDN(31) = '0') then
                                State_xDN <= stSend;
                            --else
                            --    State_xDN <= stConfigReq;
                            --end if;
                        end if;
                    end if;

                else
                    -- not Enable_xSI
                    -- discard pending sequencer data if not enabled:
                    InRead_xSO <= not InEmpty_xSI;
                end if;
            
            when stWaitDelta =>

                if (Enable_xSI = '1') then

                    -- already zero? transmit or keep counting
                    if (Delta_xDP = 0) then
                        -- address or config..?
                        --if (Address_xDP(31) = '0') then
                            State_xDN <= stSend;
                        --else
                        --    State_xDN <= stConfigReq;
                        --end if;                    
                    else
                        if (TimestampPrev_xD /= Timestamp_xDI) then
                            Delta_xDN <= Delta_xDP - 1;
                        end if;
                    end if;

                else
                    -- not Enable_xSI
                    State_xDN <= stIdle;
                end if;
            
            when stSend =>

                OutSrcRdy_xSO <= '1';

                if (OutDstRdy_xSI = '1') then
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

    p_state : process (Clk_xCI, Rst_xRBI)
    begin
        if (Rst_xRBI = '0') then               -- asynchronous reset (active low)
            State_xDP        <= stIdle;
            Address_xDP      <= (others => '0');
            Delta_xDP        <= (others => '0');
            TimestampPrev_xD <= (others => '0');
          
        elsif (rising_edge(Clk_xCI)) then  -- rising clock edge
            State_xDP        <= State_xDN;
            Address_xDP      <= Address_xDN;
            Delta_xDP        <= Delta_xDN;
            TimestampPrev_xD <= Timestamp_xDI;
          
        end if;
    end process p_state;

    
end architecture beh;

-------------------------------------------------------------------------------
