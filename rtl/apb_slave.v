`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// File        : apb_slave.v
// Description : AMBA APB slave with 11-deep, 32-bit-wide internal memory.
//               Captures writes and returns reads when the master enters
//               the ACCESS phase.
//
// Protocol    : AMBA APB (ARM IHI 0024)
// Author      : Manu
//-----------------------------------------------------------------------------

module apb_slave (
    // Clock & reset
    input  wire        pclk_s,
    input  wire        prst_s,

    // APB inputs from master
    input  wire        penable_s,
    input  wire        pwrite_s,
    input  wire        psel_s,
    input  wire [31:0] paddress_s,
    input  wire [31:0] pwdata_s,

    // Read data back to master
    output reg  [31:0] prdata_s
);

    // FSM state encoding (mirrors the master for visibility in waveforms)
    localparam [1:0] IDLE   = 2'b00,
                     SETUP  = 2'b01,
                     ACCESS = 2'b10;

    reg [1:0] present, next;

    // Internal memory: 11 locations x 32 bits
    reg [31:0] mem [0:10];
    integer    i;

    //-------------------------------------------------------------------------
    // Sequential block: state register, reset, and memory operations.
    // Memory is written / read only when (psel && penable && present==ACCESS)
    //-------------------------------------------------------------------------
    always @(posedge pclk_s) begin
        if (prst_s) begin
            for (i = 0; i < 11; i = i + 1) mem[i] <= 32'b0;
            prdata_s <= 32'b0;
            present  <= IDLE;
        end
        else begin
            present <= next;

            if (psel_s && penable_s && (present == ACCESS)) begin
                if (paddress_s < 11) begin
                    if (pwrite_s) begin
                        mem[paddress_s] <= pwdata_s;
                        $display("[%0t ns] SLAVE WRITE: addr=%0d data=%0d (0x%08h)",
                                 $time, paddress_s, pwdata_s, pwdata_s);
                    end
                    else begin
                        prdata_s <= mem[paddress_s];
                    end
                end
            end
        end
    end

    //-------------------------------------------------------------------------
    // Combinational block: next-state logic
    //-------------------------------------------------------------------------
    always @(*) begin
        next = IDLE;
        case (present)
            IDLE:    next = SETUP;
            SETUP:   next = ACCESS;
            ACCESS:  next = SETUP;
            default: next = IDLE;
        endcase
    end

endmodule
