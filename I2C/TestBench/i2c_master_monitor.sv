class i2c_master_monitor extends uvm_monitor;

    `uvm_component_utils(i2c_master_monitor)

    virtual i2c_if vif;
    uvm_analysis_port #(i2c_seq_item) ap;
    int master_id;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);

        if(!uvm_config_db #(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "vif not found")

        if(!uvm_config_db #(int)::get(this, "", "master_id", master_id))
            `uvm_fatal("NO_MID", "master_id not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            collect_transaction();
        end
    endtask

    task collect_transaction();

        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("mon_item");

        @(posedge vif.clk);

        if(master_id == 1) begin

            while(!vif.m1_busy)
                @(posedge vif.clk);

          while(!vif.m1_done && !vif.m1_arb_lost  &&
      !vif.m1_nack_error)
                @(posedge vif.clk);

            item.addr     = vif.m1_addr;
          	item.speed_sel = vif.m1_speed_sel;
            item.reg_addr = vif.m1_reg_addr;
            item.rep_start = vif.m1_rep_start;
            item.rw       = vif.m1_rw;
            item.data_in  = vif.m1_data_in;
            item.data_out = vif.m1_data_out;
            item.done     = vif.m1_done;
            item.arb_lost = vif.m1_arb_lost;
            item.nack_error = vif.m1_nack_error;

        end else begin

            while(!vif.m2_busy)
                @(posedge vif.clk);

          while(!vif.m2_done && !vif.m2_arb_lost  &&
      !vif.m2_nack_error)
                @(posedge vif.clk);

            item.addr     = vif.m2_addr;
          	item.speed_sel = vif.m2_speed_sel;
            item.reg_addr = vif.m2_reg_addr;
            item.rw       = vif.m2_rw;
            item.rep_start = vif.m2_rep_start;
            item.data_in  = vif.m2_data_in;
            item.data_out = vif.m2_data_out;
            item.done     = vif.m2_done;
            item.arb_lost = vif.m2_arb_lost;
            item.nack_error = vif.m2_nack_error;

        end

        `uvm_info("MON", "------------------------------------------------------------", UVM_NONE)
        `uvm_info("MON", $sformatf("MONITOR M%0d CAPTURED TRANSACTION", master_id), UVM_NONE)
        `uvm_info("MON", $sformatf("TYPE     : %s", item.rw ? "READ" : "WRITE"), UVM_NONE)
        `uvm_info("MON", $sformatf("SLAVE    : 0x%0h", item.addr), UVM_NONE)
        `uvm_info("MON", $sformatf("REGISTER : 0x%0h", item.reg_addr), UVM_NONE)
      	`uvm_info("MON", $sformatf("SPEED    : %0b", item.speed_sel), UVM_NONE)

        if(item.rw)
            `uvm_info("MON", $sformatf("READ DATA  : 0x%0h", item.data_out), UVM_NONE)
        else
            `uvm_info("MON", $sformatf("WRITE DATA : 0x%0h", item.data_in), UVM_NONE)

        `uvm_info("MON", $sformatf("DONE     : %0b", item.done), UVM_NONE)
        `uvm_info("MON", $sformatf("ARB_LOST : %0b", item.arb_lost), UVM_NONE)
        `uvm_info("MON", $sformatf("NACK_ERR : %0b", item.nack_error), UVM_NONE)
        `uvm_info("MON", "------------------------------------------------------------", UVM_NONE)

        ap.write(item);
      
      if(master_id == 1) begin
        while(vif.m1_busy)
          @(posedge vif.clk);
      end else begin
        while(vif.m2_busy)
          @(posedge vif.clk);
      end

    endtask

endclass
