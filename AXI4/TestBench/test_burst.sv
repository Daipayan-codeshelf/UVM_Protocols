class test_burst extends uvm_test;

  `uvm_component_utils(test_burst)

  axi_env env;

  function new(string name = "test_burst", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction

  task run_phase(uvm_phase phase);

    seq_burst burst_seq;
    virtual axi_if vif;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found in test_burst")
    end

    wait(vif.rst_n == 1'b1);
    repeat (5) @(posedge vif.clk);

    `uvm_info("TEST_BURST", "==================================================", UVM_LOW)
    `uvm_info("TEST_BURST", "STARTING BURST TEST CASES: INCR + FIXED + WRAP", UVM_LOW)
    `uvm_info("TEST_BURST", "==================================================", UVM_LOW)

    burst_seq = seq_burst::type_id::create("burst_seq");
    burst_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_BURST", "==================================================", UVM_LOW)
    `uvm_info("TEST_BURST", "COMPLETED BURST TEST CASES", UVM_LOW)
    `uvm_info("TEST_BURST", "==================================================", UVM_LOW)

    #2000;

    phase.drop_objection(this);

  endtask

endclass
