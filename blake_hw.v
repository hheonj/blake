module blake_hw (
	input          		clk,
	input          		rstb,

	input          		ena,
	input  wire [639:0] din,

	output         		rdy,
	output reg [511:0] 	dout
);
//=====================================================================================
localparam IDLE = 2'b00;
localparam RUN  = 2'b01;
localparam DONE = 2'b10;
//=====================================================================================
// counter
reg [6:0] cnt;
wire c_run;
always @(posedge clk) begin
	if (!rstb) begin
		cnt <= 7'b0;
	end else if (cnt == 7'd127) begin
		cnt <= 7'b0;
	end else if (c_run) begin
		cnt <= cnt + 1;
	end 
end 

// FSM
reg [1:0] c_state, n_state;
always @(posedge clk) begin			// update c_state
	if (!rstb) begin
		c_state <= IDLE;
	end else begin
		c_state <= n_state;
	end
end 

always @* begin		
	n_state = c_state;								// n_state comb logic
	case (c_state) 
		IDLE: begin
			if (ena) begin n_state = RUN; end
		end

		RUN: begin
			if (cnt == 7'd127) begin n_state = DONE; end
		end

		DONE: begin
			begin n_state = IDLE; end
		end
	endcase
end 

assign c_run = (c_state == RUN);					// output comb logic
assign rdy = (c_state == DONE);
//=====================================================================================
// input processing
	// swap32 function
function [31:0] swap32;
	input [31:0] x;
begin
	swap32 = {x[8*0 +: 8],x[8*1 +: 8],x[8*2 +: 8],x[8*3 +: 8]};
end
endfunction

	// build m , swap din
reg [63:0] m[0:9];

always @(posedge clk) 
begin
	if (!rstb) begin
		m[0] <= 64'b0;
		m[1] <= 64'b0;
		m[2] <= 64'b0;
		m[3] <= 64'b0;
		m[4] <= 64'b0;
		m[5] <= 64'b0;
		m[6] <= 64'b0;
		m[7] <= 64'b0;
		m[8] <= 64'b0;
		m[9] <= 64'b0;
	end else if (rdy) begin
		m[0] <= 64'b0;
		m[1] <= 64'b0;
		m[2] <= 64'b0;
		m[3] <= 64'b0;
		m[4] <= 64'b0;
		m[5] <= 64'b0;
		m[6] <= 64'b0;
		m[7] <= 64'b0;
		m[8] <= 64'b0;
		m[9] <= 64'b0;
	end else if (ena) begin
		m[9] <= {swap32(din[32* 1 +: 32]),swap32(din[32* 0 +: 32])};
		m[8] <= {swap32(din[32* 3 +: 32]),swap32(din[32* 2 +: 32])};
		m[7] <= {swap32(din[32* 5 +: 32]),swap32(din[32* 4 +: 32])};
		m[6] <= {swap32(din[32* 7 +: 32]),swap32(din[32* 6 +: 32])};
		m[5] <= {swap32(din[32* 9 +: 32]),swap32(din[32* 8 +: 32])};
		m[4] <= {swap32(din[32*11 +: 32]),swap32(din[32*10 +: 32])};
		m[3] <= {swap32(din[32*13 +: 32]),swap32(din[32*12 +: 32])};
		m[2] <= {swap32(din[32*15 +: 32]),swap32(din[32*14 +: 32])};
		m[1] <= {swap32(din[32*17 +: 32]),swap32(din[32*16 +: 32])};
		m[0] <= {swap32(din[32*19 +: 32]),swap32(din[32*18 +: 32])};
	end
end 

wire [63:0] M[0:15];  // processed msg

assign M[0] = m[0];
assign M[1] = m[1];
assign M[2] = m[2];
assign M[3] = m[3];
assign M[4] = m[4];
assign M[5] = m[5];
assign M[6] = m[6];
assign M[7] = m[7];
assign M[8] = m[8];
assign M[9] = m[9];
assign M[10] = 64'h8000000000000000;
assign M[11] = 64'h0000000000000000;
assign M[12] = 64'h0000000000000000;
assign M[13] = 64'h0000000000000001;
assign M[14] = 64'h0000000000000000;
assign M[15] = 64'h0000000000000280;

// CB
wire [63:0] CB[0:15];

assign CB[ 0] = 64'h243F6A8885A308D3;
assign CB[ 1] = 64'h13198A2E03707344;
assign CB[ 2] = 64'hA4093822299F31D0;
assign CB[ 3] = 64'h082EFA98EC4E6C89;
assign CB[ 4] = 64'h452821E638D01377;
assign CB[ 5] = 64'hBE5466CF34E90C6C;
assign CB[ 6] = 64'hC0AC29B7C97C50DD;
assign CB[ 7] = 64'h3F84D5B5B5470917;
assign CB[ 8] = 64'h9216D5D98979FB1B;
assign CB[ 9] = 64'hD1310BA698DFB5AC;
assign CB[10] = 64'h2FFD72DBD01ADFB7;
assign CB[11] = 64'hB8E1AFED6A267E96;
assign CB[12] = 64'hBA7C9045F12C7F99;
assign CB[13] = 64'h24A19947B3916CF7;
assign CB[14] = 64'h0801F2E2858EFC16;
assign CB[15] = 64'h636920D871574E69;

// sigma
wire [63:0] sigma [0:15];

assign sigma[ 0] = { 4'd0,  4'd1,  4'd2,  4'd3,  4'd4,  4'd5,  4'd6,  4'd7,  4'd8,  4'd9,  4'd10, 4'd11, 4'd12, 4'd13, 4'd14, 4'd15 };
assign sigma[ 1] = { 4'd14, 4'd10, 4'd4,  4'd8,  4'd9,  4'd15, 4'd13, 4'd6,  4'd1,  4'd12, 4'd0,  4'd2,  4'd11, 4'd7,  4'd5,  4'd3  };
assign sigma[ 2] = { 4'd11, 4'd8,  4'd12, 4'd0,  4'd5,  4'd2,  4'd15, 4'd13, 4'd10, 4'd14, 4'd3,  4'd6,  4'd7,  4'd1,  4'd9,  4'd4  };
assign sigma[ 3] = { 4'd7,  4'd9,  4'd3,  4'd1,  4'd13, 4'd12, 4'd11, 4'd14, 4'd2,  4'd6,  4'd5,  4'd10, 4'd4,  4'd0,  4'd15, 4'd8  };
assign sigma[ 4] = { 4'd9,  4'd0,  4'd5,  4'd7,  4'd2,  4'd4,  4'd10, 4'd15, 4'd14, 4'd1,  4'd11, 4'd12, 4'd6,  4'd8,  4'd3,  4'd13 };
assign sigma[ 5] = { 4'd2,  4'd12, 4'd6,  4'd10, 4'd0,  4'd11, 4'd8,  4'd3,  4'd4,  4'd13, 4'd7,  4'd5,  4'd15, 4'd14, 4'd1,  4'd9  };
assign sigma[ 6] = { 4'd12, 4'd5,  4'd1,  4'd15, 4'd14, 4'd13, 4'd4,  4'd10, 4'd0,  4'd7,  4'd6,  4'd3,  4'd9,  4'd2,  4'd8,  4'd11 };
assign sigma[ 7] = { 4'd13, 4'd11, 4'd7,  4'd14, 4'd12, 4'd1,  4'd3,  4'd9,  4'd5,  4'd0,  4'd15, 4'd4,  4'd8,  4'd6,  4'd2,  4'd10 };
assign sigma[ 8] = { 4'd6,  4'd15, 4'd14, 4'd9,  4'd11, 4'd3,  4'd0,  4'd8,  4'd12, 4'd2,  4'd13, 4'd7,  4'd1,  4'd4,  4'd10, 4'd5  };
assign sigma[ 9] = { 4'd10, 4'd2,  4'd8,  4'd4,  4'd7,  4'd6,  4'd1,  4'd5,  4'd15, 4'd11, 4'd9,  4'd14, 4'd3,  4'd12, 4'd13, 4'd0  };
assign sigma[10] = { 4'd0,  4'd1,  4'd2,  4'd3,  4'd4,  4'd5,  4'd6,  4'd7,  4'd8,  4'd9,  4'd10, 4'd11, 4'd12, 4'd13, 4'd14, 4'd15 };
assign sigma[11] = { 4'd14, 4'd10, 4'd4,  4'd8,  4'd9,  4'd15, 4'd13, 4'd6,  4'd1,  4'd12, 4'd0,  4'd2,  4'd11, 4'd7,  4'd5,  4'd3  };
assign sigma[12] = { 4'd11, 4'd8,  4'd12, 4'd0,  4'd5,  4'd2,  4'd15, 4'd13, 4'd10, 4'd14, 4'd3,  4'd6,  4'd7,  4'd1,  4'd9,  4'd4  };
assign sigma[13] = { 4'd7,  4'd9,  4'd3,  4'd1,  4'd13, 4'd12, 4'd11, 4'd14, 4'd2,  4'd6,  4'd5,  4'd10, 4'd4,  4'd0,  4'd15, 4'd8  };
assign sigma[14] = { 4'd9,  4'd0,  4'd5,  4'd7,  4'd2,  4'd4,  4'd10, 4'd15, 4'd14, 4'd1,  4'd11, 4'd12, 4'd6,  4'd8,  4'd3,  4'd13 };
assign sigma[15] = { 4'd2,  4'd12, 4'd6,  4'd10, 4'd0,  4'd11, 4'd8,  4'd3,  4'd4,  4'd13, 4'd7,  4'd5,  4'd15, 4'd14, 4'd1,  4'd9  };
//=====================================================================================
// sigma row mux
reg [63:0] sig_row;
always @* begin
	case (cnt[6:3]) 
		4'd0:  sig_row = sigma[ 0];
		4'd1:  sig_row = sigma[ 1];
		4'd2:  sig_row = sigma[ 2];
		4'd3:  sig_row = sigma[ 3];
		4'd4:  sig_row = sigma[ 4];
		4'd5:  sig_row = sigma[ 5];
		4'd6:  sig_row = sigma[ 6];
		4'd7:  sig_row = sigma[ 7];
		4'd8:  sig_row = sigma[ 8];
		4'd9:  sig_row = sigma[ 9];
		4'd10: sig_row = sigma[10];
		4'd11: sig_row = sigma[11];
		4'd12: sig_row = sigma[12];
		4'd13: sig_row = sigma[13];
		4'd14: sig_row = sigma[14];
		4'd15: sig_row = sigma[15];
	endcase
end 

// sigma column mux
reg [3:0] sig_even, sig_odd;
always @* begin
	case (cnt[2:0])
		3'd7: sig_odd = sig_row[4*0 +: 4];
		3'd6: sig_odd = sig_row[4*2 +: 4];
		3'd5: sig_odd = sig_row[4*4 +: 4];
		3'd4: sig_odd = sig_row[4*6 +: 4];
		3'd3: sig_odd = sig_row[4*8 +: 4];
		3'd2: sig_odd = sig_row[4*10 +: 4];
		3'd1: sig_odd = sig_row[4*12 +: 4];
		3'd0: sig_odd = sig_row[4*14 +: 4];
	endcase
end

always @* begin
	case (cnt[2:0])
		3'd7: sig_even = sig_row[4*1 +: 4];
		3'd6: sig_even = sig_row[4*3 +: 4];
		3'd5: sig_even = sig_row[4*5 +: 4];
		3'd4: sig_even = sig_row[4*7 +: 4];
		3'd3: sig_even = sig_row[4*9 +: 4];
		3'd2: sig_even = sig_row[4*11 +: 4];
		3'd1: sig_even = sig_row[4*13 +: 4];
		3'd0: sig_even = sig_row[4*15 +: 4];
	endcase
end
//=====================================================================================
// M0, M1, CB0, CB1
wire [63:0] M0, M1, CB0, CB1;
assign M0 = M[sig_even];
assign M1 = M[sig_odd];
assign CB0 = CB[sig_even];
assign CB1 = CB[sig_odd];
//=====================================================================================
// state_v
wire [63:0] out [0:15];
reg [63:0] a,b,c,d;
wire [63:0] o_a,o_b,o_c,o_d;
reg [63:0] state_v[0:15];
// assign out[ 0] = (!c_run ? 0 : ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd4)) ? o_a : state_v[ 0]);
// assign out[ 1] = (!c_run ? 0 : ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd5)) ? o_a : state_v[ 1]);
// assign out[ 2] = (!c_run ? 0 : ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd6)) ? o_a : state_v[ 2]);
// assign out[ 3] = (!c_run ? 0 : ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd7)) ? o_a : state_v[ 3]);
// assign out[ 4] = (!c_run ? 0 : ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd7)) ? o_b : state_v[ 4]);
// assign out[ 5] = (!c_run ? 0 : ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd4)) ? o_b : state_v[ 5]);
// assign out[ 6] = (!c_run ? 0 : ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd5)) ? o_b : state_v[ 6]);
// assign out[ 7] = (!c_run ? 0 : ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd6)) ? o_b : state_v[ 7]);
// assign out[ 8] = (!c_run ? 0 : ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd6)) ? o_c : state_v[ 8]);
// assign out[ 9] = (!c_run ? 0 : ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd7)) ? o_c : state_v[ 9]);
// assign out[10] = (!c_run ? 0 : ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd4)) ? o_c : state_v[10]);
// assign out[11] = (!c_run ? 0 : ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd5)) ? o_c : state_v[11]);
// assign out[12] = (!c_run ? 0 : ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd5)) ? o_d : state_v[12]);
// assign out[13] = (!c_run ? 0 : ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd6)) ? o_d : state_v[13]);
// assign out[14] = (!c_run ? 0 : ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd7)) ? o_d : state_v[14]);
// assign out[15] = (!c_run ? 0 : ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd4)) ? o_d : state_v[15]);
assign out[ 0] = (c_run ? ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd4)) ? o_a : state_v[ 0] : 0);
assign out[ 1] = (c_run ? ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd5)) ? o_a : state_v[ 1] : 0);
assign out[ 2] = (c_run ? ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd6)) ? o_a : state_v[ 2] : 0);
assign out[ 3] = (c_run ? ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd7)) ? o_a : state_v[ 3] : 0);
assign out[ 4] = (c_run ? ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd7)) ? o_b : state_v[ 4] : 0);
assign out[ 5] = (c_run ? ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd4)) ? o_b : state_v[ 5] : 0);
assign out[ 6] = (c_run ? ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd5)) ? o_b : state_v[ 6] : 0);
assign out[ 7] = (c_run ? ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd6)) ? o_b : state_v[ 7] : 0);
assign out[ 8] = (c_run ? ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd6)) ? o_c : state_v[ 8] : 0);
assign out[ 9] = (c_run ? ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd7)) ? o_c : state_v[ 9] : 0);
assign out[10] = (c_run ? ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd4)) ? o_c : state_v[10] : 0);
assign out[11] = (c_run ? ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd5)) ? o_c : state_v[11] : 0);
assign out[12] = (c_run ? ((cnt[2:0] == 3'd0)|(cnt[2:0] == 3'd5)) ? o_d : state_v[12] : 0);
assign out[13] = (c_run ? ((cnt[2:0] == 3'd1)|(cnt[2:0] == 3'd6)) ? o_d : state_v[13] : 0);
assign out[14] = (c_run ? ((cnt[2:0] == 3'd2)|(cnt[2:0] == 3'd7)) ? o_d : state_v[14] : 0);
assign out[15] = (c_run ? ((cnt[2:0] == 3'd3)|(cnt[2:0] == 3'd4)) ? o_d : state_v[15] : 0);

always @(posedge clk) begin
	if(!rstb) begin
		state_v[ 0] <= 64'b0;
		state_v[ 1] <= 64'b0;
		state_v[ 2] <= 64'b0;
		state_v[ 3] <= 64'b0;
		state_v[ 4] <= 64'b0;
		state_v[ 5] <= 64'b0;
		state_v[ 6] <= 64'b0;
		state_v[ 7] <= 64'b0;
		state_v[ 8] <= 64'b0;
		state_v[ 9] <= 64'b0;
		state_v[10] <= 64'b0;
		state_v[11] <= 64'b0;
		state_v[12] <= 64'b0;
		state_v[13] <= 64'b0;
		state_v[14] <= 64'b0;
		state_v[15] <= 64'b0;
	end else if (ena) begin
		state_v[ 0] <= 64'h6A09E667F3BCC908; 
		state_v[ 1] <= 64'hBB67AE8584CAA73B;
		state_v[ 2] <= 64'h3C6EF372FE94F82B;
		state_v[ 3] <= 64'hA54FF53A5F1D36F1;
		state_v[ 4] <= 64'h510E527FADE682D1;
		state_v[ 5] <= 64'h9B05688C2B3E6C1F;
		state_v[ 6] <= 64'h1F83D9ABFB41BD6B;
		state_v[ 7] <= 64'h5BE0CD19137E2179;
		state_v[ 8] <= CB[0]               ;
		state_v[ 9] <= CB[1]               ;
		state_v[10] <= CB[2]               ;
		state_v[11] <= CB[3]               ;
		state_v[12] <= 64'h452821E638D011F7;
		state_v[13] <= 64'hBE5466CF34E90EEC;
		state_v[14] <= CB[6]               ;
		state_v[15] <= CB[7]               ;
	end else begin
		state_v[ 0] <= out[ 0]; 
		state_v[ 1] <= out[ 1]; 
		state_v[ 2] <= out[ 2]; 
		state_v[ 3] <= out[ 3]; 
		state_v[ 4] <= out[ 4]; 
		state_v[ 5] <= out[ 5]; 
		state_v[ 6] <= out[ 6]; 
		state_v[ 7] <= out[ 7]; 
		state_v[ 8] <= out[ 8]; 
		state_v[ 9] <= out[ 9]; 
		state_v[10] <= out[10]; 
		state_v[11] <= out[11]; 
		state_v[12] <= out[12]; 
		state_v[13] <= out[13]; 
		state_v[14] <= out[14]; 
		state_v[15] <= out[15]; 
	end
