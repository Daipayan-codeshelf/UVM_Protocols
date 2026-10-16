class test_wstrb extends uvm_test;

  `uvm_component_utils(test_wstrb)

  axi_env env;

  function new(string name = "test_wstrb", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction

  task run_phase(uvm_phase phase);

    seq_wstrb wstrb_seq;
    virtual axi_if vif;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found in test_wstrb")
    end

    wait(vif.rst_n == 1'b1);
    repeat (5) @(posedge vif.clk);

    `uvm_info("TEST_WSTRB", "==================================================", UVM_LOW)
    `uvm_info("TEST_WSTRB", "STARTING WSTRB TEST CASES", UVM_LOW)
    `uvm_info("TEST_WSTRB", "==================================================", UVM_LOW)

    wstrb_seq = seq_wstrb::type_id::create("wstrb_seq");
    wstrb_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_WSTRB", "==================================================", UVM_LOW)
    `uvm_info("TEST_WSTRB", "COMPLETED WSTRB TEST CASES", UVM_LOW)
    `uvm_info("TEST_WSTRB", "==================================================", UVM_LOW)

    #1500;

    phase.drop_objection(this);

  endtask

endclass
