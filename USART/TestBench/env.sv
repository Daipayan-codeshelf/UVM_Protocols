class usart_env extends uvm_env;

   `uvm_component_utils(usart_env)

   apb_agent   apb_agt;
   usart_agent usart_agt;

   function new(string name,
                uvm_component parent);

      super.new(name,parent);

   endfunction

   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      apb_agt =
      apb_agent::type_id::create(
         "apb_agt",
         this
      );

      usart_agt =
      usart_agent::type_id::create(
         "usart_agt",
         this
      );

   endfunction

endclass
