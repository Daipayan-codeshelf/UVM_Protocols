class reset_test extends uvm_test;

   `uvm_component_utils(reset_test)

   usart_env env;
   virtual usart_if vif;

   function new(
      string name="reset_test",
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
            this,"","vif",vif))
         `uvm_fatal(
            "NOVIF",
            "No interface"
         );

   endfunction

   task run_phase(
      uvm_phase phase
   );

      basic_seq       cfg_seq;
      reset_check_seq chk_seq;

      phase.raise_objection(this);

      //--------------------------------
      // Configure DUT
      //--------------------------------

      cfg_seq =
      basic_seq::type_id::create(
         "cfg_seq"
      );

      cfg_seq.start(
         env.apb_agt.seqr
      );

      //--------------------------------
      // Mid-test reset
      //--------------------------------

      vif.presetn <= 0;

      repeat(5)
         @(posedge vif.pclk);

      vif.presetn <= 1;

      repeat(5)
         @(posedge vif.pclk);

      //--------------------------------
      // Verify reset values
      //--------------------------------

      chk_seq =
      reset_check_seq::type_id::create(
         "chk_seq"
      );

      chk_seq.start(
         env.apb_agt.seqr
      );

      phase.drop_objection(this);

   endtask

endclass
