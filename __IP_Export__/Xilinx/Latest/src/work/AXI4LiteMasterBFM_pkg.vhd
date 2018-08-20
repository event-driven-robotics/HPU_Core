-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Author: 			F. Diotalevi
-- Company:			IIT
-- Purpose:
-- Project:			
-- Department:	Robotics, Brain and Cognitive Sciences
--             Electronic Design Laboratory
-- 
-- No part of this document can be photocopied, 
-- reproduced, translated, or stored on electronic 
-- storage without the prior written agreement of IIT
-- 
-- IIT, Italian Institute of Technology (C) COPYRIGHT 2011
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_TEXTIO.all;

library std;
	use std.textio.all;

package AXI4LiteMasterBFM_pkg is
-- Declare constants
--
    constant MESSAGE_LENGTH     : integer := 128; 

    --------------------------------------------------------------------------
    -- Parse BFM Command Line
    --
    -- Write Data       WRD <ADDR> <DATA>
    -- Read Data        RDD <ADDR> <DATA_EXPECTED>
    -- Print a message  PRT  
    --------------------------------------------------------------------------

    constant WRD                : integer :=  1;
    constant RDD                : integer :=  2;
    constant PRT                : integer :=  3;
    constant WAT                : integer :=  4;
    constant FIN                : integer :=  5;
    constant DMR                : integer :=  6;
    constant DMW                : integer :=  7;
	constant RDV				: integer :=  8;
    constant WIN				: integer :=  9;
    constant DVS				: integer := 10;
    constant NCE				: integer := 11;
    constant RST				: integer := 12;
    constant RDM                : integer := 13;
    constant CUR                : integer := 14;
    constant SDM                : integer := 15;
    constant OCP                : integer := 16;
    constant EXF                : integer := 17;

--
-- Declare functions and procedure
--
    type REGISTER_TYPE is record
        register_address : std_logic_vector(31 downto 0);
        register_list     : integer;
    end record;
    
    type DMADataType is array (0 to 63) of std_logic_vector(31 downto 0);
    
    type OP_ENTRY is record
        OPCODE          : integer;
        ADDR            : std_logic_vector(31 downto 0);
        CLOCK_NUM       : integer;
        DATA            : std_logic_vector(31 downto 0);
        MASK            : std_logic_vector(31 downto 0);
        MESSAGE         : string(1 to MESSAGE_LENGTH);
        REG             : string(1 to 8);
		CAMERA          : CHARACTER;
		ENABLE_CAM      : natural;
		TIMEOUT         : time;
		VALUE           : std_logic_vector(7 downto 0);
        NUMREAD         : positive;
        DMALENGTH       : natural;
        NUMDATA         : natural;
        RPTBURST        : natural;
        DMADATA         : DMADataType;
        ENABLENC        : natural;
        ENABLEDMA       : natural;
        WAITSYNC        : natural;
--        Voltage         : t_VOLT;
        regoffset       : integer;
        ocp             : integer;
        ext_fault       : integer;
    end record;

    procedure read_cmd_file (
        file file_handler : TEXT;
        op_elem           : out OP_ENTRY;
        eof_reached       : out std_logic
    );

end AXI4LiteMasterBFM_pkg;

package body AXI4LiteMasterBFM_pkg is

    ---------------------------------------------------------------------
    -- Procedure to read command file lines
    ---------------------------------------------------------------------
    procedure read_cmd_file(
        file file_handler : TEXT;
        op_elem           : out OP_ENTRY;
        eof_reached       : out std_logic
    ) is
    
        variable num            : integer;
        variable buf            : line;
        variable v_opcode       : string(1 to 3);
        variable msg_char       : CHARACTER;
        variable good           : boolean;
        variable space          : string(1 to 3);
        variable timeout        : time;
        variable i              : integer;
        
        variable v_buf_out: line;
        variable tmp_reg        : string(1 to 8);

    begin
 
        while ( not ENDFILE(file_handler) ) loop

            READLINE(file_handler, buf);
        
            -- Read first character: if the first character is a '#'
            -- then the line is a comment and can be skipped
            READ(buf, v_opcode(1));
            exit when ( v_opcode(1) /= '#' and buf'length /= 0);

        end loop;


        if ( not ENDFILE(file_handler) ) then

            -- Complete the OpCode reading
            for i in 2 to 3 loop
                READ(buf, v_opcode(i));
            end loop;
            READ(buf, msg_char, good);

            -- Translate string OpCode to the corresponding integer value
            if    (v_opcode = "WRD") then op_elem.OPCODE := WRD;
            elsif (v_opcode = "RDD") then op_elem.OPCODE := RDD;
            elsif (v_opcode = "PRT") then op_elem.OPCODE := PRT;
            elsif (v_opcode = "WAT") then op_elem.OPCODE := WAT;
            elsif (v_opcode = "FIN") then op_elem.OPCODE := FIN;
            elsif (v_opcode = "DMR") then op_elem.OPCODE := DMR;
            elsif (v_opcode = "DMW") then op_elem.OPCODE := DMW;
			elsif (v_opcode = "RDV") then op_elem.OPCODE := RDV;
			elsif (v_opcode = "WIN") then op_elem.OPCODE := WIN;
 			elsif (v_opcode = "RDM") then op_elem.OPCODE := RDM;
 			elsif (v_opcode = "DVS") then op_elem.OPCODE := DVS;
 			elsif (v_opcode = "NCE") then op_elem.OPCODE := NCE;
 			elsif (v_opcode = "RST") then op_elem.OPCODE := RST;
 			elsif (v_opcode = "CUR") then op_elem.OPCODE := CUR;
 			elsif (v_opcode = "SDM") then op_elem.OPCODE := SDM;
            elsif (v_opcode = "OCP") then op_elem.OPCODE := OCP;
            elsif (v_opcode = "EXF") then op_elem.OPCODE := EXF;
           else
                assert (FALSE) report ">>>> AXI4Lite Master BFM: Command unknown."
                severity NOTE;
            end if;

            case (v_opcode) is

               when "DVS" => 
                    -- Read the camera num of aoutput data
                    READ(buf, op_elem.NUMDATA);

               when "WRD" | "RDD" => 
                    -- Read the ADDR field
                    for i in 1 to 8 loop
                     READ(buf, msg_char, good);
                       if good then
                           tmp_reg(i) := msg_char;
                       else
                           tmp_reg(i) := ' ';
                       end if;
                    end loop; 
                    op_elem.REG:=tmp_reg;
                    -- Read the data
                    HREAD(buf, op_elem.DATA);

               when "RDM" => 
                    -- Read the ADDR field
                    for i in 1 to 8 loop
                     READ(buf, msg_char, good);
                       if good then
                           tmp_reg(i) := msg_char;
                       else
                           tmp_reg(i) := ' ';
                       end if;
                    end loop; 
                    op_elem.REG:=tmp_reg;
                    -- Read the data
                    HREAD(buf, op_elem.DATA);
                    -- Read the Mask
                    HREAD(buf, op_elem.MASK);
                    -- Read max num of read
                    READ(buf, op_elem.NUMREAD);

               when "PRT" => 
                    -- Read the string message
                    for i in 1 to MESSAGE_LENGTH loop
                     READ(buf, msg_char, good);
                       if good then
                           op_elem.MESSAGE(i) := msg_char;
                       else
                           op_elem.MESSAGE(i) := ' ';
                       end if;
                    end loop; 
                 
			   when "WAT" => 
                    -- Read the num of CLOCK to wait
                    READ(buf, num);
                    op_elem.CLOCK_NUM := num;

               when "RDV" => 
                    -- Read the ADDR field
                    for i in 1 to 8 loop
                     READ(buf, msg_char, good);
                       if good then
                           tmp_reg(i) := msg_char;
                       else
                           tmp_reg(i) := ' ';
                       end if;
                    end loop; 
                    op_elem.REG:=tmp_reg;

               when "DMR" => 
                    -- Read the length of DMA
                    READ(buf, op_elem.dmalength);
                    -- Read the number of repeated burst
                    READ(buf, op_elem.rptburst);

               when "DMW" => 
                    -- Read the length of DMA
                    READ(buf, num);
                    op_elem.dmalength := num;
                    -- Read the number of repeated burst
                    READ(buf, op_elem.rptburst);
                    for i in 0 to (num-1) loop
                        HREAD(buf, op_elem.DMADATA(i));
                    end loop;

               when "FIN" => 
                    null;

               when "NCE" => 
                    -- Read the Enable
                    READ(buf, op_elem.ENABLENC);

               when "RST" => 
                    null;
                    
--                when "CUR" => 
--                     i:=0;
--                     while (true) loop
--                      READ(buf, op_elem.Voltage.val(i), good);
--                        if good then
--                            i:=i+1;
--                        else
--                            exit;
--                        end if;
--                     end loop;
--                     op_elem.Voltage.num:=i; 

               when "SDM" => 
                    -- Read the Enable
                    READ(buf, op_elem.ENABLEDMA);

               when "OCP" => 
                    -- Read the ocp
                    READ(buf, num);
                    op_elem.ocp := num;

               when "EXF" => 
                    -- Read the external_fault
                    READ(buf, num);
                    op_elem.ext_fault := num;

              when others =>
                    null;

            end case;
            
            eof_reached := '0';

        else
--         End of simulation has been moved into command bfm, it happens when the input command file is all read

--             assert (FALSE) report ">>>> AXI4 Lite Master BFM: Command file finished."
--             severity NOTE;
--             assert (FALSE) report ">>>> Simulation finished."
--             severity FAILURE;

            eof_reached := '1';

        end if;

    end read_cmd_file;

end AXI4LiteMasterBFM_pkg;
