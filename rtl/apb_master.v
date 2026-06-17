`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// File        : apb_master.v
// Description : AMBA APB master. Generates the 2-phase APB handshake
//               (SETUP -> ACCESS) for read and write transfers.
//
// Protocol    : AMBA APB (ARM IHI 0024)
// Author      : Manu
//-----------------------------------------------------------------------------

module apb_master (
    // Clock & reset
    input  wire        pclk_m,        // bus clock
    input  wire        prst_m,        // active-high synchronous reset

    // Request from upstream (CPU / testbench)
    input  wire        pwritei,       // 1 = write, 0 = read
    input  wire [31:0] address_i,     // requested address
    input  wire [31:0] pdata_i,       // requested write data

    // APB outputs to slave
    output reg         pwrite_m,      // transfer direction
    output reg         psel_m,        // select
    output reg         penable_m,     // enable (asserted in ACCESS)
    output reg  [31:0] paddress_m,    // address
    output reg  [31:0] pwdata_m       // write data
);

    // FSM state encoding
    localparam [1:0] IDLE   = 2'b00,
                     SETUP  = 2'b01,
                     ACCESS = 2'b10;

    reg [1:0] present, next;

    //-------------------------------------------------------------------------
    // Sequential block: state register with synchronous reset
    //-------------------------------------------------------------------------
    always @(posedge pclk_m) begin
        if (prst_m) present <= IDLE;
        else        present <= next;
    end

    //-------------------------------------------------------------------------
    // Combinational block: next state + outputs
    // Defaults at the top prevent latch inference.
    //-------------------------------------------------------------------------
    always @(*) begin
        // Default outputs (bus quiet)
        pwrite_m   = 1'b0;
        psel_m     = 1'b0;
        penable_m  = 1'b0;
        paddress_m = 32'b0;
        pwdata_m   = 32'b0;
        next       = IDLE;

        case (present)
            IDLE: begin
                next = SETUP;
            end

            SETUP: begin
                // SETUP phase: psel high, penable low, info on the bus
                pwrite_m   = pwritei;
                psel_m     = 1'b1;
                penable_m  = 1'b0;
                paddress_m = address_i;
                pwdata_m   = pdata_i;
                next       = ACCESS;
            end

            ACCESS: begin
                // ACCESS phase: both psel and penable high
                pwrite_m   = pwritei;
                psel_m     = 1'b1;
                penable_m  = 1'b1;
                paddress_m = address_i;
                pwdata_m   = pdata_i;
                next       = SETUP;
            end

            default: next = IDLE;
        endcase
    end

endmodule
