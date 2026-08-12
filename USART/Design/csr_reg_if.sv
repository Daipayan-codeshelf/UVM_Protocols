
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
  
    
//     assign mode        = reg_ctrl[0];
//     assign data_len    = reg_ctrl[2:1];
//     assign parity_en   = reg_ctrl[3];
//     assign parity_type = reg_ctrl[4];
//     assign stop_bits   = reg_ctrl[6:5];
//     assign baud_div    = reg_baud[15:0];

    wire [3:0] reg_sel;
	assign reg_sel = paddr[5:2];

    /* TX data */
    assign tx_data =
        (psel && penable && pwrite && (reg_sel == 4'h2))
        ? pwdata[7:0]
        : reg_txdata[7:0];

    assign tx_write =
        (psel && penable && pwrite && (reg_sel == 4'h2));

    /* APB write registers */
 /* APB write registers */
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            reg_ctrl   <= 32'd0;
            reg_baud   <= 32'd0;
            reg_txdata <= 32'd0;
        end
        else begin
          if (psel && penable && pwrite)
            begin

              
               case(reg_sel)
                  4'h0: begin
                    
                     reg_ctrl <= pwdata;
                  end

                  4'h1: begin
                    
                     reg_baud <= pwdata;
                  end

                  4'h2: begin
                    
                     reg_txdata <= pwdata;
                  end
               endcase
            end
        end
        
    end
  
  
  
  
  

        // Inside csr_reg_if.sv, after your register-write always block:
      assign mode      = reg_ctrl[0];
      assign data_len  = reg_ctrl[2:1];
      assign parity_en = reg_ctrl[3];
      assign parity_type = reg_ctrl[4];
      assign stop_bits = reg_ctrl[6:5];
      assign baud_div  = reg_baud[15:0];
      // assign tx_data   = reg_txdata[7:0];
      // assign tx_write  = (reg_txdata != 8'h00);



  
  
  
  
  
  
  
  

    /* RX data latch + status */
 always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        reg_rxdata <= 32'd0;
        reg_status <= 32'd0;
    end
    else begin

        // RX data latch
        if (rx_valid)
            reg_rxdata <= {24'd0, rx_data};

        // Level signals — always updated, never cleared
        reg_status[3] <= tx_fifo_full;
        reg_status[4] <= tx_fifo_empty;
        reg_status[7] <= rx_fifo_full;
        reg_status[8] <= rx_fifo_empty;

        // CLEAR sticky bits first (lower priority)
        if (psel && penable && !pwrite && (reg_sel == 4'h4)) begin
            reg_status[0]  <= 1'b0;   // parity_err
            reg_status[1]  <= 1'b0;   // frame_err
            reg_status[2]  <= 1'b0;   // overrun_err
            reg_status[5]  <= 1'b0;   // tx_fifo_ovf
            reg_status[6]  <= 1'b0;   // tx_fifo_udf
            reg_status[9]  <= 1'b0;   // rx_fifo_ovf
            reg_status[10] <= 1'b0;   // rx_fifo_udf
        end

        // SET sticky bits last (higher priority — last NBA wins)
        if (parity_err)  reg_status[0]  <= 1'b1;
        if (frame_err)   reg_status[1]  <= 1'b1;
        if (overrun_err) reg_status[2]  <= 1'b1;
        if (tx_fifo_ovf) reg_status[5]  <= 1'b1;
        if (tx_fifo_udf) reg_status[6]  <= 1'b1;
        if (rx_fifo_ovf) reg_status[9]  <= 1'b1;
        if (rx_fifo_udf) reg_status[10] <= 1'b1;

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
  
  
  
  
  
 
//   always @(posedge pclk)
// begin
//    $display("%0t rx_fifo_udf=%0b", $time, rx_fifo_udf);
//   $display(
//    "[%0t] reg_status=%h",
//    $time,
//    reg_status
// );
// end
 
 

endmodule

`endif

