-------------------------------------------------------------------------------
-- Neuserial_AxiStream
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;


--****************************
--   PORT DECLARATION
--****************************

entity neuserial_axistream is
    generic (
        C_NUMBER_OF_INPUT_WORDS : natural := 2048;
        C_DEBUG                 : boolean := false
    );
    port (
        Clk                    : in  std_logic;
        nRst                   : in  std_logic;
        --                    
        DMA_test_mode_i        : in  std_logic;
        EnableAxistreamIf_i    : in  std_logic;
        DMA_is_running_o       : out std_logic;
        DmaLength_i            : in  std_logic_vector(10 downto 0);
        ResetStream_i          : in  std_logic;
        LatTlat_i              : in  std_logic;
        TlastCnt_o             : out std_logic_vector(31 downto 0);
        TlastTO_i              : in  std_logic_vector(31 downto 0);
        -- From Fifo to core/dma
        FifoCoreDat_i          : in  std_logic_vector(31 downto 0);
        FifoCoreRead_o         : out std_logic;
        FifoCoreEmpty_i        : in  std_logic;
        FifoCoreBurstReady_i   : in  std_logic;
        -- From core/dma to Fifo
        CoreFifoDat_o          : out std_logic_vector(31 downto 0);
        CoreFifoWrite_o        : out std_logic;
        CoreFifoFull_i         : in  std_logic;
        -- Axi Stream I/f
        S_AXIS_TREADY          : out std_logic;
        S_AXIS_TDATA           : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST           : in  std_logic;
        S_AXIS_TVALID          : in  std_logic;
        M_AXIS_TVALID          : out std_logic;
        M_AXIS_TDATA           : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST           : out std_logic;
        M_AXIS_TREADY          : in  std_logic;
        
        -- DBG
        DBG_data_written       : out std_logic;
        DBG_dma_burst_counter  : out std_logic_vector(10 downto 0);
        DBG_dma_test_mode      : out std_logic;
        DBG_dma_EnableDma      : out std_logic;
        DBG_dma_is_running     : out std_logic;
        DBG_dma_Length         : out std_logic_vector(10 downto 0);
        DBG_dma_nedge_run      : out std_logic
    );
end entity neuserial_axistream;

architecture rtl of neuserial_axistream is

    constant DUMMY_DATA : std_logic_vector(31 downto 0) := X"F0CACC1A";

    signal i_nrOfWrites    : natural range 0 to C_NUMBER_OF_INPUT_WORDS - 1;

    signal i_M_AXIS_TVALID : std_logic;
    signal i_M_AXIS_TLAST  : std_logic;
    signal i_enable_ip     : std_logic;
    signal i_dma_burst_counter : std_logic_vector (10 downto 0);
    signal i_test_counter : std_logic_vector (31 downto 0);
    signal i_delta_counter :  std_logic_vector (5 downto 0);
    signal i_valid_test_mode : std_logic;
    signal i_enable_ip_s : std_logic;
    signal i_TlastCnt : std_logic_vector(31 downto 0);
    signal i_TlastTimer : std_logic_vector(31 downto 0);
    signal i_timeexpired : std_logic;
    signal i_sentdata : std_logic;
    signal i_sendDummydata : std_logic;

