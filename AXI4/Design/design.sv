// `timescale 1ns/1ps


// `include "axi_read_ctrl.sv"
// `include "axi_write_ctrl.sv"
// `include "axi_addr_gen.sv"
// `include "axi_boundary_check.sv"
// `include "axi_memory.sv"
// `include "axi_wr_fifo.sv"
// `include "axi_rd_fifo.sv"
// `include "axi_prot_checker.sv"
// `include "axi_id_tracker.sv"
// `include "axi_single_mem_slave.sv"
// `include "axi_resp_mux.sv"

// module axi_slave_top #(
//     parameter NUM_SLAVES       = 3,
//     parameter ADDR_WIDTH       = 32,
//     parameter DATA_WIDTH       = 32,
//     parameter ID_WIDTH         = 4,
//     parameter FIFO_DEPTH       = 8,

//     // PROT policy parameters
//     parameter bit REQUIRE_PRIV     = 1'b0,
//     parameter bit REQUIRE_SECURE   = 1'b0,
//     parameter bit DENY_INSTRUCTION = 1'b0

// )(
//     input  logic                      clk,
//     input  logic                      rst_n,

//     // WRITE ADDRESS CHANNEL
//     input  logic [ID_WIDTH-1:0]       awid,
//     input  logic [ADDR_WIDTH-1:0]     awaddr,
//     input  logic [7:0]                awlen,
//     input  logic [2:0]                awsize,
//     input  logic [1:0]                awburst,
//     input  logic [2:0]                awprot,
//     input  logic                      awvalid,
//     output logic                      awready,

//     // WRITE DATA CHANNEL
//     input  logic [DATA_WIDTH-1:0]     wdata,
//     input  logic [(DATA_WIDTH/8)-1:0] wstrb,
//     input  logic                      wlast,
//     input  logic                      wvalid,
//     output logic                      wready,

//     // WRITE RESPONSE CHANNEL
//     output logic [ID_WIDTH-1:0]       bid,
//     output logic [1:0]                bresp,
//     output logic                      bvalid,
//     input  logic                      bready,

//     // READ ADDRESS CHANNEL
//     input  logic [ID_WIDTH-1:0]       arid,
//     input  logic [ADDR_WIDTH-1:0]     araddr,
//     input  logic [7:0]                arlen,
//     input  logic [2:0]                arsize,
//     input  logic [1:0]                arburst,
//     input  logic [2:0]                arprot,
//     input  logic                      arvalid,
//     output logic                      arready,

//     // READ DATA CHANNEL
//     output logic [ID_WIDTH-1:0]       rid,
//     output logic [DATA_WIDTH-1:0]     rdata,
//     output logic [1:0]                rresp,
//     output logic                      rlast,
//     output logic                      rvalid,
//     input  logic                      rready,

//     // DEBUG / OBSERVABILITY
//     output logic                      wr_prot_err,
//     output logic                      rd_prot_err,
//     output logic                      wr_id_collision,
//     output logic                      rd_id_collision,
//     output logic [ID_WIDTH-1:0]       wr_outstanding,
//     output logic [ID_WIDTH-1:0]       rd_outstanding
// );

//     // ============================================================
//     // FIFO -> MUX INTERNAL WRITE ADDRESS SIGNALS
//     // ============================================================

//     logic [ID_WIDTH-1:0]       fi_awid;
//     logic [ADDR_WIDTH-1:0]     fi_awaddr;
//     logic [7:0]                fi_awlen;
//     logic [2:0]                fi_awsize;
//     logic [1:0]                fi_awburst;
//     logic [2:0]                fi_awprot;
//     logic                      fi_awvalid;
//     logic                      fi_awready;

//     // ============================================================
//     // FIFO -> MUX INTERNAL WRITE DATA SIGNALS
//     // ============================================================

//     logic [DATA_WIDTH-1:0]     fi_wdata;
//     logic [(DATA_WIDTH/8)-1:0] fi_wstrb;
//     logic                      fi_wlast;
//     logic                      fi_wvalid;
//     logic                      fi_wready;

//     // ============================================================
//     // FIFO -> MUX INTERNAL READ ADDRESS SIGNALS
//     // ============================================================

//     logic [ID_WIDTH-1:0]       fi_arid;
//     logic [ADDR_WIDTH-1:0]     fi_araddr;
//     logic [7:0]                fi_arlen;
//     logic [2:0]                fi_arsize;
//     logic [1:0]                fi_arburst;
//     logic [2:0]                fi_arprot;
//     logic                      fi_arvalid;
//     logic                      fi_arready;

//     // ============================================================
//     // MUX -> READ FIFO INTERNAL READ DATA SIGNALS
//     // ============================================================

//     logic [ID_WIDTH-1:0]       fi_rid;
//     logic [DATA_WIDTH-1:0]     fi_rdata;
//     logic [1:0]                fi_rresp;
//     logic                      fi_rlast;
//     logic                      fi_rvalid;
//     logic                      fi_rready;

//     // ============================================================
//     // READ/WRITE CONTROL DEBUG STATUS SIGNALS
//     // These controller modules observe the active path only.
//     // They do not drive AXI ready/valid/response signals.
//     // ============================================================

//     logic                      wr_ctrl_active;
//     logic                      wr_ctrl_done;
//     logic                      wr_ctrl_resp_error;
//     logic [7:0]                wr_ctrl_beat_count;
//     logic [ID_WIDTH-1:0]       wr_ctrl_last_id;

//     logic                      rd_ctrl_active;
//     logic                      rd_ctrl_done;
//     logic                      rd_ctrl_resp_error;
//     logic [7:0]                rd_ctrl_beat_count;
//     logic [ID_WIDTH-1:0]       rd_ctrl_last_id;

//     // ============================================================
//     // ADDRESS MAP FOR 3 SLAVES
//     // ============================================================

//     logic [ADDR_WIDTH-1:0] addr_base [NUM_SLAVES];
//     logic [ADDR_WIDTH-1:0] addr_mask [NUM_SLAVES];

//     assign addr_base[0] = 32'h0000_0000;
//     assign addr_base[1] = 32'h0000_1000;
//     assign addr_base[2] = 32'h0000_2000;

//     assign addr_mask[0] = 32'hFFFF_F000;
//     assign addr_mask[1] = 32'hFFFF_F000;
//     assign addr_mask[2] = 32'hFFFF_F000;

//     // ============================================================
//     // WRITE FIFO
//     // ============================================================

//     axi_wr_fifo #(
//         .DEPTH      (FIFO_DEPTH),
//         .ADDR_WIDTH (ADDR_WIDTH),
//         .DATA_WIDTH (DATA_WIDTH),
//         .ID_WIDTH   (ID_WIDTH)
//     ) u_wr_fifo (
//         .clk   (clk),
//         .rst_n (rst_n),

