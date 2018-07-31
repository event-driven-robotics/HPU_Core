`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    17:02:24 10/16/2014 
// Design Name: 
// Module Name:    sdly 
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
module sdly #(parameter size=1) ( output y, input a, clk, _rst);

	generate
		case( size)
			0:
				assign y = a;
			1: begin
				reg old;
				always @( posedge clk, negedge _rst) begin
					if( !_rst)
						old <= 0;
					else
						old <= a;
				end
				assign y = old;
			end
			default: begin
				reg[size-1:0] old;
				always @( posedge clk, negedge _rst) begin
					if( !_rst)
						old <= 0;
					else
						old <= {old[size-2:1],a};
				end
				assign y = old[size-1];
			end
		endcase
	endgenerate

endmodule

// vim: ai ts=4:
