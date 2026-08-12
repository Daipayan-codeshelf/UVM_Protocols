class stop_bit_seq extends apb_base_seq;

   `uvm_object_utils(stop_bit_seq)

   function new(string name="stop_bit_seq");
      super.new(name);
   endfunction

   task body();

      //------------------------------------
      // MODE=0, STOP=1
      //------------------------------------
      `uvm_info("STOPBIT",
                "MODE=0 STOP=1",
                UVM_LOW)

      write_reg(8'h00, 32'h00000006);
      write_reg(8'h04, 32'h00000036);
      write_reg(8'h08, 32'h00000011);

      #500000;

      //------------------------------------
      // MODE=0, STOP=2
      //------------------------------------
      `uvm_info("STOPBIT",
                "MODE=0 STOP=2",
                UVM_LOW)

      write_reg(8'h00, 32'h00000026);
      write_reg(8'h08, 32'h00000022);

      #500000;

      //------------------------------------
      // MODE=1, STOP=1
      //------------------------------------
      `uvm_info("STOPBIT",
                "MODE=1 STOP=1",
                UVM_LOW)

      write_reg(8'h00, 32'h00000007);
      write_reg(8'h08, 32'h00000033);

      #500000;

      //------------------------------------
      // MODE=1, STOP=2
      //------------------------------------
      `uvm_info("STOPBIT",
                "MODE=1 STOP=2",
                UVM_LOW)

      write_reg(8'h00, 32'h00000027);
      write_reg(8'h08, 32'h00000044);

      #500000;

      `uvm_info("STOPBIT",
                "MODE/STOP CROSS TEST COMPLETE",
                UVM_LOW)
     
     
     $display("Stop bit ends here");


   endtask

endclass
