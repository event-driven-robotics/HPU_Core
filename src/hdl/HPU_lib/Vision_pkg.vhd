------------------------------------------------------------------------
-- Package definitions_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the definitions of some constants used inside
--   the whole FPGA
--
------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;


package definitions_pkg is

    constant CHIP_TYPE_UNK  : std_logic_vector(2 downto 0) := "000";
    constant CHIP_TYPE_DVS  : std_logic_vector(2 downto 0) := "001";
    constant CHIP_TYPE_ATIS : std_logic_vector(2 downto 0) := "010";
    constant CHIP_TYPE_GEN3 : std_logic_vector(2 downto 0) := "011";

--    constant C_FPGA_VERSION : std_logic_vector(7 downto 0) := "00110001";       -- version 3.1

end package definitions_pkg;



------------------------------------------------------------------------
-- Package aer_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the declarations of constants and types used in the
--   Parallel and Serial AER protocol handling
--
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;


 package aer_pkg is

    constant C_INTERNAL_DSIZE : natural := 32;

    -- PAER interface
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
        pll_alarm : std_logic;
    end record t_TxGtpStat;
    
    type t_TxGtpStat_array is array (natural range <>) of t_TxGtpStat;

    type t_RxGtpStat is record
        pll_alarm : std_logic;
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

    type t_RxErrStat is record
        cnt_ko : std_logic_vector(7 downto 0);
        cnt_rx : std_logic_vector(7 downto 0);
        cnt_to : std_logic_vector(7 downto 0);
        cnt_of : std_logic_vector(7 downto 0);
    end record t_RxErrStat;

    type t_RxErrStat_array is array (natural range <>) of t_RxErrStat;

 end package aer_pkg;
