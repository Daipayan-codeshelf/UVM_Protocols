class apb_monitor extends uvm_monitor;

   `uvm_component_utils(apb_monitor)

   virtual usart_if vif;

   function new(string name,
                uvm_component parent);

      super.new(name,parent);

   endfunction

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      if(!uvm_config_db#
         (virtual usart_if)::get(
            this,
            "",
            "vif",
            vif))
      begin
         `uvm_fatal(
            "NOVIF",
            "Virtual interface not found"
         );
      end

   endfunction

   task run_phase(uvm_phase phase);

      forever begin

         @(posedge vif.pclk);

         if(vif.psel &&
            vif.penable &&
            vif.pwrite)
         begin

            `uvm_info(
               "MON",
               $sformatf(
                  "WRITE ADDR=%h DATA=%h",
                  vif.paddr,
                  vif.pwdata
               ),
               UVM_MEDIUM
            );

         end

      end

   endtask

endclass
