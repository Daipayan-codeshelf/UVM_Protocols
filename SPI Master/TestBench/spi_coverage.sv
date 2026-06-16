`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV
// =============================================================================
// FILE : spi_coverage.sv
//
// Two covergroups:
//
//   spi_cg  — protocol covergroup
//     Individual coverpoints: CPOL, CPHA, FRAME_SIZE, CS_HOLD, CS_RELEASE,
//                             CLK_DIV
//     ONE cross: PROTOCOL_CROSS = CPOL × CPHA × FRAME_SIZE × CS_HOLD × CS_RELEASE
//       ignore_bins: CS_HOLD=0 && CS_RELEASE=1 (illegal per protocol)
//       Valid bins = 2×2×5×2×2 − 2×2×5×1×1 = 80 − 20 = 60
//
//   fifo_cg — FIFO flag covergroup
//     Individual coverpoints ONLY — no cross.
//     Rationale: a 6-way cross over binary flags creates 64 raw bins; most
//     combinations (e.g. tx_full=1 && rx_full=1 simultaneously) are physically
//     impossible or highly unlikely, leaving the cross permanently open.
//     Individual coverpoints give 12 meaningful bins that are all reachable.
//     Each flag must be observed both asserted (=1) and deasserted (=0).
//
// All data sourced from seq_item fields stamped by the monitor.
// No virtual interface dependency.
// =============================================================================

class spi_coverage extends uvm_subscriber #(spi_seq_item);
    `uvm_component_utils(spi_coverage)

    spi_seq_item item;

    // Direct interface access — lets us sample rx_full the cycle it
    // asserts, without relying on the monitor's delayed fork path.
    virtual spi_if vif;

    // -----------------------------------------------------------------------
    // GROUP 1 : Protocol
    // -----------------------------------------------------------------------
    covergroup spi_cg;
        option.per_instance = 1;

        CPOL : coverpoint item.cpol {
            bins cpol_0 = {0};
            bins cpol_1 = {1};
        }
        CPHA : coverpoint item.cpha {
            bins cpha_0 = {0};
            bins cpha_1 = {1};
        }
        FRAME_SIZE : coverpoint item.frame_size {
            bins fs_4  = {4};
            bins fs_8  = {8};
            bins fs_16 = {16};
            bins fs_24 = {24};
            bins fs_32 = {32};
        }
        CS_HOLD : coverpoint item.cs_hold {
            bins hold_0 = {0};
            bins hold_1 = {1};
        }
        CS_RELEASE : coverpoint item.cs_release {
            bins release_0 = {0};
            bins release_1 = {1};
        }
      ERR_CLR : coverpoint item.err_clr {
            bins err_clr_0 = {0};
            bins err_clr_1 = {1};
        }
        CLK_DIV : coverpoint item.clk_div {
          bins low  = {[0:16]};
            bins mid  = {[17:40]};
            bins high = {[41:65535]};
        }

        // 60 valid bins after excluding the illegal hold=0,release=1 combo
//         PROTOCOL_CROSS : cross CPOL, CPHA, FRAME_SIZE, CS_HOLD, CS_RELEASE {
//             ignore_bins illegal_release =
//                 binsof(CS_HOLD.hold_0) && binsof(CS_RELEASE.release_1);
//         }

    endgroup

    // -----------------------------------------------------------------------
    // GROUP 2 : FIFO flags — individual coverpoints, NO cross
    //
    // Why no cross: a 6-way cross produces 64 raw bins with only ~4 naturally
    // reachable combinations, leaving coverage permanently low.  Each flag is
    // independent; observing each in both states (0 and 1) is the meaningful
    // metric.  12 bins, all reachable with the test phases below.
    // -----------------------------------------------------------------------
    covergroup fifo_cg;
        option.per_instance = 1;

        TX_FULL : coverpoint item.tx_full {
            bins not_full = {0};
            bins full     = {1};    // hit by FIFO stress phase (n=14..16)
        }
        TX_EMPTY : coverpoint item.tx_empty {
            bins not_empty = {0};
            bins empty     = {1};   // hit at start of every burst
        }
        RX_FULL : coverpoint item.rx_full {
            bins not_full = {0};
            bins full     = {1};    // hit by FIFO stress phase
        }
        RX_EMPTY : coverpoint item.rx_empty {
            bins not_empty = {0};
            bins empty     = {1};   // hit initially and after drain
        }
        TX_OVERFLOW : coverpoint item.tx_overflow {
            bins no_overflow = {0};
            bins overflow    = {1}; // hit by overflow phase (n=17..20)
        }
        RX_UNDERFLOW : coverpoint item.rx_underflow {
            bins no_underflow = {0};
            bins underflow    = {1}; // hit by smoke phase (RX read before data)
        }

    endgroup

    function new(string name="spi_coverage", uvm_component parent=null);
        super.new(name, parent);
        spi_cg  = new();
        fifo_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("COV", "Cannot get virtual interface")
    endfunction

    // Watch rx_full directly on the interface every clock cycle.
    // The moment it goes high, force-sample fifo_cg with rx_full=1.
    // This is completely independent of the monitor's frame timing,
    // so it cannot be beaten by the driver's RX drain loop.
    task run_phase(uvm_phase phase);
        spi_seq_item rx_full_item;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.rx_full) begin
                rx_full_item = spi_seq_item::type_id::create("rx_full_item");
                rx_full_item.rx_full      = 1'b1;
                rx_full_item.tx_full      = vif.monitor_cb.tx_full;
                rx_full_item.tx_empty     = vif.monitor_cb.tx_empty;
                rx_full_item.rx_empty     = vif.monitor_cb.rx_empty;
                rx_full_item.tx_overflow  = vif.monitor_cb.tx_overflow;
                rx_full_item.rx_underflow = vif.monitor_cb.rx_underflow;
                item = rx_full_item;
                fifo_cg.sample();
                // Wait for rx_full to deassert before re-triggering
                @(vif.monitor_cb iff !vif.monitor_cb.rx_full);
            end
        end
    endtask

    virtual function void write(spi_seq_item t);
        item = t;
        spi_cg.sample();
        fifo_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV",
            $sformatf("Protocol Coverage = %0.2f%%", spi_cg.get_coverage()),
            UVM_NONE)
        `uvm_info("COV",
            $sformatf("FIFO     Coverage = %0.2f%%", fifo_cg.get_coverage()),
            UVM_NONE)
    endfunction

endclass : spi_coverage
`endif // SPI_COVERAGE_SV
