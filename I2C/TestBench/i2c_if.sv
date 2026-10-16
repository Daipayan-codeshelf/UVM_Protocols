interface i2c_if(input logic clk, input logic rst);

    tri1 sda;
    tri1 scl;

    logic        m1_start;
    logic        m1_rw;
    logic [6:0]  m1_addr;
    logic [7:0]  m1_reg_addr;
    logic [7:0]  m1_data_in;
    logic [1:0]  m1_speed_sel;
    logic [7:0]  m1_data_out;
    logic        m1_busy;
    logic        m1_done;
    logic        m1_arb_lost;
    logic m1_rep_start;
    logic m1_nack_error;
	logic m2_nack_error;
	logic m2_rep_start;
    

    logic        m2_start;
    logic        m2_rw;
    logic [6:0]  m2_addr;
    logic [7:0]  m2_reg_addr;
    logic [7:0]  m2_data_in;
    logic [1:0]  m2_speed_sel;
    logic [7:0]  m2_data_out;
    logic        m2_busy;
    logic        m2_done;
    logic        m2_arb_lost;

    initial begin
        m1_start     = 0;
        m1_rw        = 0;
        m1_addr      = 0;
        m1_reg_addr  = 0;
        m1_data_in   = 0;
        m1_speed_sel = 0;
        m1_rep_start = 0;
		m2_rep_start = 0;

        m2_start     = 0;
        m2_rw        = 0;
        m2_addr      = 0;
        m2_reg_addr  = 0;
        m2_data_in   = 0;
        m2_speed_sel = 0;
    end

endinterface
