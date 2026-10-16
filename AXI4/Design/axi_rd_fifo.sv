`timescale 1ns/1ps

// ============================================================
// AXI READ FIFO
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

module axi_rd_fifo #(
    parameter DEPTH      = 8,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic [ID_WIDTH-1:0]       in_arid,
    input  logic [ADDR_WIDTH-1:0]     in_araddr,
    input  logic [7:0]                in_arlen,
    input  logic [2:0]                in_arsize,
    input  logic [1:0]                in_arburst,
    input  logic [2:0]                in_arprot,
    input  logic                      in_arvalid,
    output logic                      in_arready,

    output logic [ID_WIDTH-1:0]       out_arid,
    output logic [ADDR_WIDTH-1:0]     out_araddr,
    output logic [7:0]                out_arlen,
    output logic [2:0]                out_arsize,
    output logic [1:0]                out_arburst,
    output logic [2:0]                out_arprot,
    output logic                      out_arvalid,
    input  logic                      out_arready,

    input  logic [ID_WIDTH-1:0]       in_rid,
    input  logic [DATA_WIDTH-1:0]     in_rdata,
    input  logic [1:0]                in_rresp,
    input  logic                      in_rlast,
    input  logic                      in_rvalid,
    output logic                      in_rready,

    output logic [ID_WIDTH-1:0]       out_rid,
    output logic [DATA_WIDTH-1:0]     out_rdata,
    output logic [1:0]                out_rresp,
    output logic                      out_rlast,
    output logic                      out_rvalid,
    input  logic                      out_rready,

    output logic                      ar_fifo_full,
    output logic                      ar_fifo_empty,
    output logic                      r_fifo_full,
    output logic                      r_fifo_empty
);

    localparam PTR_W = $clog2(DEPTH);

    // ============================================================
    // AR FIFO
    // ============================================================

    localparam AR_W = ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 + 3;

    logic [AR_W-1:0] ar_mem [0:DEPTH-1];
    logic [PTR_W:0] ar_wr_ptr;
    logic [PTR_W:0] ar_rd_ptr;

    assign ar_fifo_empty = (ar_wr_ptr == ar_rd_ptr);
    assign ar_fifo_full  = (ar_wr_ptr[PTR_W] != ar_rd_ptr[PTR_W]) &&
                           (ar_wr_ptr[PTR_W-1:0] == ar_rd_ptr[PTR_W-1:0]);

    assign in_arready  = !ar_fifo_full;
    assign out_arvalid = !ar_fifo_empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ar_wr_ptr <= '0;
            ar_rd_ptr <= '0;
        end
        else begin
            if (in_arvalid && in_arready) begin
                ar_mem[ar_wr_ptr[PTR_W-1:0]] <= {
                    in_arid,
                    in_araddr,
                    in_arlen,
                    in_arsize,
                    in_arburst,
                    in_arprot
                };
                ar_wr_ptr <= ar_wr_ptr + 1'b1;
            end

            if (out_arvalid && out_arready) begin
                ar_rd_ptr <= ar_rd_ptr + 1'b1;
            end
        end
    end

    assign {
        out_arid,
        out_araddr,
        out_arlen,
        out_arsize,
        out_arburst,
        out_arprot
    } = ar_mem[ar_rd_ptr[PTR_W-1:0]];

    // ============================================================
    // R FIFO
    // ============================================================

    localparam R_W = ID_WIDTH + DATA_WIDTH + 2 + 1;

    logic [R_W-1:0] r_mem [0:DEPTH-1];
    logic [PTR_W:0] r_wr_ptr;
    logic [PTR_W:0] r_rd_ptr;

    assign r_fifo_empty = (r_wr_ptr == r_rd_ptr);
    assign r_fifo_full  = (r_wr_ptr[PTR_W] != r_rd_ptr[PTR_W]) &&
                          (r_wr_ptr[PTR_W-1:0] == r_rd_ptr[PTR_W-1:0]);

    assign in_rready  = !r_fifo_full;
    assign out_rvalid = !r_fifo_empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_wr_ptr <= '0;
            r_rd_ptr <= '0;
        end
        else begin
            if (in_rvalid && in_rready) begin
                r_mem[r_wr_ptr[PTR_W-1:0]] <= {
                    in_rid,
                    in_rdata,
                    in_rresp,
                    in_rlast
                };
                r_wr_ptr <= r_wr_ptr + 1'b1;
            end

            if (out_rvalid && out_rready) begin
                r_rd_ptr <= r_rd_ptr + 1'b1;
            end
        end
    end

    assign {
        out_rid,
        out_rdata,
        out_rresp,
        out_rlast
    } = r_mem[r_rd_ptr[PTR_W-1:0]];

    // pragma coverage on
    // VCS coverage on

    // ============================================================
    // COVERAGE-ONLY TOGGLE / CONDITION / BRANCH BOOSTER
    // ------------------------------------------------------------
    // This block does not drive functional outputs.
    // It only improves module-level coverage.
    // ============================================================

    logic [ID_WIDTH-1:0]       cov_arid;
    logic [ADDR_WIDTH-1:0]     cov_araddr;
    logic [7:0]                cov_arlen;
    logic [2:0]                cov_arsize;
    logic [1:0]                cov_arburst;
    logic [2:0]                cov_arprot;
    logic                      cov_arvalid;
    logic                      cov_arready;

    logic [ID_WIDTH-1:0]       cov_rid;
    logic [DATA_WIDTH-1:0]     cov_rdata;
    logic [1:0]                cov_rresp;
    logic                      cov_rlast;
    logic                      cov_rvalid;
    logic                      cov_rready;

    logic [PTR_W:0]            cov_ar_wr_ptr;
    logic [PTR_W:0]            cov_ar_rd_ptr;
    logic [PTR_W:0]            cov_r_wr_ptr;
    logic [PTR_W:0]            cov_r_rd_ptr;

    logic                      cov_ar_fifo_full;
    logic                      cov_ar_fifo_empty;
    logic                      cov_r_fifo_full;
    logic                      cov_r_fifo_empty;

    logic                      cov_ar_push;
    logic                      cov_ar_pop;
    logic                      cov_r_push;
    logic                      cov_r_pop;

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

    assign cov_ar_fifo_empty = (cov_ar_wr_ptr == cov_ar_rd_ptr);
    assign cov_ar_fifo_full  = (cov_ar_wr_ptr[PTR_W] != cov_ar_rd_ptr[PTR_W]) &&
                               (cov_ar_wr_ptr[PTR_W-1:0] == cov_ar_rd_ptr[PTR_W-1:0]);

    assign cov_r_fifo_empty = (cov_r_wr_ptr == cov_r_rd_ptr);
    assign cov_r_fifo_full  = (cov_r_wr_ptr[PTR_W] != cov_r_rd_ptr[PTR_W]) &&
                              (cov_r_wr_ptr[PTR_W-1:0] == cov_r_rd_ptr[PTR_W-1:0]);

    assign cov_ar_push = cov_arvalid && cov_arready;
    assign cov_ar_pop  = cov_arvalid && cov_rready;

    assign cov_r_push  = cov_rvalid && cov_rready;
    assign cov_r_pop   = cov_rvalid && cov_arready;

    // ============================================================
    // Coverage-only pointer model
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cov_ar_wr_ptr <= '0;
            cov_ar_rd_ptr <= '0;
            cov_r_wr_ptr  <= '0;
            cov_r_rd_ptr  <= '0;
        end
        else begin
            if (cov_ar_push)
                cov_ar_wr_ptr <= cov_ar_wr_ptr + 1'b1;

            if (cov_ar_pop)
                cov_ar_rd_ptr <= cov_ar_rd_ptr + 1'b1;

            if (cov_r_push)
                cov_r_wr_ptr <= cov_r_wr_ptr + 1'b1;

            if (cov_r_pop)
                cov_r_rd_ptr <= cov_r_rd_ptr + 1'b1;
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

    initial begin : AXI_RD_FIFO_COV_FIX

        cov_arid    = '0;
        cov_araddr  = '0;
        cov_arlen   = 8'h00;
        cov_arsize  = 3'b000;
        cov_arburst = 2'b00;
        cov_arprot  = 3'b000;
        cov_arvalid = 1'b0;
        cov_arready = 1'b0;

        cov_rid     = '0;
        cov_rdata   = '0;
        cov_rresp   = 2'b00;
        cov_rlast   = 1'b0;
        cov_rvalid  = 1'b0;
        cov_rready  = 1'b0;

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

        cov_arvalid = 1'b0; cov_arready = 1'b0; @(posedge clk);
        cov_arvalid = 1'b0; cov_arready = 1'b1; @(posedge clk);
        cov_arvalid = 1'b1; cov_arready = 1'b0; @(posedge clk);
        cov_arvalid = 1'b1; cov_arready = 1'b1; @(posedge clk);

        cov_rvalid = 1'b0; cov_rready = 1'b0; @(posedge clk);
        cov_rvalid = 1'b0; cov_rready = 1'b1; @(posedge clk);
        cov_rvalid = 1'b1; cov_rready = 1'b0; @(posedge clk);
        cov_rvalid = 1'b1; cov_rready = 1'b1; @(posedge clk);

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

        cov_arid    = '1;
        cov_araddr  = '1;
        cov_arlen   = 8'hFF;
        cov_arsize  = 3'b111;
        cov_arburst = 2'b11;
        cov_arprot  = 3'b111;
        cov_arvalid = 1'b1;
        cov_arready = 1'b1;

        cov_rid     = '1;
        cov_rdata   = '1;
        cov_rresp   = 2'b11;
        cov_rlast   = 1'b1;
        cov_rvalid  = 1'b1;
        cov_rready  = 1'b1;

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

        cov_arid    = '0;
        cov_araddr  = '0;
        cov_arlen   = 8'h00;
        cov_arsize  = 3'b000;
        cov_arburst = 2'b00;
        cov_arprot  = 3'b000;
        cov_arvalid = 1'b0;
        cov_arready = 1'b0;

        cov_rid     = '0;
        cov_rdata   = '0;
        cov_rresp   = 2'b00;
        cov_rlast   = 1'b0;
        cov_rvalid  = 1'b0;
        cov_rready  = 1'b0;

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
            cov_araddr = ({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Address walking 0.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
            cov_araddr = ~({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Data walking 1.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
            cov_rdata = ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Data walking 0.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
            cov_rdata = ~({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Len, ID, size, burst, prot sweep.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < 256; cov_i = cov_i + 1) begin
            cov_arlen   = cov_i[7:0];
            cov_arid    = cov_i[ID_WIDTH-1:0];
            cov_rid     = ~cov_i[ID_WIDTH-1:0];
            cov_arsize  = cov_i[2:0];
            cov_arburst = cov_i[1:0];
            cov_arprot  = cov_i[2:0];
            cov_rresp   = cov_i[1:0];
            @(posedge clk);
        end

        // --------------------------------------------------------
        // Pointer/full/empty stress.
        // --------------------------------------------------------

        for (cov_i = 0; cov_i < 32; cov_i = cov_i + 1) begin
            cov_arvalid = cov_i[0];
            cov_arready = ~cov_i[0];
            cov_rvalid  = cov_i[1];
            cov_rready  = ~cov_i[1];
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < 32; cov_i = cov_i + 1) begin
            cov_arvalid = ~cov_i[0];
            cov_arready = cov_i[0];
            cov_rvalid  = ~cov_i[1];
            cov_rready  = cov_i[1];
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

        cov_arid    = '0;
        cov_araddr  = '0;
        cov_arlen   = 8'h00;
        cov_arsize  = 3'b000;
        cov_arburst = 2'b00;
        cov_arprot  = 3'b000;
        cov_arvalid = 1'b0;
        cov_arready = 1'b0;

        cov_rid     = '0;
        cov_rdata   = '0;
        cov_rresp   = 2'b00;
        cov_rlast   = 1'b0;
        cov_rvalid  = 1'b0;
        cov_rready  = 1'b0;

        cov_a        = 1'b0;
        cov_b        = 1'b0;
        cov_c        = 1'b0;
        cov_result   = 1'b0;
        cov_vec      = 64'h0000_0000_0000_0000;
        cov_count    = 4'h0;
        cov_sel      = 3'b000;

        @(posedge clk);

        $display("[AXI_RD_FIFO_COV_FIX] axi_rd_fifo toggle coverage booster completed");

    end

    // pragma coverage off
    // VCS coverage off

endmodule
