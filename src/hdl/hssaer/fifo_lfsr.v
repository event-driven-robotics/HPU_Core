`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    09:57:31 11/07/2014 
// Design Name: 
// Module Name:    fifo_lfsr 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fifo_lfsr #( parameter dsize = 8) ( output reg[dsize-1:0] y, output reg full, /*empty,*/ _empty, input[dsize-1:0] a, input wr, rd, clk, _rst);


	reg[dsize-1:0] ram[3:0];
	reg[1:0] wp, rp;
	wire[1:0] wp_n = {wp[1] ^wp[0], wp[1]};
	wire[1:0] rp_n = {rp[1] ^rp[0], rp[1]};
	localparam p_init = 2'b01;

	/*
	reg[dsize-1:0] ram[7:0];
	reg[2:0] wp, rp;
	wire[2:0] wp_n = {wp[2] ^wp[1], wp[0], wp[2]};
	wire[2:0] rp_n = {rp[2] ^rp[1], rp[0], rp[2]};
	localparam p_init = 3'b001;
	*/
	/*
	reg[dsize-1:0] ram[15:0];
	reg[3:0] wp, rp;
	wire[3:0] wp_n = {wp[2:1],  wp[3]^wp[0], wp[3]};
	wire[3:0] rp_n = {rp[2:1],  rp[3]^rp[0], rp[3]};
	localparam p_init = 4'b0001;
	*/

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			wp <= p_init;
			rp <= p_init;
			full <= 0;
			//empty <= 1;
			_empty <= 0;
			y <= 0;
		end
		else begin
			if( wr) begin
				ram[wp] <= a;
				wp <= wp_n;
			end
			if( rd) begin
				y <= ram[rp];
				rp <= rp_n;
			end
			case( {wr, rd})
				2'b01: begin
					full <= 0;
					//empty <= wp == rp_n;
					_empty <= wp != rp_n;
				end
				2'b10: begin
					//empty <= 0;
					_empty <= 1;
					full <= rp == wp_n;
				end
				2'b11: begin
				end
			endcase
		end
	end

endmodule

// vim: ai ts=4 :
