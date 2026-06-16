`ifndef SPI_IF_SV
`define SPI_IF_SV
// =============================================================================
// FILE : spi_if.sv
// DESC : Virtual interface for spi_master_soc_top.
//        rst_n is passed as a port (driven by tb_spi_uvm top-level initial).
//        miso is an output so the driver can implement loopback if needed;
//        in tb_spi_uvm it is tied externally: assign dut_if.miso = dut_if.mosi.
//
// FIX: Added TX/RX FIFO status flag ports (tx_full, tx_empty, rx_full,
//      rx_empty, tx_overflow, rx_underflow) so the monitor can observe them
//      and coverage bins can be sampled.  These are DUT outputs driven by
//      the status register; add them to the DUT port map in tb_spi_uvm.sv.
// =============================================================================
interface spi_if (input logic clk, input logic rst_n);

    // Register bus
    logic [7:0]  addr;
    logic        wr_en;
    logic [31:0] wr_data;
    logic        rd_en;
    logic [31:0] rd_data;

    // SPI physical
    logic        sclk;
    logic        mosi;
    logic        miso;
    logic        cs_n;

    // ------------------------------------------------------------------
    // FIX: FIFO status / flag signals (all DUT outputs → inputs here)
    // ------------------------------------------------------------------
    logic        tx_full;       // TX FIFO full
    logic        tx_empty;      // TX FIFO empty
    logic        rx_full;       // RX FIFO full
    logic        rx_empty;      // RX FIFO empty
    logic        tx_overflow;   // TX FIFO overflow sticky flag
    logic        rx_underflow;  // RX FIFO underflow sticky flag

    // ------------------------------------------------------------------
    // Driver clocking block
    // ------------------------------------------------------------------
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output addr;
        output wr_en;
        output wr_data;
        output rd_en;
        input  rd_data;
        output miso;            // driver can drive loopback if needed
    endclocking

    // ------------------------------------------------------------------
    // Monitor clocking block
    // FIX: FIFO flags sampled by monitor so coverage fires correctly
    // ------------------------------------------------------------------
    clocking monitor_cb @(posedge clk);
        default input #1;
        input addr;
        input wr_en;
        input wr_data;
        input rd_en;
        input rd_data;
        input sclk;
        input mosi;
        input miso;
        input cs_n;
        // FIFO flags
        input tx_full;
        input tx_empty;
        input rx_full;
        input rx_empty;
        input tx_overflow;
        input rx_underflow;
    endclocking

    modport driver_mp  (clocking driver_cb,  input clk, input rst_n);
    modport monitor_mp (clocking monitor_cb, input clk, input rst_n,
                        input sclk, input mosi, input miso, input cs_n,
                        input tx_full,  input tx_empty,
                        input rx_full,  input rx_empty,
                        input tx_overflow, input rx_underflow);

endinterface : spi_if
`endif // SPI_IF_SV
