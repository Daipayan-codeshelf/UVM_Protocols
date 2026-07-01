class can_coverage extends uvm_subscriber #(can_seq_item);
    `uvm_component_utils(can_coverage)

    can_seq_item curr_item;
    can_seq_item prev_item;
    int          consecutive_frame_count;

    // CG1 – TX Frame Fields
    covergroup cg_tx_frame_fields;

        cp_tx_id: coverpoint curr_item.tx_id {
            bins id_low  = {[11'h000 : 11'h0FF]};
            bins id_mid  = {[11'h100 : 11'h5FF]};
            bins id_high = {[11'h600 : 11'h7FF]};
        }

        cp_tx_dlc: coverpoint curr_item.tx_dlc {
            bins dlc_0         = {4'd0};
            bins dlc_1         = {4'd1};
            bins dlc_2         = {4'd2};
            bins dlc_3         = {4'd3};
            bins dlc_4         = {4'd4};
            bins dlc_5         = {4'd5};
            bins dlc_6         = {4'd6};
            bins dlc_7         = {4'd7};
            bins dlc_8         = {4'd8};
            bins dlc_illegal   = {[4'd9 : 4'd15]};
        }

        cp_tx_data_first_byte: coverpoint curr_item.tx_data[63:56] {
            bins all_zeros = {8'h00};
            bins all_ones  = {8'hFF};
            bins mid_val   = {[8'h01 : 8'hFE]};
        }

        cp_tx_data_last_byte: coverpoint curr_item.tx_data[7:0] {
            bins all_zeros = {8'h00};
            bins all_ones  = {8'hFF};
            bins mid_val   = {[8'h01 : 8'hFE]};
        }

        //cx_dlc_x_id: cross cp_tx_dlc, cp_tx_id;

    endgroup

    // CG2 – ACK / No-ACK Paths
    covergroup cg_ack_paths;

        cp_ack_req: coverpoint curr_item.ack_req {
            bins ack_requested    = {1'b1};
            bins no_ack_requested = {1'b0};
        }

        cp_tx_no_ack: coverpoint curr_item.tx_no_ack {
            bins ack_received = {1'b0};
            bins no_ack_seen  = {1'b1};
        }

        cp_tx_done: coverpoint curr_item.tx_done {
            bins frame_completed = {1'b1};
        }

        //cx_ack_req_x_no_ack: cross cp_ack_req, cp_tx_no_ack;

        cp_dlc_for_ack: coverpoint curr_item.tx_dlc {
            bins dlc_zero    = {4'd0};
            bins dlc_nonzero = {[4'd1 : 4'd8]};
        }

        //cx_ack_x_dlc: cross cp_ack_req, cp_dlc_for_ack;

    endgroup

    // CG3 – Back-to-Back
    covergroup cg_back2back;
  
        cp_consecutive_count: coverpoint consecutive_frame_count {
            bins any_burst = {[1:$]};
        }

        cp_id_transition: coverpoint curr_item.tx_id {
            //bins b2b_ids[] = {11'h111, 11'h112, 11'h113, 11'h114, 11'h115};
            bins id_low  = {[11'h000 : 11'h0FF]};
            bins id_mid  = {[11'h100 : 11'h5FF]};
            bins id_high = {[11'h600 : 11'h7FF]};
            bins other     = default;
        }

        cp_dlc_zero_b2b: coverpoint curr_item.tx_dlc {
            bins empty_frame    = {0};
            bins nonempty_frame = {[1:8]};
        }

        cp_ack_in_b2b: coverpoint curr_item.ack_req {
            bins acked     = {1'b1};
            bins not_acked = {1'b0};
        }

        cp_data_first_byte: coverpoint curr_item.tx_data[63:56] {
            bins all_zeros = {8'h00};
            bins all_ones  = {8'hFF};
            bins mid_val   = {[8'h01 : 8'hFE]};
        }

        cp_data_last_byte: coverpoint curr_item.tx_data[7:0] {
            bins all_zeros = {8'h00};
            bins all_ones  = {8'hFF};
            bins mid_val   = {[8'h01 : 8'hFE]};
        }
       
        cx_b2b_x_dlc: cross cp_consecutive_count, cp_dlc_zero_b2b {
            ignore_bins ignore_long =
                binsof(cp_consecutive_count.any_burst);
        }

        cx_b2b_x_ack: cross cp_ack_in_b2b, cp_dlc_zero_b2b {
            ignore_bins ignore_no_ack_empty =
                binsof(cp_ack_in_b2b.not_acked) &&
                binsof(cp_dlc_zero_b2b.empty_frame);
        }

    endgroup

    // CG4 – Bit Stuffing
    covergroup cg_bit_stuffing;

        cp_stuff_id: coverpoint curr_item.tx_id {
            bins all_zeros_id = {11'h000};   
            bins all_ones_id  = {11'h7FF};   
            bins other        = default;
        }

        cp_stuff_data: coverpoint curr_item.tx_data[63:56] {
            bins zeros_data = {8'h00};   
            bins ones_data  = {8'hFF};   
            bins other      = default;
        }

        //cx_stuff_scenario: cross cp_stuff_id, cp_stuff_data;

    endgroup

    // CG5 – DLC Sweep
    covergroup cg_dlc_sweep;

        cp_dlc_all: coverpoint curr_item.tx_dlc {
            bins legal_0  = {4'd0};
            bins legal_1  = {4'd1};
            bins legal_2  = {4'd2};
            bins legal_3  = {4'd3};
            bins legal_4  = {4'd4};
            bins legal_5  = {4'd5};
            bins legal_6  = {4'd6};
            bins legal_7  = {4'd7};
            bins legal_8  = {4'd8};
            bins illegal  = {[4'd9:4'd15]};
        }

        cp_dlc_outcome: coverpoint curr_item.tx_done {
            bins completed = {1'b1};
            bins not_done  = {1'b0};
        }

        cp_dlc_legal_flag: coverpoint curr_item.tx_dlc {
            bins legal   = {[4'd0:4'd8]};
            bins illegal = {[4'd9:4'd15]};
        }

        cx_dlc_legal_x_done: cross cp_dlc_legal_flag, cp_dlc_outcome {
            bins legal_completed   = binsof(cp_dlc_legal_flag.legal)   &&
                                     binsof(cp_dlc_outcome.completed);
            bins illegal_not_done  = binsof(cp_dlc_legal_flag.illegal) &&
                                     binsof(cp_dlc_outcome.not_done);

            ignore_bins legal_not_done   =
                binsof(cp_dlc_legal_flag.legal)   &&
                binsof(cp_dlc_outcome.not_done);

            ignore_bins illegal_complete =
                binsof(cp_dlc_legal_flag.illegal) &&
                binsof(cp_dlc_outcome.completed);
        }

    endgroup

    // Constructor
    function new(string name = "can_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_tx_frame_fields = new();
        cg_ack_paths       = new();
        cg_back2back       = new();
        cg_bit_stuffing    = new();
        cg_dlc_sweep       = new();
        consecutive_frame_count = 0;
        prev_item = null;
    endfunction

    // write()
    function void write(can_seq_item t);
        curr_item = t;
        consecutive_frame_count++;

        cg_tx_frame_fields.sample();
        cg_ack_paths.sample();
        cg_back2back.sample();
        cg_dlc_sweep.sample();

        if (curr_item.tx_id inside {11'h000, 11'h7FF})
            cg_bit_stuffing.sample();

        `uvm_info("COV", $sformatf(
            "Sampled frame #%0d | ID=0x%03X DLC=%0d ack_req=%0b tx_no_ack=%0b",
            consecutive_frame_count,
            curr_item.tx_id,
            curr_item.tx_dlc,
            curr_item.ack_req,
            curr_item.tx_no_ack), UVM_MEDIUM)

        prev_item = t;
    endfunction

    // report_phase
    function void report_phase(uvm_phase phase);
        real overall_cov;

        `uvm_info("COV", $sformatf(
            "\n=== Functional Coverage Summary ===\n  TX Frame Fields : %0.2f%%\n  ACK Paths       : %0.2f%%\n  Back-to-Back    : %0.2f%%\n  Bit Stuffing    : %0.2f%%\n  DLC Sweep       : %0.2f%%",
            cg_tx_frame_fields.get_coverage(),
            cg_ack_paths.get_coverage(),
            cg_back2back.get_coverage(),
            cg_bit_stuffing.get_coverage(),
            cg_dlc_sweep.get_coverage()),
            UVM_NONE)

        overall_cov = (cg_tx_frame_fields.get_coverage() +
                       cg_ack_paths.get_coverage() +
                       cg_back2back.get_coverage() +
                       cg_bit_stuffing.get_coverage() +
                       cg_dlc_sweep.get_coverage()) / 5.0;

        `uvm_info("COV", $sformatf(
            "\n========================================\n  Overall Functional Coverage : %0.2f%%\n========================================",
            overall_cov), UVM_NONE)

        if (overall_cov < 80.0)
            `uvm_warning("COV", $sformatf(
                "Overall coverage %0.2f%% is below 80%% target", overall_cov))

    endfunction

endclass
