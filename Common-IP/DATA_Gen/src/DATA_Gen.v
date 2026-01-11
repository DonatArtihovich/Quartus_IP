module DATA_Gen
# (
	parameter PACKET_WORD_LEN_BITS = 8,
	parameter PACKET_LEN_WORDS     = 8,
	parameter PACKET_ID            = 8'hAE,
	parameter PACKET_PAUSE_TICKS   = 100
)
(
	input  wire                                clk,
	input  wire                                rstn,
	
	input  wire                                gen_en,
	
	output wire [PACKET_WORD_LEN_BITS - 1 : 0] m_axis_tdata,
	output wire                                m_axis_tvalid,
	output wire                                m_axis_tlast,
	input  wire                                m_axis_tready
);

localparam TRM_ID    = 4'b0001;
localparam TRM_DATA  = 4'b0010;
localparam TRM_CS    = 4'b0100;
localparam PAUSE_CNT = 4'b1000;

reg  [$clog2(PACKET_LEN_WORDS) - 1 : 0]   word_cnt = 0;
reg  [$clog2(PACKET_PAUSE_TICKS) - 1 : 0] pause_cnt = 0;
reg  [PACKET_WORD_LEN_BITS - 1 : 0]       data = PACKET_ID;

reg  [PACKET_WORD_LEN_BITS : 0]       cs_0 = PACKET_ID;
wire [PACKET_WORD_LEN_BITS : 0]       cs_1 = cs_0 + data;
wire [PACKET_WORD_LEN_BITS - 1 : 0]   cs = cs_1[PACKET_WORD_LEN_BITS - 1 : 0] + cs_1[PACKET_WORD_LEN_BITS];


//--------------------Packets Generation
//
reg  [3 : 0] state = TRM_ID;

always @(posedge clk) begin
	if (~rstn | ~gen_en) begin
		word_cnt  <= 0;
		pause_cnt <= 0;
		data      <= PACKET_ID;
		cs_0      <= PACKET_ID;
		state     <= TRM_ID;
	end else begin	
		case (state)
		TRM_ID: begin
			if (m_axis_tready) begin
				state <= TRM_DATA;
				data  <= 0;
				word_cnt <= word_cnt + 1;
			end
		end
		TRM_DATA: begin
			if (m_axis_tready) begin
				if (word_cnt == PACKET_LEN_WORDS - 2) begin
					data  <= ~cs;
					state <= TRM_CS;
				end else begin
					data <= data + 1;
				end

		        word_cnt <= word_cnt + 1;
			end
		end
		TRM_CS: begin
			if (m_axis_tready) begin
				word_cnt <= 0;
				state    <= PACKET_PAUSE_TICKS > 0? PAUSE_CNT : TRM_ID;
				data     <= PACKET_ID;
			end
		end
		PAUSE_CNT: begin
			if (pause_cnt < PACKET_PAUSE_TICKS - 1) begin
				pause_cnt <= pause_cnt + 1;
			end else begin
				pause_cnt <= 0;
				state     <= TRM_ID;
			end
		end
		default: state <= TRM_ID;
		endcase
	end
end

//--------------------------CS Calculation
//
always @(posedge clk) begin
	if (~rstn | ~gen_en) begin
		cs_0 <= 0;
	end else begin
		if (m_axis_tready & m_axis_tvalid) begin
		    cs_0 <= (state[0] ^ state[1]) ? cs_0 + data : 0;
		end
	end
end

assign m_axis_tdata  = data;
assign m_axis_tvalid = gen_en & rstn & (state[0] ^ state[1] ^ state[2]);
assign m_axis_tlast  = state[2];

endmodule