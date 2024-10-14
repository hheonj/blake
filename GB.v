module GB (
	input [63:0] 	  M0	,  
	input [63:0] 	  M1	,   
	input [63:0] 	  CB0	,
	input [63:0] 	  CB1	,
	input [63:0] 	  a		,
	input [63:0] 	  b		,
	input [63:0] 	  c		,
	input [63:0] 	  d		,
	output reg [63:0] o_a	,
	output reg [63:0] o_b	,
	output reg [63:0] o_c	,
	output reg [63:0] o_d
);
//--------------------------------------------------------------
// Variables
reg [63:0] r_a;
reg [63:0] r_b;
reg [63:0] r_c;
reg [63:0] r_d;
//--------------------------------------------------------------
//ROTL64 function
function [63:0] ROTL64;
	input [63:0] 	x;
	input [ 5:0]	n;
begin
	ROTL64 = (((x) << (n)) | ((x) >> (64 - (n)))) & 64'hFFFFFFFFFFFFFFFF;
end
endfunction
//-----------------------------------
//ROTR64 function
function [63:0] ROTR64;
	input [63:0] 	x;
	input [ 5:0]	n;
begin
	ROTR64 = ROTL64(x, (64 - (n)));
end
endfunction
//--------------------------------------------------------------
always @(*) begin
	r_a = a + b + (M0 ^ CB1);
	r_d = ROTR64(d ^ r_a, 32);
	r_c = (c + r_d);
	r_b = ROTR64(b ^ r_c, 25);

	o_a = r_a + r_b + (M1^ CB0);
	o_d = ROTR64(r_d ^ o_a, 16);
	o_c = (r_c + o_d);
	o_b = ROTR64(r_b ^ o_c, 11);
end
//--------------------------------------------------------------
endmodule