// TC01 – FS-001: Randomized ACKed TX
class can_fs_tc_01_test extends can_base_test;
    `uvm_component_utils(can_fs_tc_01_test)

    function new(string name = "can_fs_tc_01_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_fs_tc_01 seq;
        phase.raise_objection(this);
        seq = can_fs_tc_01::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC02 – FS-002: No-ACK TX
class can_fs_tc_02_test extends can_base_test;
    `uvm_component_utils(can_fs_tc_02_test)

    function new(string name = "can_fs_tc_02_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_fs_tc_02 seq;
        phase.raise_objection(this);
        seq = can_fs_tc_02::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC03 – FS-003: Back-to-Back / Intermission Gating
class can_fs_tc_03_test extends can_base_test;
    `uvm_component_utils(can_fs_tc_03_test)

    function new(string name = "can_fs_tc_03_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_fs_tc_03 seq;
        phase.raise_objection(this);
        seq = can_fs_tc_03::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC04 – FS-004: Bit Stuffing
class can_fs_tc_04_test extends can_base_test;
    `uvm_component_utils(can_fs_tc_04_test)

    function new(string name = "can_fs_tc_04_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
    can_fs_tc_04 seq;
      virtual can_if vif;

    phase.raise_objection(this);
      if(!uvm_config_db #(virtual can_if)::get(this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "test: vif not found")

    seq = can_fs_tc_04::type_id::create("seq");
    seq.start(env.agent.sequencer);

    // seq.start() returns after last finish_item
    // driver is still processing Frame B — give it time
    repeat(500) @(posedge vif.clk);

    phase.drop_objection(this);

endtask

endclass


// TC05 – FS-005: DLC Sweep
class can_fs_tc_05_test extends can_base_test;
    `uvm_component_utils(can_fs_tc_05_test)

    function new(string name = "can_fs_tc_05_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_fs_tc_05 seq;
        phase.raise_objection(this);
        seq = can_fs_tc_05::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC06 – FS-006: ACK Slot Valid and Error
class can_fs_tc_06_test extends can_base_test;
    `uvm_component_utils(can_fs_tc_06_test)

    function new(string name = "can_fs_tc_06_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_fs_tc_06 seq;
        phase.raise_objection(this);
        seq = can_fs_tc_06::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC07 – BT-001: Bit-Time Accuracy
class can_bt_tc_01_test extends can_base_test;
    `uvm_component_utils(can_bt_tc_01_test)

    function new(string name = "can_bt_tc_01_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_bt_tc_01 seq;
        phase.raise_objection(this);
        seq = can_bt_tc_01::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC08 – BT-002: Hard Synchronization
class can_bt_tc_02_test extends can_base_test;
    `uvm_component_utils(can_bt_tc_02_test)

    function new(string name = "can_bt_tc_02_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_bt_tc_02 seq;
        phase.raise_objection(this);
        seq = can_bt_tc_02::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC09 – BT-003: CSMA No TX While Bus Active
class can_bt_tc_03_test extends can_base_test;
    `uvm_component_utils(can_bt_tc_03_test)

    function new(string name = "can_bt_tc_03_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_bt_tc_03 seq;
        phase.raise_objection(this);
        seq = can_bt_tc_03::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC10 – BT-004: Sample Point Position
class can_bt_tc_04_test extends can_base_test;
    `uvm_component_utils(can_bt_tc_04_test)

    function new(string name = "can_bt_tc_04_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_bt_tc_04 seq;
        phase.raise_objection(this);
        seq = can_bt_tc_04::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

// TC11 – BT-005: Sample Point Position
class can_bt_tc_05_test extends can_base_test;
  `uvm_component_utils(can_bt_tc_05_test)

  function new(string name = "can_bt_tc_05_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_bt_tc_05 seq;
        phase.raise_objection(this);
        seq = can_bt_tc_05::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass


// TC12 – CRC-001: CRC-15 Full Random Frame
class can_crc_tc_01_test extends can_base_test;
    `uvm_component_utils(can_crc_tc_01_test)

    function new(string name = "can_crc_tc_01_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_crc_tc_01 seq;
        phase.raise_objection(this);

        `uvm_info("TEST", "=== CRC-15 Full Random Frame Test Start ===", UVM_NONE)

        seq = can_crc_tc_01::type_id::create("seq");
        seq.start(env.agent.sequencer);

        `uvm_info("TEST", "=== CRC-15 Full Random Frame Test Complete ===", UVM_NONE)

        phase.drop_objection(this);
    endtask

endclass

// TC13 – CRC-002: Maximum Stuff Bits – All-Zero 8-Byte Payload
class can_crc_tc_02_test extends can_base_test;
  `uvm_component_utils(can_crc_tc_02_test)

  function new(string name = "can_crc_tc_02_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_crc_tc_02 seq;
        phase.raise_objection(this);
        seq = can_crc_tc_02::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

// TC14 – CRC-002: Maximum Stuff Bits – All-Zero 8-Byte Payload
class can_idle_tc_test extends can_base_test;
  `uvm_component_utils(can_idle_tc_test)

  function new(string name = "can_idle_tc_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_idle_tc seq;
        phase.raise_objection(this);
        seq = can_idle_tc::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

// Full Regression – FS-001 to CRC-001
class can_regression_test extends can_base_test;
    `uvm_component_utils(can_regression_test)

    function new(string name = "can_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        can_fs_tc_01  s01;
        can_fs_tc_02  s02;
        can_fs_tc_03  s03;
        can_fs_tc_04  s04;
        can_fs_tc_05  s05;
        can_fs_tc_06  s06;
        can_bt_tc_01  s07;
        can_bt_tc_02  s08;
        can_bt_tc_03  s09;
        can_bt_tc_04  s10;
        can_bt_tc_05  s11;
        can_crc_tc_01 s12;
        can_crc_tc_02 s13;
      

        phase.raise_objection(this);
        `uvm_info("TEST", "=== Regression Test Start ===", UVM_NONE)

        s01 = can_fs_tc_01::type_id::create("s01");   s01.start(env.agent.sequencer);
        s02 = can_fs_tc_02::type_id::create("s02");   s02.start(env.agent.sequencer);
        s03 = can_fs_tc_03::type_id::create("s03");   s03.start(env.agent.sequencer);
        s04 = can_fs_tc_04::type_id::create("s04");   s04.start(env.agent.sequencer);
        s05 = can_fs_tc_05::type_id::create("s05");   s05.start(env.agent.sequencer);
        s06 = can_fs_tc_06::type_id::create("s06");   s06.start(env.agent.sequencer);
        s07 = can_bt_tc_01::type_id::create("s07");   s07.start(env.agent.sequencer);
        s08 = can_bt_tc_02::type_id::create("s08");   s08.start(env.agent.sequencer);
        s09 = can_bt_tc_03::type_id::create("s09");   s09.start(env.agent.sequencer);
        s10 = can_bt_tc_04::type_id::create("s10");   s10.start(env.agent.sequencer);
        s11 = can_bt_tc_05::type_id::create("s11");   s11.start(env.agent.sequencer);
        s12 = can_crc_tc_01::type_id::create("s12");  s12.start(env.agent.sequencer);
        s13 = can_crc_tc_02::type_id::create("s13");  s13.start(env.agent.sequencer);

        `uvm_info("TEST", "=== Regression Test Complete ===", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass
