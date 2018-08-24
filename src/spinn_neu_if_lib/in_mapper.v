
// ------------------------------------------------------------------------------
// 
//  Revision 1.1:  07/24/2018
//  - Parallel data parametrized
//    (M. Casti - IIT)
//    
// ------------------------------------------------------------------------------


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//--------------------------- in_mapper -------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps
module in_mapper #
	(
		parameter AER_WIDTH = 32
	)
    (
        input  wire        			rst,
        input  wire        			clk,

        // status interface
        output reg         			dump_mode,

        // input AER device interface
        input  wire [AER_WIDTH-1:0] iaer_data,
        input  wire        			iaer_vld,
        output             			iaer_rdy,

        // SpiNNaker packet interface
        output      [71:0] 			ipkt_data,
        output             			ipkt_vld,
        input  wire        			ipkt_rdy,
        
        // Commands
        input wire                  dump_on,
        input wire                  dump_off
    );

    //---------------------------------------------------------------
    // constants
    //---------------------------------------------------------------
    localparam FIFO_DEPTH  = 3;
    localparam FIFO_WIDTH  = 40;


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //--------------------------- control ---------------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //---------------------------------------------------------------
    // dump events from AER device if SpiNNaker not responding!
    // dump after 128 cycles without SpiNNaker response
    //---------------------------------------------------------------
    reg              [7:0] spnnlnk_timeout_cnt;
    reg                    spnnlnk_timeout;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            spnnlnk_timeout_cnt <= 8'd128;
            spnnlnk_timeout     <= 1'b0;
        end else begin
            spnnlnk_timeout <= 1'b0;
            if (ipkt_rdy) begin
                spnnlnk_timeout_cnt <= 8'd128;  // spinn_driver ready resets counter
            end else if (spnnlnk_timeout_cnt != 5'd0) begin
                spnnlnk_timeout_cnt <= spnnlnk_timeout_cnt - 1;
            end else begin
                spnnlnk_timeout_cnt <= spnnlnk_timeout_cnt;  // no change!
                spnnlnk_timeout <= 1'b1;
            end
        end
    end
    //---------------------------------------------------------------
    
    //---------------------------------------------------------------
    // a "start" command allow to send data to SpiNNaker
    // a "stop" command stops sending data 
    //---------------------------------------------------------------
    reg               cmd_dump;

    always @(posedge clk or posedge rst) begin
        if (rst) 
            cmd_dump <= 1'b1;
        else begin
            if (dump_on) 
                cmd_dump <= 1'b1;
            else if (dump_off) 
                cmd_dump <= 1'b0;
            end
        end
    //---------------------------------------------------------------   

    //---------------------------------------------------------------
    // Dump 
    //---------------------------------------------------------------
    
    always @(posedge clk or posedge rst) begin
        if (rst) 
            dump_mode <= 1'b1;
        else 
            dump_mode <= cmd_dump | spnnlnk_timeout;
        end
    //---------------------------------------------------------------       

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //---------------------- packet interface -----------------------
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //---------------------------------------------------------------
    // Parity bit calculator
    //---------------------------------------------------------------
    wire [38:0]  pkt_bits;
    wire         parity;

    assign pkt_bits = {{(32-AER_WIDTH){1'b0}}, iaer_data, 7'd0};
    assign parity   = ~(^pkt_bits);

    //---------------------------------------------------------------
    // in_mapper FIFO
    //---------------------------------------------------------------
    reg [FIFO_WIDTH-1:0] data_fifo[0:FIFO_DEPTH-1];
    integer fifo_len;

    wire write;
    wire read;
    wire fifo_full;
    wire fifo_empty;

    integer i;


    assign write = ~fifo_full  & iaer_vld;
    assign read  = ~fifo_empty & ipkt_rdy;

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
                        data_fifo[fifo_len] <= {pkt_bits, parity};
                    end

                2'b11 :
                    begin
                        for (i=0; i<FIFO_DEPTH-1; i=i+1)
                            data_fifo[i] <= data_fifo[i+1];
                        data_fifo[fifo_len-1] <= {pkt_bits, parity};
                    end
            endcase
        end
    end

    assign fifo_full  = (fifo_len == FIFO_DEPTH);
    assign fifo_empty = (fifo_len == 0);


    assign iaer_rdy   = ~fifo_full | dump_mode;

    assign ipkt_vld   = ~fifo_empty & ~dump_mode;
    assign ipkt_data  = {32'h0, data_fifo[0]};

endmodule
