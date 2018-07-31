`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    10:57:29 11/20/2014 
// Design Name: 
// Module Name:    hssaer_tx 
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

module hssaer_enc #( parameter dsize = 8) ( output reg[1:0] txd, txdly, output reg txsts, txste, txtoggle, run, output first, last, input[dsize-1:0] d, input st, en_txtoggle, clk, _rst);

	reg[dsize-1:0] dd;
	reg[7:0] cnt;
	reg seq_a, dold, seq_t;
	reg[1:0] ndd;
	reg nseq_a;
	reg[3:0] dly;

	assign last = txste;
	assign first = txsts;

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			dd <= 0;
			cnt <= 0;
			txd <= 0;
			seq_a <= 0;
			dold <= 0;
			seq_t <= 0;
			run <= 0;
			txsts <= 0;
			txste <= 0;
			ndd <= 0;
			nseq_a <= 0;
			txdly <= 0;
			dly <= 4;
			txtoggle <= 0;
		end
		else begin
			if( run) begin
				txtoggle <= 0;
				txsts <= 0;
				if( |cnt) begin
					cnt <= cnt -1;
					nseq_a <= nseq_a ^(!dd[dsize-1]);
					ndd <= (cnt == 2)? {dd[dsize-1], nseq_a ^dd[dsize-1]}: dd[dsize-1:dsize-2];
					dd <= {dd[dsize-2:0], 1'b1};
					dold <= ndd[1];
					seq_a <= seq_a ^ (!ndd[1]);
					if( seq_a) begin
						case( ndd)
							2'b00: begin
								txd <= (seq_t || ~dold)? 2'b10: 2'b00;
								seq_t <= 0;
							end
							2'b01: begin
								txd <= (seq_t || ~dold)? 2'b10: 2'b00;
								seq_t <= 0;
							end
							2'b10: begin
								txd <= seq_t? 2'b00: 2'b01;
							end
							default: begin
								seq_t <= ~seq_t;
								txd <= seq_t? 2'b00: 2'b10;
							end
						endcase
					end
					else begin
						seq_t <= 0;
						txd <= ndd[1]? 2'b01: (dold? 2'b00 :2'b10);
					end
				end
				else begin
					run <= 0;
					txd <= seq_a? (dold? (seq_t? 2'b10: 2'b00) :2'b10): 2'b01;
					txste <= !seq_a;
					dly <= (txdly == 1) ^(!seq_a)? 1: 0;
				end
			end
			else begin
				if( st) begin
					txtoggle <= 0;
					case( dly)
						0: begin
							run <= 0;
							txsts <= 0;
							txd <= seq_a? 2'b10: 2'b00;
							txste <= seq_a;
							//seq_a <= 0;
							//nseq_a <= 0;
							seq_a <= 1;
							nseq_a <= 1;
							dly <= 2;
						end
						1: begin
							run <= 1;
							txdly <= 1;
							txsts <= 1;
							txste <= 0;
							//txd <= d[dsize-1]? 2'b01: 2'b10;
							txd <= d[dsize-1] & ~d[dsize-2]? 2'b01: 2'b10;
							//seq_a <= !d[dsize-1];
							//nseq_a <= d[dsize-1] ^d[dsize-2];
							seq_a <= d[dsize-1];
							nseq_a <= !d[dsize-1] ^d[dsize-2];
							cnt <= dsize -1;
							dd <= { d[dsize-3:0], 2'b11};
							ndd <= d[dsize-2:dsize-3];
							//seq_t <= 0;
							seq_t <= d[dsize-1] & d[dsize-2];
							dold <= d[dsize-1];
						end
						2: begin
							run <= 1;
							txdly <= 0;
							txsts <= 1;
							txste <= 0;
							//txd <= d[dsize-1]? 2'b01: 2'b10;
							txd <= d[dsize-1] & ~d[dsize-2]? 2'b01: 2'b10;
							//seq_a <= !d[dsize-1];
							//nseq_a <= d[dsize-1] ^d[dsize-2];
							seq_a <= d[dsize-1];
							nseq_a <= !d[dsize-1] ^d[dsize-2];
							cnt <= dsize -1;
							dd <= { d[dsize-3:0], 2'b11};
							ndd <= d[dsize-2:dsize-3];
							//seq_t <= 0;
							seq_t <= d[dsize-1] & d[dsize-2];
							dold <= d[dsize-1];
						end
						3: begin
							run <= 1;
							txdly <= 1;
							txsts <= 1;
							txste <= 0;
							txd <= 2'b10;
							//seq_a <= 0;
							//nseq_a <= !d[dsize-1];
							seq_a <= 1;
							nseq_a <= d[dsize-1];
							cnt <= dsize;
							dd <= { d[dsize-2:0], 1'b1};
							ndd <= d[dsize-1:dsize-2];
							seq_t <= 0;
							dold <= 0;
						end
						default: begin
							run <= 1;
							txdly <= 0;
							txsts <= 1;
							txste <= 0;
							txd <= 2'b10;
							//seq_a <= 0;
							//nseq_a <= !d[dsize-1];
							seq_a <= 1;
							nseq_a <= d[dsize-1];
							cnt <= dsize;
							dd <= { d[dsize-2:0], 1'b1};
							ndd <= d[dsize-1:dsize-2];
							seq_t <= 0;
							dold <= 0;
						end
					endcase
				end
				else begin
					if( en_txtoggle) begin
						txtoggle <= dly >= 14;
						dly <= (dly < 14) ? dly+2: 2;
					end
					else begin
						txtoggle <= 0;
						dly <= (dly < 4) ? dly+2: 4;
					end
					txd <= seq_a? 2'b10: 2'b00;
					txste <= seq_a;
					seq_a <= 0;
					nseq_a <= 0;
				end
			end
		end
	end

endmodule

module hssaer_tx #( parameter dsize = 8) ( output tx, run, first, last, alive, input[dsize-1:0] d, input keepalive, st, clkp, clkn, _rst);

	wire[1:0] txd, txdly;
	wire txsts, txste, txtoggle;
	assign alive = txtoggle;

	hssaer_enc #( .dsize(dsize)) enc( .txd(txd), .txdly(txdly), .txsts(txsts), .txste(txste), .txtoggle(txtoggle),
		.run(run), .first(first), .last(last), .d(d), .st(st), .en_txtoggle(keepalive), .clk(clkp), ._rst(_rst));
	nrzid_ddr_tx_xil mod( .dout(tx), .din(txd), .dly(txdly), .st_s(txsts), .st_e(txste), .toggle(txtoggle), .clkp(clkp), .clkn(clkn), ._rst(_rst));

endmodule

// vim: ai ts=4:
