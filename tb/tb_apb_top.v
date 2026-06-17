//-----------------------------------------------------------------------------
// File        : tb_apb_top.v
// Description : Testbench for the APB protocol top-level. Drives a sequence
//               of writes and reads through the master, and self-checks the
//               read-back data against expected values.
//
// Run modes   : - default                : randomized test data
//               - +define+LINEAR_TB      : fixed test data (152, 1002)
//
// Author      : Manu
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_apb_top;

    // DUT signals
    reg         pclk;
    reg         prst;
    reg         pwrite;
    reg  [31:0] paddressi;
    reg  [31:0] pdatai;
    wire [31:0] prdata;

    // Score keeping
    integer errors = 0;
    integer checks = 0;

    // Random data captured for read-back comparison
    reg  [31:0] exp_d3;
    reg  [31:0] exp_d5;

    //-------------------------------------------------------------------------
    // Device Under Test
    //-------------------------------------------------------------------------
    apb_top dut (
        .pclk      (pclk),
        .prst      (prst),
        .pwrite    (pwrite),
        .paddressi (paddressi),
        .pdatai    (pdatai),
        .prdata    (prdata)
    );

    //-------------------------------------------------------------------------
    // Clock: 10 ns period (100 MHz)
    //-------------------------------------------------------------------------
    initial pclk = 1'b0;
    always #5 pclk = ~pclk;

    //-------------------------------------------------------------------------
    // Stimulus tasks
    //-------------------------------------------------------------------------
    task init_inputs;
        begin
            prst      = 1'b1;
            pwrite    = 1'b0;
            paddressi = 32'b0;
            pdatai    = 32'b0;
        end
    endtask

    task do_write(input [31:0] addr, input [31:0] data);
        begin
            paddressi = addr;
            pdatai    = data;
            pwrite    = 1'b1;
            #30;                          // 3 clocks > 1 full APB transfer
            pwrite    = 1'b0;
        end
    endtask

    task do_read_and_check(input [31:0] addr, input [31:0] expected);
        begin
            paddressi = addr;
            pwrite    = 1'b0;
            #30;
            checks = checks + 1;
            if (prdata === expected) begin
                $display("[%0t ns] READ  PASS: addr=%0d  prdata=%0d (0x%08h)",
                         $time, addr, prdata, prdata);
            end
            else begin
                errors = errors + 1;
                $display("[%0t ns] READ  FAIL: addr=%0d  prdata=%0d expected=%0d",
                         $time, addr, prdata, expected);
            end
        end
    endtask

    //-------------------------------------------------------------------------
    // Main stimulus
    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("apb.vcd");
        $dumpvars(0, tb_apb_top);

        $display("============================================");
        $display("     APB PROTOCOL SIMULATION  -  START");
        $display("============================================");

        init_inputs();
        #20;
        prst = 1'b0;                      // release reset

`ifdef LINEAR_TB
        do_write(32'd1, 32'd152);
        do_write(32'd2, 32'd1002);
        do_read_and_check(32'd1, 32'd152);
        do_read_and_check(32'd2, 32'd1002);
`else
        exp_d3 = $urandom_range(0, 255);
        exp_d5 = $urandom_range(0, 1023);
        do_write(32'd3, exp_d3);
        do_write(32'd5, exp_d5);
        do_read_and_check(32'd3, exp_d3);
        do_read_and_check(32'd5, exp_d5);
`endif

        #20;
        $display("============================================");
        if (errors == 0)
            $display("  RESULTS: checks=%0d  errors=%0d  -> PASS",
                     checks, errors);
        else
            $display("  RESULTS: checks=%0d  errors=%0d  -> FAIL",
                     checks, errors);
        $display("============================================");
        $finish;
    end

endmodule
