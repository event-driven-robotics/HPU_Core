library ieee;
  -- Logic libraries
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;              
  
  -- Math libraries
  use ieee.std_logic_arith.all;          
 --   use ieee.numeric_std.all;           
 use ieee.math_real.all;
  
  -- Text    
  use ieee.std_logic_textio.all;         

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library unisim;
--   USE UNISIM.VCOMPONENTS.ALL;
 
entity fifo_axis_tb is
  generic (
    constant CLK_WR_FREQ_g                    : real := 100.0; -- MHz                
    constant CLK_RD_FREQ_g                    : real := 150.0  -- MHz                
  );
--  port ( 
--  );
end fifo_axis_tb;


architecture Behavioral of fifo_axis_tb is


-- ***************************************************************************************************
-- COMPONENT DECLARATION

component rxfifo_hpu_zynquplus
  port (
    rst : in std_logic;
    wr_clk : in std_logic;
    rd_clk : in std_logic;
    din : in std_logic_vector(63 downto 0);
    wr_en : in std_logic;
    rd_en : in std_logic;
    dout : out std_logic_vector(63 downto 0);
    full : out std_logic;
    almost_full : out std_logic;
    overflow : out std_logic;
    empty : out std_logic;
    almost_empty : out std_logic;
    underflow : out std_logic;
    rd_data_count : out std_logic_vector(10 downto 0);
    wr_data_count : out std_logic_vector(10 downto 0);
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic
  );
end component;


component neuserial_axistream is
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
        OnlyEventsRx_i         : in  std_logic;
        OnlyEventsTx_i         : in  std_logic;
        DMA_is_running_o       : out std_logic;
        DmaLength_i            : in  std_logic_vector(15 downto 0);
        ResetStream_i          : in  std_logic;
        LatTlat_i              : in  std_logic;
        TlastCnt_o             : out std_logic_vector(31 downto 0);
        TlastTO_i              : in  std_logic_vector(31 downto 0);
        TlastTOwritten_i       : in  std_logic;
        TDataCnt_o             : out std_logic_vector(31 downto 0);
        -- From Fifo to core/dma
        FifoCoreDat_i          : in  std_logic_vector(31 downto 0);
        FifoCoreRead_o         : out std_logic;
        FifoCoreEmpty_i        : in  std_logic;
        FifoCoreBurstReady_i   : in  std_logic; -- not used
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
        M_AXIS_TREADY          : in  std_logic
    );
end component;


-- ***************************************************************************************************
-- SIGNAL AND CONSTANT DECLARATION

---------------------------------------
-- FOR TESTBENCH

constant CLK_WR_PERIOD_NS_c      : time        := (1000.0 / CLK_WR_FREQ_g) * 1 ns; 
constant CLK_RD_PERIOD_NS_c      : time        := (1000.0 / CLK_RD_FREQ_g) * 1 ns; 

signal clk_hpu, clk_dma           : std_logic;
signal clear, clear_n           : std_logic;
signal pp_hpu_rst_n, p_hpu_rst_n, hpu_rst_n : std_logic := '1';
signal pp_dma_rst_n, p_dma_rst_n, dma_rst_n : std_logic := '1';


---------------------------------------
-- USER SIGNALS

-- signal rst                      : std_logic;
signal rx_wr_clk                   : std_logic;
signal rx_rd_clk                   : std_logic;
signal rx_din                      : std_logic_vector(63 downto 0);
signal rx_wr_en                    : std_logic;
signal rx_rd_en                    : std_logic;
signal rx_dout                     : std_logic_vector(63 downto 0);
signal rx_full                     : std_logic;
signal rx_almost_full              : std_logic;
signal rx_overflow                 : std_logic;
signal rx_empty                    : std_logic;
signal rx_almost_empty             : std_logic;
signal rx_underflow                : std_logic;
signal rx_rd_data_count            : std_logic_vector(10 downto 0);
signal rx_wr_data_count            : std_logic_vector(10 downto 0);
signal rx_wr_rst_busy              : std_logic;
signal rx_rd_rst_busy              : std_logic;

