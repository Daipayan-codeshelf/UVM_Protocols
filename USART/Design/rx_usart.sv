`ifndef RX_USART_V
`define RX_USART_V

module rx_usart(
    input        clk,
    input        rstn,
    input        sample_tick,  /* async: 16x oversample tick */
    input        sclk,         /* sync:  clock from TX (or external master) */
    input        rxd,

    input        mode,
    input  [1:0] data_len,
    input        parity_en,
    input        parity_type,
    input  [1:0] stop_bits,

    output reg [7:0] data_out,
    output reg       data_valid,
    output reg       parity_err,
    output reg      frame_err
//     output wire      overrun_err
);

    /* ----------------------------------------------------------------
     * ASYNC mode (mode=0):
     *   16x oversampling. Detects start bit falling edge, verifies at
     *   midpoint, samples each data bit at midpoint (sample_cnt==15).
     *   Async path completely unchanged from working implementation.
     *
     * SYNC mode (mode=1):
     *   No start bit detection. Samples rxd on rising edge of sclk.
     *   sclk is driven by tx_usart and is high only during DATA/PARITY.
     *   RX watches for rxd low (start bit, sclk=0) to begin, then
     *   samples on each subsequent sclk rising edge.
     * ---------------------------------------------------------------- */

    parameter IDLE   = 3'd0;
    parameter START  = 3'd1;
    parameter DATA   = 3'd2;
    parameter PARITY = 3'd3;
    parameter STOP   = 3'd4;

    /* ----------------------------------------------------------------
     * 2-stage synchronizer for rxd (used by both modes)
     * ---------------------------------------------------------------- */
    reg rxd_r1, rxd_sync;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rxd_r1   <= 1'b1;
            rxd_sync <= 1'b1;
        end else begin
            rxd_r1   <= rxd;
            rxd_sync <= rxd_r1;
        end
    end

    /* sclk delay chain.
     * sclk 2-clock pulse: set at baud_tick+1 (txd already stable by then).
     * rxd_sync = rxd delayed 2 clocks through rxd_r1->rxd_sync pipeline.
     * 3-stage sclk delay: sclk_rise fires at baud_tick+3.
     * At baud_tick+3: rxd_sync has correct stable bit value. */
    reg sclk_d1, sclk_d2, sclk_d3;
    wire sclk_rise;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sclk_d1 <= 1'b0;
            sclk_d2 <= 1'b0;
            sclk_d3 <= 1'b0;
        end else begin
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            sclk_d3 <= sclk_d2;
        end
    end
    assign sclk_rise = sclk_d2 && !sclk_d3;

    /* data_bits / data_mask (shared) */
    reg [3:0] data_bits;
    always @(*) begin
        case (data_len)
            2'd0:    data_bits = 4'd5;
            2'd1:    data_bits = 4'd6;
            2'd2:    data_bits = 4'd7;
            default: data_bits = 4'd8;
        endcase
    end

    reg [7:0] data_mask;
    always @(*) begin
        case (data_bits)
            4'd5:    data_mask = 8'h1F;
            4'd6:    data_mask = 8'h3F;
            4'd7:    data_mask = 8'h7F;
            default: data_mask = 8'hFF;
        endcase
    end

    /* ----------------------------------------------------------------
     * ASYNC state machine - exactly as before, untouched
     * ---------------------------------------------------------------- */
    reg [2:0] async_state;
    reg [7:0] async_sipo;
    reg [3:0] async_bit_cnt;
    reg [3:0] async_sample_cnt;
    reg       async_parity_xor;

    reg [7:0] async_data_out;
    reg       async_data_valid;
    reg       async_parity_err;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            async_state      <= IDLE;
            async_sipo       <= 8'h00;
            async_bit_cnt    <= 4'd0;
            async_sample_cnt <= 4'd0;
            async_parity_xor <= 1'b0;
            async_data_out   <= 8'h00;
            async_data_valid <= 1'b0;
            async_parity_err <= 1'b0;
            frame_err        <= 1'b0;
        end else begin
            async_data_valid <= 1'b0;
          	async_parity_err <= 1'b0;
            frame_err        <= 1'b0; 

            if (sample_tick && !mode) begin
                case (async_state)

                    IDLE: begin
                        if (rxd_sync == 1'b0) begin
                            async_sample_cnt <= 4'd1;
                            async_state      <= START;
                        end
                    end

                    START: begin
                        if (async_sample_cnt == 4'd7) begin
                            if (rxd_sync != 1'b0) begin
                                async_state <= IDLE;
                            end else begin
                                async_sample_cnt <= 4'd0;
                                async_bit_cnt    <= 4'd0;
                                async_sipo       <= 8'h00;
                                async_parity_xor <= 1'b0;
                                async_state      <= DATA;
                            end
                        end else begin
                            async_sample_cnt <= async_sample_cnt + 4'd1;
                        end
                    end

                    DATA: begin
                        if (async_sample_cnt == 4'd15) begin
                            async_sample_cnt          <= 4'd0;
                            async_sipo[async_bit_cnt] <= rxd_sync;
                            async_parity_xor          <= async_parity_xor ^ rxd_sync;
                            if (async_bit_cnt == data_bits - 4'd1) begin
                                async_bit_cnt <= 4'd0;
                                if (parity_en) begin
                                    async_sipo[async_bit_cnt] <= rxd_sync;
                                    async_state <= PARITY;
                                end else begin
                                    async_data_out   <= (async_sipo | ({{7{1'b0}}, rxd_sync} << async_bit_cnt)) & data_mask;
                                    async_data_valid <= 1'b1;
                                    async_state      <= STOP; /* wait out stop bit */
                                end
                            end else begin
                                async_bit_cnt <= async_bit_cnt + 4'd1;
                            end
                        end else begin
                            async_sample_cnt <= async_sample_cnt + 4'd1;
                        end
                    end

                    PARITY: begin
                        if (async_sample_cnt == 4'd15) begin
                            async_sample_cnt <= 4'd0;
                            if (rxd_sync != (parity_type ? ~async_parity_xor : async_parity_xor))
                                async_parity_err <= 1'b1;
                            async_data_out   <= async_sipo & data_mask;
                            async_data_valid <= 1'b1;
                            async_state      <= STOP; /* wait out stop bit */
                        end else begin
                            async_sample_cnt <= async_sample_cnt + 4'd1;
                        end
                    end

                    /* Wait 16 sample_ticks for stop bit before returning to IDLE.
                     * Prevents false start detection when last data bit was 0. */
                    STOP: begin
                        if (async_sample_cnt == 4'd15) begin

                            if (rxd_sync != 1'b1)
                                frame_err <= 1'b1;

                            async_sample_cnt <= 4'd0;
                            async_state      <= IDLE;

                        end
                        else begin
                            async_sample_cnt <= async_sample_cnt + 4'd1;
                        end
                    end

                    default: async_state <= IDLE;

                endcase
            end
        end
    end

    /* ----------------------------------------------------------------
     * SYNC state machine - samples on sclk rising edge
     * ---------------------------------------------------------------- */
    reg [2:0] sync_state;
    reg [7:0] sync_sipo;
    reg [3:0] sync_bit_cnt;
    reg       sync_parity_xor;

    reg [7:0] sync_data_out;
    reg       sync_data_valid;
    reg       sync_parity_err;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_state      <= IDLE;
            sync_sipo       <= 8'h00;
            sync_bit_cnt    <= 4'd0;
            sync_parity_xor <= 1'b0;
            sync_data_out   <= 8'h00;
            sync_data_valid <= 1'b0;
            sync_parity_err <= 1'b0;
        end else begin
            sync_data_valid <= 1'b0;
          	sync_parity_err <= 1'b0;

            case (sync_state)

                /* Wait for start bit: rxd_r1 is rxd registered 1 clock.
                 * By this clock txd=0 is stable and sclk is still 0
                 * (sclk only goes high on next baud_tick in DATA state). */
                IDLE: begin
                    if (rxd_r1 == 1'b0 && sclk == 1'b0) begin
                        sync_sipo       <= 8'h00;
                        sync_bit_cnt    <= 4'd0;
                        sync_parity_xor <= 1'b0;
                        sync_state      <= DATA;
                    end
                end

                /* Sample each data bit on sclk - use rxd directly (same chip) */
                DATA: begin
                    if (sclk_rise) begin
                        sync_sipo[sync_bit_cnt] <= rxd;
                        sync_parity_xor         <= sync_parity_xor ^ rxd;
                        if (sync_bit_cnt == data_bits - 4'd1) begin
                            sync_bit_cnt <= 4'd0;
                            if (parity_en) begin
                                sync_sipo[sync_bit_cnt] <= rxd;
                                sync_state <= PARITY;
                            end else begin
                              sync_data_out <=(sync_sipo |({{7{1'b0}}, rxd} << sync_bit_cnt)) & data_mask;
                                sync_data_valid <= 1'b1;
                                sync_state      <= IDLE;
                            end
                        end else begin
                            sync_bit_cnt <= sync_bit_cnt + 4'd1;
                        end
                    end
                end

                /* Sample parity bit on sclk */
                PARITY: begin
                    if (sclk_rise) begin
                        if (rxd != (parity_type ? ~sync_parity_xor : sync_parity_xor))
                            sync_parity_err <= 1'b1;
                        sync_data_out   <= sync_sipo & data_mask;
                        sync_data_valid <= 1'b1;
                        sync_state      <= IDLE;
                    end
                end

                default: sync_state <= IDLE;

            endcase
        end
    end

    /* ----------------------------------------------------------------
     * Output mux: select async or sync path based on mode
     * ---------------------------------------------------------------- */
    always @(*) begin
        if (mode) begin
            data_out   = sync_data_out;
            data_valid = sync_data_valid;
            parity_err = sync_parity_err;
        end else begin
            data_out   = async_data_out;
            data_valid = async_data_valid;
            parity_err = async_parity_err;
        end
    end

    /* frame_err and overrun_err are async-mode concepts only */
//     assign frame_err   = 1'b0;
//     assign overrun_err = 1'b0;

endmodule

`endif
