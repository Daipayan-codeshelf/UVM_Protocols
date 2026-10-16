class axi_master_monitor extends uvm_monitor;

  `uvm_component_utils(axi_master_monitor)

  virtual axi_if vif;

  uvm_analysis_port #(axi_seq_item) w_ap;
  uvm_analysis_port #(axi_seq_item) r_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);

    w_ap = new("w_ap", this);
    r_ap = new("r_ap", this);
  endfunction

  task run_phase(uvm_phase phase);

    fork
      monitor_aw();
      monitor_w();
      monitor_b();
      monitor_ar();
      monitor_r();
    join_none

  endtask

  task monitor_aw();

    forever begin
      @(posedge vif.clk);

      if (vif.rst_n && vif.awvalid && vif.awready) begin
        `uvm_info("MON_AW",
                  $sformatf("AW handshake ID=%0h ADDR=0x%08h LEN=%0d SIZE=%0d BURST=%02b",
                            vif.awid, vif.awaddr, vif.awlen, vif.awsize, vif.awburst),
                  UVM_HIGH)
      end
    end

  endtask

  task monitor_w();

    axi_seq_item item;

    forever begin
      @(posedge vif.clk);

      if (vif.rst_n && vif.wvalid && vif.wready) begin

        item = axi_seq_item::type_id::create("w_item");

        item.data = new[1];
        item.data[0] = vif.wdata;
        item.last = vif.wlast;

        w_ap.write(item);

        `uvm_info("MON_W",
                  $sformatf("W handshake DATA=0x%08h STRB=%0h LAST=%0b",
                            vif.wdata, vif.wstrb, vif.wlast),
                  UVM_HIGH)
      end
    end

  endtask

  task monitor_b();

    forever begin
      @(posedge vif.clk);

      if (vif.rst_n && vif.bvalid && vif.bready) begin
        `uvm_info("MON_B",
                  $sformatf("B handshake BID=%0h BRESP=%02b",
                            vif.bid, vif.bresp),
                  UVM_HIGH)
      end
    end

  endtask

  task monitor_ar();

    forever begin
      @(posedge vif.clk);

      if (vif.rst_n && vif.arvalid && vif.arready) begin
        `uvm_info("MON_AR",
                  $sformatf("AR handshake ID=%0h ADDR=0x%08h LEN=%0d SIZE=%0d BURST=%02b",
                            vif.arid, vif.araddr, vif.arlen, vif.arsize, vif.arburst),
                  UVM_HIGH)
      end
    end

  endtask

  task monitor_r();

    axi_seq_item item;

    forever begin
      @(posedge vif.clk);

      if (vif.rst_n && vif.rvalid && vif.rready) begin

        item = axi_seq_item::type_id::create("r_item");

        item.id = vif.rid;
        item.data = new[1];
        item.data[0] = vif.rdata;
        item.rresp = vif.rresp;
        item.last  = vif.rlast;

        r_ap.write(item);

        `uvm_info("MON_R",
                  $sformatf("R handshake RID=%0h DATA=0x%08h RRESP=%02b RLAST=%0b",
                            vif.rid, vif.rdata, vif.rresp, vif.rlast),
                  UVM_HIGH)
      end
    end

  endtask

endclass
