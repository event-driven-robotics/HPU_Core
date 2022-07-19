library ieee;
    use ieee.std_logic_1164.all;

package constants is 
    
   constant C_INTERNAL_DSIZE : natural := 32;
   
end package constants;

-- -----------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    
library work;
  use work.constants.all;
          
package types is

-- PAER types

  type t_PaerSrc is record
      --idx : std_logic_vector(C_PAER_DSIZE-1 downto 0);
      idx : std_logic_vector(C_INTERNAL_DSIZE-1 downto 0);
      vld : std_logic;
  end record t_PaerSrc;

  type t_PaerSrc_array is array (natural range <>) of t_PaerSrc;

  type t_PaerDst is record
      rdy : std_logic;
  end record t_PaerDst;

  type t_PaerDst_array is array (natural range <>) of t_PaerDst;

  -- Configurations from uP

  type t_XConChanCfg is record
      zero    : std_logic;
      lpbk    : std_logic;
      idx     : natural range 0 to 3;
  end record t_XConChanCfg;

  type t_XConChanCfg_array is array (natural range <>) of t_XConChanCfg;

  type t_XConCfg is record
      rx1Cfg : t_XConChanCfg_array(0 to 3);
      rx2Cfg : t_XConChanCfg_array(0 to 3);
      rx3Cfg : t_XConChanCfg_array(0 to 3);
  end record t_XConCfg;
  --
  --type t_ArbiterCfg is record
  --    TODO : std_logic;
  --end record t_ArbiterCfg;
  --
  --type t_SplitterCfg is record
  --    TODO : std_logic;
  --end record t_SplitterCfg;

  -- Status to uP
  type t_TxSaerStat is record
      run  : std_logic;
      last : std_logic;
  end record t_TxSaerStat;

  type t_TxSaerStat_array is array (natural range <>) of t_TxSaerStat;

  type t_RxSaerStat is record
      err_ko : std_logic;
      err_rx : std_logic;
      err_to : std_logic;
      err_of : std_logic;
      int    : std_logic;
      run    : std_logic;
  end record t_RxSaerStat;

  type t_RxSaerStat_array is array (natural range <>) of t_RxSaerStat;

  type t_TxGtpStat is record
      pll_alarm           : std_logic;
      TxGtpEventRate      : std_logic_vector(15 downto 0); -- Count per millisecond 
      TxGtpMessageRate    : std_logic_vector( 7 downto 0); -- Count per millisecond 
  end record t_TxGtpStat;
  
  type t_TxGtpStat_array is array (natural range <>) of t_TxGtpStat;

  type t_RxGtpStat is record
      pll_alarm           : std_logic;
      rx_disaligned       : std_logic;
      RxGtpEventRate      : std_logic_vector(15 downto 0); -- Count per millisecond 
      RxGtpMessageRate    : std_logic_vector( 7 downto 0); -- Count per millisecond 
  end record t_RxGtpStat;
  
  type t_RxGtpStat_array is array (natural range <>) of t_RxGtpStat;
          
  type t_TxSpnnlnkStat is record
      dump_mode  : std_logic;
  end record t_TxSpnnlnkStat;

  type t_TxSpnnlnkStat_array is array (natural range <>) of t_TxSpnnlnkStat;

  type t_RxSpnnlnkStat is record
      parity_err : std_logic;
      rx_err     : std_logic;
  end record t_RxSpnnlnkStat;

  type t_RxSpnnlnkStat_array is array (natural range <>) of t_RxSpnnlnkStat;
  
  type SpnnCmd_type is record
      start_key : std_logic_vector(31 downto 0);
      stop_key  : std_logic_vector(31 downto 0);
  end record SpnnCmd_type;

  type t_RxErrStat is record
      cnt_ko : std_logic_vector(7 downto 0);
      cnt_rx : std_logic_vector(7 downto 0);
      cnt_to : std_logic_vector(7 downto 0);
      cnt_of : std_logic_vector(7 downto 0);
  end record t_RxErrStat;

  type t_RxErrStat_array is array (natural range <>) of t_RxErrStat;

end package types;

-- -----------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    
library work;
  use work.constants.all;
  use work.types.all;

