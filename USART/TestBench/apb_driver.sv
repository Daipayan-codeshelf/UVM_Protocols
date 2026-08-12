class apb_driver extends uvm_driver #(apb_seq_item);

   `uvm_component_utils(apb_driver)

   virtual usart_if vif;

   function new(string name, uvm_component parent);

      super.new(name, parent);

   endfunction

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      if (!uvm_config_db #(virtual usart_if)::get(this, "", "vif", vif))
       begin
         `uvm_fatal("NOVIF", "Interface not found")
       end

   endfunction

   task run_phase(uvm_phase phase);

      apb_seq_item tr;

      forever begin

         seq_item_port.get_next_item(tr);

         if (tr.pwrite)
            do_write(tr.paddr, tr.pwdata);
         else
            do_read(tr.paddr, tr.prdata);

         `uvm_info("DRV",
                   $sformatf("%s ADDR=%0h %s=%0h",
                             tr.pwrite ? "WRITE" : "READ ",
                             tr.paddr,
                             tr.pwrite ? "WDATA" : "RDATA",
                             tr.pwrite ? tr.pwdata : tr.prdata),
                   UVM_MEDIUM)

         seq_item_port.item_done();

      end

   endtask

   //////////////////////////////////////
   // APB Write
   //////////////////////////////////////

   task do_write(input [7:0] addr, input [31:0] data);

      @(negedge vif.pclk);
      vif.psel    = 1;
      vif.pwrite  = 1;
      vif.penable = 0;
      vif.paddr   = addr;
      vif.pwdata  = data;

      @(negedge vif.pclk);
      vif.penable = 1;

      @(posedge vif.pclk); // RTL captures write here

      @(negedge vif.pclk);
      vif.psel    = 0;
      vif.penable = 0;
      vif.pwrite  = 0;

   endtask

   //////////////////////////////////////
   // APB Read
   //////////////////////////////////////

   task do_read(input [7:0] addr, output [31:0] data);

      @(negedge vif.pclk);
      vif.psel    = 1;
      vif.pwrite  = 0;
      vif.penable = 0;
      vif.paddr   = addr;

      @(negedge vif.pclk);
      vif.penable = 1;

      #1;
      data = vif.prdata; // before posedge where clear fires

      @(posedge vif.pclk); // RTL processes read + clear here

      @(negedge vif.pclk);
      vif.psel    = 0;
      vif.penable = 0;

   endtask

endclass
