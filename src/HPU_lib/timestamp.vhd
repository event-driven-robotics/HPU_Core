-------------------------------------------------------------------------------
-- Timestamp
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


--****************************
--   PORT DECLARATION
--****************************

entity Timestamp is 
    port (
        Rst_xRBI       : in  std_logic;
        Clk_xCI        : in  std_logic;
        Zero_xSI       : in  std_logic;
        CleanTimer_xSI : in  std_logic;
        LoadTimer_xSI  : in  std_logic;
        LoadValue_xSI  : in std_logic_vector(31 downto 0);
        Timestamp_xDO  : out std_logic_vector(31 downto 0)
    );
end entity Timestamp;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of Timestamp is

    signal ClkCnt_xDP, ClkCnt_xDN : unsigned(2 downto 0);
    signal TsCnt_xDP, TsCnt_xDN : unsigned(31 downto 0);

    -- Clk is at 100 MHz == 10ns
    -- divisor is 8
    -- Timestamp Clock is 12.5 MHz == 80ns
  
begin

    Timestamp_xDO <= std_logic_vector(TsCnt_xDP);


    p_next : process (ClkCnt_xDP, TsCnt_xDP, Zero_xSI, CleanTimer_xSI, ClkCnt_xDN, LoadTimer_xSI, LoadValue_xSI)
    begin

        ClkCnt_xDN <= ClkCnt_xDP;
        TsCnt_xDN  <= TsCnt_xDP;
    
        if ((Zero_xSI = '1') or (CleanTimer_xSI = '1')) then
            ClkCnt_xDN <= (others => '0');
            TsCnt_xDN  <= (others => '0');
        elsif (LoadTimer_xSI = '1') then
            ClkCnt_xDN <= (others => '0');
            TsCnt_xDN  <= unsigned(LoadValue_xSI);        
        else
            ClkCnt_xDN <= ClkCnt_xDP + 1;

            if (ClkCnt_xDN = 0) then
                TsCnt_xDN <= TsCnt_xDP + 1;
            end if;
        end if;

    end process p_next;


    p_state : process (Clk_xCI, Rst_xRBI)
    begin
    
        if (Rst_xRBI = '0') then               -- asynchronous reset (active low)
            ClkCnt_xDP <= (others => '0');
            TsCnt_xDP  <= (others => '0');
        elsif (rising_edge(Clk_xCI)) then       -- rising clock edge
            ClkCnt_xDP <= ClkCnt_xDN;
            TsCnt_xDP  <= TsCnt_xDN;
        end if;
        
    end process p_state;

    
end architecture beh;

-------------------------------------------------------------------------------
