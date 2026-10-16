`include "uvm_macros.svh"
import uvm_pkg::*;

`include "i2c_if.sv"
`include "i2c_tb_pkg.sv"
import i2c_tb_pkg::*;

module tb_top;

    logic clk;
    logic rst;

    initial clk = 0;
    always #5 clk = ~clk;

    i2c_if vif(.clk(clk), .rst(rst));

    i2c_master_top MASTER1 (
        .clk       (clk),
        .rst       (rst),
        .start     (vif.m1_start),
        .rw        (vif.m1_rw),
        .addr      (vif.m1_addr),
        .reg_addr  (vif.m1_reg_addr),
        .data_in   (vif.m1_data_in),
        .speed_sel (vif.m1_speed_sel),
        .nack_error (vif.m1_nack_error),
        .data_out  (vif.m1_data_out),
        .busy      (vif.m1_busy),
        .done      (vif.m1_done),
        .arb_lost  (vif.m1_arb_lost),
       .rep_start(vif.m1_rep_start),
        .sda       (vif.sda),
        .scl       (vif.scl)
    );

    i2c_master_top MASTER2 (
        .clk       (clk),
        .rst       (rst),
        .start     (vif.m2_start),
        .rw        (vif.m2_rw),
        .addr      (vif.m2_addr),
        .reg_addr  (vif.m2_reg_addr),
        .data_in   (vif.m2_data_in),
        .speed_sel (vif.m2_speed_sel),
        .nack_error (vif.m2_nack_error),
        .data_out  (vif.m2_data_out),
        .busy      (vif.m2_busy),
        .done      (vif.m2_done),
        .arb_lost  (vif.m2_arb_lost),
        .rep_start(vif.m2_rep_start),
        .sda       (vif.sda),
        .scl       (vif.scl)
    );

    slave_bfm #(
        .SLAVE_ADDR     (7'h30),
        .STRETCH_CYCLES (0)
    ) SLAVE_NORMAL (
        .clk (clk),
        .scl (vif.scl),
        .sda (vif.sda)
    );

    slave_bfm #(
        .SLAVE_ADDR     (7'h31),
        .STRETCH_CYCLES (5)
    ) SLAVE_STRETCH (
        .clk (clk),
        .scl (vif.scl),
        .sda (vif.sda)
    );

    initial begin
        $dumpfile("i2c_uvm.vcd");
        $dumpvars(0, tb_top);
    end

    initial begin
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);
    end

    initial begin
        uvm_config_db #(virtual i2c_if)::set(null, "*", "vif", vif);
        run_test();
    end

endmodule

module slave_bfm #(
    parameter SLAVE_ADDR     = 7'h30,
    parameter STRETCH_CYCLES = 0
)(
    input  clk,
    inout  scl,
    inout  sda
);

    reg sda_drive_low;
    reg scl_drive_low;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign scl = scl_drive_low ? 1'b0 : 1'bz;

    wire sda_in = sda;
    wire scl_in = scl;

    reg [7:0] memory [0:255];
    reg [7:0] reg_ptr;

    reg [7:0] shift;
    reg [2:0] bit_cnt;
    reg [7:0] rx_byte;

    reg [7:0] tx_byte;
    reg [2:0] tx_cnt;

    reg selected;
    reg ack_pending;
    reg ack_active;
    reg read_after_ack;
    reg sending_data;
    reg release_after_ack;

    reg stretch_next_ack;
    reg stretching;
    reg [15:0] stretch_cnt;

    integer i;

    localparam ST_ADDR  = 2'd0;
    localparam ST_REG   = 2'd1;
    localparam ST_WRITE = 2'd2;
    localparam ST_IDLE  = 2'd3;

    reg [1:0] state;

    initial begin
        for(i = 0; i < 256; i = i + 1)
            memory[i] = i[7:0];

        reg_ptr           = 0;
        shift             = 0;
        bit_cnt           = 0;
        rx_byte           = 0;
        tx_byte           = 0;
        tx_cnt            = 0;

        selected          = 0;
        ack_pending       = 0;
        ack_active        = 0;
        read_after_ack    = 0;
        sending_data      = 0;
        release_after_ack = 0;

        stretch_next_ack  = 0;
        stretching        = 0;
        stretch_cnt       = 0;

        sda_drive_low     = 0;
        scl_drive_low     = 0;

        state             = ST_ADDR;
    end

    // START / REPEATED START detector
    always @(negedge sda) begin
        #1;
        if(scl_in) begin
            shift             <= 0;
            bit_cnt           <= 0;
            selected          <= 0;
            ack_pending       <= 0;
            ack_active        <= 0;
            read_after_ack    <= 0;
            sending_data      <= 0;
            release_after_ack <= 0;
            stretch_next_ack  <= 0;
            sda_drive_low     <= 0;
            state             <= ST_ADDR;
        end
    end

    // STOP detector
    always @(posedge sda) begin
        #1;
        if(scl_in) begin
            selected          <= 0;
            ack_pending       <= 0;
            ack_active        <= 0;
            read_after_ack    <= 0;
            sending_data      <= 0;
            release_after_ack <= 0;
            stretch_next_ack  <= 0;
            bit_cnt           <= 0;
            shift             <= 0;
            sda_drive_low     <= 0;
            state             <= ST_ADDR;
        end
    end

    // Sample bytes from master
    always @(posedge scl) begin
        if(!ack_active && !ack_pending && !sending_data) begin

            rx_byte = {shift[6:0], sda_in};
            shift   <= {shift[6:0], sda_in};

            if(bit_cnt == 3'd7) begin

                if(state == ST_ADDR || rx_byte[7:1] == SLAVE_ADDR) begin

                    if(rx_byte[7:1] == SLAVE_ADDR) begin
                        selected          <= 1'b1;
                        ack_pending       <= 1'b1;
                        stretch_next_ack  <= 1'b0; // stretch only address ACK

                        $display("[%0t] BFM %h ADDRESS BYTE = %h",
                                 $time, SLAVE_ADDR, rx_byte);

                        if(rx_byte[0] == 1'b0) begin
                            read_after_ack    <= 1'b0;
                            release_after_ack <= 1'b0;
                            state             <= ST_REG;
                        end else begin
                            read_after_ack    <= 1'b1;
                            release_after_ack <= 1'b0;
                            state             <= ST_IDLE;
                        end
                    end else begin
                        selected          <= 1'b0;
                        ack_pending       <= 1'b0;
                        read_after_ack    <= 1'b0;
                        release_after_ack <= 1'b0;
                        stretch_next_ack  <= 1'b0;
                        state             <= ST_ADDR;
                    end

                    bit_cnt <= 0;
                end

                else if(selected) begin
                    case(state)

                        ST_REG: begin
                            reg_ptr           <= rx_byte;
                            ack_pending       <= 1'b1;
                            stretch_next_ack  <= (STRETCH_CYCLES > 0);
                            release_after_ack <= 1'b0;
                            state             <= ST_WRITE;
                            bit_cnt           <= 0;

                            $display("[%0t] BFM %h REG_PTR = %h",
                                     $time, SLAVE_ADDR, rx_byte);
                        end

                        ST_WRITE: begin
                            memory[reg_ptr]   <= rx_byte;
                            ack_pending       <= 1'b1;
                            stretch_next_ack  <= (STRETCH_CYCLES > 0);
                            release_after_ack <= 1'b1;
                            state             <= ST_IDLE;
                            bit_cnt           <= 0;

                            $display("[%0t] BFM %h WRITE mem[%h] = %h",
                                     $time, SLAVE_ADDR, reg_ptr, rx_byte);
                        end

                        default: begin
                            bit_cnt <= 0;
                        end

                    endcase
                end

                else begin
                    bit_cnt <= 0;
                    state   <= ST_ADDR;
                end
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end
    end

    // Drive ACK and read data
    always @(negedge scl) begin

        if(ack_pending && selected) begin
            sda_drive_low <= 1'b1;
            ack_active    <= 1'b1;
            ack_pending   <= 1'b0;

            if(STRETCH_CYCLES > 0 && stretch_next_ack) begin
                scl_drive_low    <= 1'b1;
                stretching       <= 1'b1;
                stretch_cnt      <= 0;
                stretch_next_ack <= 1'b0;
            end
        end

        else if(ack_active) begin
            ack_active    <= 1'b0;
            sda_drive_low <= 1'b0;

            if(read_after_ack && selected) begin
                tx_byte        <= memory[reg_ptr];
                tx_cnt         <= 3'd7;
                sending_data   <= 1'b1;
                read_after_ack <= 1'b0;

                sda_drive_low  <= (memory[reg_ptr][7] == 1'b0);

                $display("[%0t] BFM %h ENTER READ reg_ptr=%h data=%h",
                         $time, SLAVE_ADDR, reg_ptr, memory[reg_ptr]);
            end

            else if(release_after_ack) begin
                selected          <= 1'b0;
                release_after_ack <= 1'b0;
                state             <= ST_ADDR;
                shift             <= 0;
                bit_cnt           <= 0;
            end
        end

        else if(sending_data && selected) begin
            if(tx_cnt == 3'd0) begin
                sending_data  <= 1'b0;
                sda_drive_low <= 1'b0;

                selected      <= 1'b0;
                state         <= ST_ADDR;
                shift         <= 0;
                bit_cnt       <= 0;
            end else begin
                tx_cnt        <= tx_cnt - 1'b1;
                sda_drive_low <= (tx_byte[tx_cnt - 1'b1] == 1'b0);
            end
        end

        else begin
            sda_drive_low <= 1'b0;
        end
    end

    // Clock stretch release
    always @(posedge clk) begin
        if(stretching) begin
            if(stretch_cnt >= STRETCH_CYCLES) begin
                scl_drive_low <= 1'b0;
                stretching    <= 1'b0;
            end else begin
                stretch_cnt <= stretch_cnt + 1'b1;
            end
        end
    end

endmodule
