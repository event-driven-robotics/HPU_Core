
library ieee;
    use ieee.std_logic_1164.all;

library datapath;
  use datapath.types.all;

entity loopback is
    generic (
        C_PAER_DSIZE          : natural;
        C_RX_HSSAER_N_CHAN    : natural range 1 to 4;
        C_TX_HSSAER_N_CHAN    : natural range 1 to 4
    );
    port (
        Rx1PaerLpbkEn       : in  std_logic;
        Rx2PaerLpbkEn       : in  std_logic;
        Rx3PaerLpbkEn       : in  std_logic;
        Rx1SaerLpbkEn       : in  std_logic;
        Rx2SaerLpbkEn       : in  std_logic;
        Rx3SaerLpbkEn       : in  std_logic;
        XConSerCfg          : in  t_XConCfg;
        RxSpnnLnkLpbkEnSel  : in  std_logic_vector(1 downto 0);

        -- Parallel AER
        ExtTxPAER_Addr_o    : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
        ExtTxPAER_Req_o     : out std_logic;
        ExtTxPAER_Ack_i     : in  std_logic;

        ExtRx1PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        ExtRx1PAER_Req_i    : in  std_logic;
        ExtRx1PAER_Ack_o    : out std_logic;

        ExtRx2PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        ExtRx2PAER_Req_i    : in  std_logic;
        ExtRx2PAER_Ack_o    : out std_logic;

        ExtRx3PAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        ExtRx3PAER_Req_i    : in  std_logic;
        ExtRx3PAER_Ack_o    : out std_logic;

        -- HSSAER
        ExtTxHSSAER_Tx_o    : out std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
        ExtRx1HSSAER_Rx_i   : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
        ExtRx2HSSAER_Rx_i   : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
        ExtRx3HSSAER_Rx_i   : in  std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);

        -- GTP interface
        --
        -- TBD signals to drive the GTP module
        --

        -- SpiNNlink interface
        ExtTx_data_2of7_to_spinnaker_o      : out std_logic_vector(6 downto 0);
        ExtTx_ack_from_spinnaker_i          : in  std_logic;
        ExtRx1_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
        ExtRx1_ack_to_spinnaker_o           : out std_logic;
        ExtRx2_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
        ExtRx2_ack_to_spinnaker_o           : out std_logic;
        ExtRx3_data_2of7_from_spinnaker_i   : in  std_logic_vector(6 downto 0); 
        ExtRx3_ack_to_spinnaker_o           : out std_logic;


        -- Parallel AER
        CoreTxPAER_Addr_i   : in  std_logic_vector(C_PAER_DSIZE-1 downto 0);
        CoreTxPAER_Req_i    : in  std_logic;
        CoreTxPAER_Ack_o    : out std_logic;

        CoreRx1PAER_Addr_o  : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
        CoreRx1PAER_Req_o   : out std_logic;
        CoreRx1PAER_Ack_i   : in  std_logic;

        CoreRx2PAER_Addr_o  : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
        CoreRx2PAER_Req_o   : out std_logic;
        CoreRx2PAER_Ack_i   : in  std_logic;

        CoreRx3PAER_Addr_o  : out std_logic_vector(C_PAER_DSIZE-1 downto 0);
        CoreRx3PAER_Req_o   : out std_logic;
        CoreRx3PAER_Ack_i   : in  std_logic;

        -- HSSAER
        CoreTxHSSAER_Tx_i   : in  std_logic_vector(0 to C_TX_HSSAER_N_CHAN-1);
        CoreRx1HSSAER_Rx_o  : out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
        CoreRx2HSSAER_Rx_o  : out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);
        CoreRx3HSSAER_Rx_o  : out std_logic_vector(0 to C_RX_HSSAER_N_CHAN-1);

        -- GTP interface
        --
        -- TBD signals to drive the GTP module
        --
        
        -- SpiNNlink interface
        CoreTx_data_2of7_to_spinnaker_i      : in  std_logic_vector(6 downto 0);
        CoreTx_ack_from_spinnaker_o          : out std_logic;
        CoreRx1_data_2of7_from_spinnaker_o   : out std_logic_vector(6 downto 0); 
        CoreRx1_ack_to_spinnaker_i           : in  std_logic;
        CoreRx2_data_2of7_from_spinnaker_o   : out std_logic_vector(6 downto 0); 
        CoreRx2_ack_to_spinnaker_i           : in  std_logic;
        CoreRx3_data_2of7_from_spinnaker_o   : out std_logic_vector(6 downto 0); 
        CoreRx3_ack_to_spinnaker_i           : in  std_logic
    );
