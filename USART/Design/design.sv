`ifndef USART_TOP_V
`define USART_TOP_V

`include "csr_reg_if.sv"
`include "timing_gen.sv"
`include "tx_fifo.sv"
`include "rx_fifo.sv"
`include "tx_usart.sv"
`include "rx_usart.sv"

module usart_top(
    input         pclk,
    input         presetn,

    /* APB */
    input         psel,
    input         penable,
    input         pwrite,
    input  [7:0]  paddr,
    input  [31:0] pwdata,
    output [31:0] prdata,
    output        pready,

    /* Serial */
    input         rxd,
    output        txd,
    output        sclk   /* sync clock - connect to RX device when mode=1 */
);

    /* CSR / config wires */
    wire [7:0]  tx_data;
    wire        tx_write;
    wire [7:0]  rx_data;
    wire        rx_valid;
    wire        parity_err;
    wire        frame_err;
    wire        overrun_err;
    wire [15:0] baud_div;
    wire        mode;
    wire [1:0]  data_len;
    wire        parity_en;
    wire        parity_type;
    wire [1:0]  stop_bits;

    /* Timing */
    wire sample_tick;
    wire sclk_int;   /* internal sclk from tx_usart to rx_usart */

    /* TX FIFO outputs */
    wire [7:0] tx_fifo_dout;
    wire       tx_fifo_empty;
    wire       tx_fifo_full;
    wire       tx_fifo_ovf;
    wire       tx_fifo_udf;
    wire       tx_fifo_rd;

    /* RX FIFO */
    wire [7:0] rx_fifo_data;
    wire       rx_fifo_empty;
    wire       rx_fifo_full;
    wire       rx_fifo_ovf;
    wire       rx_fifo_udf;
    wire       rx_fifo_rd;
  
  
  
  
  

//     /* RX data latch for CSR */
  //     reg  [7:0] rx_data_reg;  /* combinatorial */     Removed
