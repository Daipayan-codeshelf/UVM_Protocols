class can_seq_item extends uvm_sequence_item;
    `uvm_object_utils_begin(can_seq_item)
        `uvm_field_int(tx_id,      UVM_ALL_ON)
        `uvm_field_int(tx_dlc,     UVM_ALL_ON)
        `uvm_field_int(tx_data,    UVM_ALL_ON)
        `uvm_field_int(ack_req,    UVM_ALL_ON)
        `uvm_field_int(tx_done,    UVM_ALL_ON)
        `uvm_field_int(tx_no_ack,  UVM_ALL_ON)
        `uvm_field_int(arb_lost,   UVM_ALL_ON)
        `uvm_field_int(tx_error,   UVM_ALL_ON)
        `uvm_field_int(act_crc, UVM_ALL_ON)
        `uvm_field_int(crc_check_en, UVM_ALL_ON)
    `uvm_object_utils_end

    // Stimulus fields
    rand logic [10:0] tx_id;
    rand logic [3:0]  tx_dlc;
    rand logic [63:0] tx_data;
    rand logic        ack_req;
    logic [14:0]        act_crc;
    bit crc_check_en;

    // Response / observed fields
    logic tx_done;
    logic tx_no_ack;
    logic arb_lost;
    logic tx_error;

    // Constraints
    constraint id_range_c {tx_id inside {[11'h000 : 11'h7FF]};}
    constraint dlc_range_c { tx_dlc inside {[0:8]}; }
    constraint data_valid_c {
      if (tx_dlc == 0)
        tx_data[63:0]  == 64'h0;
    else if (tx_dlc == 1)
        tx_data[55:0]  == 56'h0;   // active: [63:56]  → 1 byte
    else if (tx_dlc == 2)
        tx_data[47:0]  == 48'h0;   // active: [63:48]  → 2 bytes
    else if (tx_dlc == 3)
        tx_data[39:0]  == 40'h0;   // active: [63:40]  → 3 bytes
    else if (tx_dlc == 4)
        tx_data[31:0]  == 32'h0;   // active: [63:32]  → 4 bytes
    else if (tx_dlc == 5)
        tx_data[23:0]  == 24'h0;   // active: [63:40]  → 5 bytes
    else if (tx_dlc == 6)
        tx_data[15:0]  == 16'h0;   // active: [63:48]  → 6 bytes
    else if (tx_dlc == 7)
        tx_data[7:0]   == 8'h0;    // active: [63:56]  → 7 bytes
    // rand_dlc == 8 → all 64 bits active, no restriction
}

    function new(string name = "can_seq_item");
        super.new(name);
    endfunction

endclass
