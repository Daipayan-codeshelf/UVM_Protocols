class can_monitor extends uvm_monitor;

    `uvm_component_utils(can_monitor)

    virtual can_if vif;

    uvm_analysis_port #(can_seq_item) ap;

    // Timing statistics
    time last_bit_tick_time;
    time bit_period_measured;

    int sof_detect_count;
    int sample_point_count;

    bit prev_bus_idle;
    bit in_idle_window;

    // Constructor
    function new(string name = "can_monitor",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    // Build Phase
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        ap = new("ap", this);

        if(!uvm_config_db #(virtual can_if)::get(
            this, "", "vif", vif))

            `uvm_fatal("NO_VIF",
                "can_monitor: virtual interface not found")

        last_bit_tick_time  = 0;
        bit_period_measured = 0;

        sof_detect_count    = 0;
        sample_point_count  = 0;

        prev_bus_idle       = 0;

    endfunction

    // Run Phase
    task run_phase(uvm_phase phase);

        fork
            monitor_frames();
            monitor_bit_timing();
            monitor_bus_idle();
        join_none

    endtask

    // Frame Monitor
task monitor_frames();

    logic [10:0] tx_id_s;
    logic [3:0]  tx_dlc_s;
    logic [63:0] tx_data_s;
    logic        ack_req_s;

    forever begin

        can_seq_item obs;

        // Wait for tx_start
        @(vif.monitor_cb iff
          vif.monitor_cb.tx_start === 1'b1);

        // Capture stimulus IMMEDIATELY
        tx_id_s   = vif.monitor_cb.tx_id;
        tx_dlc_s  = vif.monitor_cb.tx_dlc;
        tx_data_s = vif.monitor_cb.tx_data;
        ack_req_s = vif.monitor_cb.ack_req;

        obs = can_seq_item::type_id::create("obs");

        // Store stable copies
        obs.tx_id   = tx_id_s;
        obs.tx_dlc  = tx_dlc_s;
        obs.tx_data = tx_data_s;
        obs.ack_req = ack_req_s;

        // Illegal DLC
        if(obs.tx_dlc > 4'd8) begin

            repeat(500)
                @(vif.monitor_cb);

            obs.tx_done   = vif.monitor_cb.tx_done;
            obs.tx_no_ack = vif.monitor_cb.tx_no_ack;
            obs.arb_lost  = vif.monitor_cb.arb_lost;
            obs.tx_error  = vif.monitor_cb.tx_error;

            `uvm_info("MON",
                $sformatf(
                "Illegal DLC=%0d: tx_done=%0b",
                obs.tx_dlc,
                obs.tx_done),
                UVM_MEDIUM)

            ap.write(obs);

            continue;

        end

        // Wait for completion
        @(vif.monitor_cb iff
          vif.monitor_cb.tx_done === 1'b1 ||
          vif.monitor_cb.arb_lost === 1'b1);

        // Capture DUT outputs
        obs.tx_done   = vif.monitor_cb.tx_done;
        obs.tx_no_ack = vif.monitor_cb.tx_no_ack;
        obs.arb_lost  = vif.monitor_cb.arb_lost;
        obs.tx_error  = vif.monitor_cb.tx_error;

        // Capture CRC DIRECTLY from interface
        obs.act_crc = vif.tx_crc;

        `uvm_info("MON",
            $sformatf(
            "Observed: ID=0x%03X DLC=%0d CRC=0x%04h no_ack=%0b arb_lost=%0b tx_error=%0b",
            obs.tx_id,
            obs.tx_dlc,
            obs.act_crc,
            obs.tx_no_ack,
            obs.arb_lost,
            obs.tx_error),
            UVM_MEDIUM)

        ap.write(obs);

    end

endtask
    // Bit Timing Monitor
    task monitor_bit_timing();

        forever begin

            @(posedge vif.clk);

            if(vif.bit_tick === 1'b1) begin

                if(last_bit_tick_time != 0) begin

                    bit_period_measured =
                        $time - last_bit_tick_time;

                    `uvm_info("MON",
                        $sformatf(
                        "bit_tick period=%0t",
                        bit_period_measured),
                        UVM_HIGH)

                end

                last_bit_tick_time = $time;

            end

            // SOF detect
            if(vif.sof_detect === 1'b1) begin

                sof_detect_count++;

                `uvm_info("MON",
                    $sformatf(
                    "sof_detect pulse #%0d at %0t",
                    sof_detect_count,
                    $time),
                    UVM_HIGH)

            end

            // Sample point
            if(vif.sample_point === 1'b1) begin

                sample_point_count++;

            end

        end

    endtask

    // Bus Idle Monitor
    task monitor_bus_idle();

        prev_bus_idle = 0;
        in_idle_window = 0;

        forever begin

            @(posedge vif.clk);

            if(vif.bus_idle === 1'b1 &&
               prev_bus_idle === 1'b0) begin

                if(!in_idle_window) begin

                    `uvm_info("MON",
                        $sformatf(
                        "bus_idle ROSE at %0t",
                        $time),
                        UVM_MEDIUM)

                    in_idle_window = 1;

                end
            end

            if(vif.tx_start === 1'b1)
                in_idle_window = 0;

            prev_bus_idle = vif.bus_idle;

        end

    endtask
    // Report
    function void report_phase(uvm_phase phase);

        `uvm_info("MON",
            $sformatf(
            "\n=== Monitor Summary ===\nSOF Pulses=%0d\nSample Points=%0d\nLast Bit Period=%0t",
            sof_detect_count,
            sample_point_count,
            bit_period_measured),
            UVM_NONE)

    endfunction

endclass