//     reg        rx_valid_reg; /* combinatorial */
  
  
  
  
  
  
  

    /* ==================================================================
       baud_tick: 1-cycle pulse every 16 sample_ticks
       Counter 0..15; baud_tick fires on the 16th sample_tick (cnt==15)
       then counter resets to 0.
       ================================================================== */
    reg [3:0] baud_cnt;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            baud_cnt <= 4'd0;
        else if (sample_tick) begin
            if (baud_cnt == 4'd15)
                baud_cnt <= 4'd0;
            else
                baud_cnt <= baud_cnt + 4'd1;
        end
    end
    wire baud_tick;
    assign baud_tick = sample_tick && (baud_cnt == 4'd15);

    /* ==================================================================
       RX FIFO read on APB read of RX_DATA (0x0C)
       ================================================================== */
    /* rx_apb_read: APB access phase for RX_DATA register */
    wire rx_apb_read = psel && penable && !pwrite && (paddr[5:2] == 4'h3);
    assign rx_fifo_rd = rx_apb_read;

    /* Latch rx_data into a stable hold register when rx_usart delivers a byte.
     * prdata reads from rx_data_reg which stays stable until next byte arrives.
     * No FIFO timing issues - completely decoupled from FIFO pop. */
  
  
//   Removed 
//     always @(posedge pclk or negedge presetn) begin
//         if (!presetn) begin
//             rx_data_reg  <= 8'h00;
//             rx_valid_reg <= 1'b0;
//         end else begin
//             if (rx_valid) begin
//                 rx_data_reg  <= rx_data;
//                 rx_valid_reg <= 1'b1;
//             end
//             if (rx_apb_read)
//                 rx_valid_reg <= 1'b0;     /* clear after CPU reads */
//         end
//     end

    /* ==================================================================
       CSR
       ================================================================== */
    csr_reg_if csr(
        .pclk        (pclk),
        .presetn     (presetn),
        .psel        (psel),
        .penable     (penable),
        .pwrite      (pwrite),
        .paddr       (paddr),
        .pwdata      (pwdata),
        .prdata      (prdata),
        .pready      (pready),
        .mode        (mode),
        .data_len    (data_len),
        .parity_en   (parity_en),
        .parity_type (parity_type),
        .stop_bits   (stop_bits),
        .baud_div    (baud_div),
        .tx_data     (tx_data),
        .tx_write    (tx_write),
        .rx_data     (rx_fifo_data),
    	.rx_valid    (!rx_fifo_empty),
        .parity_err      (parity_err),
        .frame_err       (frame_err),
        .overrun_err     (overrun_err),
        .tx_fifo_full    (tx_fifo_full),
        .tx_fifo_empty   (tx_fifo_empty),
        .tx_fifo_ovf     (tx_fifo_ovf),
        .tx_fifo_udf     (tx_fifo_udf),
        .rx_fifo_full    (rx_fifo_full),
        .rx_fifo_empty   (rx_fifo_empty),
        .rx_fifo_ovf     (rx_fifo_ovf),
        .rx_fifo_udf     (rx_fifo_udf)
    );

    /* ==================================================================
       TX FIFO
       ================================================================== */
    tx_fifo tx_fifo_inst(
        .clk          (pclk),
        .rst_n        (presetn),
        .wr_en        (tx_write),
        .rd_en        (tx_fifo_rd),
        .din          (tx_data),
        .dout         (tx_fifo_dout),
        .TX_full      (tx_fifo_full),
        .TX_empty     (tx_fifo_empty),
        .TX_overflow  (tx_fifo_ovf),
        .TX_underflow (tx_fifo_udf)
    );

    /* ==================================================================
       Timing generator
       ================================================================== */
    timing_gen timing(
        .clk         (pclk),
        .rstn        (presetn),
        .baud_div    (baud_div),
        .sample_tick (sample_tick)
    );

    /* ==================================================================
       TX sequencer
       ------------------------------------------------------------------
       The TX FIFO has REGISTERED output: dout updates one clock after
       rd_en is asserted.

       Sequence:
         IDLE  : on baud_tick + FIFO non-empty → assert rd_en, go DOUT_WAIT
         DOUT_WAIT : ONE clock later dout is valid → latch into tx_buf,
                     set tx_data_ready flag, go LOAD_WAIT
         LOAD_WAIT : wait for next baud_tick → assert data_valid to TX
                     (tx_usart samples data_valid on baud_tick), go BUSY
         BUSY  : count down frame baud_ticks, then go IDLE

       tx_load is held HIGH from LOAD_WAIT until a baud_tick fires;
       tx_usart latches data_in when it sees data_valid on a baud_tick.
       ================================================================== */
    /* ==================================================================
       TX Sequencer
       ------------------------------------------------------------------
       Timeline (baud_div=10, FWFT FIFO):
         Clock N:   APB write: wr_en=1, din=0xA5
                    fifo[0] <= 0xA5  (registered, settles AFTER edge N)
                    count   <= 1     (registered, settles AFTER edge N)
         Clock N+1: fifo[0]=0xA5 settled. dout=fifo[r_ptr=0]=0xA5 (comb).
                    TX_empty goes low. Sequencer sees !empty -> TX_WAIT1.
         Clock N+2: TX_WAIT1: do nothing, just confirm dout stable.
                    -> TX_CAPTURE
         Clock N+3: TX_CAPTURE: tx_buf <= tx_fifo_dout  (=0xA5, stable)
                    rd_en NOT asserted yet.
                    -> TX_POP
         Clock N+4: TX_POP: assert rd_en. dout will change AFTER this edge.
                    tx_buf already safely holds 0xA5.
                    -> TX_LOAD_WAIT
         Onwards:   hold tx_load until baud_tick; TX_BUSY counts frame.
       ================================================================== */
    reg [2:0]  tx_seq;
    reg [5:0]  tx_ticks_left;
    reg        tx_fifo_rd_r;
    reg        tx_load;
    reg [7:0]  tx_buf;

    parameter TX_IDLE      = 3'd0;
    parameter TX_WAIT1     = 3'd1;  /* wait 1 clock for fifo[] to settle    */
    parameter TX_CAPTURE   = 3'd2;  /* latch dout into tx_buf               */
    parameter TX_POP       = 3'd3;  /* assert rd_en                         */
    parameter TX_LOAD_WAIT = 3'd4;  /* hold data_valid until baud_tick      */
    parameter TX_BUSY      = 3'd5;  /* counting frame baud_ticks            */

    assign tx_fifo_rd = tx_fifo_rd_r;

    reg [3:0] tx_data_bits;
    always @(*) begin
        case (data_len)
            2'd0: tx_data_bits = 4'd5;
            2'd1: tx_data_bits = 4'd6;
            2'd2: tx_data_bits = 4'd7;
            default: tx_data_bits = 4'd8;
        endcase
    end

    reg [1:0] tx_stop_total;
    always @(*) begin
        if (stop_bits == 2'd0) tx_stop_total = 2'd1;
        else                   tx_stop_total = 2'd2;
    end

    reg [5:0] tx_frame_len;
    always @(*) begin
        tx_frame_len = 6'd1                          /* start bit (both modes) */
                     + {2'b00, tx_data_bits}         /* data bits */
                     + (parity_en ? 6'd1 : 6'd0)    /* optional parity */
                     + {4'b0000, tx_stop_total};     /* stop bits (both modes) */
    end

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            tx_seq        <= TX_IDLE;
            tx_ticks_left <= 6'd0;
            tx_fifo_rd_r  <= 1'b0;
            tx_load       <= 1'b0;
            tx_buf        <= 8'h00;
        end else begin
            tx_fifo_rd_r <= 1'b0;
            tx_load      <= 1'b0;

            case (tx_seq)

                TX_IDLE: begin
                    if (!tx_fifo_empty)
                        tx_seq <= TX_WAIT1;
                end

                /* One idle clock - fifo[w_ptr] write has settled */
                TX_WAIT1: begin
                    tx_seq <= TX_CAPTURE;
                end

                /* dout = fifo[r_ptr] is now stable. Capture it. Do NOT rd_en yet. */
                TX_CAPTURE: begin
                    tx_buf <= tx_fifo_dout;
                    tx_seq <= TX_POP;
                end

                /* Now pop the FIFO. tx_buf already safe. */
                TX_POP: begin
                    tx_fifo_rd_r <= 1'b1;
                    tx_seq       <= TX_LOAD_WAIT;
                end

                /* Hold data_valid HIGH through the baud_tick clock.
                 * tx_usart checks data_valid inside if(baud_tick), so
                 * tx_load must be 1 ON the baud_tick edge.
                 * We move to BUSY on that same baud_tick; tx_load default
                 * (0) will clear it the next clock. */
                TX_LOAD_WAIT: begin
                    tx_load <= 1'b1;      /* keep high every clock in this state */
                    if (baud_tick) begin  /* tx_usart sees data_valid=1 THIS clock */
                        tx_ticks_left <= tx_frame_len;
                        tx_seq        <= TX_BUSY;
                        /* tx_load stays 1 this clock (non-blocking),
                           defaults to 0 next clock via the top-of-block assign */
                    end
                end

                TX_BUSY: begin
                    if (baud_tick) begin
                        if (tx_ticks_left != 6'd0)
                            tx_ticks_left <= tx_ticks_left - 6'd1;
                        if (tx_ticks_left == 6'd1)
                            tx_seq <= TX_IDLE;
                    end
                end

                default: tx_seq <= TX_IDLE;

            endcase
        end
    end

        /* ==================================================================
       TX USART  - fed from latched tx_buf (not directly from FIFO dout)
       ================================================================== */
    tx_usart tx(
        .clk         (pclk),
        .rstn        (presetn),
        .baud_tick   (baud_tick),
        .mode        (mode),
        .data_len    (data_len),
        .parity_en   (parity_en),
        .parity_type (parity_type),
        .stop_bits   (stop_bits),
        .data_in     (tx_buf),      /* stable: latched before dout changes */
        .data_valid  (tx_load),
        .txd         (txd),
        .sclk        (sclk_int)
    );
    assign sclk = sclk_int;

    /* ==================================================================
       RX USART  (16x oversampling)
       ================================================================== */
    rx_usart rx(
        .clk         (pclk),
        .rstn        (presetn),
        .sample_tick (sample_tick),
        .sclk        (sclk_int),
        .rxd         (rxd),
        .mode        (mode),
        .data_len    (data_len),
        .parity_en   (parity_en),
        .parity_type (parity_type),
        .stop_bits   (stop_bits),
        .data_out    (rx_data),
        .data_valid  (rx_valid),
        .parity_err  (parity_err),
        .frame_err   (frame_err)
        
    );

    /* ==================================================================
       RX FIFO
       ================================================================== */
    rx_fifo rx_fifo_inst(
        .clk          (pclk),
        .rst_n        (presetn),
        .wr_en        (rx_valid),
        .rd_en        (rx_fifo_rd),
        .data_in      (rx_data),
        .data_out     (rx_fifo_data),
        .RX_full      (rx_fifo_full),
        .RX_empty     (rx_fifo_empty),
        .RX_overflow  (rx_fifo_ovf),
        .RX_underflow (rx_fifo_udf)
    );
  
  assign overrun_err = rx_fifo_ovf;

endmodule

`endif