end entity loopback;


architecture beh of loopback is

    signal i_CoreRxLpbk_Ack : std_logic;

begin

    -- HSSAER
    ------------------

    ExtTxHSSAER_Tx_o <= CoreTxHSSAER_Tx_i;

    g_mux_rx1 : for i in 0 to C_RX_HSSAER_N_CHAN-1 generate
        CoreRx1HSSAER_Rx_o(i) <= ExtRx1HSSAER_Rx_i(i)         when Rx1SaerLpbkEn = '0' else                 -- no loopback for all the HSSAER channels
                                 '0'                          when XConSerCfg.rx1Cfg(i).zero = '1' else     -- the channel is set to '0'
                                 ExtRx1HSSAER_Rx_i(i)         when XConSerCfg.rx1Cfg(i).lpbk = '0' else     -- the channel is sent directly from Ext to Core
                                 CoreTxHSSAER_Tx_i(XConSerCfg.rx1Cfg(i).idx);                               -- the channel is taken from the Tx side
    end generate g_mux_rx1;

    g_mux_rx2 : for j in 0 to C_RX_HSSAER_N_CHAN-1 generate
        CoreRx2HSSAER_Rx_o(j) <= ExtRx2HSSAER_Rx_i(j)         when Rx2SaerLpbkEn = '0' else                 -- no loopback for all the HSSAER channels
                                 '0'                          when XConSerCfg.rx2Cfg(j).zero = '1' else     -- the channel is set to '0'
                                 ExtRx2HSSAER_Rx_i(j)         when XConSerCfg.rx2Cfg(j).lpbk = '0' else     -- the channel is sent directly from Ext to Core
                                 CoreTxHSSAER_Tx_i(XConSerCfg.rx2Cfg(j).idx);                               -- the channel is taken from the Tx side
    end generate g_mux_rx2;

    g_mux_rx3 : for j in 0 to C_RX_HSSAER_N_CHAN-1 generate
        CoreRx3HSSAER_Rx_o(j) <= ExtRx3HSSAER_Rx_i(j)         when Rx3SaerLpbkEn = '0' else                 -- no loopback for all the HSSAER channels
                                 '0'                          when XConSerCfg.rx3Cfg(j).zero = '1' else     -- the channel is set to '0'
                                 ExtRx3HSSAER_Rx_i(j)         when XConSerCfg.rx3Cfg(j).lpbk = '0' else     -- the channel is sent directly from Ext to Core
                                 CoreTxHSSAER_Tx_i(XConSerCfg.rx3Cfg(j).idx);                               -- the channel is taken from the Tx side
    end generate g_mux_rx3;


    -- PAER
    ------------------

    ExtTxPAER_Addr_o <= CoreTxPAER_Addr_i;
    ExtTxPAER_Req_o  <= CoreTxPAER_Req_i;
    CoreTxPAER_Ack_o <= i_CoreRxLpbk_Ack when (Rx1PaerLpbkEn = '1' or Rx2PaerLpbkEn = '1' or Rx3PaerLpbkEn = '1') else
                        ExtTxPAER_Ack_i;

    -- When in loopback, the acknowledge is generated when all the Rx in loopback have
    -- acknowledged the request 
    i_CoreRxLpbk_Ack <= (CoreRx1PAER_Ack_i or not(Rx1PaerLpbkEn)) and
                        (CoreRx2PAER_Ack_i or not(Rx2PaerLpbkEn)) and
                        (CoreRx3PAER_Ack_i or not(Rx3PaerLpbkEn));

    CoreRx1PAER_Addr_o <= CoreTxPAER_Addr_i when Rx1PaerLpbkEn = '1' else ExtRx1PAER_Addr_i;
    CoreRx1PAER_Req_o  <= CoreTxPAER_Req_i  when Rx1PaerLpbkEn = '1' else ExtRx1PAER_Req_i;
    ExtRx1PAER_Ack_o   <= ExtRx1PAER_Req_i  when Rx1PaerLpbkEn = '1' else CoreRx1PAER_Ack_i;

    CoreRx2PAER_Addr_o <= CoreTxPAER_Addr_i when Rx2PaerLpbkEn = '1' else ExtRx2PAER_Addr_i;
    CoreRx2PAER_Req_o  <= CoreTxPAER_Req_i  when Rx2PaerLpbkEn = '1' else ExtRx2PAER_Req_i;
    ExtRx2PAER_Ack_o   <= ExtRx2PAER_Req_i  when Rx2PaerLpbkEn = '1' else CoreRx2PAER_Ack_i;

    CoreRx3PAER_Addr_o <= CoreTxPAER_Addr_i when Rx3PaerLpbkEn = '1' else ExtRx3PAER_Addr_i;
    CoreRx3PAER_Req_o  <= CoreTxPAER_Req_i  when Rx3PaerLpbkEn = '1' else ExtRx3PAER_Req_i;
    ExtRx3PAER_Ack_o   <= ExtRx3PAER_Req_i  when Rx3PaerLpbkEn = '1' else CoreRx3PAER_Ack_i;

    -- GTP
    ------------------


    -- SpiNNlink
    ------------------
    
    ExtTx_data_2of7_to_spinnaker_o      <= CoreTx_data_2of7_to_spinnaker_i when (RxSpnnLnkLpbkEnSel = "00") else (others => '0');
    CoreTx_ack_from_spinnaker_o         <= ExtTx_ack_from_spinnaker_i      when (RxSpnnLnkLpbkEnSel = "00") else 
                                           CoreRx1_ack_to_spinnaker_i      when (RxSpnnLnkLpbkEnSel = "01") else 
                                           CoreRx2_ack_to_spinnaker_i      when (RxSpnnLnkLpbkEnSel = "10") else     
                                           CoreRx3_ack_to_spinnaker_i      when (RxSpnnLnkLpbkEnSel = "11") else '0';     
    
    CoreRx1_data_2of7_from_spinnaker_o  <= CoreTx_data_2of7_to_spinnaker_i when (RxSpnnLnkLpbkEnSel = "01") else ExtRx1_data_2of7_from_spinnaker_i;  
    ExtRx1_ack_to_spinnaker_o           <= '0'                             when (RxSpnnLnkLpbkEnSel = "01") else CoreRx1_ack_to_spinnaker_i;
    
    CoreRx2_data_2of7_from_spinnaker_o  <= CoreTx_data_2of7_to_spinnaker_i when (RxSpnnLnkLpbkEnSel = "10") else ExtRx2_data_2of7_from_spinnaker_i;
    ExtRx2_ack_to_spinnaker_o           <= '0'                             when (RxSpnnLnkLpbkEnSel = "10") else CoreRx2_ack_to_spinnaker_i;
    
    CoreRx3_data_2of7_from_spinnaker_o  <= CoreTx_data_2of7_to_spinnaker_i when (RxSpnnLnkLpbkEnSel = "11") else ExtRx3_data_2of7_from_spinnaker_i;
    ExtRx3_ack_to_spinnaker_o           <= '0'                             when (RxSpnnLnkLpbkEnSel = "11") else CoreRx3_ack_to_spinnaker_i;    
    

end architecture beh;