end 

always @* begin
	case (cnt[2:0])
		3'd0: begin a = state_v[0]; end
		3'd1: begin a = state_v[1]; end
		3'd2: begin a = state_v[2]; end
		3'd3: begin a = state_v[3]; end
		3'd4: begin a = state_v[0]; end
		3'd5: begin a = state_v[1]; end
		3'd6: begin a = state_v[2]; end
		3'd7: begin a = state_v[3]; end
	endcase
end

always @* begin
	case (cnt[2:0])
		3'd0: begin b = state_v[4]; end
		3'd1: begin b = state_v[5]; end
		3'd2: begin b = state_v[6]; end
		3'd3: begin b = state_v[7]; end
		3'd4: begin b = state_v[5]; end
		3'd5: begin b = state_v[6]; end
		3'd6: begin b = state_v[7]; end
		3'd7: begin b = state_v[4]; end
	endcase
end

always @* begin
	case (cnt[2:0]) // cnt[2:0]
		3'd0: begin c = state_v[ 8]; end
		3'd1: begin c = state_v[ 9]; end
		3'd2: begin c = state_v[10]; end
		3'd3: begin c = state_v[11]; end
		3'd4: begin c = state_v[10]; end
		3'd5: begin c = state_v[11]; end
		3'd6: begin c = state_v[ 8]; end
		3'd7: begin c = state_v[ 9]; end
	endcase
