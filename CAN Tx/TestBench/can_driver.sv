class can_driver extends uvm_driver #(can_seq_item);

    `uvm_component_utils(can_driver)

    virtual can_if vif;

    // Analysis port to send expected transactions to scoreboard
    uvm_analysis_port #(can_seq_item) drv_ap;

    // Constructor
    function new(string name = "can_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual can_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF",
                "can_driver: virtual interface not found")

        drv_ap = new("drv_ap", this);
    endfunction

    // Run Phase
    task run_phase(uvm_phase phase);

        can_seq_item req;

        // Initialize outputs
        vif.driver_cb.tx_start <= 1'b0;
        vif.driver_cb.tx_id    <= '0;
        vif.driver_cb.tx_dlc   <= '0;
        vif.driver_cb.tx_data  <= '0;
        vif.driver_cb.ack_req  <= 1'b0;
        vif.driver_cb.can_rx_i <= 1'b1;

        forever begin

            seq_item_port.get_next_item(req);

            drive_frame(req);

            seq_item_port.item_done();

        end

    endtask

    // Drive CAN Frame
    task drive_frame(can_seq_item req);

        int timeout;

        // Configure ACK behavior
        vif.driver_cb.ack_req <= req.ack_req;

        @(vif.driver_cb);

        // Wait until bus becomes idle
        timeout = 0;

        while (vif.can_rx_i === 1'b0 &&
               timeout < 2_000_000) begin

            @(posedge vif.clk);
            timeout++;

        end

        // Restore recessive bus state
        vif.driver_cb.can_rx_i <= 1'b1;

        // Wait for intermission_done
        timeout = 0;

        while (!vif.intermission_done &&
               timeout < 500_000) begin

            @(vif.driver_cb);
            timeout++;

        end

        if (timeout >= 500_000)
            `uvm_fatal("DRV_TIMEOUT",
                "Timed out waiting for intermission_done")

        @(vif.driver_cb);

        // Drive Frame Inputs
        vif.driver_cb.tx_id   <= req.tx_id;
        vif.driver_cb.tx_dlc  <= req.tx_dlc;
        vif.driver_cb.tx_data <= req.tx_data;

        // tx_start pulse
        vif.driver_cb.tx_start <= 1'b1;

        @(vif.driver_cb);

        vif.driver_cb.tx_start <= 1'b0;

        // Illegal DLC handling
        if (req.tx_dlc > 4'd8) begin

            `uvm_info("DRV",
                $sformatf(
                "Illegal DLC=%0d — using fixed wait",
                req.tx_dlc),
                UVM_MEDIUM)

            repeat(500)
                @(vif.driver_cb);

            // Capture DUT status
            req.tx_done   = vif.driver_cb.tx_done;
            req.tx_no_ack = vif.driver_cb.tx_no_ack;
            req.arb_lost  = vif.driver_cb.arb_lost;
            req.tx_error  = vif.driver_cb.tx_error;

            `uvm_info("DRV",
                $sformatf(
                "Illegal DLC result: tx_done=%0b tx_error=%0b",
                req.tx_done,
                req.tx_error),
                UVM_MEDIUM)

            // Send expected transaction to scoreboard
            drv_ap.write(req);

            return;
        end

        // Wait for tx_done or arbitration lost
        timeout = 0;

        while (!vif.driver_cb.tx_done &&
               !vif.driver_cb.arb_lost &&
               timeout < 500_000) begin

            @(vif.driver_cb);
            timeout++;

        end

        if (timeout >= 500_000)
            `uvm_fatal("DRV_TIMEOUT",
                "Timed out waiting for tx_done/arb_lost")

        // Capture DUT Response
        req.tx_done   = vif.driver_cb.tx_done;
        req.tx_no_ack = vif.driver_cb.tx_no_ack;
        req.arb_lost  = vif.driver_cb.arb_lost;
        req.tx_error  = vif.driver_cb.tx_error;

        // Driver Log
        `uvm_info("DRV",
            $sformatf(
            "Frame sent: ID=0x%03X DLC=%0d DATA=0x%016h ACK=%0b → done=%0b no_ack=%0b arb_lost=%0b",
            req.tx_id,
            req.tx_dlc,
            req.tx_data,
            req.ack_req,
            req.tx_done,
            req.tx_no_ack,
            req.arb_lost),
            UVM_MEDIUM)

        // Send Expected Transaction to Scoreboard
        drv_ap.write(req);

    endtask

endclass
