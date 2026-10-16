class test_fifo_stress extends uvm_test;

  `uvm_component_utils(test_fifo_stress)

  axi_env env;

  function new(string name = "test_fifo_stress", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction

  task run_phase(uvm_phase phase);

    seq_fifo_stress fifo_stress_seq;
    virtual axi_if vif;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found in test_fifo_stress")
    end

    // Wait for reset release
    wait(vif.rst_n == 1'b1);
    repeat (5) @(posedge vif.clk);

    `uvm_info("TEST_FIFO_STRESS", "==================================================", UVM_LOW)
    `uvm_info("TEST_FIFO_STRESS", "STARTING FIFO / STRESS TEST CASES", UVM_LOW)
    `uvm_info("TEST_FIFO_STRESS", "==================================================", UVM_LOW)

    fifo_stress_seq = seq_fifo_stress::type_id::create("fifo_stress_seq");
    fifo_stress_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_FIFO_STRESS", "==================================================", UVM_LOW)
    `uvm_info("TEST_FIFO_STRESS", "COMPLETED FIFO / STRESS TEST CASES", UVM_LOW)
    `uvm_info("TEST_FIFO_STRESS", "==================================================", UVM_LOW)

    #2500;

    phase.drop_objection(this);

  endtask

endclass
