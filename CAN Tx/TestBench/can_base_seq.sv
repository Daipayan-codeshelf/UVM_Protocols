class can_base_seq extends uvm_sequence #(can_seq_item);
    `uvm_object_utils(can_base_seq)

    function new(string name = "can_base_seq");
        super.new(name);
    endfunction

    // Helper: build and send one item
    task send_frame(logic [10:0] id,
                    logic [3:0]  dlc,
                    logic [63:0] data,
                    logic        ack,
                     bit          crc_en = 0);
        can_seq_item item;
        item          = can_seq_item::type_id::create("item");
        item.tx_id    = id;
        item.tx_dlc   = dlc;
        item.tx_data  = data;
        item.ack_req  = ack;
        item.crc_check_en = crc_en;
        start_item(item);
        finish_item(item);
    endtask

endclass
