-------------------------------------------------------------------------------
-- ShiftRegFifoRROut -- ShiftRegFifo with Ready-Ready Output
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    
library work;
  use work.components.all;

--****************************
--   PORT DECLARATION
--****************************

entity ShiftRegFifoRROut is
    generic (
        width           : positive;
        depth           : positive := 4;
        full_fifo_reset : boolean  := true
    );
    port (
        ClockxCI        : in  std_logic;
        ResetxRBI       : in  std_logic;
        --              
        InpDataxDI      : in  std_logic_vector(width-1 downto 0);
        InpWritexSI     : in  std_logic;
        --              
        OutDataxDO      : out std_logic_vector(width-1 downto 0);
        OutSrcRdyxSO    : out std_logic;
        OutDstRdyxSI    : in  std_logic;
        --              
        EmptyxSO        : out std_logic;
        AlmostEmptyxSO  : out std_logic;
        AlmostFullxSO   : out std_logic;
        FullxSO         : out std_logic;
        OverflowxSO     : out std_logic
    );
end entity ShiftRegFifoRROut;


--****************************
--   IMPLEMENTATION
--****************************

architecture rtl of ShiftRegFifoRROut is
  
    signal InpDstRdyxS     : std_logic;
    signal OutSrcRdyxS     : std_logic;
    --
    signal OutReadxS       : std_logic;
    signal FullxS, EmptyxS : std_logic;

begin

    u_ShiftRegFifo : ShiftRegFifo
        generic map (
            width           => width,
            depth           => depth,
            full_fifo_reset => full_fifo_reset
        )
        port map (
            ClockxCI        => ClockxCI,
            ResetxRBI       => ResetxRBI,
            InputxDI        => InpDataxDI,
            WritexSI        => InpWritexSI,
            AlmostFullxSO   => AlmostFullxSO,
            FullxSO         => FullxS,
            OverflowxSO     => OverflowxSO,
            OutputxDO       => OutDataxDO,
            ReadxSI         => OutReadxS,
            AlmostEmptyxSO  => AlmostEmptyxSO,
            EmptyxSO        => EmptyxS,
            UnderflowxSO    => open
        );

    -- out RR logic
    OutSrcRdyxS <= not EmptyxS;
    OutReadxS   <= OutDstRdyxSI and OutSrcRdyxS;

    -- output aliases
    FullxSO      <= FullxS;
    EmptyxSO     <= EmptyxS;
    OutSrcRdyxSO <= OutSrcRdyxS;
  
end architecture rtl;

-------------------------------------------------------------------------------
