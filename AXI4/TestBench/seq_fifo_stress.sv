class seq_fifo_stress extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_fifo_stress)

  function new(string name = "seq_fifo_stress");
    super.new(name);
  endfunction

  // ============================================================
  // Helper: normal single-beat write/read
  // ============================================================
  task do_write_read(
    input bit [3:0]  id,
    input bit [31:0] addr,
    input bit [31:0] data
  );

    axi_seq_item req;

    req = axi_seq_item::type_id::create("fifo_wr_rd_item");

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
  // Helper: write-only transaction
  // ============================================================
  task do_write_only(
    input bit [3:0]  id,
    input bit [31:0] addr,
    input bit [31:0] data
  );

    axi_seq_item req;

    req = axi_seq_item::type_id::create("fifo_wr_only_item");

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
  // Helper: read-only transaction with expected data
  // ============================================================
  task do_read_only_expected(
    input bit [3:0]  id,
    input bit [31:0] addr,
    input bit [31:0] expected_data
  );

    axi_seq_item req;

    req = axi_seq_item::type_id::create("fifo_rd_only_item");

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

    axi_seq_item req;
    int i;

    // ============================================================
    // FIFO/STRESS CASE 1:
    // Multiple sequential single-beat write/read transactions
    //
    // Addresses:
    // 0x0000_0400 to 0x0000_041C
    //
    // Expected matches = 8
    // ============================================================

    for (i = 0; i < 8; i++) begin
      do_write_read(
        4'(i + 1),
        32'h0000_0400 + (i * 4),
        32'hF000_0000 + i
      );
    end

    `uvm_info("SEQ_FIFO_STRESS",
              "CASE 1 DONE: 8 sequential single-beat write/read transactions",
              UVM_LOW)

    // ============================================================
    // FIFO/STRESS CASE 2:
    // Back-to-back writes then readbacks
    //
    // Write-only 4 addresses first.
    // Then read-only with expected data.
    //
    // Expected matches = 4
    // ============================================================

    do_write_only(4'h1, 32'h0000_0500, 32'hF100_0001);
    do_write_only(4'h2, 32'h0000_0504, 32'hF100_0002);
    do_write_only(4'h3, 32'h0000_0508, 32'hF100_0003);
    do_write_only(4'h4, 32'h0000_050C, 32'hF100_0004);

    do_read_only_expected(4'h5, 32'h0000_0500, 32'hF100_0001);
    do_read_only_expected(4'h6, 32'h0000_0504, 32'hF100_0002);
    do_read_only_expected(4'h7, 32'h0000_0508, 32'hF100_0003);
    do_read_only_expected(4'h8, 32'h0000_050C, 32'hF100_0004);

    `uvm_info("SEQ_FIFO_STRESS",
              "CASE 2 DONE: Back-to-back writes then readbacks",
              UVM_LOW)

    // ============================================================
    // FIFO/STRESS CASE 3:
    // Back-to-back reads from preloaded addresses
    //
    // Preload using write-only.
    // Then issue read-only checks.
    //
    // Expected matches = 4
    // ============================================================

    do_write_only(4'h1, 32'h0000_0600, 32'hA100_0001);
    do_write_only(4'h2, 32'h0000_0604, 32'hA100_0002);
    do_write_only(4'h3, 32'h0000_0608, 32'hA100_0003);
    do_write_only(4'h4, 32'h0000_060C, 32'hA100_0004);

    do_read_only_expected(4'h9, 32'h0000_0600, 32'hA100_0001);
    do_read_only_expected(4'hA, 32'h0000_0604, 32'hA100_0002);
    do_read_only_expected(4'hB, 32'h0000_0608, 32'hA100_0003);
    do_read_only_expected(4'hC, 32'h0000_060C, 32'hA100_0004);

    `uvm_info("SEQ_FIFO_STRESS",
              "CASE 3 DONE: Back-to-back reads from preloaded addresses",
              UVM_LOW)

    // ============================================================
    // FIFO/STRESS CASE 4:
    // 16-beat long INCR burst
    //
    // ADDR  = 0x0000_0700
    // LEN   = 15 -> 16 beats
    // SIZE  = 2  -> 4 bytes
    // BURST = INCR
    //
    // Expected matches = 16
    // ============================================================

    req = axi_seq_item::type_id::create("fifo_long_16beat_incr");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_READ;

    req.id    = 4'hD;
    req.addr  = 32'h0000_0700;
    req.len   = 8'h0F;       // 16 beats
    req.size  = 3'b010;      // 4 bytes
    req.burst = 2'b01;       // INCR
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b00;

    req.compare_enable = 1'b1;
    req.fixed_compare_last_only = 1'b0;
    req.use_read_cfg = 1'b0;
    req.expected_read_enable = 1'b0;

    req.data = new[16];
    req.wstrb = new[16];

    for (i = 0; i < 16; i++) begin
      req.data[i]  = 32'h7000_0000 + i;
      req.wstrb[i] = 4'hF;
    end

    finish_item(req);

    `uvm_info("SEQ_FIFO_STRESS",
              "CASE 4 DONE: 16-beat long INCR burst",
              UVM_LOW)

  endtask

endclass
