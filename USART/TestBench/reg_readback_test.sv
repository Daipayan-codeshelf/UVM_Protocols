class reg_readback_test extends uvm_test;

   `uvm_component_utils(
      reg_readback_test
   )

   usart_env env;
   virtual usart_if vif;

   function new(
      string name="reg_readback_test",
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

      uvm_config_db#
      (virtual usart_if)::get(
         this,
         "",
         "vif",
         vif
      );

   endfunction

   task run_phase(
      uvm_phase phase
   );

      reg_readback_seq seq;

      phase.raise_objection(this);

      wait(vif.presetn);

      seq =
      reg_readback_seq::type_id::create(
         "seq"
      );

      seq.start(
         env.apb_agt.seqr
      );

      phase.drop_objection(this);
     
   

   endtask

endclass
