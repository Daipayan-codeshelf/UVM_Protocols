class usart_env extends uvm_env;

   `uvm_component_utils(usart_env)
  
   apb_agent         apb_agt;
   usart_agent       usart_agt;
   usart_scoreboard  sb;
   usart_coverage cov;

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
     
     sb =usart_scoreboard::type_id::create("sb",this);
     cov =usart_coverage::type_id::create("cov",this);

   endfunction
  
  
   function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);

     apb_agt.mon.ap.connect(sb.apb_fifo.analysis_export);

     usart_agt.mon.ap.connect(sb.usart_fifo.analysis_export);
     
     apb_agt.mon.ap.connect(cov.analysis_export);

  endfunction

endclass