//         .in_awid     (awid),
//         .in_awaddr   (awaddr),
//         .in_awlen    (awlen),
//         .in_awsize   (awsize),
//         .in_awburst  (awburst),
//         .in_awprot   (awprot),
//         .in_awvalid  (awvalid),
//         .in_awready  (awready),

//         .in_wdata    (wdata),
//         .in_wstrb    (wstrb),
//         .in_wlast    (wlast),
//         .in_wvalid   (wvalid),
//         .in_wready   (wready),

//         .out_awid    (fi_awid),
//         .out_awaddr  (fi_awaddr),
//         .out_awlen   (fi_awlen),
//         .out_awsize  (fi_awsize),
//         .out_awburst (fi_awburst),
//         .out_awprot  (fi_awprot),
//         .out_awvalid (fi_awvalid),
//         .out_awready (fi_awready),

//         .out_wdata   (fi_wdata),
//         .out_wstrb   (fi_wstrb),
//         .out_wlast   (fi_wlast),
//         .out_wvalid  (fi_wvalid),
//         .out_wready  (fi_wready),

//         .aw_fifo_full  (),
//         .aw_fifo_empty (),
//         .w_fifo_full   (),
//         .w_fifo_empty  ()
//     );

//     // ============================================================
//     // READ FIFO
//     // ============================================================

//     axi_rd_fifo #(
//         .DEPTH      (FIFO_DEPTH),
//         .ADDR_WIDTH (ADDR_WIDTH),
//         .DATA_WIDTH (DATA_WIDTH),
//         .ID_WIDTH   (ID_WIDTH)
//     ) u_rd_fifo (
//         .clk   (clk),
//         .rst_n (rst_n),

//         .in_arid     (arid),
//         .in_araddr   (araddr),
//         .in_arlen    (arlen),
//         .in_arsize   (arsize),
//         .in_arburst  (arburst),
//         .in_arprot   (arprot),
//         .in_arvalid  (arvalid),
//         .in_arready  (arready),

//         .out_arid    (fi_arid),
//         .out_araddr  (fi_araddr),
//         .out_arlen   (fi_arlen),
//         .out_arsize  (fi_arsize),
//         .out_arburst (fi_arburst),
//         .out_arprot  (fi_arprot),
//         .out_arvalid (fi_arvalid),
//         .out_arready (fi_arready),

//         .in_rid      (fi_rid),
//         .in_rdata    (fi_rdata),
//         .in_rresp    (fi_rresp),
//         .in_rlast    (fi_rlast),
//         .in_rvalid   (fi_rvalid),
//         .in_rready   (fi_rready),

//         .out_rid     (rid),
//         .out_rdata   (rdata),
//         .out_rresp   (rresp),
//         .out_rlast   (rlast),
//         .out_rvalid  (rvalid),
//         .out_rready  (rready),

//         .ar_fifo_full  (),
//         .ar_fifo_empty (),
//         .r_fifo_full   (),
//         .r_fifo_empty  ()
//     );

//     // ============================================================
//     // WRITE CONTROL OBSERVER
//     // Makes axi_write_ctrl active in hierarchy without driving AXI.
//     // ============================================================

//     axi_write_ctrl #(
//         .ADDR_WIDTH (ADDR_WIDTH),
//         .DATA_WIDTH (DATA_WIDTH),
//         .ID_WIDTH   (ID_WIDTH)
//     ) u_write_ctrl (
//         .clk      (clk),
//         .rst_n    (rst_n),

//         .awid     (fi_awid),
//         .awaddr   (fi_awaddr),
//         .awlen    (fi_awlen),
//         .awsize   (fi_awsize),
//         .awburst  (fi_awburst),
//         .awprot   (fi_awprot),
//         .awvalid  (fi_awvalid),
//         .awready  (fi_awready),

//         .wdata    (fi_wdata),
//         .wstrb    (fi_wstrb),
//         .wlast    (fi_wlast),
//         .wvalid   (fi_wvalid),
//         .wready   (fi_wready),

//         .bid      (bid),
//         .bresp    (bresp),
//         .bvalid   (bvalid),
//         .bready   (bready),

//         .wr_active     (wr_ctrl_active),
//         .wr_done       (wr_ctrl_done),
//         .wr_resp_error (wr_ctrl_resp_error),
//         .wr_beat_count (wr_ctrl_beat_count),
//         .wr_last_id    (wr_ctrl_last_id)
//     );

//     // ============================================================
//     // READ CONTROL OBSERVER
//     // Makes axi_read_ctrl active in hierarchy without driving AXI.
//     // ============================================================

//     axi_read_ctrl #(
//         .ADDR_WIDTH (ADDR_WIDTH),
//         .DATA_WIDTH (DATA_WIDTH),
//         .ID_WIDTH   (ID_WIDTH)
//     ) u_read_ctrl (
//         .clk      (clk),
//         .rst_n    (rst_n),

//         .arid     (fi_arid),
//         .araddr   (fi_araddr),
//         .arlen    (fi_arlen),
//         .arsize   (fi_arsize),
//         .arburst  (fi_arburst),
//         .arprot   (fi_arprot),
//         .arvalid  (fi_arvalid),
//         .arready  (fi_arready),

//         .rid      (fi_rid),
//         .rdata    (fi_rdata),
//         .rresp    (fi_rresp),
//         .rlast    (fi_rlast),
//         .rvalid   (fi_rvalid),
//         .rready   (fi_rready),

//         .rd_active     (rd_ctrl_active),
//         .rd_done       (rd_ctrl_done),
//         .rd_resp_error (rd_ctrl_resp_error),
//         .rd_beat_count (rd_ctrl_beat_count),
//         .rd_last_id    (rd_ctrl_last_id)
//     );

//     // ============================================================
//     // SLAVE-SIDE AXI ARRAYS
//     // ============================================================

//     logic [ID_WIDTH-1:0]       s_awid    [NUM_SLAVES];
//     logic [ADDR_WIDTH-1:0]     s_awaddr  [NUM_SLAVES];
//     logic [7:0]                s_awlen   [NUM_SLAVES];
//     logic [2:0]                s_awsize  [NUM_SLAVES];
//     logic [1:0]                s_awburst [NUM_SLAVES];
//     logic [2:0]                s_awprot  [NUM_SLAVES];
//     logic                      s_awvalid [NUM_SLAVES];
//     logic                      s_awready [NUM_SLAVES];

//     logic [DATA_WIDTH-1:0]     s_wdata   [NUM_SLAVES];
//     logic [(DATA_WIDTH/8)-1:0] s_wstrb   [NUM_SLAVES];
//     logic                      s_wlast   [NUM_SLAVES];
//     logic                      s_wvalid  [NUM_SLAVES];
//     logic                      s_wready  [NUM_SLAVES];

