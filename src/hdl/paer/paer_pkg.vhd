library ieee;
    use ieee.std_logic_1164.all;

package components is

    component AsyncStabilizer is
        generic (
            synchronizer      : boolean  := true;
            stabilizer_cycles : positive := 2
        );
        port (
            ClkxCI      : in  std_logic;
            RstxRBI     : in  std_logic;
            --
            RstValuexDI : in  std_logic;
            --
            InputxAI    : in  std_logic;
            OutputxDO   : out std_logic
        );
    end component AsyncStabilizer;
    
    component RegisterArray1 is
        generic (
            depth : natural  := 1
        );
        port (
            ClkxCI        : in  std_logic;
            RstxRBI       : in  std_logic;
            --
            ResetValuexDI : in  std_logic;
            --
            InputxDI      : in  std_logic;
            OutputxDO     : out std_logic
        );
    end component RegisterArray1;

    component ShiftRegFifo is
        generic (
            width           : positive;
            depth           : positive;
            full_fifo_reset : boolean := false;
            errorchecking   : boolean := true
        );
        port (
            ClockxCI        : in  std_logic;
            ResetxRBI       : in  std_logic;
            --
            InputxDI        : in  std_logic_vector(width-1 downto 0);
            WritexSI        : in  std_logic;
            AlmostFullxSO   : out std_logic;
            FullxSO         : out std_logic;
            OverflowxSO     : out std_logic;
            --
            OutputxDO       : out std_logic_vector(width-1 downto 0);
            ReadxSI         : in  std_logic;
            AlmostEmptyxSO  : out std_logic;
            EmptyxSO        : out std_logic;
            UnderflowxSO    : out std_logic;
            --
            LevelxDO        : out natural range 0 to depth
        );
    end component ShiftRegFifo;
    
    component ShiftRegFifoRROut is
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
    end component ShiftRegFifoRROut;

    component ShiftRegFifoRRInp is
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
    end component ShiftRegFifoRRInp;

end package components;



