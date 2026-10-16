`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

class axi_scoreboard extends uvm_component;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp_exp #(axi_seq_item, axi_scoreboard) exp_imp;
  uvm_analysis_imp_act #(axi_seq_item, axi_scoreboard) act_imp;

  bit [31:0] expected_q[$];

  int match_count;
  int mismatch_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);

    exp_imp = new("exp_imp", this);
    act_imp = new("act_imp", this);
  endfunction

  function void write_exp(axi_seq_item item);

    if (item.data.size() > 0) begin

      expected_q.push_back(item.data[0]);

      `uvm_info("SB_EXP",
                $sformatf("Expected pushed = 0x%08h", item.data[0]),
                UVM_HIGH)

    end

  endfunction

  function void write_act(axi_seq_item item);

    bit [31:0] exp;

    if (item.data.size() > 0) begin

      if (expected_q.size() == 0) begin

        mismatch_count++;

        `uvm_error("SB_ACT",
                   $sformatf("Unexpected actual data = 0x%08h",
                             item.data[0]))

      end
      else begin

        exp = expected_q.pop_front();

        if (exp !== item.data[0]) begin

          mismatch_count++;

          `uvm_error("SB_ACT",
                     $sformatf("DATA MISMATCH exp=0x%08h got=0x%08h",
                               exp, item.data[0]))

        end
        else begin

          match_count++;

          `uvm_info("SB_ACT",
                    $sformatf("DATA MATCH exp=0x%08h got=0x%08h",
                              exp, item.data[0]),
                    UVM_HIGH)

        end
      end
    end

  endfunction

  function void report_phase(uvm_phase phase);

    `uvm_info("SB_REPORT",
              $sformatf("matches=%0d mismatches=%0d remaining_expected=%0d",
                        match_count, mismatch_count, expected_q.size()),
              UVM_LOW)

    if (mismatch_count == 0 &&
        expected_q.size() == 0) begin

      `uvm_info("SB_REPORT", "AXI TEST PASSED", UVM_LOW)

    end
    else begin

      `uvm_error("SB_REPORT", "AXI TEST FAILED")

    end

  endfunction

endclass
