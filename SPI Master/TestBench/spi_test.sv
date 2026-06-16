`ifndef SPI_TEST_SV
`define SPI_TEST_SV

class spi_base_test extends uvm_test;
    `uvm_component_utils(spi_base_test)
    spi_env        env;
    virtual spi_if vif;

    function new(string name="spi_base_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("TEST", "Cannot get virtual interface")
    endfunction

    task wait_for_reset();
        @(posedge vif.clk);
        while (vif.rst_n === 1'b0) @(posedge vif.clk);
        repeat(5) @(posedge vif.clk);
        `uvm_info("TEST", "Reset complete", UVM_LOW)
    endtask
endclass


class spi_random_test extends spi_base_test;
    `uvm_component_utils(spi_random_test)

    function new(string name="spi_random_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction


    task run_phase(uvm_phase phase);
        spi_base_seq seq;
          spi_load_to_idle_seq      load_abort_seq;   // ADD THIS
    spi_start_to_idle_seq     start_abort_seq;
        bit [5:0] all_frames[5] = '{4, 8, 16, 24, 32};

        phase.raise_objection(this);
  wait_for_reset();
// -----------------------------------------------------------------
    // PHASE 0: FSM abort transitions
    // Hits LOAD->IDLE and START->IDLE by asserting cs_release in the
    // exact cycle the FSM occupies each single-cycle state.
    // Must run before Phase 1 so the FSM is in a clean IDLE state.
    // -----------------------------------------------------------------
    `uvm_info("TEST", "===== PHASE 0 : FSM ABORT TRANSITIONS =====", UVM_NONE)

    repeat(3) begin
        load_abort_seq = spi_load_to_idle_seq::type_id::create("load_abort");
        load_abort_seq.start(env.agent.sequencer);
    end

    repeat(3) begin
        start_abort_seq = spi_start_to_idle_seq::type_id::create("start_abort");
        start_abort_seq.start(env.agent.sequencer);
    end
          // -----------------------------------------------------------------
        // PHASE 1: SMOKE — n=1..3, hits tx_empty=1 and rx_empty=1 naturall
        // -----------------------------------------------------------------
        // PHASE 1: SMOKE — n=1..3, hits tx_empty=1 and rx_empty=1 naturally
        // (FIFO starts empty, drains after single frame)
        // Sweeps all frame sizes and CPOL/CPHA modes.
        // -----------------------------------------------------------------
        `uvm_info("TEST", "===== PHASE 1 : SMOKE / EMPTY FLAGS =====", UVM_NONE)
        foreach (all_frames[i]) begin
            seq = spi_base_seq::type_id::create("smoke_seq");
            assert(seq.randomize() with {
                n          == 1;
                cs_hold    == 0;
                 clk_div    inside {[0:48]};

                frame_size == all_frames[i];
            }) else `uvm_fatal("RAND","smoke failed")
            seq.start(env.agent.sequencer);
        end
        // Random extras for CLK_DIV mid/high bins and mode sweep
        repeat(20) begin
            seq = spi_base_seq::type_id::create("smoke_rnd");
            assert(seq.randomize() with {
                n inside {[1:16]};
                                          
                    cs_hold == 0;
                 clk_div    inside {[0:48]};

            }) else `uvm_fatal("RAND","smoke rnd failed")
            seq.start(env.agent.sequencer);
        end

        // -----------------------------------------------------------------
        // PHASE 2: CS HOLD / RELEASE — n=2..4, all frame sizes
        // Closes PROTOCOL_CROSS bins for hold=1 × release=0 and release=1
        // -----------------------------------------------------------------
        `uvm_info("TEST", "===== PHASE 2 : CS HOLD + RELEASE =====", UVM_NONE)
        foreach (all_frames[i]) begin
            // hold=1, release=0
            seq = spi_base_seq::type_id::create("hold_seq");
            assert(seq.randomize() with {
                n          inside {[2:4]};
                cs_hold    == 1;
                 clk_div    inside {[0:48]};

                frame_size == all_frames[i];
            }) else `uvm_fatal("RAND","hold failed")
            seq.force_cs_release = 0;
            seq.start(env.agent.sequencer);

            // hold=1, release=1
            seq = spi_base_seq::type_id::create("rel_seq");
            assert(seq.randomize() with {
                n          inside {[2:4]};
                cs_hold    == 1;
                 clk_div    inside {[0:48]};

                frame_size == all_frames[i];
            }) else `uvm_fatal("RAND","release failed")
            seq.force_cs_release = 1;
            seq.start(env.agent.sequencer);
        end

        // -----------------------------------------------------------------
        // PHASE 3: FIFO FILL — n==16 (exact FIFO depth), slow SPI clock
        //
        // WHY n must be exactly 16:
    //   The RX FIFO is 16 entries deep. n=14 or n=15 never fills it,
        //   so rx_full never asserts. Only n==16 guarantees rx_full=1.
        //
        // WHY clk_div must be slow (>=32):
        //   The driver waits total_wait = n*(fs*2+10)*clk_div + 500 cycles
        //   before draining RX. With a fast clock (clk_div=8) and fs=8:
        //     total_wait = 16*(16+10)*8 + 500 = 3828 + 500 = 4328 cycles
        //   The +500 pad sounds large but the monitor's fork also waits
        //   (clk_div*2)+4 = 20 cycles per frame. With clk_div=32 and fs=8:
        //     total_wait = 16*(16+10)*32 + 500 = 13312 + 500 = 13812 cycles
        //   This gives the monitor_rx_full_flag task plenty of APB cycles
        //   while rx_full=1 is asserted before any drain starts.
        // -----------------------------------------------------------------
        `uvm_info("TEST", "===== PHASE 3 : FIFO FILL (tx_full / rx_full) =====", UVM_NONE)
        repeat(10) begin
            seq = spi_base_seq::type_id::create("fill_seq");
            assert(seq.randomize() with {
                n          == 16;          // MUST be 16: exact FIFO depth
                cs_hold    == 1;
                frame_size inside {4, 8, 16, 24, 32};
                clk_div    inside {[32:64]}; // slow SPI keeps rx_full asserted
            }) else `uvm_fatal("RAND","fill failed")
            seq.start(env.agent.sequencer);
        end

        // -----------------------------------------------------------------
        // PHASE 4: TX OVERFLOW — n=17..20, fast clock
        // Writing 17-20 entries into a 16-deep FIFO → tx_overflow=1.
        // Extra reads beyond what completed → rx_underflow=1.
        // Fast clock (clk_div=2..6) so the burst outpaces the SPI bus.
        // -----------------------------------------------------------------
        `uvm_info("TEST", "===== PHASE 4 : TX OVERFLOW / RX UNDERFLOW =====", UVM_NONE)
        repeat(20) begin
            seq = spi_base_seq::type_id::create("ovf_seq");
            assert(seq.randomize() with {
                n          inside {[17:20]};
                cs_hold    == 1;
                frame_size inside {4, 8, 16, 24, 32};
                clk_div    inside {[0:48]};
            }) else `uvm_fatal("RAND","overflow failed")
            seq.force_cs_release = 1;
            seq.start(env.agent.sequencer);
                                                         
             end
  // RX_UNDERFLOW + ERR_CLR
           repeat(5) begin
          seq = spi_base_seq::type_id::create("udf_errclr");
          assert(seq.randomize() with {
              n inside {[17:20]};
              cs_hold    == 0;

              frame_size == 8;
              clk_div    inside {[0:4]};
          }) else `uvm_fatal("RAND","udf errclr")

          seq.force_err_clr = $urandom_range(0,1);
          seq.start(env.agent.sequencer);
           end

        // -----------------------------------------------------------------
        // PHASE 5: RX UNDERFLOW explicit — n=1, immediately read RX twice
        // Force rx_underflow by issuing two RX reads after a single frame.
        // The second read sees an empty FIFO → rx_underflow=1.
        // Achieved by n=1 with cs_hold=0 (single frame), then the driver's
        // second n RX read loop on the already-drained FIFO triggers it.
        // Use n=2 here but write only 1 TX entry via a directed tx_data.
        // Simplest: just rely on Phase 4 overflow bursts — the n>16 writes
        // mean only 16 RX entries exist but driver reads n=17-20 times.
        // This phase adds a clean explicit underflow case with n=2, hold=0.
        // -----------------------------------------------------------------
        `uvm_info("TEST", "===== PHASE 5 : EXPLICIT RX UNDERFLOW =====", UVM_NONE)
        repeat(20) begin
            seq = spi_base_seq::type_id::create("udf_seq");
            assert(seq.randomize() with {
                n       == 2;   // write 2 to TX, but DUT may only complete 1
               cs_hold == 0;
                clk_div inside {[0:16]};  // fast: 2nd frame may not finish
                frame_size inside {4, 8, 16, 24,32};
            }) else `uvm_fatal("RAND","underflow failed")
            seq.start(env.agent.sequencer);
        end
// -----------------------------------------------------------------
// -----------------------------------------------------------------
        // PHASE 7: ERR_CLR exercise
        // -----------------------------------------------------------------
        `uvm_info("TEST", "===== PHASE 7 : ERR_CLR =====", UVM_NONE)
        repeat(20) begin
            seq = spi_base_seq::type_id::create("erclr_seq");
            assert(seq.randomize() with {
                n          inside {[1:4]};
         clk_div    inside {[0:48]};

                frame_size inside {4 ,8, 16, 24, 32};
            }) else `uvm_fatal("RAND","err_clr phase failed")

            // Randomly test the error clear
            seq.force_err_clr = $urandom_range(0,1);
            seq.start(env.agent.sequencer);
        end


        // TX_OVERFLOW + ERR_CLR
          repeat(4) begin
                  seq = spi_base_seq::type_id::create("ovf_errclr");
          assert(seq.randomize() with {
              n          == 20;
              cs_hold    == 1;

              frame_size == 8;
              clk_div    inside {[0:6]};
          }) else `uvm_fatal("RAND","ovf errclr")

          seq.force_err_clr = $urandom_range(0,1);
          seq.start(env.agent.sequencer);
          end

repeat(10) begin
                  seq = spi_base_seq::type_id::create("clk");
          assert(seq.randomize() with {
              n          == 20;
              cs_hold    == 1;

              frame_size == 8;
   clk_div    inside {[64:65535]};
          }) else `uvm_fatal("RAND","clk_err")


          seq.start(env.agent.sequencer);
          end


repeat(20) @(posedge vif.clk);
`uvm_info("TEST", "===== PHASE 7 COMPLETE =====", UVM_NONE)
        repeat(20) @(posedge vif.clk);
        `uvm_info("TEST", "===== REGRESSION COMPLETE =====", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass


`endif

                               
