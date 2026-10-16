class test_error extends uvm_test;

  `uvm_component_utils(test_error)

  axi_env env;

  function new(string name = "test_error", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction

  task run_phase(uvm_phase phase);

    seq_error error_seq;
    virtual axi_if vif;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found in test_error")
    end

    wait(vif.rst_n == 1'b1);
    repeat (5) @(posedge vif.clk);

    `uvm_info("TEST_ERROR", "==================================================", UVM_LOW)
    `uvm_info("TEST_ERROR", "STARTING ERROR TEST CASES: SLVERR + DECERR", UVM_LOW)
    `uvm_info("TEST_ERROR", "==================================================", UVM_LOW)

    error_seq = seq_error::type_id::create("error_seq");
    error_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ERROR", "==================================================", UVM_LOW)
    `uvm_info("TEST_ERROR", "COMPLETED ERROR TEST CASES", UVM_LOW)
    `uvm_info("TEST_ERROR", "==================================================", UVM_LOW)

    #2000;

    phase.drop_objection(this);

  endtask

endclass
