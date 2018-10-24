-- ------------------------------------------------------------------------------ 
--  Project Name        : 
--  Design Name         : 
--  Starting date:      : 
--  Target Devices      : 
--  Tool versions       : 
--  Project Description : 
-- ------------------------------------------------------------------------------
--  Company             : IIT - Italian Institute of Technology  
--  Engineer            : Maurizio Casti
-- ------------------------------------------------------------------------------ 
-- ==============================================================================
--  PRESENT REVISION
-- ==============================================================================
--  File        : HPUcore_tb.vhd
--  Revision    : 1.0
--  Author      : M. Casti
--  Date        : 
-- ------------------------------------------------------------------------------
--  Description : Test Bench for "HPUcore" (SpiNNlink-AER)
--     
-- ==============================================================================
--  Revision history :
-- ==============================================================================
-- 
--  Revision 1.0:  07/19/2018
--  - Initial revision, based on tbench.vhd (F. Diotalevi)
--  (M. Casti - IIT)
-- 
-- ------------------------------------------------------------------------------

    
library HPU_lib;
        use HPU_lib.aer_pkg.all;
        use HPU_lib.HPUComponents_pkg.all;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_arith.all;
-- use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;
-- use IEEE.math_real.all;

--  LIBRARY dut_lib;
--  use  dut_lib.all;

--  Uncomment the following library declaration if using
--  arithmetic functions with Signed or Unsigned values
--  USE ieee.numeric_std.ALL;
 
entity HPUcore_tb is
    generic (
        CLK_PERIOD                  : integer := 10;   -- CLK period [ns]
        C_S_AXI_DATA_WIDTH          : natural := 32;
        C_S_AXI_ADDR_WIDTH          : natural := 8;
        C_ENC_NUM_OF_STEPS          : natural := 1970; -- Limit of incremental encoder
        NUM_OF_TRANSMITTER          : integer := 32;
        NUM_OF_RECEIVER             : natural := 32;
        SPI_ADC_RES                 : natural := 12;
        
        NORANDOM_DMA                : natural := 0
        );
end HPUcore_tb;
 
architecture behavior of HPUcore_tb is 
 
 
constant F_HSCLK : real := 300.0; -- MHz
constant T_HSCLK : time := ((1.0/F_HSCLK)/2.0) * (1 us);
 
constant F_LSCLK : real := 100.0; -- MHz
constant T_LSCLK : time := ((1.0/F_LSCLK)/2.0) * (1 us); 
 
