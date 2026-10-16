class test_all extends uvm_test;

  `uvm_component_utils(test_all)

  axi_env env;

  function new(string name = "test_all", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction

  task run_phase(uvm_phase phase);

    seq_burst       burst_seq;
    seq_error       error_seq;
    seq_slave       slave_seq;
    seq_protection  protection_seq;
    seq_wstrb       wstrb_seq;
    seq_fifo_stress fifo_stress_seq;
    seq_id          id_seq;

    virtual axi_if vif;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found in test_all")
    end

    wait(vif.rst_n == 1'b1);
    repeat (5) @(posedge vif.clk);

    // ============================================================
    // BURST TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING BURST TEST CASES: INCR + FIXED + WRAP", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    burst_seq = seq_burst::type_id::create("burst_seq");
    burst_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED BURST TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    repeat (10) @(posedge vif.clk);

    // ============================================================
    // ERROR TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING ERROR TEST CASES: SLVERR + DECERR", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    error_seq = seq_error::type_id::create("error_seq");
    error_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED ERROR TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    repeat (10) @(posedge vif.clk);

    // ============================================================
    // SLAVE ROUTING / ISOLATION TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING SLAVE ROUTING / ISOLATION TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    slave_seq = seq_slave::type_id::create("slave_seq");
    slave_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED SLAVE ROUTING / ISOLATION TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    repeat (10) @(posedge vif.clk);

    // ============================================================
    // AWPROT / PROTECTION TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING AWPROT / PROTECTION TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    protection_seq = seq_protection::type_id::create("protection_seq");
    protection_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED AWPROT / PROTECTION TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    repeat (10) @(posedge vif.clk);

    // ============================================================
    // WSTRB TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING WSTRB TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    wstrb_seq = seq_wstrb::type_id::create("wstrb_seq");
    wstrb_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED WSTRB TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    repeat (10) @(posedge vif.clk);

    // ============================================================
    // FIFO / STRESS TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING FIFO / STRESS TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    fifo_stress_seq = seq_fifo_stress::type_id::create("fifo_stress_seq");
    fifo_stress_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED FIFO / STRESS TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    repeat (10) @(posedge vif.clk);

    // ============================================================
    // ID TRACKING TESTS
    // ============================================================

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "STARTING ID TRACKING TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    id_seq = seq_id::type_id::create("id_seq");
    id_seq.start(env.master_agent.seqr);

    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)
    `uvm_info("TEST_ALL", "COMPLETED ID TRACKING TEST CASES", UVM_LOW)
    `uvm_info("TEST_ALL", "==================================================", UVM_LOW)

    #2500;

    phase.drop_objection(this);

  endtask

endclass
