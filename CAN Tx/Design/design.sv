// -----------------------------------------------------------------------------
// can_tx.v  (Verilog-2001)
// Classical CAN 2.0A Transmit path (training build)
// - SOF -> ID -> RTR(0) -> IDE(0) -> r0(0) -> DLC -> DATA -> CRC(15) ->
//   CRC delimiter (1) -> ACK slot (TX recessive) -> ACK delimiter (1) ->
//   EOF(7) -> Intermission(3)
// - Bit stuffing: insert complement after five identical bits from SOF through
//   end of CRC sequence (no stuffing on CRC delimiter, ACK, or EOF).
// - CRC handshake: seed before ID, feed destuffed ID->DATA bits only.
// - Arbitration: during ID, if TX sends recessive and samples dominant at
//   sample_point, set arb_lost and abort.
// - ACK: in ACK slot, TX drives recessive; Bus-IF drives dominant iff ack_req=1.
// - Start request is latched (tx_req) and consumed at next legal bit boundary,
//   so tx_start need not be aligned with bit_tick.
// -----------------------------------------------------------------------------
module can_tx
(
    input  wire        clk,
    input  wire        reset_n,

    // Core-side controls (from TB today; from Reg-IF later)
    input  wire        tx_start,          // 1-cycle pulse (asynchronous to bit_tick allowed)
    input  wire [10:0] tx_id,             // Identifier (MSB-first on wire)
    input  wire [3:0]  tx_dlc,            // 0..8
    input  wire [63:0] tx_data,           // bytes MSB-first per byte

    // Timing from BTU
    input  wire        bit_tick,          // advance bit boundary
    input  wire        sample_point,      // sample bus (80% bit time)
    input  wire        intermission_done, // TX may start only after this

    // From Bus-IF
    input  wire        can_rx_sync,       // synchronized bus RX

    // To Bus-IF
    output reg         tx_data_bit,       // serialized bit (incl. stuffed)
    output reg         in_ack_slot,       // 1 only during the ACK bit

    // CRC15 handshake (to/from dedicated TX CRC instance)
    output reg         crc_init,          // 1 cycle before first ID bit
    output reg         crc_enable,        // 1 cycle per destuffed bit
    output reg         crc_bit_in,        // MSB-first destuffed bit
    input  wire [14:0] crc_out,           // running remainder

    // Status
    output reg         tx_done,           // pulse when EOF+intermission complete
    output reg         tx_no_ack,         // no dominant seen in ACK slot
    output reg         arb_lost,          // arbitration lost during ID
    output reg         tx_error,           // internal error (consistency)
    output wire [14:0] tx_crc_final
);

    // =========================================================================
    // State machine
    // =========================================================================
    localparam [4:0]
        S_IDLE     = 5'd0,
        S_SOF      = 5'd1,
        S_ID       = 5'd2,
        S_RTR      = 5'd3,
        S_IDE      = 5'd4,
        S_R0       = 5'd5,
        S_DLC      = 5'd6,
        S_DATA     = 5'd7,
        S_CRC      = 5'd8,
        S_CRC_DEL  = 5'd9,
        S_ACK      = 5'd10,
        S_ACK_DEL  = 5'd11,
        S_EOF      = 5'd12,
        S_WAIT_INT = 5'd13;

    // Constants
    localparam integer ID_BITS  = 11;
    localparam integer DLC_BITS = 4;
    localparam integer CRC_BITS = 15;
    localparam integer EOF_BITS = 7;

    localparam SOF_BIT = 1'b0; // dominant
    localparam RTR_BIT = 1'b0; // data frame
    localparam IDE_BIT = 1'b0; // standard format
    localparam R0_BIT  = 1'b0; // reserved
    localparam REC     = 1'b1; // recessive

    // =========================================================================
    // Registers
    // =========================================================================
    reg [4:0]  state;

    // Field counters
    reg [3:0]  cnt_id;      // 0..10
    reg [2:0]  cnt_dlc;     // 0..3
    reg [5:0]  cnt_data;    // 0..63
    reg [4:0]  cnt_crc;     // 0..14
    reg [2:0]  cnt_eof;     // 0..6

    wire [6:0] total_data_bits = {3'b000, tx_dlc} * 7'd8;

    // CRC remainder captured for serialization
    reg  [14:0] crc_latch;
    reg         crc_capture_pending;
    assign tx_crc_final = crc_latch;

    // Stuffing context (active from SOF through CRC sequence)
    reg  last_bit;
    reg  [2:0] run_len;        // 1..5
    reg        stuff_next;     // insert complement next bit
    reg        stuffing_scope; // 1 when stuffing is in effect
    reg        sending_stuff;  // currently outputting a stuffed bit
    reg        raw_bit;        // pre-stuff bit for current field

    // Arbitration/ACK strobes (combinational enables)
    reg sample_arb;
    reg sample_ack;

    // Start request latch (so tx_start need not align to bit_tick)
    reg tx_req;

    // =========================================================================
    // Small helpers
    // =========================================================================
    task clear_status; begin
        tx_done   <= 1'b0;
        tx_no_ack <= 1'b0;
        arb_lost  <= 1'b0;
        tx_error  <= 1'b0;
    end endtask

    task stuffing_init; begin
        last_bit       <= 1'b1;  // will be updated on first emitted bit
        run_len        <= 3'd0;
        stuff_next     <= 1'b0;
        stuffing_scope <= 1'b1;
        sending_stuff  <= 1'b0;
    end endtask

    task stuffing_update;
      input bit next_field_or_crc_bit;
    begin
        if (sending_stuff) begin
            // We just sent the complement; start a new run with that complement
            last_bit   <= ~last_bit;
            run_len    <= 3'd1;
            stuff_next <= 1'b0;
        end else begin
            if (next_field_or_crc_bit == last_bit) begin
                run_len <= run_len + 3'd1;
                // After five identical bits (run_len==4 before emitting), stuff next
                if (run_len == 3'd4) stuff_next <= 1'b1;
                else                  stuff_next <= 1'b0;
            end else begin
                last_bit   <= next_field_or_crc_bit;
                run_len    <= 3'd1;
                stuff_next <= 1'b0;
            end
        end
    end endtask

    // =========================================================================
    // Start request latch (independent of bit_tick)
    // =========================================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_req <= 1'b0;
        end else begin
            if (tx_start)
                tx_req <= 1'b1;

            // Clear exactly when we are about to launch from S_IDLE at a bit boundary
            if (bit_tick && (state==S_IDLE) && intermission_done && tx_req)
                tx_req <= 1'b0;
        end
    end

    // =========================================================================
    // Combinational: choose raw_bit for current field and enables for sampling
    // =========================================================================
    always @(*) begin
        raw_bit    = REC;
        sample_arb = 1'b0;
        sample_ack = 1'b0;

        case (state)
            S_SOF:      raw_bit = SOF_BIT;

            S_ID: begin
                raw_bit    = tx_id[ID_BITS-1 - cnt_id];
                sample_arb = 1'b1; // arbitration in ID field only
            end

            S_RTR:      raw_bit = RTR_BIT;
            S_IDE:      raw_bit = IDE_BIT;
            S_R0:       raw_bit = R0_BIT;

            S_DLC:      raw_bit = tx_dlc[DLC_BITS-1 - cnt_dlc];

            S_DATA:     raw_bit = tx_data[63 - cnt_data]; // MSB-first across payload

            S_CRC:      raw_bit = crc_latch[CRC_BITS-1 - cnt_crc]; // remainder MSB-first

            S_CRC_DEL:  raw_bit = REC; // fixed recessive
            S_ACK: begin
                raw_bit    = REC;      // TX must drive recessive in ACK
                sample_ack = 1'b1;
            end
            S_ACK_DEL:  raw_bit = REC;
            S_EOF:      raw_bit = REC;

            default:    raw_bit = REC;
        endcase
    end

    // =========================================================================
    // Sequential: FSM, counters, stuffing, CRC handshake, outputs
    // =========================================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state               <= S_IDLE;

            cnt_id              <= 4'd0;
            cnt_dlc             <= 3'd0;
            cnt_data            <= 6'd0;
            cnt_crc             <= 5'd0;
            cnt_eof             <= 3'd0;

            crc_latch           <= 15'h0000;
            crc_capture_pending <= 1'b0;

            tx_data_bit         <= REC;
            in_ack_slot         <= 1'b0;

            crc_init            <= 1'b0;
            crc_enable          <= 1'b0;
            crc_bit_in          <= 1'b0;

            stuffing_init();
            clear_status();
        end else begin
            // Defaults each cycle
            tx_done    <= 1'b0;
            crc_init   <= 1'b0;
            crc_enable <= 1'b0;

            if (bit_tick) begin
                // Default outside ACK slot
                in_ack_slot <= 1'b0;

                // Decide if we emit a stuffed bit this bit time
                sending_stuff <= 1'b0;
                if (stuffing_scope && stuff_next) begin
                    tx_data_bit  <= ~last_bit; // send complement
                    sending_stuff<= 1'b1;
                end else begin
                    tx_data_bit  <= raw_bit;   // send field bit
                end

                // ---------------- FSM at bit boundaries ----------------
                case (state)

                    // ---------------------------------------------------
                    S_IDLE: begin
                        // Only start when intermission is complete and a request is pending
                        if (intermission_done && tx_req) begin
                            // Prepare SOF
                            state <= S_SOF;

                            stuffing_init();
                            clear_status();

                            // Initialize stuffing run with SOF dominant
                            last_bit   <= SOF_BIT;
                            run_len    <= 3'd1;
                            stuff_next <= 1'b0;

                            // Reset field counters
                            cnt_id   <= 4'd0;
                            cnt_dlc  <= 3'd0;
                            cnt_data <= 6'd0;
                            cnt_crc  <= 5'd0;

                            // Seed CRC one bit before first ID bit (we're sending SOF now)
                            crc_init <= 1'b1;

                            stuffing_scope <= 1'b1;
                            crc_capture_pending <= 1'b0;
                        end else begin
                            state <= S_IDLE;
                        end
                        // Update stuffing context for SOF
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_SOF: begin
                        if (!sending_stuff) begin
                            state  <= S_ID;
                            cnt_id <= 4'd0;
                        end
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_ID: begin
                        // Arbitration check at sample_point
                        if (sample_point && sample_arb) begin
                            if ((tx_data_bit == 1'b1) && (can_rx_sync == 1'b0)) begin
                                arb_lost <= 1'b1;
                                state    <= S_IDLE; // abort transmission
                            end
                        end

                        // Feed CRC with destuffed ID bit
                        if (!sending_stuff) begin
                            crc_enable <= 1'b1;
                            crc_bit_in <= raw_bit;

                            if (cnt_id == (ID_BITS-1)) begin
                                state  <= S_RTR;
                                cnt_id <= 4'd0;
                            end else begin
                                cnt_id <= cnt_id + 4'd1;
                            end
                        end

                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_RTR: begin
                        if (!sending_stuff) begin
                            crc_enable <= 1'b1; crc_bit_in <= raw_bit;
                            state <= S_IDE;
                        end
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_IDE: begin
                        if (!sending_stuff) begin
                            crc_enable <= 1'b1; crc_bit_in <= raw_bit;
                            state <= S_R0;
                        end
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_R0: begin
                        if (!sending_stuff) begin
                            crc_enable <= 1'b1; crc_bit_in <= raw_bit;
                            state <= S_DLC; cnt_dlc <= 3'd0;
                        end
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_DLC: begin
                      if (!sending_stuff) begin
                          crc_enable <= 1'b1;
                          crc_bit_in <= raw_bit;
                        
                          if (cnt_dlc == (DLC_BITS-1)) begin
                              // DLC validity check
                              if (tx_dlc > 4'd8) begin

                                  tx_error <= 1'b1;
                                  state    <= S_IDLE;
                              end
                              else begin
                                  if (total_data_bits == 7'd0) begin
                                      state               <= S_CRC;
                                      cnt_crc             <= 5'd0;
                                      crc_capture_pending <= 1'b1;
                                  end
                                  else begin
                                      state    <= S_DATA;
                                      cnt_data <= 6'd0;
                                  end
                              end
                          end
                          else begin
                              cnt_dlc <= cnt_dlc + 3'd1;
                          end
                      end
                      stuffing_update(raw_bit);
                  end

                    // ---------------------------------------------------
                    S_DATA: begin
                        if (!sending_stuff) begin
                            crc_enable <= 1'b1; crc_bit_in <= raw_bit;

                            if (cnt_data == (total_data_bits-1)) begin
                                // End of data: capture CRC remainder next tick (after last enable)
                                state                <= S_CRC;
                                cnt_crc              <= 5'd0;
                                crc_capture_pending  <= 1'b1;
                            end else begin
                                cnt_data <= cnt_data + 6'd1;
                            end
                        end
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_CRC: begin
                        // On entry tick after data/empty payload, latch updated remainder
                        if (crc_capture_pending) begin
                            crc_latch           <= crc_out;
                            crc_capture_pending <= 1'b0;
                        end

                        // Serialize 15-bit remainder (with stuffing)
                        if (!sending_stuff) begin
                            if (cnt_crc == (CRC_BITS-1)) begin
                                state          <= S_CRC_DEL;
                                stuffing_scope <= 1'b0; // stuffing ends after CRC sequence
                            end else begin
                                cnt_crc <= cnt_crc + 5'd1;
                            end
                        end
                        stuffing_update(raw_bit);
                    end

                    // ---------------------------------------------------
                    S_CRC_DEL: begin
                        // Recessive delimiter, not stuffed; ACK slot comes next
                        state      <= S_ACK;
                        // NOTE: in_ack_slot must be asserted ONLY during the ACK bit,
                        // so keep it 0 here; we'll assert it in S_ACK.
                    end

                    // ---------------------------------------------------
                    S_ACK: begin
                        // Mark ACK slot now
                        in_ack_slot <= 1'b1; // Bus-IF may drive dominant if ack_req=1

                        // Sample bus for ACK presence at sample_point
                        //if (sample_point) begin
                        //    if (can_rx_sync == 1'b1) tx_no_ack <= 1'b1; // recessive seen -> no ACK
                        // end

                        // Advance to ACK delimiter after the bit slot
                        if (!sending_stuff) begin
                            state <= S_ACK_DEL;
                        end

                        // No stuffing during ACK, keep these benign:
                        stuff_next   <= 1'b0;
                        sending_stuff<= 1'b0;
                    end

                    // ---------------------------------------------------
                    S_ACK_DEL: begin
                        in_ack_slot <= 1'b0;
                        state       <= S_EOF;
                        cnt_eof     <= 3'd0;
                    end

                    // ---------------------------------------------------
                    S_EOF: begin
                        // 7 recessive bits (not stuffed)
                        if (cnt_eof == (EOF_BITS-1)) begin
                            state <= S_WAIT_INT;
                        end else begin
                            cnt_eof <= cnt_eof + 3'd1;
                        end
                    end

                    // ---------------------------------------------------
                    S_WAIT_INT: begin
                        // Wait for intermission_done (3 recessives from BTU)
                        if (intermission_done) begin
                            tx_done <= 1'b1;
                            state   <= S_IDLE;
                        end
                    end

                    default: begin
                        state    <= S_IDLE;
                        tx_error <= 1'b1;
                    end
                endcase
            end // if (bit_tick)
        end
    end
  
  
  
  
  // -----------------------------------------------------------------------------
// ACK sampling at sample_point (not gated by bit_tick)
// -----------------------------------------------------------------------------
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        // keep any reset behavior you want; tx_no_ack is already cleared on reset elsewhere
    end else begin
        // During ACK slot, TX must sample the bus at sample_point:
        // dominant (0) -> receiver ACKed; recessive (1) -> no-ACK
        if (sample_point && (in_ack_slot == 1'b1)) begin
            if (can_rx_sync == 1'b1) begin
                // No receiver drove dominant -> flag no-ACK
                tx_no_ack <= 1'b1;
            end
            // If dominant, we simply leave tx_no_ack as-is (stays 0)
        end
    end
end
  

endmodule


