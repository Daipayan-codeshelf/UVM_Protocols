class fifo_overflow_seq extends
      apb_base_seq;
   `uvm_object_utils(fifo_overflow_seq)

   function new(
      string name="fifo_overflow_seq"
   );
      super.new(name);
   endfunction
  
  

   task body();

      apb_seq_item tr;
      int i;
      bit [31:0] rd;

      //--------------------------------
      // CTRL
      //--------------------------------

      tr = apb_seq_item::type_id::create("tr");

      start_item(tr);
      tr.pwrite = 1;
      tr.paddr  = 8'h00;
      tr.pwdata = 32'h00000006;
      finish_item(tr);

      //--------------------------------
      // BAUD
      //--------------------------------

      tr = apb_seq_item::type_id::create("tr");

      start_item(tr);
      tr.pwrite = 1;
      tr.paddr  = 8'h04;
      tr.pwdata = 32'h0000FFFF;   // very slow TX
      finish_item(tr);

      //--------------------------------
      // Fill FIFO
      //--------------------------------

      for(int i=0;i<20;i++) begin

         tr = apb_seq_item::type_id::create("tr");

         start_item(tr);

         tr.pwrite = 1;
         tr.paddr  = 8'h08;
         tr.pwdata = i;

         finish_item(tr);

      end

      //----------------------------------
      // READ STATUS REGISTER
      //----------------------------------

      #10000;

read_reg(8'h10, rd);

`uvm_info("OVF",
          $sformatf("STATUS=%08h", rd),
          UVM_LOW)

   if(rd[5])
   `uvm_info(
      "OVF",
      "OVERFLOW PASS",
      UVM_LOW
   )
else
   `uvm_error(
      "OVF",
      "OVERFLOW FLAG NOT SET"
   );
     
     $display("[%0t] INFO: Overflow_seq ends here", $time);

   endtask
 
endclass
