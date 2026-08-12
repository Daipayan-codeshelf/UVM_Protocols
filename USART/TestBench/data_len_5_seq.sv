class data_len_5_seq extends apb_base_seq;

   `uvm_object_utils(data_len_5_seq)

   function new(string name="data_len_5_seq");
      super.new(name);
   endfunction

   task body();

      // CTRL
      // mode=0
      // data_len=00 (5-bit)
      // parity=0
      // stop=1

      write_reg(
         8'h00,
         32'h00000000
      );

      write_reg(
         8'h04,
         32'h00000036
      );

      write_reg(
         8'h08,
         32'h0000001F
      );

      #500000;
     
     $display("[%0t] INFO: Data len 5 ends here", $time);

   endtask

endclass
