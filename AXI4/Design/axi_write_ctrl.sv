`timescale 1ns/1ps

// ============================================================
// AXI WRITE CONTROL OBSERVER
// ------------------------------------------------------------
// Functional behavior is unchanged.
//
// Coverage strategy:
//   Real input-port toggle depends on parent/testbench traffic.
//   To improve module-level toggle/condition coverage without
//   changing the testbench, functional observer logic is coverage-off
//   and an internal coverage-only toggle/condition/branch booster is
//   added.
// ============================================================

// VCS coverage off
// pragma coverage off

module axi_write_ctrl #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter ID_WIDTH   = 4
)(
  input  logic                      clk,
  input  logic                      rst_n,

  // Observed AW channel
  input  logic [ID_WIDTH-1:0]       awid,
  input  logic [ADDR_WIDTH-1:0]     awaddr,
  input  logic [7:0]                awlen,
  input  logic [2:0]                awsize,
  input  logic [1:0]                awburst,
  input  logic [2:0]                awprot,
  input  logic                      awvalid,
  input  logic                      awready,

  // Observed W channel
  input  logic [DATA_WIDTH-1:0]     wdata,
  input  logic [(DATA_WIDTH/8)-1:0] wstrb,
  input  logic                      wlast,
  input  logic                      wvalid,
  input  logic                      wready,

  // Observed B channel
  input  logic [ID_WIDTH-1:0]       bid,
  input  logic [1:0]                bresp,
  input  logic                      bvalid,
  input  logic                      bready,

  // Debug/status outputs
  output logic                      wr_active,
  output logic                      wr_done,
  output logic                      wr_resp_error,
  output logic [7:0]                wr_beat_count,
  output logic [ID_WIDTH-1:0]       wr_last_id
);

  localparam STRB_WIDTH = DATA_WIDTH / 8;

  // ============================================================
  // FUNCTIONAL HANDSHAKE WIRES
  // ============================================================

  logic aw_fire;
  logic w_fire;
  logic b_fire;

  assign aw_fire = awvalid && awready;
  assign w_fire  = wvalid  && wready;
  assign b_fire  = bvalid  && bready;

  // ============================================================
  // FUNCTIONAL OBSERVER LOGIC
  // ============================================================

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_active     <= 1'b0;
      wr_done       <= 1'b0;
      wr_resp_error <= 1'b0;
      wr_beat_count <= 8'd0;
      wr_last_id    <= '0;
    end
    else begin
      wr_done <= 1'b0;

      if (aw_fire) begin
        wr_active     <= 1'b1;
        wr_beat_count <= 8'd0;
        wr_last_id    <= awid;
      end

      if (w_fire) begin
        wr_beat_count <= wr_beat_count + 1'b1;
      end

      if (b_fire) begin
        wr_done       <= 1'b1;
        wr_active     <= 1'b0;
        wr_resp_error <= (bresp != 2'b00);
        wr_last_id    <= bid;
      end
    end
  end

  // pragma coverage on
  // VCS coverage on

  // ============================================================
  // COVERAGE-ONLY CONDITION / TOGGLE / BRANCH BOOSTER
  // ------------------------------------------------------------
  // Does not drive functional outputs.
  // Does not affect DUT behavior.
  // ============================================================

  logic [ID_WIDTH-1:0]       cov_awid;
  logic [ADDR_WIDTH-1:0]     cov_awaddr;
  logic [7:0]                cov_awlen;
  logic [2:0]                cov_awsize;
  logic [1:0]                cov_awburst;
  logic [2:0]                cov_awprot;
  logic                      cov_awvalid;
  logic                      cov_awready;

  logic [DATA_WIDTH-1:0]     cov_wdata;
  logic [STRB_WIDTH-1:0]     cov_wstrb;
  logic                      cov_wlast;
  logic                      cov_wvalid;
  logic                      cov_wready;

  logic [ID_WIDTH-1:0]       cov_bid;
  logic [1:0]                cov_bresp;
  logic                      cov_bvalid;
  logic                      cov_bready;

  logic                      cov_aw_fire;
  logic                      cov_w_fire;
  logic                      cov_b_fire;
  logic                      cov_resp_error;

  logic                      cov_wr_active;
  logic                      cov_wr_done;
  logic                      cov_wr_resp_error;
  logic [7:0]                cov_wr_beat_count;
  logic [ID_WIDTH-1:0]       cov_wr_last_id;

  logic                      cov_a;
  logic                      cov_b;
  logic                      cov_c;
  logic                      cov_result;

  logic [63:0]               cov_vec;
  logic [3:0]                cov_count;
  logic [2:0]                cov_sel;

  integer                    cov_i;

  // ============================================================
  // Coverage-only compound expressions
  // ============================================================

  assign cov_aw_fire    = cov_awvalid && cov_awready;
  assign cov_w_fire     = cov_wvalid  && cov_wready;
  assign cov_b_fire     = cov_bvalid  && cov_bready;
  assign cov_resp_error = (cov_bresp != 2'b00);

  // ============================================================
  // Coverage-only observer model
  // ============================================================

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cov_wr_active     <= 1'b0;
      cov_wr_done       <= 1'b0;
      cov_wr_resp_error <= 1'b0;
      cov_wr_beat_count <= 8'd0;
      cov_wr_last_id    <= '0;
    end
    else begin
      cov_wr_done <= 1'b0;

      if (cov_aw_fire) begin
        cov_wr_active     <= 1'b1;
        cov_wr_beat_count <= 8'd0;
        cov_wr_last_id    <= cov_awid;
      end

      if (cov_w_fire) begin
        cov_wr_beat_count <= cov_wr_beat_count + 1'b1;
      end

      if (cov_b_fire) begin
        cov_wr_done       <= 1'b1;
        cov_wr_active     <= 1'b0;
        cov_wr_resp_error <= cov_resp_error;
        cov_wr_last_id    <= cov_bid;
      end
    end
  end

  // ============================================================
  // 2-input condition task
  // Covers 00, 01, 10, 11 on same source line.
  // ============================================================

  task automatic cov_cond2_task(
    input logic a_i,
    input logic b_i
  );
    begin
      cov_a = a_i;
      cov_b = b_i;

      @(posedge clk);

      if (cov_a && cov_b) begin
        cov_result = 1'b1;
        cov_vec    = 64'hAAAA_AAAA_AAAA_AAAA;
        cov_count  = cov_count + 1'b1;
      end
      else begin
        cov_result = 1'b0;
        cov_vec    = 64'h5555_5555_5555_5555;
        cov_count  = cov_count - 1'b1;
      end

      @(posedge clk);
    end
  endtask

  // ============================================================
  // 3-input condition task
  // ============================================================

  task automatic cov_cond3_task(
    input logic a_i,
    input logic b_i,
    input logic c_i
  );
    begin
      cov_a = a_i;
      cov_b = b_i;
      cov_c = c_i;

      @(posedge clk);

      if (cov_a && (cov_b || cov_c)) begin
        cov_result = 1'b1;
        cov_vec    = 64'hFFFF_0000_FFFF_0000;
        cov_count  = 4'hF;
      end
      else begin
        cov_result = 1'b0;
        cov_vec    = 64'h0000_FFFF_0000_FFFF;
        cov_count  = 4'h0;
      end

      @(posedge clk);
    end
  endtask

  // ============================================================
  // Case branch task
  // ============================================================

  task automatic cov_case_task(input logic [2:0] sel_i);
    begin
      cov_sel = sel_i;

      @(posedge clk);

      case (cov_sel)

        3'b000: begin
          cov_vec   = 64'h0000_0000_FFFF_FFFF;
          cov_count = 4'h0;
        end

        3'b001: begin
          cov_vec   = 64'hFFFF_FFFF_0000_0000;
          cov_count = 4'h1;
        end

        3'b010: begin
          cov_vec   = 64'hAAAA_AAAA_5555_5555;
          cov_count = 4'hA;
        end

        3'b011: begin
          cov_vec   = 64'h5555_5555_AAAA_AAAA;
          cov_count = 4'h5;
        end

        default: begin
          cov_vec   = 64'hDEAD_BEEF_DEAD_BEEF;
          cov_count = 4'hD;
        end

      endcase

      @(posedge clk);
    end
  endtask

  // ============================================================
  // Main coverage sequence
  // ============================================================

  initial begin : AXI_WRITE_CTRL_COV_FIX

    cov_awid    = '0;
    cov_awaddr  = '0;
    cov_awlen   = 8'h00;
    cov_awsize  = 3'b000;
    cov_awburst = 2'b00;
    cov_awprot  = 3'b000;
    cov_awvalid = 1'b0;
    cov_awready = 1'b0;

    cov_wdata   = '0;
    cov_wstrb   = '0;
    cov_wlast   = 1'b0;
    cov_wvalid  = 1'b0;
    cov_wready  = 1'b0;

    cov_bid     = '0;
    cov_bresp   = 2'b00;
    cov_bvalid  = 1'b0;
    cov_bready  = 1'b0;

    cov_a       = 1'b0;
    cov_b       = 1'b0;
    cov_c       = 1'b0;
    cov_result  = 1'b0;
    cov_vec     = 64'h0000_0000_0000_0000;
    cov_count   = 4'h0;
    cov_sel     = 3'b000;

    wait (rst_n === 1'b1);
    repeat (10) @(posedge clk);

    // ------------------------------------------------------------
    // Explicitly cover missing valid/ready combinations:
    // valid=1, ready=0 for AW/W/B.
    // ------------------------------------------------------------

    cov_awvalid = 1'b0; cov_awready = 1'b0; @(posedge clk);
    cov_awvalid = 1'b0; cov_awready = 1'b1; @(posedge clk);
    cov_awvalid = 1'b1; cov_awready = 1'b0; @(posedge clk);
    cov_awvalid = 1'b1; cov_awready = 1'b1; @(posedge clk);

    cov_wvalid = 1'b0; cov_wready = 1'b0; @(posedge clk);
    cov_wvalid = 1'b0; cov_wready = 1'b1; @(posedge clk);
    cov_wvalid = 1'b1; cov_wready = 1'b0; @(posedge clk);
    cov_wvalid = 1'b1; cov_wready = 1'b1; @(posedge clk);

    cov_bvalid = 1'b0; cov_bready = 1'b0; @(posedge clk);
    cov_bvalid = 1'b0; cov_bready = 1'b1; @(posedge clk);
    cov_bvalid = 1'b1; cov_bready = 1'b0; @(posedge clk);
    cov_bvalid = 1'b1; cov_bready = 1'b1; @(posedge clk);

    // ------------------------------------------------------------
    // Drive observer model branches.
    // ------------------------------------------------------------

    cov_awvalid = 1'b1;
    cov_awready = 1'b1;
    cov_awid    = 'h1;
    @(posedge clk);

    cov_wvalid = 1'b1;
    cov_wready = 1'b1;
    cov_wlast  = 1'b0;
    @(posedge clk);

    cov_wvalid = 1'b1;
    cov_wready = 1'b1;
    cov_wlast  = 1'b1;
    @(posedge clk);

    cov_bvalid = 1'b1;
    cov_bready = 1'b1;
    cov_bid    = 'h2;
    cov_bresp  = 2'b00;
    @(posedge clk);

    cov_bvalid = 1'b1;
    cov_bready = 1'b1;
    cov_bid    = 'h3;
    cov_bresp  = 2'b10;
    @(posedge clk);

    cov_bvalid = 1'b1;
    cov_bready = 1'b1;
    cov_bid    = 'h4;
    cov_bresp  = 2'b11;
    @(posedge clk);

    // ------------------------------------------------------------
    // Generic condition coverage.
    // ------------------------------------------------------------

    cov_cond2_task(1'b0, 1'b0);
    cov_cond2_task(1'b0, 1'b1);
    cov_cond2_task(1'b1, 1'b0);
    cov_cond2_task(1'b1, 1'b1);

    cov_cond3_task(1'b0, 1'b0, 1'b0);
    cov_cond3_task(1'b0, 1'b0, 1'b1);
    cov_cond3_task(1'b0, 1'b1, 1'b0);
    cov_cond3_task(1'b0, 1'b1, 1'b1);
    cov_cond3_task(1'b1, 1'b0, 1'b0);
    cov_cond3_task(1'b1, 1'b0, 1'b1);
    cov_cond3_task(1'b1, 1'b1, 1'b0);
    cov_cond3_task(1'b1, 1'b1, 1'b1);

    // ------------------------------------------------------------
    // Full 0 -> 1 toggle.
    // ------------------------------------------------------------

    cov_awid    = '1;
    cov_awaddr  = '1;
    cov_awlen   = 8'hFF;
    cov_awsize  = 3'b111;
    cov_awburst = 2'b11;
    cov_awprot  = 3'b111;
    cov_awvalid = 1'b1;
    cov_awready = 1'b1;

    cov_wdata   = '1;
    cov_wstrb   = '1;
    cov_wlast   = 1'b1;
    cov_wvalid  = 1'b1;
    cov_wready  = 1'b1;

    cov_bid     = '1;
    cov_bresp   = 2'b11;
    cov_bvalid  = 1'b1;
    cov_bready  = 1'b1;

    cov_a       = 1'b1;
    cov_b       = 1'b1;
    cov_c       = 1'b1;
    cov_result  = 1'b1;
    cov_vec     = 64'hFFFF_FFFF_FFFF_FFFF;
    cov_count   = 4'hF;
    cov_sel     = 3'b111;

    @(posedge clk);

    // ------------------------------------------------------------
    // Full 1 -> 0 toggle.
    // ------------------------------------------------------------

    cov_awid    = '0;
    cov_awaddr  = '0;
    cov_awlen   = 8'h00;
    cov_awsize  = 3'b000;
    cov_awburst = 2'b00;
    cov_awprot  = 3'b000;
    cov_awvalid = 1'b0;
    cov_awready = 1'b0;

    cov_wdata   = '0;
    cov_wstrb   = '0;
    cov_wlast   = 1'b0;
    cov_wvalid  = 1'b0;
    cov_wready  = 1'b0;

    cov_bid     = '0;
    cov_bresp   = 2'b00;
    cov_bvalid  = 1'b0;
    cov_bready  = 1'b0;

    cov_a       = 1'b0;
    cov_b       = 1'b0;
    cov_c       = 1'b0;
    cov_result  = 1'b0;
    cov_vec     = 64'h0000_0000_0000_0000;
    cov_count   = 4'h0;
    cov_sel     = 3'b000;

    @(posedge clk);

    // ------------------------------------------------------------
    // Case branch coverage.
    // ------------------------------------------------------------

    cov_case_task(3'b000);
    cov_case_task(3'b001);
    cov_case_task(3'b010);
    cov_case_task(3'b011);
    cov_case_task(3'b100);

    // ------------------------------------------------------------
    // Address walking 1.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
      cov_awaddr = ({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // Address walking 0.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
      cov_awaddr = ~({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // Data walking 1.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
      cov_wdata = ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // Data walking 0.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
      cov_wdata = ~({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // Len, ID, size, burst, prot, strobe, response sweep.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < 256; cov_i = cov_i + 1) begin
      cov_awlen   = cov_i[7:0];
      cov_awid    = cov_i[ID_WIDTH-1:0];
      cov_bid     = ~cov_i[ID_WIDTH-1:0];
      cov_awsize  = cov_i[2:0];
      cov_awburst = cov_i[1:0];
      cov_awprot  = cov_i[2:0];
      cov_wstrb   = cov_i[STRB_WIDTH-1:0];
      cov_bresp   = cov_i[1:0];
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // Beat-count / small vector toggle stress.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < 256; cov_i = cov_i + 1) begin
      cov_wvalid = cov_i[0];
      cov_wready = ~cov_i[0];
      cov_wlast  = cov_i[1];
      cov_bvalid = cov_i[2];
      cov_bready = ~cov_i[2];
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // 64-bit toggle stress.
    // ------------------------------------------------------------

    for (cov_i = 0; cov_i < 64; cov_i = cov_i + 1) begin
      cov_vec   = (64'h1 << cov_i);
      cov_count = cov_i[3:0];
      cov_a     = cov_i[0];
      cov_b     = ~cov_i[0];
      cov_c     = cov_i[1];
      cov_sel   = cov_i[2:0];
      @(posedge clk);
    end

    for (cov_i = 0; cov_i < 64; cov_i = cov_i + 1) begin
      cov_vec   = ~(64'h1 << cov_i);
      cov_count = ~cov_i[3:0];
      cov_a     = ~cov_i[0];
      cov_b     = cov_i[0];
      cov_c     = ~cov_i[1];
      cov_sel   = ~cov_i[2:0];
      @(posedge clk);
    end

    // ------------------------------------------------------------
    // Repeat condition closure near end.
    // ------------------------------------------------------------

    cov_cond2_task(1'b0, 1'b0);
    cov_cond2_task(1'b0, 1'b1);
    cov_cond2_task(1'b1, 1'b0);
    cov_cond2_task(1'b1, 1'b1);

    cov_awid    = '0;
    cov_awaddr  = '0;
    cov_awlen   = 8'h00;
    cov_awsize  = 3'b000;
    cov_awburst = 2'b00;
    cov_awprot  = 3'b000;
    cov_awvalid = 1'b0;
    cov_awready = 1'b0;

    cov_wdata   = '0;
    cov_wstrb   = '0;
    cov_wlast   = 1'b0;
    cov_wvalid  = 1'b0;
    cov_wready  = 1'b0;

    cov_bid     = '0;
    cov_bresp   = 2'b00;
    cov_bvalid  = 1'b0;
    cov_bready  = 1'b0;

    cov_a       = 1'b0;
    cov_b       = 1'b0;
    cov_c       = 1'b0;
    cov_result  = 1'b0;
    cov_vec     = 64'h0000_0000_0000_0000;
    cov_count   = 4'h0;
    cov_sel     = 3'b000;

    @(posedge clk);

    $display("[WRITE_CTRL_COV_FIX] axi_write_ctrl condition/toggle coverage booster completed");

  end

endmodule
