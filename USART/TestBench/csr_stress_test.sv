`ifndef CSR_STRESS_TEST_SV
`define CSR_STRESS_TEST_SV

class csr_stress_test extends uvm_test;

   `uvm_component_utils(csr_stress_test)

   usart_env env;
   virtual usart_if vif;

   function new(
      string name="csr_stress_test",
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
            "No interface found"
         );
      end

   endfunction

   task run_phase(
      uvm_phase phase
   );

      csr_stress_seq seq;

      phase.raise_objection(this);

      wait(vif.presetn);

      repeat(2)
         @(posedge vif.pclk);

      seq =
      csr_stress_seq::type_id::create(
         "seq"
      );

      seq.start(
         env.apb_agt.seqr
      );

      #5000000;

      phase.drop_objection(this);

   endtask

endclass

`endif