-- --------------------------------------------------
--  Unit Under Test: HPUcore
-- --------------------------------------------------
component HPUCore
    generic (
    -- ADD USER GENERICS BELOW THIS LINE ---------------

    C_PAER_DSIZE               : natural range 1 to 29   := 24;
    C_RX_HAS_PAER              : boolean                 := true;
    C_RX_HAS_HSSAER            : boolean                 := true;
    C_RX_HSSAER_N_CHAN         : natural range 1 to 4    := 3;
    C_RX_HAS_GTP               : boolean                 := true;
    C_RX_HAS_SPNNLNK           : boolean                 := true;
    C_TX_HAS_PAER              : boolean                 := true;
    C_TX_HAS_HSSAER            : boolean                 := true;
    C_TX_HSSAER_N_CHAN         : natural range 1 to 4    := 2;
    C_TX_HAS_GTP               : boolean                 := true;
    C_TX_HAS_SPNNLNK           : boolean                 := true;
    C_PSPNNLNK_WIDTH           : natural range 1 to 32   := 32;
    C_DEBUG                    : boolean                 := false;
    
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_S_AXI_DATA_WIDTH             : integer              := 32;
    C_S_AXI_ADDR_WIDTH             : integer              := 7;
    C_S_AXI_MIN_SIZE               : std_logic_vector     := X"000001FF";
    C_USE_WSTRB                    : integer              := 1;
    C_DPHASE_TIMEOUT               : integer              := 8;
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_FAMILY                       : string               := "virtex7";
    C_NUM_REG                      : integer              := 24;
    C_NUM_MEM                      : integer              := 1;
    C_SLV_AWIDTH                   : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
);
port (
    -- ADD USER PORTS BELOW THIS LINE ------------------

    -- SYNC Resetn
    nSyncReset        : in  std_logic;

    -- Clocks for HSSAER interface
    HSSAER_ClkLS_p    : in  std_logic; -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
    HSSAER_ClkLS_n    : in  std_logic; -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
    HSSAER_ClkHS_p    : in  std_logic; -- 300 Mhz clock p it must 3x HSSAER_ClkLS
    HSSAER_ClkHS_n    : in  std_logic; -- 300 Mhz clock p it must 3x HSSAER_ClkLS

    --============================================
    -- Rx Interface from Vision Sensor Controllers
    --============================================

    -- Left Sensor
    ------------------
    -- Parallel AER
    LRx_PAER_Addr_i           : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    LRx_PAER_Req_i            : in  std_logic;
    LRx_PAER_Ack_o            : out std_logic;

    -- HSSAER interface
    LRx_HSSAER_i              : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);

    -- GTP interface


    -- Right Sensor
    ------------------
    -- Parallel AER
    RRx_PAER_Addr_i           : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    RRx_PAER_Req_i            : in  std_logic;
    RRx_PAER_Ack_o            : out std_logic;

    -- HSSAER interface
    RRx_HSSAER_i              : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);

    -- GTP interface

    -- Aux Sensor
    ------------------
    -- Parallel AER
    AuxRx_PAER_Addr_i         : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
    AuxRx_PAER_Req_i          : in  std_logic;
    AuxRx_PAER_Ack_o          : out std_logic;

    -- HSSAER interface
    AuxRx_HSSAER_i            : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);

    -- GTP interface
    ---------------------

    -- SpiNNlink interface
    LRx_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
    LRx_ack_to_spinnaker_o           : out std_logic;
    RRx_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
    RRx_ack_to_spinnaker_o           : out std_logic;
    AuxRx_data_2of7_from_spinnaker_i : in  std_logic_vector(6 downto 0); 
    AuxRx_ack_to_spinnaker_o         : out std_logic;
    
    --============================================
    -- Tx Interface
    --============================================

    -- Parallel AER
    Tx_PAER_Addr_o            : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
    Tx_PAER_Req_o             : out std_logic;
    Tx_PAER_Ack_i             : in  std_logic;

    -- HSSAER interface
    Tx_HSSAER_o               : out std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);

    -- GTP interface
    
    -- SpiNNlink interface
    Tx_data_2of7_to_spinnaker_o      : out std_logic_vector(6 downto 0);
    Tx_ack_from_spinnaker_i          : in  std_logic;
        
    --============================================
    -- Configuration interface
    --============================================
    DefLocFarLpbk_i   : in  std_logic;
    DefLocNearLpbk_i  : in  std_logic;

    --============================================
    -- Processor interface
    --============================================
    Interrupt_o       : out std_logic;

    -- Debug signals interface
    DBG_dataOk        : out std_logic;
    DBG_rawi          : out std_logic_vector(15 downto 0);
    DBG_data_written  : out std_logic;
    DBG_dma_burst_counter : out std_logic_vector(10 downto 0);
    DBG_dma_test_mode      : out std_logic;
    DBG_dma_EnableDma      : out std_logic;
    DBG_dma_is_running     : out std_logic;
    DBG_dma_Length         : out std_logic_vector(10 downto 0);
    DBG_dma_nedge_run      : out std_logic;


    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    -- Axi lite I/f
    S_AXI_ACLK        : in  std_logic;
    S_AXI_ARESETN     : in  std_logic;
    S_AXI_AWADDR      : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID     : in  std_logic;
    S_AXI_WDATA       : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB       : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID      : in  std_logic;
    S_AXI_BREADY      : in  std_logic;
    S_AXI_ARADDR      : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID     : in  std_logic;
    S_AXI_RREADY      : in  std_logic;
    S_AXI_ARREADY     : out std_logic;
    S_AXI_RDATA       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP       : out std_logic_vector(1 downto 0);
    S_AXI_RVALID      : out std_logic;
    S_AXI_WREADY      : out std_logic;
    S_AXI_BRESP       : out std_logic_vector(1 downto 0);
    S_AXI_BVALID      : out std_logic;
    S_AXI_AWREADY     : out std_logic;
    -- Axi Stream I/f
    S_AXIS_TREADY     : out std_logic;
    S_AXIS_TDATA      : in  std_logic_vector(31 downto 0);
    S_AXIS_TLAST      : in  std_logic;
    S_AXIS_TVALID     : in  std_logic;
    M_AXIS_TVALID     : out std_logic;
    M_AXIS_TDATA      : out std_logic_vector(31 downto 0);
    M_AXIS_TLAST      : out std_logic;
    M_AXIS_TREADY     : in  std_logic;
    -- DO NOT EDIT ABOVE THIS LINE ---------------------

    DBG_din             : out std_logic_vector(63 downto 0);     
    DBG_wr_en           : out std_logic;  
    DBG_rd_en           : out std_logic;     
    DBG_dout            : out std_logic_vector(63 downto 0);          
    DBG_full            : out std_logic;    
    DBG_almost_full     : out std_logic;    
    DBG_overflow        : out std_logic;       
    DBG_empty           : out std_logic;           
    DBG_almost_empty    : out std_logic;    
    DBG_underflow       : out std_logic;     
    DBG_data_count      : out std_logic_vector(10 downto 0);
    DBG_CH0_DATA        : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_CH0_SRDY        : out std_logic;   
    DBG_CH0_DRDY        : out std_logic;        
    DBG_CH1_DATA        : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_CH1_SRDY        : out std_logic;   
    DBG_CH1_DRDY        : out std_logic;        
    DBG_CH2_DATA        : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_CH2_SRDY        : out std_logic;   
    DBG_CH2_DRDY        : out std_logic;
    DBG_Timestamp_xD    : out std_logic_vector(31 downto 0);       
    DBG_MonInAddr_xD    : out std_logic_vector(31 downto 0); 
    DBG_MonInSrcRdy_xS  : out std_logic;
    DBG_MonInDstRdy_xS  : out std_logic;
    DBG_RESETFIFO       : out std_logic;
    DBG_CTRG_reg        : out std_logic_vector(C_SLV_DWIDTH-1 downto 0); 
    DBG_ctrl_rd         : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DBG_src_rdy         : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_dst_rdy         : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_err             : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);  
    DBG_run             : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_RX              : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
    DBG_AUXRxSaerChanEn : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);

    DBG_shreg_aux0      : out std_logic_vector(3 downto 0);
    DBG_shreg_aux1      : out std_logic_vector(3 downto 0);
    DBG_shreg_aux2      : out std_logic_vector(3 downto 0);
    DBG_FIFO_0          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_1          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_2          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_3          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
    DBG_FIFO_4          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)
);
end component;	

