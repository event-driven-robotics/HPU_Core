// ------------------------------------------------------------------------------ 
//  Project Name        : 
//  Design Name         : 
//  Starting date:      : 
//  Target Devices      : 
//  Tool versions       : 
//  Project Description : 
// ------------------------------------------------------------------------------
//  Company             : IIT - Italian Institute of Technology  
//  Engineer            : Maurizio Casti
// ------------------------------------------------------------------------------ 
// ==============================================================================
//  PRESENT REVISION
// ==============================================================================
//  File        : AER_Device_Emulator.v
//  Revision    : 1.0
//  Author      : M. Casti
//  Date        : 
// ------------------------------------------------------------------------------
//  Description : SpiNNaker emulator for AER Device operations
//     
// ==============================================================================
//  Revision history :
// ==============================================================================
// 
//  Revision 1.0:  07/16/2018
//  - Initial revision
//  (M. Casti - IIT)
// 
// ------------------------------------------------------------------------------

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ---------------------------- SpiNNaker emulator ------------------------------
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps


module AER_Device_Emulator (

  // AER Device asynchronous output interface
  output reg  [23:0] AERout,
  output reg         AERoutReq,
  input  wire        AERoutAck,

  // AER Device asynchronous input interface
  input  wire [23:0] AERin,
  input  wire        AERinReq,
  output reg         AERinAck,
  
  // Control interface
  input wire 		 enable,
  input wire 		 rst
  );

//	********************************************************  
//	VHDL Compnent Declaration  
//	********************************************************  
//	component AER_Device_Emulator 
//		port (
//	
//			-- AER Device asynchronous output interface
//			AERout		: out std_logic_vector(15 downto 0);
//			AERoutReq	: out std_logic;
//			AERoutAck	: in std_logic;
//	
//			-- AER Device asynchronous input interface
//			AERin		: in std_logic_vector(15 downto 0);
//			AERinReq    : in std_logic;
//			AERinAck    : out std_logic;
//	
//			-- Control interface
//			rst			: in std_logic
//	); 
//	********************************************************

// Constants
localparam AER_HSDLY = 100;
  
//--------------------------------------------------
// Drive the output AER interface
//--------------------------------------------------
initial
begin
  AERout = 0;
  AERoutReq  = 1'b0;               // active HIGH!

  wait (rst);
  wait (!rst);
  
  # 1000;

  forever
  begin
	if (enable) begin
		# 10 AERoutReq = 1'b1;

		wait (AERoutAck);
		# 10 AERoutReq = 1'b0;

		wait (!AERoutAck);

		AERout = AERout + 1;
	
		# AER_HSDLY;
	end
	else begin
		# 10;
	end
  end
end
//--------------------------------------------------

//--------------------------------------------------
// Listening to the input AER interface
//--------------------------------------------------
initial
begin
  AERinAck = 1'b0;  // active HIGH!

  wait (rst);
  wait (!rst);

  forever
  begin
    wait (AERinReq);  // active HIGH
    # AER_HSDLY
      AERinAck = 1'b1;

    wait (!AERinReq);
    # AER_HSDLY
      AERinAck = 1'b0;
  end
end
//--------------------------------------------------

endmodule
