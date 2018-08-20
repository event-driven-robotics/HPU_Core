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
//  File        : SpiNNaker_Emulator.v
//  Revision    : 1.0
//  Author      : M. Casti
//  Date        : 
// ------------------------------------------------------------------------------
//  Description : SpiNNaker emulator for SpiNNlink operations
//     
// ==============================================================================
//  Revision history :
// ==============================================================================
// 
//  Revision 1.0:  07/13/2018
//  - Initial revision
//  (M. Casti - IIT)
// 
// ------------------------------------------------------------------------------

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ---------------------------- SpiNNaker emulator ------------------------------
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps


module SpiNNaker_Emulator #
 (
   parameter HAS_ID = "false",
   parameter ID     = 0
  ) 
 ( 
  // SpiNNaker link asynchronous output interface
  output reg  [6:0] Lout,
  input wire        LoutAck,
  
  // SpiNNaker link asynchronous input interface
  input  wire [6:0] Lin,
  output reg        LinAck,
  
  // Control interface
  input wire 		rst
  );

// ********************************************************  
// VHDL Compnent Declaration  
// ********************************************************  
// component SpiNNaker_Emulator 
//      generic (
//          HAS_ID       : string;
//          ID           : natural
//          ); 
// 		port (
// 		
//   		-- SpiNNaker link asynchronous output interface
//   		Lout         : out std_logic_vector(6 downto 0);
//   		LoutAck      : in std_logic;
//   		
//   		-- SpiNNaker link asynchronous input interface
//   		Lin          : in std_logic_vector(6 downto 0);
//   		LinAck       : out std_logic;
//   		
//   		-- Control interface
//   		rst          : in std_logic
//   		);
// end component ;
// ********************************************************  

