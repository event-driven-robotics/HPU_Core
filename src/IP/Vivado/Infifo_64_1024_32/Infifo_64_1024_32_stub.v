// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Wed Oct 21 15:47:36 2020
// Host        : IITICUBLAP127 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Progetti/Repository/HPU_Core/src/IP/Vivado/Infifo_64_1024_32/Infifo_64_1024_32_stub.v
// Design      : Infifo_64_1024_32
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z015clg485-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_4,Vivado 2019.1" *)
module Infifo_64_1024_32(clk, srst, din, wr_en, rd_en, dout, full, almost_full, 
  overflow, empty, almost_empty, underflow, data_count)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[63:0],wr_en,rd_en,dout[63:0],full,almost_full,overflow,empty,almost_empty,underflow,data_count[10:0]" */;
  input clk;
  input srst;
  input [63:0]din;
  input wr_en;
  input rd_en;
  output [63:0]dout;
  output full;
  output almost_full;
  output overflow;
  output empty;
  output almost_empty;
  output underflow;
  output [10:0]data_count;
endmodule
