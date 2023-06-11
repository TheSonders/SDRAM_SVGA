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
// Antonio Sanchez (@TheSonders)
// 
// Video Module
// Color 16bits RRRRRGGGGGGBBBBB
// http://tinyvga.com/vga-timing/800x600@60Hz
//////////////////////////////////////////////////////////////////////////////////

module SVGA800(
	input wire CLK,
	input wire RSTn,
	output wire HSYNC,
	output wire VSYNC,
	output wire [19:0]ADD,
	output reg RDn=1,
	output wire Buf_RDn,
	input wire [15:0]PIXEL_DATA,
	output wire [7:0]RED,
	output wire [7:0]GREEN,
	output wire [7:0]BLUE
    );

localparam fps=60;
localparam PixelFreq=40_000_000;
localparam HorSyncPolarity=1;
localparam HorVisible=800-1;
localparam HorFPorch=HorVisible+40;
localparam HorSyncPulse=HorFPorch+128;
localparam HorBPorch=HorSyncPulse+88;
localparam HorTotal=HorBPorch;
localparam VerSyncPolarity=1;
localparam VerVisible=600-1;
localparam VerFPorch=VerVisible+1;
localparam VerSyncPulse=VerFPorch+4;
localparam VerBackPorch=VerSyncPulse+23;
localparam VerTotal=VerBackPorch;

assign HSYNC=(HorCounter>HorFPorch)& (HorCounter<=HorSyncPulse);
assign VSYNC=(VerCounter>VerFPorch)& (VerCounter<=VerSyncPulse);
assign ADD={VerCounter,HorCounter[9:0]};///

//COLOR CONVERSION
assign Buf_RDn=~Visible;

assign RED=		(Visible & RSTn)?{PIXEL_DATA[15:11],PIXEL_DATA[15:13]}:0;
assign GREEN=	(Visible & RSTn)?{PIXEL_DATA[10: 5],PIXEL_DATA[10: 9]}:0;
assign BLUE=	(Visible & RSTn)?{PIXEL_DATA[ 4: 0],PIXEL_DATA[ 4: 2]}:0;

wire Visible=(HorCounter<=HorVisible) &
				(VerCounter<=VerVisible);
				
//PIXEL COUNTERS
reg [$clog2(HorTotal)-1:0]HorCounter=0;
reg [$clog2(VerTotal)-1:0]VerCounter=0;

always @(posedge CLK)begin
	if (HorCounter==HorTotal)begin
		HorCounter<=0;
		if (VerCounter==VerTotal)begin
			VerCounter<=0;
		end
		else begin
			VerCounter<=VerCounter+1;
		end
	end
	else begin
		HorCounter<=HorCounter+1;
	end
end

//SDRAM MEMORY ACCESS
reg nBuf=0;
always @(posedge CLK)begin
	if ((HorCounter<HorVisible)&(HorCounter[2:0]==0))begin
		RDn<=0;
	end
	else RDn<=1;
end
endmodule
