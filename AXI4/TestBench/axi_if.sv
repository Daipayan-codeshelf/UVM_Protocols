interface axi_if(input logic clk);

  logic rst_n;

  // ============================================================
  // WRITE ADDRESS CHANNEL
  // ============================================================

  logic [3:0]  awid;
  logic [31:0] awaddr;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic [2:0]  awprot;
  logic        awvalid;
  logic        awready;

  // ============================================================
  // WRITE DATA CHANNEL
  // ============================================================

  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  logic        wvalid;
  logic        wready;

  // ============================================================
  // WRITE RESPONSE CHANNEL
  // ============================================================

  logic [3:0]  bid;
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;

  // ============================================================
  // READ ADDRESS CHANNEL
  // ============================================================

  logic [3:0]  arid;
  logic [31:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic [2:0]  arprot;
  logic        arvalid;
  logic        arready;

  // ============================================================
  // READ DATA CHANNEL
  // ============================================================

  logic [3:0]  rid;
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rlast;
  logic        rvalid;
  logic        rready;

  // ============================================================
  // ASSERTION INDICATOR
  // ============================================================

  int assertion_fail_count;

  initial begin
    assertion_fail_count = 0;
  end

  task automatic report_assertion_failure(string msg);
    assertion_fail_count++;
    $error("%s", msg);
  endtask

  final begin
    $display("==================================================");
    if (assertion_fail_count == 0) begin
      $display("ASSERTION_STATUS : PASSED");
    end
    else begin
      $display("ASSERTION_STATUS : FAILED");
    end
    $display("Total assertion failures = %0d", assertion_fail_count);
    $display("==================================================");
  end

  // ============================================================
  // ASSERTIONS
  // ============================================================

  // ============================================================
  // 1. VALID must remain asserted until READY
  // ============================================================

  property awvalid_until_awready;
    @(posedge clk) disable iff (!rst_n)
      awvalid && !awready |=> awvalid;
  endproperty

  property wvalid_until_wready;
    @(posedge clk) disable iff (!rst_n)
      wvalid && !wready |=> wvalid;
  endproperty

  property arvalid_until_arready;
    @(posedge clk) disable iff (!rst_n)
      arvalid && !arready |=> arvalid;
  endproperty

  property bvalid_until_bready;
    @(posedge clk) disable iff (!rst_n)
      bvalid && !bready |=> bvalid;
  endproperty

  property rvalid_until_rready;
    @(posedge clk) disable iff (!rst_n)
      rvalid && !rready |=> rvalid;
  endproperty

  AWVALID_UNTIL_AWREADY_A:
  assert property (awvalid_until_awready)
    else report_assertion_failure(
      "ASSERTION FAILED: AWVALID dropped before AWREADY"
    );

  WVALID_UNTIL_WREADY_A:
  assert property (wvalid_until_wready)
    else report_assertion_failure(
      "ASSERTION FAILED: WVALID dropped before WREADY"
    );

  ARVALID_UNTIL_ARREADY_A:
  assert property (arvalid_until_arready)
    else report_assertion_failure(
      "ASSERTION FAILED: ARVALID dropped before ARREADY"
    );

  BVALID_UNTIL_BREADY_A:
  assert property (bvalid_until_bready)
    else report_assertion_failure(
      "ASSERTION FAILED: BVALID dropped before BREADY"
    );

  RVALID_UNTIL_RREADY_A:
  assert property (rvalid_until_rready)
    else report_assertion_failure(
      "ASSERTION FAILED: RVALID dropped before RREADY"
    );

  // ============================================================
  // 2. Payload must remain stable while VALID high and READY low
  // ============================================================

  property aw_payload_stable;
    @(posedge clk) disable iff (!rst_n)
      awvalid && !awready |=> $stable({
        awid,
        awaddr,
        awlen,
        awsize,
        awburst,
        awprot
      });
  endproperty

  property w_payload_stable;
    @(posedge clk) disable iff (!rst_n)
      wvalid && !wready |=> $stable({
        wdata,
        wstrb,
        wlast
      });
  endproperty

  property ar_payload_stable;
    @(posedge clk) disable iff (!rst_n)
      arvalid && !arready |=> $stable({
        arid,
        araddr,
        arlen,
        arsize,
        arburst,
        arprot
      });
  endproperty

  property b_payload_stable;
    @(posedge clk) disable iff (!rst_n)
      bvalid && !bready |=> $stable({
        bid,
        bresp
      });
  endproperty

  property r_payload_stable;
    @(posedge clk) disable iff (!rst_n)
      rvalid && !rready |=> $stable({
        rid,
        rdata,
        rresp,
        rlast
      });
  endproperty

  AW_PAYLOAD_STABLE_A:
  assert property (aw_payload_stable)
    else report_assertion_failure(
      "ASSERTION FAILED: AW payload changed before AWREADY"
    );

  W_PAYLOAD_STABLE_A:
  assert property (w_payload_stable)
    else report_assertion_failure(
      "ASSERTION FAILED: W payload changed before WREADY"
    );

  AR_PAYLOAD_STABLE_A:
  assert property (ar_payload_stable)
    else report_assertion_failure(
      "ASSERTION FAILED: AR payload changed before ARREADY"
    );

  B_PAYLOAD_STABLE_A:
  assert property (b_payload_stable)
    else report_assertion_failure(
      "ASSERTION FAILED: B payload changed before BREADY"
    );

  R_PAYLOAD_STABLE_A:
  assert property (r_payload_stable)
    else report_assertion_failure(
      "ASSERTION FAILED: R payload changed before RREADY"
    );

  // ============================================================
  // 3. No unknown values during VALID phase
  // ============================================================

  property no_unknown_aw;
    @(posedge clk) disable iff (!rst_n)
      awvalid |-> !$isunknown({
        awid,
        awaddr,
        awlen,
        awsize,
        awburst,
        awprot
      });
  endproperty

  property no_unknown_w;
    @(posedge clk) disable iff (!rst_n)
      wvalid |-> !$isunknown({
        wdata,
        wstrb,
        wlast
      });
  endproperty

  property no_unknown_b;
    @(posedge clk) disable iff (!rst_n)
      bvalid |-> !$isunknown({
        bid,
        bresp
      });
  endproperty

  property no_unknown_ar;
    @(posedge clk) disable iff (!rst_n)
      arvalid |-> !$isunknown({
        arid,
        araddr,
        arlen,
        arsize,
        arburst,
        arprot
      });
  endproperty

  property no_unknown_r;
    @(posedge clk) disable iff (!rst_n)
      rvalid |-> !$isunknown({
        rid,
        rdata,
        rresp,
        rlast
      });
  endproperty

  NO_UNKNOWN_AW_A:
  assert property (no_unknown_aw)
    else report_assertion_failure(
      "ASSERTION FAILED: Unknown value on AW channel"
    );

  NO_UNKNOWN_W_A:
  assert property (no_unknown_w)
    else report_assertion_failure(
      "ASSERTION FAILED: Unknown value on W channel"
    );

  NO_UNKNOWN_B_A:
  assert property (no_unknown_b)
    else report_assertion_failure(
      "ASSERTION FAILED: Unknown value on B channel"
    );

  NO_UNKNOWN_AR_A:
  assert property (no_unknown_ar)
    else report_assertion_failure(
      "ASSERTION FAILED: Unknown value on AR channel"
    );

  NO_UNKNOWN_R_A:
  assert property (no_unknown_r)
    else report_assertion_failure(
      "ASSERTION FAILED: Unknown value on R channel"
    );

  // ============================================================
  // ASSERTION COVERAGE
  // These cover properties help assertion coverage appear in URG.
  // ============================================================

  // ------------------------------------------------------------
  // Basic handshakes
  // ------------------------------------------------------------

  AW_HANDSHAKE_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    awvalid && awready
  );

  W_HANDSHAKE_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    wvalid && wready
  );

  B_HANDSHAKE_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    bvalid && bready
  );

  AR_HANDSHAKE_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    arvalid && arready
  );

  R_HANDSHAKE_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    rvalid && rready
  );

  // ------------------------------------------------------------
  // Wait/backpressure conditions
  // These may remain uncovered if READY is always immediate.
  // ------------------------------------------------------------

  AW_WAIT_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    awvalid && !awready
  );

  W_WAIT_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    wvalid && !wready
  );

  B_WAIT_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    bvalid && !bready
  );

  AR_WAIT_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    arvalid && !arready
  );

  R_WAIT_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    rvalid && !rready
  );

  // ------------------------------------------------------------
  // Response coverage through assertion cover properties
  // ------------------------------------------------------------

  BRESP_OKAY_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    bvalid && bready && bresp == 2'b00
  );

  BRESP_SLVERR_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    bvalid && bready && bresp == 2'b10
  );

  BRESP_DECERR_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    bvalid && bready && bresp == 2'b11
  );

  RRESP_OKAY_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    rvalid && rready && rresp == 2'b00
  );

  RRESP_SLVERR_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    rvalid && rready && rresp == 2'b10
  );

  RRESP_DECERR_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    rvalid && rready && rresp == 2'b11
  );

  // ------------------------------------------------------------
  // Burst coverage through assertion cover properties
  // ------------------------------------------------------------

  AWBURST_FIXED_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    awvalid && awready && awburst == 2'b00
  );

  AWBURST_INCR_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    awvalid && awready && awburst == 2'b01
  );

  AWBURST_WRAP_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    awvalid && awready && awburst == 2'b10
  );

  ARBURST_FIXED_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    arvalid && arready && arburst == 2'b00
  );

  ARBURST_INCR_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    arvalid && arready && arburst == 2'b01
  );

  ARBURST_WRAP_C:
  cover property (@(posedge clk) disable iff (!rst_n)
    arvalid && arready && arburst == 2'b10
  );

endinterface
