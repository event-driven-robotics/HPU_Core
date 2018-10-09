-------------------------------------------------------------------------------
-- neuserial_core
-------------------------------------------------------------------------------

-- ------------------------------------------------------------------------------
-- 
--  Revision 1.1:  07/25/2018
--  - Added SpiNNlink capabilities
--    (M. Casti - IIT)
--    
-- ------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library HPU_lib;
    use HPU_lib.aer_pkg.all;

library neuserial_lib;
    use neuserial_lib.NSComponents_pkg.all;

library neuelab_lib;
    use neuelab_lib.NEComponents_pkg.all;

library datapath_lib;
    use datapath_lib.DPComponents_pkg.neuserial_PAER_arbiter;
	
library spinn_neu_if_lib;
	use spinn_neu_if_lib.spinn_neu_pkg.all;


--****************************
--   PORT DECLARATION
--****************************

entity neuserial_core is
    generic (
        C_PAER_DSIZE            : natural range 1 to 29   := 24;
        C_RX_HAS_PAER           : boolean                 := true;
        C_RX_HAS_HSSAER         : boolean                 := true;
        C_RX_HSSAER_N_CHAN      : natural range 1 to 4    := 3;
        C_RX_HAS_GTP            : boolean                 := true;
        C_RX_HAS_SPNNLNK        : boolean                 := true;
        C_TX_HAS_PAER           : boolean                 := true;
        C_TX_HAS_HSSAER         : boolean                 := true;
        C_TX_HSSAER_N_CHAN      : natural range 1 to 4    := 2;
        C_TX_HAS_GTP            : boolean                 := true;
        C_TX_HAS_SPNNLNK        : boolean                 := true;
		C_PSPNNLNK_WIDTH      	: natural range 1 to 32   := 32
    );
    port (
        --
        -- Clocks & Reset
        ---------------------
        nRst              : in  std_logic;
        Clk_core          : in  std_logic;
        ClkLS_p           : in  std_logic;
        ClkLS_n           : in  std_logic;
        ClkHS_p           : in  std_logic;
        ClkHS_n           : in  std_logic;

        --
        -- TX DATA PATH
        ---------------------
        -- Parallel AER
        Tx_PAER_Addr_o    : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
        Tx_PAER_Req_o     : out std_logic;
        Tx_PAER_Ack_i     : in  std_logic;
        -- HSSAER channels
        Tx_HSSAER_o       : out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
        -- GTP lines

        --
        -- RX Left DATA PATH
        ---------------------
        -- Parallel AER
        LRx_PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        LRx_PAER_Req_i    : in  std_logic;
        LRx_PAER_Ack_o    : out std_logic;
        -- HSSAER channels
        LRx_HSSAER_i      : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
        -- GTP lines

        --
        -- RX Right DATA PATH
        ---------------------
        -- Parallel AER
        RRx_PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        RRx_PAER_Req_i    : in  std_logic;
        RRx_PAER_Ack_o    : out std_logic;
        -- HSSAER channels
        RRx_HSSAER_i      : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
        -- GTP lines

        --
        -- Aux DATA PATH
        ---------------------
        -- Parallel AER
        AuxRx_PAER_Addr_i : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        AuxRx_PAER_Req_i  : in  std_logic;
        AuxRx_PAER_Ack_o  : out std_logic;
        -- HSSAER channels 
        AuxRx_HSSAER_i    : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
		
        --
        -- SpiNNlink DATA PATH
        ---------------------
        -- input SpiNNaker link interface
        LRx_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
        LRx_ack_to_spinnaker_o           : out std_logic;
        RRx_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
        RRx_ack_to_spinnaker_o           : out std_logic;
        AuxRx_data_2of7_from_spinnaker_i : in  std_logic_vector(6 downto 0); 
        AuxRx_ack_to_spinnaker_o         : out std_logic;
        -- output SpiNNaker link interface
        Tx_data_2of7_to_spinnaker_o      : out std_logic_vector(6 downto 0);
        Tx_ack_from_spinnaker_i          : in  std_logic;

        --
        -- FIFOs interfaces
        ---------------------
        FifoCoreDat_o         : out std_logic_vector(31 downto 0);
        FifoCoreRead_i        : in  std_logic;
        FifoCoreEmpty_o       : out std_logic;
        FifoCoreAlmostEmpty_o : out std_logic;
        FifoCoreBurstReady_o  : out std_logic;
        FifoCoreFull_o        : out std_logic;
        FifoCoreNumData_o     : out std_logic_vector(10 downto 0);

        --
        CoreFifoDat_i         : in  std_logic_vector(31 downto 0);
        CoreFifoWrite_i       : in  std_logic;
        CoreFifoFull_o        : out std_logic;
        CoreFifoAlmostFull_o  : out std_logic;
        CoreFifoEmpty_o       : out std_logic;

        -----------------------------------------------------------------------
        -- uController Interface
        ---------------------
        -- Control
        CleanTimer_i            : in  std_logic;
        FlushFifos_i            : in  std_logic;
        --TxEnable_i              : in  std_logic;
        --TxPaerFlushFifos_i      : in  std_logic;
        --LRxEnable_i             : in  std_logic;
        --RRxEnable_i             : in  std_logic;
        LRxPaerFlushFifos_i     : in  std_logic;
        RRxPaerFlushFifos_i     : in  std_logic;
        AuxRxPaerFlushFifos_i   : in  std_logic;
        FullTimestamp_i         : in  std_logic;

        -- Configurations
        DmaLength_i             : in  std_logic_vector(10 downto 0);
        RemoteLoopback_i        : in  std_logic;
        LocNearLoopback_i       : in  std_logic;
        LocFarLPaerLoopback_i   : in  std_logic;
        LocFarRPaerLoopback_i   : in  std_logic;
        LocFarAuxPaerLoopback_i : in  std_logic;
        LocFarLSaerLoopback_i   : in  std_logic;
        LocFarRSaerLoopback_i   : in  std_logic;
        LocFarAuxSaerLoopback_i : in  std_logic;
        LocFarSaerLpbkCfg_i     : in  t_XConCfg;
        LocFarSpnnLnkLoopbackSel_i : in  std_logic_vector(1 downto 0);

        TxPaerEn_i              : in  std_logic;
        TxHSSaerEn_i            : in  std_logic;
        TxGtpEn_i               : in  std_logic;
        TxSpnnLnkEn_i           : in  std_logic;
        TxDestSwitch_i          : in  std_logic_vector(2 downto 0);
        --TxPaerIgnoreFifoFull_i  : in  std_logic;
        TxPaerReqActLevel_i     : in  std_logic;
        TxPaerAckActLevel_i     : in  std_logic;
        TxSaerChanEn_i          : in  std_logic_vector(C_TX_HSSAER_N_CHAN-1 downto 0);
        --TxSaerChanCfg_i         : in  t_hssaerCfg_array(C_TX_HSSAER_N_CHAN-1 downto 0);

        LRxPaerEn_i             : in  std_logic;
        RRxPaerEn_i             : in  std_logic;
        AuxRxPaerEn_i           : in  std_logic;
        LRxHSSaerEn_i           : in  std_logic;
        RRxHSSaerEn_i           : in  std_logic;
        AuxRxHSSaerEn_i         : in  std_logic;
        LRxGtpEn_i              : in  std_logic;
        RRxGtpEn_i              : in  std_logic;
        AuxRxGtpEn_i            : in  std_logic;
        LRxSpnnLnkEn_i          : in  std_logic;
        RRxSpnnLnkEn_i          : in  std_logic;
        AuxRxSpnnLnkEn_i        : in  std_logic;
        LRxSaerChanEn_i         : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        RRxSaerChanEn_i         : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        AuxRxSaerChanEn_i       : in  std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        RxPaerReqActLevel_i     : in  std_logic;
        RxPaerAckActLevel_i     : in  std_logic;
        RxPaerIgnoreFifoFull_i  : in  std_logic;
        RxPaerAckSetDelay_i     : in  std_logic_vector(7 downto 0);
        RxPaerSampleDelay_i     : in  std_logic_vector(7 downto 0);
        RxPaerAckRelDelay_i     : in  std_logic_vector(7 downto 0);

        -- Status
        WrapDetected_o          : out   std_logic;

        --TxPaerFifoEmpty_o       : out std_logic;
        TxSaerStat_o            : out t_TxSaerStat_array(C_TX_HSSAER_N_CHAN-1 downto 0);

		LRxPaerFifoFull_o       : out std_logic;
		RRxPaerFifoFull_o       : out std_logic;
		AuxRxPaerFifoFull_o     : out std_logic;
        LRxSaerStat_o           : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
        RRxSaerStat_o           : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
        AuxRxSaerStat_o         : out t_RxSaerStat_array(C_RX_HSSAER_N_CHAN-1 downto 0);
        
        TxSpnnlnkStat_o         : out t_TxSpnnlnkStat;
        LRxSpnnlnkStat_o        : out t_RxSpnnlnkStat;
        RRxSpnnlnkStat_o        : out t_RxSpnnlnkStat;
        AuxRxSpnnlnkStat_o      : out t_RxSpnnlnkStat;
        
        Spnn_cmd_start_key_i    : in  std_logic_vector(31 downto 0);  -- SpiNNaker "START to send data" command 
        Spnn_cmd_stop_key_i     : in  std_logic_vector(31 downto 0);  -- SpiNNaker "STOP to send data" command  
        Spnn_tx_mask_i          : in  std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
        Spnn_rx_mask_i          : in  std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 
        
        --
        -- LED drivers
        ---------------------
        LEDo_o            : out std_logic;
        LEDr_o            : out std_logic;
        LEDy_o            : out std_logic;

        --
        -- DEBUG SIGNALS
        ---------------------
        DBG_dataOk        : out std_logic;

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
        DBG_src_rdy         : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        DBG_dst_rdy         : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        DBG_err             : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);  
        DBG_run             : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        DBG_RX              : out std_logic_vector(C_RX_HSSAER_N_CHAN-1 downto 0);
        DBG_FIFO_0          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_1          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_2          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_3          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
        DBG_FIFO_4          : out std_logic_vector(C_INTERNAL_DSIZE-1 downto 0)

            
    );
