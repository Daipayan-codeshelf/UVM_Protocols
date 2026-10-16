class axi_master_driver extends uvm_driver #(axi_seq_item);

  `uvm_component_utils(axi_master_driver)

  virtual axi_if vif;

  uvm_analysis_port #(axi_seq_item) exp_ap;
  uvm_analysis_port #(axi_seq_item) act_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);

    exp_ap = new("exp_ap", this);
    act_ap = new("act_ap", this);
  endfunction

  task run_phase(uvm_phase phase);

    axi_seq_item req;

    drive_defaults();

    wait(vif.rst_n == 1'b1);
    repeat (2) @(posedge vif.clk);

    forever begin

      seq_item_port.get_next_item(req);

      `uvm_info("MDRV",
                $sformatf("Starting transaction ID=%0h ADDR=0x%08h LEN=%0d BURST=%02b TYPE=%0d",
                          req.id, req.addr, req.len, req.burst, req.txn_type),
                UVM_LOW)

      case (req.txn_type)

        axi_seq_item::AXI_WRITE_READ: begin
          drive_aw(req);
          drive_w(req);
          wait_b(req);
          drive_ar(req);
          collect_r(req);
        end

        axi_seq_item::AXI_WRITE_ONLY: begin
          drive_aw(req);
          drive_w(req);
          wait_b(req);
        end

        axi_seq_item::AXI_READ_ONLY: begin
          drive_ar(req);
          collect_r(req);
        end

        default: begin
          `uvm_error("MDRV", "Unknown transaction type")
        end

      endcase

      `uvm_info("MDRV",
                $sformatf("Completed transaction ID=%0h ADDR=0x%08h",
                          req.id, req.addr),
                UVM_LOW)

      seq_item_port.item_done();

    end

  endtask

  task drive_defaults();

    vif.awid    <= '0;
    vif.awaddr  <= '0;
    vif.awlen   <= '0;
    vif.awsize  <= '0;
    vif.awburst <= '0;
    vif.awprot  <= '0;
    vif.awvalid <= 1'b0;

    vif.wdata   <= '0;
    vif.wstrb   <= 4'h0;
    vif.wlast   <= 1'b0;
    vif.wvalid  <= 1'b0;

    vif.bready  <= 1'b0;

    vif.arid    <= '0;
    vif.araddr  <= '0;
    vif.arlen   <= '0;
    vif.arsize  <= '0;
    vif.arburst <= '0;
    vif.arprot  <= '0;
    vif.arvalid <= 1'b0;

    vif.rready  <= 1'b0;

  endtask

  task drive_aw(axi_seq_item req);

    @(posedge vif.clk);

    vif.awid    <= req.id;
    vif.awaddr  <= req.addr;
    vif.awlen   <= req.len;
    vif.awsize  <= req.size;
    vif.awburst <= req.burst;
    vif.awprot  <= req.prot;
    vif.awvalid <= 1'b1;

    while (vif.awready !== 1'b1) begin
      @(posedge vif.clk);
    end

    @(posedge vif.clk);
    vif.awvalid <= 1'b0;

    `uvm_info("MDRV_AW",
              $sformatf("AW sent ID=%0h ADDR=0x%08h LEN=%0d SIZE=%0d BURST=%02b PROT=%03b",
                        req.id, req.addr, req.len, req.size, req.burst, req.prot),
              UVM_HIGH)

  endtask

  task drive_w(axi_seq_item req);

    int i;
    axi_seq_item exp_item;
    bit [3:0] local_wstrb;
    bit       local_wlast;

    for (i = 0; i < req.data.size(); i++) begin

      @(posedge vif.clk);

      if (req.wstrb.size() == req.data.size())
        local_wstrb = req.wstrb[i];
      else
        local_wstrb = 4'hF;

      local_wlast = (i == req.data.size() - 1);

      vif.wdata  <= req.data[i];
      vif.wstrb  <= local_wstrb;
      vif.wlast  <= local_wlast;
      vif.wvalid <= 1'b1;

      while (vif.wready !== 1'b1) begin
        @(posedge vif.clk);
      end

      if (req.compare_enable && !req.fixed_compare_last_only) begin
        exp_item = axi_seq_item::type_id::create("exp_item");
        exp_item.data = new[1];
        exp_item.data[0] = req.data[i];
        exp_ap.write(exp_item);
      end

      `uvm_info("MDRV_W",
                $sformatf("W beat=%0d DATA=0x%08h STRB=%0h LAST=%0b",
                          i, req.data[i], local_wstrb, local_wlast),
                UVM_HIGH)

    end

    if (req.compare_enable && req.fixed_compare_last_only) begin
      exp_item = axi_seq_item::type_id::create("fixed_exp_item");
      exp_item.data = new[1];
      exp_item.data[0] = req.data[req.data.size() - 1];
      exp_ap.write(exp_item);
    end

    @(posedge vif.clk);
    vif.wvalid <= 1'b0;
    vif.wlast  <= 1'b0;
    vif.wstrb  <= 4'h0;

    `uvm_info("MDRV_W",
              $sformatf("W burst completed: %0d beats", req.data.size()),
              UVM_HIGH)

  endtask

  task wait_b(ref axi_seq_item req);

    vif.bready <= 1'b1;

    while (vif.bvalid !== 1'b1) begin
      @(posedge vif.clk);
    end

    req.bresp = vif.bresp;

    // ============================================================
    // ID tracking check:
    // BID must match AWID / request ID
    // ============================================================

    if (vif.bid !== req.id) begin
      `uvm_error("MDRV_BID",
                 $sformatf("BID mismatch exp=%0h got=%0h",
                           req.id, vif.bid))
    end

    if (req.bresp !== req.expected_bresp) begin
      `uvm_error("MDRV_B",
                 $sformatf("BRESP mismatch exp=%02b got=%02b",
                           req.expected_bresp, req.bresp))
    end
    else begin
      `uvm_info("MDRV_B",
                $sformatf("BRESP matched: %02b BID=%0h",
                          req.bresp, vif.bid),
                UVM_HIGH)
    end

    @(posedge vif.clk);
    vif.bready <= 1'b0;

  endtask

  task drive_ar(axi_seq_item req);

    @(posedge vif.clk);

    vif.arid <= req.id;

    if (req.use_read_cfg) begin
      vif.araddr  <= req.rd_addr;
      vif.arlen   <= req.rd_len;
      vif.arsize  <= req.rd_size;
      vif.arburst <= req.rd_burst;
      vif.arprot  <= req.rd_prot;
    end
    else begin
      vif.araddr  <= req.addr;
      vif.arlen   <= req.len;
      vif.arsize  <= req.size;
      vif.arburst <= req.burst;
      vif.arprot  <= req.prot;
    end

    vif.arvalid <= 1'b1;

    while (vif.arready !== 1'b1) begin
      @(posedge vif.clk);
    end

    @(posedge vif.clk);
    vif.arvalid <= 1'b0;

    `uvm_info("MDRV_AR",
              $sformatf("AR sent ID=%0h ADDR=0x%08h LEN=%0d BURST=%02b PROT=%03b",
                        req.id,
                        req.use_read_cfg ? req.rd_addr  : req.addr,
                        req.use_read_cfg ? req.rd_len   : req.len,
                        req.use_read_cfg ? req.rd_burst : req.burst,
                        req.use_read_cfg ? req.rd_prot  : req.prot),
              UVM_HIGH)

  endtask

  task collect_r(ref axi_seq_item req);

    int i;
    int beats;
    axi_seq_item act_item;

    if (req.use_read_cfg)
      beats = req.rd_len + 1;
    else
      beats = req.len + 1;

    req.rdata = new[beats];

    // ============================================================
    // For READ_ONLY expected data comparison.
    // Push expected read data into scoreboard before actual data.
    // ============================================================

    if (req.compare_enable && req.expected_read_enable) begin

      if (req.expected_rdata.size() != beats) begin
        `uvm_error("MDRV_EXP_RDATA",
                   $sformatf("expected_rdata size mismatch exp_size=%0d beats=%0d",
                             req.expected_rdata.size(), beats))
      end
      else begin

        for (int j = 0; j < beats; j++) begin
          axi_seq_item exp_item;

          exp_item = axi_seq_item::type_id::create("read_exp_item");
          exp_item.data = new[1];
          exp_item.data[0] = req.expected_rdata[j];

          exp_ap.write(exp_item);
        end

      end

    end

    vif.rready <= 1'b1;

    for (i = 0; i < beats; i++) begin

      while (vif.rvalid !== 1'b1) begin
        @(posedge vif.clk);
      end

      req.rdata[i] = vif.rdata;
      req.rresp    = vif.rresp;
      req.last     = vif.rlast;

      // ============================================================
      // ID tracking check:
      // RID must match ARID / request ID
      // ============================================================

      if (vif.rid !== req.id) begin
        `uvm_error("MDRV_RID",
                   $sformatf("RID mismatch beat=%0d exp=%0h got=%0h",
                             i, req.id, vif.rid))
      end

      if (req.rresp !== req.expected_rresp) begin
        `uvm_error("MDRV_R",
                   $sformatf("RRESP mismatch beat=%0d exp=%02b got=%02b",
                             i, req.expected_rresp, req.rresp))
      end
      else begin
        `uvm_info("MDRV_RRESP",
                  $sformatf("RRESP matched beat=%0d RESP=%02b RID=%0h",
                            i, req.rresp, vif.rid),
                  UVM_HIGH)
      end

      if ((i == beats - 1) && (vif.rlast !== 1'b1)) begin
        `uvm_error("MDRV_RLAST", "RLAST missing on final beat")
      end

      if (req.compare_enable) begin
        act_item = axi_seq_item::type_id::create("act_item");
        act_item.data = new[1];
        act_item.data[0] = vif.rdata;
        act_ap.write(act_item);
      end

      `uvm_info("MDRV_R",
                $sformatf("R beat=%0d DATA=0x%08h RESP=%02b LAST=%0b RID=%0h",
                          i, vif.rdata, vif.rresp, vif.rlast, vif.rid),
                UVM_HIGH)

      @(posedge vif.clk);

    end

    vif.rready <= 1'b0;

    `uvm_info("MDRV_R",
              $sformatf("R burst completed: %0d beats", beats),
              UVM_HIGH)

  endtask

endclass
