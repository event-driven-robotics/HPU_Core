-------------------------------------------------------------------------------
-- ShiftRegFifoRRInp -- ShiftRegFifo with Ready-Ready Input
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
  use work.components.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity ShiftRegFifoRRInp is
  
  generic (
    width           : positive;
    depth           : positive := 4;
    full_fifo_reset : boolean  := false
    );

  port (
    ClockxCI       : in  std_logic;
    ResetxRBI      : in  std_logic;
    --
    InpDataxDI     : in  std_logic_vector(width-1 downto 0);
    InpSrcRdyxSI   : in  std_logic;
    InpDstRdyxSO   : out std_logic;
    --
    OutDataxDO     : out std_logic_vector(width-1 downto 0);
    OutReadxSI     : in  std_logic;
    --
    EmptyxSO       : out std_logic;
    AlmostEmptyxSO : out std_logic;
    AlmostFullxSO  : out std_logic;
    FullxSO        : out std_logic;
    UnderflowxSO   : out std_logic
    );

end entity ShiftRegFifoRRInp;

-------------------------------------------------------------------------------
------------------------------------------------------------------------------

architecture rtl of ShiftRegFifoRRInp is
  
  signal OutSrcRdyxS     : std_logic;
  signal InpDstRdyxS     : std_logic;
  --
  signal InpWritexS      : std_logic;
  signal FullxS, EmptyxS : std_logic;

begin

  iShiftRegFifo : ShiftRegFifo
    generic map (
      width           => width,
      depth           => depth,
      full_fifo_reset => full_fifo_reset)
    port map (
      ClockxCI       => ClockxCI,
      ResetxRBI      => ResetxRBI,
      InputxDI       => InpDataxDI,
      WritexSI       => InpWritexS,
      AlmostFullxSO  => AlmostFullxSO,
      FullxSO        => FullxS,
      OverflowxSO    => open,
      OutputxDO      => OutDataxDO,
      ReadxSI        => OutReadxSI,
      AlmostEmptyxSO => AlmostEmptyxSO,
      EmptyxSO       => EmptyxS,
      UnderflowxSO   => UnderflowxSO
      );

  -- out RR logic
  InpDstRdyxS <= not FullxS;
  InpWritexS  <= InpSrcRdyxSI and InpDstRdyxS;

  -- output aliases
  FullxSO      <= FullxS;
  EmptyxSO     <= EmptyxS;
  InpDstRdyxSO <= InpDstRdyxS;
  
end architecture rtl;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
