interface can_if #(
    parameter integer BTU_BIT_TICKS  = 20,
    parameter integer BTU_SAMPLE_TAP = (BTU_BIT_TICKS*4)/5
)(
    input logic clk,
    input logic reset_n
);
    // TX stimulus
    logic        tx_start;
    logic [10:0] tx_id;
    logic [3:0]  tx_dlc;
    logic [63:0] tx_data;
    logic        ack_req;

    // CAN bus
    logic        can_rx_i;
    logic        can_tx_o;

    // DUT status
    logic        tx_done;
    logic        tx_no_ack;
    logic        arb_lost;
    logic        tx_error;

    // BTU visibility
    logic        bit_tick;
    logic        sample_point;
    logic        sof_detect;
    logic        hard_resync;
    logic        bus_idle;
    logic        intermission_done;
    logic [14:0] tx_crc;

    // Clocking block (driver)
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output tx_start;
        output tx_id;
        output tx_dlc;
        output tx_data;
        output ack_req;
        output can_rx_i;
        input  tx_done;
        input  tx_no_ack;
        input  arb_lost;
        input  tx_error;
        input  intermission_done;
        input  bit_tick;
        input  sample_point;
        input  bus_idle;
    endclocking

    // Clocking block (monitor)
    clocking monitor_cb @(posedge clk);
        default input #1;
        input tx_start;
        input tx_id;
        input tx_dlc;
        input tx_data;
        input ack_req;
        input can_rx_i;
        input can_tx_o;
        input tx_done;
        input tx_no_ack;
        input arb_lost;
        input tx_error;
        input intermission_done;
        input bit_tick;
        input sample_point;
        input tx_crc;
    endclocking

    // Modports
    modport driver_mp  (clocking driver_cb,  input clk, input reset_n);
    modport monitor_mp (clocking monitor_cb, input clk, input reset_n);

endinterface