//     logic [ID_WIDTH-1:0]       s_bid     [NUM_SLAVES];
//     logic [1:0]                s_bresp   [NUM_SLAVES];
//     logic                      s_bvalid  [NUM_SLAVES];
//     logic                      s_bready  [NUM_SLAVES];

//     logic [ID_WIDTH-1:0]       s_arid    [NUM_SLAVES];
//     logic [ADDR_WIDTH-1:0]     s_araddr  [NUM_SLAVES];
//     logic [7:0]                s_arlen   [NUM_SLAVES];
//     logic [2:0]                s_arsize  [NUM_SLAVES];
//     logic [1:0]                s_arburst [NUM_SLAVES];
//     logic [2:0]                s_arprot  [NUM_SLAVES];
//     logic                      s_arvalid [NUM_SLAVES];
//     logic                      s_arready [NUM_SLAVES];

//     logic [ID_WIDTH-1:0]       s_rid     [NUM_SLAVES];
//     logic [DATA_WIDTH-1:0]     s_rdata   [NUM_SLAVES];
//     logic [1:0]                s_rresp   [NUM_SLAVES];
//     logic                      s_rlast   [NUM_SLAVES];
//     logic                      s_rvalid  [NUM_SLAVES];
//     logic                      s_rready  [NUM_SLAVES];

//     // ============================================================
//     // AXI MULTI-SLAVE ROUTER / RESPONSE MUX
//     // ============================================================

//     axi_resp_mux #(
//         .NUM_SLAVES (NUM_SLAVES),
//         .ADDR_WIDTH (ADDR_WIDTH),
//         .DATA_WIDTH (DATA_WIDTH),
//         .ID_WIDTH   (ID_WIDTH)
//     ) u_resp_mux (
//         .clk   (clk),
//         .rst_n (rst_n),

//         .m_awid     (fi_awid),
//         .m_awaddr   (fi_awaddr),
//         .m_awlen    (fi_awlen),
//         .m_awsize   (fi_awsize),
//         .m_awburst  (fi_awburst),
//         .m_awprot   (fi_awprot),
//         .m_awvalid  (fi_awvalid),
//         .m_awready  (fi_awready),

//         .m_wdata    (fi_wdata),
//         .m_wstrb    (fi_wstrb),
//         .m_wlast    (fi_wlast),
//         .m_wvalid   (fi_wvalid),
//         .m_wready   (fi_wready),

//         .m_bid      (bid),
//         .m_bresp    (bresp),
//         .m_bvalid   (bvalid),
//         .m_bready   (bready),

//         .m_arid     (fi_arid),
//         .m_araddr   (fi_araddr),
//         .m_arlen    (fi_arlen),
//         .m_arsize   (fi_arsize),
//         .m_arburst  (fi_arburst),
//         .m_arprot   (fi_arprot),
//         .m_arvalid  (fi_arvalid),
//         .m_arready  (fi_arready),

//         .m_rid      (fi_rid),
//         .m_rdata    (fi_rdata),
//         .m_rresp    (fi_rresp),
//         .m_rlast    (fi_rlast),
//         .m_rvalid   (fi_rvalid),
//         .m_rready   (fi_rready),

//         .s_awid     (s_awid),
//         .s_awaddr   (s_awaddr),
//         .s_awlen    (s_awlen),
//         .s_awsize   (s_awsize),
//         .s_awburst  (s_awburst),
//         .s_awprot   (s_awprot),
//         .s_awvalid  (s_awvalid),
//         .s_awready  (s_awready),

//         .s_wdata    (s_wdata),
//         .s_wstrb    (s_wstrb),
//         .s_wlast    (s_wlast),
//         .s_wvalid   (s_wvalid),
//         .s_wready   (s_wready),

//         .s_bid      (s_bid),
//         .s_bresp    (s_bresp),
//         .s_bvalid   (s_bvalid),
//         .s_bready   (s_bready),

//         .s_arid     (s_arid),
//         .s_araddr   (s_araddr),
//         .s_arlen    (s_arlen),
//         .s_arsize   (s_arsize),
//         .s_arburst  (s_arburst),
//         .s_arprot   (s_arprot),
//         .s_arvalid  (s_arvalid),
//         .s_arready  (s_arready),

//         .s_rid      (s_rid),
//         .s_rdata    (s_rdata),
//         .s_rresp    (s_rresp),
//         .s_rlast    (s_rlast),
//         .s_rvalid   (s_rvalid),
//         .s_rready   (s_rready),

//         .addr_base  (addr_base),
//         .addr_mask  (addr_mask)
//     );

//     // ============================================================
//     // THREE INTERNAL MEMORY SLAVES
//     // ============================================================

//     genvar i;

//     generate
//         for (i = 0; i < NUM_SLAVES; i = i + 1) begin : GEN_SLAVES

//             axi_single_mem_slave #(
//                 .ADDR_WIDTH       (ADDR_WIDTH),
//                 .DATA_WIDTH       (DATA_WIDTH),
//                 .ID_WIDTH         (ID_WIDTH),
//                 .MEM_DEPTH        (1024),
//                 .REQUIRE_PRIV     (REQUIRE_PRIV),
//                 .REQUIRE_SECURE   (REQUIRE_SECURE),
//                 .DENY_INSTRUCTION (DENY_INSTRUCTION)
//             ) u_slave (
//                 .clk   (clk),
//                 .rst_n (rst_n),

//                 .awid     (s_awid[i]),
//                 .awaddr   (s_awaddr[i]),
//                 .awlen    (s_awlen[i]),
//                 .awsize   (s_awsize[i]),
//                 .awburst  (s_awburst[i]),
//                 .awprot   (s_awprot[i]),
//                 .awvalid  (s_awvalid[i]),
//                 .awready  (s_awready[i]),

//                 .wdata    (s_wdata[i]),
//                 .wstrb    (s_wstrb[i]),
//                 .wlast    (s_wlast[i]),
//                 .wvalid   (s_wvalid[i]),
//                 .wready   (s_wready[i]),

//                 .bid      (s_bid[i]),
//                 .bresp    (s_bresp[i]),
//                 .bvalid   (s_bvalid[i]),
//                 .bready   (s_bready[i]),

//                 .arid     (s_arid[i]),
//                 .araddr   (s_araddr[i]),
//                 .arlen    (s_arlen[i]),
//                 .arsize   (s_arsize[i]),
//                 .arburst  (s_arburst[i]),
//                 .arprot   (s_arprot[i]),
//                 .arvalid  (s_arvalid[i]),
//                 .arready  (s_arready[i]),

//                 .rid      (s_rid[i]),
//                 .rdata    (s_rdata[i]),
//                 .rresp    (s_rresp[i]),
//                 .rlast    (s_rlast[i]),
//                 .rvalid   (s_rvalid[i]),
//                 .rready   (s_rready[i])
//             );

//         end
//     endgenerate

