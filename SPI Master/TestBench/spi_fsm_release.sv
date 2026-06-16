`ifndef SPI_FSM_RELEASE_SV
`define SPI_FSM_RELEASE_SV

// =============================================================================
// spi_load_to_idle_seq — fires LOAD->IDLE transition
// Strategy: write CTRL(release=0), write TX, immediately write CTRL(release=1)
// The second CTRL write lands exactly while FSM is in LOAD state
// =============================================================================
class spi_load_to_idle_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_load_to_idle_seq)
    virtual spi_if vif;
    localparam [7:0] ADDR_CTRL = 8'h00;
    localparam [7:0] ADDR_TX   = 8'h08;

    function new(string name = "spi_load_to_idle_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        if (!uvm_config_db#(virtual spi_if)::get(null, get_full_name(), "vif", vif))
            `uvm_fatal("SEQ", "spi_load_to_idle_seq: cannot get vif")

        // Wait for FSM to be in IDLE (cs_n=1) before starting
        begin
            int timeout = 0;
            while (vif.cs_n !== 1'b1) begin
                @(vif.driver_cb); timeout++;
                if (timeout > 500) `uvm_fatal("FSM_ABORT","[LOAD_SEQ] Timeout waiting IDLE")
            end
        end
        repeat(4) @(vif.driver_cb);

        item = spi_seq_item::type_id::create("item");
        assert(item.randomize() with {
            n==1; frame_size==8; clk_div inside{[8:16]}; cs_hold==0; cs_release==0;
        }) else `uvm_fatal("RAND","load_to_idle failed")

        // Step 1: Write CTRL with cs_release=0
        write_reg(ADDR_CTRL, item.ctrl_word());
        repeat(4) @(vif.driver_cb);
        `uvm_info("FSM_ABORT",$sformatf(
            "[LOAD_SEQ] CTRL release=0 written | cs_n=%0b time=%0t",
            vif.cs_n,$time),UVM_NONE)

        // Step 2: Write TX — FSM will move IDLE->LOAD next clock
        write_reg(ADDR_TX, 32'hA5A5A5A5);
        `uvm_info("FSM_ABORT",$sformatf(
            "[LOAD_SEQ] TX written, immediately writing CTRL release=1 | time=%0t",
            $time),UVM_NONE)

        // Step 3: Write CTRL with cs_release=1 IMMEDIATELY — no wait
        // Timeline:
        //   cycle+1: FSM in LOAD  — CTRL write cycle 1 (addr driven)
        //   cycle+2: FSM in LOAD  — CTRL write cycle 2 (wr_en drops, RTL latches)
        //   cycle+3: FSM checks cs_release in LOAD → IDLE
        item.cs_release = 1;
        write_reg(ADDR_CTRL, item.ctrl_word());
        `uvm_info("FSM_ABORT",$sformatf(
            "[LOAD_SEQ] CTRL release=1 write complete | cs_n=%0b time=%0t",
            vif.cs_n,$time),UVM_NONE)

        // Step 4: Settle and check
        repeat(4) @(vif.driver_cb);
        `uvm_info("FSM_ABORT",$sformatf(
            "[LOAD_SEQ] After settle | cs_n=%0b (expect 1) time=%0t",
            vif.cs_n,$time),UVM_NONE)

        if (vif.cs_n !== 1'b1)
            `uvm_error("FSM_ABORT","[LOAD_SEQ] FAIL: LOAD->IDLE did NOT fire")
        else
            `uvm_info("FSM_ABORT","[LOAD_SEQ] PASS: LOAD->IDLE confirmed",UVM_NONE)

        repeat(4) @(vif.driver_cb);
    endtask

    task write_reg(input [7:0] addr, input [31:0] data);
        @(vif.driver_cb);
        vif.driver_cb.addr    <= addr;
        vif.driver_cb.wr_data <= data;
        vif.driver_cb.wr_en   <= 1'b1;
        vif.driver_cb.rd_en   <= 1'b0;
        @(vif.driver_cb);
        vif.driver_cb.wr_en   <= 1'b0;
    endtask

endclass : spi_load_to_idle_seq


// =============================================================================
// spi_start_to_idle_seq — fires START->IDLE transition
// Strategy: write CTRL(release=0), write TX, wait 1 extra cycle, then
// immediately write CTRL(release=1) so it lands while FSM is in START
// =============================================================================
class spi_start_to_idle_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_start_to_idle_seq)
    virtual spi_if vif;
    localparam [7:0] ADDR_CTRL = 8'h00;
    localparam [7:0] ADDR_TX   = 8'h08;

    function new(string name = "spi_start_to_idle_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        if (!uvm_config_db#(virtual spi_if)::get(null, get_full_name(), "vif", vif))
            `uvm_fatal("SEQ", "spi_start_to_idle_seq: cannot get vif")

        // Wait for FSM to be in IDLE (cs_n=1) before starting
        begin
            int timeout = 0;
            while (vif.cs_n !== 1'b1) begin
                @(vif.driver_cb); timeout++;
                if (timeout > 500) `uvm_fatal("FSM_ABORT","[START_SEQ] Timeout waiting IDLE")
            end
        end
        repeat(4) @(vif.driver_cb);

        item = spi_seq_item::type_id::create("item");
        assert(item.randomize() with {
            n==1; frame_size==8; clk_div inside{[8:16]}; cs_hold==0; cs_release==0;
        }) else `uvm_fatal("RAND","start_to_idle failed")

        // Step 1: Write CTRL with cs_release=0
        write_reg(ADDR_CTRL, item.ctrl_word());
        repeat(4) @(vif.driver_cb);
        `uvm_info("FSM_ABORT",$sformatf(
            "[START_SEQ] CTRL release=0 written | cs_n=%0b time=%0t",
            vif.cs_n,$time),UVM_NONE)

        // Step 2: Write TX — FSM will move IDLE->LOAD next clock
        write_reg(ADDR_TX, 32'hB6B6B6B6);
        `uvm_info("FSM_ABORT",$sformatf(
            "[START_SEQ] TX written | time=%0t",$time),UVM_NONE)

        // Step 3: Wait 1 extra cycle so FSM advances through LOAD first
        // Without this wait the CTRL write lands in LOAD (same as load_seq).
        // With this wait:
        //   cycle+1: FSM in LOAD  — we wait here doing nothing
        //   cycle+2: FSM in START — CTRL write cycle 1 (addr driven)
        //   cycle+3: FSM in START — CTRL write cycle 2 (RTL latches cs_release=1)
        //   cycle+4: FSM checks cs_release in START → IDLE
        @(vif.driver_cb);
        `uvm_info("FSM_ABORT",$sformatf(
            "[START_SEQ] +1 wait (LOAD) | cs_n=%0b time=%0t",
            vif.cs_n,$time),UVM_NONE)

        // Step 4: Write CTRL with cs_release=1 IMMEDIATELY — no more waits
        item.cs_release = 1;
        write_reg(ADDR_CTRL, item.ctrl_word());
        `uvm_info("FSM_ABORT",$sformatf(
            "[START_SEQ] CTRL release=1 write complete | cs_n=%0b time=%0t",
            vif.cs_n,$time),UVM_NONE)

        // Step 5: Settle and check
        repeat(4) @(vif.driver_cb);
        `uvm_info("FSM_ABORT",$sformatf(
            "[START_SEQ] After settle | cs_n=%0b (expect 1) time=%0t",
            vif.cs_n,$time),UVM_NONE)

        if (vif.cs_n !== 1'b1)
            `uvm_error("FSM_ABORT","[START_SEQ] FAIL: START->IDLE did NOT fire")
        else
            `uvm_info("FSM_ABORT","[START_SEQ] PASS: START->IDLE confirmed",UVM_NONE)

        repeat(4) @(vif.driver_cb);
    endtask

    task write_reg(input [7:0] addr, input [31:0] data);
        @(vif.driver_cb);
        vif.driver_cb.addr    <= addr;
        vif.driver_cb.wr_data <= data;
        vif.driver_cb.wr_en   <= 1'b1;
        vif.driver_cb.rd_en   <= 1'b0;
        @(vif.driver_cb);
        vif.driver_cb.wr_en   <= 1'b0;
    endtask

endclass : spi_start_to_idle_seq

`endif // SPI_FSM_RELEASE_SV
