library ieee;
    use ieee.std_logic_1164.all;

package components is

  component AsyncStabilizer is
      generic (
          synchronizer      : boolean  := true;
          stabilizer_cycles : positive := 2
      );
      port (
          ClkxCI      : in  std_logic;
          RstxRBI     : in  std_logic;
          --
          RstValuexDI : in  std_logic;
          --
          InputxAI    : in  std_logic;
          OutputxDO   : out std_logic
      );
  end component AsyncStabilizer;
  
  component RegisterArray1 is
      generic (
          depth : natural  := 1
      );
      port (
          ClkxCI        : in  std_logic;
          RstxRBI       : in  std_logic;
          --
          ResetValuexDI : in  std_logic;
          --
          InputxDI      : in  std_logic;
          OutputxDO     : out std_logic
      );
  end component RegisterArray1;
  
  component ShiftRegFifo is
      generic (
          width           : positive;
          depth           : positive;
          full_fifo_reset : boolean := false;
          errorchecking   : boolean := true
      );
      port (
          ClockxCI        : in  std_logic;
          ResetxRBI       : in  std_logic;
          --
          InputxDI        : in  std_logic_vector(width-1 downto 0);
          WritexSI        : in  std_logic;
          AlmostFullxSO   : out std_logic;
          FullxSO         : out std_logic;
          OverflowxSO     : out std_logic;
          --
          OutputxDO       : out std_logic_vector(width-1 downto 0);
          ReadxSI         : in  std_logic;
          AlmostEmptyxSO  : out std_logic;
          EmptyxSO        : out std_logic;
          UnderflowxSO    : out std_logic;
          --
          LevelxDO        : out natural range 0 to depth
      );
  end component ShiftRegFifo;

  component ShiftRegFifoRRInp is
      generic (
          width           : positive;
          depth           : positive := 4;
          full_fifo_reset : boolean  := false
      );
  
      port (
          ClockxCI       : in  std_logic;
          ResetxRBI      : in  std_logic;
          --
          InpDataxDI     : in  std_logic_vector(width-1 downto 0);
          InpSrcRdyxSI   : in  std_logic;
          InpDstRdyxSO   : out std_logic;
          --
          OutDataxDO     : out std_logic_vector(width-1 downto 0);
          OutReadxSI     : in  std_logic;
          --
          EmptyxSO       : out std_logic;
          AlmostEmptyxSO : out std_logic;
          AlmostFullxSO  : out std_logic;
          FullxSO        : out std_logic;
          UnderflowxSO   : out std_logic
      );
  end component ShiftRegFifoRRInp;

  component ShiftRegFifoRROut is
      generic (
          width           : positive;
          depth           : positive := 4;
          full_fifo_reset : boolean  := true
      );
      port (
          ClockxCI        : in  std_logic;
          ResetxRBI       : in  std_logic;
          --              
          InpDataxDI      : in  std_logic_vector(width-1 downto 0);
          InpWritexSI     : in  std_logic;
          --              
          OutDataxDO      : out std_logic_vector(width-1 downto 0);
          OutSrcRdyxSO    : out std_logic;
          OutDstRdyxSI    : in  std_logic;
          --              
          EmptyxSO        : out std_logic;
          AlmostEmptyxSO  : out std_logic;
          AlmostFullxSO   : out std_logic;
          FullxSO         : out std_logic;
          OverflowxSO     : out std_logic
      );
  end component ShiftRegFifoRROut;
  
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
    
end package components;



