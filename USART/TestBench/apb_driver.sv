class apb_driver extends
      uvm_driver #(apb_seq_item);

   `uvm_component_utils(apb_driver)

   virtual usart_if vif;

   function new(string name,
                uvm_component parent);

      super.new(name,parent);

   endfunction

   function void build_phase(
      uvm_phase phase);

      super.build_phase(phase);

      if(!uvm_config_db#
         (virtual usart_if)::get(
         this,"","vif",vif))
      begin
         `uvm_fatal("NOVIF",
         "Interface not found")
      end

   endfunction

   task run_phase(uvm_phase phase);

      apb_seq_item tr;

      forever begin

         seq_item_port.get_next_item(tr);

      @(negedge vif.pclk);
      vif.psel   <= 1;
      vif.pwrite <= tr.pwrite;
      vif.paddr  <= tr.paddr;
      vif.pwdata <= tr.pwdata;

      @(negedge vif.pclk);
      vif.penable <= 1;

      @(negedge vif.pclk);

      vif.psel    <= 0;
      vif.penable <= 0;
      vif.pwrite  <= 0;
      vif.paddr   <= 0;
      vif.pwdata  <= 0;

         `uvm_info("DRV",
            $sformatf(
            "WRITE ADDR=%h DATA=%h",
            tr.paddr,
            tr.pwdata),
            UVM_MEDIUM)

         seq_item_port.item_done();

      end

   endtask

endclass
