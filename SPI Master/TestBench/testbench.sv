// =============================================================================
// FILE : tb_spi_uvm.sv — Top-level UVM Testbench for spi_master_soc_top
//
// Compile order (VCS):
//   vcs -sverilog -ntb_opts uvm-1.2 \
//       spi_if.sv spi_seq_item.sv spi_sequencer.sv spi_driver.sv \
//       spi_monitor.sv spi_scoreboard.sv spi_env.sv spi_sequences.sv \
//       spi_test.sv tb_spi_uvm.sv
//
// EDA Playground: add RTL files in left panel; include only UVM TB files here.
// =============================================================================

`timescale 1ns/1ps

`ifndef UVM_MACROS_SVH
  `include "uvm_macros.svh"
`endif

`include "spi_if.sv"
`include "spi_seq_item.sv"
`include "spi_sequencer.sv"
`include "spi_driver.sv"
`include "spi_monitor.sv"
`include "spi_agent.sv"
`include "spi_scoreboard.sv"
`include "spi_coverage.sv"
`include "spi_env.sv"
`include "spi_sequences.sv"
`include "spi_fsm_release.sv"
`include "spi_test.sv"
`include "spi_assertions.sv"

module tb_spi_uvm;

    import uvm_pkg::*;

    // -------------------------------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    initial  clk = 1'b0;
    always #5 clk = ~clk;   // 100 MHz

   // -------------------------------------------------------------------------
// Clock & Reset  — keep exactly as before
// -------------------------------------------------------------------------
initial begin
    rst_n = 1'b0;
    repeat(10) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    repeat(1) @(posedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;
end   // <-- close here, separate block below

// -------------------------------------------------------------------------
// FSM default-state coverage force — SEPARATE initial block
// Must be separate so it can independently wait for reset to finish
// -------------------------------------------------------------------------

initial begin
    // Wait for rst_n to go high and stay high
    @(posedge rst_n);
    repeat(5) @(posedge clk);

    $display("[TB_TOP] @ %0t : FSM state before force = %0d",
             $time, dut.u_spi_main.state);

    // Force illegal state 6
    force dut.u_spi_main.state = 3'd6;
    $display("[TB_TOP] @ %0t : Forced FSM state = 3'd6 (illegal)", $time);
    @(posedge clk);
    release dut.u_spi_main.state;
    @(posedge clk);   // one cycle for default: state <= IDLE to register


while (dut.u_spi_main.state !== 3'd0) begin
    #1;  // small delay to avoid zero-delay infinite loop
end
end
// -------------------------------------------------------------------------
    // Interface
    // -------------------------------------------------------------------------
    spi_if dut_if (.clk(clk), .rst_n(rst_n));

    // -------------------------------------------------------------------------
    // MISO loopback — RX should equal TX in all loopback tests
    // -------------------------------------------------------------------------
    assign dut_if.miso = dut_if.mosi;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    spi_master_soc_top dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .addr         (dut_if.addr),
        .wr_en        (dut_if.wr_en),
        .wr_data      (dut_if.wr_data),
        .rd_en        (dut_if.rd_en),
        .rd_data      (dut_if.rd_data),
        .sclk         (dut_if.sclk),
        .mosi         (dut_if.mosi),
        .miso         (dut_if.miso),
        .cs_n         (dut_if.cs_n),
        
        // =====================================================================
        // FIX: Connect the exposed physical FIFO flags to the interface
        // =====================================================================
        .tx_full      (dut_if.tx_full),
        .tx_empty     (dut_if.tx_empty),
        .tx_overflow  (dut_if.tx_overflow),
        .rx_full      (dut_if.rx_full),
        .rx_empty     (dut_if.rx_empty),
        .rx_underflow (dut_if.rx_underflow)
    );
  
  
  bind spi_master_soc_top spi_assertions u_assert (
    .clk          (clk),
    .rst_n        (rst_n),
    .addr         (addr),
    .wr_en        (wr_en),
    .wr_data      (wr_data),
    .rd_en        (rd_en),
    .sclk         (sclk),
    .mosi         (mosi),
    .miso         (miso),
    .cs_n         (cs_n),
    .tx_full      (tx_full),
    .tx_empty     (tx_empty),
    .rx_full      (rx_full),
    .rx_empty     (rx_empty),
    .tx_overflow  (tx_overflow),
    .rx_underflow (rx_underflow),
    .cpol		  (cpol)
);

    // -------------------------------------------------------------------------
    // UVM start
    // -------------------------------------------------------------------------
   initial begin

    uvm_config_db #(virtual spi_if)::set( null, "uvm_test_top.*", "vif",dut_if );

    uvm_config_db #(virtual spi_if)::set(null, "uvm_test_top", "vif",dut_if);

    run_test("spi_random_test");


end

    // -------------------------------------------------------------------------
    // Waveform
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("spi_uvm_wave.vcd");
        $dumpvars(0, tb_spi_uvm);
    end

    // -------------------------------------------------------------------------
    // Simulation timeout
    // -------------------------------------------------------------------------
    initial begin
        #2_000_000_000;
        `uvm_fatal("TB_TOP", "SIMULATION TIMEOUT")
    end

endmodule