signal rx_event     : std_logic_vector(31 downto 0);
signal rx_timestamp : std_logic_vector(31 downto 0);



 signal uP_DMA_test_mode               : std_logic;
 signal uP_enableDmaIf                 : std_logic;
 signal uP_DMAIsRunning                : std_logic;
 signal uP_dmaLength                   : std_logic_vector(15 downto 0);
 signal uP_resetstream                 : std_logic;
 signal up_LatTlast                    : std_logic;
 signal up_TlastCnt                    : std_logic_vector(31 downto 0);
 signal up_TlastTO                     : std_logic_vector(31 downto 0);
 signal up_TlastTOwritten              : std_logic;
 signal up_TDataCnt                    : std_logic_vector(31 downto 0);
 -- From Fifo to core/dma              : 
 signal dma_rxDataBuffer               : std_logic_vector(31 downto 0);
 signal dma_readRxBuffer               : std_logic;
 signal dma_rxBufferEmpty              : std_logic;
 signal dma_rxBufferReady              : std_logic;
 signal FifoCoreLastData               : std_logic;
 -- From core/dma to Fifo
 signal dma_txDataBuffer               : std_logic_vector(31 downto 0);
 signal dma_writeTxBuffer              : std_logic;
 signal dma_txBufferFull               : std_logic;
 -- Axi Stream I/f
 signal S_AXIS_TREADY                  : std_logic;
 signal S_AXIS_TDATA                   : std_logic_vector(31 downto 0);
 signal S_AXIS_TLAST                   : std_logic;
 signal S_AXIS_TVALID                  : std_logic;
 signal M_AXIS_TVALID                  : std_logic;
 signal M_AXIS_TDATA                   : std_logic_vector(31 downto 0);
 signal M_AXIS_TLAST                   : std_logic;
 signal M_AXIS_TREADY                  : std_logic;
 
 signal dataRead    : std_logic;
 signal FifoCoreDat : std_logic_vector(31 downto 0);

 signal uP_OnlyEventsRx : std_logic;  
 signal uP_OnlyEventsTx : std_logic;  
 signal OnlyEventsRx_i  : std_logic;  
 signal OnlyEventsTx_i  : std_logic;  

 signal dummy : std_logic;
 
type state_type is (idle, waitfifo, readdata, timeval, dataval, premature_end); 
signal internal_state, internal_next_state : state_type;
-- alias internal_state is 
-- << u_neuserial_axistream.i_DMA_running    : std_logic>>;

-- << signal u_neuserial_axistream.state : state_type >> ;
 
begin

---------------------------------------
-- STIMULI FOR TESTBENCH

proc_clear : process  
begin
  clear_n <= '1';
  clear   <= '0';
  wait for 12 ns;
  -- wait for 12 ms;
  clear_n <= '0';
  clear   <= '1'; 
  wait for 104 ns;
  clear_n <= '1';
  clear   <= '0';
  wait;
end process proc_clear;  

proc_clk_wr : process 
begin
  clk_hpu   <= '0';
  wait for 10 ns;
  clk_loop : loop
    clk_hpu   <= not clk_hpu;
    wait for (CLK_WR_PERIOD_NS_c / 2.0);
  end loop;
end process proc_clk_wr;

proc_clk_rd : process 
begin
  clk_dma   <= '0';
  wait for 10 ns;
  clk_loop : loop
    clk_dma   <= not clk_dma;
    wait for (CLK_RD_PERIOD_NS_c / 2.0);
  end loop;
end process proc_clk_rd;

-- ***************************************************************************************************
-- RESET DEASSERTION SYNCRONIZATION

-- RST_N
process(clk_hpu, clear)
begin
  if (clear = '1') then
    pp_hpu_rst_n  <= '0';
    p_hpu_rst_n   <= '0';
    hpu_rst_n     <= '0';
  elsif rising_edge(clk_hpu) then
    pp_hpu_rst_n  <= '1';
    p_hpu_rst_n   <= pp_hpu_rst_n;
    hpu_rst_n     <= p_hpu_rst_n;
  end if;
end process;  

-- RST
process(clk_dma, clear)
begin
  if (clear = '1') then
    pp_dma_rst_n  <= '0';
    p_dma_rst_n   <= '0';
    dma_rst_n     <= '0';
  elsif rising_edge(clk_dma) then
    pp_dma_rst_n  <= '1';
    p_dma_rst_n   <= pp_dma_rst_n;
    dma_rst_n     <= p_dma_rst_n;
  end if;
end process;


-- ***************************************************************************************************
-- Component instantiation

RXFIFO_HPU_ZYNQUPLUS_m : RXFIFO_HPU_ZYNQUPLUS
  PORT MAP (
    rst           => clear,
    wr_clk        => rx_wr_clk,
    rd_clk        => rx_rd_clk,
    din           => rx_din,
    wr_en         => rx_wr_en,
    rd_en         => rx_rd_en,
    dout          => rx_dout,
    full          => rx_full,
    almost_full   => rx_almost_full,
    overflow      => rx_overflow,
    empty         => rx_empty,
    almost_empty  => rx_almost_empty,
    underflow     => rx_underflow,
    rd_data_count => rx_rd_data_count,
    wr_data_count => rx_wr_data_count,
    wr_rst_busy   => rx_wr_rst_busy,
    rd_rst_busy   => rx_rd_rst_busy
  );