-- --------------------------------------------------
--  AXI Lite Emulator
-- --------------------------------------------------	
component axi4lite_bfm_v00 
    generic(
  		limit                       : integer := 1000;
  		NORANDOM_DMA                : integer := 0;
        SPI_ADC_RES                 : integer := 12;
        NUM_OF_RECEIVER             : natural := NUM_OF_RECEIVER;
        AXI4LM_CMD_FILE             : string  := "AXI4LM_bfm.cmd";  -- Command file name
        AXI4LM_LOG_FILE             : string  := "AXI4LM_bfm.log"   -- Log file name
		);
    port ( 
        S_AXI_ACLK :in  STD_LOGIC;
        S_AXI_ARESETN               : in  STD_LOGIC;
        S_AXI_AWVALID               : out  STD_LOGIC;
        S_AXI_AWREADY               : in  STD_LOGIC;
        S_AXI_AWADDR                : out  STD_LOGIC_VECTOR (31 downto 0);
        S_AXI_WVALID                : out  STD_LOGIC;
        S_AXI_WREADY                : in  STD_LOGIC;
        S_AXI_WDATA                 : out  STD_LOGIC_VECTOR (31 downto 0);
        S_AXI_WSTRB                 : out  STD_LOGIC_VECTOR (3 downto 0);
        S_AXI_BVALID                : in  STD_LOGIC;
        S_AXI_BREADY                : out  STD_LOGIC;
        S_AXI_BRESP                 : in  STD_LOGIC_VECTOR (1 downto 0);
        S_AXI_ARVALID               : inout  STD_LOGIC;
        S_AXI_ARREADY               : in  STD_LOGIC;
        S_AXI_ARADDR                : out  STD_LOGIC_VECTOR (31 downto 0);
        S_AXI_RVALID                : in  STD_LOGIC;
        S_AXI_RREADY                : out  STD_LOGIC;
        S_AXI_RDATA                 : in  STD_LOGIC_VECTOR (31 downto 0);
        S_AXI_RRESP                 : in  STD_LOGIC_VECTOR (1 downto 0);
        M_Axis_TVALID               : in  std_logic;
        M_Axis_TLAST                : in  std_logic;
        M_Axis_TDATA                : in  std_logic_vector (31 downto 0);
        M_Axis_TREADY               : out std_logic;
        S_AXIS_TREADY               : in  std_logic;
        S_AXIS_TDATA                : out std_logic_vector(31 downto 0);
        S_AXIS_TLAST                : out std_logic;
        S_AXIS_TVALID               : out std_logic;
        -- Axi Master I-f
        M_AXI_ACLK                  : in  std_logic;
        -- Axi master
        M_AXI_AWADDR                : in  std_logic_vector(31 downto 0);
        M_AXI_AWLEN                 : in  std_logic_vector(7 downto 0); 
        M_AXI_AWSIZE                : in  std_logic_vector(2 downto 0);
        M_AXI_AWBURST               : in  std_logic_vector(1 downto 0);
        M_AXI_AWCACHE               : in  std_logic_vector(3 downto 0);
        M_AXI_AWVALID               : in  std_logic; 
        M_AXI_AWREADY               : out std_logic; 
        --       master interface write data
        M_AXI_WDATA                 : in  std_logic_vector(31 downto 0); 
        M_AXI_WSTRB                 : in  std_logic_vector(3 downto 0);
        M_AXI_WLAST                 : in  std_logic;  
        M_AXI_WVALID                : in  std_logic;   
        M_AXI_WREADY                : out std_logic;  
        --       master interface write response
        M_AXI_BRESP                 : out std_logic_vector(1 downto 0); 
        M_AXI_BVALID                : out std_logic;   
        M_AXI_BREADY                : in  std_logic;

        start_dmas                  : out std_logic;
        dma_done                    : in  std_logic;

        ocp_o                       : out std_logic;
        ext_fault_o                 : out std_logic;
         
        interrupt  	                : in std_logic;			  
        start                       : in std_logic
);
end component;

-- --------------------------------------------------
--  PLL
-- --------------------------------------------------	
component PLL
	generic(
		SYSCLK_PERIOD               : integer := 10;
        SD_PERIOD                   : integer := 50;
		SWEEP                       : integer := 0
		);
	port(
		rst_in	                    : in  std_logic; 	-- Reset in
		rst_out	                    : out std_logic;	-- Reset out
		SYS_CLK	                    : out std_logic;  	-- Clock
        sd_rst_out                  : out std_logic;    -- Reset out
        SD_CLK                      : out std_logic     -- Clock 
	);
end component ;

-- --------------------------------------------------
--  SpiNNaker Emulator
-- --------------------------------------------------	
component SpiNNaker_Emulator 
    generic (
        HAS_ID       : string;
        ID           : natural;
        HAS_TX       : string;
        TX_FILE      : string;
        HAS_RX       : string;
        RX_FILE      : string
        ); 
		port (
		
  		-- SpiNNaker link asynchronous output interface
  		Lout         : out std_logic_vector(6 downto 0);
  		LoutAck      : in std_logic;
  		
  		-- SpiNNaker link asynchronous input interface
  		Lin          : in std_logic_vector(6 downto 0);
  		LinAck       : out std_logic;
  		
  		-- Control interface
  		rst          : in std_logic
  		);
end component ;

-- --------------------------------------------------
--  AER Device Emulator
-- --------------------------------------------------	
component AER_Device_Emulator 
	port (

		-- AER Device asynchronous output interface
		AERout		: out std_logic_vector(23 downto 0);
		AERoutReq	: out std_logic;
		AERoutAck	: in std_logic;

		-- AER Device asynchronous input interface
		AERin		: in std_logic_vector(23 downto 0);
		AERinReq    : in std_logic;
		AERinAck    : out std_logic;
  
		-- Control interface
		enable		: in std_logic;
		rst			: in std_logic
  );
end component ;

signal i_clk                    : std_logic;
signal i_resetn, i_reset        : std_logic;

-- Spinnaker
signal LRx_data_2of7_from_spinnaker   : std_logic_vector(6 downto 0); 
signal LRx_ack_to_spinnaker           : std_logic;
signal RRx_data_2of7_from_spinnaker   : std_logic_vector(6 downto 0); 
signal RRx_ack_to_spinnaker           : std_logic;
signal AuxRx_data_2of7_from_spinnaker : std_logic_vector(6 downto 0); 
signal AuxRx_ack_to_spinnaker         : std_logic;
signal Tx_data_2of7_to_spinnaker      : std_logic_vector(6 downto 0);
signal Tx_ack_from_spinnaker          : std_logic;





