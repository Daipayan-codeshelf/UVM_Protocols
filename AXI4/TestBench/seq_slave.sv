class seq_slave extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_slave)

  function new(string name = "seq_slave");
    super.new(name);
  endfunction

  task body();

    axi_seq_item req;

    // ============================================================
    // SLAVE CASE 1:
    // Slave 0 write/read
    //
    // Slave 0 address range:
    // 0x0000_0000 - 0x0000_0FFF
    // ============================================================

    req = axi_seq_item::type_id::create("slave0_access");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h1;
    req.addr  = 32'h0000_0080;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'h1111_AAAA;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_SLAVE", "CASE 1 DONE: Slave 0 write/read access", UVM_LOW)

    // ============================================================
    // SLAVE CASE 2:
    // Slave 1 write/read
    //
    // Slave 1 address range:
    // 0x0000_1000 - 0x0000_1FFF
    // ============================================================

    req = axi_seq_item::type_id::create("slave1_access");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h2;
    req.addr  = 32'h0000_1080;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'h2222_BBBB;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_SLAVE", "CASE 2 DONE: Slave 1 write/read access", UVM_LOW)

    // ============================================================
    // SLAVE CASE 3:
    // Slave 2 write/read
    //
    // Slave 2 address range:
    // 0x0000_2000 - 0x0000_2FFF
    // ============================================================

    req = axi_seq_item::type_id::create("slave2_access");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h3;
    req.addr  = 32'h0000_2080;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'h3333_CCCC;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_SLAVE", "CASE 3 DONE: Slave 2 write/read access", UVM_LOW)

    // ============================================================
    // SLAVE CASE 4A:
    // Slave isolation write/read at same offset in Slave 0
    //
    // Offset = 0x0004
    // Slave 0 address = 0x0000_0004
    // ============================================================

    req = axi_seq_item::type_id::create("slave0_isolation");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h4;
    req.addr  = 32'h0000_0004;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hAAAA_0001;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_SLAVE", "CASE 4A DONE: Slave 0 isolation check", UVM_LOW)

    // ============================================================
    // SLAVE CASE 4B:
    // Slave isolation write/read at same offset in Slave 1
    //
    // Offset = 0x0004
    // Slave 1 address = 0x0000_1004
    // ============================================================

    req = axi_seq_item::type_id::create("slave1_isolation");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h5;
    req.addr  = 32'h0000_1004;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hBBBB_0002;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_SLAVE", "CASE 4B DONE: Slave 1 isolation check", UVM_LOW)

    // ============================================================
    // SLAVE CASE 4C:
    // Slave isolation write/read at same offset in Slave 2
    //
    // Offset = 0x0004
    // Slave 2 address = 0x0000_2004
    // ============================================================

    req = axi_seq_item::type_id::create("slave2_isolation");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'h6;
    req.addr  = 32'h0000_2004;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hCCCC_0003;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_SLAVE", "CASE 4C DONE: Slave 2 isolation check", UVM_LOW)

  endtask

endclass
