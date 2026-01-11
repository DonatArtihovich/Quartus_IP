`timescale 1ns / 1ps

module DATA_Checker_sim #(
    parameter real FREQ_MHZ               = 50.0,
    parameter      TESTBENCH_DURATION_MS  = 10,

    parameter      PACKET_WORD_LEN_BITS   = 16,
    parameter      PACKET_LEN_WORDS       = 12,
    parameter      PACKET_ID              = 8'hAE,
    parameter      PACKET_PAUSE_TICKS     = 10
);

reg clk    = 0;
reg rstn   = 0;
reg gen_en = 0;

always #(500 / FREQ_MHZ) clk <= ~clk;

wire [31 : 0] PKT_CNT;
wire [31 : 0] DATA_ERR_CNT;
wire [31 : 0] ID_ERR_CNT;
wire [31 : 0] CS_ERR_CNT;

wire [PACKET_WORD_LEN_BITS - 1 : 0] m_axis_tdata;
wire                                m_axis_tvalid;
wire                                m_axis_tlast;
wire                                m_axis_tready;

//---------------------------- DATA_Gen instantiation
//
DATA_Gen #(
    .PACKET_WORD_LEN_BITS (PACKET_WORD_LEN_BITS),
    .PACKET_LEN_WORDS (PACKET_LEN_WORDS),
    .PACKET_ID (PACKET_ID),
    .PACKET_PAUSE_TICKS (PACKET_PAUSE_TICKS)
)
DATA_Gen_i
(
    .clk  (clk),
    .rstn (rstn),

    .gen_en (gen_en),

    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tlast  (m_axis_tlast),
    .m_axis_tready (m_axis_tready)
);

//--------------------------- UUT instantiation
//
DATA_Checker #(
    .PACKET_WORD_LEN_BITS (PACKET_WORD_LEN_BITS),
    .PACKET_LEN_WORDS (PACKET_LEN_WORDS),
    .PACKET_ID (PACKET_ID)
)
UUT
(
    .clk(clk),
    .rstn(rstn),

    .s_axis_tdata(m_axis_tdata),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tready(m_axis_tready),

    .PKT_CNT(PKT_CNT),
    .DATA_ERR_CNT(DATA_ERR_CNT),
    .ID_ERR_CNT(ID_ERR_CNT),
    .CS_ERR_CNT(CS_ERR_CNT)
);

initial begin
    #200; rstn   <= 1;
    #100; gen_en <= 1;

    #(TESTBENCH_DURATION_MS * 1_000_000);
    $finish;
end

endmodule