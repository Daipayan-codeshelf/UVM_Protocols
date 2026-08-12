class fifo_underflow_seq extends
      apb_base_seq;

   `uvm_object_utils(fifo_underflow_seq)

   function new(
      string name="fifo_underflow_seq"
   );
      super.new(name);
   endfunction

   //--------------------------------
   // APB WRITE
   //--------------------------------

   

   //--------------------------------
   // TEST BODY
   //--------------------------------

   task body();
    bit [31:0] rd;

    write_reg(8'h00, 32'h00000006);   // CTRL
    write_reg(8'h04, 32'h00000036);   // BAUD
    
     
     
     
     
    // Read RXDATA while FIFO empty → triggers underflow
    read_reg(8'h0C, rd);
    `uvm_info("UDF", "Read RXDATA while empty", UVM_LOW)

    // Read STATUS immediately after (no delay needed)
    read_reg(8'h10, rd);
    `uvm_info("UDF", $sformatf("STATUS=%08h", rd), UVM_LOW)

    if (rd[10])
        `uvm_info("UDF",  "RX FIFO UNDERFLOW PASS", UVM_LOW)
    else
        `uvm_error("UDF", "RX FIFO UNDERFLOW FLAG NOT SET")
      
      
      $display("[%0t] INFO: Underflow_seq ends here", $time);
endtask

endclass
