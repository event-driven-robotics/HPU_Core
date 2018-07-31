`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    14:13:24 10/07/2014 
// Design Name: 
// Module Name:    tmiv_cnt 
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

//`define DEBUG_TMIV_CNT

module tmiv_cnt2 #(parameter sync_s=4)
	( output[4:0] cnt, output cnt_st, err_st, input evs, lsclkp, lsclkn, hsclkp, hsclkn, _rst,
	output dbg_fifo_full, dbg_st, dbg_est, dbg_fifo_rreq, dbg_xs, dbg_xa, dbg_clk, dbg_sat,
	dbg_st_s0, dbg_sat_s0, dbg_fifo_sat);

	/*
	wire clkp, clkn;
	tmiv_clk clk_gen( .CLKFX_OUT(clkp), .CLKFX180_OUT(clkn), .CLKIN_IN(clk), .RST_IN(~_rst));
	*/

	`ifdef DEBUG_TMIV_CNT
		assign dbg_clk = hsclk_p;
	`else
		assign dbg_clk = 0;
	`endif
	
	wire evs00, evs01;
	ddr_sampler #( .sync_s(sync_s)) sampler( .q0(evs00), .q1(evs01), .din(evs), .clkp(hsclkp), .clkn(hsclkn), ._rst(_rst));

	reg oldevs0;
	(* KEEP = "TRUE" *)
	reg[3:0] icnt_lfsr;
	wire[3:0] icnt_lfsr_next = { icnt_lfsr[2:1], icnt_lfsr[3]^icnt_lfsr[0], icnt_lfsr[3]};
	wire[3:0] icnt_lfsr_init0 = 4'b0001;
	wire[3:0] icnt_lfsr_init1 = 4'b0010;
	(* KEEP = "TRUE" *)
	reg icnt_sat, icnt_start, icnt_stop;
	wire icnt_sat_next = icnt_sat || (icnt_lfsr == 4'b1001);
	wire[6:0] icnt = { icnt_sat, icnt_stop, icnt_lfsr, icnt_start};
	(* KEEP = "TRUE" *)
	reg[6:0] cnt_int;
	reg cnt_st_int, err_st_int;

	always @( posedge hsclkp, negedge _rst) begin
		if( !_rst) begin
			oldevs0 <= 0;
			icnt_lfsr <= 4'b0001;
			icnt_start <= 0;
			icnt_stop <= 0;
			icnt_sat <= 0;
			cnt_int <= 0;
			cnt_st_int <= 0;
			err_st_int <= 0;
		end
		else begin
			oldevs0 <= evs00;
			case( { oldevs0, evs01, evs00})
				3'b000: begin
					icnt_lfsr <= icnt_lfsr_next;
					icnt_sat <= icnt_sat_next;
					cnt_st_int <= 0;
					err_st_int <= 0;
				end
				3'b001: begin
					icnt_start <= 1;
					icnt_stop <= 0;
					icnt_sat <= 0;
					icnt_lfsr <= icnt_lfsr_init0;
					cnt_st_int <= 1;
					cnt_int <= { icnt_sat, 1'b1, icnt_lfsr, icnt_start};
					err_st_int <= 0;
				end
				3'b010: begin
					icnt_start <= 1;
					icnt_stop <= 0;
					icnt_lfsr <= icnt_lfsr_init0;
					icnt_sat <= 0;
					cnt_st_int <= 1;
					cnt_int <= icnt;
					err_st_int <= 1;
				end
				3'b011: begin
					icnt_start <= 0;
					icnt_stop <= 0;
					icnt_lfsr <= icnt_lfsr_init1;
					icnt_sat <= 0;
					cnt_st_int <= 1;
					cnt_int <= icnt;
					err_st_int <= 0;
				end
				3'b100: begin
					icnt_lfsr <= icnt_lfsr_init1;
					icnt_start <= 0;
					icnt_stop <= 0;
					icnt_sat <= 0;
					cnt_st_int <= 1;
					cnt_int <= icnt;
					err_st_int <= 0;
				end
				3'b101: begin
					icnt_start <= 1;
					icnt_stop <= 0;
					icnt_lfsr <= icnt_lfsr_init0;
					icnt_sat <= 0;
					cnt_st_int <= 1;
					cnt_int <= icnt;
					err_st_int <= 1;
				end
				3'b110: begin
					icnt_start <= 1;
					icnt_stop <= 0;
					icnt_lfsr <= icnt_lfsr_init0;
					icnt_sat <= 0;
					cnt_st_int <= 1;
					cnt_int <= { icnt_sat, 1'b1, icnt_lfsr, icnt_start};
					err_st_int <= 0;
				end
				default: begin
					icnt_lfsr <=  icnt_lfsr_next;
					icnt_sat <= icnt_sat_next;
					cnt_st_int <= 0;
					err_st_int <= 0;
				end
			endcase
		end
	end

	wire tiv_st = cnt_st_int;
	wire tiv_est = err_st_int;
	wire[6:0] tiv_d = cnt_int;

	`ifdef DEBUG_TMIV_CNT
		assign dbg_st = tiv_st;
		assign dbg_est = tiv_est;
		assign dbg_sat = cnt_st_int && cnt_int[6];
	`else
		assign dbg_st = 0;
		assign dbg_est = 0;
		assign dbg_sat = 0;
	`endif

	wire _fifo_empty;
	wire[6:0] fifo_cnt;
	wire fifo_rreq;
	wire fifo_full;

	`ifdef DEBUG_TMIV_CNT
		assign dbg_fifo_rreq = fifo_rreq;
		assign dbg_fifo_full = fifo_full;
		assign dbg_fifo_sat = fifo_cnt[6];
	`else
		assign dbg_fifo_rreq = 0;
		assign dbg_fifo_full = 0;
		assign dbg_fifo_sat = 0;
	`endif

	fifo_lfsr #( .dsize(7)) fifo( .a(tiv_d), .wr(tiv_st), .y(fifo_cnt), .rd(fifo_rreq),
		._empty(_fifo_empty), .full(fifo_full), .clk(hsclkp), ._rst(_rst));

	wire fifo_st = fifo_rreq;

	wire hs_err = tiv_est | fifo_full;
	reg hs_err_o;
	always @( posedge hsclkp, negedge _rst) begin
		if( !_rst) begin
			hs_err_o <= 0;
		end
		else begin
			hs_err_o <= hs_err;
		end
	end
	wire hs_err_r = ~hs_err_o & hs_err;
	wire hs_err_f = hs_err_o & ~hs_err;

	wire[6:0] xd = fifo_cnt;
	wire xs, xs_t, xa, xer, xef, xf;
	p2t hs_side( .yt(xs_t), .ap(fifo_st), .clk(hsclkp), ._rst(_rst));
	sdly #( .size(1)) xs_dly( .y(xs), .a(xs_t), .clk(hsclkp), ._rst(_rst));
	p2t hs_side_er( .yt(xer), .ap(hs_err_r), .clk(hsclkp), ._rst(_rst));
	p2t hs_side_ef( .yt(xef), .ap(hs_err_f), .clk(hsclkp), ._rst(_rst));
	`ifdef DEBUG_TMIV_CNT
		p2t hs_side_f( .yt(xf), .ap(fifo_full), .clk(hsclkp), ._rst(_rst));
	`endif
	wire ls_st, ls_est_r, ls_est_f;
	wire[6:0] ls_d;
	t2p_ddr_r #( .size(7)) ls_side( .yp(ls_st), .yd(ls_d), .yt(xa), .at(xs), .ad(xd), .clkp(lsclkp), .clkn(lsclkn), ._rst(_rst));
	t2p ls_side_er( .yp(ls_est_r), .at(xer), .clk(lsclkp), ._rst(_rst));
	t2p ls_side_ef( .yp(ls_est_f), .at(xef), .clk(lsclkp), ._rst(_rst));
	reg ls_est_hold;
	always @( posedge lsclkp, negedge _rst) begin
		if( !_rst) begin
			ls_est_hold <= 0;
		end
		else begin
			if( ls_est_hold) begin
				ls_est_hold <= ~ls_est_f;
			end
			else begin
				ls_est_hold <= ls_est_r & ~ls_est_f;
			end
		end
	end
	wire ls_est = ls_est_r |ls_est_hold;

	`ifdef DEBUG_TMIV_CNT
		t2p ls_side_f( .yp(dbg_fifo_full), .at(xf), .clk(lsclkp), ._rst(_rst));
	`else
		assign dbg_fifo_full = 0;
	`endif

	`ifdef DEBUG_TMIV_CNT
		assign dbg_xs = xs;
		assign dbg_xa = xa;
	`else
		assign dbg_xs = 0;
		assign dbg_xa = 0;
	`endif

	reg xa_s;
	always @( posedge hsclkp, negedge _rst) begin
		if( !_rst) begin
			xa_s <= 0;
		end
		else begin
			xa_s <= xa;
		end
	end

	assign fifo_rreq = _fifo_empty && (xa_s ~^ xs_t);

	reg[4:0] cnt_s0, cnt_s1, cnt_s2;
	reg st_s0, st_s1, st_s2, est_s0, est_s1, est_s2;
	reg[2:0] sss;
	always @( posedge lsclkp, negedge _rst) begin
		if( !_rst) begin
			cnt_s0 <= 0;
			cnt_s1 <= 0;
			cnt_s2 <= 0;
			st_s0 <= 0;
			st_s1 <= 0;
			st_s2 <= 0;
			est_s0 <= 0;
			est_s1 <= 0;
			est_s2 <= 0;
			sss <= 0;
		end
		else begin
			case( ls_d[4:1])
				4'b0001: cnt_s0 <= 0;
				4'b0010: cnt_s0 <= 2;
				4'b0100: cnt_s0 <= 4;
				4'b1000: cnt_s0 <= 6;
				4'b0011: cnt_s0 <= 8;
				4'b0110: cnt_s0 <= 10;
				4'b1100: cnt_s0 <= 12;
				4'b1011: cnt_s0 <= 14;
				4'b0101: cnt_s0 <= 16;
				4'b1010: cnt_s0 <= 18;
				4'b0111: cnt_s0 <= 20;
				4'b1110: cnt_s0 <= 22;
				4'b1111: cnt_s0 <= 24;
				4'b1101: cnt_s0 <= 26;
				4'b1001: cnt_s0 <= 28;
				default: cnt_s0 <= 0;
			endcase
			sss <= {ls_d[6], ls_d[5], ls_d[0]};
			case( sss)
				3'b000: cnt_s1 <= cnt_s0;
				3'b001: cnt_s1 <= cnt_s0 +1;
				3'b010: cnt_s1 <= cnt_s0 +1;
				3'b011: cnt_s1 <= cnt_s0 +2;
				default: cnt_s1 <= 5'b11111;
			endcase
			cnt_s2 <= cnt_s1;
			st_s0 <= ls_st;
			st_s1 <= st_s0;
			st_s2 <= st_s1 & (|cnt_s1[4:1]);
			est_s0 <= ls_est;
			est_s1 <= est_s0;
			est_s2 <= est_s1 | (st_s1 & !(|cnt_s1[4:1]));
		end
	end

	`ifdef DEBUG_TMIV_CNT
		assign dbg_st_s0 = st_s0;
		assign dbg_sat_s0 = st_s0 && sss[2];
	`else
		assign dbg_st_s0 = 0;
		assign dbg_sat_s0 = 0;
	`endif

	assign cnt = cnt_s2;
	assign cnt_st = st_s2;
	assign err_st = est_s2;

endmodule

// vim: ai ts=4:
