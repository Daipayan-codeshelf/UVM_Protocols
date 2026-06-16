`include "uvm_macros.svh"
import uvm_pkg::*;


module spi_assertions (
    input logic        clk,
    input logic        rst_n,
    input logic [7:0]  addr,
    input logic        wr_en,
    input logic [31:0] wr_data,
    input logic        rd_en,
    input logic        sclk,
    input logic        mosi,
    input logic        miso,
    input logic        cs_n,
    input logic        tx_full,
    input logic        tx_empty,
    input logic        rx_full,
    input logic        rx_empty,
    input logic        tx_overflow,
    input logic        rx_underflow,
  	input logic		   cpol
);

// ---------------------------------------------------------------------------
// A1 : TX FIFO full/empty are mutually exclusive
//
// WHY: A FIFO cannot be both full and empty at the same time. If both flags
// assert together it means the FIFO depth counter or the flag logic is broken.
// This is a cheap, always-on sanity check that catches subtle RTL bugs in
// the pointer/flag generation logic.
// ---------------------------------------------------------------------------
property p_tx_fifo_mutex;
    @(posedge clk) disable iff (!rst_n)
    not (tx_full && tx_empty);
endproperty
A1_TX_FIFO_MUTEX : assert property (p_tx_fifo_mutex)
    else `uvm_error("ASSERT", "A1 FAIL: tx_full and tx_empty both asserted simultaneously")

// ---------------------------------------------------------------------------
// A2 : RX FIFO full/empty are mutually exclusive
//
// WHY: Same invariant as A1 applied to the RX side. Because the two FIFOs
// are independent, they need separate assertions — a bug in the RX pointer
// would not be caught by A1.
// ---------------------------------------------------------------------------
property p_rx_fifo_mutex;
    @(posedge clk) disable iff (!rst_n)
    not (rx_full && rx_empty);
endproperty
A2_RX_FIFO_MUTEX : assert property (p_rx_fifo_mutex)
    else `uvm_error("ASSERT", "A2 FAIL: rx_full and rx_empty both asserted simultaneously")


// ---------------------------------------------------------------------------
// A3 : Register bus must never assert wr_en and rd_en simultaneously
//
// WHY: Your APB-like register bus uses separate wr_en / rd_en strobes.
// Driving both at the same time is undefined — the DUT may write garbage
// into a register while returning wrong rd_data. The driver never does
// this intentionally, but glitches from bad clocking-block timing or a
// sequence bug can cause it. This catches those races immediately at the
// source rather than causing a mysterious scoreboard mismatch later.
// ---------------------------------------------------------------------------
property p_no_simultaneous_rw;
    @(posedge clk) disable iff (!rst_n)
    not (wr_en && rd_en);
endproperty
A3_BUS_MUTEX : assert property (p_no_simultaneous_rw)
    else `uvm_error("ASSERT", "A4 FAIL: wr_en and rd_en asserted on the same cycle")

// ---------------------------------------------------------------------------
// A4 : tx_overflow must only rise when TX FIFO was full in the same or
//      the immediately preceding cycle
//
// WHY: tx_overflow is a sticky error flag that the DUT sets when software
// writes to a full TX FIFO. If it ever asserts without tx_full having
// been high nearby, either the overflow logic is firing spuriously or the
// full flag is being cleared too early. This correlates the error flag
// back to its root cause signal.
//
// NOTE: we check $past(tx_full, 1) because the overflow flag may be
// registered one cycle after the bad write lands. Widen to ||$past(...,2)
// if your RTL has an extra pipeline stage.
// ---------------------------------------------------------------------------
property p_overflow_requires_full;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_overflow) |-> (tx_full || $past(tx_full, 1));
endproperty
A4_OVERFLOW_CAUSE : assert property (p_overflow_requires_full)
    else `uvm_error("ASSERT", "A5 FAIL: tx_overflow rose without tx_full being seen")

// ---------------------------------------------------------------------------
// A5 : CS_N must deassert (go high) within a bounded window after reset
//
// WHY: After rst_n deasserts, the SPI master must immediately return to
// idle with CS_N=1. If CS_N is ever left low through reset the slave
// device will remain selected indefinitely and the next transaction will
// be corrupted. The ##[0:8] window allows a few clock cycles for the
// DUT's output flops to settle after the synchronous reset.
// ---------------------------------------------------------------------------
property p_cs_idle_after_reset;
    @(posedge clk)
    $rose(rst_n) |-> ##[0:8] cs_n;
endproperty
A5_RESET_CS_IDLE : assert property (p_cs_idle_after_reset)
    else `uvm_error("ASSERT", "A6 FAIL: CS_N did not deassert within 8 cycles of reset release")

     // ---------------------------------------------------------------------------
// A6- SPI must be quiet when CS_N is high:
// ---------------------------------------------------------------------------
property p_sclk_idle;
    @(posedge clk) disable iff (!rst_n)
    // If CS_N is high, SCLK must either hold its current value ($stable),
    // OR, if it does transition, its new value MUST match the CPOL configuration.
    cs_n |-> $stable(sclk) || (sclk == cpol); 
endproperty

A6_SCLK_IDLE : assert property (p_sclk_idle)
    else `uvm_error("ASSERT", "A6 FAIL: SCLK toggled illegally while CS_N was high")
      
      //A7 - Same as A4 but for the RX
	
      property p_underflow_requires_empty;
    @(posedge clk) disable iff (!rst_n)
    $rose(rx_underflow) |-> (rx_empty || $past(rx_empty, 1));
endproperty
    A7_UNDERFLOW_CAUSE : assert property (p_underflow_requires_empty)
      else `uvm_error("ASSERT", "A5 FAIL: rx_underflow rose without rx_empty being seen")
      
        
// ---------------------------------------------------------------------------
// COVER properties — not failures; used to confirm interesting states
// are actually reached during simulation (complement your covergroups).
// ---------------------------------------------------------------------------

// Confirm a back-to-back transaction sequence occurs (CS toggling)
COV_CS_TOGGLE : cover property (
    @(posedge clk) disable iff (!rst_n)
    $fell(cs_n) ##[1:$] $rose(cs_n) ##[1:$] $fell(cs_n)
);

// Confirm TX FIFO fills to full during simulation
COV_TX_FULL_SEEN : cover property (
    @(posedge clk) disable iff (!rst_n)
    tx_full
);

// Confirm RX FIFO fills to full during simulation
COV_RX_FULL_SEEN : cover property (
    @(posedge clk) disable iff (!rst_n)
    rx_full
);

endmodule : spi_assertions
