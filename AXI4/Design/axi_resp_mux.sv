module axi_resp_mux #(
    parameter int NUM_SLAVES = 3,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4
)(
    input  logic clk,
    input  logic rst_n,

    // MASTER SIDE
    input  logic [ID_WIDTH-1:0]       m_awid,
    input  logic [ADDR_WIDTH-1:0]     m_awaddr,
    input  logic [7:0]                m_awlen,
    input  logic [2:0]                m_awsize,
    input  logic [1:0]                m_awburst,
    input  logic [2:0]                m_awprot,
    input  logic                      m_awvalid,
    output logic                      m_awready,

    input  logic [DATA_WIDTH-1:0]     m_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] m_wstrb,
    input  logic                      m_wlast,
    input  logic                      m_wvalid,
    output logic                      m_wready,

    output logic [ID_WIDTH-1:0]       m_bid,
    output logic [1:0]                m_bresp,
    output logic                      m_bvalid,
    input  logic                      m_bready,

    input  logic [ID_WIDTH-1:0]       m_arid,
    input  logic [ADDR_WIDTH-1:0]     m_araddr,
    input  logic [7:0]                m_arlen,
    input  logic [2:0]                m_arsize,
    input  logic [1:0]                m_arburst,
    input  logic [2:0]                m_arprot,
    input  logic                      m_arvalid,
    output logic                      m_arready,

    output logic [ID_WIDTH-1:0]       m_rid,
    output logic [DATA_WIDTH-1:0]     m_rdata,
    output logic [1:0]                m_rresp,
    output logic                      m_rlast,
    output logic                      m_rvalid,
    input  logic                      m_rready,

    // SLAVE SIDE
    output logic [ID_WIDTH-1:0]       s_awid    [NUM_SLAVES],
    output logic [ADDR_WIDTH-1:0]     s_awaddr  [NUM_SLAVES],
    output logic [7:0]                s_awlen   [NUM_SLAVES],
    output logic [2:0]                s_awsize  [NUM_SLAVES],
    output logic [1:0]                s_awburst [NUM_SLAVES],
    output logic [2:0]                s_awprot  [NUM_SLAVES],
    output logic                      s_awvalid [NUM_SLAVES],
    input  logic                      s_awready [NUM_SLAVES],

    output logic [DATA_WIDTH-1:0]     s_wdata   [NUM_SLAVES],
    output logic [(DATA_WIDTH/8)-1:0] s_wstrb   [NUM_SLAVES],
    output logic                      s_wlast   [NUM_SLAVES],
    output logic                      s_wvalid  [NUM_SLAVES],
    input  logic                      s_wready  [NUM_SLAVES],

    input  logic [ID_WIDTH-1:0]       s_bid     [NUM_SLAVES],
    input  logic [1:0]                s_bresp   [NUM_SLAVES],
    input  logic                      s_bvalid  [NUM_SLAVES],
    output logic                      s_bready  [NUM_SLAVES],

    output logic [ID_WIDTH-1:0]       s_arid    [NUM_SLAVES],
    output logic [ADDR_WIDTH-1:0]     s_araddr  [NUM_SLAVES],
    output logic [7:0]                s_arlen   [NUM_SLAVES],
    output logic [2:0]                s_arsize  [NUM_SLAVES],
    output logic [1:0]                s_arburst [NUM_SLAVES],
    output logic [2:0]                s_arprot  [NUM_SLAVES],
    output logic                      s_arvalid [NUM_SLAVES],
    input  logic                      s_arready [NUM_SLAVES],

    input  logic [ID_WIDTH-1:0]       s_rid     [NUM_SLAVES],
    input  logic [DATA_WIDTH-1:0]     s_rdata   [NUM_SLAVES],
    input  logic [1:0]                s_rresp   [NUM_SLAVES],
    input  logic                      s_rlast   [NUM_SLAVES],
    input  logic                      s_rvalid  [NUM_SLAVES],
    output logic                      s_rready  [NUM_SLAVES],

    input  logic [ADDR_WIDTH-1:0]     addr_base [NUM_SLAVES],
    input  logic [ADDR_WIDTH-1:0]     addr_mask [NUM_SLAVES]
);

    localparam SEL_W = $clog2(NUM_SLAVES);

    logic [NUM_SLAVES-1:0] wr_sel_vec;
    logic [NUM_SLAVES-1:0] rd_sel_vec;

    logic wr_no_slave;
    logic rd_no_slave;

    logic [SEL_W-1:0] wr_sel_idx;
    logic [SEL_W-1:0] rd_sel_idx;

    logic [SEL_W-1:0] wr_locked_idx;
    logic [SEL_W-1:0] rd_locked_idx;

    logic wr_locked;
    logic rd_locked;

    logic wr_decerr_active;
    logic rd_decerr_active;

    logic [ID_WIDTH-1:0] decerr_wr_id;
    logic [ID_WIDTH-1:0] decerr_rd_id;

    wire aw_fire = m_awvalid && m_awready;
    wire ar_fire = m_arvalid && m_arready;
    wire b_fire  = m_bvalid  && m_bready;
    wire r_fire  = m_rvalid  && m_rready && m_rlast;

    integer i;

    always_comb begin
        wr_sel_vec = '0;
        rd_sel_vec = '0;

        for (int j = 0; j < NUM_SLAVES; j = j + 1) begin
            if ((m_awaddr & addr_mask[j]) == addr_base[j])
                wr_sel_vec[j] = 1'b1;

            if ((m_araddr & addr_mask[j]) == addr_base[j])
                rd_sel_vec[j] = 1'b1;
        end
    end

    assign wr_no_slave = (wr_sel_vec == '0);
    assign rd_no_slave = (rd_sel_vec == '0);

    always_comb begin
        wr_sel_idx = '0;
        rd_sel_idx = '0;

        for (int j = NUM_SLAVES-1; j >= 0; j = j - 1) begin
            if (wr_sel_vec[j])
                wr_sel_idx = j[SEL_W-1:0];

            if (rd_sel_vec[j])
                rd_sel_idx = j[SEL_W-1:0];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_locked        <= 1'b0;
            rd_locked        <= 1'b0;
            wr_locked_idx    <= '0;
            rd_locked_idx    <= '0;
            wr_decerr_active <= 1'b0;
            rd_decerr_active <= 1'b0;
            decerr_wr_id     <= '0;
            decerr_rd_id     <= '0;
        end else begin
            if (aw_fire && !wr_locked) begin
                wr_locked     <= 1'b1;
                wr_locked_idx <= wr_sel_idx;
                decerr_wr_id  <= m_awid;

                if (wr_no_slave)
                    wr_decerr_active <= 1'b1;
            end

            if (b_fire) begin
                wr_locked        <= 1'b0;
                wr_decerr_active <= 1'b0;
            end

            if (ar_fire && !rd_locked) begin
                rd_locked     <= 1'b1;
                rd_locked_idx <= rd_sel_idx;
                decerr_rd_id  <= m_arid;

                if (rd_no_slave)
                    rd_decerr_active <= 1'b1;
            end

            if (r_fire) begin
                rd_locked        <= 1'b0;
                rd_decerr_active <= 1'b0;
            end
        end
    end

    always_comb begin
        for (int j = 0; j < NUM_SLAVES; j = j + 1) begin
            s_awid[j]    = m_awid;
            s_awaddr[j]  = m_awaddr;
            s_awlen[j]   = m_awlen;
            s_awsize[j]  = m_awsize;
            s_awburst[j] = m_awburst;
            s_awprot[j]  = m_awprot;

            s_awvalid[j] = m_awvalid &&
                           !wr_locked &&
                           !wr_no_slave &&
                           (wr_sel_idx == j[SEL_W-1:0]);
        end
    end

    assign m_awready = wr_locked ? 1'b0 :
                       wr_no_slave ? 1'b1 :
                       s_awready[wr_sel_idx];

    always_comb begin
        for (int j = 0; j < NUM_SLAVES; j = j + 1) begin
            s_wdata[j]  = m_wdata;
            s_wstrb[j]  = m_wstrb;
            s_wlast[j]  = m_wlast;

            s_wvalid[j] = m_wvalid &&
                          wr_locked &&
                          !wr_decerr_active &&
                          (wr_locked_idx == j[SEL_W-1:0]);
        end
    end

    assign m_wready = wr_decerr_active ? 1'b1 :
                      wr_locked ? s_wready[wr_locked_idx] :
                      1'b0;

    always_comb begin
        if (wr_decerr_active) begin
            m_bid    = decerr_wr_id;
            m_bresp  = 2'b11;
            m_bvalid = 1'b1;
        end else if (wr_locked) begin
            m_bid    = s_bid[wr_locked_idx];
            m_bresp  = s_bresp[wr_locked_idx];
            m_bvalid = s_bvalid[wr_locked_idx];
        end else begin
            m_bid    = '0;
            m_bresp  = 2'b00;
            m_bvalid = 1'b0;
        end
    end

    always_comb begin
        for (int j = 0; j < NUM_SLAVES; j = j + 1) begin
            s_bready[j] = m_bready &&
                          wr_locked &&
                          !wr_decerr_active &&
                          (wr_locked_idx == j[SEL_W-1:0]);
        end
    end

    always_comb begin
        for (int j = 0; j < NUM_SLAVES; j = j + 1) begin
            s_arid[j]    = m_arid;
            s_araddr[j]  = m_araddr;
            s_arlen[j]   = m_arlen;
            s_arsize[j]  = m_arsize;
            s_arburst[j] = m_arburst;
            s_arprot[j]  = m_arprot;

            s_arvalid[j] = m_arvalid &&
                           !rd_locked &&
                           !rd_no_slave &&
                           (rd_sel_idx == j[SEL_W-1:0]);
        end
    end

    assign m_arready = rd_locked ? 1'b0 :
                       rd_no_slave ? 1'b1 :
                       s_arready[rd_sel_idx];

    always_comb begin
        if (rd_decerr_active) begin
            m_rid    = decerr_rd_id;
            m_rdata  = '0;
            m_rresp  = 2'b11;
            m_rlast  = 1'b1;
            m_rvalid = 1'b1;
        end else if (rd_locked) begin
            m_rid    = s_rid[rd_locked_idx];
            m_rdata  = s_rdata[rd_locked_idx];
            m_rresp  = s_rresp[rd_locked_idx];
            m_rlast  = s_rlast[rd_locked_idx];
            m_rvalid = s_rvalid[rd_locked_idx];
        end else begin
            m_rid    = '0;
            m_rdata  = '0;
            m_rresp  = 2'b00;
            m_rlast  = 1'b0;
            m_rvalid = 1'b0;
        end
    end

    always_comb begin
        for (int j = 0; j < NUM_SLAVES; j = j + 1) begin
            s_rready[j] = m_rready &&
                          rd_locked &&
                          !rd_decerr_active &&
                          (rd_locked_idx == j[SEL_W-1:0]);
        end
    end

endmodule
