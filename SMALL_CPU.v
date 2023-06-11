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
module SMALL_CPU(
	input wire CLK,
	input wire RSTn,
	input wire [15:0]DATA_IN,
	output reg [15:0]DATA_OUT,
	output reg [19:0]ADDRESS,
	input wire WAITn,
	output reg READn,
	output reg WRn
    );

reg [2:0]STM=0;
reg [15:0]IR=0;
reg WAITnL=0;

always @(negedge CLK)begin
	WAITnL<=WAITn;
end

always @(posedge CLK)begin
	if (~RSTn)begin
		ADDRESS<=0;
		DATA_OUT<=0;
		STM<=0;
		IR<=0;
		READn<=1;
		WRn<=1;
	end
	else begin
		case (STM)
			0:begin
				STM<=STM+1;
				READn<=0;
			end
			1:begin
				if (WAITnL)begin
					STM<=STM+1;
					IR<=DATA_IN;
					READn<=1;
				end
			end
			2:begin
				STM<=STM+1;
				//IR<=(IR+1)| 16'h8000;
				IR<={ADDRESS[9:6],ADDRESS[7:2],ADDRESS[5:0]};
				//IR<=16'b0000011111100000;
				/*if (IR==16'b0000011111100000)begin
					IR<= 16'b1111100000011111;
				end
				else begin
					IR<=16'b0000011111100000;
				end*/
				/*if (ADDRESS[2:0]==0)begin
					if (ADDRESS[3]==0)IR<=16'hFFFF;
					else IR<=16'h07FF;
				end
				else IR<=16'h0000;*/
			end
			3:begin
				if (ADDRESS>20'hD0000)STM<=0;
				else begin
					STM<=STM+1;	
					DATA_OUT<=IR;
					WRn<=0;
				end
			end
			4:begin
				if (WAITnL)begin
					STM<=0;
					WRn<=1;
					ADDRESS<=ADDRESS+1;
				end
			end
		endcase
	end
end

endmodule