--AER
signal data_from_AER_L			: std_logic_vector(23 downto 0);
signal req_from_AER_L			: std_logic;
signal ack_to_AER_L				: std_logic;
signal data_to_AER_L			: std_logic_vector(23 downto 0);
signal req_to_AER_L    			: std_logic;
signal ack_from_AER_L     		: std_logic;
signal AER_device_enable_L		: std_logic;
signal SPNN_device_enable_L		: std_logic;

signal data_from_AER_R			: std_logic_vector(23 downto 0);
signal req_from_AER_R			: std_logic;
signal ack_to_AER_R				: std_logic;
signal data_to_AER_R			: std_logic_vector(23 downto 0);
signal req_to_AER_R    			: std_logic;
signal ack_from_AER_R     		: std_logic;
signal AER_device_enable_R		: std_logic;
signal SPNN_device_enable_R 	: std_logic;

signal data_from_AER_Aux		: std_logic_vector(23 downto 0);
signal req_from_AER_Aux			: std_logic;
signal ack_to_AER_Aux			: std_logic;
signal data_to_AER_Aux			: std_logic_vector(23 downto 0);
signal req_to_AER_Aux    		: std_logic;
signal ack_from_AER_Aux     	: std_logic;
signal AER_device_enable_Aux	: std_logic;
signal SPNN_device_enable_Aux	: std_logic;
 
signal data_from_AER_Tx			: std_logic_vector(23 downto 0);
signal req_from_AER_Tx			: std_logic;
signal ack_to_AER_Tx			: std_logic;
signal data_to_AER_Tx			: std_logic_vector(23 downto 0);
signal req_to_AER_Tx    		: std_logic;
signal ack_from_AER_Tx     		: std_logic;
signal AER_device_enable_Tx		: std_logic;
signal SPNN_device_enable_Tx	: std_logic;

-- Clocks
signal HSSAER_ClkLS_p      		: std_logic;
signal HSSAER_ClkLS_n      		: std_logic;
signal HSSAER_ClkHS_p      		: std_logic;
signal HSSAER_ClkHS_n      		: std_logic;

-- AXI
signal s_axi_aclk               : std_logic;
signal s_axi_aresetn            : std_logic;
signal s_axi_awaddr             : std_logic_vector(31 downto 0);
signal s_axi_awvalid            : std_logic;
signal s_axi_wdata              : std_logic_vector(31 downto 0);
signal s_axi_wstrb              : std_logic_vector(3 downto 0);
signal s_axi_wvalid             : std_logic;
signal s_axi_bready             : std_logic;
signal s_axi_araddr             : std_logic_vector(31 downto 0);
signal s_axi_arvalid            : std_logic;
signal s_axi_rready             : std_logic;
signal s_axi_arready            : std_logic;
signal s_axi_rdata              : std_logic_vector(31 downto 0);
signal s_axi_rresp              : std_logic_vector(1 downto 0);
signal s_axi_rvalid             : std_logic;
signal s_axi_wready             : std_logic;
signal s_axi_bresp              : std_logic_vector(1 downto 0);
signal s_axi_bvalid             : std_logic;
signal s_axi_awready            : std_logic;
signal s_axis_tready            : std_logic;
signal s_axis_tdata             : std_logic_vector(31 downto 0);
signal s_axis_tlast             : std_logic;
signal s_axis_tvalid            : std_logic;
signal m_axis_tvalid            : std_logic;
signal m_axis_tdata             : std_logic_vector(31 downto 0);
signal m_axis_tlast             : std_logic;
signal m_axis_tready            : std_logic;
signal m_axi_araddr             : std_logic_vector(31 downto 0);
signal m_axi_arlen              : std_logic_vector( 7 downto 0);
signal m_axi_arsize             : std_logic_vector( 2 downto 0);
signal m_axi_arburst            : std_logic_vector( 1 downto 0);
signal m_axi_arcache            : std_logic_vector( 3 downto 0);
signal m_axi_arvalid            : std_logic;
signal m_axi_arready            : std_logic;
signal m_axi_rdata              : std_logic_vector(31 downto 0);  
signal m_axi_rresp              : std_logic_vector( 1 downto 0);  
signal m_axi_rlast              : std_logic;                      
signal m_axi_rvalid             : std_logic;                      
signal m_axi_rready             : std_logic;                      
signal m_axi_awaddr             : std_logic_vector(31 downto 0);
signal m_axi_awlen              : std_logic_vector(7 downto 0);
signal m_axi_awsize             : std_logic_vector(2 downto 0);
signal m_axi_awburst            : std_logic_vector(1 downto 0);
signal m_axi_awvalid            : std_logic;
signal m_axi_awready            : std_logic;
signal m_axi_wdata              : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal m_axi_wstrb              : std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
signal m_axi_wlast              : std_logic; 
signal m_axi_wvalid             : std_logic;
signal m_axi_wready             : std_logic;
signal m_axi_bresp              : std_logic_vector(1 downto 0);
signal m_axi_bvalid             : std_logic;
signal m_axi_bready             : std_logic;
signal m_axi_awcache            : std_logic_vector(3 downto 0);

signal i_start                  : std_logic;
signal i_rst_in                 : std_logic := '0';
signal i_Interrupt              : std_logic := '0';

signal i_en                     : std_logic;

signal tx                       : std_logic_vector(NUM_OF_TRANSMITTER-1 downto 0 );

