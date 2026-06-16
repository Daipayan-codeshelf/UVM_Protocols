`ifndef SPI_ENV_SV
`define SPI_ENV_SV

class spi_env extends uvm_env;

    `uvm_component_utils(spi_env)

    spi_agent      agent;
    spi_scoreboard scoreboard;
    spi_coverage   coverage;

    function new(string name="spi_env",
                 uvm_component parent=null);

        super.new(name,parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent = spi_agent::type_id::create(
                    "agent", this);

        scoreboard = spi_scoreboard::type_id::create(
                        "scoreboard", this);

        coverage = spi_coverage::type_id::create(
                        "coverage", this);

    endfunction


    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        // Monitor → Scoreboard
        agent.monitor.ap.connect(
            scoreboard.analysis_export);

        // Monitor → Coverage
        agent.monitor.ap.connect(
            coverage.analysis_export);

    endfunction

endclass

`endif
