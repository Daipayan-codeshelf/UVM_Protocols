module clk_divider_prog (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] clk_div_in, // 0 or 1 = bypass (sys_clk/2), else sys_clk/(2*clk_div_in)
    output reg         tick
);

    reg [15:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            tick    <= 1'b0;
        end else begin
            if (counter >= clk_div_in - 16'd1 || clk_div_in < 16'd2) begin
                counter <= 16'd0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 16'd1;
                tick    <= 1'b0;
            end
        end
    end
endmodule
