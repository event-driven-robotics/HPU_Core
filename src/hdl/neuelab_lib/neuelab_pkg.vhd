------------------------------------------------------------------------
-- Package NEComponents_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of components used inside the
--   CoreMonSeq IP
--
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;

package NEComponents_pkg is

    component INFIFO_64_1024_ZYNQ is
        port (
            clk          : in  std_logic;
            srst         : in  std_logic;
            din          : in  std_logic_vector(63 downto 0);
            wr_en        : in  std_logic;
            rd_en        : in  std_logic;
            dout         : out std_logic_vector(63 downto 0);
            full         : out std_logic;
            almost_full  : out std_logic;
            overflow     : out std_logic;
            empty        : out std_logic;
            almost_empty : out std_logic;
            underflow    : out std_logic;
            data_count   : out std_logic_vector(10 downto 0)
        );
    end component INFIFO_64_1024_ZYNQ;

    component INFIFO_64_1024_ZYNQUPLUS is
        port (
            clk          : in  std_logic;
            srst         : in  std_logic;
            din          : in  std_logic_vector(63 downto 0);
            wr_en        : in  std_logic;
            rd_en        : in  std_logic;
            dout         : out std_logic_vector(63 downto 0);
            full         : out std_logic;
            almost_full  : out std_logic;
            overflow     : out std_logic;
            empty        : out std_logic;
            almost_empty : out std_logic;
            underflow    : out std_logic;
            data_count   : out std_logic_vector(10 downto 0);
            wr_rst_busy  : out std_logic;
            rd_rst_busy  : out std_logic
        );
    end component INFIFO_64_1024_ZYNQUPLUS;

        
    component OUTFIFO_32_2048_64_1024_ZYNQ is
        port (
            rst          : in  std_logic;
            wr_clk       : in  std_logic;
            rd_clk       : in  std_logic;
            din          : in  std_logic_vector(31 downto 0);
            wr_en        : in  std_logic;
            rd_en        : in  std_logic;
            dout         : out std_logic_vector(63 downto 0);
            full         : out std_logic;
            almost_full  : out std_logic;
            overflow     : out std_logic;
            empty        : out std_logic;
            almost_empty : out std_logic;
            underflow    : out std_logic
        );
    end component OUTFIFO_32_2048_64_1024_ZYNQ;

    component OUTFIFO_32_2048_64_1024_ZYNQUPLUS is
        port (
            rst          : in  std_logic;
            wr_clk       : in  std_logic;
            rd_clk       : in  std_logic;
            din          : in  std_logic_vector(31 downto 0);
            wr_en        : in  std_logic;
            rd_en        : in  std_logic;
            dout         : out std_logic_vector(63 downto 0);
            full         : out std_logic;
            almost_full  : out std_logic;
            overflow     : out std_logic;
            empty        : out std_logic;
            almost_empty : out std_logic;
            underflow    : out std_logic
        );
    end component OUTFIFO_32_2048_64_1024_ZYNQUPLUS;

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
            din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
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
            wr_data_count : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
            wr_rst_busy : OUT STD_LOGIC;
            rd_rst_busy : OUT STD_LOGIC
        );
    end component;    
    
    
    

   
    component Timestamp is 
        port (
            Rst_xRBI       : in  std_logic;
            Clk_xCI        : in  std_logic;
            Zero_xSI       : in  std_logic;
            CleanTimer_xSI : in  std_logic;
            LoadTimer_xSI  : in  std_logic;
            LoadValue_xSI  : in std_logic_vector(31 downto 0);
            Timestamp_xDO  : out std_logic_vector(31 downto 0)
        );
    end component Timestamp;

    
    component TimestampWrapDetector is
        port (
            Resetn       : in  std_logic;
            Clk          : in  std_logic;
            MSB          : in  std_logic;
            WrapDetected : out std_logic
        );
    end component TimestampWrapDetector;

    
    component MonitorRR is
        port (
            Rst_xRBI       : in  std_logic;
            Clk_xCI        : in  std_logic;
            Timestamp_xDI  : in  std_logic_vector(31 downto 0);
            FullTimestamp_i: in  std_logic;
            --
            MonEn_xSAI     : in  std_logic;
            --
            InAddr_xDI     : in  std_logic_vector(31 downto 0);
            InSrcRdy_xSI   : in  std_logic;
            InDstRdy_xSO   : out std_logic;
            --
            OutAddrEvt_xDO : out std_logic_vector(63 downto 0);
            OutWrite_xSO   : out std_logic;
            OutFull_xSI    : in  std_logic
        );
    end component MonitorRR;


    component AEXSsequencerRR is
        port (
            Rst_xRBI              : in  std_logic;
            Clk_xCI               : in  std_logic;
            Enable_xSI            : in  std_logic;
            --
            En100us_xSI           : in  std_logic;
            --
            TSMode_xDI            : in  std_logic_vector(1 downto 0);
            TSTimeoutSel_xDI      : in  std_logic_vector(3 downto 0);
            TSMaskSel_xDI         : in  std_logic_vector(1 downto 0);
            --
            Timestamp_xDI         : in  std_logic_vector(31 downto 0);
            LoadTimer_xSO         : out std_logic;
            LoadValue_xSO         : out std_logic_vector(31 downto 0);
            TxTSRetrigCmd_xSI     : in  std_logic;
            TxTSRearmCmd_xSI      : in  std_logic;
            TxTSRetrigStatus_xSO  : out std_logic;
            TxTSTimeoutCounts_xSO : out std_logic;
            --
            InAddrEvt_xDI         : in  std_logic_vector(63 downto 0);
            InRead_xSO            : out std_logic;
            InEmpty_xSI           : in  std_logic;
            --
            OutAddr_xDO           : out std_logic_vector(31 downto 0);
            OutSrcRdy_xSO         : out std_logic;
            OutDstRdy_xSI         : in  std_logic
            --
            --ConfigAddr_xDO : out std_logic_vector(31 downto 0);
            --ConfigReq_xSO  : out std_logic;
            --ConfigAck_xSI  : in  std_logic
        );
    end component AEXSsequencerRR;


end package NEComponents_pkg;
