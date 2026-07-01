// -----------------------------------------------------------------------------
// can_btu.v  (Verilog-2001)
// Bit-Timing Unit for simplified Classical CAN training controller
// - Fixed baud via BIT_TICKS counter (system_clk ticks per CAN bit)
// - sample_point at ~80% of bit time (SAMPLE_TAP)
// - bit_tick at end of bit
// - sof_detect on recessive->dominant edge when bus is idle (intermission met)
// - hard_resync mirrors sof_detect
// - bus_idle/intermission_done asserted after 3 consecutive recessive bit times
//
// Notes:
// * Input is can_rx_sync (already 2-FF synchronized by Bus-IF per addendum).
// * No advanced segments (Prop, Phase1, Phase2); simplified timing for training.
// -----------------------------------------------------------------------------
module can_btu #(
    parameter integer BIT_TICKS   = 20,                // sysclks per CAN bit
    parameter integer SAMPLE_TAP  = (BIT_TICKS*4)/5,   // 80% point (e.g., 16 when BIT_TICKS=20)
    parameter integer INTERM_BITS = 3                  // intermission recessive bits
)(
    input  wire clk,
    input  wire reset_n,

    input  wire can_rx_sync,       // synchronized bus line: 1=recessive, 0=dominant

    output wire bit_tick,          // 1-cycle strobe at end of each CAN bit time
    output wire sample_point,      // 1-cycle strobe at 80% point of bit time
    output reg  sof_detect,        // 1-cycle pulse on SOF edge (idle -> dominant)
    output wire hard_resync,       // mirror of sof_detect (per simplified design)
    output reg  bus_idle,          // high when intermission satisfied (>= 3 recessive bits)
    output reg  intermission_done  // same as bus_idle in this simplified BTU
);

    // -------------------------------------------------------------------------
    // Bit-time counter for timing strobes
    // -------------------------------------------------------------------------
    reg [$clog2(BIT_TICKS)-1:0] cnt;

    assign sample_point = (cnt == (SAMPLE_TAP-1));
    assign bit_tick     = (cnt == (BIT_TICKS-1));

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cnt <= {($clog2(BIT_TICKS)){1'b0}};
        end else if (bit_tick) begin
            cnt <= {($clog2(BIT_TICKS)){1'b0}};
        end else begin
            cnt <= cnt + {{($clog2(BIT_TICKS)-1){1'b0}},1'b1};
        end
    end

    // -------------------------------------------------------------------------
    // SOF detection: falling edge (recessive->dominant) when bus is idle
    // -------------------------------------------------------------------------
    reg rx_q;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) rx_q <= 1'b1;         // assume recessive on reset
        else          rx_q <= can_rx_sync;
    end

    wire recessive_to_dominant = (rx_q == 1'b1) && (can_rx_sync == 1'b0);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sof_detect <= 1'b0;
        end else begin
            // pulse on qualifying edge; no need to gate with sample_point here
            sof_detect <= recessive_to_dominant && bus_idle;
        end
    end

    assign hard_resync = sof_detect; // simplified: resync on SOF edge only

    // -------------------------------------------------------------------------
    // Recessive-bit counter -> bus_idle / intermission_done
    // Count at bit boundaries using the value sampled at sample_point.
    // bus_idle/intermission_done asserted once we've seen >= INTERM_BITS
    // consecutive recessive bits; cleared upon any dominant bit.
    // -------------------------------------------------------------------------
    reg [3:0] recessive_cnt; // enough for small counts

    reg sample_point_q;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sample_point_q  <= 1'b0;
            recessive_cnt   <= 4'd0;
            bus_idle        <= 1'b0;
            intermission_done <= 1'b0;
        end else begin
            sample_point_q <= sample_point;

            // On each sample_point, classify the bit level
            if (sample_point_q) begin
                if (can_rx_sync == 1'b1) begin
                    // recessive bit observed
                    if (recessive_cnt < 4'hF)
                        recessive_cnt <= recessive_cnt + 4'd1;
                end else begin
                    // dominant bit observed -> break recessive run
                    recessive_cnt <= 4'd0;
                end

                // Update idle/intermission flags
                if (recessive_cnt >= INTERM_BITS-1) begin
                    bus_idle          <= 1'b1;
                    intermission_done <= 1'b1;
                end else begin
                    bus_idle          <= 1'b0;
                    intermission_done <= 1'b0;
                end
            end

            // Clear idle when a dominant edge appears immediately
            if (recessive_to_dominant) begin
                bus_idle          <= 1'b0;
                intermission_done <= 1'b0;
            end
        end
    end

endmodule
