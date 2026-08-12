class parity_odd_seq extends apb_base_seq;

   `uvm_object_utils(parity_odd_seq)

   function new(string name="parity_odd_seq");
      super.new(name);
   endfunction

   task body();

      `uvm_info(
         "PARITY",
         "Testing ODD parity",
         UVM_LOW
      );

      //--------------------------------
      // ODD PARITY CONFIG
      //--------------------------------

      write_reg(
         8'h00,
         32'h0000001E
      );

      write_reg(
         8'h04,
         32'h00000036
      );

      //--------------------------------
      // Test Pattern 1
      //--------------------------------

      write_reg(
         8'h08,
         32'h00000055
      );

      #500000;

      //--------------------------------
      // Test Pattern 2
      //--------------------------------

      write_reg(
         8'h08,
         32'h000000AA
      );

      #500000;

      //--------------------------------
      // Test Pattern 3
      //--------------------------------

      write_reg(
         8'h08,
         32'h000000F0
      );

      #500000;


     $display("Parity odd ends here");

   endtask

endclass
