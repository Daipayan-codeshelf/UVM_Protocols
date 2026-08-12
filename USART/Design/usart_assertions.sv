`ifndef USART_ASSERTIONS_SV
`define USART_ASSERTIONS_SV

module usart_assertions(

    input pclk,
    input presetn,

    // APB
    input psel,
    input penable,
    input pwrite,

    // TX FIFO
    input tx_write,
    input tx_fifo_full,
    input tx_fifo_ovf,

    // RX FIFO
    input rx_fifo_rd,
    input rx_fifo_empty,
    input rx_fifo_udf

);

    ////////////////////////////////////////////////////////////
    // 1. APB Protocol
    // If SETUP phase occurs, ACCESS phase must follow
    ////////////////////////////////////////////////////////////

    property apb_enable_after_select;

        @(posedge pclk)
        disable iff(!presetn)

        (psel && !penable)
            |=> penable;

    endproperty

    APB_ENABLE_AFTER_SELECT_A :
    assert property(apb_enable_after_select)
    else
        $error("[%0t] APB protocol violation: PENABLE not asserted after PSEL",
               $time);



    ////////////////////////////////////////////////////////////
    // 2. RX FIFO Underflow
    ////////////////////////////////////////////////////////////

    property rx_fifo_underflow_check;

        @(posedge pclk)
        disable iff(!presetn)

        (rx_fifo_empty && rx_fifo_rd)
            |-> rx_fifo_udf;

    endproperty

    RX_FIFO_UNDERFLOW_A :
    assert property(rx_fifo_underflow_check)
    else
        $error("[%0t] RX FIFO underflow assertion failed",
               $time);



    ////////////////////////////////////////////////////////////
    // 3. TX FIFO Overflow
    ////////////////////////////////////////////////////////////

    property tx_fifo_overflow_check;

        @(posedge pclk)
        disable iff(!presetn)

        (tx_fifo_full && tx_write)
            |-> tx_fifo_ovf;

    endproperty

    TX_FIFO_OVERFLOW_A :
    assert property(tx_fifo_overflow_check)
    else
        $error("[%0t] TX FIFO overflow assertion failed",
               $time);



    ////////////////////////////////////////////////////////////
    // Optional Coverage
    ////////////////////////////////////////////////////////////

    APB_ENABLE_AFTER_SELECT_C :
    cover property(apb_enable_after_select);

    RX_FIFO_UNDERFLOW_C :
    cover property(rx_fifo_underflow_check);

    TX_FIFO_OVERFLOW_C :
    cover property(tx_fifo_overflow_check);

endmodule

`endif
