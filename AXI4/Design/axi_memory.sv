`timescale 1ns/1ps

module axi_memory #(
    parameter DEPTH      = 1024,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic                      wr_en,
    input  logic [(DATA_WIDTH/8)-1:0] wr_strb,
    input  logic [ADDR_WIDTH-1:0]     wr_addr,
    input  logic [DATA_WIDTH-1:0]     wr_data,

    input  logic                      rd_en,
    input  logic [ADDR_WIDTH-1:0]     rd_addr,
    output logic [DATA_WIDTH-1:0]     rd_data
);

    localparam BYTE_LANES = DATA_WIDTH / 8;
    localparam ADDR_LSB   = $clog2(BYTE_LANES);
    localparam IDX_W      = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    wire [IDX_W-1:0] wr_idx = wr_addr[ADDR_LSB +: IDX_W];
    wire [IDX_W-1:0] rd_idx = rd_addr[ADDR_LSB +: IDX_W];

    integer i;
    integer b;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= '0;

            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= '0;
            end
        end else begin

            // Byte write enable
            if (wr_en) begin
                for (b = 0; b < BYTE_LANES; b = b + 1) begin
                    if (wr_strb[b]) begin
                        mem[wr_idx][(8*b) +: 8] <= wr_data[(8*b) +: 8];
                    end
                end
            end

            // Synchronous read
            if (rd_en) begin
                rd_data <= mem[rd_idx];
            end
        end
    end

endmodule
