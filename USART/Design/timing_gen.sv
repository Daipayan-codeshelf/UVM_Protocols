`ifndef TIMING_GEN_V
`define TIMING_GEN_V

module timing_gen(
    input         clk,
    input         rstn,
    input  [15:0] baud_div,
    output reg    sample_tick
);

    reg [15:0] counter;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            counter     <= 16'd0;
            sample_tick <= 1'b0;
        end else begin
            if (baud_div == 16'd0) begin
                counter     <= 16'd0;
                sample_tick <= 1'b0;
            end else if (counter == (baud_div - 16'd1)) begin
                counter     <= 16'd0;
                sample_tick <= 1'b1;
            end else begin
                counter     <= counter + 16'd1;
                sample_tick <= 1'b0;
            end
        end
    end

endmodule

`endif
