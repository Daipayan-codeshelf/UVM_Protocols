class basic_seq extends uvm_sequence #(apb_seq_item);

   `uvm_object_utils(basic_seq)

   function new(string name="basic_seq");
      super.new(name);
   endfunction

   task body();

      apb_seq_item tr;

      // CTRL Write
      tr = apb_seq_item::type_id::create("tr");
      start_item(tr);
      tr.pwrite = 1;
      tr.paddr  = 8'h00;
      tr.pwdata = 32'h00000006;
      finish_item(tr);

      // BAUD Write
      tr = apb_seq_item::type_id::create("tr");
      start_item(tr);
      tr.pwrite = 1;
      tr.paddr  = 8'h04;
      tr.pwdata = 32'h00000036;
      finish_item(tr);

      // TXDATA Write
      tr = apb_seq_item::type_id::create("tr");
      start_item(tr);
      tr.pwrite = 1;
      tr.paddr  = 8'h08;
      tr.pwdata = 32'h000000A5;
      finish_item(tr);

   endtask

endclass
