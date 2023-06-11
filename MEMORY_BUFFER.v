`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
/*
MIT License

Copyright (c) 2023 Antonio Sánchez (@TheSonders)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
//////////////////////////////////////////////////////////////////////////////////
module MEMORY_BUFFER(
	input wire CLK_RD,
	input wire CLK_WR,
	input wire RDn,
	input wire WRn,
	input wire [15:0]DATA_WR,
	output reg [15:0]DATA_RD=0);

	(* ram_style = "block" *)
	reg [15:0]Memory[0:31];
	integer x;
	initial begin
		for (x=0;x<32;x=x+1)begin
			Memory[x]<=16'h0000;
		end
	end
	reg [4:0]RDCounter=0;
	reg [4:0]WRCounter=0;
	
	always @(posedge CLK_RD) begin
		if (~RDn)begin
			DATA_RD<=Memory[RDCounter];
			RDCounter<=RDCounter+1;
		end
	end
	
	always @(posedge CLK_WR) begin
		if (~WRn)begin
			Memory[WRCounter]<=DATA_WR;
			WRCounter<=WRCounter+1;
		end
	end

endmodule
