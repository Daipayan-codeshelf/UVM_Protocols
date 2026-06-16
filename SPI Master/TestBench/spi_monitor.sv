`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if vif;
    uvm_analysis_port #(spi_seq_item) ap;

    // CTRL shadow
    bit        mon_cpol;
    bit        mon_cpha;
    bit [5:0]  mon_frame_size;
    bit [15:0] mon_clk_div;
    bit        mon_cs_hold;
    bit        mon_cs_release;
    bit        mon_err_clr;

    // NEW: Event latches to catch 1-cycle FIFO flags
    bit        latched_tx_full;
    bit        latched_rx_full;

    localparam [7:0] ADDR_CTRL = 8'h00;
    localparam [7:0] ADDR_STAT = 8'h04;

    function new(string name="spi_monitor", uvm_component parent=null);
        super.new(name, parent);
        ap = new("ap", this);

        mon_cpol = 0;
        mon_cpha = 0;
        mon_frame_size = 8;
        mon_clk_div = 4;
        mon_cs_hold = 0;
        mon_cs_release = 0;
        mon_err_clr = 0;
        
        latched_tx_full = 0;
        latched_rx_full = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Cannot get virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_reg_bus();
            monitor_spi_bus();
            monitor_rx_full_flag();  // FIX: dedicated task — never misses rx_full
        join
    endtask

    // ---------------- CTRL &  LATCH ----------------
    task monitor_reg_bus();
        forever begin
            @(vif.monitor_cb);
            
            // FIX: Latch the momentary full flags on the APB clock
            // so the slower SPI thread doesn't miss them!
            if (vif.monitor_cb.tx_full) latched_tx_full = 1'b1;
            if (vif.monitor_cb.rx_full) latched_rx_full = 1'b1;

            // Track configuration settings sent by the driver
            if (vif.monitor_cb.wr_en &&
                vif.monitor_cb.addr == ADDR_CTRL) begin

                mon_clk_div    = vif.monitor_cb.wr_data[31:16];
                mon_cs_release = vif.monitor_cb.wr_data[10];
                mon_err_clr    = vif.monitor_cb.wr_data[9];
                mon_cs_hold    = vif.monitor_cb.wr_data[8];
                mon_frame_size = vif.monitor_cb.wr_data[7:2];
                mon_cpha       = vif.monitor_cb.wr_data[1];
                mon_cpol       = vif.monitor_cb.wr_data[0];
            end
        end
    endtask

    // ---------------- SPI reconstruction ----------------
    task monitor_spi_bus();
        spi_seq_item item, item_clone;
        bit [31:0] tx_shift, rx_shift;
        int bit_count;
        bit sample_posedge;

        forever begin
            @(negedge vif.cs_n);

            item = spi_seq_item::type_id::create("item");
            item.cpol       = mon_cpol;
            item.cpha       = mon_cpha;
            item.frame_size = mon_frame_size;
            item.clk_div    = mon_clk_div;
            item.cs_hold    = mon_cs_hold;
            item.cs_release = mon_cs_release;
            item.err_clr    = mon_err_clr;

            tx_shift = 0;
            rx_shift = 0;
            bit_count = 0;
            sample_posedge = ~(mon_cpol ^ mon_cpha);

            while (vif.cs_n === 0) begin
                if (sample_posedge)
                    @(posedge vif.sclk or posedge vif.cs_n);
                else
                    @(negedge vif.sclk or posedge vif.cs_n);

                if (vif.cs_n) break;

                tx_shift = {tx_shift[30:0], vif.mosi};
                rx_shift = {rx_shift[30:0], vif.miso};
                bit_count++;

                if (bit_count >= item.frame_size) begin
                    item.tx_data = tx_shift;
                    item.rx_data = rx_shift;

                    item_clone = spi_seq_item::type_id::create("item_clone");
                    item_clone.copy(item);

                    fork
                        automatic spi_seq_item sent_item = item_clone;
                        begin
                            repeat ((sent_item.clk_div * 2) + 4) @(vif.monitor_cb);

                            sent_item.tx_full      = vif.monitor_cb.tx_full;
                            sent_item.tx_empty     = vif.monitor_cb.tx_empty;
                            sent_item.rx_full      = vif.monitor_cb.rx_full;
                            sent_item.rx_empty     = vif.monitor_cb.rx_empty;
                            sent_item.tx_overflow  = vif.monitor_cb.tx_overflow;
                            sent_item.rx_underflow = vif.monitor_cb.rx_underflow;

                            ap.write(sent_item);
                        end
                    join_none

                    tx_shift = 0;
                    rx_shift = 0;
                    bit_count = 0;
                end
            end
        end
    endtask

    // ---------------- DEDICATED RX_FULL WATCHER ----------------
    // This task runs independently of the SPI frame monitor.
    // It watches the APB rx_full signal every clock cycle and
    // immediately publishes a coverage-only item the moment rx_full
    // goes high — before any drain can deassert it.
    //
    // Why this works re the latch didn't:
    //   The SPI frame forks all spawn on cs_n edges and wait
    //   (clk_div*2)+4 cycles before sampling. By then the driver
    //   has already drained RX and rx_full=0. This task has no
    //   such delay — it samples on the very APB cycle rx_full=1.
    task monitor_rx_full_flag();
        spi_seq_item cov_item;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.rx_full) begin
                cov_item = spi_seq_item::type_id::create("rx_full_cov");
                // Snapshot all current flag state into the item
                cov_item.cpol        = mon_cpol;
                cov_item.cpha        = mon_cpha;
                cov_item.frame_size  = mon_frame_size;
                cov_item.clk_div     = mon_clk_div;
                cov_item.cs_hold     = mon_cs_hold;
                cov_item.cs_release  = mon_cs_release;
                cov_item.err_clr     = mon_err_clr;
                cov_item.rx_full     = 1'b1;
                cov_item.tx_full     = vif.monitor_cb.tx_full;
                cov_item.tx_empty    = vif.monitor_cb.tx_empty;
                cov_item.rx_empty    = vif.monitor_cb.rx_empty;
                cov_item.tx_overflow = vif.monitor_cb.tx_overflow;
                cov_item.rx_underflow= vif.monitor_cb.rx_underflow;
                ap.write(cov_item);
                // Wait for rx_full to deassert before re-triggering
                // so we don't flood the analysis port every cycle
                @(vif.monitor_cb iff !vif.monitor_cb.rx_full);
            end
        end
    endtask

endclass

`endif
