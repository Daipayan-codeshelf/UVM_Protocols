class basic_test extends uvm_test;

   `uvm_component_utils(basic_test)

   usart_env env;
   virtual usart_if vif; 

   function new(string name="basic_test",
                uvm_component parent=null);

      super.new(name,parent);

   endfunction

   function void build_phase(uvm_phase phase);

   super.build_phase(phase);

   env = usart_env::type_id::create(
      "env",
      this
   );

   if(!uvm_config_db#(virtual usart_if)::get(
      this,
      "",
      "vif",
      vif
   ))
      `uvm_fatal("NOVIF","No interface")

endfunction

   task run_phase(uvm_phase phase);

   basic_seq seq;

   phase.raise_objection(this);

   // WAIT FOR RESET RELEASE
   wait(vif.presetn == 1);

   repeat(2)
      @(posedge vif.pclk);

   seq = basic_seq::type_id::create("seq");

   seq.start(env.apb_agt.seqr);

   #1000ns;

   phase.drop_objection(this);

endtask

endclass
