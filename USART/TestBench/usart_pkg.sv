`ifndef USART_PKG_SV
`define USART_PKG_SV

package usart_pkg;

   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////
   // Transactions
   //////////////////////////////////////

   `include "apb_seq_item.sv"
   `include "usart_seq_item.sv"

   //////////////////////////////////////
   // Scoreboard
   //////////////////////////////////////

   `include "usart_scoreboard.sv"

   //////////////////////////////////////
   // APB Agent
   //////////////////////////////////////

   `include "apb_sequencer.sv"
   `include "apb_driver.sv"
   `include "apb_monitor.sv"
   `include "apb_agent.sv"

   //////////////////////////////////////
   // USART Agent
   //////////////////////////////////////

   `include "usart_monitor.sv"
   `include "usart_agent.sv"

   //////////////////////////////////////
   // Environment
   //////////////////////////////////////
   `include "usart_coverage.sv"
   `include "env.sv"

   //////////////////////////////////////
   // Sequences
   //////////////////////////////////////
   `include "apb_base_seq.sv"
   `include "sequences.sv"
   `include "multi_byte_seq.sv"
   `include "reg_readback_seq.sv"
   `include "fifo_overflow_seq.sv"
   `include "fifo_underflow_seq.sv"
   `include "rx_overflow_seq.sv"
   `include "reset_seq.sv"
   `include "data_len_seq.sv"
   `include "data_len_5_seq.sv"
   `include "parity_even_seq.sv"
   `include "parity_odd_seq.sv"
   `include "sync_mode_seq.sv"
   `include "random_cfg_seq.sv"
   `include "stop_bit_seq.sv"
   `include "csr_stress_seq.sv"


   //////////////////////////////////////
   // Tests
   //////////////////////////////////////

   `include "test.sv"
   `include "multi_byte_test.sv"
   `include "reg_readback_test.sv"
   `include "fifo_overflow_test.sv"
   `include "fifo_underflow_test.sv"
   `include "rx_overflow_test.sv"
   `include "reset_test.sv"
   `include "data_len_test.sv"
   `include "data_len_5_test.sv"
   `include "parity_even_test.sv"
   `include "parity_odd_test.sv"
   `include "sync_mode_test.sv"
   `include "random_cfg_test.sv"
   `include "stop_bit_test.sv"
   `include "csr_stress_test.sv"
   `include "usart_regression_test.sv"



endpackage

`endif
