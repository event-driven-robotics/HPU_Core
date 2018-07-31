------------------------------------------------------------------------
-- Package utilities_pkg
--
------------------------------------------------------------------------
-- Description:
--   Contains the definitions of some utilities function used inside
--   the whole FPGA
--
------------------------------------------------------------------------
 
library ieee;
    use ieee.std_logic_1164.all;

package utilities_pkg is

    constant RISE_EDGE : std_logic_vector(1 downto 0) := "01";
    constant FALL_EDGE : std_logic_vector(1 downto 0) := "10";

    function f_VectPosedgeDetect (Vect : std_logic_vector; VectSampled : std_logic_vector) return std_logic_vector;
    function f_OR_reduction (Vect : std_logic_vector) return std_logic;
    function f_AND_reduction (Vect : std_logic_vector) return std_logic;
    function f_PriorityEncoder (Vect : std_logic_vector) return natural;
    function f_Decoder (idx : natural; n : natural) return std_logic_vector;
    
    function f_ceil_log2 (x : natural) return natural;
    
    function To_StdLogic (x : boolean) return std_logic;

 end package utilities_pkg;



 package body utilities_pkg is

    function f_VectPosedgeDetect (Vect : std_logic_vector; VectSampled : std_logic_vector) return std_logic_vector is
        variable v_temp : std_logic_vector(Vect'range);
    begin
        v_temp := Vect;
        for i in Vect'range loop
            v_temp(i) := v_temp(i) and not(VectSampled(i));
        end loop;
        return v_temp;
    end function f_VectPosedgeDetect;

    function f_VectNegedgeDetect (Vect : std_logic_vector; VectSampled : std_logic_vector) return std_logic_vector is
        variable v_temp : std_logic_vector(Vect'range);
    begin
        v_temp := Vect;
        for i in Vect'range loop
            v_temp(i) := not(v_temp(i)) and VectSampled(i);
        end loop;
        return v_temp;
    end function f_VectNegedgeDetect;

    function f_OR_reduction (Vect : std_logic_vector) return std_logic is
        variable v_temp : std_logic;
    begin
        v_temp := '0';
        for i in Vect'range loop
            v_temp := v_temp or Vect(i);
        end loop;
        return v_temp;
    end function f_OR_reduction;

    function f_AND_reduction (Vect : std_logic_vector) return std_logic is
        variable v_temp : std_logic;
    begin
        v_temp := '1';
        for i in Vect'range loop
            v_temp := v_temp and Vect(i);
        end loop;
        return v_temp;
    end function f_AND_reduction;

    function f_PriorityEncoder (Vect : std_logic_vector) return natural is
        variable v_temp : natural range Vect'low to Vect'high;
    begin
        v_temp := 0;
        for i in Vect'high downto Vect'low loop
            if (Vect(i) = '1') then
                v_temp := i;
                exit;
            end if;
        end loop;
        return v_temp;
    end function f_PriorityEncoder;

    function f_Decoder (idx : natural; n : natural) return std_logic_vector is
        variable v_temp : std_logic_vector(n-1 downto 0);
    begin
        v_temp := (others => '0');
        v_temp(idx) := '1';
        return v_temp;
    end function f_Decoder;

    function f_ceil_log2 (x : natural) return natural is
        variable v_temp : natural;
        variable v_x : natural;
    begin
        assert (x > 0)
            report "Error: log2(0)"
            severity failure;

        v_temp := 0;
        v_x := x-1;
        while v_x > 0 loop
            v_x := v_x / 2;
            v_temp := v_temp + 1;
        end loop;
        
        return v_temp;
    end function f_ceil_log2;

    function To_StdLogic (x : boolean) return std_logic is
    begin
        if (x) then
            return '1';
        else
            return '0';
        end if;
    end function To_StdLogic;

 end package body utilities_pkg;