// Constants
localparam SPL_HSDLY = 8;


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//--------------------------- functions -------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//---------------------------------------------------------------
// NRZ 2-of-7 EOP Detection
//---------------------------------------------------------------
function [3:0] eop_nrz_2of7 ;
  input [6:0] data;
  input [6:0] data_r;

  case (data ^ data_r)
    7'b1100000:   // eop
                eop_nrz_2of7 = 1;
    default:    eop_nrz_2of7 = 0;
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// NRZ 2-of-7 Decoder
//---------------------------------------------------------------
function [3:0] decode_nrz_2of7 ;
  input [6:0] data;
  input [6:0] Lin_r;

  case (data ^ Lin_r)
    7'b0010001: decode_nrz_2of7 = 0;    // 0
    7'b0010010: decode_nrz_2of7 = 1;    // 1
    7'b0010100: decode_nrz_2of7 = 2;    // 2
    7'b0011000: decode_nrz_2of7 = 3;    // 3
    7'b0100001: decode_nrz_2of7 = 4;    // 4
    7'b0100010: decode_nrz_2of7 = 5;    // 5
    7'b0100100: decode_nrz_2of7 = 6;    // 6
    7'b0101000: decode_nrz_2of7 = 7;    // 7
    7'b1000001: decode_nrz_2of7 = 8;    // 8
    7'b1000010: decode_nrz_2of7 = 9;    // 9
    7'b1000100: decode_nrz_2of7 = 10;   // 10
    7'b1001000: decode_nrz_2of7 = 11;   // 11
    7'b0000011: decode_nrz_2of7 = 12;   // 12
    7'b0000110: decode_nrz_2of7 = 13;   // 13
    7'b0001100: decode_nrz_2of7 = 14;   // 14
    7'b0001001: decode_nrz_2of7 = 15;   // 15
    default:    decode_nrz_2of7 = 4'hx; // eop, incomplete, oob
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// NRZ 2-of-7 Whole Decoder with EOP and ERR
//---------------------------------------------------------------
function [3:0] whole_decode_nrz_2of7 ;
  input [6:0] data;
  input [6:0] Lin_r;

  case (data ^ Lin_r)
    7'b0010001: whole_decode_nrz_2of7 = 6'b0_0_0000;    // 0
    7'b0010010: whole_decode_nrz_2of7 = 6'b0_0_0001;    // 1
    7'b0010100: whole_decode_nrz_2of7 = 6'b0_0_0010;    // 2
    7'b0011000: whole_decode_nrz_2of7 = 6'b0_0_0011;    // 3
    7'b0100001: whole_decode_nrz_2of7 = 6'b0_0_0100;    // 4
    7'b0100010: whole_decode_nrz_2of7 = 6'b0_0_0101;    // 5
    7'b0100100: whole_decode_nrz_2of7 = 6'b0_0_0110;    // 6
    7'b0101000: whole_decode_nrz_2of7 = 6'b0_0_0111;    // 7
    7'b1000001: whole_decode_nrz_2of7 = 6'b0_0_1000;    // 8
    7'b1000010: whole_decode_nrz_2of7 = 6'b0_0_1001;    // 9
    7'b1000100: whole_decode_nrz_2of7 = 6'b0_0_1010;    // 10
    7'b1001000: whole_decode_nrz_2of7 = 6'b0_0_1011;    // 11
    7'b0000011: whole_decode_nrz_2of7 = 6'b0_0_1100;    // 12
    7'b0000110: whole_decode_nrz_2of7 = 6'b0_0_1101;    // 13
    7'b0001100: whole_decode_nrz_2of7 = 6'b0_0_1110;    // 14
    7'b0001001: whole_decode_nrz_2of7 = 6'b0_0_1111;    // 15
    7'b1100000: whole_decode_nrz_2of7 = 6'b0_1_xxxx;    // EOP
    default:    whole_decode_nrz_2of7 = 6'b1_x_xxxx;    // ERROR
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// NRZ 2-of-7 Completion Detection
//---------------------------------------------------------------
function [3:0] complete_nrz_2of7 ;
  input [6:0] data;
  input [6:0] Lin_r;

  case (data ^ Lin_r)
    7'b0010001,   // 0
    7'b0010010,   // 1
    7'b0010100,   // 2
    7'b0011000,   // 3
    7'b0100001,   // 4
    7'b0100010,   // 5
    7'b0100100,   // 6
    7'b0101000,   // 7
    7'b1000001,   // 8
    7'b1000010,   // 9
    7'b1000100,   // 10
    7'b1001000,   // 11
    7'b0000011,   // 12
    7'b0000110,   // 13
    7'b0001100,   // 14
    7'b0001001,   // 15
    7'b1100000:   // eop
                complete_nrz_2of7 = 1;
    default:    complete_nrz_2of7 = 0;
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// RTZ 2-of-7 Decoder
//---------------------------------------------------------------
function [3:0] decode_2of7 ;
  input [6:0] data;

  case (data)
    7'b0010001: decode_2of7 = 0;    // 0
    7'b0010010: decode_2of7 = 1;    // 1
    7'b0010100: decode_2of7 = 2;    // 2
    7'b0011000: decode_2of7 = 3;    // 3
    7'b0100001: decode_2of7 = 4;    // 4
    7'b0100010: decode_2of7 = 5;    // 5
    7'b0100100: decode_2of7 = 6;    // 6
    7'b0101000: decode_2of7 = 7;    // 7
    7'b1000001: decode_2of7 = 8;    // 8
    7'b1000010: decode_2of7 = 9;    // 9
    7'b1000100: decode_2of7 = 10;   // 10
    7'b1001000: decode_2of7 = 11;   // 11
    7'b0000011: decode_2of7 = 12;   // 12
    7'b0000110: decode_2of7 = 13;   // 13
    7'b0001100: decode_2of7 = 14;   // 14
    7'b0001001: decode_2of7 = 15;   // 15
    default:    decode_2of7 = 4'hx; // eop, incomplete, oob
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// RTZ 2-of-7 Whole Decoder with EOP and ERR
//---------------------------------------------------------------
function [5:0] whole_decode_2of7 ;
  input [6:0] data;

  case (data)
    7'b0010001: whole_decode_2of7 = 6'b0_0_0000;    // 0
    7'b0010010: whole_decode_2of7 = 6'b0_0_0001;    // 1
    7'b0010100: whole_decode_2of7 = 6'b0_0_0010;    // 2
    7'b0011000: whole_decode_2of7 = 6'b0_0_0011;    // 3
    7'b0100001: whole_decode_2of7 = 6'b0_0_0100;    // 4
    7'b0100010: whole_decode_2of7 = 6'b0_0_0101;    // 5
    7'b0100100: whole_decode_2of7 = 6'b0_0_0110;    // 6
    7'b0101000: whole_decode_2of7 = 6'b0_0_0111;    // 7
    7'b1000001: whole_decode_2of7 = 6'b0_0_1000;    // 8
    7'b1000010: whole_decode_2of7 = 6'b0_0_1001;    // 9
    7'b1000100: whole_decode_2of7 = 6'b0_0_1010;    // 10
    7'b1001000: whole_decode_2of7 = 6'b0_0_1011;    // 11
    7'b0000011: whole_decode_2of7 = 6'b0_0_1100;    // 12
    7'b0000110: whole_decode_2of7 = 6'b0_0_1101;    // 13
    7'b0001100: whole_decode_2of7 = 6'b0_0_1110;    // 14
    7'b0001001: whole_decode_2of7 = 6'b0_0_1111;    // 15
    7'b1100000: whole_decode_2of7 = 6'b0_1_xxxx;    // EOP
    default:    whole_decode_2of7 = 6'b1_x_xxxx;    // ERROR
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// RTZ 2-of-7 Completion Detection
//---------------------------------------------------------------
function [3:0] complete_2of7 ;
  input [6:0] data;
  input [6:0] data_r;

  case (data ^ data_r)
    7'b0010001,   // 0
    7'b0010010,   // 1
    7'b0010100,   // 2
    7'b0011000,   // 3
    7'b0100001,   // 4
    7'b0100010,   // 5
    7'b0100100,   // 6
    7'b0101000,   // 7
    7'b1000001,   // 8
    7'b1000010,   // 9
    7'b1000100,   // 10
    7'b1001000,   // 11
    7'b0000011,   // 12
    7'b0000110,   // 13
    7'b0001100,   // 14
    7'b0001001,   // 15
    7'b1100000:   // eop
                complete_2of7 = 1;
    default:    complete_2of7 = 0;
  endcase
