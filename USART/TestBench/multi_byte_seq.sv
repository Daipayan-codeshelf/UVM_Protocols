class multi_byte_seq extends apb_base_seq;

   `uvm_object_utils(multi_byte_seq)

   function new(string name="multi_byte_seq");
      super.new(name);
   endfunction

   task body();

      write_reg(
         8'h00,
         32'h00000006
      );

      write_reg(
         8'h04,
         32'h00000036
      );

      send_byte(8'h11);
      send_byte(8'h22);
      send_byte(8'h33);
      send_byte(8'h44);
      send_byte(8'h55);
 $display("[%0t] INFO: Multibyte ends here", $time);
   endtask

   task send_byte(bit [7:0] data);

      write_reg(
         8'h08,
         data
      );
     
    

   endtask

endclass
