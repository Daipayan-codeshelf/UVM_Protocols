class apb_monitor extends uvm_monitor;

   `uvm_component_utils(apb_monitor)

   virtual usart_if vif;
   uvm_analysis_port #(apb_seq_item) ap;

   function new(string name,
                uvm_component parent);

      super.new(name,parent);
      ap = new("ap", this);

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

      if(vif.psel && vif.penable)
      begin

         apb_seq_item tr;

         tr = apb_seq_item::type_id::create("tr");

         tr.pwrite = vif.pwrite;
         tr.paddr  = vif.paddr;

         if(vif.pwrite)
         begin

            tr.pwdata = vif.pwdata;

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
         else
         begin

            tr.prdata = vif.prdata;

            `uvm_info(
               "MON",
               $sformatf(
                  "READ ADDR=%h DATA=%h",
                  vif.paddr,
                  vif.prdata
               ),
               UVM_MEDIUM
            );

         end

         ap.write(tr);

      end

   end

endtask
endclass
