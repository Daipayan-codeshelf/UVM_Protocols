`timescale 1ns/1ns

module i2c_master_top(
    input         clk,
    input         rst,
    input         start,
    input         rw,
    input  [6:0]  addr,
    input  [7:0]  reg_addr,
    input  [7:0]  data_in,
    input  [1:0]  speed_sel,
    input         rep_start,
    output reg    nack_error,
    output reg [7:0] data_out,
    output reg    busy,
    output reg    done,
    output reg    arb_lost,
    inout         sda,
    inout         scl
);

parameter IDLE        = 0;
parameter START_ST    = 1;
parameter ADDR        = 2;
parameter ACK1        = 3;
parameter REG_ADDR    = 4;
parameter ACK_REG     = 5;
parameter WRITE       = 6;
parameter READ        = 7;
parameter MACK        = 8;
parameter ACK2        = 9;
parameter REP_START_1 = 10;
parameter REP_START_2 = 11;
parameter ADDR2       = 12;
parameter ACK3        = 13;
parameter STOP        = 14;
parameter ARB_LOST_ST = 15;

reg [3:0] state;

parameter STD  = 4;
parameter FAST = 2;
parameter FM   = 1;

reg [15:0] divider;

always @(*) begin
    case(speed_sel)
        2'b00: divider = STD;
        2'b01: divider = FAST;
        2'b10: divider = FM;
        default: divider = STD;
    endcase
end

reg [15:0] clk_cnt;
reg        scl_tick;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        clk_cnt  <= 0;
        scl_tick <= 0;
    end else if(clk_cnt >= divider) begin
        clk_cnt  <= 0;
        scl_tick <= 1;
    end else begin
        clk_cnt  <= clk_cnt + 1;
        scl_tick <= 0;
    end
end

reg sda_out;
reg scl_out;

assign sda = sda_out ? 1'bz : 1'b0;
assign scl = scl_out ? 1'bz : 1'b0;

wire sda_in = sda;
wire scl_in = scl;

reg [7:0] shift;
reg [2:0] bit_cnt;

reg        rw_lat;
reg [6:0]  addr_lat;
reg [7:0]  reg_addr_lat;
reg [7:0]  data_in_lat;
reg        rep_start_lat;

reg [1:0] ack_phase;
reg [1:0] read_phase;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state         <= IDLE;
        busy          <= 0;
        done          <= 0;
        arb_lost      <= 0;
        sda_out       <= 1;
        scl_out       <= 1;
        shift         <= 0;
        bit_cnt       <= 0;
        data_out      <= 0;
        rw_lat        <= 0;
        addr_lat      <= 0;
        reg_addr_lat  <= 0;
        data_in_lat   <= 0;
        rep_start_lat <= 0;
        ack_phase     <= 0;
        read_phase    <= 0;
        nack_error    <= 0;
    end else if(scl_tick) begin
        case(state)

            IDLE: begin
                done       <= 0;
                arb_lost   <= 0;
                sda_out    <= 1;
                scl_out    <= 1;
                busy       <= 0;
                ack_phase  <= 0;
                read_phase <= 0;
                nack_error <= 0;

                if(start) begin
                    busy          <= 1;
                    rep_start_lat <= rep_start;
                    rw_lat        <= rw;
                    addr_lat      <= addr;
                    reg_addr_lat  <= reg_addr;
                    data_in_lat   <= data_in;
                    data_out      <= 0;
                    nack_error    <= 0;
                    state         <= START_ST;
                end
            end

            START_ST: begin
                sda_out <= 0;
                scl_out <= 1;
                shift   <= {addr_lat, 1'b0};
                bit_cnt <= 7;
                state   <= ADDR;
            end

            ADDR: begin
                if(scl_out) begin
                    if(scl_in) begin
                        sda_out <= shift[bit_cnt];
                        scl_out <= 0;
                    end
                end else begin
                    scl_out <= 1;

                    if(sda_out && (sda_in == 1'b0)) begin
                        sda_out  <= 1;
                        arb_lost <= 1;
                        busy     <= 0;
                        state    <= ARB_LOST_ST;
                    end else begin
                        if(bit_cnt == 0) begin
                            ack_phase <= 0;
                            state     <= ACK1;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
            end

            ACK1: begin
                sda_out <= 1;

                case(ack_phase)
                    2'd0: begin
                        scl_out   <= 0;
                        ack_phase <= 2'd1;
                    end

                    2'd1: begin
                        scl_out   <= 1;
                        ack_phase <= 2'd2;
                    end

                    2'd2: begin
                        if(scl_in) begin
                            ack_phase <= 0;

                            if(sda_in == 1'b1) begin
                                state      <= STOP;
                                nack_error <= 1'b1;
                            end else begin
                                scl_out <= 1;
                                bit_cnt <= 7;
                                state   <= REG_ADDR;
                            end
                        end
                    end

                    default: ack_phase <= 0;
                endcase
            end

            REG_ADDR: begin
                if(scl_out) begin
                    if(scl_in) begin
                        sda_out <= reg_addr_lat[bit_cnt];
                        scl_out <= 0;
                    end
                end else begin
                    scl_out <= 1;

                    if(sda_out && (sda_in == 1'b0)) begin
                        sda_out  <= 1;
                        arb_lost <= 1;
                        busy     <= 0;
                        state    <= ARB_LOST_ST;
                    end else begin
                        if(bit_cnt == 0) begin
                            ack_phase <= 0;
                            state     <= ACK_REG;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
            end

            ACK_REG: begin
                sda_out <= 1;

                case(ack_phase)
                    2'd0: begin
                        scl_out   <= 0;
                        ack_phase <= 2'd1;
                    end

                    2'd1: begin
                        scl_out   <= 1;
                        ack_phase <= 2'd2;
                    end

                    2'd2: begin
                        if(scl_in) begin
                            ack_phase <= 0;

                            if(sda_in == 1'b1) begin
                                state      <= STOP;
                                nack_error <= 1'b1;
                            end else begin
                                scl_out <= 1;
                                bit_cnt <= 7;

                                if(rw_lat == 1'b0) begin
                                    shift <= data_in_lat;
                                    state <= WRITE;
                                end else begin
                                    state <= REP_START_1;
                                end
                            end
                        end
                    end

                    default: ack_phase <= 0;
                endcase
            end

            WRITE: begin
                if(scl_out) begin
                    if(scl_in) begin
                        sda_out <= shift[bit_cnt];
                        scl_out <= 0;
                    end
                end else begin
                    scl_out <= 1;

                    if(sda_out && (sda_in == 1'b0)) begin
                        sda_out  <= 1;
                        arb_lost <= 1;
                        busy     <= 0;
                        state    <= ARB_LOST_ST;
                    end else begin
                        if(bit_cnt == 0) begin
                            ack_phase <= 0;
                            state     <= ACK2;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
            end

            ACK2: begin
                sda_out <= 1;

                case(ack_phase)
                    2'd0: begin
                        scl_out   <= 0;
                        ack_phase <= 2'd1;
                    end

                    2'd1: begin
                        scl_out   <= 1;
                        ack_phase <= 2'd2;
                    end

                    2'd2: begin
                        if(scl_in) begin
                            ack_phase <= 0;

                            if(sda_in == 1'b1) begin
                                state      <= STOP;
                                nack_error <= 1'b1;
                            end else begin
                                scl_out <= 0;

                                if(rep_start_lat)
                                    state <= REP_START_1;
                                else
                                    state <= STOP;
                            end
                        end
                    end

                    default: ack_phase <= 0;
                endcase
            end

            REP_START_1: begin
                sda_out    <= 1;
                scl_out    <= 1;
                ack_phase  <= 0;
                read_phase <= 0;
                state      <= REP_START_2;
            end

            REP_START_2: begin
                sda_out <= 0;
                scl_out <= 1;
                shift   <= {addr_lat, 1'b1};
                bit_cnt <= 7;
                state   <= ADDR2;
            end

            ADDR2: begin
                if(scl_out) begin
                    if(scl_in) begin
                        sda_out <= shift[bit_cnt];
                        scl_out <= 0;
                    end
                end else begin
                    scl_out <= 1;

                    if(sda_out && (sda_in == 1'b0)) begin
                        sda_out  <= 1;
                        arb_lost <= 1;
                        busy     <= 0;
                        state    <= ARB_LOST_ST;
                    end else begin
                        if(bit_cnt == 0) begin
                            ack_phase <= 0;
                            state     <= ACK3;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
            end

            ACK3: begin
                sda_out <= 1;

                case(ack_phase)
                    2'd0: begin
                        scl_out   <= 0;
                        ack_phase <= 2'd1;
                    end

                    2'd1: begin
                        scl_out   <= 1;
                        ack_phase <= 2'd2;
                    end

                    2'd2: begin
                        if(scl_in) begin
                            ack_phase <= 0;

                            if(sda_in == 1'b1) begin
                                state      <= STOP;
                                nack_error <= 1'b1;
                            end else begin
                                scl_out    <= 0;
                                bit_cnt    <= 7;
                                read_phase <= 0;
                                state      <= READ;
                            end
                        end
                    end

                    default: ack_phase <= 0;
                endcase
            end

            READ: begin
                sda_out <= 1;

                case(read_phase)
                    2'd0: begin
                        scl_out    <= 0;
                        read_phase <= 2'd1;
                    end

                    2'd1: begin
                        scl_out    <= 1;
                        read_phase <= 2'd2;
                    end

                    2'd2: begin
                        if(scl_in) begin
                            data_out[bit_cnt] <= sda_in;
                            scl_out <= 0;

                            if(bit_cnt == 0) begin
                                read_phase <= 0;
                                state      <= MACK;
                            end else begin
                                bit_cnt    <= bit_cnt - 1;
                                read_phase <= 0;
                            end
                        end
                    end

                    default: read_phase <= 0;
                endcase
            end

            MACK: begin
                if(scl_out) begin
                    if(scl_in) begin
                        sda_out <= 1;
                        scl_out <= 0;
                    end
                end else begin
                    scl_out <= 1;
                    sda_out <= 1;
                    state   <= STOP;
                end
            end

            STOP: begin
                sda_out    <= 1;
                scl_out    <= 1;
                busy       <= 0;
                done       <= 1;
                ack_phase  <= 0;
                read_phase <= 0;
                state      <= IDLE;
            end

            ARB_LOST_ST: begin
                arb_lost   <= 1;
                sda_out    <= 1;
                scl_out    <= 1;
                busy       <= 0;
                ack_phase  <= 0;
                read_phase <= 0;
                state      <= IDLE;
            end

            default: begin
                state <= IDLE;
            end

        endcase
    end
end

endmodule

