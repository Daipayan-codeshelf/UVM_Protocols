class csr_stress_seq extends apb_base_seq;

   `uvm_object_utils(csr_stress_seq)

   function new(string name="csr_stress_seq");
      super.new(name);
   endfunction

   task body();

      bit [31:0] rdata;
      bit [7:0] addr;

      //-------------------------------
      // CTRL register variations
      //-------------------------------

      write_reg(8'h00, 32'h00);
      read_reg (8'h00, rdata);

      write_reg(8'h00, 32'h01);
      read_reg (8'h00, rdata);

      write_reg(8'h00, 32'h09);
      read_reg (8'h00, rdata);

      write_reg(8'h00, 32'h19);
      read_reg (8'h00, rdata);

      write_reg(8'h00, 32'h61);
      read_reg (8'h00, rdata);

      write_reg(8'h00, 32'h7F);
      read_reg (8'h00, rdata);

      //-------------------------------
      // BAUD register
      //-------------------------------

      write_reg(8'h04, 32'd1);
      read_reg (8'h04, rdata);

      write_reg(8'h04, 32'd16);
      read_reg (8'h04, rdata);

      write_reg(8'h04, 32'd255);
      read_reg (8'h04, rdata);

      write_reg(8'h04, 32'hFFFF);
      read_reg (8'h04, rdata);

      //-------------------------------
      // TXDATA register
      //-------------------------------

      write_reg(8'h08, 32'h55);
      write_reg(8'h08, 32'hAA);
      write_reg(8'h08, 32'h00);
      write_reg(8'h08, 32'hFF);

      //-------------------------------
      // Read all readable registers
      //-------------------------------

      read_reg(8'h00, rdata);
      read_reg(8'h04, rdata);
      read_reg(8'h08, rdata);
      read_reg(8'h0C, rdata);
      read_reg(8'h10, rdata);

      //-------------------------------
      // Hit default read case
      //-------------------------------

      read_reg(8'h14, rdata);
      read_reg(8'h18, rdata);

      //-------------------------------
      // Hit write paths with invalid
      //-------------------------------

      write_reg(8'h0C, 32'h12345678);
      write_reg(8'h10, 32'h87654321);

      //-------------------------------
      // Random APB activity
      //-------------------------------

      repeat (50) begin

         case($urandom_range(0,4))
            0: addr = 8'h00;
            1: addr = 8'h04;
            2: addr = 8'h08;
            3: addr = 8'h0C;
            4: addr = 8'h10;
         endcase

         if($urandom_range(0,1))
            write_reg(addr, $urandom);
         else
            read_reg(addr, rdata);

      end
     
     $display("[%0t] INFO: Csr stress here", $time);

   endtask

endclass
