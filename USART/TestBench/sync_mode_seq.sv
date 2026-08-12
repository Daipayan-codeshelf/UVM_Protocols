class sync_mode_seq extends apb_base_seq;

   `uvm_object_utils(sync_mode_seq)

   function new(string name="sync_mode_seq");
      super.new(name);
   endfunction

   task body();

      `uvm_info(
         "SYNC",
         "Testing synchronous mode",
         UVM_LOW
      );

      //--------------------------------
      // Sync Mode Config
      //--------------------------------

      write_reg(
         8'h00,
         32'h00000007
      );

      write_reg(
         8'h04,
         32'h00000036
      );

      //--------------------------------
      // Pattern 1
      //--------------------------------

      write_reg(
         8'h08,
         32'h00000055
      );

      #500000;

      //--------------------------------
      // Pattern 2
      //--------------------------------

      write_reg(
         8'h08,
         32'h000000AA
      );

      #500000;

      //--------------------------------
      // Pattern 3
      //--------------------------------

      write_reg(
         8'h08,
         32'h000000F0
      );

      #500000;
     
     

     
     
     
     //////////////////////////////////////////////////////
    //               Sync mode ends here                //
    //////////////////////////////////////////////////////

    $display("Sync mode ends here");

     

   endtask

endclass
