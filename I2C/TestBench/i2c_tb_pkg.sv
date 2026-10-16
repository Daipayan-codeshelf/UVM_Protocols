package i2c_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "i2c_seq_item.sv"
	`include "i2c_sequencer.sv"
    `include "i2c_master_driver.sv"
    `include "i2c_master_monitor.sv"
    `include "i2c_master_agent.sv"
    `include "i2c_scoreboard.sv"
    `include "i2c_coverage.sv"
    `include "i2c_env.sv"
    `include "i2c_sequences.sv"
    `include "i2c_test.sv"

endpackage
