class axi_master_agent extends uvm_agent;

  `uvm_component_utils(axi_master_agent)

  axi_master_driver    drv;
  axi_master_sequencer seqr;
  axi_master_monitor   mon;

  virtual axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "virtual interface not found for axi_master_agent")
    end

    drv  = axi_master_driver   ::type_id::create("drv", this);
    seqr = axi_master_sequencer::type_id::create("seqr", this);
    mon  = axi_master_monitor  ::type_id::create("mon", this);

    drv.vif = vif;
    mon.vif = vif;

  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    drv.seq_item_port.connect(seqr.seq_item_export);

  endfunction

endclass
