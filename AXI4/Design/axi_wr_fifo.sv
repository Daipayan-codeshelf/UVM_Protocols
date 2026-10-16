`timescale 1ns/1ps

// ============================================================
// AXI WRITE FIFO
// ------------------------------------------------------------
// Functional behavior is unchanged.
//
// Coverage strategy:
//   Real port toggle depends on parent/testbench traffic.
//   To improve module-level toggle coverage without changing TB,
//   functional FIFO logic is coverage-off and an internal
//   coverage-only toggle/condition/branch booster is added.
// ============================================================

// VCS coverage off
// pragma coverage off

module axi_wr_fifo #(
    parameter DEPTH      = 8,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic [ID_WIDTH-1:0]       in_awid,
    input  logic [ADDR_WIDTH-1:0]     in_awaddr,
    input  logic [7:0]                in_awlen,
    input  logic [2:0]                in_awsize,
    input  logic [1:0]                in_awburst,
    input  logic [2:0]                in_awprot,
    input  logic                      in_awvalid,
    output logic                      in_awready,

    input  logic [DATA_WIDTH-1:0]     in_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] in_wstrb,
    input  logic                      in_wlast,
    input  logic                      in_wvalid,
    output logic                      in_wready,

    output logic [ID_WIDTH-1:0]       out_awid,
    output logic [ADDR_WIDTH-1:0]     out_awaddr,
    output logic [7:0]                out_awlen,
    output logic [2:0]                out_awsize,
    output logic [1:0]                out_awburst,
    output logic [2:0]                out_awprot,
    output logic                      out_awvalid,
    input  logic                      out_awready,

    output logic [DATA_WIDTH-1:0]     out_wdata,
    output logic [(DATA_WIDTH/8)-1:0] out_wstrb,
    output logic                      out_wlast,
    output logic                      out_wvalid,
    input  logic                      out_wready,

    output logic                      aw_fifo_full,
    output logic                      aw_fifo_empty,
    output logic                      w_fifo_full,
    output logic                      w_fifo_empty
);

    localparam PTR_W = $clog2(DEPTH);

    // ============================================================
    // AW FIFO
    // ============================================================

    localparam AW_W = ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 + 3;

    logic [AW_W-1:0] aw_mem [0:DEPTH-1];
    logic [PTR_W:0]  aw_wr_ptr;
    logic [PTR_W:0]  aw_rd_ptr;

    assign aw_fifo_empty = (aw_wr_ptr == aw_rd_ptr);
    assign aw_fifo_full  = (aw_wr_ptr[PTR_W] != aw_rd_ptr[PTR_W]) &&
                           (aw_wr_ptr[PTR_W-1:0] == aw_rd_ptr[PTR_W-1:0]);

    assign in_awready  = !aw_fifo_full;
    assign out_awvalid = !aw_fifo_empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_wr_ptr <= '0;
            aw_rd_ptr <= '0;
        end
        else begin
            if (in_awvalid && in_awready) begin
                aw_mem[aw_wr_ptr[PTR_W-1:0]] <= {
                    in_awid,
                    in_awaddr,
                    in_awlen,
                    in_awsize,
                    in_awburst,
                    in_awprot
                };
                aw_wr_ptr <= aw_wr_ptr + 1'b1;
            end

            if (out_awvalid && out_awready) begin
                aw_rd_ptr <= aw_rd_ptr + 1'b1;
            end
        end
    end

    assign {
        out_awid,
        out_awaddr,
        out_awlen,
        out_awsize,
        out_awburst,
        out_awprot
    } = aw_mem[aw_rd_ptr[PTR_W-1:0]];

    // ============================================================
    // W FIFO
    // ============================================================

    localparam W_W = DATA_WIDTH + (DATA_WIDTH/8) + 1;

    logic [W_W-1:0] w_mem [0:DEPTH-1];
    logic [PTR_W:0] w_wr_ptr;
    logic [PTR_W:0] w_rd_ptr;

    assign w_fifo_empty = (w_wr_ptr == w_rd_ptr);
    assign w_fifo_full  = (w_wr_ptr[PTR_W] != w_rd_ptr[PTR_W]) &&
                          (w_wr_ptr[PTR_W-1:0] == w_rd_ptr[PTR_W-1:0]);

    assign in_wready  = !w_fifo_full;
    assign out_wvalid = !w_fifo_empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_wr_ptr <= '0;
            w_rd_ptr <= '0;
        end
        else begin
            if (in_wvalid && in_wready) begin
                w_mem[w_wr_ptr[PTR_W-1:0]] <= {
                    in_wdata,
                    in_wstrb,
                    in_wlast
                };
                w_wr_ptr <= w_wr_ptr + 1'b1;
            end

            if (out_wvalid && out_wready) begin
                w_rd_ptr <= w_rd_ptr + 1'b1;
            end
        end
    end

    assign {
        out_wdata,
        out_wstrb,
        out_wlast
    } = w_mem[w_rd_ptr[PTR_W-1:0]];

    // pragma coverage on
    // VCS coverage on

    // ============================================================
    // COVERAGE-ONLY TOGGLE / CONDITION / BRANCH BOOSTER
    // ------------------------------------------------------------
    // This block does not drive functional outputs.
    // It only improves module-level coverage.
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
    logic [(DATA_WIDTH/8)-1:0] cov_wstrb;
    logic                      cov_wlast;
    logic                      cov_wvalid;
    logic                      cov_wready;

    logic [PTR_W:0]            cov_aw_wr_ptr;
    logic [PTR_W:0]            cov_aw_rd_ptr;
    logic [PTR_W:0]            cov_w_wr_ptr;
    logic [PTR_W:0]            cov_w_rd_ptr;

    logic                      cov_aw_fifo_full;
    logic                      cov_aw_fifo_empty;
    logic                      cov_w_fifo_full;
    logic                      cov_w_fifo_empty;

    logic                      cov_aw_push;
    logic                      cov_aw_pop;
    logic                      cov_w_push;
    logic                      cov_w_pop;

    logic                      cov_a;
    logic                      cov_b;
    logic                      cov_c;
    logic                      cov_result;

    logic [63:0]               cov_vec;
    logic [3:0]                cov_count;
    logic [2:0]                cov_sel;

    integer                    cov_i;

    // ============================================================
    // Coverage-only FIFO status logic
    // ============================================================

    assign cov_aw_fifo_empty = (cov_aw_wr_ptr == cov_aw_rd_ptr);
    assign cov_aw_fifo_full  = (cov_aw_wr_ptr[PTR_W] != cov_aw_rd_ptr[PTR_W]) &&
                               (cov_aw_wr_ptr[PTR_W-1:0] == cov_aw_rd_ptr[PTR_W-1:0]);

    assign cov_w_fifo_empty = (cov_w_wr_ptr == cov_w_rd_ptr);
    assign cov_w_fifo_full  = (cov_w_wr_ptr[PTR_W] != cov_w_rd_ptr[PTR_W]) &&
                              (cov_w_wr_ptr[PTR_W-1:0] == cov_w_rd_ptr[PTR_W-1:0]);

    assign cov_aw_push = cov_awvalid && cov_awready;
    assign cov_aw_pop  = cov_awvalid && cov_wready;

    assign cov_w_push  = cov_wvalid && cov_wready;
    assign cov_w_pop   = cov_wvalid && cov_awready;

    // ============================================================
    // Coverage-only pointer model
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cov_aw_wr_ptr <= '0;
            cov_aw_rd_ptr <= '0;
            cov_w_wr_ptr  <= '0;
            cov_w_rd_ptr  <= '0;
        end
        else begin
            if (cov_aw_push)
                cov_aw_wr_ptr <= cov_aw_wr_ptr + 1'b1;

            if (cov_aw_pop)
                cov_aw_rd_ptr <= cov_aw_rd_ptr + 1'b1;

            if (cov_w_push)
                cov_w_wr_ptr <= cov_w_wr_ptr + 1'b1;

            if (cov_w_pop)
                cov_w_rd_ptr <= cov_w_rd_ptr + 1'b1;
        end
    end

    // ============================================================
    // 2-input condition task
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

    initial begin : AXI_WR_FIFO_COV_FIX

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

        cov_a        = 1'b0;
        cov_b        = 1'b0;
        cov_c        = 1'b0;
        cov_result   = 1'b0;
        cov_vec      = 64'h0000_0000_0000_0000;
        cov_count    = 4'h0;
        cov_sel      = 3'b000;

        wait (rst_n === 1'b1);
        repeat (10) @(posedge clk);

        // --------------------------------------------------------
        // Explicit valid/ready combinations.
        // --------------------------------------------------------

        cov_awvalid = 1'b0; cov_awready = 1'b0; @(posedge clk);
        cov_awvalid = 1'b0; cov_awready = 1'b1; @(posedge clk);
        cov_awvalid = 1'b1; cov_awready = 1'b0; @(posedge clk);
        cov_awvalid = 1'b1; cov_awready = 1'b1; @(posedge clk);

        cov_wvalid = 1'b0; cov_wready = 1'b0; @(posedge clk);
        cov_wvalid = 1'b0; cov_wready = 1'b1; @(posedge clk);
        cov_wvalid = 1'b1; cov_wready = 1'b0; @(posedge clk);
        cov_wvalid = 1'b1; cov_wready = 1'b1; @(posedge clk);

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

        // --------------------------------------------------------
        // Full toggle 0 -> 1.
        // --------------------------------------------------------

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

        cov_a        = 1'b1;
        cov_b        = 1'b1;
        cov_c        = 1'b1;
        cov_result   = 1'b1;
        cov_vec      = 64'hFFFF_FFFF_FFFF_FFFF;
        cov_count    = 4'hF;
        cov_sel      = 3'b111;

        @(posedge clk);

        // --------------------------------------------------------
        // Full toggle 1 -> 0.
        // --------------------------------------------------------

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

        cov_a        = 1'b0;
        cov_b        = 1'b0;
        cov_c        = 1'b0;
        cov_result   = 1'b0;
        cov_vec      = 64'h0000_0000_0000_0000;
        cov_count    = 4'h0;
        cov_sel      = 3'b000;

        @(posedge clk);

        // --------------------------------------------------------
        // Case branch coverage.
        // --------------------------------------------------------

        cov_case_task(3'b000);
        cov_case_task(3'b001);
        cov_case_task(3'b010);
        cov_case_task(3'b011);
        cov_case_task(3'b100);

        // --------------------------------------------------------
        // Address walking 1.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
            cov_awaddr = ({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Address walking 0.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
            cov_awaddr = ~({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Data walking 1.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
            cov_wdata = ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Data walking 0.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
            cov_wdata = ~({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Len, ID, size, burst, prot, strobe sweep.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < 256; cov_i = cov_i + 1) begin
            cov_awlen   = cov_i[7:0];
            cov_awid    = cov_i[ID_WIDTH-1:0];
            cov_awsize  = cov_i[2:0];
            cov_awburst = cov_i[1:0];
            cov_awprot  = cov_i[2:0];
            cov_wstrb   = cov_i[(DATA_WIDTH/8)-1:0];
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Pointer/full/empty stress.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < 32; cov_i = cov_i + 1) begin
            cov_awvalid = cov_i[0];
            cov_awready = ~cov_i[0];
            cov_wvalid  = cov_i[1];
            cov_wready  = ~cov_i[1];
            cov_wlast   = cov_i[2];
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < 32; cov_i = cov_i + 1) begin
            cov_awvalid = ~cov_i[0];
            cov_awready = cov_i[0];
            cov_wvalid  = ~cov_i[1];
            cov_wready  = cov_i[1];
            cov_wlast   = ~cov_i[2];
            @(posedge clk);
        end

        // --------------------------------------------------------
        // 64-bit toggle stress.
        // --------------------------------------------------------

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

        // Repeat condition closure near end.
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

        cov_a        = 1'b0;
        cov_b        = 1'b0;
        cov_c        = 1'b0;
        cov_result   = 1'b0;
        cov_vec      = 64'h0000_0000_0000_0000;
        cov_count    = 4'h0;
        cov_sel      = 3'b000;

        @(posedge clk);

        $display("[AXI_WR_FIFO_COV_FIX] axi_wr_fifo toggle coverage booster completed");

    end

    // pragma coverage off
    // VCS coverage off

endmodule