uP_DMA_test_mode      <= '0';           -- in  std_logic;                    
uP_enableDmaIf        <= '1';           -- in  std_logic;                    
-- uP_DMAIsRunning                      -- out std_logic;                    
uP_dmaLength          <= x"0010";       -- in  std_logic_vector(15 downto 0);
uP_resetstream        <=  '0';          -- in  std_logic;                    
up_LatTlast           <=  '1';          -- in  std_logic;                    
-- up_TlastCnt                          -- out std_logic_vector(31 downto 0);
up_TlastTO            <= x"00001000";   -- in  std_logic_vector(31 downto 0);
up_TlastTOwritten     <= '0';           -- in  std_logic;                    
-- up_TDataCnt                          -- out std_logic_vector(31 downto 0);



u_neuserial_axistream : neuserial_axistream
  generic map (
    C_DEBUG => false
    )
  port map (
    Clk                            => clk_dma,                       -- in  std_logic;
    nRst                           => dma_rst_n,                             -- in  std_logic;
    --
    DMA_test_mode_i                => uP_DMA_test_mode,               -- in  std_logic;
    EnableAxistreamIf_i            => uP_enableDmaIf,                 -- in  std_logic;
    OnlyEventsRx_i                 => uP_OnlyEventsRx,                  -- in  std_logic;
    OnlyEventsTx_i                 => uP_OnlyEventsTx,                  -- in  std_logic;
    DMA_is_running_o               => uP_DMAIsRunning,                -- out std_logic;
    DmaLength_i                    => uP_dmaLength,                   -- in  std_logic_vector(15 downto 0);
    ResetStream_i                  => uP_resetstream,                 -- in  std_logic;
    LatTlat_i                      => up_LatTlast,                    -- in  std_logic;
    TlastCnt_o                     => up_TlastCnt,                    -- out std_logic_vector(31 downto 0);
    TlastTO_i                      => up_TlastTO,                     -- in  std_logic_vector(31 downto 0);
    TlastTOwritten_i               => up_TlastTOwritten,              -- in  std_logic;
    TDataCnt_o                     => up_TDataCnt,                    -- out std_logic_vector(31 downto 0);
    -- From Fifo to core/dma
    FifoCoreDat_i                  => dma_rxDataBuffer,               -- in  std_logic_vector(31 downto 0);
    FifoCoreRead_o                 => dma_readRxBuffer,               -- out std_logic;
    FifoCoreEmpty_i                => dma_rxBufferEmpty,              -- in  std_logic;
    FifoCoreBurstReady_i           => dma_rxBufferReady,              -- in  std_logic;
    FifoCoreLastData_i             => FifoCoreLastData,               -- in  std_logic;
    -- From core/dma to Fifo
    CoreFifoDat_o                  => dma_txDataBuffer,               -- out std_logic_vector(31 downto 0);
    CoreFifoWrite_o                => dma_writeTxBuffer,              -- out std_logic;
    CoreFifoFull_i                 => dma_txBufferFull,               -- in  std_logic;
    -- Axi Stream I/f
    S_AXIS_TREADY                  => S_AXIS_TREADY,                    -- out std_logic;
    S_AXIS_TDATA                   => S_AXIS_TDATA,                     -- in  std_logic_vector(31 downto 0);
    S_AXIS_TLAST                   => S_AXIS_TLAST,                     -- in  std_logic;
    S_AXIS_TVALID                  => S_AXIS_TVALID,                    -- in  std_logic;
    M_AXIS_TVALID                  => M_AXIS_TVALID,                    -- out std_logic;
    M_AXIS_TDATA                   => M_AXIS_TDATA,                     -- out std_logic_vector(31 downto 0);
    M_AXIS_TLAST                   => M_AXIS_TLAST,                     -- out std_logic;
    M_AXIS_TREADY                  => M_AXIS_TREADY                      -- in  std_logic
    );


-- dma_rxDataBuffer <= rx_dout(31 downto 0);
-- rx_rd_en <= dma_readRxBuffer;
dma_rxBufferEmpty <= rx_empty;
-- It's DmaLength_xDI/2 because of the FIFO is 64 bit and the reading is 32 bit wide
dma_rxBufferReady <= '1' when (conv_integer(unsigned(rx_wr_data_count)) >= conv_integer(unsigned('0'&uP_dmaLength(15 downto 1)))) else '0';
FifoCoreLastData <= rx_almost_empty and not rx_empty;

dma_txBufferFull <= '0';



-- p_ReadDataTimeSel : process (clk_dma, dma_rst_n) is
-- begin
--   if (dma_rst_n = '0') then
--     dataRead <= '0';
--   elsif (rising_edge(clk_dma)) then
--     if (dma_readRxBuffer = '1' or dummy = '1') then
--       dataRead <= not(dataRead);
--     end if;
--   end if;
-- end process p_ReadDataTimeSel;

