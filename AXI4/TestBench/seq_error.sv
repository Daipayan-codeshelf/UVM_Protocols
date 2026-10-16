class seq_error extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(seq_error)

  function new(string name = "seq_error");
    super.new(name);
  endfunction

  task body();

    axi_seq_item req;

    // ============================================================
    // ERROR CASE 1:
    // Write crossing 4KB boundary -> SLVERR
    //
    // Address sequence:
    // 0x0FF8 -> 0x0FFC -> 0x1000 -> 0x1004
    // ============================================================

    req = axi_seq_item::type_id::create("err_bnd_write_cross");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'h9;
    req.addr  = 32'h0000_0FF8;
    req.len   = 8'h03;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b10; // SLVERR
    req.expected_rresp = 2'b00;
    req.compare_enable = 1'b0;

    req.data = new[4];
    req.data[0] = 32'h0000_0001;
    req.data[1] = 32'h0000_0002;
    req.data[2] = 32'h0000_0003;
    req.data[3] = 32'h0000_0004;

    req.wstrb = new[4];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;
    req.wstrb[2] = 4'hF;
    req.wstrb[3] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_ERROR", "CASE 1 DONE: Write crossing 4KB boundary -> SLVERR", UVM_LOW)

    // ============================================================
    // ERROR CASE 2:
    // Read crossing 4KB boundary -> SLVERR
    // ============================================================

    req = axi_seq_item::type_id::create("err_bnd_read_cross");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = 4'hA;
    req.addr  = 32'h0000_0FF8;
    req.len   = 8'h03;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b10; // SLVERR
    req.compare_enable = 1'b0;

    finish_item(req);

    `uvm_info("SEQ_ERROR", "CASE 2 DONE: Read crossing 4KB boundary -> SLVERR", UVM_LOW)

    // ============================================================
    // ERROR CASE 3:
    // Out-of-range write -> DECERR
    //
    // 0x3000 is outside:
    // Slave0: 0x0000 - 0x0FFF
    // Slave1: 0x1000 - 0x1FFF
    // Slave2: 0x2000 - 0x2FFF
    // ============================================================

    req = axi_seq_item::type_id::create("err_dec_write_oor");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'hC;
    req.addr  = 32'h0000_3000;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b11; // DECERR
    req.expected_rresp = 2'b00;
    req.compare_enable = 1'b0;

    req.data = new[1];
    req.data[0] = 32'hDEC0_0001;

    req.wstrb = new[1];
    req.wstrb[0] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_ERROR", "CASE 3 DONE: Out-of-range write -> DECERR", UVM_LOW)

    // ============================================================
    // ERROR CASE 4:
    // Out-of-range read -> DECERR
    // ============================================================

    req = axi_seq_item::type_id::create("err_dec_read_oor");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = 4'hD;
    req.addr  = 32'h0000_3000;
    req.len   = 8'h00;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b11; // DECERR
    req.compare_enable = 1'b0;

    finish_item(req);

    `uvm_info("SEQ_ERROR", "CASE 4 DONE: Out-of-range read -> DECERR", UVM_LOW)

    // ============================================================
    // ERROR CASE 5:
    // Partial out-of-range write
    //
    // Address sequence:
    // 0x2FFC -> 0x3000 -> 0x3004
    //
    // DUT returns SLVERR because this also crosses a 4KB boundary.
    // Boundary error has priority over decode error.
    // ============================================================

    req = axi_seq_item::type_id::create("err_partial_write_slverr");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_WRITE_ONLY;

    req.id    = 4'hE;
    req.addr  = 32'h0000_2FFC;
    req.len   = 8'h02;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b10; // SLVERR due boundary priority
    req.expected_rresp = 2'b00;
    req.compare_enable = 1'b0;

    req.data = new[3];
    req.data[0] = 32'hDEC0_1001;
    req.data[1] = 32'hDEC0_1002;
    req.data[2] = 32'hDEC0_1003;

    req.wstrb = new[3];
    req.wstrb[0] = 4'hF;
    req.wstrb[1] = 4'hF;
    req.wstrb[2] = 4'hF;

    finish_item(req);

    `uvm_info("SEQ_ERROR", "CASE 5 DONE: Partial out-of-range write -> SLVERR due boundary priority", UVM_LOW)

    // ============================================================
    // ERROR CASE 6:
    // Partial out-of-range read
    //
    // Address sequence:
    // 0x2FFC -> 0x3000 -> 0x3004
    //
    // DUT returns SLVERR because this also crosses a 4KB boundary.
    // ============================================================

    req = axi_seq_item::type_id::create("err_partial_read_slverr");

    start_item(req);

    req.txn_type = axi_seq_item::AXI_READ_ONLY;

    req.id    = 4'hF;
    req.addr  = 32'h0000_2FFC;
    req.len   = 8'h02;
    req.size  = 3'b010;
    req.burst = 2'b01;
    req.prot  = 3'b000;

    req.expected_bresp = 2'b00;
    req.expected_rresp = 2'b10; // SLVERR due boundary priority
    req.compare_enable = 1'b0;

    finish_item(req);

    `uvm_info("SEQ_ERROR", "CASE 6 DONE: Partial out-of-range read -> SLVERR due boundary priority", UVM_LOW)

  endtask

endclass
