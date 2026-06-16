module spi_reg_block (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire [7:0]  addr,
    input  wire        wr_en,
    input  wire [31:0] wr_data,
    input  wire        rd_en,
    output reg  [31:0] rd_data,
    
    output reg  [15:0] clk_div,
    output reg         cpol,
    output reg         cpha,
    output reg  [5:0]  frame_size,
    output reg         cs_hold,
    output reg         err_clr,
    output reg         cs_release,
    output reg         tx_wr_en,
    output reg  [31:0] tx_data_in,
    output reg         rx_rd_en,
    
    input  wire [31:0] rx_data_out,
    input  wire        tx_full,
    input  wire        tx_empty,
    input  wire        tx_overflow,
    input  wire        rx_full,
    input  wire        rx_empty,
    input  wire        rx_underflow
);

    localparam ADDR_CTRL    = 8'h00;
    localparam ADDR_STAT    = 8'h04;
    localparam ADDR_TX_DATA = 8'h08;
    localparam ADDR_RX_DATA = 8'h0C;

    // =============================
    // WRITE LOGIC (FIXED)
    // =============================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div    <= 16'd2;
            cpol       <= 1'b0;
            cpha       <= 1'b0;
            frame_size <= 6'd8;
            cs_hold    <= 1'b0;
            err_clr    <= 1'b0;
            cs_release <= 1'b0;
            tx_wr_en   <= 1'b0;
            tx_data_in <= 32'd0;
        end else begin
            //  default pulses
            tx_wr_en   <= 1'b0;
            err_clr    <= 1'b0;
            cs_release <= 1'b0;

            if (wr_en) begin
                case (addr)

                    ADDR_CTRL: begin
                        clk_div    <= wr_data[31:16];
                        if (wr_data[9]) err_clr <= 1'b1;
                        cs_hold    <= wr_data[8];
                       if (wr_data[10])
    cs_release <= 1'b1; // pulse
                        frame_size <= wr_data[7:2];
                        cpha       <= wr_data[1];
                        cpol       <= wr_data[0];
                    end

                    //  RESTORED (CRITICAL)
                    ADDR_TX_DATA: begin
                        tx_data_in <= wr_data;
                        tx_wr_en   <= 1'b1;
                    end

                endcase
            end
        end
    end


    // =============================
    // READ LOGIC (UNCHANGED)
    // =============================
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_data  <= 32'd0;
        rx_rd_en <= 1'b0;
    end else begin
        rx_rd_en <= 1'b0;
        // REMOVED: rd_data <= 32'd0  ← this was the bug

        if (rd_en) begin
            case (addr)
                ADDR_CTRL: begin
                    rd_data <= {clk_div, 6'd0, 1'b0, cs_hold,
                                frame_size, cpha, cpol};
                end
                ADDR_STAT: begin
                    rd_data <= {26'd0, rx_underflow, rx_full,
                                rx_empty, tx_overflow,
                                tx_full, tx_empty};
                end
                ADDR_RX_DATA: begin
                    rd_data  <= rx_data_out;
                    rx_rd_en <= 1'b1;
                end
            endcase
        end
    end
end
endmodule
