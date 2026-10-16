//─────────────────────────────────────────────────────
//  TC1 — BASIC REGISTER WRITE
//─────────────────────────────────────────────────────
class i2c_write_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_write_seq)

    function new(string name = "i2c_write_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("WRITE_SEQ", "============================================================", UVM_NONE)
        `uvm_info("WRITE_SEQ", "TC1 : BASIC REGISTER WRITE", UVM_NONE)
        `uvm_info("WRITE_SEQ", "WRITE 0x25 TO SLAVE 0x30 REGISTER 0x02", UVM_NONE)
        `uvm_info("WRITE_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h02;
            data_in   == 8'h25;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("WRITE_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC2 — BASIC REGISTER READ
//─────────────────────────────────────────────────────
class i2c_read_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_read_seq)

    function new(string name = "i2c_read_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("READ_SEQ", "============================================================", UVM_NONE)
        `uvm_info("READ_SEQ", "TC2 : BASIC REGISTER READ", UVM_NONE)
        `uvm_info("READ_SEQ", "READ SLAVE 0x30 REGISTER 0x02", UVM_NONE)
        `uvm_info("READ_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 1;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h02;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("READ_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC3 — READ UNWRITTEN / DEFAULT REGISTER
//─────────────────────────────────────────────────────
class i2c_read_default_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_read_default_seq)

    function new(string name = "i2c_read_default_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("DEFAULT_READ_SEQ", "============================================================", UVM_NONE)
        `uvm_info("DEFAULT_READ_SEQ", "TC3 : READ UNWRITTEN / DEFAULT REGISTER", UVM_NONE)
        `uvm_info("DEFAULT_READ_SEQ", "READ SLAVE 0x30 REGISTER 0x21, EXPECT DEFAULT 0x21", UVM_NONE)
        `uvm_info("DEFAULT_READ_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 1;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h21;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("DEFAULT_READ_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC4 — CLOCK STRETCH REGISTER WRITE
//─────────────────────────────────────────────────────
class i2c_stretch_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_stretch_seq)

    function new(string name = "i2c_stretch_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("STRETCH_SEQ", "============================================================", UVM_NONE)
        `uvm_info("STRETCH_SEQ", "TC4 : CLOCK STRETCH REGISTER WRITE", UVM_NONE)
        `uvm_info("STRETCH_SEQ", "WRITE 0xD7 TO STRETCH SLAVE 0x31 REGISTER 0x04", UVM_NONE)
        `uvm_info("STRETCH_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h31;
            reg_addr  == 8'h04;
            data_in   == 8'hD7;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("STRETCH_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC5 — READ FROM STRETCH SLAVE
//─────────────────────────────────────────────────────
class i2c_read_stretch_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_read_stretch_seq)

    function new(string name = "i2c_read_stretch_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("READ_STRETCH_SEQ", "============================================================", UVM_NONE)
        `uvm_info("READ_STRETCH_SEQ", "TC5 : READ FROM STRETCH SLAVE", UVM_NONE)
        `uvm_info("READ_STRETCH_SEQ", "READ SLAVE 0x31 REGISTER 0x20", UVM_NONE)
        `uvm_info("READ_STRETCH_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 1;
            rep_start == 0;
            addr      == 7'h31;
            reg_addr  == 8'h20;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("READ_STRETCH_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC6 — WRITE TO BOTH SLAVES
//─────────────────────────────────────────────────────
class i2c_both_slaves_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_both_slaves_seq)

    function new(string name = "i2c_both_slaves_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;

        `uvm_info("BOTH_SEQ", "============================================================", UVM_NONE)
        `uvm_info("BOTH_SEQ", "TC6 : WRITE TO BOTH SLAVES", UVM_NONE)
        `uvm_info("BOTH_SEQ", "NORMAL SLAVE 0x30 AND STRETCH SLAVE 0x31", UVM_NONE)
        `uvm_info("BOTH_SEQ", "============================================================", UVM_NONE)

        item = i2c_seq_item::type_id::create("item1");
        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h10;
            data_in   == 8'hA5;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        item = i2c_seq_item::type_id::create("item2");
        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h31;
            reg_addr  == 8'h20;
            data_in   == 8'hD7;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC7 — REGISTER OVERWRITE
//─────────────────────────────────────────────────────
class i2c_overwrite_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_overwrite_seq)

    function new(string name = "i2c_overwrite_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;

        `uvm_info("OVERWRITE_SEQ", "============================================================", UVM_NONE)
        `uvm_info("OVERWRITE_SEQ", "TC7 : REGISTER OVERWRITE", UVM_NONE)
        `uvm_info("OVERWRITE_SEQ", "WRITE 0x11 THEN 0x99 TO SAME REGISTER 0x55, THEN READ BACK", UVM_NONE)
        `uvm_info("OVERWRITE_SEQ", "============================================================", UVM_NONE)

        item = i2c_seq_item::type_id::create("first_write");
        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h55;
            data_in   == 8'h11;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        item = i2c_seq_item::type_id::create("second_write");
        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h55;
            data_in   == 8'h99;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        item = i2c_seq_item::type_id::create("read_after_overwrite");
        start_item(item);
        if(!item.randomize() with {
            rw        == 1;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == 8'h55;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC8 — REPEATED START REGISTER READ
//─────────────────────────────────────────────────────
class i2c_repeated_start_read_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_repeated_start_read_seq)

    function new(string name = "i2c_repeated_start_read_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("REP_START_SEQ", "============================================================", UVM_NONE)
        `uvm_info("REP_START_SEQ", "TC8 : REPEATED START REGISTER READ", UVM_NONE)
        `uvm_info("REP_START_SEQ", "START + SLA/W + REG + REP_START + SLA/R + READ + STOP", UVM_NONE)
        `uvm_info("REP_START_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 1;
            rep_start == 1;
            addr      == 7'h30;
            reg_addr  == 8'h02;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("REP_START_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC9 — INVALID SLAVE ADDRESS / NACK
//─────────────────────────────────────────────────────
class i2c_invalid_slave_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_invalid_slave_seq)

    function new(string name = "i2c_invalid_slave_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("NACK_SEQ", "============================================================", UVM_NONE)
        `uvm_info("NACK_SEQ", "TC9 : INVALID SLAVE ADDRESS / NACK", UVM_NONE)
        `uvm_info("NACK_SEQ", "ACCESS SLAVE 0x32, EXPECT NACK", UVM_NONE)
        `uvm_info("NACK_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        item.valid_slave_c.constraint_mode(0);

        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h32;
            reg_addr  == 8'h02;
            data_in   == 8'h55;
        })
            `uvm_fatal("RAND", "randomize failed")

        finish_item(item);

        `uvm_info("NACK_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC10 — ARBITRATION WITH DIFFERENT DATA
//─────────────────────────────────────────────────────
class i2c_arb_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_arb_seq)

    bit [7:0] data_val;
    bit [7:0] reg_val;

    function new(string name = "i2c_arb_seq");
        super.new(name);
        data_val = 8'hBB;
        reg_val  = 8'h05;
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("ARB_SEQ", "============================================================", UVM_NONE)
        `uvm_info("ARB_SEQ", "TC10 : ARBITRATION WITH DIFFERENT DATA", UVM_NONE)
        `uvm_info("ARB_SEQ", $sformatf("SLAVE 0x30 REG 0x%0h DATA 0x%0h", reg_val, data_val), UVM_NONE)
        `uvm_info("ARB_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 0;
            addr      == 7'h30;
            reg_addr  == local::reg_val;
            data_in   == local::data_val;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("ARB_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC11 — SAME DATA ARBITRATION
//─────────────────────────────────────────────────────
class i2c_same_data_arb_seq extends uvm_sequence;

    `uvm_object_utils(i2c_same_data_arb_seq)

    uvm_sequencer #(i2c_seq_item) m1_seqr;
    uvm_sequencer #(i2c_seq_item) m2_seqr;

    function new(string name = "i2c_same_data_arb_seq");
        super.new(name);
    endfunction

    task body();
        i2c_arb_seq seq_m1;
        i2c_arb_seq seq_m2;

        `uvm_info("SAME_ARB_SEQ", "============================================================", UVM_NONE)
        `uvm_info("SAME_ARB_SEQ", "TC11 : SAME DATA ARBITRATION", UVM_NONE)
        `uvm_info("SAME_ARB_SEQ", "BOTH MASTERS WRITE SAME REGISTER AND SAME DATA", UVM_NONE)
        `uvm_info("SAME_ARB_SEQ", "============================================================", UVM_NONE)

        seq_m1 = i2c_arb_seq::type_id::create("seq_m1");
        seq_m2 = i2c_arb_seq::type_id::create("seq_m2");

        seq_m1.reg_val  = 8'h33;
        seq_m2.reg_val  = 8'h33;
        seq_m1.data_val = 8'hAA;
        seq_m2.data_val = 8'hAA;

        fork
            seq_m1.start(m1_seqr);
            seq_m2.start(m2_seqr);
        join
    endtask

endclass


//─────────────────────────────────────────────────────
//  TC12 — RANDOM REGISTER TRANSACTIONS
//─────────────────────────────────────────────────────
class i2c_random_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_random_seq)

    int unsigned num_trans = 10;

    function new(string name = "i2c_random_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;

        `uvm_info("RANDOM_SEQ", "============================================================", UVM_NONE)
        `uvm_info("RANDOM_SEQ", "TC12 : RANDOM REGISTER TRANSACTIONS", UVM_NONE)
        `uvm_info("RANDOM_SEQ", $sformatf("%0d RANDOM WRITES/READS", num_trans), UVM_NONE)
        `uvm_info("RANDOM_SEQ", "============================================================", UVM_NONE)

        repeat(num_trans) begin
            item = i2c_seq_item::type_id::create("item");

            start_item(item);
            if(!item.randomize() with {
                rep_start == 0;
            })
                `uvm_fatal("RAND", "randomize failed")
            finish_item(item);
        end
    endtask

endclass

//─────────────────────────────────────────────────────
//  TC13 — IMMEDIATE READ AFTER WRITE USING REPEATED START
//  START + SLA/W + REG + DATA + REP_START + SLA/R + READ + STOP
//─────────────────────────────────────────────────────
class i2c_write_then_repeated_read_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_write_then_repeated_read_seq)

    function new(string name = "i2c_write_then_repeated_read_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");

        `uvm_info("WR_RD_REP_SEQ", "============================================================", UVM_NONE)
        `uvm_info("WR_RD_REP_SEQ", "TC13 : IMMEDIATE READ AFTER WRITE USING REPEATED START", UVM_NONE)
        `uvm_info("WR_RD_REP_SEQ", "WRITE 0x55 TO SLAVE 0x30 REG 0x02, THEN REP_START READ", UVM_NONE)
        `uvm_info("WR_RD_REP_SEQ", "EXPECTED READ DATA = 0x55", UVM_NONE)
        `uvm_info("WR_RD_REP_SEQ", "============================================================", UVM_NONE)

        start_item(item);
        if(!item.randomize() with {
            rw        == 0;
            rep_start == 1;
            addr      == 7'h30;
            reg_addr  == 8'h02;
            data_in   == 8'h55;
        })
            `uvm_fatal("RAND", "randomize failed")
        finish_item(item);

        `uvm_info("WR_RD_REP_SEQ", item.convert2string(), UVM_MEDIUM)
    endtask

endclass

class i2c_coverage_closure_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_coverage_closure_seq)

    function new(string name = "i2c_coverage_closure_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;

        // reg_00 + data_00
        item = i2c_seq_item::type_id::create("cov_reg00");
        start_item(item);
        item.randomize() with {
            rw == 0; rep_start == 0;
            addr == 7'h30;
            reg_addr == 8'h00;
            data_in == 8'h00;
        };
        finish_item(item);

        // reg_01 + data_ff
        item = i2c_seq_item::type_id::create("cov_reg01");
        start_item(item);
        item.randomize() with {
            rw == 0; rep_start == 0;
            addr == 7'h30;
            reg_addr == 8'h01;
            data_in == 8'hFF;
        };
        finish_item(item);

        // reg_ff + high data
        item = i2c_seq_item::type_id::create("cov_regff");
        start_item(item);
        item.randomize() with {
            rw == 0; rep_start == 0;
            addr == 7'h31;
            reg_addr == 8'hFF;
            data_in == 8'hA5;
        };
        finish_item(item);

        // read high data back from 0x31 reg_ff
        item = i2c_seq_item::type_id::create("cov_read_high");
        start_item(item);
        item.randomize() with {
            rw == 1; rep_start == 0;
            addr == 7'h31;
            reg_addr == 8'hFF;
        };
        finish_item(item);

    endtask

endclass


// TC14 — SPEED MODE COVERAGE
class i2c_speed_seq extends uvm_sequence #(i2c_seq_item);

  `uvm_object_utils(i2c_speed_seq)

  function new(string name = "i2c_speed_seq");
    super.new(name);
  endfunction

  task body();
    i2c_seq_item item;

    `uvm_info("SPEED_SEQ", "==============================================", UVM_NONE)
    `uvm_info("SPEED_SEQ", "COVERING ALL SPEED MODES (00,01,10,11)", UVM_NONE)
    `uvm_info("SPEED_SEQ", "==============================================", UVM_NONE)

    // loop through all speed values
    for(int i = 0; i < 4; i++) begin

      item = i2c_seq_item::type_id::create($sformatf("item_%0d", i));

      start_item(item);

      if(!item.randomize() with {
        speed_sel == i;
        addr inside {7'h30, 7'h31}; // valid slave
        rw inside {0,1};
      })
        `uvm_fatal("RAND", "Speed sequence randomization failed")

      finish_item(item);

      `uvm_info("SPEED_SEQ",
        $sformatf("Driven SPEED_SEL = %0d", i),
        UVM_MEDIUM)

    end

  endtask

endclass
//─────────────────────────────────────────────────────
//  REGRESSION SEQUENCE — CLEAN ORDER
//─────────────────────────────────────────────────────
class i2c_regression_seq extends uvm_sequence;

    `uvm_object_utils(i2c_regression_seq)

    uvm_sequencer #(i2c_seq_item) m1_seqr;
    uvm_sequencer #(i2c_seq_item) m2_seqr;

    function new(string name = "i2c_regression_seq");
        super.new(name);
    endfunction

    task body();

        i2c_write_seq               tc1;
        i2c_read_seq                tc2;
        i2c_read_default_seq        tc3;
        i2c_stretch_seq             tc4;
        i2c_read_stretch_seq        tc5;
        i2c_both_slaves_seq         tc6;
        i2c_overwrite_seq           tc7;
        i2c_repeated_start_read_seq tc8;
        i2c_invalid_slave_seq       tc9;
        i2c_arb_seq                 tc10_m1;
        i2c_arb_seq                 tc10_m2;
        i2c_same_data_arb_seq       tc11;
        i2c_random_seq              tc12;
        i2c_write_then_repeated_read_seq tc13;
		i2c_coverage_closure_seq tc_cov;
      	i2c_speed_seq tc14;


        `uvm_info("REG_SEQ", "============================================================", UVM_NONE)
        `uvm_info("REG_SEQ", "FULL I2C REGRESSION STARTED", UVM_NONE)
        `uvm_info("REG_SEQ", "ORDER: BASIC → DEFAULT → STRETCH → MULTI-SLAVE → OVERWRITE → REP_START → NACK → ARB → RANDOM", UVM_NONE)
        `uvm_info("REG_SEQ", "============================================================", UVM_NONE)

        tc1 = i2c_write_seq::type_id::create("tc1");
        tc1.start(m1_seqr);

        tc2 = i2c_read_seq::type_id::create("tc2");
        tc2.start(m1_seqr);

        tc3 = i2c_read_default_seq::type_id::create("tc3");
        tc3.start(m1_seqr);

        tc4 = i2c_stretch_seq::type_id::create("tc4");
        tc4.start(m1_seqr);

        tc5 = i2c_read_stretch_seq::type_id::create("tc5");
        tc5.start(m1_seqr);

        tc6 = i2c_both_slaves_seq::type_id::create("tc6");
        tc6.start(m1_seqr);

        tc7 = i2c_overwrite_seq::type_id::create("tc7");
        tc7.start(m1_seqr);

        tc8 = i2c_repeated_start_read_seq::type_id::create("tc8");
        tc8.start(m1_seqr);

        tc9 = i2c_invalid_slave_seq::type_id::create("tc9");
        tc9.start(m1_seqr);

        tc10_m1 = i2c_arb_seq::type_id::create("tc10_m1");
        tc10_m2 = i2c_arb_seq::type_id::create("tc10_m2");

        tc10_m1.reg_val  = 8'h05;
        tc10_m2.reg_val  = 8'h05;
        tc10_m1.data_val = 8'hBB;
        tc10_m2.data_val = 8'hCC;

        fork
            tc10_m1.start(m1_seqr);
            tc10_m2.start(m2_seqr);
        join

        tc11 = i2c_same_data_arb_seq::type_id::create("tc11");
        tc11.m1_seqr = m1_seqr;
        tc11.m2_seqr = m2_seqr;
        tc11.start(null);
      
        tc13 = i2c_write_then_repeated_read_seq::type_id::create("tc13");
        tc13.start(m1_seqr);
      
      	tc14 = i2c_speed_seq::type_id::create("tc14");
		tc14.start(m1_seqr);

        tc12 = i2c_random_seq::type_id::create("tc12");
        tc12.num_trans = 20;
        tc12.start(m1_seqr);
      
		tc_cov = i2c_coverage_closure_seq::type_id::create("tc_cov");
		tc_cov.start(m1_seqr);

        `uvm_info("REG_SEQ", "============================================================", UVM_NONE)
        `uvm_info("REG_SEQ", "FULL I2C REGRESSION COMPLETED", UVM_NONE)
        `uvm_info("REG_SEQ", "============================================================", UVM_NONE)

    endtask

endclass

