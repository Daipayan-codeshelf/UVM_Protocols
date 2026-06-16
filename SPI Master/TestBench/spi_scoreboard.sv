`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV
// =============================================================================
// FILE : spi_scoreboard.sv
//
// Checks per completed SPI frame:
//   1. Loopback integrity  : (rx_data & mask) == (tx_data & mask)
//   2. Frame size valid    : frame_size in {4,8,16,24,32}
//   3. Mode bits valid     : cpol, cpha in {0,1}
//   4. CS protocol legality: cs_release=1 only when cs_hold=1
//   5. FIFO overflow flag  : if tx_overflow=1, log a warning (not a failure —
//                            overflow is an expected DUT status, not a bug,
//                            but it should be visible in the summary)
// =============================================================================

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) analysis_export;

    int pass_count;
    int fail_count;
    int overflow_count;    // informational
    int underflow_count;   // informational
    int err_clr_count;
    function new(string name = "spi_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        pass_count      = 0;
        fail_count      = 0;
        overflow_count  = 0;
        underflow_count = 0;
      err_clr_count = 0;
    endfunction

    function void write(spi_seq_item item);
        bit        pass = 1;
        bit [31:0] frame_mask;
        bit [31:0] expected_rx;

        // Active-bit mask
        if (item.frame_size == 6'd32)
            frame_mask = 32'hFFFF_FFFF;
        else
            frame_mask = (32'h1 << item.frame_size) - 1;

        expected_rx = item.tx_data & frame_mask;

        // -- CHECK 1: loopback data integrity --
        if ((item.rx_data & frame_mask) !== expected_rx) begin
            `uvm_error("SB", $sformatf(
                "[LOOPBACK FAIL] mode=%0d%0d fs=%0d | EXP=0x%08h GOT=0x%08h",
                item.cpol, item.cpha, item.frame_size,
                expected_rx, item.rx_data & frame_mask))
            pass = 0;
        end

        // -- CHECK 2: frame size valid --
        if (!(item.frame_size inside {6'd4, 6'd8, 6'd16, 6'd24, 6'd32})) begin
            `uvm_error("SB", $sformatf(
                "[FRAME SIZE FAIL] frame_size=%0d not in {4,8,16,24,32}",
                item.frame_size))
            pass = 0;
        end

        // -- CHECK 3: mode bits valid --
        if (!(item.cpol inside {0,1}) || !(item.cpha inside {0,1})) begin
            `uvm_error("SB", "[MODE FAIL] cpol or cpha out of range")
            pass = 0;
        end

        // -- CHECK 4: cs_release only legal when cs_hold is asserted --
        if (item.cs_release === 1'b1 && item.cs_hold === 1'b0) begin
            `uvm_error("SB", $sformatf(
                "[CS PROTOCOL FAIL] cs_release=1 but cs_hold=0 — illegal combination | %s",
                item.convert2string()))
            pass = 0;
        end

        // -- INFO 5: FIFO overflow / underflow observation --
        if (item.tx_overflow) begin
            overflow_count++;
        end
        if (item.rx_underflow) begin
            underflow_count++;
            
        end

        if (pass) begin
            pass_count++;
            `uvm_info("SB", $sformatf(
                "[PASS #%0d] mode=%0d%0d fs=%0d hold=%0d rel=%0d tx=0x%08h rx=0x%08h",
                pass_count, item.cpol, item.cpha, item.frame_size,
                item.cs_hold, item.cs_release,
                item.tx_data & frame_mask, item.rx_data & frame_mask),
                UVM_MEDIUM)
        end 
  if (item.err_clr) begin
    err_clr_count++;
   
end

if (!pass)
    fail_count++;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", "==============================================", UVM_NONE)
        `uvm_info("SB", "          SCOREBOARD SUMMARY",                  UVM_NONE)
        `uvm_info("SB", $sformatf("  PASS      : %0d", pass_count),      UVM_NONE)
        `uvm_info("SB", $sformatf("  FAIL      : %0d", fail_count),      UVM_NONE)
//         `uvm_info("SB", $sformatf("  TX OVF    : %0d (informational)",
//                                    overflow_count),                       UVM_NONE)
//         `uvm_info("SB", $sformatf("  RX UDF    : %0d (informational)",
//                                    underflow_count),                      UVM_NONE)
//       `uvm_info("SB",
//     $sformatf("  ERR_CLR   : %0d",
//               err_clr_count),
//     UVM_NONE)
        if (fail_count == 0)
            `uvm_info("SB",  "  RESULT : ALL CHECKS PASSED",             UVM_NONE)
        else
            `uvm_error("SB", $sformatf("  RESULT : %0d FAILURES", fail_count))
        `uvm_info("SB", "==============================================", UVM_NONE)
    endfunction

endclass : spi_scoreboard
`endif // SPI_SCOREBOARD_SV
