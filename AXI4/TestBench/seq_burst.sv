class seq_burst extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_burst)

  function new(string name = "seq_burst");
    super.new(name);
  endfunction

  task body();

    axi_seq_item req;

    // ============================================================
    // INCR CASE 1:
    // Single-beat INCR write/read
    // ============================================================

    req = axi_seq_item::type_id::create("incr_single");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h1;
    req.addr  = 32'h0000_0000;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;       // INCR
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;
    req.compare_enable = 1'b1;

    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hDEAD_BEEF;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_BURST", "INCR CASE 1 DONE: Single-beat INCR", UVM_LOW)

    // ============================================================
    // INCR CASE 2:
    // 4-beat INCR burst write/read
    // ============================================================

    req = axi_seq_item::type_id::create("incr_4beat");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h2;
    req.addr  = 32'h0000_0010;
    req.len   = 8'h03;
    req.size  = 3'b010;
    req.burst = 2'b01;       // INCR
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;
    req.compare_enable = 1'b1;

    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[4];
    req.data[0] = 32'hAAAA_0000;
    req.data[1] = 32'hBBBB_1111;
    req.data[2] = 32'hCCCC_2222;
    req.data[3] = 32'hDDDD_3333;

    req.wstrb = new[4];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;
    req.wstrb[2] = 4'hF;
    req.wstrb[3] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_BURST", "INCR CASE 2 DONE: 4-beat INCR", UVM_LOW)

    // ============================================================
    // INCR CASE 3:
    // Unaligned INCR write/read
    // ============================================================

    req = axi_seq_item::type_id::create("incr_unaligned");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h3;
    req.addr  = 32'h0000_0002;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;       // INCR
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;
    req.compare_enable = 1'b1;

    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'h1234_ABCD;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_BURST", "INCR CASE 3 DONE: Unaligned INCR", UVM_LOW)

    // ============================================================
    // INCR CASE 4:
    // Byte-size INCR transaction
    //
    // Data compare disabled for now because byte-level scoreboard
    // is not implemented yet.
    // ============================================================

    req = axi_seq_item::type_id::create("incr_byte_size");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h4;
    req.addr  = 32'h0000_0100;
    req.len   = 8'h03;
    req.size  = 3'b000;      // byte size
    req.burst = 2'b01;       // INCR
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b0;

    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[4];
    req.data[0] = 32'h0000_00AA;
    req.data[1] = 32'h0000_00BB;
    req.data[2] = 32'h0000_00CC;
    req.data[3] = 32'h0000_00DD;

    req.wstrb = new[4];
    req.wstrb[0] = 4'b0001;
    req.wstrb[1] = 4'b0001;
    req.wstrb[2] = 4'b0001;
    req.wstrb[3] = 4'b0001;

    finish_item(req);

    `uvm_info("SEQ_BURST", "INCR CASE 4 DONE: Byte-size INCR", UVM_LOW)

    // ============================================================
    // FIXED CASE 1:
    // 2-beat FIXED burst
    //
    // Both beats target same address.
    // Final expected value = CAFE_F00D.
    // ============================================================

    req = axi_seq_item::type_id::create("fixed_2beat");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h5;
    req.addr  = 32'h0000_0020;
    req.len   = 8'h01;
    req.size  = 3'b010;
    req.burst = 2'b00;       // FIXED
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b1;

    req.data = new[2];
    req.data[0] = 32'hDEAD_BEEF;
    req.data[1] = 32'hCAFE_F00D;

    req.wstrb = new[2];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;

    // Read only one beat from same address
    req.use_read_cfg = 1'b1;
    req.rd_addr  = 32'h0000_0020;
    req.rd_len   = 8'h00;
    req.rd_size  = 3'b010;
    req.rd_burst = 2'b01;
    req.rd_prot  = 3'b000;

    finish_item(req);

    `uvm_info("SEQ_BURST", "FIXED CASE 1 DONE: 2-beat FIXED burst", UVM_LOW)

    // ============================================================
    // FIXED CASE 2:
    // 4-beat FIXED burst
    //
    // Final expected value = 4444_4444.
    // ============================================================

    req = axi_seq_item::type_id::create("fixed_4beat");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h6;
    req.addr  = 32'h0000_0040;
    req.len   = 8'h03;
    req.size  = 3'b010;
    req.burst = 2'b00;       // FIXED
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b1;

    req.data = new[4];
    req.data[0] = 32'h1111_1111;
    req.data[1] = 32'h2222_2222;
    req.data[2] = 32'h3333_3333;
    req.data[3] = 32'h4444_4444;

    req.wstrb = new[4];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;
    req.wstrb[2] = 4'hF;
    req.wstrb[3] = 4'hF;

    // Read only one beat from same address
    req.use_read_cfg = 1'b1;
    req.rd_addr  = 32'h0000_0040;
    req.rd_len   = 8'h00;
    req.rd_size  = 3'b010;
    req.rd_burst = 2'b01;
    req.rd_prot  = 3'b000;

    finish_item(req);

    `uvm_info("SEQ_BURST", "FIXED CASE 2 DONE: 4-beat FIXED burst", UVM_LOW)

    // ============================================================
    // WRAP CASE 1:
    // 4-beat WRAP burst write/read
    //
    // ADDR  = 0x0000_0008
    // LEN   = 3
    // SIZE  = 2
    // BURST = WRAP
    // ============================================================

    req = axi_seq_item::type_id::create("wrap_4beat");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h7;
    req.addr  = 32'h0000_0008;
    req.len   = 8'h03;
    req.size  = 3'b010;
    req.burst = 2'b10;       // WRAP
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[4];
    req.data[0] = 32'h1111_1111;
    req.data[1] = 32'h2222_2222;
    req.data[2] = 32'h3333_3333;
    req.data[3] = 32'h4444_4444;

    req.wstrb = new[4];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;
    req.wstrb[2] = 4'hF;
    req.wstrb[3] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_BURST", "WRAP CASE 1 DONE: 4-beat WRAP burst", UVM_LOW)

    // ============================================================
    // WRAP CASE 2:
    // 8-beat WRAP burst write/read
    // ============================================================

    req = axi_seq_item::type_id::create("wrap_8beat");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h8;
    req.addr  = 32'h0000_0010;
    req.len   = 8'h07;
    req.size  = 3'b010;
    req.burst = 2'b10;       // WRAP
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[8];
    req.data[0] = 32'hA000_0000;
    req.data[1] = 32'hA111_1111;
    req.data[2] = 32'hA222_2222;
    req.data[3] = 32'hA333_3333;
    req.data[4] = 32'hA444_4444;
    req.data[5] = 32'hA555_5555;
    req.data[6] = 32'hA666_6666;
    req.data[7] = 32'hA777_7777;

    req.wstrb = new[8];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;
    req.wstrb[2] = 4'hF;
    req.wstrb[3] = 4'hF;
    req.wstrb[4] = 4'hF;
    req.wstrb[5] = 4'hF;
    req.wstrb[6] = 4'hF;
    req.wstrb[7] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_BURST", "WRAP CASE 2 DONE: 8-beat WRAP burst", UVM_LOW)

  endtask

endclass
