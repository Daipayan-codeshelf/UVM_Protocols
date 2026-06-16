`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

// =============================================================================
// FILE : spi_sequencer.sv
// =============================================================================

class spi_sequencer extends uvm_sequencer #(spi_seq_item);
    `uvm_component_utils(spi_sequencer)
    function new(string name = "spi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass : spi_sequencer

`endif // SPI_SEQUENCER_SV
