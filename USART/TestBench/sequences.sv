class basic_seq extends apb_base_seq;
    `uvm_object_utils(basic_seq)

  
    function new(string name="basic_seq");
        super.new(name);
    endfunction

    // ─── helper: write ────────────────────────────────────
    task write_reg(input [7:0] addr, input [31:0] data);
        apb_seq_item tr;
        tr = apb_seq_item::type_id::create("tr");
        start_item(tr);
        tr.pwrite = 1'b1;
        tr.paddr  = addr;
        tr.pwdata = data;
        finish_item(tr);
    endtask

    // ─── helper: read ─────────────────────────────────────
    task read_reg(input [7:0] addr, output [31:0] data);
        apb_seq_item tr;
        tr = apb_seq_item::type_id::create("tr");
        start_item(tr);
        tr.pwrite = 1'b0;     // read
        tr.paddr  = addr;
        tr.pwdata = 32'd0;
        finish_item(tr);
        data = tr.prdata;     // driver fills this before item_done()
    endtask

    // ─── body ─────────────────────────────────────────────
    task body();
        logic [31:0] rdata;

        // --- Config ---
        write_reg(8'h00, 32'h00000006);   // CTRL  : async, 8N1
        write_reg(8'h04, 32'h00000036);   // BAUD  : div=54

        // --- Send byte ---
        write_reg(8'h08, 32'h000000A5);   // TXDATA: 0xA5

        // --- Wait for TX→RX to complete ---
        // baud_div=54, 16x oversample, 10-bit frame (8N1)
        // 54 * 16 * 10 = 8640 clocks minimum, add margin
        #200000;

        // --- Read RXDATA ---
        read_reg(8'h0C, rdata);
        `uvm_info("SEQ",
            $sformatf("RXDATA = 0x%0h (expected=0xA5)", rdata),
            UVM_LOW)

        // --- Read STATUS ---
        read_reg(8'h10, rdata);
        `uvm_info("SEQ",
            $sformatf("STATUS = 0x%0h", rdata),
            UVM_LOW)

    endtask

endclass
