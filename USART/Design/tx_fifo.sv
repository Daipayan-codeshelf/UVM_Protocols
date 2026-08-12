`ifndef TX_FIFO_V
`define TX_FIFO_V

// TX FIFO - depth 16, width 8

module tx_fifo(
    input        clk,
    input        rst_n,
    input        wr_en,
    input        rd_en,
    input  [7:0] din,
    output [7:0] dout,
    output       TX_full,
    output       TX_empty,
    output       TX_overflow,
    output       TX_underflow
);

    parameter DEPTH = 16;
    parameter PTR_W = 4;
    parameter CNT_W = 5;

    reg [7:0]       fifo  [0:DEPTH-1];
    reg [PTR_W-1:0] w_ptr;
    reg [PTR_W-1:0] r_ptr;
    reg [CNT_W-1:0] count;
    integer         i;

    assign TX_full      = (count == DEPTH);
    assign TX_empty     = (count == 0);
    assign TX_overflow  = wr_en && TX_full;
    assign TX_underflow = rd_en && TX_empty;

    /* Pure FWFT: dout always reflects current read pointer */
    assign dout = fifo[r_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <= 0;
            r_ptr <= 0;
            count <= 0;
            for (i = 0; i < DEPTH; i = i + 1)
                fifo[i] <= 8'h00;
        end else begin
            if (wr_en && !TX_full && rd_en && !TX_empty) begin
                fifo[w_ptr] <= din;
                w_ptr <= (w_ptr == DEPTH-1) ? 0 : w_ptr + 1;
                r_ptr <= (r_ptr == DEPTH-1) ? 0 : r_ptr + 1;
                /* count unchanged */
            end else begin
                if (wr_en && !TX_full) begin
                    fifo[w_ptr] <= din;
                    w_ptr <= (w_ptr == DEPTH-1) ? 0 : w_ptr + 1;
                    count <= count + 1;
                end
                if (rd_en && !TX_empty) begin
                    r_ptr <= (r_ptr == DEPTH-1) ? 0 : r_ptr + 1;
                    count <= count - 1;
                end
            end
        end
    end

endmodule

`endif
