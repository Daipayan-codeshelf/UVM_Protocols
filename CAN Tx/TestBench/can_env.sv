
class can_env extends uvm_env;

    `uvm_component_utils(can_env)

    can_agent      agent;
    can_scoreboard scoreboard;
    can_coverage   coverage;

    // Constructor
    function new(string name = "can_env",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    // Build Phase
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent      = can_agent::type_id::create(
                        "agent", this);

        scoreboard = can_scoreboard::type_id::create(
                        "scoreboard", this);

        coverage   = can_coverage::type_id::create(
                        "coverage", this);

    endfunction

    // Connect Phase
    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        // Driver → Scoreboard Expected Path
        agent.drv_ap.connect(
            scoreboard.exp_export);

        // Monitor → Scoreboard Actual Path
        agent.mon_ap.connect(
            scoreboard.act_export);

        // Monitor → Coverage
        agent.mon_ap.connect(
            coverage.analysis_export);

    endfunction

endclass