endfunction
//---------------------------------------------------------------

//---------------------------------------------------------------
// RTZ 2-of-7 Encoder
//---------------------------------------------------------------
function [6:0] encode_2of7 ;
  input [4:0] data;

  casex (data)
    5'b0_0000 : encode_2of7 = 7'b0010001; // 0
    5'b0_0001 : encode_2of7 = 7'b0010010; // 1
    5'b0_0010 : encode_2of7 = 7'b0010100; // 2
    5'b0_0011 : encode_2of7 = 7'b0011000; // 3
    5'b0_0100 : encode_2of7 = 7'b0100001; // 4
    5'b0_0101 : encode_2of7 = 7'b0100010; // 5
    5'b0_0110 : encode_2of7 = 7'b0100100; // 6
    5'b0_0111 : encode_2of7 = 7'b0101000; // 7
    5'b0_1000 : encode_2of7 = 7'b1000001; // 8
    5'b0_1001 : encode_2of7 = 7'b1000010; // 9
    5'b0_1010 : encode_2of7 = 7'b1000100; // 10
    5'b0_1011 : encode_2of7 = 7'b1001000; // 11
    5'b0_1100 : encode_2of7 = 7'b0000011; // 12
    5'b0_1101 : encode_2of7 = 7'b0000110; // 13
    5'b0_1110 : encode_2of7 = 7'b0001100; // 14
    5'b0_1111 : encode_2of7 = 7'b0001001; // 15
    5'b1_xxxx : encode_2of7 = 7'b1100000; // EOP
    default   : encode_2of7 = 7'bxxxxxxx;
  endcase
endfunction
//---------------------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


//--------------------------------------------------
// drive the output SpiNNaker interface
//--------------------------------------------------
wire [39:0] packet;
reg  [31:0] pkt_data;
reg  [3:0]  id_data;
reg  [27:0] data;
wire        parity;

reg        LoutAck_r;

assign parity = ~(^pkt_data);
assign packet = {pkt_data, 7'b0000000, parity};

integer i;

always @*
    begin
        pkt_data  = 32'h00000000;
    end
    
initial

begin
  
  if (HAS_ID == "true")  pkt_data  = {ID, 28'h0000000}; 
  if (HAS_ID == "false") pkt_data  = {32'h00000000}; 

  Lout = 0;

  wait (rst);
  wait (!rst);

  forever 
  begin
    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[3:0]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[7:4]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[11:8]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[15:12]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[19:16]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[23:20]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[27:24]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[31:28]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[35:32]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
    Lout = Lout ^ encode_2of7 ({01'b0, packet[39:36]});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    # SPL_HSDLY
      Lout = Lout ^ encode_2of7 ({01'b1, 4'b0000});

    LoutAck_r = LoutAck;
    wait (LoutAck != LoutAck_r);

    if (HAS_ID == "true")  pkt_data[27:0] = pkt_data[27:0] + 1; 
    if (HAS_ID == "false") pkt_data = pkt_data + 1;;
    

  end
end
//--------------------------------------------------

//--------------------------------------------------
// Listening to the input SpiNNaker interface
//--------------------------------------------------
reg  [6:0] Lin_r = 0;
reg [39:0] rec_packet_sr = 0;
reg  [7:0] header = 0;
reg [31:0] key = 0;
wire [3:0] rec_data;
wire       rec_eop;

assign rec_data = decode_nrz_2of7 (Lin, Lin_r);
assign rec_eop  = eop_nrz_2of7 (Lin, Lin_r);

initial
begin
  Lin_r = 0;
  LinAck = 0;

  wait (rst);
  wait (!rst);

  # SPL_HSDLY
  LinAck = 1;
  Lin_r = Lin;

  forever
  begin
    wait (complete_nrz_2of7 (Lin, Lin_r));
    # SPL_HSDLY
    if (!rec_eop) rec_packet_sr = {rec_packet_sr[35:0],rec_data};
    if (rec_eop) begin
        header = {rec_packet_sr[35:32],
                  rec_packet_sr[39:36]};
        key    = {rec_packet_sr[3:0],
                  rec_packet_sr[7:4],
                  rec_packet_sr[11:8],
                  rec_packet_sr[15:12],
                  rec_packet_sr[19:16],
                  rec_packet_sr[23:20],
                  rec_packet_sr[27:24],
                  rec_packet_sr[31:28]};
        end;
    LinAck = ~LinAck;
    Lin_r = Lin;
  end
end

//--------------------------------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule
