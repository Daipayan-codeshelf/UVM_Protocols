module fifo_adv #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4 // Depth = 16 words
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  err_clr, // Clears sticky error flags
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] dout,
    output wire                  empty,
    output wire                  full,
    output reg                   overflow,
    output reg                   underflow
);

    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH:0]   wr_ptr;
    reg [ADDR_WIDTH:0]   rd_ptr;

    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr == rd_ptr);
    assign dout  = mem[rd_ptr[ADDR_WIDTH-1:0]];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr    <= 0;
            rd_ptr    <= 0;
            overflow  <= 0;
            underflow <= 0;
        end else begin
            // Clear errors
            if (err_clr) begin
                overflow  <= 0;
                underflow <= 0;
            end

            // Write logic
            if (wr_en) begin
                if (!full) begin
                    mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                    wr_ptr <= wr_ptr + 1;
                end else begin
                    overflow <= 1'b1; // Sticky overflow
                end
            end

            // Read logic
            if (rd_en) begin
                if (!empty) begin
                    rd_ptr <= rd_ptr + 1;
                end else begin
                    underflow <= 1'b1; // Sticky underflow
                end
            end
        end
    end
endmodule
