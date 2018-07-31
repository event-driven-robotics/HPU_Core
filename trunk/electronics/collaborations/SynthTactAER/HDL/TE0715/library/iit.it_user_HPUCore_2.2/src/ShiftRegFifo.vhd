-------------------------------------------------------------------------------
-- ShiftRegFifo -- FIFO suitable for Shift-Register mapping in FPGAs
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;


--****************************
--   PORT DECLARATION
--****************************

entity ShiftRegFifo is
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
end entity ShiftRegFifo;


--****************************
--   IMPLEMENTATION
--****************************

architecture rtl of ShiftRegFifo is

    -- fifo data
    type   t_fifo_array is array (depth-1 downto 0) of std_logic_vector(width-1 downto 0);
    signal FifoxDP, FifoxDN : t_fifo_array;
   
    -- fifo level
    signal LevelxDP, LevelxDN : natural range 0 to depth;
   
    -- flag signals
    signal AlmostFullxSP, AlmostFullxSN   : std_logic;
    signal FullxSP, FullxSN               : std_logic;
    signal OverflowxSP, OverflowxSN       : std_logic;
    --
    signal AlmostEmptyxSP, AlmostEmptyxSN : std_logic;
    signal EmptyxSP, EmptyxSN             : std_logic;
    signal UnderflowxSP, UnderflowxSN     : std_logic;

begin

    -----------------------------------------------------------------------------
    -- checks
    -----------------------------------------------------------------------------

    -- synthesis translate_off
    g_check : if errorchecking generate
        p_check : process (OverflowxSP, ResetxRBI, UnderflowxSP)
        begin
            if (ResetxRBI = '1') then
                assert OverflowxSP = '0' report "ShiftRegFifo OVERFLOW on last clock!" severity error;
                assert UnderflowxSP = '0' report "ShiftRegFifo UNDERFLOW deteceted on last clock!" severity error;
            end if;
        end process p_check;
    end generate g_check;
    -- synthesis translate_on


    -----------------------------------------------------------------------------
    -- next state logic
    -----------------------------------------------------------------------------

    p_memless : process (EmptyxSP, FifoxDP, FullxSP, InputxDI, LevelxDN,
                         LevelxDP, ReadxSI, WritexSI) is

        -- internal signals, aehm variables of course, not signals..!!!
        variable ValidWrite, ValidRead : boolean;

    begin

        ---------------------------------------------------------------------------
        -- just some VARIABLES
        ---------------------------------------------------------------------------

        -- ValidWrite
        if (FullxSP = '0' and WritexSI = '1') then
            ValidWrite := true;
        else
            ValidWrite := false;
        end if;
        
        -- ValidRead
        if (EmptyxSP = '0' and ReadxSI = '1') then
            ValidRead := true;
        else
            ValidRead := false;
        end if;

        ---------------------------------------------------------------------------
        -- the real thing, fifo level, fifo data, fifo output
        ---------------------------------------------------------------------------

        -- LevelxDN
        if (ValidWrite = false and ValidRead = true) then
            LevelxDN <= LevelxDP - 1;
        elsif (ValidWrite = true and ValidRead = false) then
            LevelxDN <= LevelxDP + 1;
        else
            -- ( not write and not read ) or ( write and read ):
            LevelxDN <= LevelxDP;
        end if;

        -- Fifo
        if (ValidWrite = true) then
            --FifoxDN(depth-1 downto 0) <= FifoxDP(depth-2 downto 0) & InputxDI;
            -- this was wrong because we don't create an array with '&'..!!!
            --
            -- better:
            FifoxDN(depth-1 downto 1) <= FifoxDP(depth-2 downto 0);
            FifoxDN(0)                <= InputxDI;
        else
            FifoxDN <= FifoxDP;               -- (default)
        end if;

        -- Fifo Output
        if (EmptyxSP = '0') then
            OutputxDO <= FifoxDP(LevelxDP - 1);
        else
            -- when the fifo is empty, we still output the first SRL stage hoping
            -- to avoid generating another #width multiplexers..:
            OutputxDO <= FifoxDP(0);
        end if;

        ---------------------------------------------------------------------------
        -- Flags
        ---------------------------------------------------------------------------

        -- AlmostFull
        if (LevelxDN >= depth - 1) then
            AlmostFullxSN <= '1';
        else
            AlmostFullxSN <= '0';
        end if;
        
        -- Full
        if (LevelxDN >= depth) then
            FullxSN <= '1';
        else
            FullxSN <= '0';
        end if;

        -- AlmostEmpty
        if (LevelxDN <= 1) then
            AlmostEmptyxSN <= '1';
        else
            AlmostEmptyxSN <= '0';
        end if;

        -- Empty
        if (LevelxDN <= 0) then
            EmptyxSN <= '1';
        else
            EmptyxSN <= '0';
        end if;

        -- Overflow
        if (FullxSP = '1' and WritexSI = '1') then
            OverflowxSN <= '1';
        else
            OverflowxSN <= '0';
        end if;

        -- Underflow
        if (EmptyxSP = '1' and ReadxSI = '1') then
            UnderflowxSN <= '1';
        else
            UnderflowxSN <= '0';
        end if;

    end process p_memless;

    
    -----------------------------------------------------------------------------
    -- storage
    -----------------------------------------------------------------------------

    p_memzing : process (ClockxCI, ResetxRBI) is
    begin
        if (ResetxRBI = '0') then             -- asynchronous reset (active low)

            if (full_fifo_reset) then
                FifoxDP <= (others => (others => '0'));
            end if;

            LevelxDP       <= 0;
            --
            AlmostFullxSP  <= '0';
            FullxSP        <= '0';
            OverflowxSP    <= '0';
            --
            AlmostEmptyxSP <= '1';
            EmptyxSP       <= '1';
            UnderflowxSP   <= '0';

        elsif (rising_edge(ClockxCI)) then  -- rising clock edge

            FifoxDP        <= FifoxDN;

            LevelxDP       <= LevelxDN;
            --
            AlmostFullxSP  <= AlmostFullxSN;
            FullxSP        <= FullxSN;
            OverflowxSP    <= OverflowxSN;
            --
            AlmostEmptyxSP <= AlmostEmptyxSN;
            EmptyxSP       <= EmptyxSN;
            UnderflowxSP   <= UnderflowxSN;

        end if;
    end process p_memzing;

    
    -----------------------------------------------------------------------------
    -- output alias wiring
    -----------------------------------------------------------------------------

    AlmostFullxSO  <= AlmostFullxSP;
    FullxSO        <= FullxSP;
    OverflowxSO    <= OverflowxSP;
    --
    AlmostEmptyxSO <= AlmostEmptyxSP;
    EmptyxSO       <= EmptyxSP;
    UnderflowxSO   <= UnderflowxSP;
    --
    LevelxDO       <= LevelxDP;

end architecture rtl;

-------------------------------------------------------------------------------
