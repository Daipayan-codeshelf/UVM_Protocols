`ifndef RX_FIFO_V
`define RX_FIFO_V

// RX FIFO - depth 16, width 8

module rx_fifo(
    input        clk,
    input        rst_n,
    input        wr_en,
    input        rd_en,
    input  [7:0] data_in,
    output [7:0] data_out,
    output       RX_full,
    output       RX_empty,
    output       RX_overflow,
    output       RX_underflow
);

    parameter DEPTH = 16;
    parameter PTR_W = 4;
    parameter CNT_W = 5;

    reg [7:0]       fifo [0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] rd_ptr;
    reg [CNT_W-1:0] count;
    integer         i;

    /* Combinatorial output - valid as soon as data is in FIFO */
    assign data_out     = fifo[rd_ptr];
    assign RX_full      = (count == DEPTH);
    assign RX_empty     = (count == 0);
    assign RX_overflow  = wr_en && RX_full;
    assign RX_underflow = rd_en && RX_empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            for (i = 0; i < DEPTH; i = i + 1)
                fifo[i] <= 8'h00;
        end else begin
            if (wr_en && !RX_full && rd_en && !RX_empty) begin
                /* simultaneous read + write: count unchanged */
                fifo[wr_ptr] <= data_in;
                wr_ptr       <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                rd_ptr       <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end else begin
                if (wr_en && !RX_full) begin
                    fifo[wr_ptr] <= data_in;
                    wr_ptr       <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                    count        <= count + 1;
                end
                if (rd_en && !RX_empty) begin
                    rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                    count  <= count - 1;
                end
            end
        end
    end

endmodule

`endif