package components is

    component SimplePAERInputRRv2 is
        generic (
            paer_width               : positive := 16;
            internal_width           : positive := 32;
            --data_on_req_release      : boolean  := false;
            input_fifo_depth         : positive := 1
        );
        port (
            -- clk rst
            ClkxCI                   : in  std_logic;
            RstxRBI                  : in  std_logic;
            EnableIp                 : in  std_logic;
            FlushFifo                : in  std_logic;
            IgnoreFifoFull_i         : in  std_logic;
            aux_channel              : in  std_logic;


            -- parallel AER
            AerReqxAI                : in  std_logic;
            AerAckxSO                : out std_logic;
            AerDataxADI              : in  std_logic_vector(paer_width-1 downto 0);

            -- configuration
            AerHighBitsxDI           : in  std_logic_vector(internal_width-1-paer_width downto 0);
            --AerReqActiveLevelxDI     : in  std_logic;
            --AerAckActiveLevelxDI     : in  std_logic;
            CfgAckSetDelay_i         : in  std_logic_vector(7 downto 0);
            CfgSampleDelay_i         : in  std_logic_vector(7 downto 0);
            CfgAckRelDelay_i         : in  std_logic_vector(7 downto 0);
            -- output
            OutDataxDO               : out std_logic_vector(internal_width-1 downto 0);
            OutSrcRdyxSO             : out std_logic;
            OutDstRdyxSI             : in  std_logic;
            -- Fifo Full signal
            FifoFullxSO              : out std_logic;
            -- dbg
            dbg_dataOk               : out std_logic
        );
    end component SimplePAERInputRRv2;
    
    component SimplePAEROutputRR is
        generic (
            paer_width        : positive := 16;
            internal_width    : positive := 32;
            --ack_stable_cycles : natural  := 2;
            --req_delay_cycles  : natural  := 4;
            output_fifo_depth : positive := 1
        );
        port (
            -- clk rst
            ClkxCI  : in std_logic;
            RstxRBI : in std_logic;

            -- parallel AER 
            AerAckxAI  : in  std_logic;
            AerReqxSO  : out std_logic;
            AerDataxDO : out std_logic_vector(paer_width-1 downto 0);

            -- configuration
            AerReqActiveLevelxDI : in std_logic;
            AerAckActiveLevelxDI : in std_logic;

            -- output
            InpDataxDI   : in  std_logic_vector(internal_width-1 downto 0);
            InpSrcRdyxSI : in  std_logic;
            InpDstRdyxSO : out std_logic
        );
    end component SimplePAEROutputRR;

    component req_fifo is
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
    end component req_fifo;

    component merge_rdy is
        generic (
            N_CHAN        : natural := 4
        );                
        port (            
            nRst          : in  std_logic;
            Clk           : in  std_logic;
                          
            InVld_i       : in  std_logic;
            OutRdy_o      : out std_logic;
                          
            OutVldVect_o  : out std_logic_vector(N_CHAN-1 downto 0);
            InRdyVect_i   : in  std_logic_vector(N_CHAN-1 downto 0)
        );
    end component merge_rdy;
    
    component hssaer_paer_tx_wrapper is
        generic (
            dsize       : integer;
            int_dsize   : integer
        );
        port (
            nrst        : in  std_logic;
            clkp        : in  std_logic;
            clkn        : in  std_logic;
            keep_alive  : in  std_logic;

            ae          : in  std_logic_vector(int_dsize-1 downto 0);
            src_rdy     : in  std_logic;
            dst_rdy     : out std_logic;

            tx          : out std_logic;

            run         : out std_logic;
            last        : out std_logic
        );
    end component hssaer_paer_tx_wrapper;
    
    component hssaer_paer_rx_wrapper is
        generic (
            dsize       : integer;
            int_dsize   : integer
        );
        port (
            nrst        : in  std_logic;
            lsclkp      : in  std_logic;
            lsclkn      : in  std_logic;
            hsclkp      : in  std_logic;
            hsclkn      : in  std_logic;

            rx          : in  std_logic;

            ae          : out std_logic_vector(int_dsize-1 downto 0);
            src_rdy     : out std_logic;
            dst_rdy     : in  std_logic;

            higher_bits : in  std_logic_vector(int_dsize-1 downto dsize);
            err_ko      : out std_logic;
            err_rx      : out std_logic;
            err_to      : out std_logic;
            err_of      : out std_logic;
            int         : out std_logic;
            run         : out std_logic;

            aux_channel : in  std_logic
        );
    end component hssaer_paer_rx_wrapper;
    
    component spinn_neu_if
    	generic (
            C_PSPNNLNK_WIDTH              : natural range 1 to 32 := 32;
            C_HAS_TX                      : string;
            C_HAS_RX                      : string
    		);
    	port (
    		rst							: in  std_logic;
    		clk_32						: in  std_logic;
    		enable                      : in  std_logic;
    		
    		dump_mode					: out std_logic;
    		parity_err					: out std_logic;
    		rx_err						: out std_logic;
            offload                     : out std_logic;
            link_timeout                : out std_logic;
    	    link_timeout_dis            : in  std_logic;
    	    
    		-- input SpiNNaker link interface
    		data_2of7_from_spinnaker 	: in  std_logic_vector(6 downto 0); 
    		ack_to_spinnaker			: out std_logic;
    	
    		-- output SpiNNaker link interface
    		data_2of7_to_spinnaker		: out std_logic_vector(6 downto 0);
    		ack_from_spinnaker          : in  std_logic;
    	
    		-- input AER device interface
    		iaer_addr 					: in  std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
    		iaer_vld					: in  std_logic;
    		iaer_rdy					: out std_logic;
    	
    		-- output AER device interface
    		oaer_addr					: out std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
    		oaer_vld					: out std_logic;
    		oaer_rdy					: in  std_logic;
    		
            -- Command from SpiNNaker
            keys_enable                 : in  std_logic;
            start_key                   : in  std_logic_vector(31 downto 0); 
            stop_key                    : in  std_logic_vector(31 downto 0); 
            cmd_start                   : out std_logic;
            cmd_stop                    : out std_logic;
    
            -- Settings
            tx_data_mask                : in  std_logic_vector(31 downto 0);
            rx_data_mask                : in  std_logic_vector(31 downto 0);
    
            -- Controls
            offload_off                 : in std_logic;
            offload_on                  : in std_logic;
        
            -- Debug ports
    		
    		dbg_rxstate					: out std_logic_vector(2 downto 0);
    		dbg_txstate					: out std_logic_vector(1 downto 0);
    		dbg_ipkt_vld				: out std_logic;
    		dbg_ipkt_rdy				: out std_logic;
    		dbg_opkt_vld				: out std_logic;
    		dbg_opkt_rdy				: out std_logic
            ); 
    end component;   

    component GT_Manager is
      generic ( 
        FAMILY_g                  : string                := "zynquplus"; -- "zynq", "zynquplus" 
        --
        USER_DATA_WIDTH_g         : integer range 0 to 64 := 32;    -- Width of Data - Fabric side
        USER_MESSAGE_WIDTH_g      : integer range 0 to 64 :=  8;    -- Width of Message - Fabric side 
        GT_DATA_WIDTH_g           : integer range 0 to 64 := 16;    -- Width of Data - GT side
        GT_TXUSRCLK2_PERIOD_NS_g  : real :=  6.4;                   -- TX GT User clock period
        GT_RXUSRCLK2_PERIOD_NS_g  : real :=  6.4;                   -- RX GT User clock period
        SIM_TIME_COMPRESSION_g    : in boolean := FALSE             -- When "TRUE", simulation time is "compressed": frequencies of internal clock enables are speeded-up 
        );
      port (
        
        -- COMMONs
        -- Bare Control ports
        CLK_i                   : in  std_logic;   -- Input clock - Fabric side
        RST_N_i                 : in  std_logic;   -- Active low, asynchronous assertion, synchronous deassertion reset (CLK_i clock domain)
        EN1S_i                  : in  std_logic;   -- Enable @ 1 sec (CLK_i clock domain)
    
        -- Status
        PLL_ALARM_o             : out std_logic;
        
        -- ---------------------------------------------------------------------------------------
        -- TX SIDE
    
        -- Control in
        TX_AUTO_ALIGN_i         : in  std_logic;   -- Enables the "Auto alignment mode"
        TX_ALIGN_REQUEST_i      : in  std_logic;   -- Align request from Receiver (async)
        TX_ERROR_INJECTION_i    : in  std_logic;   -- Error insertion (not used, intended for debug purpose)
        
        -- Status and errors
        TX_GT_ALIGN_FLAG_o      : out std_logic;   -- Monitor out: sending align
        
        -- Statistics
        TX_DATA_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond
        TX_ALIGN_RATE_o         : out std_logic_vector( 7 downto 0); -- Count per millisecond
        TX_MSG_RATE_o           : out std_logic_vector(15 downto 0); -- Count per millisecond
        TX_IDLE_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond
        TX_EVENT_RATE_o         : out std_logic_vector(15 downto 0); -- Count per millisecond
        TX_MESSAGE_RATE_o       : out std_logic_vector( 7 downto 0); -- Count per millisecond
    
      
        -- Data TX 
        TX_DATA_i               : in  std_logic_vector(USER_DATA_WIDTH_g-1 downto 0); -- Data to be transmitted
        TX_DATA_SRC_RDY_i       : in  std_logic;  -- Handshake for data transmission: Source Ready
        TX_DATA_DST_RDY_o       : out std_logic;  -- Handshake for data transmission: Destination Ready
        -- Message TX
        TX_MSG_i                : in   std_logic_vector(USER_MESSAGE_WIDTH_g-1 downto 0); -- Message to be transmitted
        TX_MSG_SRC_RDY_i        : in   std_logic;  -- Handshake for message transmission: Source Ready     
        TX_MSG_DST_RDY_o        : out  std_logic;  -- Handshake for message transmission: Destination Ready
    
        -- ---------------------------------------------------------------------------------------
        -- RX SIDE    
        
        -- Control out
        RX_ALIGN_REQUEST_o      : out std_logic;  
        
        -- Status and errors
        RX_DISALIGNED_o         : out std_logic;   -- Monitor out: sending align
        
        -- Statistics        
        RX_DATA_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond 
        RX_ALIGN_RATE_o         : out std_logic_vector( 7 downto 0); -- Count per millisecond 
        RX_MSG_RATE_o           : out std_logic_vector(15 downto 0); -- Count per millisecond 
        RX_IDLE_RATE_o          : out std_logic_vector(15 downto 0); -- Count per millisecond 
        RX_EVENT_RATE_o         : out std_logic_vector(15 downto 0); -- Count per millisecond 
        RX_MESSAGE_RATE_o       : out std_logic_vector( 7 downto 0); -- Count per millisecond 
    
        -- Data RX 
        RX_DATA_o               : out std_logic_vector(USER_DATA_WIDTH_g-1 downto 0);
        RX_DATA_SRC_RDY_o       : out std_logic;
        RX_DATA_DST_RDY_i       : in  std_logic;
        -- Message RX
        RX_MSG_o                : out std_logic_vector(USER_MESSAGE_WIDTH_g-1 downto 0);
        RX_MSG_SRC_RDY_o        : out std_logic;
        RX_MSG_DST_RDY_i        : in  std_logic;    
        
            
       
        -- *****************************************************************************************
        -- Transceiver Interface for Serie 7 GTP
        -- *****************************************************************************************
        
        -- Clock Ports
        GTP_TXUSRCLK2_i          : in  std_logic;
        GTP_RXUSRCLK2_i          : in  std_logic;  
        
        -- Reset FSM Control Ports
        SOFT_RESET_TX_o          : out  std_logic;                                          -- SYS_CLK   --
        SOFT_RESET_RX_o          : out  std_logic;                                          -- SYS_CLK   --
        GTP_DATA_VALID_o         : out std_logic;                                           -- SYS_CLK   --
        
        -- -------------------------------------------------------------------------
        -- TRANSMITTER 
        --------------------- TX Initialization and Reset Ports --------------------
        GTP_TXUSERRDY_o          : out std_logic;                                           -- ASYNC     --
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GTP_TXDATA_o             : out std_logic_vector(15 downto 0);                       -- TXUSRCLK2 --
        ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
        GTP_TXCHARISK_o          : out std_logic_vector(1 downto 0);                        -- TXUSRCLK2 --
        
        -- -------------------------------------------------------------------------
        -- RECEIVER
        --------------------- RX Initialization and Reset Ports --------------------
        GTP_RXUSERRDY_o          : out std_logic;                                           -- ASYNC     --
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GTP_RXDATA_i             : in  std_logic_vector(GT_DATA_WIDTH_g-1 downto 0);       -- RXUSRCLK2 --
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GTP_RXCHARISCOMMA_i      : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
        GTP_RXCHARISK_i          : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
        GTP_RXDISPERR_i          : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
        GTP_RXNOTINTABLE_i       : in  std_logic_vector((GT_DATA_WIDTH_g/8)-1 downto 0);   -- RXUSRCLK2 --
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GTP_RXBYTEISALIGNED_i    : in  std_logic;                                           -- RXUSRCLK2 --
        GTP_RXBYTEREALIGN_i      : in  std_logic;                                           -- RXUSRCLK2 --
        
        -- -------------------------------------------------------------------------    
        -- COMMON PORTS
        GTP_PLL_LOCK_i           : in  std_logic;                                           -- ASYNC     --
        GTP_PLL_REFCLKLOST_i     : in  std_logic;                                           -- SYS_CLK   -- 
     
     
     
        -- *****************************************************************************************
        -- Transceiver Interface for Ultrascale+ GTH
        -- ***************************************************************************************** 
         
        -- Clock Ports
    --  GTH_GTWIZ_USERCLK_TX_USRCLK2_i        : in std_logic_vector(0 downto 0);
        GTH_GTWIZ_USERCLK_RX_USRCLK2_i        : in std_logic_vector(0 downto 0);
        
        -- Reset FSM Control Ports
        GTH_GTWIZ_RESET_ALL_o                 : out std_logic_vector(0 downto 0);                        -- ASYNC     --
    
    
        -- -------------------------------------------------------------------------
        -- TRANSMITTER 
    
        -- TBD
    
        
        -- -------------------------------------------------------------------------
        -- RECEIVER
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GTH_GTWIZ_USERDATA_RX_i               : in  std_logic_vector(GT_DATA_WIDTH_g-1 downto 0);       -- RXUSRCLK2 --
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GTH_RXCTRL2_i                         : in  std_logic_vector(7 downto 0);    -- (RXCHARISCOMMA)  -- RXUSRCLK2 --
        GTH_RXCTRL0_i                         : in  std_logic_vector(15 downto 0);   -- (RXCHARISK)      -- RXUSRCLK2 --
        GTH_RXCTRL1_i                         : in  std_logic_vector(15 downto 0);   -- (RXDISPERR)      -- RXUSRCLK2 --
        GTH_RXCTRL3_i                         : in  std_logic_vector(7 downto 0);    -- (RXNOTINTABLE)   -- RXUSRCLK2 --
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GTH_RXBYTEISALIGNED_i                 : in  std_logic_vector(0 downto 0);                        -- RXUSRCLK2 --
        GTH_RXBYTEREALIGN_i                   : in  std_logic_vector(0 downto 0);                        -- RXUSRCLK2 --
            
        -- -------------------------------------------------------------------------    
        -- COMMON PORTS    
        GTH_QPLL_LOCK_i                       : in  std_logic_vector(0 downto 0);                        -- ASYNC     --
        GTH_QPLL_REFCLKLOST_i                 : in  std_logic_vector(0 downto 0)                         -- QPLL0LOCKDETCLK --
                 
        );
    end component;
 
    component PAER_arbiter is
        generic (
            C_NUM_CHAN         : natural range 1 to 4 := 2;
            C_ODATA_WIDTH      : natural
        );
        port (
            Clk                : in  std_logic;
            nRst               : in  std_logic;

            --ArbCfg_i           : in  t_ArbiterCfg;

            SplittedPaerSrc_i  : in  t_PaerSrc_array(0 to C_NUM_CHAN-1);
            SplittedPaerDst_o  : out t_PaerDst_array(0 to C_NUM_CHAN-1);

            PaerData_o         : out std_logic_vector(C_ODATA_WIDTH-1 downto 0);
            PaerSrcRdy_o       : out std_logic;
            PaerDstRdy_i       : in  std_logic
        );
    end component PAER_arbiter;
    
    component PAER_splitter is
        generic (
            C_NUM_CHAN         : natural range 1 to 4 := 2;
            C_IDATA_WIDTH      : natural
        );
        port (
            Clk                : in  std_logic;
            nRst               : in  std_logic;
            --
            ChEn_i             : in  std_logic_vector(C_NUM_CHAN-1 downto 0);
            --               
            PaerDataIn_i       : in  std_logic_vector(C_IDATA_WIDTH-1 downto 0);
            PaerSrcRdy_i       : in  std_logic;
            PaerDstRdy_o       : out std_logic;
            --               
            SplittedPaerSrc_o  : out t_PaerSrc_array(0 to C_NUM_CHAN-1);
            SplittedPaerDst_i  : in  t_PaerDst_array(0 to C_NUM_CHAN-1)
        );
    end component PAER_splitter;

    component FIFO_SAER_ZYNQ
      port (
        rst : in std_logic;
        wr_clk : in std_logic;
        rd_clk : in std_logic;
        din : in std_logic_vector(31 downto 0);
        wr_en : in std_logic;
        rd_en : in std_logic;
        dout : out std_logic_vector(31 downto 0);
        full : out std_logic;
        empty : out std_logic
      );
    end component;

    component FIFO_SAER_ZYNQUPLUS
      port (
        rst : in std_logic;
        wr_clk : in std_logic;
        rd_clk : in std_logic;
        din : in std_logic_vector(31 downto 0);
        wr_en : in std_logic;
        rd_en : in std_logic;
        dout : out std_logic_vector(31 downto 0);
        full : out std_logic;
        empty : out std_logic
      );
    end component;
    
end package components;