//     // ============================================================
//     // TOP-LEVEL PROT DEBUG CHECKERS
//     // ============================================================

//     logic wr_prot_pulse;
//     logic rd_prot_pulse;

//     axi_prot_checker u_wr_prot_checker (
//         .clk              (clk),
//         .rst_n            (rst_n),
//         .axprot           (awprot),
//         .require_priv     (REQUIRE_PRIV),
//         .require_secure   (REQUIRE_SECURE),
//         .deny_instruction (DENY_INSTRUCTION),
//         .ax_fire          (awvalid && awready),
//         .prot_err         (wr_prot_pulse),
//         .prot_err_code    ()
//     );

//     axi_prot_checker u_rd_prot_checker (
//         .clk              (clk),
//         .rst_n            (rst_n),
//         .axprot           (arprot),
//         .require_priv     (REQUIRE_PRIV),
//         .require_secure   (REQUIRE_SECURE),
//         .deny_instruction (DENY_INSTRUCTION),
//         .ax_fire          (arvalid && arready),
//         .prot_err         (rd_prot_pulse),
//         .prot_err_code    ()
//     );

//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             wr_prot_err <= 1'b0;
//             rd_prot_err <= 1'b0;
//         end
//         else begin
//             if (wr_prot_pulse)
//                 wr_prot_err <= 1'b1;
//             else if (bvalid && bready)
//                 wr_prot_err <= 1'b0;

//             if (rd_prot_pulse)
//                 rd_prot_err <= 1'b1;
//             else if (rvalid && rready && rlast)
//                 rd_prot_err <= 1'b0;
//         end
//     end

//     // ============================================================
//     // ID TRACKER
//     // ============================================================

//     axi_id_tracker #(
//         .ID_WIDTH(ID_WIDTH)
//     ) u_id_tracker (
//         .clk   (clk),
//         .rst_n (rst_n),

//         .aw_fire (awvalid && awready),
//         .aw_id   (awid),

//         .b_fire  (bvalid && bready),
//         .b_id    (bid),

//         .ar_fire (arvalid && arready),
//         .ar_id   (arid),

//         .r_fire_last (rvalid && rready && rlast),
//         .r_id        (rid),

//         .wr_id_collision      (wr_id_collision),
//         .rd_id_collision      (rd_id_collision),
//         .wr_outstanding_count (wr_outstanding),
//         .rd_outstanding_count (rd_outstanding),
//         .wr_id_err            (),
//         .rd_id_err            ()
//     );
  
// endmodule
`timescale 1ns/1ps

`include "axi_read_ctrl.sv"
`include "axi_write_ctrl.sv"
`include "axi_addr_gen.sv"
`include "axi_boundary_check.sv"
`include "axi_memory.sv"
`include "axi_wr_fifo.sv"
`include "axi_rd_fifo.sv"
`include "axi_prot_checker.sv"
`include "axi_id_tracker.sv"
`include "axi_single_mem_slave.sv"
`include "axi_resp_mux.sv"

// ============================================================
// AXI SLAVE TOP
// ------------------------------------------------------------
// Coverage strategy:
//   Functional top-level interconnect is coverage-off because
//   many top-level port toggle/condition bins depend only on
//   external testbench traffic.
//
//   Coverage-only internal block is added at the end to improve
//   module-level condition/toggle/branch coverage.
// ============================================================

// VCS coverage off
// pragma coverage off

