class random_cfg_seq extends apb_base_seq;

   `uvm_object_utils(random_cfg_seq)

   rand bit       mode;
   rand bit [1:0] data_len;
   rand bit       parity_en;
   rand bit       parity_type;

   function new(string name="random_cfg_seq");
      super.new(name);
   endfunction

   task body();

      bit [31:0] ctrl;
      bit [7:0]  tx_data;

      //--------------------------------
      // Random configurations
      //--------------------------------

      repeat(20)
      begin

         assert(randomize());

         //--------------------------------
         // Build CTRL register
         //--------------------------------

         ctrl = 0;

         ctrl[0]   = mode;
         ctrl[2:1] = data_len;
         ctrl[3]   = parity_en;
         ctrl[4]   = parity_type;

         //--------------------------------
         // Random TX Data
         //--------------------------------

         tx_data = $urandom_range(0,255);

         //--------------------------------
         // Program DUT
         //--------------------------------

         write_reg(
            8'h00,
            ctrl
         );

         write_reg(
            8'h04,
            32'h00000036
         );

         write_reg(
            8'h08,
            tx_data
         );

         `uvm_info(
            "RANDCFG",
            $sformatf(
               "MODE=%0d DLEN=%0d PEN=%0d PTYPE=%0d DATA=%02h",
               mode,
               data_len,
               parity_en,
               parity_type,
               tx_data
            ),
            UVM_LOW
         );

         #1000000;

      end

      //--------------------------------
      // Force coverage bin : DATA = 00
      //--------------------------------

      write_reg(
         8'h08,
         32'h00000000
      );

      #1000000;

      //--------------------------------
      // Force coverage bin : DATA = FF
      //--------------------------------

      write_reg(
         8'h08,
         32'h000000FF
      );

      #1000000;
     $display("[%0t] INFO: Random_seq ends here", $time);

   endtask

endclass
