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
        Rst_n_i         : in  std_logic;
        Clk_i           : in  std_logic;
        Timestamp_i     : in  std_logic_vector(31 downto 0);
        FullTimestamp_i : in  std_logic;
        --              
        MonEn_i         : in  std_logic;
        --              
        InAddr_i        : in  std_logic_vector(31 downto 0);
        InSrcRdy_i      : in  std_logic;
        InDstRdy_o      : out std_logic;
        --              
        OutAddrEvt_o    : out std_logic_vector(63 downto 0);
        OutWrite_o      : out std_logic;
        OutFull_i       : in  std_logic
    );
end entity MonitorRR;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of MonitorRR is

    signal MonEn_xS, MonEn_xSAA : std_logic;

begin

    p_memless : process (InAddr_i, InSrcRdy_i, MonEn_xS, OutFull_i,
                         Timestamp_i, FullTimestamp_i)
    begin
        if (MonEn_xS = '1') then
            if (FullTimestamp_i='0') then
                -- normal operation
                OutAddrEvt_o(63 downto 32) <= "10000000" & Timestamp_i(23 downto 0);
            else
                OutAddrEvt_o(63 downto 32) <= Timestamp_i(31 downto 0);
            end if;
            OutAddrEvt_o(31 downto 0)  <= InAddr_i;
            --
            InDstRdy_o                 <= not OutFull_i;
            OutWrite_o                 <= not OutFull_i and InSrcRdy_i;
        else
            -- no output
            OutAddrEvt_o <= (others => '0');
            OutWrite_o   <= '0';
            -- sink at input
            InDstRdy_o   <= '1';
        end if;
    end process p_memless;

    
    -- synchronizer
    p_sync : process (Clk_i)
    begin
        if (rising_edge(Clk_i)) then
            MonEn_xS   <= MonEn_xSAA;
            MonEn_xSAA <= MonEn_i;
        end if;
    end process p_sync;

end architecture beh;

-------------------------------------------------------------------------------
