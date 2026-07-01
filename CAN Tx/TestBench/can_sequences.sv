// TC01 – FS-001: Randomized ACKed TX
class can_fs_tc_01 extends can_base_seq;
    `uvm_object_utils(can_fs_tc_01)


    function new(string name = "can_fs_tc_01");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_fs_tc_01: Randomized ACKed TX", UVM_MEDIUM)

      send_frame(11'h1AA, 4'd9,  64'hDE_AD_BE_EF_CA_FE_BA_BE, 1'b1,1'b1);

        `uvm_info("SEQ", "can_fs_tc_01 complete", UVM_MEDIUM)
    endtask

endclass


// TC02 – FS-002: No-ACK TX
class can_fs_tc_02 extends can_base_seq;
    `uvm_object_utils(can_fs_tc_02)

    function new(string name = "can_fs_tc_02");
        super.new(name);
    endfunction

    task body();
       // Frame A
        `uvm_info("SEQ", "Starting can_fs_tc_02: No-ACK TX", UVM_MEDIUM)

      send_frame(11'h045, 4'd1, 64'h5A00000000000000, 1'b0);
      
       // Frame B
        `uvm_info("SEQ", "Frame B: ID=0x7FF DLC=1 DATA=0xFF (dom->rec stuff)", UVM_MEDIUM)
       send_frame(11'h046, 4'd1, 64'h5B00000000000000, 1'b1);

        `uvm_info("SEQ", "can_fs_tc_02 complete", UVM_MEDIUM)
    endtask

endclass


