class apb_seq_item extends uvm_sequence_item;

   rand bit        pwrite;
   rand bit [7:0]  paddr;
   rand bit [31:0] pwdata;

   `uvm_object_utils_begin(apb_seq_item)
      `uvm_field_int(pwrite,UVM_ALL_ON)
      `uvm_field_int(paddr ,UVM_ALL_ON)
      `uvm_field_int(pwdata,UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name="apb_seq_item");
      super.new(name);
   endfunction

endclass
