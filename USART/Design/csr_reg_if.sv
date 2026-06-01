
`ifndef CSR_REG_IF_V
`define CSR_REG_IF_V

module csr_reg_if(
    input         pclk,
    input         presetn,
    input         psel,
    input         penable,
    input         pwrite,
    input  [7:0]  paddr,
    input  [31:0] pwdata,
    output reg [31:0] prdata,
    output        pready,

    output        mode,
    output [1:0]  data_len,
    output        parity_en,
    output        parity_type,
    output [1:0]  stop_bits,
    output [15:0] baud_div,

    output [7:0]  tx_data,
    output        tx_write,

    input  [7:0]  rx_data,
    input         rx_valid,
    input         parity_err,
    input         frame_err,
    input         overrun_err,
    input         tx_fifo_full,
    input         tx_fifo_empty,
    input         tx_fifo_ovf,
    input         tx_fifo_udf,
    input         rx_fifo_full,
    input         rx_fifo_empty,
    input         rx_fifo_ovf,
    input         rx_fifo_udf
);

    assign pready = 1'b1;

    reg [31:0] reg_ctrl;
    reg [31:0] reg_baud;
    reg [31:0] reg_txdata;
    reg [31:0] reg_rxdata;
    reg [31:0] reg_status;

    assign mode        = reg_ctrl[0];
    assign data_len    = reg_ctrl[2:1];
    assign parity_en   = reg_ctrl[3];
    assign parity_type = reg_ctrl[4];
    assign stop_bits   = reg_ctrl[6:5];
    assign baud_div    = reg_baud[15:0];

    wire [3:0] reg_sel = paddr[5:2];

    /* TX data */
    assign tx_data =
        (psel && penable && pwrite && (reg_sel == 4'h2))
        ? pwdata[7:0]
        : reg_txdata[7:0];

    assign tx_write =
        (psel && penable && pwrite && (reg_sel == 4'h2));

    /* APB write registers */
    always @(posedge pclk or negedge presetn) begin

    if (!presetn) begin
        reg_ctrl   <= 32'd0;
        reg_baud   <= 32'd0;
        reg_txdata <= 32'd0;
    end
    else begin

        // Debug print whenever any APB signal is active
        if (psel || penable || pwrite)
            $display(
                "[%0t] CSR sees psel=%0b penable=%0b pwrite=%0b reg_sel=%0d",
                $time,
                psel,
                penable,
                pwrite,
                reg_sel
            );

        // Actual write condition
        if (psel && penable && pwrite) begin

            $display(
                "[%0t] CSR_REAL_WRITE reg_sel=%0d data=%h",
                $time,
                reg_sel,
                pwdata
            );

            case (reg_sel)
                4'h0: begin
                    $display("WRITING CTRL");
                    reg_ctrl <= pwdata;
                end

                4'h1: begin
                    $display("WRITING BAUD");
                    reg_baud <= pwdata;
                end

                4'h2: begin
                    $display("WRITING TXDATA");
                    reg_txdata <= pwdata;
                end
            endcase
        end

    end
end
  
  
  
  
  
  

    /* RX data latch + status */
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            reg_rxdata <= 32'd0;
            reg_status <= 32'd0;
        end
        else begin

            /* Hold RX data stable for APB reads */
            if (rx_valid)
                reg_rxdata <= {24'd0, rx_data};

            /* Sticky error bits */
            if (parity_err)
                reg_status[0] <= 1'b1;

            if (frame_err)
                reg_status[1] <= 1'b1;

            if (overrun_err)
                reg_status[2] <= 1'b1;

            /* TX FIFO status */
            reg_status[3] <= tx_fifo_full;
            reg_status[4] <= tx_fifo_empty;
            reg_status[5] <= tx_fifo_ovf;
            reg_status[6] <= tx_fifo_udf;

            /* RX FIFO status */
            reg_status[7]  <= rx_fifo_full;
            reg_status[8]  <= rx_fifo_empty;
            reg_status[9]  <= rx_fifo_ovf;
            reg_status[10] <= rx_fifo_udf;

            /* Clear sticky errors on STATUS read */
            if (psel && penable && !pwrite &&
                (reg_sel == 4'h4))
                reg_status[2:0] <= 3'd0;
        end
    end

    /* APB read mux */
    always @(*) begin
        if (psel && !pwrite) begin
            case (reg_sel)
                4'h0:    prdata = reg_ctrl;
                4'h1:    prdata = reg_baud;
                4'h2:    prdata = reg_txdata;
                4'h3:    prdata = reg_rxdata;
                4'h4:    prdata = reg_status;
                default: prdata = 32'd0;
            endcase
        end
        else begin
            prdata = 32'd0;
        end
    end
  
  
  
  
  
  
  
  
  
  always @(posedge pclk) begin
    #1;
    $display(
      "[%0t] REGS ctrl=%h baud=%h tx=%h",
      $time,
      reg_ctrl,
      reg_baud,
      reg_txdata
    );
end
  
  
  
  
  
  always @(posedge pclk)
begin
   $display(
      "[%0t] CSR_INPUTS presetn=%0b psel=%0b penable=%0b pwrite=%0b",
      $time,
      presetn,
      psel,
      penable,
      pwrite
   );
end
  

endmodule

`endif

