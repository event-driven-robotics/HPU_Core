`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    09:36:09 12/03/2014 
// Design Name: 
// Module Name:    hssaer_paer_trx 
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

module hssaer_paer_tx #( parameter dsize=8) ( output tx, dst_rdy, run, last, input[dsize-1:0] ae, input src_rdy, keepalive, clkp, clkn, _rst);

	reg s;
	reg[dsize-1:0] d;
	wire first;
	reg firsto;
	assign dst_rdy = ~s;

	always @( posedge clkp, negedge _rst) begin
		if( !_rst) begin
			s <= 0;
			d <= 0;
			firsto <= 0;
		end
		else begin
			firsto <= first;
			if( s) begin
				s <= ~first && firsto;
			end
			else begin
				s <= src_rdy;
				d <= ae;
			end
		end
	end

	hssaer_tx #( .dsize(dsize)) tx_impl( .tx(tx), .run(run), .first(first), .last(last), .d(d), .st(s), .keepalive(keepalive), .clkp(clkp), .clkn(clkn), ._rst(_rst));

endmodule

module hssaer_paer_rx #( parameter dsize=8) ( output reg[dsize-1:0] ae, output reg src_rdy, output err_ko, err_rx, err_to, err_of, int, run, alive, idle,
	input dst_rdy, rx, lsclkp, lsclkn, hsclkp, hsclkn, _rst, output dbg0, dbg1);

	wire st, dok;
	wire[dsize-1:0] d;
	
	assign err_ko = st && !dok;
	assign err_of = (st && dok) && src_rdy;

	always @( posedge lsclkp, negedge _rst) begin
		if( !_rst) begin
			ae <= 0;
			src_rdy <= 0;
		end
		else begin
			if( src_rdy) begin
				src_rdy <= ~dst_rdy;
			end
			else begin
				src_rdy <= st && dok;
				ae <= d;
			end
		end
	end

	hssaer_rx #( .dsize(dsize)) rx_impl( .d(d), .dok(dok), .st(st), .err(err_rx), .to_err(err_to), .int(int), .run(run), .alive(alive), .idle(idle), .rx(rx),
		.lsclkp(lsclkp), .lsclkn(lsclkn), .hsclkp(hsclkp), .hsclkn(hsclkn), ._rst(_rst), .dbg0(dbg0), .dbg1(dbg1));

endmodule

// vim: ai ts=4:
