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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.MATH_REAL.ALL;
USE IEEE.numeric_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library std;
	use std.textio.all;
library work;
	use work.AXI4LiteMasterBFM_pkg.all;

entity axi4lite_bfm_v00 is
   generic(
		limit : integer := 1000;
		NORANDOM_DMA : integer := 0;
        SPI_ADC_RES : integer := 24;
        NUM_OF_RECEIVER    : natural := 32;
      AXI4LM_CMD_FILE    : string        := "AXI4LM_bfm.cmd";  -- Command file name
      AXI4LM_LOG_FILE    : string        := "AXI4LM_bfm.log"   -- Log file name
		);
    Port ( S_AXI_ACLK : in  STD_LOGIC;
           S_AXI_ARESETN : in  STD_LOGIC;
           S_AXI_AWVALID : out  STD_LOGIC;
           S_AXI_AWREADY : in  STD_LOGIC;
           S_AXI_AWADDR : out  STD_LOGIC_VECTOR (31 downto 0);
           S_AXI_WVALID : out  STD_LOGIC;
           S_AXI_WREADY : in  STD_LOGIC;
           S_AXI_WDATA : out  STD_LOGIC_VECTOR (31 downto 0);
           S_AXI_WSTRB : out  STD_LOGIC_VECTOR (3 downto 0);
           S_AXI_BVALID : in  STD_LOGIC;
           S_AXI_BREADY : out  STD_LOGIC;
           S_AXI_BRESP : in  STD_LOGIC_VECTOR (1 downto 0);
           S_AXI_ARVALID : inout  STD_LOGIC;
           S_AXI_ARREADY : in  STD_LOGIC;
           S_AXI_ARADDR : out  STD_LOGIC_VECTOR (31 downto 0);
           S_AXI_RVALID : in  STD_LOGIC;
           S_AXI_RREADY : out  STD_LOGIC;
           S_AXI_RDATA : in  STD_LOGIC_VECTOR (31 downto 0);
           S_AXI_RRESP : in  STD_LOGIC_VECTOR (1 downto 0);
           M_Axis_TVALID  : in  std_logic;
           M_Axis_TLAST   : in  std_logic;
           M_Axis_TDATA   : in  std_logic_vector (31 downto 0);
           M_Axis_TREADY  : out std_logic;
           S_AXIS_TREADY  : in  std_logic;
           S_AXIS_TDATA   : out std_logic_vector(31 downto 0);
           S_AXIS_TLAST   : out std_logic;
           S_AXIS_TVALID  : out std_logic;
           -- axi master
           M_AXI_ACLK : in  STD_LOGIC;
           M_AXI_AWADDR   : in  std_logic_vector(31 downto 0);
           M_AXI_AWLEN    : in  std_logic_vector(7 downto 0); 
           M_AXI_AWSIZE   : in  std_logic_vector(2 downto 0);
           M_AXI_AWBURST  : in  std_logic_vector(1 downto 0);
           M_AXI_AWCACHE  : in  std_logic_vector(3 downto 0);
           M_AXI_AWVALID  : in  std_logic; 
           M_AXI_AWREADY  : out std_logic; 
           --       master interface write data
           M_AXI_WDATA    : in  std_logic_vector(31 downto 0); 
           M_AXI_WSTRB    : in  std_logic_vector(3 downto 0);
           M_AXI_WLAST    : in  std_logic;  
           M_AXI_WVALID   : in  std_logic;   
           M_AXI_WREADY   : out std_logic;  
           --       master interface write response
           M_AXI_BRESP    : out std_logic_vector(1 downto 0); 
           M_AXI_BVALID   : out std_logic;   
           M_AXI_BREADY   : in  std_logic;

           start_dmas     : out std_logic;
           dma_done       : in  std_logic;

           ocp_o          : out std_logic;
           ext_fault_o    : out std_logic;
           
           interrupt  	: in std_logic;
           start        : in std_logic

          );
end axi4lite_bfm_v00;

architecture Behavioral of axi4lite_bfm_v00 is
	
	-- Clock period definitions
  file logfile_ptr      : text open WRITE_MODE is AXI4LM_LOG_FILE;
  file cmdfile_ptr      : text open READ_MODE  is AXI4LM_CMD_FILE;
  
  type t_Voltage_real_array is array (natural range <>) of real;

function ParseReg (Reg : string (1 to 8); offset: integer)
    return REGISTER_TYPE is
    
    variable address : std_logic_vector (31 downto 0);
    variable regnum  : integer;
    variable returnValue : REGISTER_TYPE;
begin
    case (Reg) is
        when "CTRL    " => address:=x"00000000"; regnum:=1 ;
        when "LPBK    " => address:=x"00000004"; regnum:=2 ;
        when "RXDATA  " => address:=x"00000008"; regnum:=3 ;
        when "RXTIME  " => address:=x"0000000C"; regnum:=4 ;
        when "TXDATA  " => address:=x"00000010"; regnum:=5 ;
        when "DMA_B   " => address:=x"00000014"; regnum:=6 ;
        when "STAT_RAW" => address:=x"00000018"; regnum:=7 ;
        when "IRQ_REG " => address:=x"0000001C"; regnum:=8 ;
        when "MSK_REG " => address:=x"00000020"; regnum:=9 ;
        when "WRAPTS  " => address:=x"00000028"; regnum:=10;
        when "SAER_ST " => address:=x"00000034"; regnum:=11;
        when "SAERRXER" => address:=x"00000038"; regnum:=12;
        when "SAERRXMS" => address:=x"0000003C"; regnum:=13;
        when "RX_CTRL " => address:=x"00000040"; regnum:=14;
        when "TX_CTRL " => address:=x"00000044"; regnum:=15;
        when "RXPAERCF" => address:=x"00000048"; regnum:=16;
        when "TXPAERCF" => address:=x"0000004C"; regnum:=17;
        when "IPCONFIG" => address:=x"00000050"; regnum:=18;
        when "FIFOTHRS" => address:=x"00000054"; regnum:=19;
        when "LPBK_AUX" => address:=x"00000058"; regnum:=20;
        when "ID_REG  " => address:=x"0000005C"; regnum:=21;
        when "AUX_CTRL" => address:=x"00000060"; regnum:=22;
        when "SAAUXRXE" => address:=x"00000064"; regnum:=23;
        when "SAAUXRXM" => address:=x"00000068"; regnum:=24;
        when "SARETHR " => address:=x"0000006C"; regnum:=25;
        when "SARE_CH0" => address:=x"00000070"; regnum:=26;
        when "SARE_CH1" => address:=x"00000074"; regnum:=27;
        when "SARE_CH2" => address:=x"00000078"; regnum:=28;
        when "SARE_CH3" => address:=x"0000007C"; regnum:=29;

        when others =>   assert (FALSE) report "In accesing REGISTER" severity ERROR;
    end case;
    
    returnValue.register_address := address;
    returnValue.register_list := regnum;
    
    return(returnValue);
end ParseReg;

------------------------------------------------------------------
--- Procedure FinishSimulation
------------------------------------------------------------------
procedure  FinishSimulation(
   signal  aclk  : in std_logic) is
   variable v_buf_out: line;
begin
  for i in 1 to 10 loop
		wait until (aclk'event and aclk='1');
  end loop;
  
  write (v_buf_out, string'(">>>> End of Simulation") );
  writeline (output, v_buf_out);

  write (v_buf_out, string'(">>>> End of Simulation") );
  writeline (logfile_ptr, v_buf_out);
  
end procedure FinishSimulation;

------------------------------------------------------------------
--- Procedure DMARead
------------------------------------------------------------------
procedure  DMARead_old(
   signal    aclk           : in  std_logic;
   constant  lenghtOfBurst  : in  natural;
   constant  repeatedBurst  : in  natural;
   signal    M_Axis_TVALID  : in  std_logic;
   signal    M_Axis_TLAST   : in  std_logic;
   signal    M_Axis_TDATA   : in  std_logic_vector (31 downto 0);
   signal    M_Axis_TREADY  : out std_logic
   ) is
   variable v_buf_out: line;
   variable v_looptimes : natural;
   variable v_Burst : natural;
   variable TDATA : std_logic_vector (31 downto 0);
   variable data_type : natural;
begin

  v_looptimes := repeatedBurst;
  v_Burst := lenghtOfBurst;
  
  while (v_looptimes>0) loop
      wait until (aclk'event and aclk='1');
      M_Axis_TREADY <= '1';

      write (v_buf_out, now);
      write (v_buf_out, string'(" DMA Read. ") );
      write (v_buf_out, repeatedBurst-v_looptimes);
      writeline (output, v_buf_out);

      write (v_buf_out, now);
      write (v_buf_out, string'(" DMA Read. ") );
      write (v_buf_out, repeatedBurst-v_looptimes);
      writeline (logfile_ptr, v_buf_out);
     
      while (v_Burst>0 and M_Axis_TLAST='0') loop
        wait until (aclk'event and aclk='1');
        if (M_Axis_TVALID='1') then
            TDATA:=M_Axis_TDATA;
            data_type:=v_Burst mod 2;
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, lenghtOfBurst-v_Burst );
    	    write (v_buf_out, string'(": Read ") );
    	    hwrite (v_buf_out, TDATA );
            writeline (output, v_buf_out);
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, lenghtOfBurst-v_Burst );
    	    write (v_buf_out, string'(": Read ") );
    	    hwrite (v_buf_out, TDATA );
            writeline (logfile_ptr, v_buf_out);
            
            v_burst := v_burst - 1;
        end if;
        if (M_Axis_TLAST='1') then
            M_Axis_TREADY <= '0';
        end if;
      end loop;
      v_Burst := lenghtOfBurst;
      M_Axis_TREADY<= '0';
      v_looptimes:=v_looptimes-1;
  end loop;
end procedure DMARead_old;

procedure  DMARead(
   signal    aclk           : in  std_logic;
   constant  repeatedBurst  : in  natural;
   signal    M_Axis_TVALID  : in  std_logic;
   signal    M_Axis_TLAST   : in  std_logic;
   signal    M_Axis_TDATA   : in  std_logic_vector (31 downto 0);
   signal    M_Axis_TREADY  : out std_logic
   ) is
   variable v_buf_out: line;
   variable v_Burst : natural;
   variable TDATA : std_logic_vector (31 downto 0);
   variable i : natural;
begin

  wait until (aclk'event and aclk='1');
  M_Axis_TREADY <= '1';
  write (v_buf_out, now);
  write (v_buf_out, string'(" DMA Read. ") );
  writeline (output, v_buf_out);

  write (v_buf_out, now);
  write (v_buf_out, string'(" DMA Read. ") );
  writeline (logfile_ptr, v_buf_out);
  
  v_Burst := repeatedBurst;
  i:=0;
  while (v_Burst>0) loop
      wait until (aclk'event and aclk='1');
        if (M_Axis_TVALID='1') then
            TDATA:=M_Axis_TDATA;
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, repeatedBurst-v_Burst );
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, i );
    	    write (v_buf_out, string'(": Read ") );
    	    hwrite (v_buf_out, TDATA );
            writeline (output, v_buf_out);
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, repeatedBurst-v_Burst );
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, i );
    	    write (v_buf_out, string'(": Read ") );
    	    hwrite (v_buf_out, TDATA );
            writeline (logfile_ptr, v_buf_out);
            
            i:=i+1;
        end if;
            
        if (M_Axis_TLAST='1') then
    	    write (v_buf_out, string'(">>> End burst") );
            writeline (output, v_buf_out);
    	    write (v_buf_out, string'(">>> End burst") );
            writeline (logfile_ptr, v_buf_out);
            v_burst := v_burst - 1;
            i := 0;
        end if;
  end loop;
  
  M_Axis_TREADY<= '0' after 0.1 ns;
end procedure DMARead;

------------------------------------------------------------------
--- Procedure DMAWrite
------------------------------------------------------------------
procedure  DMAWrite(
   signal    aclk           : in  std_logic;
   constant  lenghtOfBurst  : in  natural;
   constant  DMAData        : in  DMADataType;
   constant  repeatedBurst  : in  natural;
   signal    S_Axis_TVALID  : out std_logic;
   signal    S_Axis_TLAST   : out std_logic;
   signal    S_Axis_TDATA   : out std_logic_vector (31 downto 0);
   signal    S_Axis_TREADY  : in std_logic
   ) is
   variable v_buf_out: line;
   variable v_looptimes : natural;
   variable v_Burst : natural;
   variable TDATA : std_logic_vector (31 downto 0);
begin

  v_looptimes := repeatedBurst;
  v_Burst := lenghtOfBurst;
  
  while (v_looptimes>0) loop
      wait_ok: loop
          wait until (aclk'event and aclk='1');
          exit wait_ok when S_Axis_TREADY = '1';
      end loop;

      write (v_buf_out, now);
      write (v_buf_out, string'(" DMA Write. ") );
      write (v_buf_out, repeatedBurst-v_looptimes);
      writeline (output, v_buf_out);

      write (v_buf_out, now);
      write (v_buf_out, string'(" DMA Write. ") );
      write (v_buf_out, repeatedBurst-v_looptimes);
      writeline (logfile_ptr, v_buf_out);
     
      wait until (aclk'event and aclk='1');
      while (v_Burst>0) loop
        if (S_Axis_TREADY='1') then
            S_Axis_TDATA<=DMAData(lenghtOfBurst-v_Burst);
            S_Axis_TVALID<= '1';
    	    
            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, lenghtOfBurst-v_Burst );
    	    write (v_buf_out, string'(": Write ") );
   	        write (v_buf_out, string'("DVS ") );
    	    hwrite (v_buf_out, DMAData(lenghtOfBurst-v_Burst) );
            writeline (output, v_buf_out);

            write (v_buf_out, string'("  ") );
    	    write (v_buf_out, lenghtOfBurst-v_Burst );
    	    write (v_buf_out, string'(": Write ") );
   	        write (v_buf_out, string'("DVS ") );
    	    hwrite (v_buf_out, DMAData(lenghtOfBurst-v_Burst) );
            writeline (logfile_ptr, v_buf_out);
            
            v_burst := v_burst - 1;
        else
            S_Axis_TVALID<= '0';
        end if;
        if (v_Burst=0) then
            S_Axis_TLAST <= '1';
        end if;
        wait until (aclk'event and aclk='1');
      end loop;
      v_Burst := lenghtOfBurst;
      S_Axis_TVALID <= '0';
      S_Axis_TLAST <= '0';
      S_Axis_TDATA<=(others=>'0');
      v_looptimes:=v_looptimes-1;
  end loop;
end procedure DMAWrite;

------------------------------------------------------------------
--- Procedure PrintMsg: print a message 
------------------------------------------------------------------
procedure  PrintMsg(
   constant  message  : in	string(1 to MESSAGE_LENGTH)) is
   variable v_buf_out: line;
begin
  write (v_buf_out, message );
  write (v_buf_out, now);
  writeline (output, v_buf_out);
  write (v_buf_out, message );
  write (v_buf_out, now);
  writeline (logfile_ptr, v_buf_out);
end procedure PrintMsg;

------------------------------------------------------------------
--- Procedure WaitNClockCycles: Wait num_of_clock Cycles 
------------------------------------------------------------------
procedure  WaitNClockCycles(
   signal  aclk   : in  std_logic;
   constant  num_of_clock  : in	integer) is
begin
  for i in 1 to num_of_clock loop
		wait until (aclk'event and aclk='1');
  end loop;
end procedure WaitNClockCycles;

 
------------------------------------------------------------------
--- Procedure WriteData: this function writes at address the data 
------------------------------------------------------------------
procedure WriteData (
     signal  aclk   : in  std_logic;
     signal  awaddr : out  std_logic_vector (31 downto 0);
	  signal  awvalid  : out	std_logic;
	  signal  wvalid  : out	std_logic;
     signal  bready : out	std_logic;
     signal  wdata   : out	std_logic_vector (31 downto 0); 
     signal  awready : in	std_logic;
     signal  wready : in	std_logic;
	  signal  bvalid : in std_logic;
	  
     address      : in string(1 to 8);  
     data         : in std_logic_vector(31 downto 0);
     offset       : in integer
	  ) is
  variable v_buf_out: line;
  variable address_accessed : REGISTER_TYPE;
  begin
--	write (v_buf_out, string'(">>>> Procedure WriteData at ") );
--	write (v_buf_out, now);
--	writeline (logfile_ptr, v_buf_out);
	wait until (aclk'event and aclk='1');
    address_accessed := ParseReg(address, offset);
	awaddr   <= address_accessed.register_address;
	awvalid	<= '1';
	wdata 	<= data;
	wvalid	<= '1';
	bready   <= '1';
	loop 
		wait until (aclk'event and aclk='1');
		if (awready='1') then
			awvalid	<= '0';
		end if;
		if (wready='1') then
			wvalid	<= '0';
		end if;
		exit when (awready='1' and wready='1'); 
	end loop;
	
	loop
		if (bvalid='1') then
			bready<='0';
		end if;
		wait until (aclk'event and aclk='1');
		exit when (bvalid='1'); 
	end loop;
end procedure WriteData;

------------------------------------------------------------------
--- Procedure ReadData: this function reads at address and check if
--- read data is equal to  expecteddata 
------------------------------------------------------------------
procedure ReadData (
     signal  aclk   : in  std_logic;
     signal  araddr : out  std_logic_vector (31 downto 0);
	  signal  arvalid  : out	std_logic;
	  signal  rvalid  : in	std_logic;
     signal  arready : in	std_logic;
     signal  rready : out	std_logic;
	  signal  rdata : in std_logic_vector (31 downto 0);
	  
     address      : in string(1 to 8);  
     offset       : in integer;
     expecteddata  : in std_logic_vector(31 downto 0)
	  ) is
  variable v_buf_out: line;
  variable address_accessed : REGISTER_TYPE;
  begin
--	write (v_buf_out, string'(">>>> Procedure ReadData at ") );
--	write (v_buf_out, now);
--	writeline (output, v_buf_out);
--	write (v_buf_out, string'(">>>> Procedure ReadData at ") );
--	write (v_buf_out, now);
--	writeline (logfile_ptr, v_buf_out);
	wait until (aclk'event and aclk='1');
    address_accessed := ParseReg(address,offset);
	araddr   <= address_accessed.register_address;
	arvalid	<= '1'after 1 ns;
	rready	<= '1';
	loop 
		wait until (aclk'event and aclk='1');
		exit when (arready='1'); 
	end loop;
	arvalid	<= '0';
	loop
		wait until (aclk'event and aclk='1');
		if (rvalid='1') then
			-- read data
			write (v_buf_out, string'(">>>> ReadData at ") );
			write (v_buf_out, now);
			writeline (logfile_ptr, v_buf_out);

			if (rdata/=expecteddata) then 
				write (v_buf_out, string'(">>>> Read Data Mismatch at ") );
				write (v_buf_out, now);
				writeline (output, v_buf_out);
				write (v_buf_out, string'(">>>> Read Data Mismatch at ") );
				write (v_buf_out, now);
				writeline (logfile_ptr, v_buf_out);
				write (v_buf_out, string'(">>>> Expected: ") );
				hwrite (v_buf_out, expecteddata);
				writeline(output, v_buf_out);
				write (v_buf_out, string'(">>>> Expected: ") );
				hwrite (v_buf_out, expecteddata);
				writeline(logfile_ptr, v_buf_out);
				write (v_buf_out, string'(">>>> Actual  : ") );
				hwrite (v_buf_out, rdata);
				writeline (output, v_buf_out);
				write (v_buf_out, string'(">>>> Actual  : ") );
				hwrite (v_buf_out, rdata);
				writeline (logfile_ptr, v_buf_out);
			end if;
		end if;			
		exit when (rvalid='1'); 
	end loop;
	rready<='0';

end procedure ReadData;

------------------------------------------------------------------
--- Procedure ReadDataMask: this function reads at address and check if
--- read data is equal to the masked expecteddata 
------------------------------------------------------------------
procedure ReadDataMask (
     signal  aclk   : in  std_logic;
     signal  araddr : out  std_logic_vector (31 downto 0);
	  signal  arvalid  : out	std_logic;
	  signal  rvalid  : in	std_logic;
     signal  arready : in	std_logic;
     signal  rready : out	std_logic;
	  signal  rdata : in std_logic_vector (31 downto 0);
	  
     address      : in string(1 to 8);
     offset       : in integer;  
     expecteddata  : in std_logic_vector(31 downto 0);
     mask         : in std_logic_vector(31 downto 0);
     timeout_readings  : in integer
	  ) is
  variable v_buf_out: line;
  variable v_masked : std_logic_vector(31 downto 0);
  variable read_ok : std_logic;
  variable k : natural := 0;
  variable address_accessed : REGISTER_TYPE;
  begin
--	write (v_buf_out, string'(">>>> Procedure ReadData at ") );
--	write (v_buf_out, now);
--	writeline (output, v_buf_out);
--	write (v_buf_out, string'(">>>> Procedure ReadData at ") );
--	write (v_buf_out, now);
--	writeline (logfile_ptr, v_buf_out);
   read_ok := '0';
   loop
    k:=k+1;
	wait until (aclk'event and aclk='1');
    address_accessed := ParseReg(address, offset) ;
	araddr   <= address_accessed.register_address;
	arvalid	<= '1';
	rready	<= '1';
	loop 
		wait until (aclk'event and aclk='1');
		exit when (arready='1'); 
	end loop;
	arvalid	<= '0';
		wait until (aclk'event and aclk='1');
		if (rvalid='1') then
			-- read data
            for i in 0 to 31 LOOP
               v_masked(i):= rdata(i) and mask(i);
            end LOOP;

			if (v_masked=expecteddata) then 
				write (v_buf_out, string'(">>>> Trigger'ed at ") );
				write (v_buf_out, now);
				write (v_buf_out, string'(" Addr: ") );
				write (v_buf_out, address);
				write (v_buf_out, string'(" Expected: ") );
				hwrite (v_buf_out, expecteddata);
				write (v_buf_out, string'(" Actual  : ") );
				hwrite (v_buf_out, rdata);
				write (v_buf_out, string'(" Mask  : ") );
				hwrite (v_buf_out, mask);
				writeline (output, v_buf_out);

				write (v_buf_out, string'(">>>> Trigger'ed at ") );
				write (v_buf_out, now);
				write (v_buf_out, string'(" Addr: ") );
				write (v_buf_out, address);
				write (v_buf_out, string'(" Expected: ") );
				hwrite (v_buf_out, expecteddata);
				write (v_buf_out, string'(" Actual  : ") );
				hwrite (v_buf_out, rdata);
				write (v_buf_out, string'(" Mask  : ") );
				hwrite (v_buf_out, mask);
				writeline (logfile_ptr, v_buf_out);
                
                read_ok:='1';
			end if;
		end if;			
    rready<='0';
	exit when ((read_ok='1') or (k=timeout_readings)); 
   end loop;

   if ((k=timeout_readings) and (read_ok='0')) then
        write (v_buf_out, string'(">>>> TimeOut expired ") );
        write (v_buf_out, now);
        write (v_buf_out, string'(" Addr: ") );
        write (v_buf_out, address);
        writeline (output, v_buf_out);
        
        write (v_buf_out, string'(">>>> TimeOut expired ") );
        write (v_buf_out, now);
        write (v_buf_out, string'(" Addr: ") );
        write (v_buf_out, address);
        writeline (logfile_ptr, v_buf_out);
   end if;

end procedure ReadDataMask;

------------------------------------------------------------------
--- Procedure ReadValue: this function reads at address 
------------------------------------------------------------------
procedure ReadValue (
     signal  aclk   : in  std_logic;
     signal  araddr : out  std_logic_vector (31 downto 0);
	  signal  arvalid  : out	std_logic;
	  signal  rvalid  : in	std_logic;
     signal  arready : in	std_logic;
     signal  rready : out	std_logic;
	  signal  rdata : in std_logic_vector (31 downto 0);
	  
     address      : in string(1 to 8);
     offset       : in integer
	  ) is
  variable v_buf_out: line;
  variable address_accessed : REGISTER_TYPE;
  variable dataread : std_logic_vector (31 downto 0);

  begin
	wait until (aclk'event and aclk='1');
    address_accessed := ParseReg(address, offset) ;
	araddr   <= address_accessed.register_address;
	arvalid	<= '1';
	rready	<= '1';
	loop 
		wait until (aclk'event and aclk='1');
		exit when (arready='1'); 
	end loop;
	arvalid	<= '0';
	loop
        wait until (aclk'event and aclk='1');
		if (rvalid='1') then
			-- read data
			write (v_buf_out, string'(" ReadData at ") );
			write (v_buf_out, now);
			write (v_buf_out, string'(" Address: "));
			write (v_buf_out, address);
            dataread := rdata;
            if (address_accessed.register_list=3) then
    	        write (v_buf_out, string'(" Camera "));
            end if;
            if (address_accessed.register_list=2) then
			    write (v_buf_out, string'(" TIME STAMP "));
            end if;
			write (v_buf_out, string'(" Data: "));
			hwrite (v_buf_out, dataread);
			writeline (output, v_buf_out);

			write (v_buf_out, string'(" ReadData at ") );
			write (v_buf_out, now);
			write (v_buf_out, string'(" Address: "));
			write (v_buf_out, address);
            dataread := rdata ;
            if (address_accessed.register_list=3) then
		        write (v_buf_out, string'(" Camera "));
            end if;
            if (address_accessed.register_list=2) then
			    write (v_buf_out, string'(" TIME STAMP "));
            end if;
			write (v_buf_out, string'(" Data: "));
			hwrite (v_buf_out, dataread);
			writeline (logfile_ptr, v_buf_out);
            
            exit;
		end if;			
	end loop;
	rready<='0';
    wait until (aclk'event and aclk='1');
end procedure ReadValue;
------------------------------------------------------------------
--- Procedure Reset: this function enable the Async_reset 
------------------------------------------------------------------
procedure Reset(
     signal  aclk   : in  std_logic;
     signal  Async_reset : out	std_logic
	  ) is
  variable v_buf_out: line;
  begin
    Async_reset<='1';
    wait until (aclk'event and aclk='1');
    wait until (aclk'event and aclk='0'); 
    Async_reset<='0';

	write (v_buf_out, string'(">>>> ASync reset detected at ") );
	write (v_buf_out, now);
	writeline (output, v_buf_out);

	write (v_buf_out, string'(">>>> ASync reset detected at ") );
	write (v_buf_out, now);
	writeline (logfile_ptr, v_buf_out);
    

end procedure Reset;
------------------------------------------------------------------
--- Procedure WaitInterrupt: this function waits the interrupt 
------------------------------------------------------------------
procedure WaitInterrupt (
     signal  aclk   : in  std_logic;
     signal  interrupt : in	std_logic
	  ) is
  variable v_buf_out: line;

  begin

	loop 
		wait until (aclk'event and aclk='1');
		exit when (interrupt='1'); 
	end loop;

	-- Interrupt
	write (v_buf_out, string'(">>>> Interrupt detected at ") );
	write (v_buf_out, now);
	writeline (output, v_buf_out);

	write (v_buf_out, string'(">>>> Interrupt detected at ") );
	write (v_buf_out, now);
	writeline (logfile_ptr, v_buf_out);
end procedure WaitInterrupt;




------------------------------------------------------------------
--- Procedure RandomizeTimeSignalAssertion
------------------------------------------------------------------
procedure  RandomizeTimeSignalAssertionHigh(
	signal  aclk  : in std_logic;
	signal  sigtodrive : out std_logic;
	signal  norandom : in std_logic;
	signal Seed_1 : inout positive;
	signal Seed_2 : inout positive) is
   
	variable v_buf_out: line;
	variable seed1, seed2 : positive;
	variable rand:real;
	variable int_rand: integer;

begin


	if (norandom='1') then
		int_rand:=0;
    else
		--seed1 :=positive(now/(1 ns));
		seed1:=Seed_1; seed2:=Seed_2;
		Seed_1<=Seed_1+1; Seed_2<=Seed_2+1;
		uniform(seed1, seed2, rand);
        int_rand:= 100*integer(trunc(rand*15.0));
	end if;
	
	if (int_rand>0) then
		for i in 0 to int_rand loop
			wait until (aclk'event and aclk='1');
		end loop;
	end if;
	sigtodrive <= '1';
end procedure RandomizeTimeSignalAssertionHigh;

procedure  RandomizeTimeSignalAssertionLowAndHighAgain(
	signal  aclk  : in std_logic;
	signal  sigtodrive : out std_logic;
	signal  norandom : in std_logic;
	signal Seed_1 : inout positive;
	signal Seed_2 : inout positive) is
   
	variable v_buf_out: line;
	variable seed1, seed2 : positive;
	variable rand:real;
	variable int_rand: integer;

begin
	if (norandom='1') then
		int_rand:=0;
    else
		--seed2 :=positive(now/(1 ps));
		--seed1 :=positive(seed2);
		seed1:=Seed_1; seed2:=Seed_2;
		Seed_1<=Seed_1+1; Seed_2<=Seed_2+1;
		uniform(seed1, seed2, rand);
        int_rand:= 100*integer(trunc(rand*4.0));
	end if;

	sigtodrive <= '0';

	if (int_rand>0) then
		for i in 0 to int_rand loop
			wait until (aclk'event and aclk='1');
		end loop;
	end if;
	sigtodrive <= '1';
end procedure RandomizeTimeSignalAssertionLowAndHighAgain;

------------------------------------------------------------------
--- Procedure WriteMasterData: this function writes at address the data 
------------------------------------------------------------------
procedure WriteMasterData (
     signal  aclk   : in  std_logic;
     signal  awaddr : in  std_logic_vector (31 downto 0);
	  signal  awvalid  : in	std_logic;
	  signal  wvalid  : in	std_logic;
     signal  bready : in	std_logic;
     signal  wdata   : in	std_logic_vector (31 downto 0); 
     signal  awready : out std_logic;
     signal  wready : out std_logic;
	  signal  bvalid : out std_logic;
      signal wlast : in std_logic;
      signal norandom : in std_logic--;
      --signal Seed_1 : inout positive;
      --signal Seed_2 : inout positive
	  ) is
  variable v_buf_out: line;
  
  variable Datawritten : std_logic_vector (31 downto 0);
  variable v_awaddr : std_logic_vector (31 downto 0);

  variable okwriting : time ;
  
  variable seed1, seed2: positive;
  variable rand: real;
  variable int_rand: integer;
  
    
  begin
    awready	<= '0';
    bvalid <='0';
    loop

    	wait until (aclk'event and aclk='1');
		-- RandomizeTimeSignalAssertionHigh(aclk, awready, norandom, Seed_1, Seed_2);
		-- 
		if (norandom='1') then
			int_rand:=0;
		else
			uniform(seed1, seed2, rand);
			int_rand:= 100*integer(trunc(rand*10.0));
		end if;
		if (int_rand>0) then
			for i in 0 to int_rand loop
				wait until (aclk'event and aclk='1');
			end loop;
		end if;
		awready <= '1';
		-- -------------------------------------------------------------
		
    	wait until (aclk'event and aclk='1');       
		if (awvalid='1') then
			v_awaddr := awaddr;
			okwriting := now;
			awready	<= '0';
			wait until (aclk'event and aclk='1');
    	else
			loop
				wait until (aclk'event and aclk='1');
				v_awaddr := awaddr;
				okwriting := now;
				exit when (awvalid='1'); 
			end loop;
		end if;
		awready	<= '0';
		
		write (v_buf_out, string'("Starting writing address at "));
		write (v_buf_out, okwriting);
		write (v_buf_out, string'(" from: "));
		hwrite (v_buf_out, v_awaddr);
		writeline (output, v_buf_out);

		write (v_buf_out, string'("Starting writing address at "));
		write (v_buf_out, okwriting);
		write (v_buf_out, string'(" from: "));
		hwrite (v_buf_out, v_awaddr);
		writeline (logfile_ptr, v_buf_out);
		
		--RandomizeTimeSignalAssertionHigh(aclk, wready, norandom, Seed_1, Seed_2);
		-- 
		if (norandom='1') then
			int_rand:=0;
		else
			uniform(seed1, seed2, rand);
			int_rand:= 100*integer(trunc(rand*4.0));
		end if;
		if (int_rand>0) then
			for i in 0 to int_rand loop
				wait until (aclk'event and aclk='1');
			end loop;
		end if;
		wready <= '1';
		-- -------------------------------------------------------------
		
		wait until (aclk'event and aclk='1');
		loop       
			if (wvalid='1') then
				-- Write data
				datawritten := wdata;
				okwriting := now;
			else
				loop
					wait until (aclk'event and aclk='1');
					datawritten := wdata;
					okwriting := now;
					exit when (awvalid='1'); 
				end loop;
			end if;
			write (v_buf_out, string'(" Data: "));
			hwrite (v_buf_out, datawritten);
			write (v_buf_out, string'(" at "));
			write (v_buf_out, okwriting);
			writeline (output, v_buf_out);
		
			write (v_buf_out, string'(" Data: "));
			hwrite (v_buf_out, datawritten);
			write (v_buf_out, string'(" at "));
			write (v_buf_out, okwriting);
			writeline (logfile_ptr, v_buf_out);
			exit when (wlast='1');
			-- RandomizeTimeSignalAssertionLowAndHighAgain(aclk, wready, norandom, Seed_1, Seed_2);
			--
			if (norandom='1') then
				int_rand:=0;
			else
				uniform(seed1, seed2, rand);
				int_rand:= 100*integer(trunc(rand*4.0));
			end if;
			wready <= '0';
			if (int_rand>0) then
				for i in 0 to int_rand loop
					wait until (aclk'event and aclk='1');
				end loop;
			end if;
			wready <= '1';
			-- ---------------------------------------------------------
			wait until (aclk'event and aclk='1');
		end loop;
		wready	<= '0';
        wait until (aclk'event and aclk='1');
		-- RandomizeTimeSignalAssertionHigh(aclk, bvalid, norandom, Seed_1, Seed_2);
 		-- 
		if (norandom='1') then
			int_rand:=0;
		else
			uniform(seed1, seed2, rand);
			int_rand:= 100*integer(trunc(rand*4.0));
		end if;
		if (int_rand>0) then
			for i in 0 to int_rand loop
				wait until (aclk'event and aclk='1');
			end loop;
		end if;
		bvalid <= '1';
		-- -------------------------------------------------------------
        loop
            exit when (bready='1');
            wait until (aclk'event and aclk='1');
        end loop;
		bvalid<='0';  
    end loop; -- infinite loop
    
end procedure WriteMasterData;

-- ------------------------------------------------------------------
-- --- Procedure Voltage: Set Voltages coming from ADC
-- ------------------------------------------------------------------
-- procedure Voltage (
--      signal  	 aclk 	: in  std_logic;
--      constant  	 Voltage: in  t_VOLT;
--      signal  	 out_val: out t_ADC_array(NUM_OF_RECEIVER-1 downto 0)
-- 	  ) is
--   variable v_buf_out: line;
--   variable Voltage_v : ufixed(SPI_ADC_RES-1 downto 0);
--   variable Volt_i : t_Voltage_real_array(63 downto 0);
--   
--   begin  
--     for i in 0 to Voltage.num-1 loop
--         Volt_i(i) := 4095.0*(Voltage.val(i))/3.3;
--     end loop;
-- 
-- 	wait until (aclk'event and aclk='1');
--     for i in 0 to NUM_OF_RECEIVER-1 loop
--         if (i>Voltage.num) then
--             out_val(i) <= (others =>'0');
--         else
--             out_val(i) <= std_logic_vector(to_unsigned(integer(Volt_i(i)),SPI_ADC_RES));
--         end if;
--     end loop;
-- 
-- end procedure Voltage;

------------------------------------------------------------------
--- Procedure StartDMA: this procedure start the DMA
------------------------------------------------------------------
procedure StartDMA (
     signal  aclk   : in  std_logic;
   constant  type_of_dma  : in  natural;
     signal  startdma : out  std_logic
    ) is
   variable v_buf_out: line;
begin
    wait until (aclk'event and aclk='1');
    if (type_of_dma=0) then
        write (v_buf_out, now);
        write (v_buf_out, string'(" DMA Write one shot ") );
        writeline (output, v_buf_out);
        startdma<= '1';
        wait until (aclk'event and aclk='1');
        startdma<= '0';
    else
        write (v_buf_out, now);
        write (v_buf_out, string'(" DMA Write cyclic ") );
        writeline (output, v_buf_out);
        startdma<= '1';
    end if;
end procedure StartDMA;

------------------------------------------------------------------
--- Procedure OverCurrent: this procedure start the DMA
------------------------------------------------------------------
procedure OverCurrent (
     signal  aclk   : in  std_logic;
     constant  wait_num_clk : in natural;
     signal  ocp : out  std_logic
    ) is
   variable v_buf_out: line;
begin
  ocp <= '1';
  for i in 1 to wait_num_clk loop
    wait until (aclk'event and aclk='1');
  end loop;
  ocp <= '0';
end procedure OverCurrent;

------------------------------------------------------------------
--- Procedure ExternalFault: this procedure start the DMA
------------------------------------------------------------------
procedure ExternalFault (
     signal  aclk   : in  std_logic;
     constant  wait_num_clk : in natural;
     signal  ext_fault : out  std_logic
    ) is
   variable v_buf_out: line;
begin
  ext_fault <= '1';
  for i in 1 to wait_num_clk loop
    wait until (aclk'event and aclk='1');
  end loop;
  ext_fault <= '0';
end procedure ExternalFault;
   
signal dbg1, dbg2, dbg3 : std_logic;
signal norandom : std_logic;
signal seed1, seed2 : positive;

begin

RANDOM_ACT: if NORANDOM_DMA=0 generate
norandom <= '0';
end generate RANDOM_ACT;

NORANDOM_ACT: if NORANDOM_DMA=1 generate
norandom <= '1';
end generate NORANDOM_ACT;

--------------------------------------------------
-- Command File FSM
--------------------------------------------------
p_cmd_fsm: process

    variable v_access           : OP_ENTRY;
    variable v_eof              : std_logic;
    variable v_buf_out          : line;

begin
	S_AXI_AWVALID <= '0';
    S_AXI_WVALID  <= '0';
    S_AXI_WDATA   <= (others => '0');
	S_AXI_WSTRB   <= "1111";
    S_AXI_BREADY  <= '0';
    S_AXI_ARVALID <= '0';
    S_AXI_ARADDR  <= (others => '0');
	S_AXI_RREADY  <= '0';
	S_AXI_AWADDR  <= (others => '0');
    M_Axis_TREADY <= '0';
    S_AXIS_TDATA  <= (others => '0');
    S_AXIS_TLAST  <= '0';
    S_AXIS_TVALID <= '0';
    start_dmas    <= '0';
    ocp_o <= '0';
    ext_fault_o <= '0';
    
   wait until (start'event and start ='1');

   v_eof := '0';
   --- Start simulation ---
   write (v_buf_out, string'(">>>> Start simulation at ") );
	write (v_buf_out, now);
	writeline (output, v_buf_out);
   write (v_buf_out, string'(">>>> Start simulation at ") );
	write (v_buf_out, now);
	writeline (logfile_ptr, v_buf_out);

   loop
      read_cmd_file(cmdfile_ptr, v_access, v_eof);
      exit when (v_eof='1');
      case (v_access.OPCODE) is
            when WRD => WriteData(S_AXI_ACLK, S_AXI_AWADDR, S_AXI_AWVALID, S_AXI_WVALID, S_AXI_BREADY, S_AXI_WDATA, S_AXI_AWREADY, S_AXI_WREADY,  S_AXI_BVALID, v_access.REG, v_access.DATA, v_access.regoffset);
            when RDD => ReadData(S_AXI_ACLK, S_AXI_ARADDR, S_AXI_ARVALID, S_AXI_RVALID, S_AXI_ARREADY, S_AXI_RREADY, S_AXI_RDATA, v_access.REG, v_access.regoffset, v_access.DATA);
            when RDM => ReadDataMask(S_AXI_ACLK, S_AXI_ARADDR, S_AXI_ARVALID, S_AXI_RVALID, S_AXI_ARREADY, S_AXI_RREADY, S_AXI_RDATA, v_access.REG, v_access.regoffset, v_access.DATA, v_access.MASK, v_access.NUMREAD);
            when PRT => PrintMsg(v_access.MESSAGE);
            when WAT => WaitNClockCycles(S_AXI_ACLK,v_access.CLOCK_NUM);
            when RDV => ReadValue(S_AXI_ACLK, S_AXI_ARADDR, S_AXI_ARVALID, S_AXI_RVALID, S_AXI_ARREADY, S_AXI_RREADY, S_AXI_RDATA, v_access.REG, v_access.regoffset);
            when WIN => WaitInterrupt(S_AXI_ACLK, interrupt);
            when FIN => FinishSimulation(S_AXI_ACLK);
--			when CUR => Voltage(S_AXI_ACLK,v_access.Voltage,adc_val);
            --when DMR => DMARead_old(S_AXI_ACLK,v_access.DMALENGTH,v_access.RPTBURST,M_Axis_TVALID,M_Axis_TLAST,M_Axis_TDATA,M_Axis_TREADY);
            when DMR => DMARead(S_AXI_ACLK,v_access.RPTBURST,M_Axis_TVALID,M_Axis_TLAST,M_Axis_TDATA,M_Axis_TREADY);
            when DMW => DMAWrite(S_AXI_ACLK,v_access.DMALENGTH,v_access.DMADATA,v_access.RPTBURST,S_Axis_TVALID,S_Axis_TLAST,S_Axis_TDATA,S_Axis_TREADY);
--            when RST => Reset(S_AXI_ACLK,Async_reset);
            when SDM => StartDMA(S_AXI_ACLK,v_access.ENABLEDMA,start_dmas);
            when OCP => OverCurrent(S_AXI_ACLK,v_access.ocp,ocp_o);
            when EXF => ExternalFault(S_AXI_ACLK,v_access.ext_fault,ext_fault_o);
            when others => null;
      end case;
   end loop;
   FinishSimulation(S_AXI_ACLK);
   
end process p_cmd_fsm;

p_master_axi: process

    variable v_access           : OP_ENTRY;
    variable v_eof              : std_logic;
    variable v_buf_out          : line;
    variable INITIAL          : positive;

begin
			INITIAL  := 8192;
           M_AXI_AWREADY  <= '0'; 
           M_AXI_WREADY   <= '0'; 
           M_AXI_BRESP    <= "00"; 
           M_AXI_BVALID   <= '0'; 
           norandom       <= '0';
           seed1 <= INITIAL;
           seed2 <= INITIAL*2;
   wait until (start'event and start ='1');
 			write (v_buf_out, string'("ini seed1: "));
			write (v_buf_out, seed1);
			write (v_buf_out, string'(" ini seed2: "));
			write (v_buf_out, seed2);
			writeline (logfile_ptr, v_buf_out);
  
   wait until (S_AXI_ACLK'event and S_AXI_ACLK='1');
   
   loop
        WriteMasterData(M_AXI_ACLK, M_AXI_AWADDR, M_AXI_AWVALID, M_AXI_WVALID, M_AXI_BREADY, M_AXI_WDATA, M_AXI_AWREADY, M_AXI_WREADY, M_AXI_BVALID, M_AXI_WLAST, norandom); --, seed1, seed2);
   end loop;
   
end process p_master_axi;

end Behavioral;

