`timescale 1ns / 1ps

module DATA_Gen_sim #(
    parameter real FREQ_MHZ               = 50.0,
    parameter      TESTBENCH_DURATION_MS  = 50,

    parameter      PACKET_WORD_LEN_BITS   = 16,
    parameter      PACKET_LEN_WORDS       = 12,
    parameter      PACKET_ID              = 8'hAE,
    parameter      PACKET_PAUSE_TICKS     = 10,

    parameter      PROCESSING_PERIOD_TICKS = 5
);

reg clk    = 0;
reg rstn   = 0;
reg gen_en = 0;

always #(500 / FREQ_MHZ) clk <= ~clk;

wire [PACKET_WORD_LEN_BITS - 1 : 0] m_axis_tdata;
wire                                m_axis_tvalid;
wire                                m_axis_tlast;
wire                                m_axis_tready;

DATA_Gen #(
    .PACKET_WORD_LEN_BITS (PACKET_WORD_LEN_BITS),
    .PACKET_LEN_WORDS (PACKET_LEN_WORDS),
    .PACKET_ID (PACKET_ID),
    .PACKET_PAUSE_TICKS (PACKET_PAUSE_TICKS)
)
UUT (
    .clk  (clk),
    .rstn (rstn),

    .gen_en (gen_en),

    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tlast  (m_axis_tlast),
    .m_axis_tready (m_axis_tready)
);

integer period_cnt = 0;

always @(posedge clk) begin
    if (~rstn | ~gen_en) begin
        period_cnt <= 0;
    end else begin
        period_cnt <= (period_cnt < PROCESSING_PERIOD_TICKS - 1 || ~m_axis_tvalid) ? period_cnt + 1 : 0;
    end
end

assign m_axis_tready = ~|period_cnt;

initial begin
    #100; rstn <= 1;
    #100; gen_en <= 1;

    #(TESTBENCH_DURATION_MS * 1_000_000);

    $finish;
end

endmodule