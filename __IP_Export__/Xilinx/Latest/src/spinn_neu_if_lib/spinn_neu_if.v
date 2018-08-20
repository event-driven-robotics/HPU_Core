// -------------------------------------------------------------------------
// $Id: spinn_aer2_if.v 2644 2013-10-24 15:18:41Z plana $
// -------------------------------------------------------------------------
// COPYRIGHT
// Copyright (c) The University of Manchester, 2012. All rights reserved.
// SpiNNaker Project
// Advanced Processor Technologies Group
// School of Computer Science
// -------------------------------------------------------------------------
// Project            : bidirectional SpiNNaker link to AER device interface
// Module             : top-level module
// Author             : lap/Jeff Pepper/Simon Davidson
// Status             : Review pending
// $HeadURL: https://solem.cs.man.ac.uk/svn/spinn_aer2_if/spinn_aer2_if.v $
// Last modified on   : $Date: 2013-10-24 16:18:41 +0100 (Thu, 24 Oct 2013) $
// Last modified by   : $Author: plana $
// Version            : $Revision: 2644 $
// -------------------------------------------------------------------------

// ------------------------------------------------------------------------------ 
//  Project Name        : 
//  Design Name         : 
//  Starting date:      : 
//  Target Devices      : 
//  Tool versions       : 
//  Project Description : 
// ------------------------------------------------------------------------------
//  Company             : IIT - Italian Institute of Technology  
//  Engineer            : Maurizio Casti
// ------------------------------------------------------------------------------ 
// ==============================================================================
//  PRESENT REVISION
// ==============================================================================
//  File        : HPUcore_tb.vhd
//  Revision    : 1.0
//  Author      : M. Casti
//  Date        : 
// ------------------------------------------------------------------------------
//  Description : Test Bench for "HPUcore" (SpiNNlink-AER)
//     
// ==============================================================================
//  Revision history :
// ==============================================================================
// 
//  Revision 1.0:  07/19/2018
//  - Initial revision, based on tbench.vhd (F. Diotalevi)
//  (M. Casti - IIT)
// 
// ------------------------------------------------------------------------------


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//------------------------ spinn_aer2_if ------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps
module spinn_neu_if #
    (
    	parameter C_PSPNNLNK_WIDTH = 32
    )
    (
        input wire         rst,
        input wire         clk_32,

        output wire        dump_mode,
        output wire        parity_err,
        output wire        rx_err,

        // input SpiNNaker link interface
        input  wire  [6:0] data_2of7_from_spinnaker,
        output wire        ack_to_spinnaker,

        // output SpiNNaker link interface
        output wire  [6:0] data_2of7_to_spinnaker,
        input  wire        ack_from_spinnaker,

        // input AER device interface
        input  wire [31:0] iaer_addr,
        input  wire        iaer_vld,
        output wire        iaer_rdy,

        // output AER device interface
        output wire [31:0] oaer_addr,
        output wire        oaer_vld,
        input  wire        oaer_rdy,
        
        output wire  [2:0] dbg_rxstate,
        output wire  [1:0] dbg_txstate,
        output wire        dbg_ipkt_vld,
        output wire        dbg_ipkt_rdy,
        output wire        dbg_opkt_vld,
        output wire        dbg_opkt_rdy
        
    );


    wire        clk_sync;
    wire        clk_mod;

    wire [31:0] i_iaer_addr;
    wire        i_iaer_rdy;
    wire        i_iaer_vld;
    wire        i_ispinn_ack;
    wire  [6:0] i_ispinn_data;
    wire  [6:0] s_ispinn_data;

    wire [31:0] i_oaer_addr;
    wire        i_oaer_rdy;
    wire        i_oaer_vld;
    wire        i_ospinn_ack;
    wire  [6:0] i_ospinn_data;
    wire        s_ospinn_ack;

    wire [71:0] i_ipkt_data;
    wire        i_ipkt_vld;
    wire        i_ipkt_rdy;

    wire [71:0] i_opkt_data;
    wire        i_opkt_vld;
    wire        i_opkt_rdy;


    assign clk_sync = clk_32;
    assign clk_mod  = clk_32;

    assign i_ispinn_data    = data_2of7_from_spinnaker;
    assign ack_to_spinnaker = i_ispinn_ack;

    assign data_2of7_to_spinnaker = i_ospinn_data;
    assign i_ospinn_ack           = ack_from_spinnaker;

    assign i_iaer_addr = iaer_addr;
    assign i_iaer_vld  = iaer_vld;
    assign iaer_rdy    = i_iaer_rdy;

    assign oaer_addr   = i_oaer_addr;
    assign oaer_vld    = i_oaer_vld;
    assign i_oaer_rdy  = oaer_rdy;

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------- synchronisers -----------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //---------------------------------------------------------------
    // Synchronise the output SpiNNaker async i/f ack
    //---------------------------------------------------------------
    synchronizer
    #(
        .SIZE  (1),
        .DEPTH (2)
    ) ssack
    (
        .clk (clk_sync),
        .in  (i_ospinn_ack),
        .out (s_ospinn_ack)
    );
    //---------------------------------------------------------------

    //---------------------------------------------------------------
    // Synchronise the input SpiNNaker async i/f data
    //---------------------------------------------------------------
    synchronizer
    #(
        .SIZE  (7),
        .DEPTH (2)
    ) sdat
    (
        .clk (clk_sync),
        .in  (i_ispinn_data),
        .out (s_ispinn_data)
    );
    //---------------------------------------------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------ spinn_receiver -----------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    spinn_receiver sr
    (
        .rst       (rst),
        .clk       (clk_mod),
        .err       (rx_err),
        .data_2of7 (s_ispinn_data),
        .ack       (i_ispinn_ack),
        .pkt_data  (i_opkt_data),
        .pkt_vld   (i_opkt_vld),
        .pkt_rdy   (i_opkt_rdy),
        .dbg_state (dbg_rxstate)
    );
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------- out_mapper --------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    out_mapper om
    (
        .rst        (rst),
        .clk        (clk_mod),
        .parity_err (parity_err),
        .opkt_data  (i_opkt_data),
        .opkt_vld   (i_opkt_vld),
        .opkt_rdy   (i_opkt_rdy),
        .oaer_data  (i_oaer_addr),
        .oaer_vld   (i_oaer_vld),
        .oaer_rdy   (i_oaer_rdy)
    );
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //-------------------------- in_mapper --------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    in_mapper im
    (
        .rst       (rst),
        .clk       (clk_mod),
        .dump_mode (dump_mode),
        .iaer_data (i_iaer_addr),
        .iaer_vld  (i_iaer_vld),
        .iaer_rdy  (i_iaer_rdy),
        .ipkt_data (i_ipkt_data),
        .ipkt_vld  (i_ipkt_vld),
        .ipkt_rdy  (i_ipkt_rdy)
    );
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------- spinn_driver ------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    spinn_driver sd
    (
        .rst       (rst),
        .clk       (clk_mod),
        .pkt_data  (i_ipkt_data),
        .pkt_vld   (i_ipkt_vld),
        .pkt_rdy   (i_ipkt_rdy),
        .data_2of7 (i_ospinn_data),
        .ack       (s_ospinn_ack),
        .dbg_state (dbg_txstate)
    );
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    assign dbg_ipkt_vld = i_ipkt_vld;
    assign dbg_ipkt_rdy = i_ipkt_rdy;
    assign dbg_opkt_vld = i_opkt_vld;
    assign dbg_opkt_rdy = i_opkt_rdy;


endmodule
