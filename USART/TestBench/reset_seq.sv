class reset_check_seq extends apb_base_seq;

   `uvm_object_utils(reset_check_seq)

   function new(string name="reset_check_seq");
      super.new(name);
   endfunction

   task body();

   bit [31:0] rd;
   bit fail;

   fail = 0;

   //--------------------------------
   // CTRL should be 0
   //--------------------------------

   read_reg(8'h00, rd);

   if(rd != 32'h0) begin
      fail = 1;
      `uvm_error(
         "RSTCHK",
         $sformatf(
            "CTRL not reset exp=0 got=%08h",
            rd
         )
      );
   end

   //--------------------------------
   // BAUD should be 0
   //--------------------------------

   read_reg(8'h04, rd);

   if(rd != 32'h0) begin
      fail = 1;
      `uvm_error(
         "RSTCHK",
         $sformatf(
            "BAUD not reset exp=0 got=%08h",
            rd
         )
      );
   end

   //--------------------------------
   // STATUS sticky bits should be 0
   //--------------------------------

   read_reg(8'h10, rd);

   // Check only sticky/error bits:
   // [10:9] RX ovf/udf
   // [6:5]  TX ovf/udf
   // [2:0]  parity/frame/overrun

   if(rd & 32'h00000667) begin
      fail = 1;
      `uvm_error(
         "RSTCHK",
         $sformatf(
            "STATUS sticky bits not reset. STATUS=%08h",
            rd
         )
      );
   end

   //--------------------------------
   // Final Result
   //--------------------------------

   if(!fail)
      `uvm_info(
         "RSTCHK",
         $sformatf(
            "RESET CHECK PASS (STATUS=%08h)",
            rd
         ),
         UVM_LOW
      );

endtask
endclass