end

always @* begin
	case (cnt[2:0])
		3'd0: begin d = state_v[12]; end
		3'd1: begin d = state_v[13]; end
		3'd2: begin d = state_v[14]; end
		3'd3: begin d = state_v[15]; end
		3'd4: begin d = state_v[15]; end
		3'd5: begin d = state_v[12]; end
		3'd6: begin d = state_v[13]; end
		3'd7: begin d = state_v[14]; end
	endcase
end
//=====================================================================================
GB u_gb (
	.M0	(M0	),  
	.M1	(M1	),   
	.CB0(CB0),
	.CB1(CB1),
	.a  (a  ),
	.b  (b  ),
	.c  (c  ),
	.d  (d  ),
	.o_a(o_a),
	.o_b(o_b),
	.o_c(o_c),
	.o_d(o_d)
);

always @* begin
	if (rdy) begin
		dout [511:448] = 64'h6A09E667F3BCC908 ^ state_v[0] ^ state_v[ 8];	
		dout [447:384] = 64'hBB67AE8584CAA73B ^ state_v[1] ^ state_v[ 9];	
		dout [383:320] = 64'h3C6EF372FE94F82B ^ state_v[2] ^ state_v[10];	
		dout [319:256] = 64'hA54FF53A5F1D36F1 ^ state_v[3] ^ state_v[11];	
		dout [255:192] = 64'h510E527FADE682D1 ^ state_v[4] ^ state_v[12];	
		dout [191:128] = 64'h9B05688C2B3E6C1F ^ state_v[5] ^ state_v[13];	
		dout [127: 64] = 64'h1F83D9ABFB41BD6B ^ state_v[6] ^ state_v[14];	
		dout [ 63:  0] = 64'h5BE0CD19137E2179 ^ state_v[7] ^ state_v[15];	
	end else begin
		dout [511:0] = 512'b0;
	end
end

endmodule