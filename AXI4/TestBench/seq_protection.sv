class seq_protection extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_protection)

  function new(string name = "seq_protection");
    super.new(name);
  endfunction

  task body();

    axi_seq_item req;

    // ============================================================
    // PROTECTION CASE 1:
    // Protected / instruction write should be blocked
    // AWPROT = 3'b100
    // Expected BRESP = SLVERR
    // ============================================================

    req = axi_seq_item::type_id::create("prot_blocked_write");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'h1;
    req.addr  = 32'h0000_0184;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b100;

    req.expected_bresp = 2'b10;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b0;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;
    req.expected_read_enable = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hDEAD_BEEF;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_PROTECTION",
              "CASE 1 DONE: Protected write with AWPROT=100 -> SLVERR",
              UVM_LOW)

    // ============================================================
    // PROTECTION CASE 2:
    // Setup original data normally
    // ============================================================

    req = axi_seq_item::type_id::create("prot_original_write");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h2;
    req.addr  = 32'h0000_0188;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;
    req.expected_read_enable = 1'b0;

    req.data = new[1];
    req.data[0] = 32'h1234_5678;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_PROTECTION",
              "CASE 2 DONE: Setup normal write/read original data -> OKAY",
              UVM_LOW)

    // ============================================================
    // PROTECTION CASE 3:
    // Attempt protected overwrite
    // Expected BRESP = SLVERR
    // ============================================================

    req = axi_seq_item::type_id::create("prot_overwrite_blocked");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'h3;
    req.addr  = 32'h0000_0188;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b100;

    req.expected_bresp = 2'b10;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b0;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;
    req.expected_read_enable = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hDEAD_BEEF;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_PROTECTION",
              "CASE 3 DONE: Protected overwrite attempt -> SLVERR",
              UVM_LOW)

    // ============================================================
    // PROTECTION CASE 4:
    // Read back and verify original data remains
    // ============================================================

    req = axi_seq_item::type_id::create("prot_readback_original");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = 4'h4;
    req.addr  = 32'h0000_0188;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.expected_read_enable = 1'b1;
    req.expected_rdata = new[1];
    req.expected_rdata[0] = 32'h1234_5678;

    finish_item(req);

    `uvm_info("SEQ_PROTECTION",
              "CASE 4 DONE: Readback confirms protected write did not overwrite original data",
              UVM_LOW)

  endtask

endclass
