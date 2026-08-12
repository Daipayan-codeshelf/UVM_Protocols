class parity_odd_test extends uvm_test;

   `uvm_component_utils(parity_odd_test)

   usart_env env;
   virtual usart_if vif;

   function new(
      string name="parity_odd_test",
      uvm_component parent=null
   );
      super.new(name,parent);
   endfunction

   function void build_phase(
      uvm_phase phase
   );

      super.build_phase(phase);

      env =
      usart_env::type_id::create(
         "env",
         this
      );

      if(!uvm_config_db#
         (virtual usart_if)::get(
            this,
            "",
            "vif",
            vif
         ))
      begin
         `uvm_fatal(
            "NOVIF",
            "No interface"
         );
      end

   endfunction

   task run_phase(
      uvm_phase phase
   );

      parity_odd_seq seq;

      phase.raise_objection(this);

      wait(vif.presetn == 1);

      repeat(2)
         @(posedge vif.pclk);

      seq =
      parity_odd_seq::type_id::create(
         "seq"
      );

      seq.start(
         env.apb_agt.seqr
      );

      #5000000;

      phase.drop_objection(this);

   endtask

endclass
