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
//  Change history :
// ==============================================================================
// 
//  - 08/24/2018 : START/STOP Command (M. Casti - IIT) 
//  - 10/08/2018 : Data Mask (M. Casti - IIT) 
//    
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//------------------------ spinn_aer2_if ------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps
module spinn_neu_if #
    (
    	parameter C_PSPNNLNK_WIDTH = 32,
    	parameter C_HAS_TX         = "true",
    	parameter C_HAS_RX         = "true"
    )
    (
        input wire         rst,
        input wire         clk_32,
        input wire         enable,

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
                
        // Command from SpiNNaker
        input  wire [31:0] cmd_start_key,
        input  wire [31:0] cmd_stop_key, 
        output wire        cmd_start,
        output wire        cmd_stop,
        input  wire [31:0] tx_data_mask,
        input  wire [31:0] rx_data_mask,
        
        // Controls
        input wire         dump_off,
        input wire         dump_on,

        // Debug Port       
        output wire  [2:0] dbg_rxstate,
        output wire  [1:0] dbg_txstate,
        output wire        dbg_ipkt_vld,
        output wire        dbg_ipkt_rdy,
        output wire        dbg_opkt_vld,
        output wire        dbg_opkt_rdy
        
    );

// *****************************************************************************************************
//  VHDL Component Declaration
// 
//  component spinn_neu_if
//    	generic (
//        C_PSPNNLNK_WIDTH              : natural range 1 to 32 := 32;
//        C_HAS_TX                      : string;
//        C_HAS_RX                      : string
//            );
//      port (
//        rst                           : in  std_logic;
//        clk_32                        : in  std_logic;
//        
//        dump_mode                     : out std_logic;
//        parity_err                    : out std_logic;
//        rx_err                        : out std_logic;
//    
//        -- input SpiNNaker link interface
//        data_2of7_from_spinnaker      : in  std_logic_vector(6 downto 0); 
//        ack_to_spinnaker              : out std_logic;
//    
//        -- output SpiNNaker link interface
//        data_2of7_to_spinnaker        : out std_logic_vector(6 downto 0);
//        ack_from_spinnaker            : in  std_logic;
//    
//        -- input AER device interface
//        iaer_addr                     : in  std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
//        iaer_vld                      : in  std_logic;
//        iaer_rdy                      : out std_logic;
//    
//        -- output AER device interface
//        oaer_addr                     : out std_logic_vector(C_PSPNNLNK_WIDTH-1 downto 0);
//        oaer_vld                      : out std_logic;
//        oaer_rdy                      : in  std_logic;
//        
//        -- Command from SpiNNaker
//        cmd_start_key                 : in  std_logic_vector(6 downto 0); 
//        cmd_stop_key                  : in  std_logic_vector(6 downto 0); 
//        cmd_start                     : out std_logic;
//        cmd_stop                      : out std_logic;
//
//        -- Controls
//        dump_off                      : in std_logic;
//        dump_on                       : in std_logic;
//           
//        -- Debug ports
//        
//        dbg_rxstate                   : out std_logic_vector(2 downto 0);
//        dbg_txstate                   : out std_logic_vector(1 downto 0);
//        dbg_ipkt_vld                  : out std_logic;
//        dbg_ipkt_rdy                  : out std_logic;
//        dbg_opkt_vld                  : out std_logic;
//        dbg_opkt_rdy                  : out std_logic
//  ); 
//  end component;
// *****************************************************************************************************

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
    
    wire        i_cmd_start;
    wire        i_cmd_stop;
    wire        i_dump_on;
    wire        i_dump_off;


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


// ******************************************************************
//                          R X    P A T H
// ******************************************************************

generate
    if(C_HAS_RX == "true") 
    begin

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------- synchronisers -----------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
        .enable    (enable),
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
    out_mapper     #(
        .AER_WIDTH     (C_PSPNNLNK_WIDTH)
    ) om
    (
        .rst           (rst),
        .clk           (clk_mod),
        .parity_err    (parity_err),        
        .cmd_start_key (cmd_start_key),
        .cmd_stop_key  (cmd_stop_key),
        .cmd_start     (i_cmd_start),
        .cmd_stop      (i_cmd_stop),
        .rx_data_mask  (rx_data_mask),
        .opkt_data     (i_opkt_data),
        .opkt_vld      (i_opkt_vld),
        .opkt_rdy      (i_opkt_rdy),
        .oaer_data     (i_oaer_addr),
        .oaer_vld      (i_oaer_vld),
        .oaer_rdy      (i_oaer_rdy)

    );
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
    end  
endgenerate   
    
// ******************************************************************
//                          T X    P A T H
// ******************************************************************    

generate
    if(C_HAS_TX == "true")
    begin    
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
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //-------------------------- in_mapper --------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    in_mapper     #(
        .AER_WIDTH (C_PSPNNLNK_WIDTH)
    ) im
    (
        .rst          (rst),
        .clk          (clk_mod),
        .enable       (enable),
        .dump_mode    (dump_mode),
        .dump_on      (i_dump_on),
        .dump_off     (i_dump_off),  
        .tx_data_mask (tx_data_mask), 
        .iaer_data    (i_iaer_addr),
        .iaer_vld     (i_iaer_vld),
        .iaer_rdy     (i_iaer_rdy),
        .ipkt_data    (i_ipkt_data),
        .ipkt_vld     (i_ipkt_vld),
        .ipkt_rdy     (i_ipkt_rdy)
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
    end
endgenerate



    assign dbg_ipkt_vld = i_ipkt_vld;
    assign dbg_ipkt_rdy = i_ipkt_rdy;
    assign dbg_opkt_vld = i_opkt_vld;
    assign dbg_opkt_rdy = i_opkt_rdy;
    
    assign i_dump_off   = ((C_HAS_RX == "true") & i_cmd_start) | ((C_HAS_TX == "true") & dump_off);
    assign i_dump_on    = ((C_HAS_RX == "true") & i_cmd_stop)  | ((C_HAS_TX == "true") & dump_on );
    assign cmd_start    = (C_HAS_RX == "true") & i_cmd_start;
    assign cmd_stop     = (C_HAS_RX == "true") & i_cmd_stop;


endmodule
