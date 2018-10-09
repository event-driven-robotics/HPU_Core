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
//  Changes:  
//  - 07/24/2018 : Parallel data parametrized (M. Casti - IIT)
//  - 08/24/2018 : START/STOP Command (M. Casti - IIT) 
//  - 10/08/2018 : Data Mask (M. Casti - IIT) 
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
        
        // Command from SpiNNaker 
        input  wire [31:0]          cmd_start_key,
        input  wire [31:0]          cmd_stop_key, 
        output reg                  cmd_start,
        output reg                  cmd_stop,
                        
        // Controls
        input  wire [31:0]          rx_data_mask,
        
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
    wire mc_pkt;
    wire parity_chk;
    wire fifo_full;
    wire fifo_empty;    

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
 
    //---------------------------------------------------------------
    // Commands
    
    wire cmd_vld, cmd_flag;   // Signals for command recongnition
    


    assign cmd_flag = (opkt_data[39:8] == cmd_start_key) | (opkt_data[39:8] == cmd_stop_key);
    assign cmd_vld = cmd_flag & opkt_vld & mc_pkt & parity_chk;     
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_start <= 0;
            cmd_stop  <= 0;
            end 
        else begin
            cmd_start <= (opkt_data[39:8] == cmd_start_key) & cmd_vld;
            cmd_stop  <= (opkt_data[39:8] == cmd_stop_key) & cmd_vld;
            end
        end    

    //---------------------------------------------------------------
    // Data
    
    integer i;
   
    assign write   = ~cmd_flag & ~fifo_full & opkt_vld & mc_pkt & parity_chk;
    assign read    = ~fifo_empty & oaer_rdy;

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
                        data_fifo[fifo_len] <= (rx_data_mask & opkt_data[39:8]);
                    end

                2'b11 :
                    begin
                        for (i=0; i<FIFO_DEPTH-1; i=i+1)
                            data_fifo[i] <= data_fifo[i+1];
                        data_fifo[fifo_len-1] <= (rx_data_mask & opkt_data[39:8]);
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
