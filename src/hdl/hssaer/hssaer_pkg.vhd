library ieee;
    use ieee.std_logic_1164.all;

package components is

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
  
end package components;



