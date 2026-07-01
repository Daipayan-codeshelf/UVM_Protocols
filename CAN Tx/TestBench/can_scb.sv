`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

class can_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(can_scoreboard)

    // Expected transactions from driver
    uvm_analysis_imp_exp #(can_seq_item,can_scoreboard) exp_export;

    // Actual transactions from monitor
    uvm_analysis_imp_act #(can_seq_item,can_scoreboard) act_export;

    // Queues
    can_seq_item exp_q[$];
    can_seq_item act_q[$];

    int pass_count;
    int fail_count;

    // Constructor
    function new(string name = "can_scoreboard",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    // Build Phase
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        exp_export = new("exp_export", this);
        act_export = new("act_export", this);

        pass_count = 0;
        fail_count = 0;

    endfunction

    // Expected Transaction
    function void write_exp(can_seq_item tr);

        exp_q.push_back(tr);

    endfunction

    // Actual Transaction
    function void write_act(can_seq_item tr);

        act_q.push_back(tr);

        compare_transactions();

    endfunction
  
  // CRC Calculation
	function automatic [14:0] calc_crc15(
    input logic [10:0] tx_id,
    input logic [3:0]  tx_dlc,
    input logic [63:0] tx_data
);

    logic [14:0] crc_reg;
    logic        fb;

    // Build the full serial bitstream into one array
    int           total_bits;
    logic [81:0]  bitstream;
    int           idx;

    total_bits = 11 + 1 + 1 + 1 + 4 + (tx_dlc * 8);  // max = 18 + 64 = 82 bits
    bitstream  = '0;
    idx        = total_bits - 1;  // fill MSB first so bitstream[total_bits-1] is first bit out

    // Pack ID [10:0] MSB first
    for (int i = 10; i >= 0; i--)
        bitstream[idx--] = tx_id[i];

    // RTR = 0
    bitstream[idx--] = 1'b0;

    // IDE = 0
    bitstream[idx--] = 1'b0;

    // R0 = 0
    bitstream[idx--] = 1'b0;

    // DLC [3:0] MSB first
    for (int i = 3; i >= 0; i--)
        bitstream[idx--] = tx_dlc[i];

    // DATA MSB first, only dlc*8 bits
    for (int i = 0; i < (tx_dlc * 8); i++)
        bitstream[idx--] = tx_data[63 - i];

    // CRC loop 
    crc_reg = 15'h7FFF; 

    for (int i = total_bits - 1; i >= 0; i--) begin
        fb      = bitstream[i] ^ crc_reg[14];
        crc_reg = {
            crc_reg[13] ^ fb,
            crc_reg[12],
            crc_reg[11],
            crc_reg[10],
            crc_reg[9]  ^ fb,
            crc_reg[8],
            crc_reg[7]  ^ fb,
            crc_reg[6]  ^ fb,
            crc_reg[5],
            crc_reg[4],
            crc_reg[3]  ^ fb,
            crc_reg[2]  ^ fb,
            crc_reg[1],
            crc_reg[0],
            fb
        };
    end

    calc_crc15 = crc_reg;

endfunction

    // Compare Logic
    function void compare_transactions();

        can_seq_item exp;
        can_seq_item act;

        bit ok = 1;
        logic [14:0] exp_crc; 

        if(exp_q.size() == 0 || act_q.size() == 0)
            return;

        exp = exp_q.pop_front();
        act = act_q.pop_front();

        // Skip Illegal DLC Frames
        if(exp.tx_dlc > 4'd8) begin

            `uvm_info("SB",
                $sformatf(
                "Skipping illegal DLC=%0d frame",
                exp.tx_dlc),
                UVM_MEDIUM)

            return;

        end

        // ID Compare
        if(exp.tx_id != act.tx_id) begin

            `uvm_error("SB",
                $sformatf(
                "ID MISMATCH EXP=0x%03X ACT=0x%03X",
                exp.tx_id,
                act.tx_id))

            ok = 0;

        end

        // DLC Compare
        if(exp.tx_dlc != act.tx_dlc) begin

            `uvm_error("SB",
                $sformatf(
                "DLC MISMATCH EXP=%0d ACT=%0d",
                exp.tx_dlc,
                act.tx_dlc))

            ok = 0;

        end

        // DATA Compare
        if(exp.tx_data != act.tx_data) begin

            `uvm_error("SB",
                $sformatf(
                "DATA MISMATCH EXP=0x%016h ACT=0x%016h",
                exp.tx_data,
                act.tx_data))

            ok = 0;

        end
      
      // CRC Compare

          // CRC check only for ACKed frames
       if(exp.crc_check_en) begin

            exp_crc = calc_crc15(

                          exp.tx_id,
                          exp.tx_dlc,
                          exp.tx_data

                      );

            if(exp_crc != act.act_crc) begin

                `uvm_error("SB",
                    $sformatf(
                    "CRC MISMATCH EXP=0x%04h ACT=0x%04h",
                    exp_crc,
                    act.act_crc))

                ok = 0;

            end
            else begin

                `uvm_info("SB",
                    $sformatf(
                    "CRC MATCH EXP=0x%04h ACT=0x%04h",
                    exp_crc,
                    act.act_crc),
                    UVM_MEDIUM)

            end

        end

        // tx_done Check
        if(!act.tx_done) begin

            `uvm_error("SB",
                "tx_done not asserted")

            ok = 0;

        end

        // ACK Check
        if(exp.ack_req && act.tx_no_ack) begin

            `uvm_error("SB",
                "ACK expected but tx_no_ack asserted")

            ok = 0;

        end

        if(!exp.ack_req && !act.tx_no_ack) begin

            `uvm_error("SB",
                "No ACK expected but tx_no_ack not asserted")

            ok = 0;

        end

        // Arbitration Check
        if(act.arb_lost) begin

            `uvm_info("SB",
                "Arbitration lost detected",
                UVM_MEDIUM)

        end

        // Final Result
//         if(ok) begin

//             pass_count++;

//             `uvm_info("SB",
//                 $sformatf(
//                 "PASS ID=0x%03X DLC=%0d DATA=0x%016h",
//                 act.tx_id,
//                 act.tx_dlc,
//                 act.tx_data),
//                 UVM_MEDIUM)

//         end
//         else begin

//             fail_count++;

//         end
          if (ok) begin

              string pass_msg;

              pass_count++;

              pass_msg = $sformatf(
                  "\n========================================\nTESTCASE PASS\n----------------------------------------\nID       MATCH : EXP=0x%03X ACT=0x%03X\nDLC      MATCH : EXP=%0d ACT=%0d\nDATA     MATCH : EXP=0x%016h ACT=0x%016h\nACK      MATCH : EXP=%0b ACT=%0b\nTX_DONE  MATCH : %0b\nARB_LOST MATCH : %0b\nCRC      MATCH : EXP=0x%04h ACT=0x%04h\n========================================",

                  exp.tx_id,   act.tx_id,
                  exp.tx_dlc,  act.tx_dlc,
                  exp.tx_data, act.tx_data,
                  exp.ack_req, (act.tx_no_ack ? 1'b0 : 1'b1),
                  act.tx_done,
                  act.arb_lost,
                  exp_crc,
                  act.act_crc
              );

              `uvm_info("SB", pass_msg, UVM_MEDIUM)

          end
          else begin
              fail_count++;
          end

    endfunction

    // Report
    function void report_phase(uvm_phase phase);

        `uvm_info("SB",
            $sformatf(
            "\n=====================================\nPASS=%0d FAIL=%0d\n=====================================",
            pass_count,
            fail_count),
            UVM_NONE)

        if(fail_count > 0)
            `uvm_error("SB",
                "One or more checks FAILED")

    endfunction

endclass
