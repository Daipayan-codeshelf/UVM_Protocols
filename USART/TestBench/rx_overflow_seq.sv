class rx_overflow_seq extends apb_base_seq;

   `uvm_object_utils(rx_overflow_seq)

   function new(
      string name="rx_overflow_seq"
   );
      super.new(name);
   endfunction

   task body();

      bit [31:0] rd;

      //--------------------------------
      // Configure UART
      //--------------------------------

      write_reg(
         8'h00,
         32'h00000006
      );

      //--------------------------------
      // Fast baud
      //--------------------------------

      write_reg(
         8'h04,
         32'h00000001
      );

      //--------------------------------
      // Send > RX FIFO depth
      //--------------------------------

      for(int i=0;i<25;i++)
      begin

         write_reg(
            8'h08,
            i
         );

      end

      //--------------------------------
      // Wait for RX FIFO to fill
      //--------------------------------

      #500000;

      //--------------------------------
      // Read STATUS
      //--------------------------------

      read_reg(
         8'h10,
         rd
      );

      `uvm_info(
         "RX_OVF",
         $sformatf(
            "STATUS = %08h",
            rd
         ),
         UVM_LOW
      )

      //--------------------------------
      // Check RX FIFO Overflow Bit
      //--------------------------------

      if(rd[9])
      begin

         `uvm_info(
            "RX_OVF",
            "RX FIFO OVERFLOW PASS",
            UVM_LOW
         )

      end
      else
      begin

         `uvm_error(
            "RX_OVF",
            "RX FIFO OVERFLOW FLAG NOT SET"
         )

      end

   endtask

endclass
