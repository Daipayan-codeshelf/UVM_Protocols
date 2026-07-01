// -----------------------------------------------------------------------------
// can_bus_if.v  (Verilog-2001)
// Bus Interface for simplified CAN controller
// - 2-FF synchronizer for can_rx_i -> can_rx_sync
// - ACK drive mux: during ACK slot, if ack_req=1 then drive dominant (0);
//   otherwise pass-through tx_data_bit.
// Notes:
//   dominant = 0, recessive = 1 (logical view toward the transceiver).
// -----------------------------------------------------------------------------
module can_bus_if (
    input  wire clk,
    input  wire reset_n,

    // Raw CAN pins
    input  wire can_rx_i,        // asynchronous RX from transceiver
    output wire can_tx_o,        // to transceiver TXD (dominant=0, recessive=1)

    // From core
    input  wire tx_data_bit,     // bit to put on TXD (outside ACK slot)
    input  wire ack_req,         // asserted by RX when a valid frame should be ACKed
    input  wire in_ack_slot,     // 1 only during the ACK bit time

    // To core
    output wire can_rx_sync      // 2-FF synchronized RX
);

    // 2-FF synchronizer for can_rx_i
    reg rx_meta, rx_sync;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_meta <= 1'b1;   // assume recessive on reset
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= can_rx_i;
            rx_sync <= rx_meta;
        end
    end

    assign can_rx_sync = rx_sync;

    // ACK drive mux:
    // During ACK slot, drive dominant (0) iff ack_req=1.
    // Otherwise, forward tx_data_bit.
    assign can_tx_o = (in_ack_slot && ack_req) ? 1'b0 : tx_data_bit;

endmodule
