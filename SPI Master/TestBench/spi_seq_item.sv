`ifndef SPI_SEQ_ITEM_SV
`define SPI_SEQ_ITEM_SV

class spi_seq_item extends uvm_sequence_item;
    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(cpol,         UVM_ALL_ON)
        `uvm_field_int(cpha,         UVM_ALL_ON)
        `uvm_field_int(frame_size,   UVM_ALL_ON)
        `uvm_field_int(clk_div,      UVM_ALL_ON)
        `uvm_field_int(cs_hold,      UVM_ALL_ON)
        `uvm_field_int(cs_release,   UVM_ALL_ON)
        `uvm_field_int(tx_data,      UVM_ALL_ON)
        `uvm_field_int(rx_data,      UVM_ALL_ON)
        `uvm_field_int(n,            UVM_ALL_ON)   // NEW: burst count
        `uvm_field_int(tx_full,      UVM_ALL_ON)
        `uvm_field_int(tx_empty,     UVM_ALL_ON)
        `uvm_field_int(rx_full,      UVM_ALL_ON)
        `uvm_field_int(rx_empty,     UVM_ALL_ON)
        `uvm_field_int(tx_overflow,  UVM_ALL_ON)
        `uvm_field_int(rx_underflow, UVM_ALL_ON)
  `uvm_field_int(err_clr, UVM_ALL_ON)
    `uvm_object_utils_end

    rand bit          cpol;
    rand bit          cpha;
    rand bit [5:0]    frame_size;
    rand bit [15:0]   clk_div;
    rand bit          cs_hold;
    rand bit          cs_release;
    rand bit [31:0]   tx_data;
    rand bit [4:0]    n;            // NEW: 1–20 frames per burst

    bit [31:0] rx_data;
    bit        tx_full;
    bit        tx_empty;
    bit        rx_full;
    bit        rx_empty;
    bit        tx_overflow;
    bit        rx_underflow;
// inside uvm_object_utils_begin / end — add after cs_release line:


// rand declarations — add after cs_release:
rand bit err_clr;

// constraint — add anywhere in the constraint block:
constraint c_err_clr { err_clr inside {1'b0, 1'b1}; }

    constraint c_frame_size { frame_size inside {6'd4, 6'd8, 6'd16, 6'd24, 6'd32}; }
  constraint c_clk_div    { clk_div inside {[16'd0:16'd65535]}; clk_div % 2 == 0; }
    constraint c_n          { n inside {[1:20]}; }
    constraint c_release_requires_hold { cs_release == 1'b1 -> cs_hold == 1'b1; }

    function automatic bit [31:0] ctrl_word();
    return { clk_div, 5'd0, cs_release, err_clr,
             cs_hold, frame_size, cpha, cpol };
endfunction


    function automatic bit [31:0] masked_tx();
        if (frame_size == 6'd32) return tx_data;
        return tx_data & ((32'h1 << frame_size) - 1);
    endfunction

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
      return $sformatf(
    "cpol=%0b cpha=%0b fs=%0d div=%0d hold=%0b rel=%0b err_clr=%0b n=%0d tx=0x%08h rx=0x%08h | tf=%0b te=%0b rf=%0b re=%0b ovf=%0b udf=%0b",
    cpol, cpha, frame_size, clk_div,
    cs_hold, cs_release, err_clr, n,
    tx_data, rx_data,
    tx_full, tx_empty, rx_full, rx_empty,
    tx_overflow, rx_underflow
);
    endfunction
endclass : spi_seq_item

`endif
