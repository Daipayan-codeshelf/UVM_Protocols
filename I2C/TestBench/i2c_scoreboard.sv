class i2c_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(i2c_scoreboard)

    `uvm_analysis_imp_decl(_m1)
    `uvm_analysis_imp_decl(_m2)

    uvm_analysis_imp_m1 #(i2c_seq_item, i2c_scoreboard) m1_imp;
    uvm_analysis_imp_m2 #(i2c_seq_item, i2c_scoreboard) m2_imp;
  
    i2c_seq_item m1_queue[$];
    i2c_seq_item m2_queue[$];
  

    int pass_cnt;
    int fail_cnt;

    // Reference memory:
    // ref_memory[slave_address][register_address]
    bit [7:0] ref_memory [bit [6:0]][bit [7:0]];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        pass_cnt = 0;
        fail_cnt = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m1_imp = new("m1_imp", this);
        m2_imp = new("m2_imp", this);
        init_ref_memory();
    endfunction

    function void init_ref_memory();
        int slave;
        int reg_i;

        for(slave = 0; slave < 128; slave = slave + 1) begin
            for(reg_i = 0; reg_i < 256; reg_i = reg_i + 1) begin
                ref_memory[slave[6:0]][reg_i[7:0]] = reg_i[7:0];
            end
        end
    endfunction

    function bit is_valid_slave(bit [6:0] addr);
        return (addr == 7'h30 || addr == 7'h31);
    endfunction
  
  function void write_m1(i2c_seq_item item);
    
    `uvm_info("SB", "============================================================", UVM_NONE)
    `uvm_info("SB", $sformatf("SCOREBOARD RECEIVED M1 : %s",
                              item.convert2string()), UVM_NONE)
    `uvm_info("SB",
              "============================================================",
              UVM_NONE)
    
    if(m2_queue.size() > 0) begin
      i2c_seq_item m2_item;
      m2_item = m2_queue.pop_front();
      check_arbitration(item, m2_item);
      return;
    end
    
    if(item.arb_lost) begin
      m1_queue.push_back(item);
      return;
    end
    
    check_transaction(item, "M1");
  
  endfunction
  
  
  function void write_m2(i2c_seq_item item);
    
    `uvm_info("SB",
              "============================================================",
              UVM_NONE)
    `uvm_info("SB", $sformatf("SCOREBOARD RECEIVED M2 : %s",
                              item.convert2string()), UVM_NONE)
    `uvm_info("SB",
              "============================================================",
              UVM_NONE)
    
    if(m1_queue.size() > 0) begin
      i2c_seq_item m1_item;
      m1_item = m1_queue.pop_front();
      check_arbitration(m1_item, item);
      return;
    end
    
    if(item.arb_lost) begin
      m2_queue.push_back(item);
      return;
    end
    check_transaction(item, "M2");
  
  endfunction

    function void check_transaction(i2c_seq_item item, string tag);

        // Expected NACK case:
        // Only slaves 0x30 and 0x31 exist in the TB.
        if(item.nack_error) begin
            if(!is_valid_slave(item.addr)) begin
                pass_cnt++;

                `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
                `uvm_info("SB", $sformatf("[PASS] %s EXPECTED NACK", tag), UVM_NONE)
                `uvm_info("SB", $sformatf("INVALID SLAVE : 0x%0h", item.addr), UVM_NONE)
                `uvm_info("SB", "No reference memory update performed.", UVM_NONE)
                `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
                return;
            end else begin
                fail_cnt++;

                `uvm_error("SB",
                    $sformatf("[%s] FAIL : unexpected NACK for valid slave 0x%0h",
                        tag,
                        item.addr))
                return;
            end
        end

        if(!item.done) begin
            fail_cnt++;
            `uvm_error("SB", $sformatf("[%s] FAIL : done not asserted", tag))
            return;
        end

        if(item.arb_lost) begin
            fail_cnt++;
            `uvm_error("SB", $sformatf("[%s] FAIL : unexpected arbitration lost", tag))
            return;
        end

        if(!is_valid_slave(item.addr)) begin
            fail_cnt++;
            `uvm_error("SB",
                $sformatf("[%s] FAIL : invalid slave 0x%0h completed without NACK",
                    tag,
                    item.addr))
            return;
        end
      
      if(item.rw == 0 && item.rep_start == 1) begin
        ref_memory[item.addr][item.reg_addr] = item.data_in;
        
        if(item.data_out !== item.data_in) begin
          fail_cnt++;
          `uvm_error("SB",
                     $sformatf("[%s] WRITE-THEN-READ REPEATED START MISMATCH slave=0x%0h reg=0x%0h got=0x%0h expected=0x%0h", tag, item.addr, item.reg_addr, item.data_out, item.data_in))
          return;
        end
        
        pass_cnt++;
        `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
        `uvm_info("SB", $sformatf("[PASS] %s WRITE THEN READ WITH REPEATED START", tag), UVM_NONE)
        `uvm_info("SB", $sformatf("SLAVE    : 0x%0h", item.addr), UVM_NONE)
        `uvm_info("SB", $sformatf("REGISTER : 0x%0h", item.reg_addr), UVM_NONE)
        `uvm_info("SB", $sformatf("WRITE    : 0x%0h", item.data_in), UVM_NONE)
        `uvm_info("SB", $sformatf("READBACK : 0x%0h", item.data_out), UVM_NONE)
        `uvm_info("SB", "No STOP between write and read phase.", UVM_NONE)
        `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
        return;
      end

        if(item.rw == 0) begin

            ref_memory[item.addr][item.reg_addr] = item.data_in;
            pass_cnt++;

            `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
            `uvm_info("SB", $sformatf("[PASS] %s REGISTER WRITE", tag), UVM_NONE)
            `uvm_info("SB", $sformatf("SLAVE    : 0x%0h", item.addr), UVM_NONE)
            `uvm_info("SB", $sformatf("REGISTER : 0x%0h", item.reg_addr), UVM_NONE)
            `uvm_info("SB", $sformatf("DATA     : 0x%0h", item.data_in), UVM_NONE)
            `uvm_info("SB", "Reference model updated:", UVM_NONE)
            `uvm_info("SB",
                $sformatf("ref_memory[0x%0h][0x%0h] = 0x%0h",
                    item.addr, item.reg_addr, item.data_in),
                UVM_NONE)
            `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)

        end else begin

            if(item.data_out !== ref_memory[item.addr][item.reg_addr]) begin
                fail_cnt++;

                `uvm_error("SB",
                    $sformatf("[%s] READ MISMATCH slave=0x%0h reg=0x%0h got=0x%0h expected=0x%0h",
                        tag,
                        item.addr,
                        item.reg_addr,
                        item.data_out,
                        ref_memory[item.addr][item.reg_addr]))
                return;
            end

            pass_cnt++;

            `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
            `uvm_info("SB", $sformatf("[PASS] %s REGISTER READ", tag), UVM_NONE)
            `uvm_info("SB", $sformatf("SLAVE    : 0x%0h", item.addr), UVM_NONE)
            `uvm_info("SB", $sformatf("REGISTER : 0x%0h", item.reg_addr), UVM_NONE)
            `uvm_info("SB", $sformatf("READ DATA: 0x%0h", item.data_out), UVM_NONE)
            `uvm_info("SB", $sformatf("EXPECTED : 0x%0h", ref_memory[item.addr][item.reg_addr]), UVM_NONE)
            `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)

        end

    endfunction

    function void check_arbitration(i2c_seq_item m1_item, i2c_seq_item m2_item);

        bit m1_won;
        bit m2_won;
        bit m1_lost;
        bit m2_lost;

        m1_won  = (m1_item.done     && !m1_item.arb_lost && !m1_item.nack_error);
        m2_won  = (m2_item.done     && !m2_item.arb_lost && !m2_item.nack_error);
        m1_lost = (m1_item.arb_lost && !m1_item.done);
        m2_lost = (m2_item.arb_lost && !m2_item.done);

        if((m1_won && m2_lost) || (m2_won && m1_lost)) begin

            pass_cnt++;

            if(m1_won && m1_item.rw == 0)
                ref_memory[m1_item.addr][m1_item.reg_addr] = m1_item.data_in;
            else if(m2_won && m2_item.rw == 0)
                ref_memory[m2_item.addr][m2_item.reg_addr] = m2_item.data_in;

            `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)
            `uvm_info("SB", "[PASS] ARBITRATION", UVM_NONE)

            if(m1_won)
                `uvm_info("SB", "WINNER : MASTER 1", UVM_NONE)
            else
                `uvm_info("SB", "WINNER : MASTER 2", UVM_NONE)

            `uvm_info("SB", "------------------------------------------------------------", UVM_NONE)

        end else begin

            fail_cnt++;

            `uvm_error("SB",
                $sformatf("[FAIL] ARBITRATION m1_done=%0b m1_arb=%0b m1_nack=%0b m2_done=%0b m2_arb=%0b m2_nack=%0b",
                    m1_item.done,
                    m1_item.arb_lost,
                    m1_item.nack_error,
                    m2_item.done,
                    m2_item.arb_lost,
                    m2_item.nack_error))

        end

    endfunction

    function void report_phase(uvm_phase phase);

        `uvm_info("SB", "============================================================", UVM_NONE)
        `uvm_info("SB", "                    SCOREBOARD FINAL REPORT                 ", UVM_NONE)
        `uvm_info("SB", "============================================================", UVM_NONE)
        `uvm_info("SB", $sformatf("PASS COUNT : %0d", pass_cnt), UVM_NONE)
        `uvm_info("SB", $sformatf("FAIL COUNT : %0d", fail_cnt), UVM_NONE)

        if(fail_cnt == 0)
            `uvm_info("SB", "RESULT     : ALL TESTS PASSED", UVM_NONE)
        else
            `uvm_error("SB", $sformatf("RESULT     : %0d TESTS FAILED", fail_cnt))

        `uvm_info("SB", "============================================================", UVM_NONE)

    endfunction

endclass
