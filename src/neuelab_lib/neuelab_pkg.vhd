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

    component Infifo_64_1024_32 is
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
    end component Infifo_64_1024_32;

    
    component Outfifo_32_2048_64 is
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
    end component Outfifo_32_2048_64;

    
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
            TxTSRetrigStatus_xSO  : out std_logic;
            TxTSSyncEnable_xSI    : in  std_logic;
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
