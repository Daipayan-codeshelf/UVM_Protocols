class i2c_coverage extends uvm_subscriber #(i2c_seq_item);

    `uvm_component_utils(i2c_coverage)

    i2c_seq_item item;

    covergroup i2c_cg;

        option.per_instance = 1;

        cp_rw : coverpoint item.rw {
            bins write_op = {0};
            bins read_op  = {1};
        }

        cp_slave_addr : coverpoint item.addr {
            bins slave_normal  = {7'h30};
            bins slave_stretch = {7'h31};
            bins invalid_slave = {7'h32};
        }

        cp_reg_addr : coverpoint item.reg_addr {
            bins low_regs  = {[8'h00 : 8'h3F]};
            bins mid_regs  = {[8'h40 : 8'hBF]};
            bins high_regs = {[8'hC0 : 8'hFF]};

            bins reg_00 = {8'h00};
            bins reg_01 = {8'h01};
            bins reg_02 = {8'h02};
            bins reg_ff = {8'hFF};
        }

        cp_rep_start : coverpoint item.rep_start {
            bins no_repeated_start = {0};
            bins repeated_start    = {1};
        }

        cp_data_in : coverpoint item.data_in iff(item.rw == 0 && !item.nack_error && !item.arb_lost) {
            bins low_data  = {[8'h00 : 8'h7F]};
            bins high_data = {[8'h80 : 8'hFF]};
            bins data_00   = {8'h00};
            bins data_ff   = {8'hFF};
        }

        cp_data_out : coverpoint item.data_out iff(item.rw == 1 && item.done && !item.nack_error && !item.arb_lost) {
            bins low_read_data  = {[8'h00 : 8'h7F]};
            bins high_read_data = {[8'h80 : 8'hFF]};
        }

        cp_done : coverpoint item.done {
            bins completed     = {1};
            bins not_completed = {0};
        }

        cp_arb_lost : coverpoint item.arb_lost {
            bins lost     = {1};
            bins not_lost = {0};
        }

        cp_nack_error : coverpoint item.nack_error {
            bins nack_seen = {1};
            bins no_nack   = {0};
        }

        cx_rw_slave : cross cp_rw, cp_slave_addr {
            ignore_bins invalid_read =
                binsof(cp_slave_addr.invalid_slave) && binsof(cp_rw.read_op);
        }

        cx_rw_reg : cross cp_rw, cp_reg_addr;

        cx_slave_reg : cross cp_slave_addr, cp_reg_addr {
            ignore_bins invalid_slave_regs =
                binsof(cp_slave_addr.invalid_slave);
        }

        cx_rw_repstart : cross cp_rw, cp_rep_start {
            ignore_bins impossible_write_rep =
                binsof(cp_rw.write_op) && binsof(cp_rep_start.repeated_start);
        }

        cx_arb_done : cross cp_arb_lost, cp_done {
            ignore_bins arb_and_done =
                binsof(cp_arb_lost.lost) && binsof(cp_done.completed);

            ignore_bins no_arb_no_done =
                binsof(cp_arb_lost.not_lost) && binsof(cp_done.not_completed);
        }

        cx_slave_nack : cross cp_slave_addr, cp_nack_error {
            ignore_bins valid_slave_nack =
                (binsof(cp_slave_addr.slave_normal) ||
                 binsof(cp_slave_addr.slave_stretch)) &&
                 binsof(cp_nack_error.nack_seen);

            ignore_bins invalid_slave_no_nack =
                binsof(cp_slave_addr.invalid_slave) &&
                binsof(cp_nack_error.no_nack);
        }

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        i2c_cg = new();
    endfunction

    function void write(i2c_seq_item t);
        item = t;
        i2c_cg.sample();

        `uvm_info("COV", "------------------------------------------------------------", UVM_HIGH)
        `uvm_info("COV", "COVERAGE SAMPLE TAKEN", UVM_HIGH)
        `uvm_info("COV", $sformatf("TYPE     : %s", t.rw ? "READ" : "WRITE"), UVM_HIGH)
        `uvm_info("COV", $sformatf("SLAVE    : 0x%0h", t.addr), UVM_HIGH)
        `uvm_info("COV", $sformatf("REGISTER : 0x%0h", t.reg_addr), UVM_HIGH)
        `uvm_info("COV", $sformatf("DONE     : %0b", t.done), UVM_HIGH)
        `uvm_info("COV", $sformatf("ARB_LOST : %0b", t.arb_lost), UVM_HIGH)
        `uvm_info("COV", $sformatf("NACK_ERR : %0b", t.nack_error), UVM_HIGH)
        `uvm_info("COV", "------------------------------------------------------------", UVM_HIGH)
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", "============================================================", UVM_NONE)
        `uvm_info("COV", "                      COVERAGE REPORT                       ", UVM_NONE)
        `uvm_info("COV", "============================================================", UVM_NONE)
        `uvm_info("COV", $sformatf("i2c_cg coverage : %0.2f%%", i2c_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", "============================================================", UVM_NONE)
    endfunction

endclass
