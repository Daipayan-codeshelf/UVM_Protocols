class usart_monitor extends uvm_monitor;

   `uvm_component_utils(usart_monitor)

   virtual usart_if vif;
   uvm_analysis_port #(usart_seq_item) ap;

   function new(string name,uvm_component parent);
      super.new(name,parent);
      ap = new("ap", this);
   endfunction

   function void build_phase(uvm_phase phase);

     if(!uvm_config_db# (virtual usart_if)::get(this,"","vif",vif))
      begin
         `uvm_fatal("NOVIF","No interface");
      end

   endfunction

   task run_phase(uvm_phase phase);

      forever begin

        @(posedge vif.pclk);

        if(vif.rx_valid_mon)
          begin
            usart_seq_item tr;
            tr = usart_seq_item::type_id::create("tr");
            tr.rx_data = vif.rx_data_mon;
            ap.write(tr);
            `uvm_info("USART_MON",$sformatf("RX DATA=%h",vif.rx_data_mon),UVM_MEDIUM);

          end

      end

   endtask

endclass
