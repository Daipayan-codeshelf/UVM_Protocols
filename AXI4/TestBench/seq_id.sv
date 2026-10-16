class seq_id extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_id)

  function new(string name = "seq_id");
    super.new(name);
  endfunction

  // ============================================================
  // Helper: write/read with selected ID
  // ============================================================

  task do_write_read_id(
    input bit [3:0]  id,
    input bit [31:0] addr,
    input bit [31:0] data
  );

    axi_seq_item req;

    req = axi_seq_item::type_id::create("id_wr_rd_item");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = id;
    req.addr  = addr;
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
    req.data[0] = data;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

  endtask

  // ============================================================
  // Helper: write-only preload
  // ============================================================

  task do_write_only_id(
    input bit [3:0]  id,
    input bit [31:0] addr,
    input bit [31:0] data
  );

    axi_seq_item req;

    req = axi_seq_item::type_id::create("id_wr_only_item");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = id;
    req.addr  = addr;
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
    req.data[0] = data;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

  endtask

  // ============================================================
  // Helper: read-only with expected data
  // ============================================================

  task do_read_only_id(
    input bit [3:0]  id,
    input bit [31:0] addr,
    input bit [31:0] expected_data
  );

    axi_seq_item req;

    req = axi_seq_item::type_id::create("id_rd_only_item");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = id;
    req.addr  = addr;
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
    req.expected_rdata[0] = expected_data;

    finish_item(req);

  endtask

  // ============================================================
  // Main body
  // ============================================================

  task body();

    // ============================================================
    // ID CASE 1:
    // Unique IDs for normal write/read transactions
    //
    // Checks:
    // BID == AWID
    // RID == ARID
    // Data readback matches
    //
    // Expected matches = 3
    // ============================================================

    do_write_read_id(4'h1, 32'h0000_0800, 32'h1D00_0001);
    do_write_read_id(4'h2, 32'h0000_0804, 32'h1D00_0002);
    do_write_read_id(4'h3, 32'h0000_0808, 32'h1D00_0003);

    `uvm_info("SEQ_ID",
              "CASE 1 DONE: Unique IDs write/read tracking",
              UVM_LOW)

    // ============================================================
    // ID CASE 2:
    // Same ID reused after response completion
    //
    // This is legal because previous transaction completed first.
    //
    // Expected matches = 2
    // ============================================================

    do_write_read_id(4'h5, 32'h0000_0840, 32'h1D50_0001);
    do_write_read_id(4'h5, 32'h0000_0844, 32'h1D50_0002);

    `uvm_info("SEQ_ID",
              "CASE 2 DONE: Same ID reused after completion",
              UVM_LOW)

    // ============================================================
    // ID CASE 3:
    // Read-only ID tracking from preloaded address
    //
    // Flow:
    // 1. Preload memory using write-only transaction
    // 2. Read using different ARID
    // 3. Check RID and read data
    //
    // Expected matches = 1
    // ============================================================

    do_write_only_id(4'h6, 32'h0000_0880, 32'h1DAD_BEEF);
    do_read_only_id (4'hA, 32'h0000_0880, 32'h1DAD_BEEF);

    `uvm_info("SEQ_ID",
              "CASE 3 DONE: Read-only RID tracking from preloaded address",
              UVM_LOW)

  endtask

endclass
