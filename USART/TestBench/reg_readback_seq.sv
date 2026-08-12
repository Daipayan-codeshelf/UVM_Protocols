class reg_readback_seq extends apb_base_seq;

   `uvm_object_utils(reg_readback_seq)

   function new(string name="reg_readback_seq");
      super.new(name);
   endfunction

   task body();

      bit [31:0] rd;

      //--------------------------------
      // CTRL Register
      //--------------------------------

      write_reg(
         8'h00,
         32'h00000006
      );

      read_reg(
         8'h00,
         rd
      );

      if(rd != 32'h00000006)
         `uvm_error(
            "REGCHK",
            $sformatf(
               "CTRL mismatch exp=%h got=%h",
               32'h00000006,
               rd
            )
         );

      //--------------------------------
      // BAUD Register
      //--------------------------------

      write_reg(
         8'h04,
         32'h00000036
      );

      read_reg(
         8'h04,
         rd
      );

      if(rd != 32'h00000036)
         `uvm_error(
            "REGCHK",
            $sformatf(
               "BAUD mismatch exp=%h got=%h",
               32'h00000036,
               rd
            )
         );

      //--------------------------------
      // Send one byte
      //--------------------------------

      write_reg(
         8'h08,
         32'h00000055
      );

      //--------------------------------
      // Wait for loopback RX
      //--------------------------------

      #85000;

      //--------------------------------
      // Read STATUS Register
      //--------------------------------

      read_reg(
         8'h10,
         rd
      );

      `uvm_info(
         "REGCHK",
         $sformatf(
            "STATUS = %h",
            rd
         ),
         UVM_LOW
      );

      //--------------------------------
      // Read RXDATA Register
      //--------------------------------

      read_reg(
         8'h0C,
         rd
      );

      `uvm_info(
         "REGCHK",
         $sformatf(
            "RXDATA = %h",
            rd
         ),
         UVM_LOW
      );

      //--------------------------------
      // Verify received data
      //--------------------------------

      if(rd[7:0] != 8'h55)
      begin

         `uvm_error(
            "REGCHK",
            $sformatf(
               "RXDATA mismatch exp=55 got=%h",
               rd[7:0]
            )
         );

      end
      else
      begin

         `uvm_info(
            "REGCHK",
            "RXDATA READBACK PASS",
            UVM_LOW
         );

      end

      //--------------------------------
      // Test Complete
      //--------------------------------

      `uvm_info(
         "REGCHK",
         "REGISTER READBACK PASS",
         UVM_LOW
      );
     
       $display("[%0t] INFO: Reg readback ends here", $time);

   endtask

endclass
