`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    16:01:13 10/16/2014 
// Design Name: 
// Module Name:    p2t 
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
module p2t( output reg yt, input ap, clk, _rst);

	always @( posedge clk, negedge _rst) begin
		if( !_rst)
			yt <= 0;
		else
			//yt <= ap ? ~yt : yt;
			yt <= ap ^yt;
	end

endmodule

module p2t_r #( parameter size=8) ( output reg[size-1:0] yd, output reg yt, input[size-1:0] ad, input ap, clk, _rst);

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			yt <= 0;
			yd <= 0;
		end
		else begin
			yt <= ap ? ~yt : yt;
			yd <= ap ? ad : yd;
		end
	end

endmodule

module t2p( output yp, input at, clk, _rst);

	reg p_at, pp_at;

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			p_at <= 0;
			pp_at <= 0;
		end
		else begin
			p_at <= at;
			pp_at <= p_at;
		end
	end

	assign yp = pp_at ^p_at;

endmodule

module t2p_r #( parameter size=8) ( output reg[size-1:0] yd, output reg yp, output yt, input[size-1:0] ad, input at, clk, _rst);

	reg p_at;
	reg pp_at;
	reg[size-1:0] p_ad;

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			p_at <= 0;
			pp_at <= 0;
			p_ad <= 0;
		end
		else begin
			p_at <= at;
			pp_at <= p_at;
			p_ad <= ad;
		end
	end

	wire yp_int = pp_at ^p_at;

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			yd <= 0;
			yp <= 0;
		end
		else begin
			yp <= yp_int;
			yd <= yp_int ? p_ad: yd;
		end
	end
	
	assign yt = p_at;

endmodule

module t2p_ddr_r #( parameter size=8) ( output reg[size-1:0] yd, output reg yp, output yt, input[size-1:0] ad, input at, clkp, clkn, _rst);

	reg p_at, n_at, pn_at;
	reg pp_at;
	reg[size-1:0] p_ad, n_ad, pn_ad;

	always @( posedge clkp, negedge _rst) begin
		if( !_rst) begin
			p_at <= 0;
			pp_at <= 0;
			p_ad <= 0;
			pn_at <= 0;
			pn_ad <= 0;
		end
		else begin
			p_at <= at;
			pp_at <= p_at;
			p_ad <= ad;
			pn_at <= n_at;
			pn_ad <= n_ad;
		end
	end

	always @( posedge clkn, negedge _rst) begin
		if( !_rst) begin
			n_at <= 0;
			n_ad <= 0;
		end
		else begin
			n_at <= at;
			n_ad <= ad;
		end
	end

	wire yp_int1 = pp_at ^pn_at;
	wire yp_int2 = pn_at ^p_at;
	wire yp_int = yp_int1 || yp_int2;

	always @( posedge clkp, negedge _rst) begin
		if( !_rst) begin
			yd <= 0;
			yp <= 0;
		end
		else begin
			yp <= yp_int;
			yd <= yp_int1 ? pn_ad: (yp_int2? p_ad : yd); 
		end
	end
	
	assign yt = n_at;
	//assign yt = (n_at & clkn) | (p_at & clkp);

endmodule


// vim: ai ts=4:
