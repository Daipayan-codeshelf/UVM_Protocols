class can_sequencer extends uvm_sequencer #(can_seq_item);
    `uvm_component_utils(can_sequencer)

    function new(string name = "can_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

    
