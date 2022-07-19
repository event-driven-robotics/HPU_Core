`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    09:36:09 12/03/2014 
// Design Name: 
// Module Name:    hssaer_paer_tx 
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

module hssaer_paer_tx_wrapper
#(
    parameter dsize=8,
    parameter int_dsize=24
) 
(
    output                  tx, 
                            dst_rdy, 
                            run, 
                            last, 
    input  [int_dsize-1:0]  ae, 
    input                   src_rdy,
                            keep_alive, 
                            clkp, 
                            clkn, 
                            nrst
);

    wire [dsize-1:0] i_ae;

    assign i_ae = ae[dsize-1:0];
    
	hssaer_paer_tx
        #(
            .dsize(dsize)
        )
        tx_inst
        (
            .tx(tx), 
            .dst_rdy(dst_rdy), 
            .run(run), 
            .last(last), 
            .ae(i_ae[dsize-1:0]),
            .src_rdy(src_rdy),
            .keepalive(keep_alive), 
            .clkp(clkp), 
            .clkn(clkn), 
            ._rst(nrst)
        );

endmodule

