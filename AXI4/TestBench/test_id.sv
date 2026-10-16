class test_id extends uvm_test;

  `uvm_component_utils(test_id)

  axi_env env;

  function new(string name = "test_id", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction

  task run_phase(uvm_phase phase);

    seq_id id_seq;
    virtual axi_if vif;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found in test_id")
    end

    wait(vif.rst_n == 1'b1);
    repeat (5) @(posedge vif.clk);

    `uvm_info("TEST_ID", "==================================================", UVM_LOW)
    `uvm_info("TEST_ID", "STARTING ID TRACKING TEST CASES", UVM_LOW)
    `uvm_info("TEST_ID", "==================================================", UVM_LOW)

    id_seq = seq_id::type_id::create("id_seq");
    id_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ID", "==================================================", UVM_LOW)
    `uvm_info("TEST_ID", "COMPLETED ID TRACKING TEST CASES", UVM_LOW)
    `uvm_info("TEST_ID", "==================================================", UVM_LOW)

    #1500;

    phase.drop_objection(this);

  endtask

endclass
