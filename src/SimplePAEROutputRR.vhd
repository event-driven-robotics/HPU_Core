--------------------------------------------------------------------------------
-- SimplePAEROutputRR
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    
library datapath_lib;
    use datapath_lib.DPComponents_pkg.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity SimplePAEROutputRR is
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

    -- input
    InpDataxDI   : in  std_logic_vector(internal_width-1 downto 0);
    InpSrcRdyxSI : in  std_logic;
    InpDstRdyxSO : out std_logic
    );

end SimplePAEROutputRR;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture rtl of SimplePAEROutputRR is

  type   state is (stWaitData, stWaitAckAssert, stWaitAckRelease);
  signal StatexDP, StatexDN : state;
  --
  signal AerAckxA           : std_logic;
  signal AerAckStabilizedxS : std_logic;
  --
  signal AerReqxS           : std_logic;
  signal AerReqDelayedxS    : std_logic;
  --
  signal AerDataxD          : std_logic_vector(paer_width-1 downto 0);
  --
  signal FifoOutDataxD      : std_logic_vector(internal_width-1 downto 0);
  signal FifoOutReadxS      : std_logic;
  --
  signal FifoEmptyxS        : std_logic;
  
begin

  -----------------------------------------------------------------------------
  -- internally we use active high req/ack
  AerAckxA  <= AerAckxAI xnor AerAckActiveLevelxDI;
  AerReqxSO <= AerReqDelayedxS xnor AerReqActiveLevelxDI;

  -----------------------------------------------------------------------------

  iReqDelay_RegisterArray1 : RegisterArray1
    generic map (
      depth => 2
      )
    port map (
      ClkxCI        => ClkxCI,
      RstxRBI       => RstxRBI,
      ResetValuexDI => '0',
      InputxDI      => AerReqxS,
      OutputxDO     => AerReqDelayedxS
      );

  -----------------------------------------------------------------------------

  iReq_AsyncStabilizer : AsyncStabilizer
    generic map (
      synchronizer      => true,
      stabilizer_cycles => 2
      )
    port map (
      ClkxCI      => ClkxCI,
      RstxRBI     => RstxRBI,
      RstValuexDI => '0',
      InputxAI    => AerAckxA,
      OutputxDO   => AerAckStabilizedxS
      );

  -----------------------------------------------------------------------------
  
  iShiftRegFifoRRInp : ShiftRegFifoRRInp
    generic map (
      width           => internal_width,
      depth           => output_fifo_depth,
      full_fifo_reset => false
      )
    port map (
      ClockxCI       => ClkxCI,
      ResetxRBI      => RstxRBI,
      --
      InpDataxDI     => InpDataxDI,
      InpSrcRdyxSI   => InpSrcRdyxSI,
      InpDstRdyxSO   => InpDstRdyxSO,
      --
      OutDataxDO     => FifoOutDataxD,
      OutReadxSI     => FifoOutReadxS,
      --
      EmptyxSO       => FifoEmptyxS,
      AlmostEmptyxSO => open,
      AlmostFullxSO  => open,
      FullxSO        => open,
      UnderflowxSO   => open
      );

  --iShiftRegFifoRROut : entity HPU_lib.ShiftRegFifoRROut
  --  generic map (
  --    width           => internal_width,
  --    depth           => input_fifo_depth,
  --    full_fifo_reset => false
  --    )
  --  port map (
  --    ClockxCI       => ClkxCI,
  --    ResetxRBI      => RstxRBI,
  --    --
  --    InpDataxDI     => FifoInpDataxD,
  --    InpWritexSI    => FifoInpWritexS,
  --    --
  --    OutDataxDO     => OutDataxDO,
  --    OutSrcRdyxSO   => OutSrcRdyxSO,
  --    OutDstRdyxSI   => OutDstRdyxSI,
  --    --
  --    EmptyxSO       => open,
  --    AlmostEmptyxSO => open,
  --    AlmostFullxSO  => open,
  --    FullxSO        => FifoFullxS,
  --    OverflowxSO    => open
  --    );

  -----------------------------------------------------------------------------

  p_memless : process (AerAckStabilizedxS, FifoEmptyxS, StatexDP)
  begin

    -- defaults
    StatexDN      <= StatexDP;
    AerReqxS      <= '0';
    FifoOutReadxS <= '0';

    case StatexDP is
      when stWaitData =>

        -- no req yet
        AerReqxS <= '0';

        if FifoEmptyxS = '0' then
          AerReqxS <= '1';              -- assert req
          StatexDN <= stWaitAckAssert;
        else
          -- stay
        end if;
        
      when stWaitAckAssert =>

        -- keep req
        AerReqxS <= '1';

        if AerAckStabilizedxS = '1' then
          AerReqxS <= '0';               -- deassert req
          StatexDN <= stWaitAckRelease;  -- cont
        else
          -- stay
        end if;

      when stWaitAckRelease =>

        -- keep ack deasserted
        AerReqxS <= '0';

        if AerAckStabilizedxS = '0' then
          -- ack finally cleared
          FifoOutReadxS <= '1';         -- read fifo
          StatexDN      <= stWaitData;  -- go for the next one
        else
          -- stay
        end if;

      when others => null;
    end case;
    
  end process p_memless;

  ---------------------------------------------------------------------------

  p_memzing : process (ClkxCI, RstxRBI)
  begin
    if RstxRBI = '0' then               -- asynchronous reset (active low)
      StatexDP <= stWaitData;
    elsif ClkxCI'event and ClkxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
    end if;
  end process p_memzing;

  -----------------------------------------------------------------------------
  -- fifo data
  AerDataxD <= FifoOutDataxD(paer_width-1 downto 0);

  -----------------------------------------------------------------------------
  -- output alias wiring
  AerDataxDO <= AerDataxD;

  
end rtl;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
