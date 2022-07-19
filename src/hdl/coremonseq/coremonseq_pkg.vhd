library ieee;
    use ieee.std_logic_1164.all;

package components is

  component RXFIFO_HPU_ZYNQ
    port (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      full : OUT STD_LOGIC;
      almost_full : OUT STD_LOGIC;
      overflow : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      almost_empty : OUT STD_LOGIC;
      underflow : OUT STD_LOGIC;
      rd_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
      wr_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
      wr_rst_busy : OUT STD_LOGIC;
      rd_rst_busy : OUT STD_LOGIC
      );
  end component;
      
  component TXFIFO_HPU_ZYNQ
    port (
      rst : IN STD_LOGIC;                                  
      wr_clk : IN STD_LOGIC;                               
      rd_clk : IN STD_LOGIC;                               
      din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);              
      wr_en : IN STD_LOGIC;                                
      rd_en : IN STD_LOGIC;                                
      dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);            
      full : OUT STD_LOGIC;                                
      almost_full : OUT STD_LOGIC;                         
      overflow : OUT STD_LOGIC;                            
      empty : OUT STD_LOGIC;                               
      almost_empty : OUT STD_LOGIC;                        
      underflow : OUT STD_LOGIC;                           
      rd_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);    
      wr_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);    
      wr_rst_busy : OUT STD_LOGIC;                         
      rd_rst_busy : OUT STD_LOGIC                          
    );
  end component;
  
  component RXFIFO_HPU_ZYNQUPLUS
    port (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      full : OUT STD_LOGIC;
      almost_full : OUT STD_LOGIC;
      overflow : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      almost_empty : OUT STD_LOGIC;
      underflow : OUT STD_LOGIC;
      rd_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
      wr_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
      wr_rst_busy : OUT STD_LOGIC;
      rd_rst_busy : OUT STD_LOGIC
      );
  end component;
      
  component TXFIFO_HPU_ZYNQUPLUS
    port (
      rst : IN STD_LOGIC;                                  
      wr_clk : IN STD_LOGIC;                               
      rd_clk : IN STD_LOGIC;                               
      din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);              
      wr_en : IN STD_LOGIC;                                
      rd_en : IN STD_LOGIC;                                
      dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);            
      full : OUT STD_LOGIC;                                
      almost_full : OUT STD_LOGIC;                         
      overflow : OUT STD_LOGIC;                            
      empty : OUT STD_LOGIC;                               
      almost_empty : OUT STD_LOGIC;                        
      underflow : OUT STD_LOGIC;                           
      rd_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);    
      wr_data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);    
      wr_rst_busy : OUT STD_LOGIC;                         
      rd_rst_busy : OUT STD_LOGIC                          
    );
  end component;
      
  component Timestamp is 
    port (
      Rst_n_i        : in  std_logic;
      Clk_i          : in  std_logic;
      Zero_i         : in  std_logic;
      CleanTimer_i   : in  std_logic;
      LoadTimer_i    : in  std_logic;
      LoadValue_i    : in std_logic_vector(31 downto 0);
      Timestamp_o    : out std_logic_vector(31 downto 0)
    );
  end component Timestamp;
  
  component TimestampWrapDetector is
    port (
      Reset_n_i      : in  std_logic;
      Clk_i          : in  std_logic;
      MSB_i          : in  std_logic;
      WrapDetected_o : out std_logic
    );
  end component TimestampWrapDetector;
  
  component timetagger is
    port (
      Rst_n_i         : in  std_logic;
      Clk_i           : in  std_logic;
      Timestamp_i     : in  std_logic_vector(31 downto 0);
      FullTimestamp_i : in  std_logic;
      --
      MonEn_i         : in  std_logic;
      --
      InAddr_i        : in  std_logic_vector(31 downto 0);
      InSrcRdy_i      : in  std_logic;
      InDstRdy_o      : out std_logic;
      --
      OutAddrEvt_o    : out std_logic_vector(63 downto 0);
      OutWrite_o      : out std_logic;
      OutFull_i       : in  std_logic
    );
  end component timetagger;
  
  component sequencer is
    port (
      Rst_n_i             : in  std_logic;
      Clk_i               : in  std_logic;
      Enable_i            : in  std_logic;
      --                  
      En100us_i           : in  std_logic;
      --                  
      TSMode_i            : in  std_logic_vector(1 downto 0);
      TSTimeoutSel_i      : in  std_logic_vector(3 downto 0);
      TSMaskSel_i         : in  std_logic_vector(1 downto 0);
      --                  
      Timestamp_i         : in  std_logic_vector(31 downto 0);
      LoadTimer_o         : out std_logic;
      LoadValue_o         : out std_logic_vector(31 downto 0);
      TxTSRetrigCmd_i     : in  std_logic;
      TxTSRearmCmd_i      : in  std_logic;
      TxTSRetrigStatus_o  : out std_logic;
      TxTSTimeoutCounts_o : out std_logic;
      --                  
      InAddrEvt_i         : in  std_logic_vector(63 downto 0);
      InRead_o            : out std_logic;
      InEmpty_i           : in  std_logic;
      --                  
      OutAddr_o           : out std_logic_vector(31 downto 0);
      OutSrcRdy_o         : out std_logic;
      OutDstRdy_i         : in  std_logic
      --
      -- ConfigAddr_o     : out std_logic_vector(31 downto 0);
      -- ConfigReq_o      : out std_logic;
      -- ConfigAck_i      : in  std_logic
    );
  end component sequencer;
  
end package components;
