module can_crc15 #(
    parameter [14:0] CRC_SEED       = 15'h7FFF,
    parameter        CRC_OUT_INVERT = 1'b0
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        crc_init,
    input  wire        crc_enable,
    input  wire        crc_bit_in,
    output wire [14:0] crc_out
);
    reg  [14:0] crc_reg;
    wire        fb = crc_bit_in ^ crc_reg[14];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)      crc_reg <= CRC_SEED;
        else if (crc_init) crc_reg <= CRC_SEED;
        else if (crc_enable) begin
            crc_reg[14] <= crc_reg[13] ^ fb; // x^14
            crc_reg[13] <= crc_reg[12];
            crc_reg[12] <= crc_reg[11];
            crc_reg[11] <= crc_reg[10];
            crc_reg[10] <= crc_reg[9]  ^ fb; // x^10
            crc_reg[9]  <= crc_reg[8];
            crc_reg[8]  <= crc_reg[7]  ^ fb; // x^8
            crc_reg[7]  <= crc_reg[6]  ^ fb; // x^7
            crc_reg[6]  <= crc_reg[5];
            crc_reg[5]  <= crc_reg[4];
            crc_reg[4]  <= crc_reg[3]  ^ fb; // x^4
            crc_reg[3]  <= crc_reg[2]  ^ fb; // x^3
            crc_reg[2]  <= crc_reg[1];
            crc_reg[1]  <= crc_reg[0];
            crc_reg[0]  <= fb;               // x^0
        end
    end

    assign crc_out = CRC_OUT_INVERT ? ~crc_reg : crc_reg;
endmodule
