//─────────────────────────────────────────────────────
//  BASE TEST
//─────────────────────────────────────────────────────
class i2c_base_test extends uvm_test;

    `uvm_component_utils(i2c_base_test)

    i2c_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass


//─────────────────────────────────────────────────────
//  TC1 — BASIC REGISTER WRITE
//─────────────────────────────────────────────────────
class i2c_test_write extends i2c_base_test;

    `uvm_component_utils(i2c_test_write)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC1 : BASIC REGISTER WRITE", UVM_NONE)
        `uvm_info("TEST", "WRITE 0x25 TO SLAVE 0x30 REGISTER 0x02", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_write_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC2 — BASIC REGISTER READ
//─────────────────────────────────────────────────────
class i2c_test_read extends i2c_base_test;

    `uvm_component_utils(i2c_test_read)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_read_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC2 : BASIC REGISTER READ", UVM_NONE)
        `uvm_info("TEST", "READ SLAVE 0x30 REGISTER 0x02", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_read_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC3 — READ UNWRITTEN / DEFAULT REGISTER
//─────────────────────────────────────────────────────
class i2c_test_read_default extends i2c_base_test;

    `uvm_component_utils(i2c_test_read_default)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_read_default_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC3 : READ UNWRITTEN / DEFAULT REGISTER", UVM_NONE)
        `uvm_info("TEST", "READ SLAVE 0x30 REGISTER 0x21", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_read_default_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC4 — CLOCK STRETCH REGISTER WRITE
//─────────────────────────────────────────────────────
class i2c_test_stretch extends i2c_base_test;

    `uvm_component_utils(i2c_test_stretch)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_stretch_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC4 : CLOCK STRETCH REGISTER WRITE", UVM_NONE)
        `uvm_info("TEST", "WRITE 0xD7 TO SLAVE 0x31 REGISTER 0x04", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_stretch_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC5 — READ FROM STRETCH SLAVE
//─────────────────────────────────────────────────────
class i2c_test_read_stretch extends i2c_base_test;

    `uvm_component_utils(i2c_test_read_stretch)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_read_stretch_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC5 : READ FROM STRETCH SLAVE", UVM_NONE)
        `uvm_info("TEST", "READ SLAVE 0x31 REGISTER 0x20", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_read_stretch_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC6 — WRITE BOTH SLAVES
//─────────────────────────────────────────────────────
class i2c_test_both_slaves extends i2c_base_test;

    `uvm_component_utils(i2c_test_both_slaves)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_both_slaves_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC6 : WRITE BOTH SLAVES", UVM_NONE)
        `uvm_info("TEST", "NORMAL SLAVE 0x30 AND STRETCH SLAVE 0x31", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_both_slaves_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC7 — REGISTER OVERWRITE
//─────────────────────────────────────────────────────
class i2c_test_overwrite extends i2c_base_test;

    `uvm_component_utils(i2c_test_overwrite)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_overwrite_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC7 : REGISTER OVERWRITE", UVM_NONE)
        `uvm_info("TEST", "WRITE 0x11 THEN 0x99 TO SAME REGISTER, THEN READ BACK", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_overwrite_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC8 — REPEATED START REGISTER READ
//─────────────────────────────────────────────────────
class i2c_test_repeated_start_read extends i2c_base_test;

    `uvm_component_utils(i2c_test_repeated_start_read)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_repeated_start_read_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC8 : REPEATED START REGISTER READ", UVM_NONE)
        `uvm_info("TEST", "START + SLA/W + REG + REP_START + SLA/R + READ + STOP", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_repeated_start_read_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC9 — INVALID SLAVE ADDRESS / NACK
//─────────────────────────────────────────────────────
class i2c_test_invalid_slave extends i2c_base_test;

    `uvm_component_utils(i2c_test_invalid_slave)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_invalid_slave_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC9 : INVALID SLAVE ADDRESS / NACK", UVM_NONE)
        `uvm_info("TEST", "ACCESS SLAVE 0x32, EXPECT NACK", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_invalid_slave_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC10 — ARBITRATION WITH DIFFERENT DATA
//─────────────────────────────────────────────────────
class i2c_test_arb extends i2c_base_test;

    `uvm_component_utils(i2c_test_arb)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_arb_seq seq_m1;
        i2c_arb_seq seq_m2;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC10 : ARBITRATION WITH DIFFERENT DATA", UVM_NONE)
        `uvm_info("TEST", "M1 WRITES 0xBB, M2 WRITES 0xCC TO SAME REGISTER", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq_m1 = i2c_arb_seq::type_id::create("seq_m1");
        seq_m2 = i2c_arb_seq::type_id::create("seq_m2");

        seq_m1.reg_val  = 8'h05;
        seq_m2.reg_val  = 8'h05;
        seq_m1.data_val = 8'hCC;
        seq_m2.data_val = 8'hBB;

        fork
            seq_m1.start(env.master_agent_m1.seqr);
            seq_m2.start(env.master_agent_m2.seqr);
        join

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC11 — SAME DATA ARBITRATION
//─────────────────────────────────────────────────────
class i2c_test_same_arb extends i2c_base_test;

    `uvm_component_utils(i2c_test_same_arb)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_same_data_arb_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC11 : SAME DATA ARBITRATION", UVM_NONE)
        `uvm_info("TEST", "BOTH MASTERS WRITE SAME REGISTER AND SAME DATA", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_same_data_arb_seq::type_id::create("seq");
        seq.m1_seqr = env.master_agent_m1.seqr;
        seq.m2_seqr = env.master_agent_m2.seqr;
        seq.start(null);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC12 — RANDOM REGISTER TRANSACTIONS
//─────────────────────────────────────────────────────
class i2c_test_random extends i2c_base_test;

    `uvm_component_utils(i2c_test_random)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_random_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC12 : RANDOM REGISTER TRANSACTIONS", UVM_NONE)
        `uvm_info("TEST", "20 RANDOM WRITES/READS TO REGISTERS", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_random_seq::type_id::create("seq");
        seq.num_trans = 20;
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass

//─────────────────────────────────────────────────────
//  TC13 — IMMEDIATE READ AFTER WRITE USING REPEATED START
//─────────────────────────────────────────────────────
class i2c_test_write_then_repeated_read extends i2c_base_test;

    `uvm_component_utils(i2c_test_write_then_repeated_read)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_then_repeated_read_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "TC13 : IMMEDIATE READ AFTER WRITE USING REPEATED START", UVM_NONE)
        `uvm_info("TEST", "WRITE 0x55 THEN READ BACK WITHOUT INTERMEDIATE STOP", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_write_then_repeated_read_seq::type_id::create("seq");
        seq.start(env.master_agent_m1.seqr);

        phase.drop_objection(this);
    endtask

endclass


//─────────────────────────────────────────────────────
//  REGRESSION TEST
//─────────────────────────────────────────────────────
class i2c_test_regression extends i2c_base_test;

    `uvm_component_utils(i2c_test_regression)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_regression_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "============================================================", UVM_NONE)
        `uvm_info("TEST", "FULL I2C REGISTER-BASED REGRESSION", UVM_NONE)
        `uvm_info("TEST", "ORDER: BASIC, DEFAULT, STRETCH, MULTI-SLAVE, OVERWRITE, REP_START, NACK, ARB, RANDOM", UVM_NONE)
        `uvm_info("TEST", "============================================================", UVM_NONE)

        seq = i2c_regression_seq::type_id::create("seq");

        seq.m1_seqr = env.master_agent_m1.seqr;
        seq.m2_seqr = env.master_agent_m2.seqr;

        seq.start(null);

        phase.drop_objection(this);
    endtask

endclass