begin

    tlastcnt_p : process (nRst, Clk)
    begin
        if (nRst = '0') then
          i_TlastCnt <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (i_M_AXIS_TLAST = '1' and i_M_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
                 i_TlastCnt <= i_TlastCnt + "01";
            end if;
        end if;
    end process tlastcnt_p;

    TlastCnt_o <= i_TlastCnt;

    tlasttimer_p : process (nRst, Clk)
    begin
        if (nRst = '0') then
          i_TlastTimer <= (others => '0');
          i_timeexpired <= '0';
          i_sentdata <= '0';
        elsif (Clk'event and Clk = '1') then
            if (LatTlat_i='1') then
                if (i_M_AXIS_TLAST = '1' and i_M_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
                    i_TlastTimer <= (others => '0');
                    i_timeexpired <= '0';
                    i_sentdata <= '0';
                elsif (i_TlastTimer/=TlastTO_i) then
                    i_TlastTimer <= i_TlastTimer + "01";
                    i_timeexpired <= '0';
                    if (i_M_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
                        i_sentdata <= '1';
                    end if;
                else
                    i_timeexpired <= '1';
                end if;
            end if;
        end if;
    end process tlasttimer_p;
    -- When i_timeexpired == '1' and i_sentdata =='1', means that we can close the AXI stream with a dummy TLAST
    i_sendDummydata <= i_timeexpired and i_sentdata;



    enable_p : process (nRst, Clk)
    begin
        if (nRst = '0') then
          i_enable_ip <= '0';
        elsif (Clk'event and Clk = '1') then
            if (ResetStream_i='1') then
                 i_enable_ip <= '0';
            else
                if EnableAxistreamIf_i = '1' then
                    i_enable_ip <= '1';
                -- The following is to finish the current burst regardless the Disable IP command from cpu
                elsif (i_M_AXIS_TLAST = '1' and i_M_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
                    i_enable_ip <= '0';
                end if;
            end if;
        end if;
    end process enable_p;

    DMA_is_running_o <= i_enable_ip;

    i_M_AXIS_TVALID <= (not(FifoCoreEmpty_i) and i_enable_ip) when (DMA_test_mode_i='0' and i_sendDummydata='0') else
                       '1' when (DMA_test_mode_i='0' and i_sendDummydata='1') else
                       i_valid_test_mode ;
    M_AXIS_TVALID <= i_M_AXIS_TVALID;

    burst_counter_p : process (nRst, Clk)
    begin
        if nRst = '0' then
            i_dma_burst_counter <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (ResetStream_i='1') then
                i_dma_burst_counter <= (others => '0');
            else
                if (M_AXIS_TREADY = '1' and i_M_AXIS_TVALID = '1' and i_M_AXIS_TLAST='1') then
                    i_dma_burst_counter <= (others => '0');
                elsif (M_AXIS_TREADY = '1' and i_M_AXIS_TVALID = '1') then
                    i_dma_burst_counter <= i_dma_burst_counter + "01";
                end if;
            end if;
        end if;
    end process burst_counter_p;
    
    tlast_p : process (i_M_AXIS_TVALID, i_dma_burst_counter, DmaLength_i, i_sendDummydata)
    begin
        if ((i_dma_burst_counter = DmaLength_i) or (i_sendDummydata='1')) then 
            i_M_AXIS_TLAST <= i_M_AXIS_TVALID;
        else 
            i_M_AXIS_TLAST <= '0';
        end if;
    end process tlast_p;
    
    M_AXIS_TLAST <= i_M_AXIS_TLAST;

    FifoCoreRead_o <= (M_AXIS_TREADY and i_M_AXIS_TVALID and not (FifoCoreEmpty_i)) when DMA_test_mode_i='0' else
                      '0';

    DBG_dma_burst_counter <= i_dma_burst_counter;
    DBG_dma_test_mode     <= DMA_test_mode_i;
    DBG_dma_EnableDma     <= EnableAxistreamIf_i;
    DBG_dma_is_running    <= i_enable_ip;
    DBG_dma_Length        <= DmaLength_i;
    DBG_dma_nedge_run     <= i_enable_ip_s and not(i_enable_ip);

    -- Test mode
    
    process (nRst, Clk)
    begin
        if nRst = '0' then
            i_test_counter <= (others => '0');
            i_enable_ip_s <= '0';

        elsif (Clk'event and Clk = '1') then
          i_enable_ip_s <= i_enable_ip;

          if (i_enable_ip = '0') then
            i_test_counter <= (others => '0');
          elsif (M_AXIS_TREADY = '1' and i_M_AXIS_TVALID = '1') then
            i_test_counter <= i_test_counter + "01";
          end if;
        end if;
    end process;
    
    M_AXIS_TDATA      <= FifoCoreDat_i when (DMA_test_mode_i='0' and i_sendDummydata='0') else
                         DUMMY_DATA when (DMA_test_mode_i='0' and i_sendDummydata='1') else
                         i_test_counter;
    
    deltacounter_p : process (nRst, Clk)
    begin
        if nRst = '0' then
            i_delta_counter <= (others => '1');
        elsif (Clk'event and Clk = '1') then
            if (ResetStream_i='1') then
                i_delta_counter <= (others => '1');
            else
                if (i_enable_ip='1' and DMA_test_mode_i='1' and i_valid_test_mode='1' and M_AXIS_TREADY='0' ) then
                    i_delta_counter <= i_delta_counter;
                else 
                    if (i_enable_ip='1' and DMA_test_mode_i='1') then
                        i_delta_counter <= i_delta_counter - "01";
                    else 
                        i_delta_counter <= (others => '1');
                    end if;
                end if;
            end if;
        end if;
    end process deltacounter_p;

    i_valid_test_mode <= '1' when i_delta_counter=0 else '0';
    -- Slave I/f

    S_AXIS_TREADY     <= not(CoreFifoFull_i) and i_enable_ip;
    CoreFifoDat_o     <= S_AXIS_TDATA;
    CoreFifoWrite_o   <= (not(CoreFifoFull_i) and S_AXIS_TVALID) and i_enable_ip;
    
    
    -- DEBUG
    
    DBG_data_written <= i_M_AXIS_TVALID and M_AXIS_TREADY;


end architecture rtl;
-------------------------------------------------------------------------------