signal start_dmas               : std_logic;
signal dma_done                 : std_logic;
signal i_Async_reset            : std_logic;
signal i_vr1_i                  : std_logic_vector (7 downto 0);
signal i_vr2_i                  : std_logic_vector (7 downto 0);
signal i_vr3_i                  : std_logic_vector (7 downto 0);
signal pwmap                    : std_logic;
signal pwman                    : std_logic;
signal pwmbp                    : std_logic;
signal pwmbn                    : std_logic;
signal pwmcp                    : std_logic;
signal pwmcn                    : std_logic;

-- encoder
signal i_FromSpeed              : real;
signal i_ToSpeed                : real := 10000.0;
signal i_SpeedInDeltaTime       : time := 3 ms;
signal i_encoder_A, i_encoder_B, i_encoder_Index, i_encoder_Home : std_logic;
signal i_encoder_encoder_A, i_encoder_encoder_B, i_encoder_encoder_Index, i_encoder_encoder_Home : std_logic;

-- SD
signal i_sd_resetn              : std_logic;
signal i_sd_clk                 : std_logic;
signal clk_sd                   : std_logic;
signal resetn_sd                : std_logic;
signal current_sd               : std_logic_vector(2 downto 0);

-- current
signal i_ocp                    : std_logic;
signal i_ext_fault              : std_logic;

-- VDClink
signal i_vdclink_data_sd        : std_logic;
signal i_vdclink_clk_sd         : std_logic;


-- 
signal M_Axis_TREADY_HPU        : std_logic;

begin 

-- ************************************************************************************************************************

-- --------------------------------------------------
-- Clock Generator
-- --------------------------------------------------	
-- PLL_i : PLL
-- 	generic map(
-- 		SYSCLK_PERIOD        => CLK_PERIOD,
--         SD_PERIOD            => 50,
-- 		SWEEP                => 0
-- 		)
-- 	port map( 
-- 		rst_in	             => i_rst_in,
-- 		rst_out	             => i_resetn,
-- 		SYS_CLK	             => i_clk,
--         sd_rst_out           => i_sd_resetn,
--         SD_CLK               => i_sd_clk
-- 	);


-- --------------------------------------------------
-- SpiNNaker Emulator
-- --------------------------------------------------	
R_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 1,
    HAS_TX     => "false",
    TX_FILE    => "../../../../../sim/Data_To_R.txt",
    HAS_RX     => "false",
    RX_FILE    => ""
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => RRx_data_2of7_from_spinnaker,
	LoutAck    => RRx_ack_to_spinnaker,
	
	-- SpiNNaker link asynchronous input interface
	Lin        => (others => '0'),
	LinAck     => open,
	
	-- Control interface
	rst        => SPNN_device_enable_R -- i_reset
	);

L_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 2,
    HAS_TX     => "false",
    TX_FILE    => "../../../../../sim/Data_To_L.txt",
    HAS_RX     => "false",
    RX_FILE    => ""
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => LRx_data_2of7_from_spinnaker,
	LoutAck    => LRx_ack_to_spinnaker,
	
	-- SpiNNaker link asynchronous input interface
	Lin        => (others => '0'),
	LinAck     => open,
	
	-- Control interface
	rst        => SPNN_device_enable_L -- i_reset
	);

AUX_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 3,
    HAS_TX     => "true",
    TX_FILE    => "../../../../../sim/Data_To_AUX.txt",
    HAS_RX     => "false",
    RX_FILE    => "u"
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => AUXRx_data_2of7_from_spinnaker,
	LoutAck    => AUXRx_ack_to_spinnaker,
	
	-- SpiNNaker link asynchronous input interface
	Lin        => (others => '0'),
	LinAck     => open,
	
	-- Control interface
	rst        => SPNN_device_enable_Aux -- i_reset
	);


TX_SPINNAKER_EMULATOR_i : SpiNNaker_Emulator
    generic map (
    HAS_ID     => "false",
    ID         => 0,
    HAS_TX     => "false",
    TX_FILE    => "",
    HAS_RX     => "true",
    RX_FILE    => "Data_From_TX.txt"
    )
	port map (
	-- SpiNNaker link asynchronous output interface
	Lout       => open,
	LoutAck    => '0',
	
	-- SpiNNaker link asynchronous input interface
	Lin        => Tx_data_2of7_to_spinnaker,
	LinAck     => Tx_ack_from_spinnaker,
	
	-- Control interface
	rst        => SPNN_device_enable_Tx -- i_reset
	);


-- --------------------------------------------------
-- AXI lite Emulator
-- --------------------------------------------------
AXI_EMULATOR_i : axi4lite_bfm_v00
	generic map (
        NORANDOM_DMA => NORANDOM_DMA
        )
	port map (				
        S_AXI_ACLK      => HSSAER_ClkLS_p,
        S_AXI_ARESETN   => i_resetn,
        S_AXI_AWVALID   => s_axi_awvalid,
        S_AXI_AWREADY   => s_axi_awready,
        S_AXI_AWADDR    => s_axi_awaddr,
        S_AXI_WVALID    => s_axi_wvalid,
        S_AXI_WREADY    => s_axi_wready,
        S_AXI_WDATA     => s_axi_wdata,
        S_AXI_WSTRB     => s_axi_wstrb,
        S_AXI_BVALID    => s_axi_bvalid,
        S_AXI_BREADY    => s_axi_bready,
        S_AXI_BRESP     => s_axi_bresp,
        S_AXI_ARVALID   => s_axi_arvalid,
        S_AXI_ARREADY   => s_axi_arready,
        S_AXI_ARADDR    => s_axi_araddr,
        S_AXI_RVALID    => s_axi_rvalid,
        S_AXI_RREADY    => s_axi_rready,
        S_AXI_RDATA     => s_axi_rdata,
        S_AXI_RRESP     => s_axi_rresp,
        M_Axis_TVALID   => m_axis_tvalid,
        M_Axis_TLAST    => m_axis_tlast,
        M_Axis_TDATA    => m_axis_tdata,
        M_Axis_TREADY   => m_axis_tready,
        S_AXIS_TREADY   => s_axis_tready,
        S_AXIS_TDATA    => s_axis_tdata,
        S_AXIS_TLAST    => s_axis_tlast,
        S_AXIS_TVALID   => s_axis_tvalid,
        -- Axi master
        M_AXI_ACLK      => HSSAER_ClkLS_p,
        M_AXI_AWADDR    => m_axi_awaddr,
        M_AXI_AWLEN     => m_axi_awlen,
        M_AXI_AWSIZE    => m_axi_awsize,
        M_AXI_AWBURST   => m_axi_awburst,
        M_AXI_AWCACHE   => m_axi_awcache,
        M_AXI_AWVALID   => m_axi_awvalid,
        M_AXI_AWREADY   => m_axi_awready,
        --       master interface write data
        M_AXI_WDATA     => m_axi_wdata,
        M_AXI_WSTRB     => m_axi_wstrb,
        M_AXI_WLAST     => m_axi_wlast,
        M_AXI_WVALID    => m_axi_wvalid,
        M_AXI_WREADY    => m_axi_wready,
        --       master interface write response
        M_AXI_BRESP     => m_axi_bresp,
        M_AXI_BVALID    => m_axi_bvalid,
        M_AXI_BREADY    => m_axi_bready,
        
        start_dmas      => start_dmas,
        dma_done        => dma_done,
        
        ocp_o           => i_ocp,
        ext_fault_o     => i_ext_fault,
        
        
        interrupt       => i_Interrupt,
        start           => i_start
        );

