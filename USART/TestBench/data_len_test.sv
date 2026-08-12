class data_len_test extends uvm_test;

   `uvm_component_utils(data_len_test)

   usart_env env;
   virtual usart_if vif;

   function new(
      string name="data_len_test",
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

      if(!uvm_config_db#(virtual usart_if)::get(
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

      data_len_seq seq;

      phase.raise_objection(this);

      //--------------------------------
      // Wait for reset release
      //--------------------------------

      wait(vif.presetn == 1);

      repeat(2)
         @(posedge vif.pclk);

      //--------------------------------
      // Start sequence
      //--------------------------------

      seq =
      data_len_seq::type_id::create(
         "seq"
      );

      seq.start(
         env.apb_agt.seqr
      );

      //--------------------------------
      // Allow all 4 configurations
      // to complete
      //--------------------------------

      #500000;

      phase.drop_objection(this);

   endtask

endclass
