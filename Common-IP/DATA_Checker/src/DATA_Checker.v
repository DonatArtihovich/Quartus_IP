`timescale 1ns / 1ps

module DATA_Checker #(
    parameter PACKET_WORD_LEN_BITS = 8,
	parameter PACKET_LEN_WORDS     = 8,
	parameter PACKET_ID            = 8'hAE
)
(
    input  wire                                clk,
    input  wire                                rstn,

    // s_axis
    input  wire [PACKET_WORD_LEN_BITS - 1 : 0] s_axis_tdata,
    input  wire                                s_axis_tvalid,
    input  wire                                s_axis_tlast,
    output wire                                s_axis_tready,

    // Statistics
    output wire [31 : 0]                       PKT_CNT,
    output wire [31 : 0]                       DATA_ERR_CNT,
    output wire [31 : 0]                       ID_ERR_CNT,
    output wire [31 : 0]                       CS_ERR_CNT
);

reg [31 : 0] pkt_cnt  = 0;

reg [31 : 0] data_err_cnt = 0;
reg [31 : 0] id_err_cnt   = 0;
reg [31 : 0] cs_err_cnt   = 0;

//--------------------------- Packets & Words counting
//
reg [$clog2(PACKET_LEN_WORDS) - 1 : 0] word_cnt = 0;

always @(posedge clk) begin
    if (~rstn) begin
        pkt_cnt      <= 0;
        word_cnt     <= 0;
    end else begin
        if (s_axis_tvalid & s_axis_tready) begin
            word_cnt <= word_cnt + 1;

            if (s_axis_tlast) begin
                pkt_cnt  <= pkt_cnt + 1;
                word_cnt <= 0;
            end
        end
    end
end

//----------------------------- CS Calculating
//
reg  [PACKET_WORD_LEN_BITS : 0]     cs_0 = 0;
wire [PACKET_WORD_LEN_BITS : 0]     cs_1 = s_axis_tlast? cs_0 : cs_0 + s_axis_tdata;
wire [PACKET_WORD_LEN_BITS - 1 : 0] cs = cs_1[PACKET_WORD_LEN_BITS - 1 : 0] + cs_1[PACKET_WORD_LEN_BITS];

always @(posedge clk) begin
    if (~rstn) begin
        cs_0 <= 0;
    end else begin
        if (s_axis_tvalid & s_axis_tready) begin
            cs_0 <= s_axis_tlast? 0 : cs;
        end
    end
end

//-------------------------- Errors counting
//
wire id_err   = (s_axis_tvalid && s_axis_tready) && (word_cnt == 0 && s_axis_tdata != PACKET_ID);
wire data_err = (s_axis_tvalid && s_axis_tready && ~s_axis_tlast) && (word_cnt > 0 && (s_axis_tdata != (word_cnt - 1)));
wire cs_err   = (s_axis_tvalid && s_axis_tready && s_axis_tlast) && (s_axis_tdata != ~cs);

always @(posedge clk) begin
    if (~rstn) begin
        data_err_cnt <= 0;
        id_err_cnt   <= 0;
        cs_err_cnt   <= 0;
    end else begin
        if (id_err && ~&id_err_cnt)     id_err_cnt   <= id_err_cnt + 1;
        if (data_err && ~&data_err_cnt) data_err_cnt <= data_err_cnt + 1;
        if (cs_err && ~&cs_err_cnt)     cs_err_cnt <= cs_err_cnt + 1;
    end
end

assign s_axis_tready = 1'b1;
assign PKT_CNT       = pkt_cnt;
assign ID_ERR_CNT    = id_err_cnt;
assign DATA_ERR_CNT  = data_err_cnt;
assign CS_ERR_CNT    = cs_err_cnt;

endmodule