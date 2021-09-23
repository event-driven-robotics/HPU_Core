// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
// Date        : Thu Sep 23 14:47:33 2021
// Host        : IITICUBWS052 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Projects/Repository/HPU_Core_GTP/src/IP/Vivado/OUTFIFO_32_2048_64_1024_S7/OUTFIFO_32_2048_64_1024_S7_stub.v
// Design      : OUTFIFO_32_2048_64_1024_S7
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z015clg485-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_5,Vivado 2020.1" *)
module OUTFIFO_32_2048_64_1024_S7(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  almost_full, overflow, empty, almost_empty, underflow)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[63:0],full,almost_full,overflow,empty,almost_empty,underflow" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [31:0]din;
  input wr_en;
  input rd_en;
  output [63:0]dout;
  output full;
  output almost_full;
  output overflow;
  output empty;
  output almost_empty;
  output underflow;
endmodule
