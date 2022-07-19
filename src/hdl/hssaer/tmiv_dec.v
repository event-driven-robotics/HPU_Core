`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    08:15:41 10/24/2014 
// Design Name: 
// Module Name:    tmiv_dec 
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
module tmiv_hssaer_dec( output reg[2:0] tvr_d, output reg tvr_st, tvr_err, input[4:0] tmiv_d, input tmiv_st, tmiv_err, clk, _rst);

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			tvr_d <= 0;
			tvr_st <= 0;
			tvr_err <= 0;
		end
		else begin
			tvr_st <= tmiv_st;
			tvr_err <= tmiv_err;
			if( tmiv_st) begin
				case( tmiv_d)
					2, 3, 4:
					//2, 3:
						tvr_d <= 0;
					5, 6, 7:
					//4, 5:
						tvr_d <= 1;
					8, 9, 10:
					//6, 7:
						tvr_d <= 2;
					11, 12, 13:
					//8, 9:
						tvr_d <= 3;
					14, 15, 16:
					//10, 11, 12:
						tvr_d <= 4;
					default:
						tvr_d <= 3'b111;
				endcase
			end
		end
	end

endmodule

// vim: ai ts=4:
