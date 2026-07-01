
class can_agent extends uvm_agent;

    `uvm_component_utils(can_agent)

    can_driver     driver;
    can_monitor    monitor;
    can_sequencer  sequencer;

    // Monitor output → actual transactions
    uvm_analysis_port #(can_seq_item) mon_ap;

    // Driver output → expected transactions
    uvm_analysis_port #(can_seq_item) drv_ap;

    function new(string name = "can_agent",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    // Build Phase
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        driver    = can_driver::type_id::create("driver", this);
        monitor   = can_monitor::type_id::create("monitor", this);
        sequencer = can_sequencer::type_id::create("sequencer", this);

        mon_ap = new("mon_ap", this);
        drv_ap = new("drv_ap", this);

    endfunction

    // Connect Phase
    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        // Driver ↔ Sequencer
        driver.seq_item_port.connect(sequencer.seq_item_export);

        // Monitor → Agent analysis port
        monitor.ap.connect(mon_ap);

        // Driver → Agent analysis port
        driver.drv_ap.connect(drv_ap);

    endfunction

endclass
