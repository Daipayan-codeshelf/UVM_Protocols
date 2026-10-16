class axi_seq_item extends uvm_sequence_item;

  typedef enum {
    AXI_WRITE_READ,
    AXI_WRITE_ONLY,
    AXI_READ_ONLY
  } axi_txn_type_e;

  axi_txn_type_e txn_type;

  rand bit [3:0]  id;
  rand bit [31:0] addr;
  rand bit [7:0]  len;
  rand bit [2:0]  size;
  rand bit [1:0]  burst;
  rand bit [2:0]  prot;

  rand bit [31:0] data[];
  rand bit [3:0]  wstrb[];

  bit use_read_cfg;

  bit [31:0] rd_addr;
  bit [7:0]  rd_len;
  bit [2:0]  rd_size;
  bit [1:0]  rd_burst;
  bit [2:0]  rd_prot;

  bit fixed_compare_last_only;

  bit [1:0] expected_bresp;
  bit [1:0] expected_rresp;

  bit compare_enable;

  bit [1:0] bresp;
  bit [1:0] rresp;
  bit       last;

  bit [31:0] rdata[];

  // For READ_ONLY expected data comparison
  bit expected_read_enable;
  bit [31:0] expected_rdata[];

  // ============================================================
  // Constraints
  // Keep constraints inside class and outside function/task.
  // ============================================================

  constraint c_valid_burst {
    burst inside {2'b00, 2'b01, 2'b10};
  }

  constraint c_valid_size {
    size inside {3'b000, 3'b001, 3'b010};
  }

  constraint c_valid_len {
    len inside {[8'h00:8'h0F]};
  }

  constraint c_valid_prot {
    prot inside {3'b000, 3'b100};
  }

  constraint c_data_size {
    data.size() == (len + 1);
  }

  constraint c_wstrb_size {
    wstrb.size() == data.size();
  }

  constraint c_wstrb_valid {
    foreach (wstrb[i]) {
      wstrb[i] inside {[4'b0000:4'b1111]};
    }
  }

  constraint c_word_align_for_word_size {
    if (size == 3'b010) {
      addr[1:0] == 2'b00;
    }
  }

  constraint c_wrap_len_valid {
    if (burst == 2'b10) {
      len inside {8'h01, 8'h03, 8'h07, 8'h0F};
    }
  }

  `uvm_object_utils(axi_seq_item)

  function new(string name = "axi_seq_item");
    super.new(name);

    txn_type = AXI_WRITE_READ;

    expected_bresp = 2'b00;
    expected_rresp = 2'b00;
    compare_enable = 1'b1;

    use_read_cfg = 1'b0;

    rd_addr  = 32'h0;
    rd_len   = 8'h0;
    rd_size  = 3'b010;
    rd_burst = 2'b01;
    rd_prot  = 3'b000;

    fixed_compare_last_only = 1'b0;

    expected_read_enable = 1'b0;
  endfunction

endclass
