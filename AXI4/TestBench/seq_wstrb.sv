class seq_wstrb extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_wstrb)

  function new(string name = "seq_wstrb");
    super.new(name);
  endfunction

  task body();

    axi_seq_item req;

    // ============================================================
    // WSTRB SETUP:
    // Write known base data to memory.
    //
    // This is not counted as a WSTRB testcase.
    //
    // ADDR  = 0x0000_0300
    // DATA  = 0xAAAA_BBBB
    // WSTRB = 4'b1111
    // ============================================================

    req = axi_seq_item::type_id::create("wstrb_setup_base_write");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h1;
    req.addr  = 32'h0000_0300;
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
    req.data[0] = 32'hAAAA_BBBB;

    req.wstrb = new[1];
    req.wstrb[0] = 4'b1111;

    finish_item(req);

    `uvm_info("SEQ_WSTRB",
              "SETUP DONE: Base write/read DATA=0xAAAA_BBBB WSTRB=1111",
              UVM_LOW)

    // ============================================================
    // WSTRB CASE 1A:
    // Partial byte write
    //
    // Base data      = 0xAAAA_BBBB
    // Write data     = 0x1122_3344
    // WSTRB          = 4'b0101
    //
    // Little-endian byte-lane mapping:
    // byte0 updates: 0xBB -> 0x44
    // byte1 remains: 0xBB
    // byte2 updates: 0xAA -> 0x22
    // byte3 remains: 0xAA
    //
    // Expected final = 0xAA22_BB44
    // ============================================================

    req = axi_seq_item::type_id::create("wstrb_partial_write");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'h2;
    req.addr  = 32'h0000_0300;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    // Disable compare on WRITE_ONLY partial write.
    // We will compare using READ_ONLY expected_rdata in CASE 1B.
    req.compare_enable = 1'b0;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;
    req.expected_read_enable = 1'b0;

    req.data = new[1];
    req.data[0] = 32'h1122_3344;

    req.wstrb = new[1];
    req.wstrb[0] = 4'b0101;

    finish_item(req);

    `uvm_info("SEQ_WSTRB",
              "CASE 1A DONE: Partial byte write WSTRB=0101",
              UVM_LOW)

    // ============================================================
    // WSTRB CASE 1B:
    // Readback after partial write
    //
    // Expected DATA = 0xAA22_BB44
    // ============================================================

    req = axi_seq_item::type_id::create("wstrb_partial_readback");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = 4'h3;
    req.addr  = 32'h0000_0300;
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
    req.expected_rdata[0] = 32'hAA22_BB44;

    finish_item(req);

    `uvm_info("SEQ_WSTRB",
              "CASE 1B DONE: Partial write readback matched expected 0xAA22_BB44",
              UVM_LOW)

    // ============================================================
    // WSTRB CASE 2A:
    // No-byte write
    //
    // Current memory = 0xAA22_BB44
    // Write data     = 0xDEAD_BEEF
    // WSTRB          = 4'b0000
    //
    // Expected memory should remain unchanged.
    // ============================================================

    req = axi_seq_item::type_id::create("wstrb_no_byte_write");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'h4;
    req.addr  = 32'h0000_0300;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b0;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;
    req.expected_read_enable = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hDEAD_BEEF;

    req.wstrb = new[1];
    req.wstrb[0] = 4'b0000;

    finish_item(req);

    `uvm_info("SEQ_WSTRB",
              "CASE 2A DONE: No-byte write WSTRB=0000",
              UVM_LOW)

    // ============================================================
    // WSTRB CASE 2B:
    // Readback after no-byte write
    //
    // Expected DATA remains 0xAA22_BB44
    // ============================================================

    req = axi_seq_item::type_id::create("wstrb_no_byte_readback");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = 4'h5;
    req.addr  = 32'h0000_0300;
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
    req.expected_rdata[0] = 32'hAA22_BB44;

    finish_item(req);

    `uvm_info("SEQ_WSTRB",
              "CASE 2B DONE: No-byte write readback confirmed unchanged data 0xAA22_BB44",
              UVM_LOW)

  endtask

endclass