-- --------------------------------------------------
-- AER Device Emulators
-- --------------------------------------------------
L_AER_DEVICE_EMULATOR_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_L,
		AERoutReq	=> req_from_AER_L,
		AERoutAck	=> ack_to_AER_L,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_L,
		AERinReq    => req_to_AER_L,
		AERinAck    => ack_from_AER_L,

		-- Control interface
		enable		=> AER_device_enable_L,
		rst			=> i_reset
); 

R_AER_DEVICE_EMULATOR_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_R,
		AERoutReq	=> req_from_AER_R,
		AERoutAck	=> ack_to_AER_R,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_R,
		AERinReq    => req_to_AER_R,
		AERinAck    => ack_from_AER_R,

		-- Control interface
		enable		=> AER_device_enable_R,
		rst			=> i_reset
); 

AUX_AER_DEVICE_EMULATOR_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_Aux,
		AERoutReq	=> req_from_AER_Aux,
		AERoutAck	=> ack_to_AER_Aux,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_Aux,
		AERinReq    => req_to_AER_Aux,
		AERinAck    => ack_from_AER_Aux,

		-- Control interface
		enable		=> AER_device_enable_Aux,
		rst			=> i_reset
); 

AER_DEVICE_EMULATOR_Tx_i : AER_Device_Emulator 
	port map(

		-- AER Device asynchronous output interface
		AERout		=> data_from_AER_Tx,
		AERoutReq	=> req_from_AER_Tx,
		AERoutAck	=> ack_to_AER_Tx,

		-- AER Device asynchronous input interface
		AERin		=> data_to_AER_Tx,
		AERinReq    => req_to_AER_Tx,
		AERinAck    => ack_from_AER_Tx,

		-- Control interface
		enable		=> AER_device_enable_Tx,
		rst			=> i_reset
); 
-- --------------------------------------------------
--  Unit Under Test: HPUcore
-- --------------------------------------------------
HPUCORE_i : HPUCore
    generic map (
        -- ADD USER GENERICS BELOW THIS LINE ---------------

        C_PAER_DSIZE               	=> 24,				--	: natural range 1 to 29   := 24;
        C_RX_HAS_PAER              	=> true,			--	: boolean                 := true;
        C_RX_HAS_HSSAER            	=> false,			--	: boolean                 := true;
        C_RX_HSSAER_N_CHAN         	=> 3,				--	: natural range 1 to 4    := 3;
        C_RX_HAS_GTP               	=> false,			--	: boolean                 := true;
        C_RX_HAS_SPNNLNK          	=> false,			--	: boolean                 := true;
        C_TX_HAS_PAER              	=> false,			--	: boolean                 := true;
        C_TX_HAS_HSSAER            	=> false,			--	: boolean                 := true;
        C_TX_HSSAER_N_CHAN         	=> 2,				--	: natural range 1 to 4    := 2;
        C_TX_HAS_GTP               	=> false,			--	: boolean                 := true;
        C_TX_HAS_SPNNLNK          	=> false,			--	: boolean                 := true;
        C_DEBUG                    	=> false,			--	: boolean                 := false;

        -- ADD USER GENERICS ABOVE THIS LINE ---------------

        -- DO NOT EDIT BELOW THIS LINE ---------------------
        -- Bus protocol parameters, do not add to or delete
        C_S_AXI_DATA_WIDTH          => C_S_AXI_DATA_WIDTH,				--	: integer              := 32;
        C_S_AXI_ADDR_WIDTH          => C_S_AXI_ADDR_WIDTH,				--	: integer              := 7;
        C_S_AXI_MIN_SIZE            => X"000001FF",		--	: std_logic_vector     := X"000001FF";
        C_USE_WSTRB                 => 1,				--	: integer              := 1;
        C_DPHASE_TIMEOUT            => 8,				--	: integer              := 8;
        C_BASEADDR                  => X"FFFFFFFF",		--	: std_logic_vector     := X"FFFFFFFF";
        C_HIGHADDR                  => X"00000000",		--	: std_logic_vector     := X"00000000";
        C_FAMILY                    => "virtex7",		--	: string               := "virtex7";
        C_NUM_REG                   => 24,				--	: integer              := 24;
        C_NUM_MEM                   => 1,				--	: integer              := 1;
        C_SLV_AWIDTH                => 32,				--	: integer              := 32;
        C_SLV_DWIDTH                => 32				--	: integer              := 32
        -- DO NOT EDIT ABOVE THIS LINE ---------------------
    )
    port map(
        -- ADD USER PORTS BELOW THIS LINE ------------------

        -- SYNC Resetn
        nSyncReset        			=> i_resetn,

        -- Clocks for HSSAER interface
        HSSAER_ClkLS_p   			=> HSSAER_ClkLS_p, -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
        HSSAER_ClkLS_n   			=> HSSAER_ClkLS_n, -- 100 Mhz clock p it must be at the same frequency of the clock of the transmitter
        HSSAER_ClkHS_p   			=> HSSAER_ClkHS_p, -- 300 Mhz clock p it must 3x HSSAER_ClkLS
        HSSAER_ClkHS_n   			=> HSSAER_ClkHS_n, -- 300 Mhz clock p it must 3x HSSAER_ClkLS

        --============================================
        -- Rx Interface from Vision Sensor Controllers
        --============================================

        -- Left Sensor
        ------------------
        -- Parallel AER
        LRx_PAER_Addr_i           	=> data_from_AER_L,
        LRx_PAER_Req_i            	=> req_from_AER_L,
        LRx_PAER_Ack_o            	=> ack_to_AER_L,

        -- HSSAER interface
        LRx_HSSAER_i              	=> (others=> '0'),

        -- GTP interface


        -- Right Sensor
        ------------------
        -- Parallel AER
        RRx_PAER_Addr_i           	=> data_from_AER_R,
        RRx_PAER_Req_i            	=> req_from_AER_R,
        RRx_PAER_Ack_o            	=> ack_to_AER_R,

        -- HSSAER interface
        RRx_HSSAER_i              	=> (others=> '0'),

        -- GTP interface

        -- Aux Sensor
        ------------------
        -- Parallel AER
        AuxRx_PAER_Addr_i         	=> data_from_AER_Aux,
        AuxRx_PAER_Req_i          	=> req_from_AER_Aux,
        AuxRx_PAER_Ack_o          	=> ack_to_AER_Aux,

        -- HSSAER interface
        AuxRx_HSSAER_i            	=> (others=> '0'),

        -- GTP interface

        -- SpiNNlink interface
        LRx_data_2of7_from_spinnaker_i   => LRx_data_2of7_from_spinnaker,   -- in  std_logic_vector(6 downto 0); 
        LRx_ack_to_spinnaker_o           => LRx_ack_to_spinnaker,           -- out std_logic;
        RRx_data_2of7_from_spinnaker_i   => RRx_data_2of7_from_spinnaker,   -- in  std_logic_vector(6 downto 0); 
        RRx_ack_to_spinnaker_o           => RRx_ack_to_spinnaker,           -- out std_logic;
        AuxRx_data_2of7_from_spinnaker_i => AuxRx_data_2of7_from_spinnaker, -- in  std_logic_vector(6 downto 0); 
        AuxRx_ack_to_spinnaker_o         => AuxRx_ack_to_spinnaker,         -- out std_logic;

        --============================================
        -- Tx Interface
        --============================================

        -- Parallel AER
        Tx_PAER_Addr_o            	=> data_to_AER_Tx,
        Tx_PAER_Req_o             	=> req_to_AER_Tx,
        Tx_PAER_Ack_i             	=> ack_from_AER_Tx,

        -- HSSAER interface
        Tx_HSSAER_o               	=> open,

        -- GTP interface

        -- SpiNNlink interface
        Tx_data_2of7_to_spinnaker_o  => Tx_data_2of7_to_spinnaker,  --   : out std_logic_vector(6 downto 0);
        Tx_ack_from_spinnaker_i      => Tx_ack_from_spinnaker,      --   : in  std_logic;
        
        --============================================
        -- Configuration interface
        --============================================
        DefLocFarLpbk_i   			=> '0',
        DefLocNearLpbk_i  			=> '0',

        --============================================
        -- Processor interface
        --============================================
        Interrupt_o       			=> open,

        -- Debug signals interface
        DBG_dataOk        			=> open,
        DBG_rawi          			=> open,
        DBG_data_written  			=> open,
        DBG_dma_burst_counter 		=> open,
        DBG_dma_test_mode      		=> open,
        DBG_dma_EnableDma      		=> open,
        DBG_dma_is_running     		=> open,
        DBG_dma_Length         		=> open,
        DBG_dma_nedge_run      		=> open,
                                    

        -- ADD USER PORTS ABOVE THIS LINE ------------------

        -- DO NOT EDIT BELOW THIS LINE ---------------------
        -- Bus protocol ports, do not add to or delete
        -- Axi lite I/f
        S_AXI_ACLK        			=> HSSAER_ClkLS_p,
        S_AXI_ARESETN     			=> i_resetn,
        S_AXI_AWADDR      			=> s_axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto 0),
        S_AXI_AWVALID     			=> s_axi_awvalid,
        S_AXI_WDATA       			=> s_axi_wdata,
        S_AXI_WSTRB       			=> s_axi_wstrb,
        S_AXI_WVALID      			=> s_axi_wvalid,
        S_AXI_BREADY      			=> s_axi_bready,
        S_AXI_ARADDR      			=> s_axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto 0),
        S_AXI_ARVALID     			=> s_axi_arvalid,
        S_AXI_RREADY      			=> s_axi_rready,
        S_AXI_ARREADY     			=> s_axi_arready,
        S_AXI_RDATA       			=> s_axi_rdata,
        S_AXI_RRESP       			=> s_axi_rresp,
        S_AXI_RVALID      			=> s_axi_rvalid,
        S_AXI_WREADY      			=> s_axi_wready,
        S_AXI_BRESP       			=> s_axi_bresp,
        S_AXI_BVALID      			=> s_axi_bvalid,
        S_AXI_AWREADY     			=> s_axi_awready,
        -- Axi Stream I/f
        S_AXIS_TREADY     			=>  s_axis_tready, -- open,			  -- : out std_logic;
        S_AXIS_TDATA      			=>  s_axis_tdata,  -- (others => '0'),	  -- : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST      			=>  s_axis_tlast,  -- '0',				  -- : in  std_logic;
        S_AXIS_TVALID     			=>  s_axis_tvalid, -- '0',				  -- : in  std_logic;
        M_AXIS_TVALID     			=>  m_axis_tvalid, -- open, 			  -- : out std_logic;
        M_AXIS_TDATA      			=>  m_axis_tdata,  -- open, 			  -- : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST      			=>  m_axis_tlast,  -- open, 			  -- : out std_logic;
        M_AXIS_TREADY     			=>  M_Axis_TREADY_HPU, -- : in  std_logic;
        -- DO NOT EDIT ABOVE THIS LINE ---------------------

        DBG_din             		=> open,
        DBG_wr_en           		=> open,
        DBG_rd_en           		=> open,
        DBG_dout            		=> open,
        DBG_full            		=> open,
        DBG_almost_full     		=> open,
        DBG_overflow        		=> open,
        DBG_empty           		=> open,
        DBG_almost_empty    		=> open,
        DBG_underflow       		=> open,
        DBG_data_count      		=> open,
        DBG_CH0_DATA        		=> open,
        DBG_CH0_SRDY        		=> open,
        DBG_CH0_DRDY        		=> open,
        DBG_CH1_DATA        		=> open,
        DBG_CH1_SRDY        		=> open,
        DBG_CH1_DRDY        		=> open,
        DBG_CH2_DATA        		=> open,
        DBG_CH2_SRDY        		=> open,
        DBG_CH2_DRDY        		=> open,
        DBG_Timestamp_xD    		=> open,
        DBG_MonInAddr_xD    		=> open,
        DBG_MonInSrcRdy_xS  		=> open,
        DBG_MonInDstRdy_xS  		=> open,
        DBG_RESETFIFO       		=> open,
        DBG_CTRG_reg        		=> open,
        DBG_ctrl_rd         		=> open,
        DBG_src_rdy         		=> open,
        DBG_dst_rdy         		=> open,
        DBG_err             		=> open, 
        DBG_run             		=> open,
        DBG_RX              		=> open,
        DBG_AUXRxSaerChanEn 		=> open,

        DBG_shreg_aux0      		=> open,
        DBG_shreg_aux1      		=> open,
        DBG_shreg_aux2      		=> open,
        DBG_FIFO_0          		=> open,
        DBG_FIFO_1          		=> open,
        DBG_FIFO_2          		=> open,
        DBG_FIFO_3          		=> open,
        DBG_FIFO_4          		=> open
    );


