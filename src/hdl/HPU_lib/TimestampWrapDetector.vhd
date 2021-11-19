-------------------------------------------------------------------------------
-- Timestamp wrap detector
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


--****************************
--   PORT DECLARATION
--****************************

entity TimestampWrapDetector is
    port (
        Reset_n_i      : in  std_logic;
        Clk_i          : in  std_logic;
        MSB_i          : in  std_logic;
        WrapDetected_o : out std_logic
    );
end entity TimestampWrapDetector;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of TimestampWrapDetector is

    signal msb_s : std_logic;

begin

    p_sample : process (Clk_i)
    begin
        if (rising_edge(Clk_i)) then
            if (Reset_n_i = '0') then
                msb_s <= '0';
            else
                msb_s <= MSB_i;
            end if;
        end if;
    end process p_sample;

    WrapDetected_o <= msb_s and not(MSB_i);

end architecture beh;

-------------------------------------------------------------------------------
