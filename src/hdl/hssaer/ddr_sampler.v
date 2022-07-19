`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    15:16:15 10/06/2014 
// Design Name: 
// Module Name:    ddr_sampler 
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

`define DEBUG

module ddr_sampler #( parameter sync_s=4) ( output reg q0, q1, input din, clkp, clkn, _rst);
	
	reg[sync_s-1:0] din0, din1;

	always @( posedge clkn, negedge _rst) begin
		if( !_rst) begin
			din1 <= 0;
		end
		else begin
			din1 <= { din1[sync_s-2:0], din};
		end
	end

	always @( posedge clkp, negedge _rst) begin
		if( !_rst) begin
			din0 <= 0;
		end
		else begin
			din0 <= { din0[sync_s-2:0], din};
		end
	end

	always @( posedge clkp, negedge _rst) begin
		if( !_rst) begin
			q0 <= 0;
			q1 <= 0;
		end
		else begin
			q0 <= din0[sync_s-2];
			q1 <= din1[sync_s-1];
		end
	end

endmodule

// vim: ai ts=4:
