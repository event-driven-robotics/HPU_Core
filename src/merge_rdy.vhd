library ieee;
    use ieee.std_logic_1164.all;

library common_lib;
    use common_lib.utilities_pkg.all;


entity merge_rdy is
    generic (
        N_CHAN        : natural := 4
    );                
    port (            
        nRst          : in  std_logic;
        Clk           : in  std_logic;
                      
        InVld_i       : in  std_logic;
        OutRdy_o      : out std_logic;
                      
        OutVldVect_o  : out std_logic_vector(N_CHAN-1 downto 0);
        InRdyVect_i   : in  std_logic_vector(N_CHAN-1 downto 0)
    );
end entity merge_rdy;


architecture beh of merge_rdy is
    
    signal i_rdy : std_logic;
    signal i_vldMask : std_logic_vector(N_CHAN-1 downto 0);
    signal i_inVldVect : std_logic_vector(N_CHAN-1 downto 0);

begin

    -- Generate a Ready condition when all the remaining sources acknowledge the valid signal
    i_rdy <= f_AND_reduction(InRdyVect_i or not(i_vldMask));
    
    p_vldMask : process (Clk)
    begin
        if (rising_edge(Clk)) then
            if (nRst = '0') then
                i_vldMask <= (others => '1');
            else
                for i in i_vldMask'range loop
                    if (i_rdy = '1') then
                        -- after a vld/rdy cycle completion reset the mask
                        i_vldMask(i) <= '1';
                    elsif (InVld_i = '1' and InRdyVect_i(i) = '1') then
                        -- clear the channels that have already acknowledged the valid signal
                        i_vldMask(i) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process p_vldMask;

    i_inVldVect <= (others => InVld_i);
    OutVldVect_o <= i_vldMask and i_inVldVect;
    OutRdy_o <= i_rdy;

end architecture beh;
