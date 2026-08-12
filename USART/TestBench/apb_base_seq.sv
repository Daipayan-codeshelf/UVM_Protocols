class apb_base_seq extends
      uvm_sequence #(apb_seq_item);

   `uvm_object_utils(apb_base_seq)

   function new(
      string name="apb_base_seq"
   );
      super.new(name);
   endfunction

   //--------------------------------
   // APB WRITE
   //--------------------------------

   task write_reg(
      input [7:0] addr,
      input [31:0] data
   );

      apb_seq_item tr;

      tr =
      apb_seq_item::type_id::create("tr");

      start_item(tr);

      tr.pwrite = 1'b1;
      tr.paddr  = addr;
      tr.pwdata = data;

      finish_item(tr);

   endtask

   //--------------------------------
   // APB READ
   //--------------------------------

   task read_reg(
      input  [7:0] addr,
      output [31:0] data
   );

      apb_seq_item tr;

      tr =
      apb_seq_item::type_id::create("tr");

      start_item(tr);

      tr.pwrite = 1'b0;
      tr.paddr  = addr;
      tr.pwdata = 32'd0;

      finish_item(tr);

      data = tr.prdata;

   endtask

endclass
