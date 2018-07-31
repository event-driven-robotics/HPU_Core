-------------------------------------------------------------------------------
-- MonitorRR
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

    
--****************************
--   PORT DECLARATION
--****************************

entity MonitorRR is
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
end entity MonitorRR;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of MonitorRR is

    signal MonEn_xS, MonEn_xSAA : std_logic;

begin

    p_memless : process (InAddr_xDI, InSrcRdy_xSI, MonEn_xS, OutFull_xSI,
                         Timestamp_xDI, FullTimestamp_i)
    begin
        if (MonEn_xS = '1') then
            if (FullTimestamp_i='0') then
                -- normal operation
                OutAddrEvt_xDO(63 downto 32) <= "10000000" & Timestamp_xDI(23 downto 0);
            else
                OutAddrEvt_xDO(63 downto 32) <= Timestamp_xDI(31 downto 0);
            end if;
            OutAddrEvt_xDO(31 downto 0)  <= InAddr_xDI;
            --
            InDstRdy_xSO                 <= not OutFull_xSI;
            OutWrite_xSO                 <= not OutFull_xSI and InSrcRdy_xSI;
        else
            -- no output
            OutAddrEvt_xDO <= (others => '0');
            OutWrite_xSO   <= '0';
            -- sink at input
            InDstRdy_xSO   <= '1';
        end if;
    end process p_memless;

    
    -- synchronizer
    p_sync : process (Clk_xCI)
    begin
        if (rising_edge(Clk_xCI)) then
            MonEn_xS   <= MonEn_xSAA;
            MonEn_xSAA <= MonEn_xSAI;
        end if;
    end process p_sync;

end architecture beh;

-------------------------------------------------------------------------------
