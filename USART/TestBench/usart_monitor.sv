class usart_monitor extends uvm_monitor;

   `uvm_component_utils(usart_monitor)

   virtual usart_if vif;

   function new(string name,
                uvm_component parent);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);

      if(!uvm_config_db#
         (virtual usart_if)::get(
            this,"","vif",vif))
      begin
         `uvm_fatal("NOVIF","No interface");
      end

   endfunction

   task run_phase(uvm_phase phase);

      forever begin

         @(posedge vif.pclk);

         if(vif.rx_valid_mon)
         begin

            `uvm_info(
               "USART_MON",
               $sformatf(
                  "RX DATA=%h",
                  vif.rx_data_mon
               ),
               UVM_MEDIUM
            );

         end

      end

   endtask

endclass