-- s_axis_tready <= '1';
 

i_resetn <= not i_reset;

		-- Stimulus process
    
i_rst_in    <= '0', '1' after 150 ns;
i_en        <= '0', '1' after 300 ns;
i_FromSpeed <= 0.0, 2000.0 after 400 ns;

Reset_Proc : process
	begin
		i_reset <= '0';
		wait for 1 us;
		i_reset <= '1';
		wait for 1 us;
		wait until (HSSAER_ClkLS_p'event and HSSAER_ClkLS_p='1');
		i_reset <= '0';
		wait;
end process Reset_Proc;

Start_Proc : process
	begin
		i_start <= '0';
		wait for 10 us;
		wait until (HSSAER_ClkLS_p'event and HSSAER_ClkLS_p='1');
		i_start <= '1';
		wait;
end process Start_Proc;

Enable_AER_Proc : process
	begin
		AER_device_enable_L   <= '0';
		AER_device_enable_R   <= '0';
		AER_device_enable_Aux <= '0';
		AER_device_enable_Tx  <= '0';

		wait for 100 us;
		AER_device_enable_L   <= '0';
		AER_device_enable_R   <= '0';
		AER_device_enable_Aux <= '1';
		AER_device_enable_Tx  <= '0';
		wait;
end process Enable_AER_Proc;

Enable_SPNN_Proc : process
	begin
		SPNN_device_enable_L   <= '1';
		SPNN_device_enable_R   <= '1';
		SPNN_device_enable_Aux <= '1';
		SPNN_device_enable_Tx  <= '1';

		wait for 100 us;
		SPNN_device_enable_L   <= '1';
		SPNN_device_enable_R   <= '1';
		SPNN_device_enable_Tx  <= '1';
		
		wait for 348 us;
	    SPNN_device_enable_Aux <= '1';
		wait;
end process Enable_SPNN_Proc;

Axis_HPU_proc : process
	begin
		M_Axis_TREADY_HPU   <= '1';

--		wait for 2000 us;
--		M_Axis_TREADY_HPU   <= '0';
		wait;
end process Axis_HPU_proc;

LS_Clock_Proc : process
	begin
		HSSAER_ClkLS_p <= '0';
		HSSAER_ClkLS_n <= '1';
		wait until i_resetn='1';
		loop
			HSSAER_ClkLS_p <= not HSSAER_ClkLS_p;
			HSSAER_ClkLS_n <= not HSSAER_ClkLS_n;
			wait for T_HSCLK * 3;
		end loop;
end process LS_Clock_Proc;

HS_Clock_Proc : process
	begin
		HSSAER_ClkHS_p <= '0';
		HSSAER_ClkHS_n <= '1';
		wait until i_resetn='1';
		loop
			HSSAER_ClkHS_p <= not HSSAER_ClkHS_p;
			HSSAER_ClkHS_n <= not HSSAER_ClkHS_n;
			wait for T_HSCLK;
		end loop;
end process HS_Clock_Proc;

END;
