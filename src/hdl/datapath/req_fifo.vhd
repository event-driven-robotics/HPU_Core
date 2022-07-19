----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 04/23/2015
-- Design Name:
-- Module Name: req_fifo - beh
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--    The block implements a FIFO able to store the requests coming from multiple
--    input lines and produce the index of the requesting line, operating a
--    serialization when concurrent requests are received.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library common;
    use common.utilities_pkg.all;


--****************************
--   PORT DECLARATION
--****************************

entity req_fifo is
    generic (
        C_DATA_WIDTH : natural;         -- Number of input request lines
        C_IDX_WIDTH  : natural;         -- Width of the index bus in output (should be at least log2(C_DATA_WIDTH)
        C_FIFO_DEPTH : natural          -- Number of cells of the FIFO
    );
    port (
        Clk         : in  std_logic;
        nRst        : in  std_logic;
        PreFill_i   : in  std_logic;
        Push_i      : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        Pop_i       : in  std_logic;
        Idx_o       : out std_logic_vector(C_IDX_WIDTH-1 downto 0);
        Empty_o     : out std_logic;
        Full_o      : out std_logic;
        Underflow_o : out std_logic;
        Overflow_o  : out std_logic
    );
-- synthesis translate_off
begin
    -- check the consistency of the generics
    assert (C_DATA_WIDTH <= 2**C_IDX_WIDTH)
        report  "C_IDX_WIDTH should be at least log2(C_DATA_WIDTH)"
        severity failure;
-- synthesis translate_on
end entity req_fifo;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of req_fifo is

    type   t_fifoMem is array (0 to C_FIFO_DEPTH-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal ram : t_fifoMem;

    --signal reqSampled   : std_logic_vector (C_DATA_WIDTH-1 downto 0);
    --signal reqEdge      : std_logic_vector (C_DATA_WIDTH-1 downto 0);
    --signal reqIssued    : std_logic;

    signal i_pushIssued : std_logic;

    signal i_reqPop  : std_logic;
    signal i_reqPush : std_logic;

    signal pointer_w   : integer range 0 to C_FIFO_DEPTH;
    signal i_empty     : std_logic;
    signal i_full      : std_logic;
    signal i_overflow  : std_logic;
    signal i_underflow : std_logic;
    
    signal i_fifoPop    : std_logic;
    signal i_fifoPush   : std_logic;
    signal i_fifoClrbit : std_logic;

    signal i_idx  : natural range 0 to C_DATA_WIDTH;
    signal i_id   : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal isLast : std_logic;
    

begin

    -- Request rising edge detection
    -----------------------------------
    --p_reqSample : process (Clk)
    --begin
    --    if (rising_edge(Clk)) then
    --        if (nRst = '0') then
    --            reqSampled <= (others => '0');
    --        else
    --            reqSampled <= ReqVect_i;
    --        end if;
    --    end if;
    --end process p_reqSample;
    --
    --reqEdge <= f_VectPosedgeDetect(ReqVect_i, reqSampled);
    --reqIssued <= f_OR_reduction(reqEdge);    -- reqIssued <= '1' when unsigned(reqEdge) /= 0 else '0';
    
    i_pushIssued <= f_OR_reduction(Push_i);


    -- Request Fifo
    ----------------------------------------
    i_reqPop  <= Pop_i        when i_empty = '0' else '0';
    i_reqPush <= i_pushIssued when i_full  = '0' else '0';
    i_overflow  <= '1' when i_pushIssued = '1' and i_full  = '1' else '0';
    i_underflow <= '1' when Pop_i = '1'        and i_empty = '1' else '0';

    i_fifoPush   <= i_reqPush;
    i_fifoPop    <= i_reqPop  when isLast = '1' else '0';
    i_fifoClrbit <= i_reqPop  when isLast = '0' else '0';


    p_reqFifoWrite : process (Clk)
        variable ptr_wr : natural;
    begin
        if (rising_edge(Clk)) then
            if (nRst = '0') then
                -- If PreFill_i is '1', pre-fill the first location with "all '1'"
                -- Consequently pointer_w will be initialized to the next fifo location, i.e. 1
                ram <= (0 => (others => PreFill_i), others => (others=>'0'));
                if (PreFill_i = '1') then
                    pointer_w <= 1;
                else
                    pointer_w <= 0;
                end if;
            else
                ptr_wr := pointer_w;
                if (i_fifoPop = '1') then
                    -- discard ram(0) and shift all other cells
                    for i in 1 to C_FIFO_DEPTH-1 loop
                        ram(i-1) <= ram(i);
                    end loop;
                    ptr_wr := ptr_wr - 1;
                elsif (i_fifoClrbit = '1') then
                    -- clear the served request in a multi-request cell
                    ram(0) <= ram(0) and not(i_id);
                end if;

                if (i_fifoPush = '1') then
                    ram(ptr_wr) <= Push_i;
                    ptr_wr := ptr_wr + 1;
                end if;
                pointer_w <= ptr_wr;
            end if;
        end if;
    end process p_reqFifoWrite;

    i_empty <= '1' when pointer_w = 0            else '0';
    i_full  <= '1' when pointer_w = C_FIFO_DEPTH else '0';
    
    i_idx  <= f_PriorityEncoder(ram(0));
    i_id   <= f_Decoder(i_idx,C_DATA_WIDTH);
    isLast <= '1' when i_id = ram(0) else '0';
    
    Idx_o <= std_logic_vector(to_unsigned(i_idx,C_IDX_WIDTH));
    Empty_o <= i_empty;
    Full_o  <= i_full;
    Underflow_o <= i_underflow;
    Overflow_o  <= i_overflow;
    

end architecture beh;