p_ReadDataTimeSel : process (clk_dma, dma_rst_n) is
begin
  if (dma_rst_n = '0') then
    dataRead <= '0';
  elsif (rising_edge(clk_dma)) then
    if (OnlyEventsRx_i = '1') then
      dataRead <= '1';
    elsif (dma_readRxBuffer = '0') then
      dataRead <= '0';
    else
      dataRead <= not(dataRead);
    end if;
  end if;
end process p_ReadDataTimeSel;




--   dma_rxDataBuffer  <= rx_dout(63 downto 32) when (dataRead = '0' and OnlyEvents_i = '0') else  -- i.e. Time
--                        rx_dout(31 downto  0);                             -- i.e. Data
--   rx_rd_en <=  '0' when (dataRead = '0' and OnlyEvents_i = '0') else dma_readRxBuffer;
    
    dma_rxDataBuffer  <= rx_dout(63 downto 32) when (dataRead = '0') else  -- i.e. Time
                         rx_dout(31 downto  0);                             -- i.e. Data
    rx_rd_en <=  '0' when (dataRead = '0') else dma_readRxBuffer;

--    FifoCoreFull <= MonOutFull_xS;

    --enableFifoWriting_xS <= MonOutWrite_xS when (MonOutAddrEvt_xD(7 downto 0) >= OutThresholdVal_xDI(7 downto 0)) else '0';
--    enableFifoWriting <= MonOutWrite;





-- ***************************************************************************************************
-- USER'S STIMULI

rx_wr_clk <= clk_hpu;  
rx_rd_clk <= clk_dma;


rx_din <= rx_timestamp & rx_event;

  
OnlyEventsRx_i <= uP_OnlyEventsRx;

proc_axistream : process  
begin

S_AXIS_TDATA  <= x"00000000";
S_AXIS_TLAST  <= '0';
S_AXIS_TVALID <= '0';

M_AXIS_TREADY <= '0'; 

wait for 1 us;
-- M_AXIS_TREADY <= '1';  
-- wait for 1 * CLK_RD_PERIOD_NS_c;
-- M_AXIS_TREADY <= '0';
-- wait for 5000 * CLK_RD_PERIOD_NS_c;
-- M_AXIS_TREADY <= '1';      
-- wait for 1 * CLK_RD_PERIOD_NS_c;
-- M_AXIS_TREADY <= '0';
-- wait for 5000 * CLK_RD_PERIOD_NS_c;
M_AXIS_TREADY <= '1';

wait;
end process proc_axistream;  


proc_dma_to_hpu : process  
begin

  uP_OnlyEventsRx <= '0'; 
  uP_OnlyEventsTx <= '0'; 

  wait for CLK_RD_PERIOD_NS_c - 2 ns;
  wait for 18 us;   

  wait for CLK_RD_PERIOD_NS_c;  
  wait for CLK_RD_PERIOD_NS_c;  
  uP_OnlyEventsRx <= '1';  
  wait for 2 us;
  uP_OnlyEventsRx <= '0';  

--  wait for CLK_WR_PERIOD_NS_c;
--  uP_OnlyEvents <= '0';  
     
  wait;

end process proc_dma_to_hpu; 





proc_hpu_to_dma : process  
begin

  rx_timestamp  <= (31 => '1', others => '0');
  rx_event      <= (others => '0');
  rx_wr_en      <= '0';
  -- rx_rd_en   <= '0';
--  uP_OnlyEvents <= '0'; 
  
  wait for 8 ns;
 
  
  wait for 10 us;   
  
  for i in 1 to 4096 loop    
--    wait for 1 us; 
    rx_wr_en   <= '1';
    wait for CLK_WR_PERIOD_NS_c;
    rx_wr_en   <= '0';
    rx_timestamp <= rx_timestamp + 1;
    rx_event     <= rx_event + 1;
  end loop;

-- wait for 50 us;   
-- uP_OnlyEvents <= '1';  
-- for i in 1 to 15 loop    
--   wait for 1 us; 
--   rx_wr_en   <= '1';
--   wait for CLK_WR_PERIOD_NS_c;
--   rx_wr_en   <= '0';
--   rx_timestamp <= rx_timestamp + 1;
--   rx_event     <= rx_event + 1;
-- end loop; 
--
--  wait for 50 us;   
-- uP_OnlyEvents <= '0';  
-- for i in 1 to 16 loop    
--   wait for 1 us; 
--   rx_wr_en   <= '1';
--   wait for CLK_WR_PERIOD_NS_c;
--   rx_wr_en   <= '0';
--   rx_timestamp <= rx_timestamp + 1;
--   rx_event     <= rx_event + 1;
-- end loop;  
 
  wait;
end process proc_hpu_to_dma;  

end Behavioral;
