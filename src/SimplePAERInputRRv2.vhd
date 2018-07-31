-------------------------------------------------------------------------------
-- SimplePAERInputRRv2
-------------------------------------------------------------------------------

-- data_on_req_release:
--
-- if false, data is sampled as soon as a valid assertion of req is detected,
-- if false, data is only sampled as soon as req is detected to be deasserted
-- again, i.e. in SCX protocol
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
library datapath_lib;
    use datapath_lib.DPComponents_pkg.all;


--****************************
--   PORT DECLARATION
--****************************

entity SimplePAERInputRRv2 is
    generic (
        paer_width          : positive := 16;
        internal_width      : positive := 32;
        --data_on_req_release : boolean  := false;
        input_fifo_depth    : positive := 1
    );
    port (
        -- clk rst
        ClkxCI           : in  std_logic;
        RstxRBI          : in  std_logic;
        EnableIp         : in  std_logic;
        FlushFifo        : in  std_logic;
        IgnoreFifoFull_i : in  std_logic;

        -- parallel AER
        AerReqxAI    : in  std_logic;
        AerAckxSO    : out std_logic;
        AerDataxADI  : in  std_logic_vector(paer_width-1 downto 0);

        -- configuration
        AerHighBitsxDI       : in  std_logic_vector(internal_width-1-paer_width downto 0);
        --AerReqActiveLevelxDI : in  std_logic;
        --AerAckActiveLevelxDI : in  std_logic;
        CfgAckSetDelay_i     : in  std_logic_vector(7 downto 0);
        CfgSampleDelay_i     : in  std_logic_vector(7 downto 0);
        CfgAckRelDelay_i     : in  std_logic_vector(7 downto 0);

        -- output
        OutDataxDO   : out std_logic_vector(internal_width-1 downto 0);
        OutSrcRdyxSO : out std_logic;
        OutDstRdyxSI : in  std_logic;
        -- Fifo Full signal
        FifoFullxSO  : out std_logic;
        -- dbg
        dbg_dataOk   : out std_logic
    );
end SimplePAERInputRRv2;


--****************************
--   IMPLEMENTATION
--****************************

architecture rtl of SimplePAERInputRRv2 is

    signal AerAckxS           : std_logic;
    signal AerReqMetaxS       : std_logic;
    signal AerReqStablexS     : std_logic;
    signal counter            : unsigned(8 downto 0);
    signal FifoInpDataxD      : std_logic_vector(internal_width-1 downto 0);
    signal FifoInpWritexS     : std_logic;
    signal FifoFullxS         : std_logic;
    signal i_fiforstn         : std_logic;
    signal i_fifoReady        : std_logic;

begin

    p_aerReqMeta : process (ClkxCI, RstxRBI)
    begin
        if (RstxRBI = '0') then               -- asynchronous reset (active low)
            AerReqMetaxS   <= '0';
            AerReqStablexS <= '0';
        elsif (rising_edge(ClkxCI)) then      -- rising clock edge
            AerReqMetaxS   <= AerReqxAI;
            AerReqStablexS <= AerReqMetaxS;
        end if;
    end process p_aerReqMeta;

    i_fiforstn <= RstxRBI and not(FlushFifo);

    iShiftRegFifoRROut : ShiftRegFifoRROut
        generic map (
            width           => internal_width,
            depth           => input_fifo_depth,
            full_fifo_reset => true
        )
        port map (
            ClockxCI        => ClkxCI,
            ResetxRBI       => i_fiforstn,
            --
            InpDataxDI      => FifoInpDataxD,
            InpWritexSI     => FifoInpWritexS,
            --
            OutDataxDO      => OutDataxDO,
            OutSrcRdyxSO    => OutSrcRdyxSO,
            OutDstRdyxSI    => OutDstRdyxSI,
            --
            EmptyxSO        => open,
            AlmostEmptyxSO  => open,
            AlmostFullxSO   => open,
            FullxSO         => FifoFullxS,
            OverflowxSO     => open
        );

    -- fifo data wiring
    FifoInpDataxD(internal_width-1 downto paer_width) <= AerHighBitsxDI;
    FifoInpDataxD(paer_width-1 downto 0)              <= AerDataxADI;

    
    -- If IgnoreFifoFull_i is High the request is always granted
    i_fifoReady <= IgnoreFifoFull_i or not FifoFullxS;
    
    ack_proc : process (ClkxCI, RstxRBI)
    begin
        if (RstxRBI = '0') then               -- asynchronous reset (active low)
            AerAckxS <= '0';
        elsif (rising_edge(ClkxCI)) then      -- rising clock edge
            if (EnableIp = '0') then
                AerAckxS <= '0';
            else
                if (counter = unsigned(CfgAckRelDelay_i)) then
                    AerAckxS <= AerReqStablexS;
                --elsif (counter = unsigned(CfgAckSetDelay_i)) then
                --    AerAckxS <= AerReqStablexS and i_fifoReady;
                elsif (counter = unsigned(CfgAckSetDelay_i)) then
                    AerAckxS <= AerReqStablexS;
                end if;
            end if;
        end if;
    end process ack_proc;

    AerAckxSO <= AerAckxS;


    -- Counter used to set the sampling of the input data
    counter_proc : process (ClkxCI, RstxRBI)
    begin
        if (RstxRBI = '0') then               -- asynchronous reset (active low)
            counter <= "000000000";
        elsif (rising_edge(ClkxCI)) then      -- rising clock edge
            if (EnableIP = '0') then
                counter <= "000000000";
            else
                if ((i_fifoReady = '0' or AerReqStablexS = '0') and AerAckxS = '0') then
                    counter <= "000000000";
                elsif (counter = "100000000") then
                    counter <= "100000000";
                --elsif (counter = unsigned(CfgAckSetDelay_i) and i_fifoReady = '0') then
                --    counter <= counter;
                elsif (counter = unsigned(CfgAckRelDelay_i)) then
                    counter <= counter;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process counter_proc;


    FifoInpWritexS <= EnableIp when counter = unsigned(CfgSampleDelay_i) else
                      '0';

    dbg_dataOk <= FifoInpWritexS;
    FifoFullxSO <= FifoFullxS;

end rtl;

-------------------------------------------------------------------------------
