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
module SDRAM_Controller_TOP(
	input wire 	CLK_50M,
	input wire	RSTn,
	//SDRAM
	output wire [12:0] SDRAM_A,
	inout wire [15:0] SDRAM_DQ,
	output wire SDRAM_DQML_N,
	output wire SDRAM_DQMH_N,
	output wire [1:0] SDRAM_BA,
	output wire SDRAM_WE_N,
	output wire SDRAM_CAS_N,
	output wire SDRAM_RAS_N,
	output wire SDRAM_CS_N,
	output wire SDRAM_CLK_BUF,
	output wire SDRAM_CKE,
	//CPU
	//VideoChip
	output wire VGA_CLK_BUF,
	output wire HSYNC,
	output wire VSYNC,
	output wire [7:0]VGA_R,
	output wire [7:0]VGA_G,
	output wire [7:0]VGA_B
	);

	wire SDRAM_CLK;
	wire CPU_CLK;
	wire VGA_CLK;
	wire [15:0]CPU_DATA_OUT;
	wire [15:0]CPU_DATA_IN;
	wire [19:0]CPU_A;
	wire CPU_RDn;
	wire CPU_WRn;
	
	wire [19:0]Video_A;
	wire VIDEO_RDn;
	wire [15:0]PIXEL_DATA;
	wire CPU_WAITn;
	
	wire Buf_WRn;
	wire Buf_RDn;

	//ODDR2 Requeridos por la Spartan para sacar señales del PLL hacia los pines de la SDRAM y del DAC de Vídeo
	ODDR2 #(
      .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
      .INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
   ) SDRAM_BUF (
      .Q(SDRAM_CLK_BUF),   // 1-bit DDR output data
      .C0(SDRAM_CLK),   // 1-bit clock input
      .C1(~SDRAM_CLK),   // 1-bit clock input
      .CE(1), // 1-bit clock enable input
      .D0(1), // 1-bit data input (associated with C0)
      .D1(0), // 1-bit data input (associated with C1)
      .R(0),   // 1-bit reset input
      .S(0)    // 1-bit set input
   );

 ODDR2 #(
      .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
      .INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
   ) VGA_BUF (
      .Q(VGA_CLK_BUF),   // 1-bit DDR output data
      .C0(VGA_CLK),   // 1-bit clock input
      .C1(~VGA_CLK),   // 1-bit clock input
      .CE(1), // 1-bit clock enable input
      .D0(1), // 1-bit data input (associated with C0)
      .D1(0), // 1-bit data input (associated with C1)
      .R(0),   // 1-bit reset input
      .S(0)    // 1-bit set input
   );

MEMORY_BUFFER BUFFER(
    .CLK_RD(VGA_CLK), 
    .CLK_WR(SDRAM_CLK), 
    .RDn(Buf_RDn),
    .WRn(Buf_WRn), 
    .DATA_WR(SDRAM_DQ), 
    .DATA_RD(PIXEL_DATA)
    );

SVGA800 VIDEO (
    .CLK(VGA_CLK), 
	 .RSTn(RSTn),
    .HSYNC(HSYNC), 
    .VSYNC(VSYNC),
	 .ADD(Video_A),
	 .RDn(VIDEO_RDn),
	 .Buf_RDn(Buf_RDn),
	 .PIXEL_DATA(PIXEL_DATA),
	 .RED(VGA_R),
	 .GREEN(VGA_G),
	 .BLUE(VGA_B)
    );

SMALL_CPU CPU (
    .CLK(CPU_CLK), 
    .RSTn(RSTn), 
    .DATA_IN(CPU_DATA_OUT), 
    .DATA_OUT(CPU_DATA_IN), 
    .ADDRESS(CPU_A), 
    .WAITn(CPU_WAITn), 
    .READn(CPU_RDn), 
    .WRn(CPU_WRn)
    );

SDRAM_Controller SDRAM (
    .CLK_SDRAM(SDRAM_CLK), 
    .RSTn(RSTn), 
    .SDRAM_A(SDRAM_A), 
    .SDRAM_DQ(SDRAM_DQ), 
    .SDRAM_DQML_N(SDRAM_DQML_N), 
    .SDRAM_DQMH_N(SDRAM_DQMH_N), 
    .SDRAM_BA(SDRAM_BA), 
    .SDRAM_WE_N(SDRAM_WE_N), 
    .SDRAM_CAS_N(SDRAM_CAS_N), 
    .SDRAM_RAS_N(SDRAM_RAS_N), 
    .SDRAM_CS_N(SDRAM_CS_N), 
    .SDRAM_CKE(SDRAM_CKE), 
    .CPU_RDn(CPU_RDn), 
    .CPU_WRn(CPU_WRn), 
    .CPU_A(CPU_A),
	 .CPU_DATA_IN(CPU_DATA_IN),
	 .CPU_DATA_OUT(CPU_DATA_OUT),	 
    .CPU_WAITn(CPU_WAITn),
	 .Video_A(Video_A),
	 .VIDEO_RDn(VIDEO_RDn),
	 .DO_REFRESH(HSYNC),
	 .Buf_WRn(Buf_WRn)
    );
	 
 SDRAM_PLL PLL
   (.CLK_50(CLK_50M),
    .CLK_SDRAM(SDRAM_CLK), 	//133,333MHZ
    .CLK_SVGA(VGA_CLK),		// 40,000MHz
    .CLK_CPU(CPU_CLK));		// 32,000MHz
	 
endmodule
