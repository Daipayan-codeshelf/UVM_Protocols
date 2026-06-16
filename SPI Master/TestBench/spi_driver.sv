`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV
class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)
    virtual spi_if vif;
    localparam [7:0] ADDR_CTRL = 8'h00;
    localparam [7:0] ADDR_STAT = 8'h04;
    localparam [7:0] ADDR_TX   = 8'h08;
    localparam [7:0] ADDR_RX   = 8'h0C;
    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Cannot get virtual interface from config_db")
    endfunction
    task run_phase(uvm_phase phase);
        bus_idle();
        forever begin
            spi_seq_item item;
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask
    task drive_item(spi_seq_item item);
        bit [31:0] stat_val;
        bit [31:0] running_tx;
        // Frames actually transferred = min(n, 16) because FIFO depth = 16
        int unsigned frames_xfr;


        // FIX 1: Correct SPI timing formula.
        //
        // Each SPI bit takes (2 * clk_div)  cycles:
        //   clk_div  cycles for the first half-period (SCLK low or high),
        //   clk_div  cycles for the second half-period.
        // One complete frame = frame_size bits × 2 × clk_div  cycles,
        // plus CS assert/deassert overhead (~10 cycles per frame).
        //


        int unsigned cycles_per_frame;
        int unsigned total_wait;
        `uvm_info("DRV", $sformatf(
            "Burst n=%0d cpol=%0d cpha=%0d fs=%0d div=%0d hold=%0d rel=%0d tx=0x%08h",
            item.n, item.cpol, item.cpha, item.frame_size,
            item.clk_div, item.cs_hold, item.cs_release,
            item.tx_data), UVM_MEDIUM)
        frames_xfr       = (int'(item.n) > 16) ? 16 : int'(item.n);

        // 2 half-periods per bit × clk_div A cycles per half-period × frame_size bits
        // + 10  cycles overhead for CS setup/hold per frame
        cycles_per_frame = (2 * int'(item.clk_div) * int'(item.frame_size)) + 10;
        total_wait       = frames_xfr * cycles_per_frame + 64;

        write_reg(ADDR_CTRL, item.ctrl_word());
        repeat(4) @(vif.driver_cb);
// if (item.cs_release && item.release_after_cycles > 0) begin
  //      repeat(item.release_after_cycles) @(vif.driver_cb);
    //    write_reg(ADDR_CTRL, item.ctrl_word());  // cs_release=1 already in ctrl_word
      //  repeat(2) @(vif.driver_cb);
        // clear release so normal flow doesn't re-assert it
      //  write_reg(ADDR_CTRL, item.ctrl_word_no_release());
        //return;  // transaction aborted, skip TX writes
   // end
        running_tx = item.tx_data;
        for (int i = 0; i < int'(item.n); i++) begin
            write_reg(ADDR_TX, running_tx);
            running_tx++;
        end
        read_reg(ADDR_STAT, stat_val);
        `uvm_info("DRV", $sformatf("STAT after TX burst: 0x%08h", stat_val), UVM_HIGH)
        // Wait for all SPI frames to complete before draining RX.
        repeat(total_wait) @(vif.driver_cb);

        // FIX 2: Drain only as many RX entries as actually completed.
        //
        // With n > 16 the FIFO holds at most 16 entries; reading n times
        // causes (n - 16) reads from an empty FIFO which returns X and
        // makes rx_data_out show xxxxxxxx in the waveform.
        // Only read frames_xfr (= min(n, 16)) entries.
        for (int i = 0; i < int'(frames_xfr); i++) begin
     bit [31:0] rx_val;
            read_reg(ADDR_RX, rx_val);
            if (i == 0) item.rx_data = rx_val;
        end
        read_reg(ADDR_STAT, stat_val);
        `uvm_info("DRV", $sformatf("STAT after RX drain: 0x%08h", stat_val), UVM_HIGH)

write_reg(8'hFF, 32'hDEADBEEF);  // invalid → hits default
read_reg(8'hAA, stat_val);       // invalid read

    endtask
    task write_reg(input [7:0] a, input [31:0] d);
        @(vif.driver_cb);
        vif.driver_cb.addr    <= a;
        vif.driver_cb.wr_data <= d;
        vif.driver_cb.wr_en   <= 1'b1;
        vif.driver_cb.rd_en   <= 1'b0;
        @(vif.driver_cb);
        vif.driver_cb.wr_en   <= 1'b0;
    endtask
    task read_reg(input [7:0] a, output [31:0] d);
        @(vif.driver_cb);
        vif.driver_cb.addr  <= a;
        vif.driver_cb.rd_en <= 1'b1;
        vif.driver_cb.wr_en <= 1'b0;
        @(vif.driver_cb);
        vif.driver_cb.rd_en <= 1'b0;
        @(vif.driver_cb);
        d = vif.driver_cb.rd_data;
    endtask
    task bus_idle();
        @(vif.driver_cb);
        vif.driver_cb.addr    <= 8'h00;
        vif.driver_cb.wr_en   <= 1'b0;
        vif.driver_cb.wr_data <= 32'h0;
        vif.driver_cb.rd_en   <= 1'b0;
        vif.driver_cb.miso    <= 1'b0;
    endtask
endclass : spi_driver
`endif
                  
