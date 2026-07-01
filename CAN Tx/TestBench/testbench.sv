///// tb_top  //////
`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
 
// TB Components 
`include "can_interface.sv"
`include "can_seq_item.sv"
`include "can_seqncr.sv"
`include "can_driver.sv"
`include "can_monitor.sv"
`include "can_scb.sv"
`include "can_agent.sv"
`include "can_covergae.sv"
`include "can_env.sv"
`include "can_base_seq.sv"
`include "can_sequences.sv"
`include "can_base_test.sv"
`include "can_tests.sv"


module tb_top;

    localparam integer BTU_BIT_TICKS  = 20;
    localparam integer BTU_SAMPLE_TAP = (BTU_BIT_TICKS*4)/5;

    // Clock & Reset
    logic clk;
    logic reset_n;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  
    end

    initial begin
        reset_n = 1'b0;
        repeat (8) @(posedge clk);
        reset_n = 1'b1;
    end

    // Interface 
    can_if #(
        .BTU_BIT_TICKS  (BTU_BIT_TICKS),
        .BTU_SAMPLE_TAP (BTU_SAMPLE_TAP)
    ) can_vif (
        .clk     (clk),
        .reset_n (reset_n)
    );

    // Wire-AND loopback
    assign can_vif.can_rx_i = can_vif.can_tx_o;

    // DUT
    can_ctrl_top #(
        .BTU_BIT_TICKS  (BTU_BIT_TICKS),
        .BTU_SAMPLE_TAP (BTU_SAMPLE_TAP),
        .CRC_OUT_INVERT (1'b0),
        .CRC_SEED       (15'h7FFF)
    ) dut (
        .clk               (clk),
        .reset_n           (reset_n),

        .can_rx_i          (can_vif.can_rx_i),
        .can_tx_o          (can_vif.can_tx_o),

        .tx_start          (can_vif.tx_start),
        .tx_id             (can_vif.tx_id),
        .tx_dlc            (can_vif.tx_dlc),
        .tx_data           (can_vif.tx_data),

        .ack_req           (can_vif.ack_req),

        .tx_done           (can_vif.tx_done),
        .tx_no_ack         (can_vif.tx_no_ack),
        .arb_lost          (can_vif.arb_lost),
        .tx_error          (can_vif.tx_error),

        .bit_tick          (can_vif.bit_tick),
        .sample_point      (can_vif.sample_point),
        .sof_detect        (can_vif.sof_detect),
        .hard_resync       (can_vif.hard_resync),
        .bus_idle          (can_vif.bus_idle),
        .intermission_done (can_vif.intermission_done),
        .tx_crc            (can_vif.tx_crc)
    );

    // UVM config_db + run 
    initial begin
        uvm_config_db #(virtual can_if)::set(null, "*", "vif", can_vif);

        $dumpfile("waves_can_uvm.vcd");
        $dumpvars(0, tb_top);

        // Select test
      //run_test("can_crc_tc_01_test");
      //run_test("can_fs_tc_05_test");
      //run_test("can_fs_tc_01_test");
      //run_test("can_idle_tc_test");
      run_test("can_regression_test");
    end

endmodule
