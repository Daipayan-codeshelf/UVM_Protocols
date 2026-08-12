class data_len_seq extends apb_base_seq;

   `uvm_object_utils(data_len_seq)

   function new(string name="data_len_seq");
      super.new(name);
   endfunction

   task body();

      //----------------------------------------
      // 5-BIT MODE
      //----------------------------------------
      `uvm_info("DATA_LEN",
         "Testing 5-bit mode",
         UVM_LOW)

      write_reg(
         8'h00,
         32'h00000000   // data_len = 00
      );

      write_reg(
         8'h04,
         32'h00000036
      );

      write_reg(
         8'h08,
         32'h0000001F   // max 5-bit value
      );

      #500000;

      //----------------------------------------
      // 6-BIT MODE
      //----------------------------------------
      `uvm_info("DATA_LEN",
         "Testing 6-bit mode",
         UVM_LOW)

      write_reg(
         8'h00,
         32'h00000002   // data_len = 01
      );

      write_reg(
         8'h08,
         32'h0000003F   // max 6-bit value
      );

      #500000;

      //----------------------------------------
      // 7-BIT MODE
      //----------------------------------------
      `uvm_info("DATA_LEN",
         "Testing 7-bit mode",
         UVM_LOW)

      write_reg(
         8'h00,
         32'h00000004   // data_len = 10
      );

      write_reg(
         8'h08,
         32'h0000007F   // max 7-bit value
      );

      #500000;

      //----------------------------------------
      // 8-BIT MODE
      //----------------------------------------
      `uvm_info("DATA_LEN",
         "Testing 8-bit mode",
         UVM_LOW)

      write_reg(
         8'h00,
         32'h00000006   // data_len = 11
      );

      write_reg(
         8'h08,
         32'h000000FF   // max 8-bit value
      );

      #500000;

      `uvm_info("DATA_LEN",
         "All data length tests completed",
         UVM_LOW)


     $display("[%0t] INFO: Data Len ends here", $time);

   endtask

endclass
