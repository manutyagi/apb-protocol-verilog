`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// File        : apb_top.v
// Description : Top-level wrapper. Instantiates one APB master and one APB
//               slave, and wires the protocol signals between them.
//
// Hierarchy   : apb_top
//                 +-- u_master (apb_master)
//                 +-- u_slave  (apb_slave)
//
// Author      : Manu
//-----------------------------------------------------------------------------

module apb_top (
    // Clock & reset
    input  wire        pclk,
    input  wire        prst,

    // Request side (from CPU / testbench)
    input  wire        pwrite,
    input  wire [31:0] paddressi,
    input  wire [31:0] pdatai,

    // Read data returned to CPU / testbench
    output wire [31:0] prdata
);

    // Internal APB bus (master -> slave)
    wire        bus_pwrite;
    wire        bus_psel;
    wire        bus_penable;
    wire [31:0] bus_paddress;
    wire [31:0] bus_pwdata;

    //-------------------------------------------------------------------------
    // APB master instance
    //-------------------------------------------------------------------------
    apb_master u_master (
        .pclk_m     (pclk),
        .prst_m     (prst),
        .pwritei    (pwrite),
        .address_i  (paddressi),
        .pdata_i    (pdatai),
        .pwrite_m   (bus_pwrite),
        .psel_m     (bus_psel),
        .penable_m  (bus_penable),
        .paddress_m (bus_paddress),
        .pwdata_m   (bus_pwdata)
    );

    //-------------------------------------------------------------------------
    // APB slave instance
    //-------------------------------------------------------------------------
    apb_slave u_slave (
        .pclk_s     (pclk),
        .prst_s     (prst),
        .penable_s  (bus_penable),
        .pwrite_s   (bus_pwrite),
        .psel_s     (bus_psel),
        .paddress_s (bus_paddress),
        .pwdata_s   (bus_pwdata),
        .prdata_s   (prdata)
    );

endmodule
