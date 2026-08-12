class fifo_underflow_test extends
      uvm_test;

   `uvm_component_utils(
      fifo_underflow_test
   )

   usart_env env;
 virtual usart_if vif;  

   function new(
      string name =
      "fifo_underflow_test",
      uvm_component parent = null
   );

      super.new(
         name,
         parent
      );

   endfunction

   function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = usart_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual usart_if)::get(this,"","vif",vif))
            `uvm_fatal("NOVIF","No interface")
    endfunction

   task run_phase(uvm_phase phase);
    fifo_underflow_seq seq;
    phase.raise_objection(this);

    wait(vif.presetn === 1'b1);         // ← wait for reset release
    repeat(5) @(posedge vif.pclk);      // ← settle cycles

    seq = fifo_underflow_seq::type_id::create("seq");
    seq.start(env.apb_agt.seqr);
    repeat(10) @(posedge vif.pclk);
    phase.drop_objection(this);
endtask

endclass
