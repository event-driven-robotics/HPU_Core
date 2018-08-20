// -------------------------------------------------------------------------
// $Id: out_mapper.v 2615 2013-10-02 10:39:58Z plana $
// -------------------------------------------------------------------------
// COPYRIGHT
// Copyright (c) The University of Manchester, 2012. All rights reserved.
// SpiNNaker Project
// Advanced Processor Technologies Group
// School of Computer Science
// -------------------------------------------------------------------------
// Project            : bidirectional SpiNNaker link to AER device interface
// Module             : SpiNNaker packet to AER event mapper
// Author             : lap/Jeff Pepper/Simon Davidson
// Status             : Review pending
// $HeadURL: https://solem.cs.man.ac.uk/svn/spinn_aer2_if/out_mapper.v $
// Last modified on   : $Date: 2013-10-02 11:39:58 +0100 (Wed, 02 Oct 2013) $
// Last modified by   : $Author: plana $
// Version            : $Revision: 2615 $
// -------------------------------------------------------------------------

// ------------------------------------------------------------------------------
// 
//  Revision 1.1:  07/24/2018
//  - Parallel data parametrized
//    (M. Casti - IIT)
//    
// ------------------------------------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//-------------------------- out_mapper -------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps
module out_mapper #
	(
		parameter AER_WIDTH = 32
	)
    (
        input wire         			rst,
        input wire         			clk,

        // status interface
        output reg         			parity_err,

        // SpiNNaker packet interface
        input  wire [71:0] 			opkt_data,
        input  wire        			opkt_vld,
        output             			opkt_rdy,

        // output AER device interface
        output      [AER_WIDTH-1:0] oaer_data,
        output             			oaer_vld,
        input  wire        			oaer_rdy
    );

    //---------------------------------------------------------------
    // constants
    //---------------------------------------------------------------

    //---------------------------------------------------------------
    // internal signals
    //---------------------------------------------------------------



    //---------------------------------------------------------------
    // constants
    //---------------------------------------------------------------
    localparam FIFO_DEPTH  = 3;
    localparam FIFO_WIDTH  = 32;


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //--------------------------- control ---------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------- out_mapper --------------------------
    // NOTE: must throw away non-multicast packets!
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    wire    mc_pkt;
    wire    parity_chk;

    // check if multicast packet
    assign mc_pkt = ~opkt_data[7] & ~opkt_data[6];
    
    // check the parity bit
    assign parity_chk = ^opkt_data;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            parity_err <= 1'b0;
        else
            if (~fifo_full & opkt_vld & mc_pkt)
                parity_err <= ~parity_chk;
    end
    
    //---------------------------------------------------------------

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //---------------------- packet interface -----------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //---------------------------------------------------------------
    // out_mapper FIFO
    //---------------------------------------------------------------
    reg [FIFO_WIDTH-1:0] data_fifo[0:FIFO_DEPTH-1];
    integer fifo_len;

    wire write;
    wire read;
    wire fifo_full;
    wire fifo_empty;

    integer i;


    assign write = ~fifo_full  & opkt_vld & mc_pkt & parity_chk;
    assign read  = ~fifo_empty & oaer_rdy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_len <= 0;
        end else begin
            case ({write, read})
                2'b01 :
                    begin
                        fifo_len <= fifo_len - 1;
                        for (i=0; i<FIFO_DEPTH-1; i=i+1)
                            data_fifo[i] <= data_fifo[i+1];
                    end

                2'b10 :
                    begin
                        fifo_len <= fifo_len + 1;
                        data_fifo[fifo_len] <= opkt_data[39:8];
                    end

                2'b11 :
                    begin
                        for (i=0; i<FIFO_DEPTH-1; i=i+1)
                            data_fifo[i] <= data_fifo[i+1];
                        data_fifo[fifo_len-1] <= opkt_data[39:8];
                    end
            endcase
        end
    end

    assign fifo_full  = (fifo_len == FIFO_DEPTH);
    assign fifo_empty = (fifo_len == 0);


    assign opkt_rdy   = ~fifo_full;

    assign oaer_vld   = ~fifo_empty;
    assign oaer_data  = data_fifo[0];

endmodule