-- translate_off
begin
    -- check the consistency of the generics
    assert (C_INTERNAL_DSIZE >= (C_PAER_DSIZE+3))
        report  "C_PAER_DSIZE should be at least " & string(integer'image(C_INTERNAL_DSIZE-4)) & "with current value" & CR &
                "of C_INTERNAL_DSIZE constant (see package aer_pkg)"
        severity failure;
-- translate_on
end entity neuserial_core;


--****************************
--   IMPLEMENTATION
--****************************

architecture str of neuserial_core is

    -----------------------------------------------------------------------------
    -- constants
    -----------------------------------------------------------------------------
    --
    -- this is the number of cycles the level on req has to be stable in order for
    -- a value change to be detected (and not interpreted as a possible glitch)
    --constant c_ReqStableCycles                      : positive := 31;
    --
    --constant c_SIFReqDelayCycles                    : natural  := 2;
    --constant c_SIFAckStableCycles                   : natural  := 3;
    --
    --constant c_DVS_SCX                              : boolean  := false;
    --
    constant c_TestEnableSequencerNoWait            : boolean  := false;
    constant c_TestEnableSequencerToMonitorLoopback : boolean  := false;
    constant c_EnableMonitorControlsSequencerToo    : boolean  := false;
    --
    --constant cTestEnableNoGaepButGenCounter        : boolean  := false;
    --constant c_LRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0000";
    --constant c_LRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0100";
    --constant c_LRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "1000";
    --constant c_RRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0001";
    --constant c_RRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "0101";
    --constant c_RRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  "1001";

    constant c_RIGHT_EYE : std_logic_vector(1 downto 0) := "01";
    constant c_LEFT_EYE  : std_logic_vector(1 downto 0) := "00";
    constant c_AUX1      : std_logic_vector(1 downto 0) := "10";
    constant c_PAER_SRC  : std_logic_vector(1 downto 0) := "00";
    constant c_SAER_SRC  : std_logic_vector(1 downto 0) := "01";
    constant c_GTP_SRC   : std_logic_vector(1 downto 0) := "10";

    -- This header coding comes from AERsensorsMap.xlsx (svn version r12867)
    constant C_EVENT_TYPE_ADDRESS   : std_logic := '0';
    constant C_EVENT_TYPE_TIMESTAMP : std_logic := '1';
    constant C_RESERVED             : std_logic_vector(C_INTERNAL_DSIZE-C_PAER_DSIZE-4-1 downto 0) := (others => '0');
    constant C_SRC_ID_CAMERA        : std_logic_vector(2 downto 0) := "000";
    constant C_SRC_ID_AUX_SKIN_SENS : std_logic_vector(2 downto 0) := "001";
    constant C_SRC_ID_OTHER_SENS    : std_logic_vector(2 downto 0) := "X1X";
    constant c_zero_vect : std_logic_vector(C_INTERNAL_DSIZE-C_PAER_DSIZE-4-1 downto 0) := (others => '0');

    constant c_LRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_CAMERA;
    constant c_LRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_CAMERA;
    constant c_LRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_CAMERA;
    constant c_RRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_CAMERA;
    constant c_RRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_CAMERA;
    constant c_RRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_CAMERA;
    constant c_AuxRxPaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_AUX_SKIN_SENS;
    constant c_AuxRxSaerHighBits : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_AUX_SKIN_SENS;
    constant c_AuxRxGtpHighBits  : std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE) :=  C_EVENT_TYPE_ADDRESS & c_zero_vect & C_SRC_ID_AUX_SKIN_SENS;


    -----------------------------------------------------------------------------
    -- types
    -----------------------------------------------------------------------------


    -----------------------------------------------------------------------------
    -- signals
    -----------------------------------------------------------------------------
	signal	Rst				 : std_logic;
	
    signal  i_rxMonSrc       : t_PaerSrc_array(2 downto 0);
    signal  i_rxMonDst       : t_PaerDst_array(2 downto 0);

    signal  i_txSeqData      : std_logic_vector(31 downto 0);
    signal  i_txSeqSrcRdy    : std_logic;
    signal  i_txSeqDstRdy    : std_logic;

    signal  i_rxMonData      : std_logic_vector(31 downto 0);
    signal  i_rxMonSrcRdy    : std_logic;
    signal  i_rxMonDstRdy    : std_logic;

    signal  i_seqData        : std_logic_vector(31 downto 0);
    signal  i_seqSrcRdy      : std_logic;
    signal  i_seqDstRdy      : std_logic;

    signal  i_monData        : std_logic_vector(31 downto 0);
    signal  i_monSrcRdy      : std_logic;
    signal  i_monDstRdy      : std_logic;

    signal  i_Tx_PAER_Addr   : std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_Tx_PAER_Req    : std_logic;
    signal  i_Tx_PAER_Ack    : std_logic;
    signal  ii_Tx_PAER_Req   : std_logic;
    signal  ii_Tx_PAER_Ack   : std_logic;

    signal  i_LRx_PAER_Addr  : std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_LRx_PAER_Req   : std_logic;
    signal  i_LRx_PAER_Ack   : std_logic;
    signal  ii_LRx_PAER_Req  : std_logic;
    signal  ii_LRx_PAER_Ack  : std_logic;

    signal  i_RRx_PAER_Addr  : std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_RRx_PAER_Req   : std_logic;
    signal  i_RRx_PAER_Ack   : std_logic;
    signal  ii_RRx_PAER_Req  : std_logic;
    signal  ii_RRx_PAER_Ack  : std_logic;

    signal  i_AuxRx_PAER_Addr: std_logic_vector(C_PAER_DSIZE-1 downto 0);
    signal  i_AuxRx_PAER_Req : std_logic;
    signal  i_AuxRx_PAER_Ack : std_logic;
    signal  ii_AuxRx_PAER_Req: std_logic;
    signal  ii_AuxRx_PAER_Ack: std_logic;

    signal  i_Tx_HSSAER      : std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
    signal  i_LRx_HSSAER     : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    signal  i_RRx_HSSAER     : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    signal  i_AuxRx_HSSAER   : std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
    
    signal  i_LRx_data_2of7_from_spinnaker : std_logic_vector(6 downto 0);
    signal  i_LRx_ack_to_spinnaker         : std_logic;
    signal  i_RRx_data_2of7_from_spinnaker : std_logic_vector(6 downto 0);
    signal  i_RRx_ack_to_spinnaker         : std_logic;
    signal  i_AuxRx_data_2of7_from_spinnaker : std_logic_vector(6 downto 0);
    signal  i_AuxRx_ack_to_spinnaker         : std_logic;
    signal  i_Tx_data_2of7_to_spinnaker   : std_logic_vector(6 downto 0);
    signal  i_TX_ack_from_spinnaker       : std_logic;
    
    signal  i_Spnn_cmd_start              : std_logic;   -- SpiNNaker "START to send data" command 
    signal  i_Spnn_cmd_stop               : std_logic;   -- SpiNNaker "STOP to send data" command  
    signal  i_Spnn_tx_mask                : std_logic_vector(31 downto 0);  -- SpiNNaker TX Data Mask
    signal  i_Spnn_rx_mask                : std_logic_vector(31 downto 0);  -- SpiNNaker RX Data Mask 


