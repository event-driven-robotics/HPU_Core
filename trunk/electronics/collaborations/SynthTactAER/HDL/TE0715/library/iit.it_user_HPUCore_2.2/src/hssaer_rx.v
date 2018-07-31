`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    13:40:05 11/21/2014 
// Design Name: 
// Module Name:    hsssaer_rx 
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

module hssaer_dec #( parameter dsize = 8) ( output reg[dsize-1:0] d, output reg st, dok, err, int, run, alive, idle, output to_err,
	input[2:0] rxd, input rxst, rxerr, clk, _rst,
	output dbg0, dbg1);

	reg seq_a, wait0;
	reg[dsize:0] dt;
	reg[7:0] cnt;
	reg check0;
	//reg[2:0] to_cnt;
	//reg[3:0] to_cnt;
	//reg[4:0] to_cnt;
	reg[5:0] to_cnt;
	//localparam max_to = 3;
	//localparam max_to = 3'b111;
	//localparam max_to = 7;
	localparam max_to = 11;
	//localparam max_to = 4'b1111;
	//localparam max_to = 15;
	//localparam max_to = 23;
	//localparam max_to = 5'b11111;
	//localparam max_to = 39;
	//localparam max_to = 6'b111111;

	assign to_err = run && !(|to_cnt) && (|cnt);

	wire rx_end = run && !(|cnt) && (|to_cnt);

	assign dbg0 = |to_cnt;
	assign dbg1 = |cnt;

	always @( posedge clk, negedge _rst) begin
		if( !_rst) begin
			run <= 0;
			seq_a <= 0;
			dt <= 0;
			cnt <= 0;
			d <= 0;
			st <= 0;
			err <= 0;
			wait0 <= 0;
			check0 <= 0;
			dok <= 0;
			to_cnt <= 0;
			int <= 0;
			alive <= 0;
			idle <= 0;
		end
		else begin
			st <= rx_end && !err;
			d <= rx_end? dt[dsize:1]: d;
			dok <= rx_end && !err && !check0;
			if( rxerr) begin
				err <= 1;
				to_cnt <= 0;
				run <= 0;
				int <= 0;
				alive <= 0;
				idle <= 0;
			end
			else if( |cnt && rxst && !err) begin
				int <= 0;
				alive <= 0;
				idle <= 0;
				if( seq_a) begin
					case( rxd)
						1: begin
							dt <= {dt[dsize-1:0], 1'b0};
							seq_a <= 0;
							cnt <= cnt -1;
							wait0 <= 0;
							check0 <= ~check0;
							to_cnt <= max_to;
						end
						2: begin
							if( wait0) begin
								dt <= {dt[dsize-1:0], 1'b0};
								seq_a <= 0;
								cnt <= cnt -1;
							end
							else begin
								dt <= {dt[dsize-2:0], 2'b01};
								seq_a <= 0;
								cnt <= cnt >= 2? cnt -2 :0;
								err <= cnt < 2;
							end
							check0 <= ~check0;
							wait0 <= 0;
							to_cnt <= max_to;
						end
						3: begin
							if( wait0) begin
								dt <= {dt[dsize-2:0], 2'b01};
								cnt <= cnt >= 2? cnt -2 :0;
								err <= cnt < 2;
								seq_a <= 0;
								check0 <= ~check0;
							end
							else begin
								dt <= {dt[dsize-2:0], 2'b11};
								cnt <= cnt >= 2? cnt -2 :0;
								err <= cnt < 2;
							end
							wait0 <= 0;
							to_cnt <= max_to;
						end
						4: begin
							dt <= {dt[dsize-3:0], 3'b111};
							cnt <= cnt > 3? cnt -3 :0;
							err <= cnt < 3;
							wait0 <= 1;
							to_cnt <= max_to;
						end
						default: begin
							err <= 1;
							to_cnt <= 0;
							run <= 0;
						end
					endcase
				end
				else begin
					case( rxd)
						1: begin
							if( !dt[0]) begin
								dt <= {dt[dsize-1:0], 1'b0};
								seq_a <= 1;
								cnt <= cnt -1;
								check0 <= ~check0;
							end
							else
							begin
								dt <= {dt[dsize-1:0], 1'b1};
								seq_a <= 0;
								cnt <= cnt -1;
							end
							to_cnt <= max_to;
						end
						2: begin
							if( !dt[0]) begin
								dt <= {dt[dsize-2:0], 2'b01};
								seq_a <= 1;
								cnt <= cnt >= 2? cnt -2 :0;
								err <= cnt < 2;
								wait0 <= 1;
								check0 <= ~check0;
							end
							else begin
								dt <= {dt[dsize-1:0], 1'b0};
								seq_a <= 1;
								cnt <= cnt -1;
								check0 <= ~check0;
							end
							to_cnt <= max_to;
						end
						3: begin
							dt <= {dt[dsize-2:0], 2'b01};
							cnt <= cnt >= 2? cnt -2 :0;
							err <= cnt < 2;
							seq_a <= 1;
							wait0 <= 1;
							check0 <= ~check0;
							to_cnt <= max_to;
						end
						default: begin
							err <= 1;
							to_cnt <= 0;
							run <= 0;
						end
					endcase
				end
			end
			else begin
				if( rxst) begin
					//to_cnt <= max_to;
					check0 <= 1;
					case( rxd)
						1: begin
							dt <= 0;
							seq_a <= 1;
							wait0 <= 0;
							cnt <= dsize+1;
							run <= 1;
							err <= 0;
							alive <= 1;
							idle <= 0;
							to_cnt <= max_to;
						end
						2: begin
							//dt[0] <= 1;
							dt <= 1;
							seq_a <= 1;
							wait0 <= 1;
							cnt <= dsize;
							run <= 1;
							err <= 0;
							alive <= 1;
							idle <= 0;
							to_cnt <= max_to;
						end
						7: begin
							//run <= (run && !(|cnt))? 0 : run;
							run <= 0;
							err <= 0;
							alive <= 1;
							idle <= 1;
							to_cnt <= 0;
						end
						0: begin
							run <= 0;
							int <= 1;
							err <= 0;
							alive <= 0;
							idle <= 0;
							to_cnt <= 0;
						end
						default: begin
							//run <= (run && !(|cnt))? 0 : run;
							run <= 0;
							err <= 0;
							/*
							err <= 1;
							run <= 0;
							*/
							alive <= 0;
							idle <= 0;
							to_cnt <= 0;
						end
					endcase
				end
				else begin
					err <= 0;
					//run <= (run && !(|cnt) && (|to_cnt))? 0 : run;
					run <= (err | (run && !(|cnt) && (|to_cnt)) | (run && (|cnt) && !(|to_cnt)))? 0 : run;
					//run <= (err | to_err | run && !(|cnt) && (|to_cnt))? 0 : run;
					//cnt <= (run && (|cnt) && (|to_cnt))? cnt : 0;
					cnt <= (!err && run && (|cnt) && (|to_cnt))? cnt : 0;
					//to_cnt <= (run && (|cnt) && (|to_cnt))? to_cnt -1 : 0;
					//to_cnt <= (!err && run && (|cnt) && (|to_cnt))? to_cnt -1 : 0;
					to_cnt <= !(|to_cnt) | rx_end | err? 0: to_cnt -1;
					int <= 0;
					alive <= 0;
					idle <= 0;
				end
			end
		end
	end

endmodule

module hssaer_rx #( parameter dsize = 8) ( output[dsize-1:0] d, output dok, st, err, to_err, int, run, alive, idle,
	input rx, lsclkp, lsclkn, hsclkp, hsclkn, _rst,
	output dbg0, dbg1);

	wire[4:0] cnt;
	wire cnt_st, err_st;
	wire[2:0] tvr_d;
	wire tvr_st, tvr_err;

	tmiv_cnt2 rx_cnt( .cnt(cnt), .cnt_st(cnt_st), .err_st(err_st), .evs(rx), .lsclkp(lsclkp), .lsclkn(lsclkn), .hsclkp(hsclkp), .hsclkn(hsclkn), ._rst(_rst));
	tmiv_hssaer_dec tvr_dec( .tvr_d(tvr_d), .tvr_st(tvr_st), .tvr_err(tvr_err), .tmiv_d(cnt), .tmiv_st(cnt_st), .tmiv_err(err_st), .clk(lsclkp), ._rst(_rst));
	hssaer_dec #( .dsize(dsize)) test_hssaer_rx( .d(d), .st(st), .dok(dok), .err(err), .to_err(to_err), .int(int), .run(run), .alive(alive), .idle(idle),
		.rxd(tvr_d), .rxst(tvr_st), .rxerr(tvr_err), .clk(lsclkp), ._rst(_rst), .dbg0(dbg0), .dbg1(dbg1));

endmodule

// vim: ai ts=4:
