package axi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ============================================================
  // Sequence item
  // ============================================================
  `include "axi_seq_item.sv"

  // ============================================================
  // Master agent components
  // ============================================================
  `include "axi_master_driver.sv"
  `include "axi_master_sequencer.sv"
  `include "axi_master_monitor.sv"
  `include "axi_master_agent.sv"

  // ============================================================
  // Scoreboard / Functional Coverage / Environment
  // ============================================================
  `include "axi_scoreboard.sv"
  `include "axi_coverage.sv"
  `include "axi_env.sv"

  // ============================================================
  // Grouped Sequences
  // ============================================================
  `include "seq_burst.sv"
  `include "seq_error.sv"
  `include "seq_slave.sv"
  `include "seq_protection.sv"
  `include "seq_wstrb.sv"
  `include "seq_fifo_stress.sv"
  `include "seq_id.sv"

  // ============================================================
  // Grouped Tests
  // ============================================================
  `include "test_burst.sv"
  `include "test_error.sv"
  `include "test_slave.sv"
  `include "test_protection.sv"
  `include "test_wstrb.sv"
  `include "test_fifo_stress.sv"
  `include "test_id.sv"
  `include "test_all.sv"

endpackage