--    for all : neuserial_loopback     use entity neuserial_lib.neuserial_loopback(beh);
--    for all : hpu_tx_datapath        use entity datapath_lib.hpu_tx_datapath(str);
--    for all : hpu_rx_datapath        use entity datapath_lib.hpu_rx_datapath(str);
--    for all : neuserial_PAER_arbiter use entity datapath_lib.neuserial_PAER_arbiter(rtl);
--    for all : CoreMonSeqRR           use entity neuelab_lib.CoreMonSeqRR(str);


begin

	Rst <= not nRst;

    -- PAER Req and acknowledge polarity
    --
    Tx_PAER_Req_o   <= ii_Tx_PAER_Req  xnor TxPaerReqActLevel_i;
    ii_Tx_PAER_Ack  <= Tx_PAER_Ack_i   xnor TxPaerAckActLevel_i;

    ii_LRx_PAER_Req <= LRx_PAER_Req_i  xnor RxPaerReqActLevel_i;
    LRx_PAER_Ack_o  <= ii_LRx_PAER_Ack xnor RxPaerAckActLevel_i;

    ii_RRx_PAER_Req <= RRx_PAER_Req_i  xnor RxPaerReqActLevel_i;
    RRx_PAER_Ack_o  <= ii_RRx_PAER_Ack xnor RxPaerAckActLevel_i;

    ii_AuxRx_PAER_Req <= AuxRx_PAER_Req_i  xnor RxPaerReqActLevel_i;
    AuxRx_PAER_Ack_o  <= ii_AuxRx_PAER_Ack xnor RxPaerAckActLevel_i;

    ------------------------
    -- Local Far Loopback
    ------------------------

    u_neuserial_loopback : neuserial_loopback
        generic map (
            C_PAER_DSIZE          => C_PAER_DSIZE,
            C_RX_HSSAER_N_CHAN    => C_RX_HSSAER_N_CHAN,
            C_TX_HSSAER_N_CHAN    => C_TX_HSSAER_N_CHAN
        )
        port map (
            Rx1PaerLpbkEn         => LocFarLPaerLoopback_i,      -- in  std_logic;
            Rx2PaerLpbkEn         => LocFarRPaerLoopback_i,      -- in  std_logic;
            Rx3PaerLpbkEn         => LocFarAuxPaerLoopback_i,    -- in  std_logic;
            Rx1SaerLpbkEn         => LocFarLSaerLoopback_i,      -- in  std_logic;
            Rx2SaerLpbkEn         => LocFarRSaerLoopback_i,      -- in  std_logic;
            Rx3SaerLpbkEn         => LocFarAuxSaerLoopback_i,    -- in  std_logic;
            XConSerCfg            => LocFarSaerLpbkCfg_i,        -- in  t_XConCfg;
            RxSpnnLnkLpbkEnSel    => LocFarSpnnLnkLoopbackSel_i, -- in  std_logic_vector(1 downto 0);

            -- Parallel AER
            ExtTxPAER_Addr_o      => Tx_PAER_Addr_o,             -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
            ExtTxPAER_Req_o       => ii_Tx_PAER_Req,             -- out std_logic;
            ExtTxPAER_Ack_i       => ii_Tx_PAER_Ack,             -- in  std_logic;

            ExtRx1PAER_Addr_i     => LRx_PAER_Addr_i,            -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            ExtRx1PAER_Req_i      => ii_LRx_PAER_Req,            -- in  std_logic;
            ExtRx1PAER_Ack_o      => ii_LRx_PAER_Ack,            -- out std_logic;

            ExtRx2PAER_Addr_i     => RRx_PAER_Addr_i,            -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            ExtRx2PAER_Req_i      => ii_RRx_PAER_Req,            -- in  std_logic;
            ExtRx2PAER_Ack_o      => ii_RRx_PAER_Ack,            -- out std_logic;

            ExtRx3PAER_Addr_i     => AuxRx_PAER_Addr_i,          -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            ExtRx3PAER_Req_i      => ii_AuxRx_PAER_Req,          -- in  std_logic;
            ExtRx3PAER_Ack_o      => ii_AuxRx_PAER_Ack,          -- out std_logic;

            -- HSSAER
            ExtTxHSSAER_Tx_o      => Tx_HSSAER_o,                -- out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
            ExtRx1HSSAER_Rx_i     => LRx_HSSAER_i,               -- in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
            ExtRx2HSSAER_Rx_i     => RRx_HSSAER_i,               -- in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
            ExtRx3HSSAER_Rx_i     => AuxRx_HSSAER_i,             -- in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);

            -- GTP interface
            --
            -- TBD signals to drive the GTP module
            --
            -- SpiNNlink interface
            ExtTx_data_2of7_to_spinnaker_o      => Tx_data_2of7_to_spinnaker_o,     -- out std_logic_vector(6 downto 0);
            ExtTx_ack_from_spinnaker_i          => Tx_ack_from_spinnaker_i,         -- in  std_logic;
            ExtRx1_data_2of7_from_spinnaker_i   => LRx_data_2of7_from_spinnaker_i,  -- in  std_logic_vector(6 downto 0); 
            ExtRx1_ack_to_spinnaker_o           => LRx_ack_to_spinnaker_o,          -- out std_logic;
            ExtRx2_data_2of7_from_spinnaker_i   => RRx_data_2of7_from_spinnaker_i,  -- in  std_logic_vector(6 downto 0); 
            ExtRx2_ack_to_spinnaker_o           => RRx_ack_to_spinnaker_o,          -- out std_logic;
            ExtRx3_data_2of7_from_spinnaker_i   => AuxRx_data_2of7_from_spinnaker_i,-- in  std_logic_vector(6 downto 0); 
            ExtRx3_ack_to_spinnaker_o           => AuxRx_ack_to_spinnaker_o,        -- out std_logic;
            
          
            -- Parallel AER
            CoreTxPAER_Addr_i     => i_Tx_PAER_Addr,             -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            CoreTxPAER_Req_i      => i_Tx_PAER_Req,              -- in  std_logic;
            CoreTxPAER_Ack_o      => i_Tx_PAER_Ack,              -- out std_logic;

            CoreRx1PAER_Addr_o    => i_LRx_PAER_Addr,            -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
            CoreRx1PAER_Req_o     => i_LRx_PAER_Req,             -- out std_logic;
            CoreRx1PAER_Ack_i     => i_LRx_PAER_Ack,             -- in  std_logic;

            CoreRx2PAER_Addr_o    => i_RRx_PAER_Addr,            -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
            CoreRx2PAER_Req_o     => i_RRx_PAER_Req,             -- out std_logic;
            CoreRx2PAER_Ack_i     => i_RRx_PAER_Ack,             -- in  std_logic;

            CoreRx3PAER_Addr_o    => i_AuxRx_PAER_Addr,          -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
            CoreRx3PAER_Req_o     => i_AuxRx_PAER_Req,           -- out std_logic;
            CoreRx3PAER_Ack_i     => i_AuxRx_PAER_Ack,           -- in  std_logic;

            -- HSSAER
            CoreTxHSSAER_Tx_i     => i_Tx_HSSAER,                -- in  std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
            CoreRx1HSSAER_Rx_o    => i_LRx_HSSAER,               -- out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
            CoreRx2HSSAER_Rx_o    => i_RRx_HSSAER,               -- out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
            CoreRx3HSSAER_Rx_o    => i_AuxRx_HSSAER,             -- out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1)

            -- GTP interface
            --
            -- TBD signals to drive the GTP module
            --

            -- SpiNNlink interface
            CoreTx_data_2of7_to_spinnaker_i     => i_Tx_data_2of7_to_spinnaker,     -- in  std_logic_vector(6 downto 0);
            CoreTx_ack_from_spinnaker_o         => i_Tx_ack_from_spinnaker,         -- out std_logic;
            CoreRx1_data_2of7_from_spinnaker_o  => i_LRx_data_2of7_from_spinnaker,  -- out std_logic_vector(6 downto 0); 
            CoreRx1_ack_to_spinnaker_i          => i_LRx_ack_to_spinnaker,          -- in  std_logic;
            CoreRx2_data_2of7_from_spinnaker_o  => i_RRx_data_2of7_from_spinnaker,  -- out std_logic_vector(6 downto 0); 
            CoreRx2_ack_to_spinnaker_i          => i_RRx_ack_to_spinnaker,          -- in  std_logic;
            CoreRx3_data_2of7_from_spinnaker_o  => i_AuxRx_data_2of7_from_spinnaker,-- out std_logic_vector(6 downto 0); 
            CoreRx3_ack_to_spinnaker_i          => i_AuxRx_ack_to_spinnaker         -- in  std_logic
        );

    
    ---------------------
    -- TX path
    ---------------------

    u_tx_datapath : hpu_tx_datapath
        generic map (
            C_INPUT_DSIZE    => 32,
            C_PAER_DSIZE     => C_PAER_DSIZE,
            C_HAS_PAER       => C_TX_HAS_PAER,
            C_HAS_HSSAER     => C_TX_HAS_HSSAER,
            C_HSSAER_N_CHAN  => C_TX_HSSAER_N_CHAN,
            C_HAS_GTP        => C_TX_HAS_GTP,
            C_HAS_SPNNLNK    => C_TX_HAS_SPNNLNK,
            C_PSPNNLNK_WIDTH => C_PSPNNLNK_WIDTH
            
        )
        port map (
            -- Clocks & Reset
            nRst                 => nRst,                        -- in  std_logic;
            Clk_core             => Clk_core,                    -- in  std_logic;
			Clk_ls_p             => ClkLS_p,                     -- in  std_logic;
			Clk_ls_n             => ClkLS_n,                     -- in  std_logic;

            -----------------------------
            -- uController Interface
            -----------------------------

            -- Control signals
            -----------------------------
            --EnableIp_i           => TxEnable_i,                  -- in  std_logic;
			--PaerFlushFifos_i     => TxPaerFlushFifos_i,          -- in  std_logic;

            -- Status signals
            -----------------------------
            --PaerFifoFull_o       => TxPaerFifoEmpty_o,           -- out std_logic;
            TxSaerStat_o         => TxSaerStat_o,                -- out t_TxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
            TxSpnnlnkStat_o      => TxSpnnlnkStat_o,             -- out t_TxSpnnlnkStat;
            
            -- Configuration signals
            -----------------------------
            --
            -- Destination I/F configurations
            EnablePAER_i         => TxPaerEn_i,                  -- in  std_logic;
            EnableHSSAER_i       => TxHSSaerEn_i,                -- in  std_logic;
            EnableGTP_i          => TxGtpEn_i,                   -- in  std_logic;
            EnableSPNNLNK_i      => TxSpnnLnkEn_i,
            DestinationSwitch_i  => TxDestSwitch_i,              -- in  std_logic_vector(2 downto 0);
            -- PAER
            --PaerIgnoreFifoFull_i => TxPaerIgnoreFifoFull_i,      -- in  std_logic;
            PaerReqActLevel_i    => '1',                         -- in  std_logic;
            PaerAckActLevel_i    => '1',                         -- in  std_logic;
            -- HSSAER
            HSSaerChanEn_i       => TxSaerChanEn_i,              -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
            --HSSAERChanCfg_i      => TxHSSaerChanCfg_i,           -- in  t_hssaerCfg_array(C_HSSAER_N_CHAN-1 downto 0);
            -- GTP

            -----------------------------
            -- Sequencer interface
            -----------------------------
            FromSeqDataIn_i      => i_txSeqData,                 -- in  std_logic_vector(C_INPUT_DSIZE-1 downto 0);
            FromSeqSrcRdy_i      => i_txSeqSrcRdy,               -- in  std_logic;
            FromSeqDstRdy_o      => i_txSeqDstRdy,               -- out std_logic;

            -- SpiNNlink controls
            -----------------------------
            Spnn_Dump_on_i      => i_Spnn_cmd_stop,              -- in  std_logic;
            Spnn_Dump_off_i     => i_Spnn_cmd_start,             -- in  std_logic;            
            Spnn_tx_mask_i      => Spnn_tx_mask_i,               -- in  std_logic_vector(31 downto 0);
        
            -----------------------------
            -- Destination interfaces
            -----------------------------
            -- Parallel AER
            PAER_Addr_o          => i_Tx_PAER_Addr,              -- out std_logic_vector(C_PAER_DSIZE-1 downto 0);
            PAER_Req_o           => i_Tx_PAER_Req,               -- out std_logic;
            PAER_Ack_i           => i_Tx_PAER_Ack,               -- in  std_logic;

            -- HSSAER
            HSSAER_Tx_o          => i_Tx_HSSAER,                  -- out std_logic_vector(0 to C_HSSAER_N_CHAN-1)

            -- GTP interface
            --
            -- TBD signals to drive the GTP
            --

		    -- SpiNNlink 
		    data_2of7_to_spinnaker_o	=> i_Tx_data_2of7_to_spinnaker,
		    ack_from_spinnaker_i        => i_Tx_ack_from_spinnaker

            -----------------------------
            -- Debug signals
            -----------------------------
        );
    
   
    
    ---------------------
    -- RX paths
    ---------------------

    u_rx_left_datapath : hpu_rx_datapath
        generic map (
            C_OUTPUT_DSIZE   => C_INTERNAL_DSIZE,
            C_PAER_DSIZE     => C_PAER_DSIZE,
            C_HAS_PAER       => C_RX_HAS_PAER,
            C_HAS_GTP        => C_RX_HAS_GTP,
            C_HAS_HSSAER     => C_RX_HAS_HSSAER,
            C_HSSAER_N_CHAN  => C_RX_HSSAER_N_CHAN,
            C_HAS_SPNNLNK    => C_RX_HAS_SPNNLNK,
            C_PSPNNLNK_WIDTH => C_PSPNNLNK_WIDTH
        )
        port map (
            -- Clocks & Reset
            nRst                 => nRst,                        -- in  std_logic;
            Clk_core             => Clk_core,                    -- in  std_logic;
			Clk_hs_p             => ClkHS_p,                     -- in  std_logic;
			Clk_hs_n             => ClkHS_n,                     -- in  std_logic;
            Clk_ls_p             => ClkLS_p,                     -- in  std_logic;
            Clk_ls_n             => ClkLS_n,                     -- in  std_logic;

            -----------------------------
            -- uController Interface
            -----------------------------

            -- Control signals
            -----------------------------
            --Enable_i             => LRxEnable_i,                 -- in  std_logic;
			PaerFlushFifos_i     => LRxPaerFlushFifos_i,         -- in  std_logic;

            -- Status signals
            -----------------------------
			PaerFifoFull_o       => LRxPaerFifoFull_o,           -- out std_logic;
            RxSaerStat_o         => LRxSaerStat_o,               -- out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
            RxSpnnlnkStat_o      => LRxSpnnlnkStat_o,            -- out t_RxSpnnlnkStat;

            -- Configuration signals
            -----------------------------
            --
            -- Source I/F configurations
            EnablePAER_i         => LRxPaerEn_i,                 -- in  std_logic;
            EnableHSSAER_i       => LRxHSSaerEn_i,               -- in  std_logic;
            EnableGTP_i          => LRxGtpEn_i,                  -- in  std_logic;
            EnableSPNNLNK_i      => LRxSpnnLnkEn_i,              -- in  std_logic;
            -- PAER
            RxPaerHighBits_i     => c_LRxPaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
            PaerReqActLevel_i    => RxPaerReqActLevel_i,         -- in  std_logic;
            PaerAckActLevel_i    => RxPaerAckActLevel_i,         -- in  std_logic;
            PaerIgnoreFifoFull_i => RxPaerIgnoreFifoFull_i,      -- in  std_logic;
            PaerAckSetDelay_i    => RxPaerAckSetDelay_i,         -- in  std_logic_vector(7 downto 0);
            PaerSampleDelay_i    => RxPaerSampleDelay_i,         -- in  std_logic_vector(7 downto 0);
            PaerAckRelDelay_i    => RxPaerAckRelDelay_i,         -- in  std_logic_vector(7 downto 0);
            -- HSSAER
            RxSaerHighbits_i     => c_LRxSaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
            HSSaerChanEn_i       => LRxSaerChanEn_i,             -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
            -- GTP
            RxGtpHighbits_i      => c_LRxGtpHighBits,            -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);

            -- SpiNNlink controls
            -----------------------------
            Spnn_cmd_start_key_i => Spnn_cmd_start_key_i,        -- in  std_logic_vector(31 downto 0);
            Spnn_cmd_stop_key_i  => Spnn_cmd_stop_key_i,         -- in  std_logic_vector(31 downto 0);
            Spnn_cmd_start_o     => open,                        -- out std_logic;
            Spnn_cmd_stop_o      => open,                        -- out std_logic;
            Spnn_rx_mask_i       => Spnn_rx_mask_i,              -- in  std_logic_vector(31 downto 0);
            
            -----------------------------
            -- Source interfaces
            -----------------------------

            -- Parallel AER
            PAER_Addr_i          => i_LRx_PAER_Addr,             -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            PAER_Req_i           => i_LRx_PAER_Req,              -- in  std_logic;
            PAER_Ack_o           => i_LRx_PAER_Ack,              -- out std_logic;

            -- HSSAER
            HSSAER_Rx_i          => i_LRx_HSSAER,                -- in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

            --
            -- GTP interface
            --
            -- TBD signals to drive the GTP module
            --

            -- SpiNNlink
            data_2of7_from_spinnaker_i => i_LRx_data_2of7_from_spinnaker,
            ack_to_spinnaker_o         => i_LRx_ack_to_spinnaker,

            -----------------------------
            -- Monitor Interface
            -----------------------------
            ToMonDataIn_o        => i_rxMonSrc(0).idx,           -- out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
            ToMonSrcRdy_o        => i_rxMonSrc(0).vld,           -- out std_logic;
            ToMonDstRdy_i        => i_rxMonDst(0).rdy,           -- in  std_logic;
        
            -----------------------------
            -- In case of aux channel the HPU header is adapted to what received
            -----------------------------
            Aux_Channel_i        => '0',


            -----------------------------
            -- Debug signals
            -----------------------------
            dbg_PaerDataOk       => open,                         -- out std_logic
            DBG_src_rdy          => open,
            DBG_dst_rdy          => open,
            DBG_err              => open, 
            DBG_run              => open,
            DBG_RX               => open,
	
        	DBG_FIFO_0           => open,
        	DBG_FIFO_1           => open,
        	DBG_FIFO_2           => open,
        	DBG_FIFO_3           => open,
        	DBG_FIFO_4           => open                         
        );

    u_rx_right_datapath : hpu_rx_datapath
        generic map (
            C_OUTPUT_DSIZE   => C_INTERNAL_DSIZE,
            C_PAER_DSIZE     => C_PAER_DSIZE,
            C_HAS_PAER       => C_RX_HAS_PAER,
            C_HAS_GTP        => C_RX_HAS_GTP,
            C_HAS_HSSAER     => C_RX_HAS_HSSAER,
            C_HSSAER_N_CHAN  => C_RX_HSSAER_N_CHAN,
            C_HAS_SPNNLNK    => C_RX_HAS_SPNNLNK,
            C_PSPNNLNK_WIDTH => C_PSPNNLNK_WIDTH
        )
        port map (
            -- Clocks & Reset
            nRst                 => nRst,                        -- in  std_logic;
            Clk_core             => Clk_core,                    -- in  std_logic;
			Clk_hs_p             => ClkHS_p,                     -- in  std_logic;
			Clk_hs_n             => ClkHS_n,                     -- in  std_logic;
            Clk_ls_p             => ClkLS_p,                     -- in  std_logic;
            Clk_ls_n             => ClkLS_n,                     -- in  std_logic;

            -----------------------------
            -- uController Interface
            -----------------------------

            -- Control signals
            -----------------------------
            --Enable_i             => RRxEnable_i,                 -- in  std_logic;
			PaerFlushFifos_i     => RRxPaerFlushFifos_i,         -- in  std_logic;

            -- Status signals
            -----------------------------
			PaerFifoFull_o       => RRxPaerFifoFull_o,           -- out std_logic;
            RxSaerStat_o         => RRxSaerStat_o,               -- out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
            RxSpnnlnkStat_o      => RRxSpnnlnkStat_o,            -- out t_RxSpnnlnkStat;

            -- Configuration signals
            -----------------------------
            --
            -- Source I/F configurations
            EnablePAER_i         => RRxPaerEn_i,                 -- in  std_logic;
            EnableHSSAER_i       => RRxHSSaerEn_i,               -- in  std_logic;
            EnableGTP_i          => RRxGtpEn_I,                  -- in  std_logic;
            EnableSPNNLNK_i      => RRxSpnnLnkEn_i,              -- in  std_logic;
            -- PAER
            RxPaerHighBits_i     => c_RRxPaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
            PaerReqActLevel_i    => RxPaerReqActLevel_i,         -- in  std_logic;
            PaerAckActLevel_i    => RxPaerAckActLevel_i,         -- in  std_logic;
            PaerIgnoreFifoFull_i => RxPaerIgnoreFifoFull_i,      -- in  std_logic;
            PaerAckSetDelay_i    => RxPaerAckSetDelay_i,         -- in  std_logic_vector(7 downto 0);
            PaerSampleDelay_i    => RxPaerSampleDelay_i,         -- in  std_logic_vector(7 downto 0);
            PaerAckRelDelay_i    => RxPaerAckRelDelay_i,         -- in  std_logic_vector(7 downto 0);
            -- HSSAER
            RxSaerHighbits_i     => c_RRxSaerHighBits,           -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
            HSSaerChanEn_i       => RRxSaerChanEn_i,             -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
            -- GTP
            RxGtpHighbits_i      => c_RRxGtpHighBits,            -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);

            -- SpiNNlink controls
            -----------------------------
            Spnn_cmd_start_key_i => Spnn_cmd_start_key_i,        -- in  std_logic_vector(31 downto 0);
            Spnn_cmd_stop_key_i  => Spnn_cmd_stop_key_i,         -- in  std_logic_vector(31 downto 0);
            Spnn_cmd_start_o     => open,                        -- out std_logic;
            Spnn_cmd_stop_o      => open,                        -- out std_logic;
            Spnn_rx_mask_i       => Spnn_rx_mask_i,              -- in  std_logic_vector(31 downto 0);
            
            -----------------------------
            -- Source interfaces
            -----------------------------

            -- Parallel AER
            PAER_Addr_i          => i_RRx_PAER_Addr,             -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            PAER_Req_i           => i_RRx_PAER_Req,              -- in  std_logic;
            PAER_Ack_o           => i_RRx_PAER_Ack,              -- out std_logic;

            -- HSSAER
            HSSAER_Rx_i          => i_RRx_HSSAER,                -- in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

            --
            -- GTP interface
            --
            -- TBD signals to drive the GTP module
            --

            -- SpiNNlink
            data_2of7_from_spinnaker_i => i_RRx_data_2of7_from_spinnaker,
            ack_to_spinnaker_o         => i_RRx_ack_to_spinnaker,

            -----------------------------
            -- Destination Interface
            -----------------------------
            ToMonDataIn_o        => i_rxMonSrc(1).idx,           -- out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
            ToMonSrcRdy_o        => i_rxMonSrc(1).vld,           -- out std_logic;
            ToMonDstRdy_i        => i_rxMonDst(1).rdy,           -- in  std_logic;

            -----------------------------
            -- In case of aux channel the HPU header is adapted to what received
            -----------------------------
            Aux_Channel_i        => '0',

            -----------------------------
            -- Debug signals
            -----------------------------
            dbg_PaerDataOk       => open,                         -- out std_logic
        	DBG_src_rdy          => open,
        	DBG_dst_rdy          => open,
        	DBG_err              => open, 
        	DBG_run              => open,
            DBG_RX               => open,
	
        	DBG_FIFO_0           => open,
        	DBG_FIFO_1           => open,
        	DBG_FIFO_2           => open,
        	DBG_FIFO_3           => open,
        	DBG_FIFO_4           => open            
        );

    u_rx_aux_datapath : hpu_rx_datapath
        generic map (
            C_OUTPUT_DSIZE   => C_INTERNAL_DSIZE,
            C_PAER_DSIZE     => C_PAER_DSIZE,
            C_HAS_PAER       => C_RX_HAS_PAER,
            C_HAS_GTP        => C_RX_HAS_GTP,
            C_HAS_HSSAER     => C_RX_HAS_HSSAER,
            C_HSSAER_N_CHAN  => C_RX_HSSAER_N_CHAN,
            C_HAS_SPNNLNK    => C_RX_HAS_SPNNLNK,
            C_PSPNNLNK_WIDTH => C_PSPNNLNK_WIDTH
        )
        port map (
            -- Clocks & Reset
            nRst                 => nRst,                        -- in  std_logic;
            Clk_core             => Clk_core,                    -- in  std_logic;
			Clk_hs_p             => ClkHS_p,                     -- in  std_logic;
			Clk_hs_n             => ClkHS_n,                     -- in  std_logic;
            Clk_ls_p             => ClkLS_p,                     -- in  std_logic;
            Clk_ls_n             => ClkLS_n,                     -- in  std_logic;

            -----------------------------
            -- uController Interface
            -----------------------------

            -- Control signals
            -----------------------------
            --Enable_i             => AuxRxEnable_i,             -- in  std_logic;
			PaerFlushFifos_i     => AuxRxPaerFlushFifos_i,       -- in  std_logic;

            -- Status signals
            -----------------------------
			PaerFifoFull_o       => AuxRxPaerFifoFull_o,         -- out std_logic;
            RxSaerStat_o         => AuxRxSaerStat_o,             -- out t_RxSaerStat_array(C_HSSAER_N_CHAN-1 downto 0);
            RxSpnnlnkStat_o      => AuxRxSpnnlnkStat_o,          -- out t_RxSpnnlnkStat;

            -- Configuration signals
            -----------------------------
            --
            -- Source I/F configurations
            EnablePAER_i         => AuxRxPaerEn_i,               -- in  std_logic;
            EnableHSSAER_i       => AuxRxHSSaerEn_i,             -- in  std_logic;
            EnableGTP_i          => AuxRxGtpEn_I,                -- in  std_logic;
            EnableSPNNLNK_i      => AuxRxSpnnLnkEn_i,            -- in  std_logic;
            -- PAER
            RxPaerHighBits_i     => c_AuxRxPaerHighBits,         -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
            PaerReqActLevel_i    => RxPaerReqActLevel_i,         -- in  std_logic;
            PaerAckActLevel_i    => RxPaerAckActLevel_i,         -- in  std_logic;
            PaerIgnoreFifoFull_i => RxPaerIgnoreFifoFull_i,      -- in  std_logic;
            PaerAckSetDelay_i    => RxPaerAckSetDelay_i,         -- in  std_logic_vector(7 downto 0);
            PaerSampleDelay_i    => RxPaerSampleDelay_i,         -- in  std_logic_vector(7 downto 0);
            PaerAckRelDelay_i    => RxPaerAckRelDelay_i,         -- in  std_logic_vector(7 downto 0);
            -- HSSAER
            RxSaerHighbits_i     => c_AuxRxSaerHighBits,         -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);
            HSSaerChanEn_i       => AuxRxSaerChanEn_i,           -- in  std_logic_vector(C_HSSAER_N_CHAN-1 downto 0);
            -- GTP
            RxGtpHighbits_i      => c_AuxRxGtpHighBits,          -- in  std_logic_vector(C_INTERNAL_DSIZE-1 downto C_PAER_DSIZE);

            -- SpiNNlink controls
            -----------------------------
            Spnn_cmd_start_key_i => Spnn_cmd_start_key_i,        -- in  std_logic_vector(31 downto 0); -- SpiNNaker "START to send data" command 
            Spnn_cmd_stop_key_i  => Spnn_cmd_stop_key_i,         -- in  std_logic_vector(31 downto 0); -- SpiNNaker "STOP to send data" command  
            Spnn_cmd_start_o     => i_Spnn_cmd_start,            -- out std_logic;
            Spnn_cmd_stop_o      => i_Spnn_cmd_stop,             -- out std_logic;
            Spnn_rx_mask_i       => Spnn_rx_mask_i,              -- in  std_logic_vector(31 downto 0);

            -----------------------------
            -- Source interfaces
            -----------------------------

            -- Parallel AER
            PAER_Addr_i          => i_AuxRx_PAER_Addr,           -- in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
            PAER_Req_i           => i_AuxRx_PAER_Req,            -- in  std_logic;
            PAER_Ack_o           => i_AuxRx_PAER_Ack,            -- out std_logic;

            -- HSSAER
            HSSAER_Rx_i          => i_AuxRx_HSSAER,              -- in  std_logic_vector(0 to C_HSSAER_N_CHAN-1);

            --
            -- GTP interface
            --
            -- TBD signals to drive the GTP module
            --

            -- SpiNNlink
            data_2of7_from_spinnaker_i => i_AuxRx_data_2of7_from_spinnaker,
            ack_to_spinnaker_o         => i_AuxRx_ack_to_spinnaker,

            -----------------------------
            -- Destination Interface
            -----------------------------
            ToMonDataIn_o        => i_rxMonSrc(2).idx,           -- out std_logic_vector(C_OUTPUT_DSIZE-1 downto 0);
            ToMonSrcRdy_o        => i_rxMonSrc(2).vld,           -- out std_logic;
            ToMonDstRdy_i        => i_rxMonDst(2).rdy,           -- in  std_logic;

            -----------------------------
            -- In case of aux channel the HPU header is adapted to what received
            -----------------------------
            Aux_Channel_i        => '1',

            -----------------------------
            -- Debug signals
            -----------------------------
            DBG_src_rdy          => DBG_src_rdy,
            DBG_dst_rdy          => DBG_dst_rdy,
            DBG_err              => DBG_err,     
            DBG_run              => DBG_run,
            DBG_RX               => DBG_RX,
	
        	DBG_FIFO_0           => DBG_FIFO_0,
        	DBG_FIFO_1           => DBG_FIFO_1,
        	DBG_FIFO_2           => DBG_FIFO_2,
        	DBG_FIFO_3           => DBG_FIFO_3,
        	DBG_FIFO_4           => DBG_FIFO_4

        );

    u_RxArbiter : neuserial_PAER_arbiter
        generic map (
            C_NUM_CHAN     => 3,
            C_ODATA_WIDTH  => 32
        )
        port map (
            Clk                => Clk_core,                  -- in  std_logic;
            nRst               => nRst,                      -- in  std_logic;

            SplittedPaerSrc_i  => i_rxMonSrc,                -- in  t_PaerSrc_array(0 to C_NUM_CHAN-1);
            SplittedPaerDst_o  => i_rxMonDst,                -- out t_PaerDst_array(0 to C_NUM_CHAN-1);

            PaerData_o         => i_rxMonData,               -- out std_logic_vector(31 downto 0);
            PaerSrcRdy_o       => i_rxMonSrcRdy,             -- out std_logic;
            PaerDstRdy_i       => i_rxMonDstRdy              -- in  std_logic
        );


   
    ---------------------
    -- Loopbacks
    ---------------------

    -- Local Near and Remote Loopback

    i_monData   <= i_seqData   when LocNearLoopback_i = '1' else
                   i_rxMonData;
    i_monSrcRdy <= i_seqSrcRdy when LocNearLoopback_i = '1' else
                   i_rxMonSrcRdy;

    i_seqDstRdy <= i_monDstRdy when LocNearLoopback_i = '1' else
                   '1'         when RemoteLoopback_i  = '1' else
                   i_txSeqDstRdy;

    i_rxMonDstRdy <= i_txSeqDstRdy when RemoteLoopback_i  = '1' else
                     '1'           when LocNearLoopback_i = '1' else
                     i_monDstRdy;

    i_txSeqData   <= i_rxMonData   when RemoteLoopback_i = '1' else
                     i_seqData;
    i_txSeqSrcRdy <= i_rxMonSrcRdy when RemoteLoopback_i = '1' else
                     i_seqSrcRdy;


    -------------------------------
    -- Sequencer & Monitor core
    -------------------------------

    u_CoreMonSeqRR : CoreMonSeqRR
        generic map (
            C_PAER_DSIZE                         => C_PAER_DSIZE,
            TestEnableSequencerNoWait            => c_TestEnableSequencerNoWait,
            TestEnableSequencerToMonitorLoopback => c_TestEnableSequencerToMonitorLoopback,
            EnableMonitorControlsSequencerToo    => c_EnableMonitorControlsSequencerToo
        )
        port map (
            Reset_xRBI              => nRst,                     -- in  std_logic;
            CoreClk_xCI             => Clk_core,                 -- in  std_logic;
            --
            FlushFifos_xSI          => FlushFifos_i,             -- in  std_logic;
            --ChipType_xSI            => ChipType,                 -- in  std_logic;
            DmaLength_xDI           => DmaLength_i,              -- in  std_logic_vector(10 downto 0);
            --
            MonInAddr_xDI           => i_monData,                -- in  std_logic_vector(31 downto 0);
            MonInSrcRdy_xSI         => i_monSrcRdy,              -- in  std_logic;
            MonInDstRdy_xSO         => i_monDstRdy,              -- out std_logic;
            --
            SeqOutAddr_xDO          => i_seqData,                -- out std_logic_vector(31 downto 0);
            SeqOutSrcRdy_xSO        => i_seqSrcRdy,              -- out std_logic;
            SeqOutDstRdy_xSI        => i_seqDstRdy,              -- in  std_logic;
            -- Time stamper
            CleanTimer_xSI          => CleanTimer_i,             -- in  std_logic;
            WrapDetected_xSO        => WrapDetected_o,           -- out std_logic;
            FullTimestamp_i         => FullTimestamp_i,          -- in  std_logic;  
            --
            EnableMonitor_xSI       => '1',                      -- in  std_logic;
            CoreReady_xSI           => '1',                      -- in  std_logic;
            --
            FifoCoreDat_xDO         => FifoCoreDat_o,            -- out std_logic_vector(31 downto 0);
            FifoCoreRead_xSI        => FifoCoreRead_i,           -- in  std_logic;
            FifoCoreEmpty_xSO       => FifoCoreEmpty_o,          -- out std_logic;
            FifoCoreAlmostEmpty_xSO => FifoCoreAlmostEmpty_o,    -- out std_logic;
            FifoCoreBurstReady_xSO  => FifoCoreBurstReady_o,     -- out std_logic;
            FifoCoreFull_xSO        => FifoCoreFull_o,           -- out std_logic;
            FifoCoreNumData_o       => FifoCoreNumData_o,        -- out std_logic_vector(10 downto 0);
            --
            CoreFifoDat_xDI         => CoreFifoDat_i,            -- in  std_logic_vector(31 downto 0);
            CoreFifoWrite_xSI       => CoreFifoWrite_i,          -- in  std_logic;
            CoreFifoFull_xSO        => CoreFifoFull_o,           -- out std_logic;
            CoreFifoAlmostFull_xSO  => CoreFifoAlmostFull_o,     -- out std_logic;
            CoreFifoEmpty_xSO       => CoreFifoEmpty_o,          -- out std_logic;
            --
            --BiasFinished_xSO        => BiasFinished,             -- out std_logic;
            --ClockLow_xDI            => ClockLow,                 -- in  natural;
            --LatchTime_xDI           => LatchTime,                -- in  natural;
            --SetupHold_xDI           => SetupHold,                -- in  natural;
            --PrescalerValue_xDI      => PrescalerValue,           -- in  std_logic_vector(31 downto 0);
            --BiasProgPins_xDO        => i_BiasProgPins_xD,        -- out std_logic_vector(7 downto 0);
            ---------------------------------------------------------------------------
            -- Output neurons threshold
            --OutThresholdVal_xDI     => OutThresholdVal           -- in  std_logic_vector(31 downto 0)
            DBG_din             => DBG_din,   
            DBG_wr_en           => DBG_wr_en,       
            DBG_rd_en           => DBG_rd_en,       
            DBG_dout            => DBG_dout,            
            DBG_full            => DBG_full,        
            DBG_almost_full     => DBG_almost_full, 
            DBG_overflow        => DBG_overflow,      
            DBG_empty           => DBG_empty,            
            DBG_almost_empty    => DBG_almost_empty,
            DBG_underflow       => DBG_underflow,   
            DBG_data_count      => DBG_data_count,
            DBG_Timestamp_xD    => DBG_Timestamp_xD,
            DBG_MonInAddr_xD    => DBG_MonInAddr_xD, 
            DBG_MonInSrcRdy_xS  => DBG_MonInSrcRdy_xS,
            DBG_MonInDstRdy_xS  => DBG_MonInDstRdy_xS,
            DBG_RESETFIFO       => DBG_RESETFIFO
 
 
        );




    -----------------------------------------------------------------------------
    -- LEDs
    -----------------------------------------------------------------------------
    LEDo_o <= '1';
    LEDr_o <= '1';
    LEDy_o <= '1';
    
    DBG_CH0_DATA <= i_rxMonSrc(0).idx;
    DBG_CH0_SRDY <= i_rxMonSrc(0).vld;
    DBG_CH0_DRDY <= i_rxMonDst(0).rdy;

    DBG_CH1_DATA <= i_rxMonSrc(1).idx;
    DBG_CH1_SRDY <= i_rxMonSrc(1).vld;
    DBG_CH1_DRDY <= i_rxMonDst(1).rdy;

    DBG_CH2_DATA <= i_rxMonSrc(2).idx;
    DBG_CH2_SRDY <= i_rxMonSrc(2).vld;
    DBG_CH2_DRDY <= i_rxMonDst(2).rdy;
    


end architecture str;

-------------------------------------------------------------------------------
