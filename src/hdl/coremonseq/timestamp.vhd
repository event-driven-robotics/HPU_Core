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
        Rst_n_i        : in  std_logic;
        Clk_i          : in  std_logic;
        Zero_i         : in  std_logic;
        CleanTimer_i   : in  std_logic;
        LoadTimer_i    : in  std_logic;
        LoadValue_i    : in std_logic_vector(31 downto 0);
        Timestamp_o    : out std_logic_vector(31 downto 0)
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

    Timestamp_o <= std_logic_vector(TsCnt_xDP);


    p_next : process (ClkCnt_xDP, TsCnt_xDP, Zero_i, CleanTimer_i, ClkCnt_xDN, LoadTimer_i, LoadValue_i)
    begin

        ClkCnt_xDN <= ClkCnt_xDP;
        TsCnt_xDN  <= TsCnt_xDP;
    
        if ((Zero_i = '1') or (CleanTimer_i = '1')) then
            ClkCnt_xDN <= (others => '0');
            TsCnt_xDN  <= (others => '0');
        elsif (LoadTimer_i = '1') then
            ClkCnt_xDN <= (others => '0');
            TsCnt_xDN  <= unsigned(LoadValue_i);        
        else
            ClkCnt_xDN <= ClkCnt_xDP + 1;

            if (ClkCnt_xDN = 0) then
                TsCnt_xDN <= TsCnt_xDP + 1;
            end if;
        end if;

    end process p_next;


    p_state : process (Clk_i, Rst_n_i)
    begin
    
        if (Rst_n_i = '0') then               -- asynchronous reset (active low)
            ClkCnt_xDP <= (others => '0');
            TsCnt_xDP  <= (others => '0');
        elsif (rising_edge(Clk_i)) then       -- rising clock edge
            ClkCnt_xDP <= ClkCnt_xDN;
            TsCnt_xDP  <= TsCnt_xDN;
        end if;
        
    end process p_state;

    
end architecture beh;

-------------------------------------------------------------------------------
