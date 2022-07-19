`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    10:04:51 11/20/2014 
// Design Name: 
// Module Name:    nrzi_ddr_tx 
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

module nrzi_ddr_tx( output dout, input[1:0] din, input st, clkp, clkn, _rst);

	reg doutp, doutn;

	assign dout = (clkp && doutp) || (clkn && doutn);

	always @( posedge clkp, negedge _rst)
	if( !_rst) begin
		doutp <= 0;
		doutn <= 0;
	end
	else begin
		if( st) begin
			doutp <= din[1] ^doutn;
			doutn <= din[0] ^( din[1] ^doutn);
		end
		else begin
			doutp <= doutn;
		end
	end

endmodule

module nrzi_ddr_tx_xil( output dout, input[1:0] din, input st, clkp, clkn, _rst);

	reg doutp, doutn; 
	//assign dout = (clkp && doutp) || (clkn && doutn);
	ODDR2 #( .DDR_ALIGNMENT("C0"), .INIT(0), .SRTYPE("ASYNC"))
		drv( .Q(dout), .D0(doutp), .D1(doutn), .C0(clkp), .C1(clkn), .CE(1'b1), .R(~_rst));

	always @( posedge clkp, negedge _rst)
	if( !_rst) begin
		doutp <= 0;
		doutn <= 0;
	end
	else begin
		if( st) begin
			doutp <= din[1] ^doutn;
			doutn <= din[0] ^( din[1] ^doutn);
		end
		else begin
			doutp <= doutn;
		end
	end

endmodule

module nrzid_ddr_tx_xil( output dout, output reg run, output last, input[1:0] din, dly, input st_s, st_e, toggle, clkp, clkn, _rst);

	reg[1:0] dl, dino, d;
	reg st, st_eo, st_eoo;

	//assign run = st;
	assign last = (|dl)? st_eoo: st_eo;

	always @( posedge clkp, negedge _rst) begin
		if( !_rst) begin
			dl <= 0;
			dino <= 0;
			d <= 0;
			st <= 0;
			st_eo <= 0;
			st_eoo <= 0;
			run <= 0;
		end
		else begin
			dino <= din;
			st_eo <= st_e;
			st_eoo <= st_eo;
			if( run) begin
				//st <= st? !st_e :0
				case( dl)
					0: begin
						d <= din;
						run <= !st_e;
					end
					1: begin
						d <= st_eo? {dino[0], 1'b0}: {dino[0], din[1]};
						run <= !st_eo;
					end
					default: begin
						d <= dino;
						run <= !st_eo;
					end
				endcase
			end
			else begin
				run <= st_s;
				st <= st_s | toggle;
				dl <= dly;
				case( dly)
					0: begin
						d <= (toggle && !st_s)? 2'b10: din;
					end
					1: begin
						d <= (toggle && !st_s)? 2'b10: {1'b0, din[1]};
					end
					default: begin
						d <= (toggle && !st_s)? 2'b10: 0;
					end
				endcase
			end
		end
	end

	nrzi_ddr_tx_xil tx( .dout(dout), .din(d), .st(st), .clkp(clkp), .clkn(clkn), ._rst(_rst));

endmodule

module nrzi_ddr_tx2( output dout, input[1:0] din, input st, clkp, clkn, _rst);

	reg doutp, doutp2, doutn;

	assign dout = (clkp && doutp2) || (clkn && doutn);

	always @( posedge clkp, negedge _rst)
	if( !_rst) begin
		doutp <= 0;
		doutn <= 0;
		doutp2 <= 0;
	end
	else begin
		doutp2 <= doutp;
		if( st) begin
			doutn <= din[1] ^doutp;
			doutp <= din[0] ^( din[1] ^doutp);
		end
		else begin
			doutn <= doutp;
		end
	end

endmodule

// vim: ai ts=4 :
