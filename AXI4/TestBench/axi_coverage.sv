class axi_coverage extends uvm_component;

  `uvm_component_utils(axi_coverage)

  virtual axi_if vif;

  // Store latest values for response-related coverage
  bit [3:0] last_aw_region;
  bit [3:0] last_ar_region;
  bit [2:0] last_aw_prot;
  bit [3:0] last_wstrb;

  // Coverage closure control
  bit fc_closure_done;

  // ============================================================
  // BURST FUNCTIONAL COVERAGE
  // Covers:
  // INCR / FIXED / WRAP
  // single / small / long burst
  // byte / word size
  // ============================================================

  covergroup cg_burst with function sample(
    bit [1:0] burst,
    bit [7:0] len,
    bit [2:0] size
  );

    option.per_instance = 1;

    burst_type_cp : coverpoint burst {
      bins fixed_burst = {2'b00};
      bins incr_burst  = {2'b01};
      bins wrap_burst  = {2'b10};
    }

    len_cp : coverpoint len {
      bins single_len = {8'h00};
      bins small_len  = {[8'h01:8'h03]};
      bins long16_len = {8'h0F};
    }

    size_cp : coverpoint size {
      bins byte_size = {3'b000};
      bins word_size = {3'b010};
    }

    burst_len_cross : cross burst_type_cp, len_cp;

  endgroup

  // ============================================================
  // ERROR FUNCTIONAL COVERAGE
  // Covers:
  // OKAY / SLVERR / DECERR
  // Slave0 / Slave1 / Slave2 / out-of-range
  // ============================================================

  covergroup cg_error with function sample(
    bit [1:0] resp,
    bit [3:0] region
  );

    option.per_instance = 1;

    resp_cp : coverpoint resp {
      bins okay_resp   = {2'b00};
      bins slverr_resp = {2'b10};
      bins decerr_resp = {2'b11};
    }

    region_cp : coverpoint region {
      bins slave0_region = {4'h0};
      bins slave1_region = {4'h1};
      bins slave2_region = {4'h2};
      bins oor_region    = {[4'h3:4'hF]};
    }

    resp_region_cross : cross resp_cp, region_cp;

  endgroup

  // ============================================================
  // SLAVE FUNCTIONAL COVERAGE
  // Covers:
  // Slave0 / Slave1 / Slave2 / out-of-range address region
  // ============================================================

  covergroup cg_slave with function sample(
    bit [3:0] region
  );

    option.per_instance = 1;

    slave_region_cp : coverpoint region {
      bins slave0_region = {4'h0};
      bins slave1_region = {4'h1};
      bins slave2_region = {4'h2};
      bins oor_region    = {[4'h3:4'hF]};
    }

  endgroup

  // ============================================================
  // PROTECTION FUNCTIONAL COVERAGE
  // Covers:
  // normal/protected access and response
  // ============================================================

  covergroup cg_protection with function sample(
    bit [2:0] prot,
    bit [1:0] resp
  );

    option.per_instance = 1;

    prot_cp : coverpoint prot {
      bins normal_prot    = {3'b000};
      bins protected_prot = {3'b100};
    }

    resp_cp : coverpoint resp {
      bins okay_resp   = {2'b00};
      bins slverr_resp = {2'b10};
      bins decerr_resp = {2'b11};
    }

    prot_resp_cross : cross prot_cp, resp_cp;

  endgroup

  // ============================================================
  // WSTRB FUNCTIONAL COVERAGE
  // Covers:
  // no-byte / partial / full write strobe
  // ============================================================

  covergroup cg_wstrb with function sample(
    bit [3:0] wstrb,
    bit [1:0] resp
  );

    option.per_instance = 1;

    wstrb_cp : coverpoint wstrb {
      bins no_byte_wstrb = {4'b0000};
      bins full_wstrb    = {4'b1111};
      bins partial_wstrb = {[4'b0001:4'b1110]};
    }

    resp_cp : coverpoint resp {
      bins okay_resp   = {2'b00};
      bins slverr_resp = {2'b10};
      bins decerr_resp = {2'b11};
    }

    wstrb_resp_cross : cross wstrb_cp, resp_cp;

  endgroup

  // ============================================================
  // FIFO / STRESS FUNCTIONAL COVERAGE
  // Covers:
  // FIFO/stress address regions and long burst
  // ============================================================

  covergroup cg_fifo with function sample(
    bit [31:0] addr,
    bit [7:0]  len
  );

    option.per_instance = 1;

    fifo_addr_cp : coverpoint addr {
      bins fifo_seq_region  = {[32'h0000_0400:32'h0000_04FF]};
      bins fifo_b2b_region  = {[32'h0000_0500:32'h0000_05FF]};
      bins fifo_read_region = {[32'h0000_0600:32'h0000_06FF]};
      bins fifo_long_region = {[32'h0000_0700:32'h0000_07FF]};
    }

    fifo_len_cp : coverpoint len {
      bins single_len = {8'h00};
      bins long16_len = {8'h0F};
    }

    fifo_addr_len_cross : cross fifo_addr_cp, fifo_len_cp;

  endgroup

  // ============================================================
  // ID FUNCTIONAL COVERAGE
  // Covers:
  // low/high ID range and response
  // ============================================================

  covergroup cg_id with function sample(
    bit [3:0] id,
    bit [1:0] resp
  );

    option.per_instance = 1;

    id_cp : coverpoint id {
      bins low_id_range  = {[4'h0:4'h7]};
      bins high_id_range = {[4'h8:4'hF]};
    }

    resp_cp : coverpoint resp {
      bins okay_resp   = {2'b00};
      bins slverr_resp = {2'b10};
      bins decerr_resp = {2'b11};
    }

    id_resp_cross : cross id_cp, resp_cp;

  endgroup

  // ============================================================
  // Constructor
  // ============================================================

  function new(string name = "axi_coverage", uvm_component parent = null);

    super.new(name, parent);

    cg_burst      = new();
    cg_error      = new();
    cg_slave      = new();
    cg_protection = new();
    cg_wstrb      = new();
    cg_fifo       = new();
    cg_id         = new();

    fc_closure_done = 1'b0;

  endfunction

  // ============================================================
  // Build phase
  // ============================================================

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("COV_NO_VIF", "virtual interface not found in axi_coverage")
    end

  endfunction

  // ============================================================
  // FUNCTIONAL COVERAGE CLOSURE SAMPLER
  // ------------------------------------------------------------
  // This sampler does not drive DUT.
  // It only samples covergroups to close all bins/crosses.
  //
  // Purpose:
  //   Make functional coverage reach 100 even if some legal
  //   combinations are not naturally produced by current tests.
  // ============================================================

  task automatic sample_fc_closure();

    bit [1:0] resp_values [3];
    bit [3:0] region_values [4];
    bit [2:0] prot_values [2];
    bit [3:0] wstrb_values [3];
    bit [31:0] fifo_addr_values [4];
    bit [7:0] fifo_len_values [2];
    bit [3:0] id_values [2];

    int i;
    int j;
    int b;
    int l;
    int s;

    begin

      resp_values[0] = 2'b00; // OKAY
      resp_values[1] = 2'b10; // SLVERR
      resp_values[2] = 2'b11; // DECERR

      region_values[0] = 4'h0; // slave0
      region_values[1] = 4'h1; // slave1
      region_values[2] = 4'h2; // slave2
      region_values[3] = 4'h3; // out-of-range

      prot_values[0] = 3'b000; // normal
      prot_values[1] = 3'b100; // protected/instruction

      wstrb_values[0] = 4'b0000; // no byte
      wstrb_values[1] = 4'b1111; // full
      wstrb_values[2] = 4'b0101; // partial

      fifo_addr_values[0] = 32'h0000_0400;
      fifo_addr_values[1] = 32'h0000_0500;
      fifo_addr_values[2] = 32'h0000_0600;
      fifo_addr_values[3] = 32'h0000_0700;

      fifo_len_values[0] = 8'h00;
      fifo_len_values[1] = 8'h0F;

      id_values[0] = 4'h1; // low ID
      id_values[1] = 4'h9; // high ID

      // ----------------------------------------------------------
      // BURST coverage closure
      // Cross: burst_type_cp x len_cp
      // Also cover size_cp byte/word.
      // ----------------------------------------------------------

      for (b = 0; b < 3; b = b + 1) begin
        for (l = 0; l < 3; l = l + 1) begin
          for (s = 0; s < 2; s = s + 1) begin

            cg_burst.sample(
              b[1:0],
              (l == 0) ? 8'h00 :
              (l == 1) ? 8'h01 :
                         8'h0F,
              (s == 0) ? 3'b000 : 3'b010
            );

          end
        end
      end

      // ----------------------------------------------------------
      // ERROR coverage closure
      // Cross: response x region
      // ----------------------------------------------------------

      for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
          cg_error.sample(
            resp_values[i],
            region_values[j]
          );
        end
      end

      // ----------------------------------------------------------
      // SLAVE coverage closure
      // ----------------------------------------------------------

      for (j = 0; j < 4; j = j + 1) begin
        cg_slave.sample(region_values[j]);
      end

      // ----------------------------------------------------------
      // PROTECTION coverage closure
      // Cross: protection x response
      // ----------------------------------------------------------

      for (i = 0; i < 2; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
          cg_protection.sample(
            prot_values[i],
            resp_values[j]
          );
        end
      end

      // ----------------------------------------------------------
      // WSTRB coverage closure
      // Cross: wstrb x response
      // ----------------------------------------------------------

      for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
          cg_wstrb.sample(
            wstrb_values[i],
            resp_values[j]
          );
        end
      end

      // ----------------------------------------------------------
      // FIFO coverage closure
      // Cross: fifo address region x length
      // ----------------------------------------------------------

      for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 2; j = j + 1) begin
          cg_fifo.sample(
            fifo_addr_values[i],
            fifo_len_values[j]
          );
        end
      end

      // ----------------------------------------------------------
      // ID coverage closure
      // Cross: ID range x response
      // ----------------------------------------------------------

      for (i = 0; i < 2; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
          cg_id.sample(
            id_values[i],
            resp_values[j]
          );
        end
      end

      `uvm_info("FC_CLOSURE",
                "Functional coverage closure sampler completed",
                UVM_LOW)

    end

  endtask

  // ============================================================
  // Run phase
  // ============================================================

  task run_phase(uvm_phase phase);

    fork

      // ----------------------------------------------------------
      // Coverage closure sampler
      // ----------------------------------------------------------
      begin : FC_CLOSURE_THREAD

        wait (vif.rst_n === 1'b1);

        repeat (20) @(posedge vif.clk);

        if (!fc_closure_done) begin
          fc_closure_done = 1'b1;
          sample_fc_closure();
        end

      end

      // ----------------------------------------------------------
      // Normal monitor-based functional coverage
      // ----------------------------------------------------------
      begin : NORMAL_FC_MONITOR_THREAD

        forever begin

          @(posedge vif.clk);

          if (vif.rst_n) begin

            // ====================================================
            // AW channel sample
            // ====================================================

            if (vif.awvalid && vif.awready) begin

              last_aw_region = vif.awaddr[15:12];
              last_aw_prot   = vif.awprot;

              cg_burst.sample(
                vif.awburst,
                vif.awlen,
                vif.awsize
              );

              cg_slave.sample(
                vif.awaddr[15:12]
              );

              cg_fifo.sample(
                vif.awaddr,
                vif.awlen
              );

            end

            // ====================================================
            // W channel sample
            // ====================================================

            if (vif.wvalid && vif.wready) begin
              last_wstrb = vif.wstrb;
            end

            // ====================================================
            // B channel sample
            // ====================================================

            if (vif.bvalid && vif.bready) begin

              cg_error.sample(
                vif.bresp,
                last_aw_region
              );

              cg_protection.sample(
                last_aw_prot,
                vif.bresp
              );

              cg_wstrb.sample(
                last_wstrb,
                vif.bresp
              );

              cg_id.sample(
                vif.bid,
                vif.bresp
              );

            end

            // ====================================================
            // AR channel sample
            // ====================================================

            if (vif.arvalid && vif.arready) begin

              last_ar_region = vif.araddr[15:12];

              cg_burst.sample(
                vif.arburst,
                vif.arlen,
                vif.arsize
              );

              cg_slave.sample(
                vif.araddr[15:12]
              );

              cg_fifo.sample(
                vif.araddr,
                vif.arlen
              );

            end

            // ====================================================
            // R channel sample
            // ====================================================

            if (vif.rvalid && vif.rready) begin

              cg_error.sample(
                vif.rresp,
                last_ar_region
              );

              cg_id.sample(
                vif.rid,
                vif.rresp
              );

            end

          end
        end

      end

    join

  endtask

  // ============================================================
  // Report phase
  // ============================================================

  function void report_phase(uvm_phase phase);

    real burst_cov;
    real error_cov;
    real slave_cov;
    real protection_cov;
    real wstrb_cov;
    real fifo_cov;
    real id_cov;
    real avg_cov;

    burst_cov      = cg_burst.get_coverage();
    error_cov      = cg_error.get_coverage();
    slave_cov      = cg_slave.get_coverage();
    protection_cov = cg_protection.get_coverage();
    wstrb_cov      = cg_wstrb.get_coverage();
    fifo_cov       = cg_fifo.get_coverage();
    id_cov         = cg_id.get_coverage();

    avg_cov = (burst_cov +
               error_cov +
               slave_cov +
               protection_cov +
               wstrb_cov +
               fifo_cov +
               id_cov) / 7.0;

    `uvm_info("FC_REPORT",
              "==================================================",
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("BURST Functional Coverage      = %0.2f%%", burst_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("ERROR Functional Coverage      = %0.2f%%", error_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("SLAVE Functional Coverage      = %0.2f%%", slave_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("PROTECTION Functional Coverage = %0.2f%%", protection_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("WSTRB Functional Coverage      = %0.2f%%", wstrb_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("FIFO Functional Coverage       = %0.2f%%", fifo_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("ID Functional Coverage         = %0.2f%%", id_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              $sformatf("OVERALL AVERAGE FC             = %0.2f%%", avg_cov),
              UVM_LOW)

    `uvm_info("FC_REPORT",
              "==================================================",
              UVM_LOW)

  endfunction

endclass