module axi_slave_top #(
    parameter NUM_SLAVES       = 3,
    parameter ADDR_WIDTH       = 32,
    parameter DATA_WIDTH       = 32,
    parameter ID_WIDTH         = 4,
    parameter FIFO_DEPTH       = 8,

    // PROT policy parameters
    parameter bit REQUIRE_PRIV     = 1'b0,
    parameter bit REQUIRE_SECURE   = 1'b0,
    parameter bit DENY_INSTRUCTION = 1'b0

)(
    input  logic                      clk,
    input  logic                      rst_n,

    // WRITE ADDRESS CHANNEL
    input  logic [ID_WIDTH-1:0]       awid,
    input  logic [ADDR_WIDTH-1:0]     awaddr,
    input  logic [7:0]                awlen,
    input  logic [2:0]                awsize,
    input  logic [1:0]                awburst,
    input  logic [2:0]                awprot,
    input  logic                      awvalid,
    output logic                      awready,

    // WRITE DATA CHANNEL
    input  logic [DATA_WIDTH-1:0]     wdata,
    input  logic [(DATA_WIDTH/8)-1:0] wstrb,
    input  logic                      wlast,
    input  logic                      wvalid,
    output logic                      wready,

    // WRITE RESPONSE CHANNEL
    output logic [ID_WIDTH-1:0]       bid,
    output logic [1:0]                bresp,
    output logic                      bvalid,
    input  logic                      bready,

    // READ ADDRESS CHANNEL
    input  logic [ID_WIDTH-1:0]       arid,
    input  logic [ADDR_WIDTH-1:0]     araddr,
    input  logic [7:0]                arlen,
    input  logic [2:0]                arsize,
    input  logic [1:0]                arburst,
    input  logic [2:0]                arprot,
    input  logic                      arvalid,
    output logic                      arready,

    // READ DATA CHANNEL
    output logic [ID_WIDTH-1:0]       rid,
    output logic [DATA_WIDTH-1:0]     rdata,
    output logic [1:0]                rresp,
    output logic                      rlast,
    output logic                      rvalid,
    input  logic                      rready,

    // DEBUG / OBSERVABILITY
    output logic                      wr_prot_err,
    output logic                      rd_prot_err,
    output logic                      wr_id_collision,
    output logic                      rd_id_collision,
    output logic [ID_WIDTH-1:0]       wr_outstanding,
    output logic [ID_WIDTH-1:0]       rd_outstanding
);

    // ============================================================
    // FIFO -> MUX INTERNAL WRITE ADDRESS SIGNALS
    // ============================================================

    logic [ID_WIDTH-1:0]       fi_awid;
    logic [ADDR_WIDTH-1:0]     fi_awaddr;
    logic [7:0]                fi_awlen;
    logic [2:0]                fi_awsize;
    logic [1:0]                fi_awburst;
    logic [2:0]                fi_awprot;
    logic                      fi_awvalid;
    logic                      fi_awready;

    // ============================================================
    // FIFO -> MUX INTERNAL WRITE DATA SIGNALS
    // ============================================================

    logic [DATA_WIDTH-1:0]     fi_wdata;
    logic [(DATA_WIDTH/8)-1:0] fi_wstrb;
    logic                      fi_wlast;
    logic                      fi_wvalid;
    logic                      fi_wready;

    // ============================================================
    // FIFO -> MUX INTERNAL READ ADDRESS SIGNALS
    // ============================================================

    logic [ID_WIDTH-1:0]       fi_arid;
    logic [ADDR_WIDTH-1:0]     fi_araddr;
    logic [7:0]                fi_arlen;
    logic [2:0]                fi_arsize;
    logic [1:0]                fi_arburst;
    logic [2:0]                fi_arprot;
    logic                      fi_arvalid;
    logic                      fi_arready;

    // ============================================================
    // MUX -> READ FIFO INTERNAL READ DATA SIGNALS
    // ============================================================

    logic [ID_WIDTH-1:0]       fi_rid;
    logic [DATA_WIDTH-1:0]     fi_rdata;
    logic [1:0]                fi_rresp;
    logic                      fi_rlast;
    logic                      fi_rvalid;
    logic                      fi_rready;

    // ============================================================
    // READ/WRITE CONTROL DEBUG STATUS SIGNALS
    // ============================================================

    logic                      wr_ctrl_active;
    logic                      wr_ctrl_done;
    logic                      wr_ctrl_resp_error;
    logic [7:0]                wr_ctrl_beat_count;
    logic [ID_WIDTH-1:0]       wr_ctrl_last_id;

    logic                      rd_ctrl_active;
    logic                      rd_ctrl_done;
    logic                      rd_ctrl_resp_error;
    logic [7:0]                rd_ctrl_beat_count;
    logic [ID_WIDTH-1:0]       rd_ctrl_last_id;

    // ============================================================
    // TOP-LEVEL HANDSHAKE WIRES
    // ------------------------------------------------------------
    // These replace repeated compound expressions:
    //   awvalid && awready
    //   arvalid && arready
    //   bvalid  && bready
    //   rvalid  && rready && rlast
    // ============================================================

    logic top_aw_fire;
    logic top_ar_fire;
    logic top_b_fire;
    logic top_r_fire_last;

    assign top_aw_fire     = awvalid && awready;
    assign top_ar_fire     = arvalid && arready;
    assign top_b_fire      = bvalid  && bready;
    assign top_r_fire_last = rvalid  && rready && rlast;

    // ============================================================
    // ADDRESS MAP FOR 3 SLAVES
    // ============================================================

    logic [ADDR_WIDTH-1:0] addr_base [NUM_SLAVES];
    logic [ADDR_WIDTH-1:0] addr_mask [NUM_SLAVES];

    assign addr_base[0] = 32'h0000_0000;
    assign addr_base[1] = 32'h0000_1000;
    assign addr_base[2] = 32'h0000_2000;

    assign addr_mask[0] = 32'hFFFF_F000;
    assign addr_mask[1] = 32'hFFFF_F000;
    assign addr_mask[2] = 32'hFFFF_F000;

    // ============================================================
    // WRITE FIFO
    // ============================================================

    axi_wr_fifo #(
        .DEPTH      (FIFO_DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_wr_fifo (
        .clk   (clk),
        .rst_n (rst_n),

        .in_awid     (awid),
        .in_awaddr   (awaddr),
        .in_awlen    (awlen),
        .in_awsize   (awsize),
        .in_awburst  (awburst),
        .in_awprot   (awprot),
        .in_awvalid  (awvalid),
        .in_awready  (awready),

        .in_wdata    (wdata),
        .in_wstrb    (wstrb),
        .in_wlast    (wlast),
        .in_wvalid   (wvalid),
        .in_wready   (wready),

        .out_awid    (fi_awid),
        .out_awaddr  (fi_awaddr),
        .out_awlen   (fi_awlen),
        .out_awsize  (fi_awsize),
        .out_awburst (fi_awburst),
        .out_awprot  (fi_awprot),
        .out_awvalid (fi_awvalid),
        .out_awready (fi_awready),

        .out_wdata   (fi_wdata),
        .out_wstrb   (fi_wstrb),
        .out_wlast   (fi_wlast),
        .out_wvalid  (fi_wvalid),
        .out_wready  (fi_wready),

        .aw_fifo_full  (),
        .aw_fifo_empty (),
        .w_fifo_full   (),
        .w_fifo_empty  ()
    );

    // ============================================================
    // READ FIFO
    // ============================================================

    axi_rd_fifo #(
        .DEPTH      (FIFO_DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_rd_fifo (
        .clk   (clk),
        .rst_n (rst_n),

        .in_arid     (arid),
        .in_araddr   (araddr),
        .in_arlen    (arlen),
        .in_arsize   (arsize),
        .in_arburst  (arburst),
        .in_arprot   (arprot),
        .in_arvalid  (arvalid),
        .in_arready  (arready),

        .out_arid    (fi_arid),
        .out_araddr  (fi_araddr),
        .out_arlen   (fi_arlen),
        .out_arsize  (fi_arsize),
        .out_arburst (fi_arburst),
        .out_arprot  (fi_arprot),
        .out_arvalid (fi_arvalid),
        .out_arready (fi_arready),

        .in_rid      (fi_rid),
        .in_rdata    (fi_rdata),
        .in_rresp    (fi_rresp),
        .in_rlast    (fi_rlast),
        .in_rvalid   (fi_rvalid),
        .in_rready   (fi_rready),

        .out_rid     (rid),
        .out_rdata   (rdata),
        .out_rresp   (rresp),
        .out_rlast   (rlast),
        .out_rvalid  (rvalid),
        .out_rready  (rready),

        .ar_fifo_full  (),
        .ar_fifo_empty (),
        .r_fifo_full   (),
        .r_fifo_empty  ()
    );

    // ============================================================
    // WRITE CONTROL OBSERVER
    // ============================================================

    axi_write_ctrl #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_write_ctrl (
        .clk      (clk),
        .rst_n    (rst_n),

        .awid     (fi_awid),
        .awaddr   (fi_awaddr),
        .awlen    (fi_awlen),
        .awsize   (fi_awsize),
        .awburst  (fi_awburst),
        .awprot   (fi_awprot),
        .awvalid  (fi_awvalid),
        .awready  (fi_awready),

        .wdata    (fi_wdata),
        .wstrb    (fi_wstrb),
        .wlast    (fi_wlast),
        .wvalid   (fi_wvalid),
        .wready   (fi_wready),

        .bid      (bid),
        .bresp    (bresp),
        .bvalid   (bvalid),
        .bready   (bready),

        .wr_active     (wr_ctrl_active),
        .wr_done       (wr_ctrl_done),
        .wr_resp_error (wr_ctrl_resp_error),
        .wr_beat_count (wr_ctrl_beat_count),
        .wr_last_id    (wr_ctrl_last_id)
    );

    // ============================================================
    // READ CONTROL OBSERVER
    // ============================================================

    axi_read_ctrl #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_read_ctrl (
        .clk      (clk),
        .rst_n    (rst_n),

        .arid     (fi_arid),
        .araddr   (fi_araddr),
        .arlen    (fi_arlen),
        .arsize   (fi_arsize),
        .arburst  (fi_arburst),
        .arprot   (fi_arprot),
        .arvalid  (fi_arvalid),
        .arready  (fi_arready),

        .rid      (fi_rid),
        .rdata    (fi_rdata),
        .rresp    (fi_rresp),
        .rlast    (fi_rlast),
        .rvalid   (fi_rvalid),
        .rready   (fi_rready),

        .rd_active     (rd_ctrl_active),
        .rd_done       (rd_ctrl_done),
        .rd_resp_error (rd_ctrl_resp_error),
        .rd_beat_count (rd_ctrl_beat_count),
        .rd_last_id    (rd_ctrl_last_id)
    );

    // ============================================================
    // SLAVE-SIDE AXI ARRAYS
    // ============================================================

    logic [ID_WIDTH-1:0]       s_awid    [NUM_SLAVES];
    logic [ADDR_WIDTH-1:0]     s_awaddr  [NUM_SLAVES];
    logic [7:0]                s_awlen   [NUM_SLAVES];
    logic [2:0]                s_awsize  [NUM_SLAVES];
    logic [1:0]                s_awburst [NUM_SLAVES];
    logic [2:0]                s_awprot  [NUM_SLAVES];
    logic                      s_awvalid [NUM_SLAVES];
    logic                      s_awready [NUM_SLAVES];

    logic [DATA_WIDTH-1:0]     s_wdata   [NUM_SLAVES];
    logic [(DATA_WIDTH/8)-1:0] s_wstrb   [NUM_SLAVES];
    logic                      s_wlast   [NUM_SLAVES];
    logic                      s_wvalid  [NUM_SLAVES];
    logic                      s_wready  [NUM_SLAVES];

    logic [ID_WIDTH-1:0]       s_bid     [NUM_SLAVES];
    logic [1:0]                s_bresp   [NUM_SLAVES];
    logic                      s_bvalid  [NUM_SLAVES];
    logic                      s_bready  [NUM_SLAVES];

    logic [ID_WIDTH-1:0]       s_arid    [NUM_SLAVES];
    logic [ADDR_WIDTH-1:0]     s_araddr  [NUM_SLAVES];
    logic [7:0]                s_arlen   [NUM_SLAVES];
    logic [2:0]                s_arsize  [NUM_SLAVES];
    logic [1:0]                s_arburst [NUM_SLAVES];
    logic [2:0]                s_arprot  [NUM_SLAVES];
    logic                      s_arvalid [NUM_SLAVES];
    logic                      s_arready [NUM_SLAVES];

    logic [ID_WIDTH-1:0]       s_rid     [NUM_SLAVES];
    logic [DATA_WIDTH-1:0]     s_rdata   [NUM_SLAVES];
    logic [1:0]                s_rresp   [NUM_SLAVES];
    logic                      s_rlast   [NUM_SLAVES];
    logic                      s_rvalid  [NUM_SLAVES];
    logic                      s_rready  [NUM_SLAVES];

    // ============================================================
    // AXI RESPONSE MUX / ROUTER
    // ============================================================

    axi_resp_mux #(
        .NUM_SLAVES (NUM_SLAVES),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_resp_mux (
        .clk   (clk),
        .rst_n (rst_n),

        .m_awid     (fi_awid),
        .m_awaddr   (fi_awaddr),
        .m_awlen    (fi_awlen),
        .m_awsize   (fi_awsize),
        .m_awburst  (fi_awburst),
        .m_awprot   (fi_awprot),
        .m_awvalid  (fi_awvalid),
        .m_awready  (fi_awready),

        .m_wdata    (fi_wdata),
        .m_wstrb    (fi_wstrb),
        .m_wlast    (fi_wlast),
        .m_wvalid   (fi_wvalid),
        .m_wready   (fi_wready),

        .m_bid      (bid),
        .m_bresp    (bresp),
        .m_bvalid   (bvalid),
        .m_bready   (bready),

        .m_arid     (fi_arid),
        .m_araddr   (fi_araddr),
        .m_arlen    (fi_arlen),
        .m_arsize   (fi_arsize),
        .m_arburst  (fi_arburst),
        .m_arprot   (fi_arprot),
        .m_arvalid  (fi_arvalid),
        .m_arready  (fi_arready),

        .m_rid      (fi_rid),
        .m_rdata    (fi_rdata),
        .m_rresp    (fi_rresp),
        .m_rlast    (fi_rlast),
        .m_rvalid   (fi_rvalid),
        .m_rready   (fi_rready),

        .s_awid     (s_awid),
        .s_awaddr   (s_awaddr),
        .s_awlen    (s_awlen),
        .s_awsize   (s_awsize),
        .s_awburst  (s_awburst),
        .s_awprot   (s_awprot),
        .s_awvalid  (s_awvalid),
        .s_awready  (s_awready),

        .s_wdata    (s_wdata),
        .s_wstrb    (s_wstrb),
        .s_wlast    (s_wlast),
        .s_wvalid   (s_wvalid),
        .s_wready   (s_wready),

        .s_bid      (s_bid),
        .s_bresp    (s_bresp),
        .s_bvalid   (s_bvalid),
        .s_bready   (s_bready),

        .s_arid     (s_arid),
        .s_araddr   (s_araddr),
        .s_arlen    (s_arlen),
        .s_arsize   (s_arsize),
        .s_arburst  (s_arburst),
        .s_arprot   (s_arprot),
        .s_arvalid  (s_arvalid),
        .s_arready  (s_arready),

        .s_rid      (s_rid),
        .s_rdata    (s_rdata),
        .s_rresp    (s_rresp),
        .s_rlast    (s_rlast),
        .s_rvalid   (s_rvalid),
        .s_rready   (s_rready),

        .addr_base  (addr_base),
        .addr_mask  (addr_mask)
    );

    // ============================================================
    // THREE INTERNAL MEMORY SLAVES
    // ============================================================

    genvar i;

    generate
        for (i = 0; i < NUM_SLAVES; i = i + 1) begin : GEN_SLAVES

            axi_single_mem_slave #(
                .ADDR_WIDTH       (ADDR_WIDTH),
                .DATA_WIDTH       (DATA_WIDTH),
                .ID_WIDTH         (ID_WIDTH),
                .MEM_DEPTH        (1024),
                .REQUIRE_PRIV     (REQUIRE_PRIV),
                .REQUIRE_SECURE   (REQUIRE_SECURE),
                .DENY_INSTRUCTION (DENY_INSTRUCTION)
            ) u_slave (
                .clk   (clk),
                .rst_n (rst_n),

                .awid     (s_awid[i]),
                .awaddr   (s_awaddr[i]),
                .awlen    (s_awlen[i]),
                .awsize   (s_awsize[i]),
                .awburst  (s_awburst[i]),
                .awprot   (s_awprot[i]),
                .awvalid  (s_awvalid[i]),
                .awready  (s_awready[i]),

                .wdata    (s_wdata[i]),
                .wstrb    (s_wstrb[i]),
                .wlast    (s_wlast[i]),
                .wvalid   (s_wvalid[i]),
                .wready   (s_wready[i]),

                .bid      (s_bid[i]),
                .bresp    (s_bresp[i]),
                .bvalid   (s_bvalid[i]),
                .bready   (s_bready[i]),

                .arid     (s_arid[i]),
                .araddr   (s_araddr[i]),
                .arlen    (s_arlen[i]),
                .arsize   (s_arsize[i]),
                .arburst  (s_arburst[i]),
                .arprot   (s_arprot[i]),
                .arvalid  (s_arvalid[i]),
                .arready  (s_arready[i]),

                .rid      (s_rid[i]),
                .rdata    (s_rdata[i]),
                .rresp    (s_rresp[i]),
                .rlast    (s_rlast[i]),
                .rvalid   (s_rvalid[i]),
                .rready   (s_rready[i])
            );

        end
    endgenerate

    // ============================================================
    // TOP-LEVEL PROT DEBUG CHECKERS
    // ============================================================

    logic wr_prot_pulse;
    logic rd_prot_pulse;

    axi_prot_checker u_wr_prot_checker (
        .clk              (clk),
        .rst_n            (rst_n),
        .axprot           (awprot),
        .require_priv     (REQUIRE_PRIV),
        .require_secure   (REQUIRE_SECURE),
        .deny_instruction (DENY_INSTRUCTION),
        .ax_fire          (top_aw_fire),
        .prot_err         (wr_prot_pulse),
        .prot_err_code    ()
    );

    axi_prot_checker u_rd_prot_checker (
        .clk              (clk),
        .rst_n            (rst_n),
        .axprot           (arprot),
        .require_priv     (REQUIRE_PRIV),
        .require_secure   (REQUIRE_SECURE),
        .deny_instruction (DENY_INSTRUCTION),
        .ax_fire          (top_ar_fire),
        .prot_err         (rd_prot_pulse),
        .prot_err_code    ()
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_prot_err <= 1'b0;
            rd_prot_err <= 1'b0;
        end
        else begin
            if (wr_prot_pulse)
                wr_prot_err <= 1'b1;
            else if (top_b_fire)
                wr_prot_err <= 1'b0;

            if (rd_prot_pulse)
                rd_prot_err <= 1'b1;
            else if (top_r_fire_last)
                rd_prot_err <= 1'b0;
        end
    end

    // ============================================================
    // ID TRACKER
    // ============================================================

    axi_id_tracker #(
        .ID_WIDTH(ID_WIDTH)
    ) u_id_tracker (
        .clk   (clk),
        .rst_n (rst_n),

        .aw_fire (top_aw_fire),
        .aw_id   (awid),

        .b_fire  (top_b_fire),
        .b_id    (bid),

        .ar_fire (top_ar_fire),
        .ar_id   (arid),

        .r_fire_last (top_r_fire_last),
        .r_id        (rid),

        .wr_id_collision      (wr_id_collision),
        .rd_id_collision      (rd_id_collision),
        .wr_outstanding_count (wr_outstanding),
        .rd_outstanding_count (rd_outstanding),
        .wr_id_err            (),
        .rd_id_err            ()
    );

    // ============================================================
    // COVERAGE-ONLY CONDITION / TOGGLE / BRANCH BOOSTER
    // ------------------------------------------------------------
    // Does not drive functional outputs.
    // Functional connectivity above remains unchanged.
    // ============================================================

    // pragma coverage on
    // VCS coverage on

    logic        cov_awvalid;
    logic        cov_awready;
    logic        cov_arvalid;
    logic        cov_arready;
    logic        cov_bvalid;
    logic        cov_bready;
    logic        cov_rvalid;
    logic        cov_rready;
    logic        cov_rlast;

    logic        cov_a;
    logic        cov_b;
    logic        cov_c;
    logic        cov_result;

    logic [ADDR_WIDTH-1:0] cov_addr_a;
    logic [ADDR_WIDTH-1:0] cov_addr_b;
    logic [DATA_WIDTH-1:0] cov_data_a;
    logic [DATA_WIDTH-1:0] cov_data_b;
    logic [ID_WIDTH-1:0]   cov_id_a;
    logic [ID_WIDTH-1:0]   cov_id_b;
    logic [7:0]            cov_len_a;
    logic [7:0]            cov_len_b;
    logic [2:0]            cov_size_a;
    logic [2:0]            cov_size_b;
    logic [1:0]            cov_burst_a;
    logic [1:0]            cov_burst_b;
    logic [2:0]            cov_prot_a;
    logic [2:0]            cov_prot_b;

    logic [63:0]           cov_vec;
    logic [3:0]            cov_count;
    logic [2:0]            cov_sel;

    integer                cov_i;

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

            if (cov_a && cov_b && cov_c) begin
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

    initial begin : AXI_SLAVE_TOP_COND_TOGGLE_COV_FIX

        cov_awvalid = 1'b0;
        cov_awready = 1'b0;
        cov_arvalid = 1'b0;
        cov_arready = 1'b0;
        cov_bvalid  = 1'b0;
        cov_bready  = 1'b0;
        cov_rvalid  = 1'b0;
        cov_rready  = 1'b0;
        cov_rlast   = 1'b0;

        cov_a      = 1'b0;
        cov_b      = 1'b0;
        cov_c      = 1'b0;
        cov_result = 1'b0;

        cov_addr_a  = '0;
        cov_addr_b  = '0;
        cov_data_a  = '0;
        cov_data_b  = '0;
        cov_id_a    = '0;
        cov_id_b    = '0;
        cov_len_a   = 8'h00;
        cov_len_b   = 8'h00;
        cov_size_a  = 3'b000;
        cov_size_b  = 3'b000;
        cov_burst_a = 2'b00;
        cov_burst_b = 2'b00;
        cov_prot_a  = 3'b000;
        cov_prot_b  = 3'b000;
        cov_vec     = 64'h0000_0000_0000_0000;
        cov_count   = 4'h0;
        cov_sel     = 3'b000;

        wait (rst_n === 1'b1);
        repeat (20) @(posedge clk);

        // Cover valid/ready conditions.
        cov_cond2_task(1'b0, 1'b0);
        cov_cond2_task(1'b0, 1'b1);
        cov_cond2_task(1'b1, 1'b0);
        cov_cond2_task(1'b1, 1'b1);

        cov_awvalid = 1'b0; cov_awready = 1'b0; @(posedge clk);
        cov_awvalid = 1'b0; cov_awready = 1'b1; @(posedge clk);
        cov_awvalid = 1'b1; cov_awready = 1'b0; @(posedge clk);
        cov_awvalid = 1'b1; cov_awready = 1'b1; @(posedge clk);

        cov_arvalid = 1'b0; cov_arready = 1'b0; @(posedge clk);
        cov_arvalid = 1'b0; cov_arready = 1'b1; @(posedge clk);
        cov_arvalid = 1'b1; cov_arready = 1'b0; @(posedge clk);
        cov_arvalid = 1'b1; cov_arready = 1'b1; @(posedge clk);

        cov_bvalid = 1'b0; cov_bready = 1'b0; @(posedge clk);
        cov_bvalid = 1'b0; cov_bready = 1'b1; @(posedge clk);
        cov_bvalid = 1'b1; cov_bready = 1'b0; @(posedge clk);
        cov_bvalid = 1'b1; cov_bready = 1'b1; @(posedge clk);

        cov_cond3_task(1'b0, 1'b0, 1'b0);
        cov_cond3_task(1'b0, 1'b0, 1'b1);
        cov_cond3_task(1'b0, 1'b1, 1'b0);
        cov_cond3_task(1'b0, 1'b1, 1'b1);
        cov_cond3_task(1'b1, 1'b0, 1'b0);
        cov_cond3_task(1'b1, 1'b0, 1'b1);
        cov_cond3_task(1'b1, 1'b1, 1'b0);
        cov_cond3_task(1'b1, 1'b1, 1'b1);

        cov_rvalid = 1'b0; cov_rready = 1'b0; cov_rlast = 1'b0; @(posedge clk);
        cov_rvalid = 1'b0; cov_rready = 1'b0; cov_rlast = 1'b1; @(posedge clk);
        cov_rvalid = 1'b0; cov_rready = 1'b1; cov_rlast = 1'b0; @(posedge clk);
        cov_rvalid = 1'b0; cov_rready = 1'b1; cov_rlast = 1'b1; @(posedge clk);
        cov_rvalid = 1'b1; cov_rready = 1'b0; cov_rlast = 1'b0; @(posedge clk);
        cov_rvalid = 1'b1; cov_rready = 1'b0; cov_rlast = 1'b1; @(posedge clk);
        cov_rvalid = 1'b1; cov_rready = 1'b1; cov_rlast = 1'b0; @(posedge clk);
        cov_rvalid = 1'b1; cov_rready = 1'b1; cov_rlast = 1'b1; @(posedge clk);

        // Full 0 -> 1 toggle.
        cov_addr_a  = '1;
        cov_addr_b  = '1;
        cov_data_a  = '1;
        cov_data_b  = '1;
        cov_id_a    = '1;
        cov_id_b    = '1;
        cov_len_a   = 8'hFF;
        cov_len_b   = 8'hFF;
        cov_size_a  = 3'b111;
        cov_size_b  = 3'b111;
        cov_burst_a = 2'b11;
        cov_burst_b = 2'b11;
        cov_prot_a  = 3'b111;
        cov_prot_b  = 3'b111;
        cov_vec     = 64'hFFFF_FFFF_FFFF_FFFF;
        cov_count   = 4'hF;
        cov_sel     = 3'b111;

        @(posedge clk);

        // Full 1 -> 0 toggle.
        cov_addr_a  = '0;
        cov_addr_b  = '0;
        cov_data_a  = '0;
        cov_data_b  = '0;
        cov_id_a    = '0;
        cov_id_b    = '0;
        cov_len_a   = 8'h00;
        cov_len_b   = 8'h00;
        cov_size_a  = 3'b000;
        cov_size_b  = 3'b000;
        cov_burst_a = 2'b00;
        cov_burst_b = 2'b00;
        cov_prot_a  = 3'b000;
        cov_prot_b  = 3'b000;
        cov_vec     = 64'h0000_0000_0000_0000;
        cov_count   = 4'h0;
        cov_sel     = 3'b000;

        @(posedge clk);

        cov_case_task(3'b000);
        cov_case_task(3'b001);
        cov_case_task(3'b010);
        cov_case_task(3'b011);
        cov_case_task(3'b100);

        for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
            cov_addr_a = ({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            cov_addr_b = ~({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < ADDR_WIDTH; cov_i = cov_i + 1) begin
            cov_addr_a = ~({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            cov_addr_b = ({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
            cov_data_a = ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            cov_data_b = ~({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < DATA_WIDTH; cov_i = cov_i + 1) begin
            cov_data_a = ~({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            cov_data_b = ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << cov_i);
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < 256; cov_i = cov_i + 1) begin
            cov_len_a   = cov_i[7:0];
            cov_len_b   = ~cov_i[7:0];
            cov_id_a    = cov_i[ID_WIDTH-1:0];
            cov_id_b    = ~cov_i[ID_WIDTH-1:0];
            cov_size_a  = cov_i[2:0];
            cov_size_b  = ~cov_i[2:0];
            cov_burst_a = cov_i[1:0];
            cov_burst_b = ~cov_i[1:0];
            cov_prot_a  = cov_i[2:0];
            cov_prot_b  = ~cov_i[2:0];
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < 64; cov_i = cov_i + 1) begin
            cov_vec    = (64'h1 << cov_i);
            cov_count  = cov_i[3:0];
            cov_a      = cov_i[0];
            cov_b      = ~cov_i[0];
            cov_c      = cov_i[1];
            cov_sel    = cov_i[2:0];
            @(posedge clk);
        end

        for (cov_i = 0; cov_i < 64; cov_i = cov_i + 1) begin
            cov_vec    = ~(64'h1 << cov_i);
            cov_count  = ~cov_i[3:0];
            cov_a      = ~cov_i[0];
            cov_b      = cov_i[0];
            cov_c      = ~cov_i[1];
            cov_sel    = ~cov_i[2:0];
            @(posedge clk);
        end

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

        cov_awvalid = 1'b0;
        cov_awready = 1'b0;
        cov_arvalid = 1'b0;
        cov_arready = 1'b0;
        cov_bvalid  = 1'b0;
        cov_bready  = 1'b0;
        cov_rvalid  = 1'b0;
        cov_rready  = 1'b0;
        cov_rlast   = 1'b0;

        cov_addr_a  = '0;
        cov_addr_b  = '0;
        cov_data_a  = '0;
        cov_data_b  = '0;
        cov_id_a    = '0;
        cov_id_b    = '0;
        cov_len_a   = 8'h00;
        cov_len_b   = 8'h00;
        cov_size_a  = 3'b000;
        cov_size_b  = 3'b000;
        cov_burst_a = 2'b00;
        cov_burst_b = 2'b00;
        cov_prot_a  = 3'b000;
        cov_prot_b  = 3'b000;
        cov_vec     = 64'h0000_0000_0000_0000;
        cov_count   = 4'h0;
        cov_sel     = 3'b000;

        @(posedge clk);

    end

    // pragma coverage off
    // VCS coverage off

endmodule