// TC03 – FS-003: Back-to-Back / Intermission Gating
class can_fs_tc_03 extends can_base_seq;
    `uvm_object_utils(can_fs_tc_03)

    rand bit [10:0] rand_id;
    rand bit [3:0]  rand_dlc;
    rand bit [63:0] rand_data;
    bit [10:0]      fixed_id;

    constraint id_c {
        rand_id inside {[11'h100:11'h7FF]};
    }

    constraint dlc_c {
        rand_dlc inside {[0:8]};
    }

    constraint data_valid_c {
        if      (rand_dlc == 0) rand_data[63:0] == 64'h0;
        else if (rand_dlc == 1) rand_data[55:0] == 56'h0;
        else if (rand_dlc == 2) rand_data[47:0] == 48'h0;
        else if (rand_dlc == 3) rand_data[39:0] == 40'h0;
        else if (rand_dlc == 4) rand_data[31:0] == 32'h0;
        else if (rand_dlc == 5) rand_data[23:0] == 24'h0;
        else if (rand_dlc == 6) rand_data[15:0] == 16'h0;
        else if (rand_dlc == 7) rand_data[7:0]  == 8'h0;
    }

    function new(string name = "can_fs_tc_03");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_fs_tc_03: Back-to-Back / Intermission Gating", UVM_MEDIUM)

        repeat (10) begin
            assert(this.randomize())
                else `uvm_fatal("SEQ", "Randomization failed")
                  send_frame(rand_id, rand_dlc, rand_data, 1'b1,1'b1);
        end

        `uvm_info("SEQ", "can_fs_tc_03 complete", UVM_MEDIUM)
    endtask

endclass


// TC04 – FS-004: Bit Stuffing – Polarity and Fixed-Field Exclusion
class can_fs_tc_04 extends can_base_seq;
    `uvm_object_utils(can_fs_tc_04)

    function new(string name = "can_fs_tc_04");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_fs_tc_04: Bit Stuffing Polarity", UVM_MEDIUM)

        // Frame A: all-zeros → 5 consecutive recessive bits
        `uvm_info("SEQ", "Frame A: ID=0x000 DLC=1 DATA=0x00 (rec->dom stuff)", UVM_MEDIUM)
        send_frame(11'h000, 4'd1, 64'h0000000000000000, 1'b1, 1'b1);

        // Frame B: all-ones → 5 consecutive dominant bits
        `uvm_info("SEQ", "Frame B: ID=0x7FF DLC=1 DATA=0xFF (dom->rec stuff)", UVM_MEDIUM)
        send_frame(11'h7FF, 4'd1, 64'hFF00000000000000, 1'b1, 1'b1);

        `uvm_info("SEQ", "can_fs_tc_04 complete", UVM_MEDIUM)
    endtask

endclass


// TC05 – FS-005: DLC All Legal Values (0–8) + Illegal DLC=9,10
class can_fs_tc_05 extends can_base_seq;
    `uvm_object_utils(can_fs_tc_05)

    function new(string name = "can_fs_tc_05");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_fs_tc_05: DLC Sweep 0-8 + Illegal DLC=9,10", UVM_MEDIUM)

        for (int dlc = 0; dlc <= 8; dlc++) begin
            `uvm_info("SEQ", $sformatf("  DLC=%0d", dlc), UVM_MEDIUM)
            send_frame(11'h1AA, dlc[3:0], 64'hDE_AD_BE_EF_CA_FE_BA_BE, 1'b1,1'b1);
        end
      
        `uvm_info("SEQ", "  DLC=0 ", UVM_MEDIUM)
      send_frame(11'h1AA, 4'd0,  64'h0, 1'b1,1'b1);

        `uvm_info("SEQ", "  DLC=8", UVM_MEDIUM)
      send_frame(11'h1AA, 4'd8, 64'hDE_AD_BE_EF_CA_FE_BA_BE, 1'b1,1'b1);

        `uvm_info("SEQ", "  DLC=9 illegal ACKed", UVM_MEDIUM)
      send_frame(11'h1AA, 4'd9,  64'hDE_AD_BE_EF_CA_FE_BA_BE, 1'b1,1'b1);

        `uvm_info("SEQ", "  DLC=10 illegal no-ACK", UVM_MEDIUM)
      send_frame(11'h1AA, 4'd10, 64'hDE_AD_BE_EF_CA_FE_BA_BE, 1'b1,1'b1);

        `uvm_info("SEQ", "can_fs_tc_05 complete", UVM_MEDIUM)
    endtask

endclass


// TC06 – FS-006: ACK Slot – Valid ACK and ACK Error Paths
class can_fs_tc_06 extends can_base_seq;
    `uvm_object_utils(can_fs_tc_06)

    function new(string name = "can_fs_tc_06");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_fs_tc_06: ACK Slot Valid and Error Paths", UVM_MEDIUM)

        `uvm_info("SEQ", "Scenario A: ack_req=1 (ACK received)", UVM_MEDIUM)
        send_frame(11'h2A5, 4'd4, 64'hDE_AD_BE_EF_00_00_00_00, 1'b1);

        `uvm_info("SEQ", "Scenario B: ack_req=0 (No ACK — expect tx_no_ack)", UVM_MEDIUM)
        send_frame(11'h2A5, 4'd4, 64'hDE_AD_BE_EF_00_00_00_00, 1'b0);

        `uvm_info("SEQ", "can_fs_tc_06 complete", UVM_MEDIUM)
    endtask

endclass


// TC07 – BT-001: Bit-Time Accuracy and Segment Composition
class can_bt_tc_01 extends can_base_seq;
    `uvm_object_utils(can_bt_tc_01)

    function new(string name = "can_bt_tc_01");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_bt_tc_01: Bit-Time Accuracy", UVM_MEDIUM)

        send_frame(11'h100, 4'd2, 64'hA5_C3_00_00_00_00_00_00, 1'b1);
        send_frame(11'h200, 4'd2, 64'h5A_3C_00_00_00_00_00_00, 1'b1);
        send_frame(11'h300, 4'd4, 64'hDE_AD_BE_EF_00_00_00_00, 1'b1);
        send_frame(11'h600, 4'd1, 64'hAA_00_00_00_00_00_00_00, 1'b1);
        send_frame(11'h650, 4'd4, 64'hBB_CC_DD_EE_00_00_00_00, 1'b1);
        send_frame(11'h700, 4'd8, 64'hDE_AD_BE_EF_CA_FE_BA_BE, 1'b1);
        send_frame(11'h750, 4'd0, 64'h0,                        1'b1);

        `uvm_info("SEQ", "can_bt_tc_01 complete", UVM_MEDIUM)
    endtask

endclass


// TC08 – BT-002: Hard Synchronization on SOF Edge
class can_bt_tc_02 extends can_base_seq;
    `uvm_object_utils(can_bt_tc_02)

    function new(string name = "can_bt_tc_02");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_bt_tc_02: Hard Synchronization on SOF Edge", UVM_MEDIUM)

        `uvm_info("SEQ", "Frame 1: observe hard_sync/sof_detect on SOF", UVM_MEDIUM)
        send_frame(11'h3C0, 4'd2, 64'hAA_BB_00_00_00_00_00_00, 1'b1);

        `uvm_info("SEQ", "Frame 2: verify only one hard_sync per frame", UVM_MEDIUM)
        send_frame(11'h3C1, 4'd2, 64'hCC_DD_00_00_00_00_00_00, 1'b1);

        `uvm_info("SEQ", "can_bt_tc_02 complete", UVM_MEDIUM)
    endtask

endclass


// TC09 – BT-003: CSMA – No TX While Bus Is Active
class can_bt_tc_03 extends can_base_seq;
    `uvm_object_utils(can_bt_tc_03)

    virtual can_if vif;

    function new(string name = "can_bt_tc_03");
        super.new(name);
    endfunction

    task body();
        can_seq_item item;

        `uvm_info("SEQ", "Starting can_bt_tc_03: CSMA No TX While Bus Active", UVM_MEDIUM)

        if (!uvm_config_db#(virtual can_if)::get(null, "uvm_test_top.*", "vif", vif))
            `uvm_fatal("NO_VIF", "can_bt_tc_03: vif not found")

        `uvm_info("SEQ", "Holding bus dominant to simulate active frame", UVM_MEDIUM)
        vif.driver_cb.can_rx_i <= 1'b0;

        item         = can_seq_item::type_id::create("item");
        item.tx_id   = 11'h080;
        item.tx_dlc  = 4'd2;
        item.tx_data = 64'hBE_EF_00_00_00_00_00_00;
        item.ack_req = 1'b1;

        repeat(50 * 20) @(vif.driver_cb);
        `uvm_info("SEQ", "Releasing bus to recessive (bus idle)", UVM_MEDIUM)
        vif.driver_cb.can_rx_i <= 1'b1;

        start_item(item);
        finish_item(item);

        `uvm_info("SEQ", "can_bt_tc_03 complete", UVM_MEDIUM)
    endtask

endclass


// TC10 – BT-004: Sample Point Position Across Segment Configs
class can_bt_tc_04 extends can_base_seq;
    `uvm_object_utils(can_bt_tc_04)

    function new(string name = "can_bt_tc_04");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_bt_tc_04: Sample Point Position", UVM_MEDIUM)

        `uvm_info("SEQ", "C1: ID=0x010 DLC=1 DATA=0xA5", UVM_MEDIUM)
        send_frame(11'h010, 4'd1, 64'hA5_00_00_00_00_00_00_00, 1'b1);

        `uvm_info("SEQ", "C2: ID=0x020 DLC=1 DATA=0x5A", UVM_MEDIUM)
        send_frame(11'h020, 4'd1, 64'h5A_00_00_00_00_00_00_00, 1'b1);

        `uvm_info("SEQ", "C3: ID=0x030 DLC=1 DATA=0xFF", UVM_MEDIUM)
        send_frame(11'h030, 4'd1, 64'hFF_00_00_00_00_00_00_00, 1'b1);

        `uvm_info("SEQ", "can_bt_tc_04 complete", UVM_MEDIUM)
    endtask

endclass

// TC12 – BT-005: Bus Idle Detection – 3 Recessive Bits
class can_bt_tc_05 extends can_base_seq;
    `uvm_object_utils(can_bt_tc_05)

    virtual can_if vif;

    function new(string name = "can_bt_tc_05");
        super.new(name);
    endfunction

    task body();

        `uvm_info("SEQ",
            "Starting can_bt_tc_05: Bus Idle Detection – 3 Recessive Bits",
            UVM_MEDIUM)

        // Get virtual interface
        if (!uvm_config_db #(virtual can_if)::get(
                null,
                "uvm_test_top.*",
                "vif",
                vif))
            `uvm_fatal("NO_VIF",
                "can_bt_tc_05: vif not found")

        // Step 1 : Force dominant bit
        `uvm_info("SEQ",
            "Driving dominant bus → bus_idle should deassert",
            UVM_MEDIUM)

        vif.driver_cb.can_rx_i <= 1'b0;   // dominant
        repeat(20) @(vif.driver_cb);      // 1 bit time

        // Step 2 : Release to recessive
        `uvm_info("SEQ",
            "Driving 3 recessive bits → bus_idle should assert",
            UVM_MEDIUM)

        vif.driver_cb.can_rx_i <= 1'b1;   // recessive
        repeat(3 * 20) @(vif.driver_cb);  // 3 bit times

        // Step 3 : Drive dominant again
        `uvm_info("SEQ",
            "Driving dominant bit again → bus_idle should drop",
            UVM_MEDIUM)

        vif.driver_cb.can_rx_i <= 1'b0;
        repeat(20) @(vif.driver_cb);

        // Step 4 : Release bus
        vif.driver_cb.can_rx_i <= 1'b1;

        // Step 5 : Send normal frame
        `uvm_info("SEQ",
            "Send frame after idle detection",
            UVM_MEDIUM)
      
        send_frame(11'h123, 4'd2, 64'hA5_5A_00_00_00_00_00_00, 1'b1);
     
        `uvm_info("SEQ","can_bt_tc_05 complete", UVM_MEDIUM)

    endtask

endclass


// TC11 – CRC-001: CRC-15 Full Random Frame
class can_crc_tc_01 extends can_base_seq;
    `uvm_object_utils(can_crc_tc_01)

    rand bit [10:0] rand_id;
    rand bit [3:0]  rand_dlc;
    rand bit [63:0] rand_data;

    constraint id_c {
        rand_id inside {[11'h000 : 11'h7FF]};
    }

    constraint dlc_c {
        rand_dlc inside {[0:8]};
    }

    constraint data_valid_c {
        if      (rand_dlc == 0) rand_data[63:0] == 64'h0;
        else if (rand_dlc == 1) rand_data[55:0] == 56'h0;
        else if (rand_dlc == 2) rand_data[47:0] == 48'h0;
        else if (rand_dlc == 3) rand_data[39:0] == 40'h0;
        else if (rand_dlc == 4) rand_data[31:0] == 32'h0;
        else if (rand_dlc == 5) rand_data[23:0] == 24'h0;
        else if (rand_dlc == 6) rand_data[15:0] == 16'h0;
        else if (rand_dlc == 7) rand_data[7:0]  == 8'h0;
    }
 
    function new(string name = "can_crc_tc_01");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting can_crc_tc_01: CRC-15 Full Random Frame", UVM_MEDIUM)

        repeat (20) begin
            assert(this.randomize())
                else `uvm_fatal("SEQ", "CRC sequence randomization failed")

            `uvm_info("SEQ",
                $sformatf("CRC Frame: ID=0x%03X DLC=%0d DATA=0x%016h",
                rand_id, rand_dlc, rand_data),
                UVM_MEDIUM)

            send_frame(rand_id, rand_dlc, rand_data, 1'b1, 1'b1);
        end

        `uvm_info("SEQ", "can_crc_tc_01 complete", UVM_MEDIUM)
    endtask

endclass  

class can_crc_tc_02 extends can_base_seq;
    `uvm_object_utils(can_crc_tc_02)

    function new(string name = "can_crc_tc_02");
        super.new(name);
    endfunction

    task body();

        `uvm_info("SEQ",
            "Starting can_crc_tc_02: Stuff Bit at CRC Boundary",
            UVM_MEDIUM)

        // Long dominant/recessive runs
        // High chance stuffing continues near CRC field

        send_frame(
            11'h7FF,                         // all 1s ID
            4'd8,                           // full payload
            64'hFF_FF_FF_FF_FF_FF_FF_FF,    // long repeated 1s
            1'b1,                           // ACK
            1'b1                            // CRC check
        );

        // opposite polarity case
        send_frame(
            11'h000,
            4'd8,
            64'h00_00_00_00_00_00_00_00,
            1'b1,
            1'b1
        );

        `uvm_info("SEQ",
            "can_crc_tc_02 complete",
            UVM_MEDIUM)

    endtask
endclass

class can_idle_tc extends can_base_seq;
    `uvm_object_utils(can_idle_tc)

    function new(string name="can_idle_tc");
        super.new(name);
    endfunction

    task body();

        `uvm_info("SEQ",
            "Staying idle",
            UVM_MEDIUM)

        #100us;

    endtask
endclass
