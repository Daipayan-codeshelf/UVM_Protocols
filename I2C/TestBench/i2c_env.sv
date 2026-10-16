class i2c_env extends uvm_env;

    `uvm_component_utils(i2c_env)

    i2c_master_agent master_agent_m1;
    i2c_master_agent master_agent_m2;
    i2c_scoreboard   scoreboard;
    i2c_coverage     coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // push master_id before creating each agent
        // agent passes it down to driver and monitor
        uvm_config_db #(int)::set(
            this, "master_agent_m1*", "master_id", 1);

        master_agent_m1 =
            i2c_master_agent::type_id::create(
                "master_agent_m1", this);

        uvm_config_db #(int)::set(
            this, "master_agent_m2*", "master_id", 2);

        master_agent_m2 =
            i2c_master_agent::type_id::create(
                "master_agent_m2", this);

        scoreboard =
            i2c_scoreboard::type_id::create(
                "scoreboard", this);

        coverage =
            i2c_coverage::type_id::create(
                "coverage", this);

    endfunction

    function void connect_phase(uvm_phase phase);

        // M1 monitor → scoreboard and coverage
        master_agent_m1.ap.connect(
            scoreboard.m1_imp);
        master_agent_m1.ap.connect(
            coverage.analysis_export);

        // M2 monitor → scoreboard
        master_agent_m2.ap.connect(
            scoreboard.m2_imp);

    endfunction

endclass
