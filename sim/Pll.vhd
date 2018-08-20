-- #-------------------------------------------------------------------------------
-- #  Author   : Francesco Diotalevi
-- # Company   : IIT - Fondazione Istituto Italiano di Tecnologia
-- #             Headquarter Genova, Italy.
-- # Department: RBCS, EDL
-- #       Date: September 2012
-- #-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

entity PLL is
    generic(
        SYSCLK_PERIOD     : integer := 10;
        SD_PERIOD        : integer := 50;
       SWEEP   : integer := 0
    );
    port(
    -- System clock
        rst_in       : in   std_logic;      -- Reset in
        rst_out      : out  std_logic;      -- Reset out
        SYS_CLK      : out  std_logic;      -- Clock 
        sd_rst_out  : out  std_logic;      -- Reset out
        SD_CLK      : out  std_logic       -- Clock 
    );
end PLL;

architecture synth of PLL is 

  constant TSCALE          : time := 1 ns;
  
  signal SYS_CLKIN         : std_logic;
  signal SD_CLKIN         : std_logic;

  
  type   state_value is (idle, down, up) ;
  signal state : state_value := idle;

  signal sweep_period : integer := 3130;
  constant inc  : integer := 50;

begin

-- Drive the output port with the internal signals
SYS_CLK     <= SYS_CLKIN;
SD_CLK     <= SD_CLKIN;

-----------------------------------------------------------------------
-- This controls the clock generation for the system
-----------------------------------------------------------------------
p_ClockGen : process

    variable PHASETIME   : time ;
    variable sweep_time   : time ;
    variable MODULE      : integer;

begin

    PHASETIME := SYSCLK_PERIOD/2 * TSCALE;
    MODULE    := SYSCLK_PERIOD mod 2;
    sweep_time := sweep_period/2 * TSCALE;

if (SWEEP = 1) then

    SYS_CLKIN <= '0';
    wait for sweep_time;
    SYS_CLKIN <= '1';
    wait for sweep_time;

else        
    
    
    if (MODULE = 0) then
        SYS_CLKIN <= '0';
        wait for PHASETIME;
        SYS_CLKIN <= '1';
        wait for PHASETIME;
    else
        SYS_CLKIN <= '0';
        wait for PHASETIME + 0.5 ns;
        SYS_CLKIN <= '1';
        wait for PHASETIME + 0.5 ns;
    end if;

end if;

end process p_ClockGen;

p_epiClockGen : process

    variable PHASETIME   : time ;
    variable sweep_time   : time ;
    variable MODULE      : integer;

begin

    PHASETIME := SD_PERIOD/2 * TSCALE;
    MODULE    := SD_PERIOD mod 2;
    sweep_time := sweep_period/2 * TSCALE;

if (SWEEP = 1) then

    SD_CLKIN <= '0';
    wait for sweep_time;
    SD_CLKIN <= '1';
    wait for sweep_time;

else        
    
    
    if (MODULE = 0) then
        SD_CLKIN <= '0';
        wait for PHASETIME;
        SD_CLKIN <= '1';
        wait for PHASETIME;
    else
        SD_CLKIN <= '0';
        wait for PHASETIME + 0.5 ns;
        SD_CLKIN <= '1';
        wait for PHASETIME + 0.5 ns;
    end if;

end if;

end process p_epiClockGen;


p_Rst : process(rst_in, SYS_CLKIN)

begin

    if (rst_in = '0') then
      
      rst_out <= '0';
    
    elsif (SYS_CLKIN'event and SYS_CLKIN = '0') then

      rst_out <= '1';
      
    end if;

end process p_Rst;

p_epi_Rst : process(rst_in, SD_CLKIN)

begin

    if (rst_in = '0') then
      
      sd_rst_out <= '0';
    
    elsif (SD_CLKIN'event and SD_CLKIN = '0') then

      sd_rst_out <= '1';
      
    end if;

end process p_epi_Rst;


--- Sweep Process

state_change: process(sweep_period)

variable next_state: state_value := idle;
variable new_period: integer;

begin
		
		case state is
		
			when idle => 
				
				next_state := down;
			
			when down => 
				
				if (sweep_period = 30) then
				
                                next_state := up;
				
                            else next_state := down;
				
                           end if;
			
			when up => 
				
				if (sweep_period = 3130) then
					
                                next_state := down;
				
                            else next_state := up;
				
                            end if;
			
			when others =>
				
				next_state := idle;
		
		end case;
		
		state <= next_state;
	
end process state_change;

result: process
  
  begin
  
      case state is
  
             when idle =>
      
                    wait for 22.5 us;
                    sweep_period <= 3130;

             when up =>
      
                    sweep_period <= sweep_period + inc;
                    wait for 22.5 us;
             
             when down =>
      
                    sweep_period <= sweep_period - inc;
                    wait for 22.5 us;
  
      end case;
  
end process result;



end synth;

-- --================================= End ===================================--
