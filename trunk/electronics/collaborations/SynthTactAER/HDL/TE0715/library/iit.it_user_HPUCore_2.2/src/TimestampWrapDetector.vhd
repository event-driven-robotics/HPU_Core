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
        Resetn       : in  std_logic;
        Clk          : in  std_logic;
        MSB          : in  std_logic;
        WrapDetected : out std_logic
    );
end entity TimestampWrapDetector;


--****************************
--   IMPLEMENTATION
--****************************

architecture beh of TimestampWrapDetector is

    signal msb_s : std_logic;

begin

    p_sample : process (Clk)
    begin
        if (rising_edge(Clk)) then
            if (Resetn = '0') then
                msb_s <= '0';
            else
                msb_s <= MSB;
            end if;
        end if;
    end process p_sample;

    WrapDetected <= msb_s and not(MSB);

end architecture beh;

-------------------------------------------------------------------------------
