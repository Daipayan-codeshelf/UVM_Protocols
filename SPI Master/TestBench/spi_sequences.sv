`ifndef SPI_SEQUENCES_SV
`define SPI_SEQUENCES_SV

class spi_base_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_base_seq)

    rand int unsigned n;
    rand bit          cpol;
    rand bit          cpha;
    rand bit [5:0]    frame_size;
    rand bit [15:0]   clk_div;
    rand bit          cs_hold;
    rand bit [31:0]   tx_data;
    
    // FIX: Use knobs instead of randomizing err_clr
    bit force_cs_release = 0;
    bit force_err_clr    = 0; 

    constraint c_n     { n inside {[1:20]}; }
    constraint c_frame { frame_size inside {6'd4, 6'd8, 6'd16, 6'd24, 6'd32}; }
  constraint c_clk   { clk_div inside {[16'd0:16'd65535]}; clk_div % 2 == 0; }

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item = spi_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                cpol       == local::cpol;
                cpha       == local::cpha;
                frame_size == local::frame_size;
                clk_div    == local::clk_div;
                cs_hold    == local::cs_hold;
                tx_data    == local::tx_data;
                n          == local::n;
                cs_release == (local::force_cs_release ? 1'b1 : 1'b0);
                err_clr    == local::force_err_clr; // Tied securely to knob
            })
            `uvm_fatal("SEQ", "item.randomize() failed")
        finish_item(item);
        `uvm_info("SEQ", item.convert2string(), UVM_HIGH)
    endtask

endclass : spi_base_seq
`endif
