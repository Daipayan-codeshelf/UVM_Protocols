class i2c_seq_item extends uvm_sequence_item;

    `uvm_object_utils(i2c_seq_item)

    // 0 = write, 1 = read
    rand bit       rw;
    rand bit [6:0] addr;
    rand bit [7:0] reg_addr;
    rand bit [7:0] data_in;
    rand bit       rep_start;

    // speed select: 00=STD, 01=FAST, 10=FM, 11=default case
    rand bit [1:0] speed_sel;

    bit [7:0] data_out;
    bit done;
    bit arb_lost;
    bit nack_error;

    constraint valid_slave_c {
        addr inside {7'h30, 7'h31};
    }

    constraint rw_c {
        rw inside {0,1};
    }

    constraint reg_addr_c {
        reg_addr inside {[8'h00:8'hFF]};
    }

    constraint speed_c {
        speed_sel inside {[2'b00:2'b11]};
    }
 
	constraint default_speed_c {
      soft speed_sel == 2'b00;
	}

    function new(string name="i2c_seq_item");
        super.new(name);
    endfunction

    function string convert2string();

        return $sformatf(
        "RW=%0s SLAVE=0x%0h REG=0x%0h DIN=0x%0h DOUT=0x%0h REP_START=%0b SPEED=%0b DONE=%0b ARB=%0b NACK=%0b",
        rw ? "READ" : "WRITE",
        addr,
        reg_addr,
        data_in,
        data_out,
        rep_start,
        speed_sel,
        done,
        arb_lost,
        nack_error);

    endfunction

endclass
