module spi_main_adv (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick,

    // Configuration
    input  wire        cpol,
    input  wire        cpha,
    input  wire [5:0]  frame_size,
    input  wire        cs_hold,
    input  wire        cs_release,

    // TX FIFO
    input  wire        tx_empty,
    input  wire [31:0] tx_data,
    output reg         tx_rd_en,

    // RX FIFO
    input  wire        rx_full,
    output reg [31:0]  rx_data,
    output reg         rx_wr_en,

    // SPI
    output reg         sclk,
    output reg         mosi,
    input  wire        miso,
    output reg         cs_n
);

    //------------------------------------------------------------
    // STATES
    //------------------------------------------------------------
    localparam IDLE       = 3'd0;
    localparam LOAD       = 3'd1;   // NEW: wait 1 cycle for FIFO output to be valid
    localparam START      = 3'd2;
    localparam LEAD_EDGE  = 3'd3;
    localparam TRAIL_EDGE = 3'd4;
    localparam STOP       = 3'd5;

    reg [2:0] state;

    //------------------------------------------------------------
    // INTERNALS
    //------------------------------------------------------------
    reg [31:0] tx_shift;
    reg [31:0] rx_shift;
    reg [5:0]  bit_cnt;

    //------------------------------------------------------------
    // MAIN FSM
    //------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state    <= IDLE;
            sclk     <= 0;
            mosi     <= 0;
            cs_n     <= 1;
            tx_rd_en <= 0;
            rx_wr_en <= 0;
            tx_shift <= 0;
            rx_shift <= 0;
            rx_data  <= 0;
            bit_cnt  <= 0;
        end
        else begin

            //----------------------------------------------------
            // DEFAULT PULSES
            //----------------------------------------------------
            tx_rd_en <= 0;
            rx_wr_en <= 0;

            

            

                case (state)

                //------------------------------------------------
                // IDLE: detect data available, pulse tx_rd_en
                //------------------------------------------------
                IDLE: begin

                    sclk <= cpol;

                    if (!cs_hold)
                        cs_n <= 1'b1;

                    if (!tx_empty && !rx_full) begin
                        // Pulse read-enable so the FIFO advances.
                        // We do NOT read tx_data here — the FIFO
                        // needs one full clock cycle after rd_en
                        // before its output bus is valid.
                        tx_rd_en <= 1'b1;

                        // Clear rx accumulator for every new frame
                        rx_shift <= 32'd0;

                        bit_cnt <= frame_size;

                        state <= LOAD;  // wait one cycle
                    end
                end

               // REMOVE the global cs_release block entirely, then inside the case:

LOAD: begin
    if (cs_release) begin          // NEW: local release check
        cs_n  <= 1'b1;
        sclk  <= cpol;
        state <= IDLE;
    end else begin
        tx_shift <= tx_data << (32 - frame_size);
        state    <= START;
    end
end

START: begin
    if (cs_release) begin          // NEW: local release check
        cs_n  <= 1'b1;
        sclk  <= cpol;
        state <= IDLE;
    end else begin
        cs_n <= 1'b0;
        sclk <= cpol;
        if (cpha == 0)
            mosi <= tx_shift[31];
        state <= LEAD_EDGE;
    end
end

// Keep cs_release checks in LEAD_EDGE, TRAIL_EDGE, STOP as well
// so behavior is unchanged — just now the tool sees explicit arcs
                //------------------------------------------------
                // LEADING EDGE
                //------------------------------------------------
                LEAD_EDGE: begin

                    if (tick) begin
                        sclk <= ~cpol;

                        // CPHA=0: sample MISO on leading edge
                        if (cpha == 0)
                            rx_shift <= { rx_shift[30:0], miso };
                        // CPHA=1: drive MOSI on leading edge
                        else
                            mosi <= tx_shift[31];

                        state <= TRAIL_EDGE;
                    end
                end

                //------------------------------------------------
                // TRAILING EDGE
                //------------------------------------------------
                TRAIL_EDGE: begin

                    if (tick) begin
                        sclk <= cpol;

                        // CPHA=0: shift tx, pre-load next MOSI bit
                        if (cpha == 0) begin
                            tx_shift <= { tx_shift[30:0], 1'b0 };
                            if (bit_cnt > 1)
                                mosi <= tx_shift[30];
                        end
                        // CPHA=1: sample MISO, shift tx
                        else begin
                            rx_shift <= { rx_shift[30:0], miso };
                            tx_shift <= { tx_shift[30:0], 1'b0 };
                        end

                        if (bit_cnt <= 1) begin
                            bit_cnt <= 0;
                            state   <= STOP;
                        end
                        else begin
                            bit_cnt <= bit_cnt - 1;
                            state   <= LEAD_EDGE;
                        end
                    end
                end

                //------------------------------------------------
                // STOP: push received byte into RX FIFO
                //------------------------------------------------
              STOP: begin

    if (tick) begin

        //------------------------------------------------
        // TRUE RX BACKPRESSURE
        // Stall here until RX FIFO has space
        //------------------------------------------------
        if (!rx_full) begin

            rx_data  <= rx_shift;
            rx_wr_en <= 1'b1;

            sclk <= cpol;

            state <= IDLE;

            // Release CS only when no more bytes pending
            if (!(cs_hold && !tx_empty))
                cs_n <= 1'b1;
        end

        //------------------------------------------------
        // RX FIFO FULL -> HOLD TRANSFER
        //------------------------------------------------
        else begin

            // Hold CS active
            cs_n <= 1'b0;

            // Hold clock idle
            sclk <= cpol;

            // Stay in STOP until space available
            state <= STOP;
        end
    end
end
                default: state <= IDLE;

                endcase
            
        end
    end
           
endmodule
