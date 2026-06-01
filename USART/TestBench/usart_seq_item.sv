class usart_seq_item extends uvm_sequence_item;

   bit [7:0] rx_data;

   `uvm_object_utils_begin(usart_seq_item)
      `uvm_field_int(rx_data,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="usart_seq_item");
      super.new(name);
   endfunction

endclass
