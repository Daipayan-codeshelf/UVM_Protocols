`ifndef TX_USART_V
`define TX_USART_V

module tx_usart(
    input        clk,
    input        rstn,
    input        baud_tick,

    input        mode,         /* 0=async(UART)  1=sync(USART) */
    input  [1:0] data_len,
    input        parity_en,
    input        parity_type,
    input  [1:0] stop_bits,

    input  [7:0] data_in,
    input        data_valid,
    output reg   txd,
    output reg   sclk
);

    /* ------------------------------------------------------------------
     * Frame structure:
     *
     * ASYNC (mode=0):  [START=0][D0..Dn][PARITY?][STOP x1or2]
     *   - stop bits mandatory: receiver needs HIGH→LOW edge for next frame
     *   - no shared clock, line must return to idle between frames
     *
     * SYNC  (mode=1):  [START=0][D0..Dn][PARITY?]  ← NO STOP BITS
     *   - receiver clocked by SCLK, not by line transitions
     *   - stop bits carry no meaning in sync mode
     *   - frame ends when SCLK stops pulsing
     * ------------------------------------------------------------------ */

    parameter IDLE   = 3'd0;
    parameter DATA   = 3'd2;
    parameter PARITY = 3'd3;
    parameter STOP   = 3'd4;

    reg [2:0] state;
    reg [7:0] piso;
    reg [3:0] bit_cnt;
    reg       parity_bit;
    reg [1:0] stop_cnt;

    /* ---- config decoders ---- */
    reg [3:0] data_bits;
    always @(*) begin
        case (data_len)
            2'd0: data_bits = 4'd5;
            2'd1: data_bits = 4'd6;
            2'd2: data_bits = 4'd7;
            default: data_bits = 4'd8;
        endcase
    end

    reg [1:0] stop_total;
    always @(*) begin
        if (stop_bits == 2'd0) stop_total = 2'd1;
        else                   stop_total = 2'd2;
    end

    reg [7:0] data_mask;
    always @(*) begin
        case (data_bits)
            4'd5: data_mask = 8'h1F;
            4'd6: data_mask = 8'h3F;
            4'd7: data_mask = 8'h7F;
            default: data_mask = 8'hFF;
        endcase
    end

    /* ------------------------------------------------------------------
     * SCLK generation (sync mode only)
     * Delayed 1 cycle after baud_tick so txd is stable when sclk rises.
     * Stays high for 2 clocks then falls.
     * Only pulses during DATA and PARITY — not during START or STOP.
     * ------------------------------------------------------------------ */
    reg sclk_set;
    reg sclk_clr1;
    reg sclk_clr2;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sclk_set  <= 1'b0;
            sclk_clr1 <= 1'b0;
            sclk_clr2 <= 1'b0;
            sclk      <= 1'b0;
        end else begin
            sclk_set  <= mode && baud_tick && (state == DATA || state == PARITY);
            sclk_clr1 <= sclk_set;
            sclk_clr2 <= sclk_clr1;
            if      (sclk_set)  sclk <= 1'b1;
            else if (sclk_clr2) sclk <= 1'b0;
        end
    end

    /* ------------------------------------------------------------------
     * TX state machine — advances only on baud_tick
     * ------------------------------------------------------------------ */
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state      <= IDLE;
            txd        <= 1'b1;
            piso       <= 8'h00;
            bit_cnt    <= 4'd0;
            parity_bit <= 1'b0;
            stop_cnt   <= 2'd0;
        end else if (baud_tick) begin

            case (state)

                /* --------------------------------------------------------
                 * IDLE: line held HIGH
                 * On data_valid: load byte, pre-compute parity,
                 *                send START bit (LOW), go to DATA
                 * -------------------------------------------------------- */
                IDLE: begin
                    txd <= 1'b1;
                    if (data_valid) begin
                        piso       <= data_in;
                        bit_cnt    <= 4'd0;
                        parity_bit <= ^(data_in & data_mask);
                        txd        <= 1'b0;   /* START bit */
                        state      <= DATA;
                    end
                end

                /* --------------------------------------------------------
                 * DATA: shift out LSB first, count bits
                 *
                 * After last bit:
                 *   parity_en=1          → always go to PARITY
                 *                          (both modes need parity bit)
                 *   parity_en=0, ASYNC   → go to STOP
                 *                          (line must return HIGH, receiver
                 *                           needs idle gap before next frame)
                 *   parity_en=0, SYNC    → go to IDLE
                 *                          (no stop needed, SCLK just stops)
                 * -------------------------------------------------------- */
                DATA: begin
                    txd  <= piso[0];
                    piso <= {1'b0, piso[7:1]};

                    if (bit_cnt == (data_bits - 4'd1)) begin
                        bit_cnt <= 4'd0;
                        if (parity_en) begin
                            state <= PARITY;        /* both modes: send parity */
                        end else if (!mode) begin   /* ASYNC, no parity */
                            stop_cnt <= 2'd0;
                            state    <= STOP;       /* must send stop bits     */
                        end else begin              /* SYNC, no parity */
                            state    <= IDLE;       /* no stop bits needed     */
                        end
                    end else begin
                        bit_cnt <= bit_cnt + 4'd1;
                    end
                end

                /* --------------------------------------------------------
                 * PARITY: send 1 parity bit
                 *   even parity (parity_type=0): send parity_bit as-is
                 *   odd  parity (parity_type=1): send inverted
                 *
                 * After parity bit:
                 *   ASYNC → go to STOP  (line still needs to return HIGH)
                 *   SYNC  → go to IDLE  (no stop bits, SCLK stops here)
                 * -------------------------------------------------------- */
                PARITY: begin
                    txd <= parity_type ? ~parity_bit : parity_bit;

                    if (!mode) begin        /* ASYNC: stop bits required */
                        stop_cnt <= 2'd0;
                        state    <= STOP;
                    end else begin          /* SYNC: frame complete */
                        state    <= IDLE;
                    end
                end

                /* --------------------------------------------------------
                 * STOP: hold line HIGH for stop_total bit periods
                 * ASYNC only — SYNC never reaches this state
                 * -------------------------------------------------------- */
                STOP: begin
                    txd <= 1'b1;
                    if (stop_cnt + 2'd1 >= stop_total) begin
                        stop_cnt <= 2'd0;
                        state    <= IDLE;
                    end else begin
                        stop_cnt <= stop_cnt + 2'd1;
                    end
                end

                default: begin
                    state <= IDLE;
                    txd   <= 1'b1;
                end

            endcase
        end
    end

endmodule
`endif
