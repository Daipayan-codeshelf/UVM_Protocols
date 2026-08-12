class parity_even_seq extends apb_base_seq;

   `uvm_object_utils(parity_even_seq)

   function new(string name="parity_even_seq");
      super.new(name);
   endfunction

   task body();

      `uvm_info(
         "PARITY",
         "Testing EVEN parity",
         UVM_LOW
      );

      //--------------------------------
      // EVEN PARITY CONFIG
      //--------------------------------

      write_reg(
         8'h00,
         32'h0000000E
      );

      write_reg(
         8'h04,
         32'h00000036
      );

      //--------------------------------
      // Test Patterns
      //--------------------------------

      write_reg(
         8'h08,
         32'h00000055
      );

      #500000;

      write_reg(
         8'h08,
         32'h000000AA
      );

      #500000;

      write_reg(
         8'h08,
         32'h000000F0
      );

      #500000;


     $display("Parity even ends here");


   endtask

endclass
