class i2c_master_driver extends uvm_driver #(i2c_seq_item);

    `uvm_component_utils(i2c_master_driver)

    virtual i2c_if vif;
    int master_id;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "vif not found")

        if(!uvm_config_db #(int)::get(this, "", "master_id", master_id))
            `uvm_fatal("NO_MID", "master_id not found")
    endfunction

    task run_phase(uvm_phase phase);
        i2c_seq_item item;

        forever begin
            seq_item_port.get_next_item(item);
            drive(item);
            seq_item_port.item_done();
        end
    endtask

    task drive(i2c_seq_item item);
        if(master_id == 1)
            drive_m1(item);
        else
            drive_m2(item);
    endtask

    task drive_m1(i2c_seq_item item);

        `uvm_info("DRV", "============================================================", UVM_NONE)
        `uvm_info("DRV", $sformatf("MASTER 1 %s TRANSACTION", item.rw ? "READ" : "WRITE"), UVM_NONE)
        `uvm_info("DRV", $sformatf("SLAVE    : 0x%0h", item.addr), UVM_NONE)
        `uvm_info("DRV", $sformatf("REGISTER : 0x%0h", item.reg_addr), UVM_NONE)
      `uvm_info("DRV", $sformatf("SPEED    : %0b", item.speed_sel), UVM_NONE)
      
        if(item.rw == 0)
            `uvm_info("DRV", $sformatf("WRITE DATA : 0x%0h", item.data_in), UVM_NONE)
        `uvm_info("DRV", "============================================================", UVM_NONE)

        @(posedge vif.clk);

        vif.m1_addr     <= item.addr;
        vif.m1_reg_addr <= item.reg_addr;
        vif.m1_rep_start <= item.rep_start;
        vif.m1_rw       <= item.rw;
        vif.m1_data_in  <= item.data_in;
      	vif.m1_speed_sel <= item.speed_sel;
        vif.m1_start    <= 1;

        @(posedge vif.clk);

        while(!vif.m1_busy)
            @(posedge vif.clk);

        vif.m1_start <= 0;

      while(!vif.m1_done && !vif.m1_arb_lost && !vif.m1_nack_error)
            @(posedge vif.clk);

        item.done     = vif.m1_done;
        item.arb_lost = vif.m1_arb_lost;
        item.data_out = vif.m1_data_out;
        item.nack_error = vif.m1_nack_error;
      
      while(vif.m1_busy)
        @(posedge vif.clk);

       if(item.arb_lost) begin
         `uvm_info("DRV", "MASTER 1 RESULT : ARBITRATION LOST", UVM_NONE)
       end else if(item.nack_error) begin
         `uvm_info("DRV", "MASTER 1 RESULT : NACK ERROR", UVM_NONE)
       end else if(item.done) begin
            if(item.rw)
                `uvm_info("DRV", $sformatf("MASTER 1 READ COMPLETE : DATA_OUT = 0x%0h", item.data_out), UVM_NONE)
            else
                `uvm_info("DRV", "MASTER 1 WRITE COMPLETE", UVM_NONE)
        end

        `uvm_info("DRV", item.convert2string(), UVM_MEDIUM)

    endtask

    task drive_m2(i2c_seq_item item);

        `uvm_info("DRV", "================================================------------", UVM_NONE)
        `uvm_info("DRV", $sformatf("MASTER 2 %s TRANSACTION", item.rw ? "READ" : "WRITE"), UVM_NONE)
        `uvm_info("DRV", $sformatf("SLAVE    : 0x%0h", item.addr), UVM_NONE)
        `uvm_info("DRV", $sformatf("REGISTER : 0x%0h", item.reg_addr), UVM_NONE)
         `uvm_info("DRV", $sformatf("SPEED    : %0b", item.speed_sel), UVM_NONE)
        if(item.rw == 0)
            `uvm_info("DRV", $sformatf("WRITE DATA : 0x%0h", item.data_in), UVM_NONE)
        `uvm_info("DRV", "================================================------------", UVM_NONE)

        @(posedge vif.clk);

        vif.m2_addr     <= item.addr;
        vif.m2_reg_addr <= item.reg_addr;
        vif.m2_rw       <= item.rw;
        vif.m2_rep_start <= item.rep_start;
        vif.m2_data_in  <= item.data_in;
        vif.m2_speed_sel <= item.speed_sel;
        vif.m2_start    <= 1;

        @(posedge vif.clk);

        while(!vif.m2_busy)
            @(posedge vif.clk);

        vif.m2_start <= 0;

         while(!vif.m2_done && !vif.m2_arb_lost && !vif.m2_nack_error)
            @(posedge vif.clk);

        item.done     = vif.m2_done;
        item.arb_lost = vif.m2_arb_lost;
        item.data_out = vif.m2_data_out;
        item.nack_error = vif.m2_nack_error;
         
         while(vif.m2_busy)
           @(posedge vif.clk);
         
         if(item.arb_lost) begin
           `uvm_info("DRV", "MASTER 2 RESULT : ARBITRATION LOST", UVM_NONE)
         end else if(item.nack_error) begin
           `uvm_info("DRV", "MASTER 2 RESULT : NACK ERROR", UVM_NONE)
        end else if(item.done) begin
            if(item.rw)
                `uvm_info("DRV", $sformatf("MASTER 2 READ COMPLETE : DATA_OUT = 0x%0h", item.data_out), UVM_NONE)
            else
                `uvm_info("DRV", "MASTER 2 WRITE COMPLETE", UVM_NONE)
        end

        `uvm_info("DRV", item.convert2string(), UVM_MEDIUM)

    endtask

endclass
