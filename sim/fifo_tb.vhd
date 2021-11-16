library ieee;
  -- Logic libraries
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;              
  
  -- Math libraries
  use ieee.std_logic_arith.all;          
  -- use ieee.numeric_std.all;           
  use ieee.math_real.all;
  
  -- Text    
  use ieee.std_logic_textio.all;         

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library unisim;
--   USE UNISIM.VCOMPONENTS.ALL;
 
entity fifo_tb is
  generic (
    constant CLK_WR_FREQ_g                    : real := 100.0; -- MHz                
    constant CLK_RD_FREQ_g                    : real := 150.0  -- MHz                
  );
--  port ( 
--  );
end fifo_tb;


architecture Behavioral of fifo_tb is


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

-- ***************************************************************************************************
-- SIGNAL AND CONSTANT DECLARATION

---------------------------------------
-- FOR TESTBENCH

constant CLK_WR_PERIOD_NS_c      : time        := (1000.0 / CLK_WR_FREQ_g) * 1 ns; 
constant CLK_RD_PERIOD_NS_c      : time        := (1000.0 / CLK_RD_FREQ_g) * 1 ns; 

signal clk_wr, clk_rd           : std_logic;
signal clear, clear_n           : std_logic;
signal pp_rst_n, p_rst_n, rst_n : std_logic := '0';
signal pp_rst, p_rst, rst       : std_logic := '1';


---------------------------------------
-- USER SIGNALS

-- signal rst                      : std_logic;
signal wr_clk                   : std_logic;
signal rd_clk                   : std_logic;
signal din                      : std_logic_vector(63 downto 0);
signal wr_en                    : std_logic;
signal rd_en                    : std_logic;
signal dout                     : std_logic_vector(63 downto 0);
signal full                     : std_logic;
signal almost_full              : std_logic;
signal overflow                 : std_logic;
signal empty                    : std_logic;
signal almost_empty             : std_logic;
signal underflow                : std_logic;
signal rd_data_count            : std_logic_vector(10 downto 0);
signal wr_data_count            : std_logic_vector(10 downto 0);
signal wr_rst_busy              : std_logic;
signal rd_rst_busy              : std_logic;



begin

---------------------------------------
-- STIMULI FOR TESTBENCH

proc_clear : process  
begin
  clear_n <= '1';
  clear   <= '0';
  wait for 1002 ns;
  wait for 12 ms;
  clear_n <= '0';
  clear   <= '1'; 
  wait for 104 ns;
  clear_n <= '1';
  clear   <= '0';
  wait;
end process proc_clear;  

proc_clk_wr : process 
begin
  clk_wr   <= '0';
  wait for 10 ns;
  clk_loop : loop
    clk_wr   <= not clk_wr;
    wait for (CLK_WR_PERIOD_NS_c / 2.0);
  end loop;
end process proc_clk_wr;

proc_clk_rd : process 
begin
  clk_rd   <= '0';
  wait for 10 ns;
  clk_loop : loop
    clk_rd   <= not clk_rd;
    wait for (CLK_RD_PERIOD_NS_c / 2.0);
  end loop;
end process proc_clk_rd;

-- ***************************************************************************************************
-- RESET DEASSERTION SYNCRONIZATION

-- RST_N
process(clk_wr, clear)
begin
  if (clear = '1') then
    pp_rst_n  <= '0';
    p_rst_n   <= '0';
    rst_n     <= '0';
  elsif rising_edge(clk_wr) then
    pp_rst_n  <= '1';
    p_rst_n   <= pp_rst_n;
    rst_n     <= p_rst_n;
  end if;
end process;  

-- RST
process(clk_wr, clear_n)
begin
  if (clear_n = '0') then
    pp_rst    <= '1';
    p_rst     <= '1';
    rst       <= '1';
  elsif rising_edge(clk_wr) then
    pp_rst    <= '0';
    p_rst     <= pp_rst;
    rst       <= p_rst;
  end if;
end process;  


-- ***************************************************************************************************
-- Component instantiation

RXFIFO_HPU_ZYNQUPLUS_m : RXFIFO_HPU_ZYNQUPLUS
  PORT MAP (
    rst           => rst,
    wr_clk        => wr_clk,
    rd_clk        => rd_clk,
    din           => din,
    wr_en         => wr_en,
    rd_en         => rd_en,
    dout          => dout,
    full          => full,
    almost_full   => almost_full,
    overflow      => overflow,
    empty         => empty,
    almost_empty  => almost_empty,
    underflow     => underflow,
    rd_data_count => rd_data_count,
    wr_data_count => wr_data_count,
    wr_rst_busy   => wr_rst_busy,
    rd_rst_busy   => rd_rst_busy
  );


-- ***************************************************************************************************
-- USER'S STIMULI

wr_clk <= clk_wr;
rd_clk <= clk_rd;

proc_write_data : process  
begin

  din     <= (others => '0');
  wr_en   <= '0';
  rd_en   <= '0';
  
  wait for 8 ns;
  
  wait for 10 us;
  wr_en   <= '1';
  wait for CLK_WR_PERIOD_NS_c;
  wr_en   <= '0';
  din     <= din + 1;

  wait for 1 us;
  wr_en   <= '1';
  wait for CLK_WR_PERIOD_NS_c;
  wr_en   <= '0';
  din     <= din + 1;

  wait for 1 us;
  wr_en   <= '1';
  wait for CLK_WR_PERIOD_NS_c;
  wr_en   <= '0';
  din     <= din + 1;

  wait for 1 us;
  wr_en   <= '1';
  wait for CLK_WR_PERIOD_NS_c;
  wr_en   <= '0';
  din     <= din + 1;
  
  
  wait for 1 us;
  wr_en   <= '1';
  wait for CLK_WR_PERIOD_NS_c;
  wr_en   <= '0';
  din     <= din + 1;
  
  
  wait for 1 us;
  wr_en   <= '1';
  wait for CLK_WR_PERIOD_NS_c;
  wr_en   <= '0';
  din     <= din + 1;
  
  --

  wait for 10 us;
  rd_en   <= '1';
  wait for CLK_RD_PERIOD_NS_c;
  rd_en   <= '0';


  wait for 1 us;
  rd_en   <= '1';
  wait for CLK_RD_PERIOD_NS_c;
  rd_en   <= '0';


  wait for 1 us;
  rd_en   <= '1';
  wait for CLK_RD_PERIOD_NS_c;
  rd_en   <= '0';


  wait for 1 us;
  rd_en   <= '1';
  wait for CLK_RD_PERIOD_NS_c;
  rd_en   <= '0';

  
  
  wait for 1 us;
  rd_en   <= '1';
  wait for CLK_RD_PERIOD_NS_c;
  rd_en   <= '0';

  
  
  wait for 1 us;
  rd_en   <= '1';
  wait for CLK_RD_PERIOD_NS_c;
  rd_en   <= '0';

     
  wait;
end process proc_write_data;  

end Behavioral;
