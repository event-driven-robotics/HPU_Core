`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Istituto Italiano di Tecnologia -- Center for Space Human Robotics (CSHR IIT@PoliTO) 
// Engineer: Paolo Motto Ros (paolo.mottoros@iit.it) 
// 
// Create Date:    09:36:09 12/03/2014 
// Design Name: 
// Module Name:    hssaer_paer_rx 
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

module hssaer_paer_rx_wrapper
#(
    parameter dsize=8,
    parameter int_dsize=24
)
(
    output [int_dsize-1:0]      ae,
    output                      src_rdy,
                                err_ko,
                                err_rx, 
                                err_to, 
                                err_of,
                                int,
                                run,
    input  [int_dsize-1:dsize]  higher_bits,
    input                       dst_rdy, 
                                rx, 
                                lsclkp, 
                                lsclkn, 
                                hsclkp, 
                                hsclkn, 
                                nrst,
                                aux_channel
);
    
    wire [dsize-1:0] i_ae;

    assign ae = (aux_channel==1) ? {higher_bits[int_dsize-1:dsize+3], i_ae[dsize-1-2:dsize-1-2-2],  i_ae} : {higher_bits, i_ae};

	hssaer_paer_rx
        #(
            .dsize(dsize)
        )
        rx_inst
        (
            .ae(i_ae),
            .src_rdy(src_rdy),
            .err_ko(err_ko),
            .err_rx(err_rx), 
            .err_to(err_to), 
            .err_of(err_of),
            .int(int),
            .run(run),
            .dst_rdy(dst_rdy), 
            .rx(rx), 
            .lsclkp(lsclkp), 
            .lsclkn(lsclkn), 
            .hsclkp(hsclkp), 
            .hsclkn(hsclkn), 
            ._rst(nrst)
        );

endmodule

