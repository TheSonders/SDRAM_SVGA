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
// Antonio Sánchez (@TheSonders)
// Mayo 2023
// SDRAM: MT48LC16M16A2P-75
// 32MiB (16Mx16bits)
// CL=3 @133MHz
// Rows=8K Cols=512 Banks=4
//////////////////////////////////////////////////////////////////////////////////
module SDRAM_Controller(
	input wire CLK_SDRAM,
	input wire RSTn,
	//SDRAM
	output reg [12:0] SDRAM_A=0,
	inout wire [15:0] SDRAM_DQ,
	output reg SDRAM_DQML_N=0,
	output wire SDRAM_DQMH_N,
	output reg [1:0] SDRAM_BA=0,
	output reg SDRAM_WE_N=0,
	output reg SDRAM_CAS_N=0,
	output reg SDRAM_RAS_N=0,
	output reg SDRAM_CS_N=0,
	output reg SDRAM_CKE=0,
	//CPU
	input wire CPU_RDn,
	input wire CPU_WRn,
	input wire [19:0]CPU_A,
	output reg CPU_WAITn=0,
	input wire [15:0]CPU_DATA_IN,
	output reg [15:0]CPU_DATA_OUT=0,
	//VideoChip
	input wire [19:0]Video_A,
	input wire VIDEO_RDn,
	input wire DO_REFRESH,
	//Databuffer
	output reg Buf_WRn=1
	);
	 
	 //Timing
	 localparam MAIN_FREQ=133_333_333;
	 localparam DELAY_INIT=Cycles_ns(50_000);
	 localparam tRP=Cycles_ns(20);
	 localparam tRFC=Cycles_ns(66);
	 localparam tRCD=Cycles_ns(20);
	 localparam tWR=Cycles_ns(15);
	 localparam tMRD=2;
	 localparam tCL=3-1;
	 
	 //Commands
	 localparam NOP=				4'b0111;//7		
	 localparam ACTIVE=			4'b0011;//3		
	 localparam READ=				4'b0101;//5		
	 localparam WRITE=			4'b0100;//4		
	 localparam PRECHARGE=		4'b0010;//2		
	 localparam AUTO_REFRESH=	4'b0001;//1		
	 localparam LMR=				4'b0000;//0		
	 localparam MODE=13'b000_1_00_011_0_011;
	 
	 //State Machine
	 localparam St_Reset=0;
	 localparam St_Init=1;
	 localparam St_Prech=2;
	 localparam St_ARefr1=3;
	 localparam St_ARefr2=4;
	 localparam St_LMR=5;
	 localparam St_Idle=6;
	 localparam St_CPU_Read=7;
	 localparam St_CPU_Start_Write=8;
	 localparam St_CPU_Precharge=9;
	 localparam St_CPU_Finish=10;
	 localparam St_Video_Start_Read=11;
	 localparam St_Video_Do_Read=12;
	 localparam St_Video_Finish=13;
	 localparam St_Video_Read_Cycle=14;
	 localparam St_Finish_Refresh=15;
	 localparam St_CPU_End_Write=16;
	 
	 assign SDRAM_DQ=(OutputEnable)?CPU_DATA_IN:16'hZZ;
	 assign SDRAM_DQMH_N=SDRAM_DQML_N;
	 reg [$clog2(DELAY_INIT)-1:0]TimerCounter=0;
	 reg [4:0]STM=0;
	 
	 reg OutputEnable=0;
	 reg VIDEO_WAITn=0;
	 reg Prev_VIDEO_RDn=0;
	 reg Prev_CPU_RDn=0;
	 reg Prev_CPU_WRn=0;
	 reg Prev_Prev_CPU_WRn=0;  
	 reg Prev_Prev_VIDEO_RDn=0;
	 `define FallVideo (Prev_Prev_VIDEO_RDn & ~Prev_VIDEO_RDn & ~VIDEO_RDn)
	 `define FallCPU ((Prev_CPU_RDn & ~CPU_RDn) |(Prev_Prev_CPU_WRn & ~Prev_CPU_WRn & ~CPU_WRn))
	 reg Round=0;
	 reg Latch_CPU=0;
	 reg [19:0]Video_AL=0;
	 
	 always @(posedge CLK_SDRAM)begin
		if (~RSTn)begin
			CPU_WAITn<=0;
			VIDEO_WAITn<=0;
		end
		else begin
			if (Latch_CPU)CPU_DATA_OUT<=SDRAM_DQ;
			Prev_Prev_CPU_WRn<=Prev_CPU_WRn;
			Prev_Prev_VIDEO_RDn<=Prev_VIDEO_RDn;
			Prev_VIDEO_RDn<=VIDEO_RDn;
			Prev_CPU_RDn<=CPU_RDn;
			Prev_CPU_WRn<=CPU_WRn;
			if (`FallVideo)begin
				VIDEO_WAITn<=0;
				Video_AL<=Video_A;
			end
			else if (STM==St_Video_Finish)begin
				VIDEO_WAITn<=1;
			end
			if (`FallCPU)begin
				CPU_WAITn<=0;
			end
			else if (STM==St_CPU_Finish)begin
				CPU_WAITn<=1;
			end
		end
	 end
	 
	 always @(negedge CLK_SDRAM)begin
		if (~RSTn)begin
			STM<=St_Reset;
			SDRAM_CKE<=0;
			Latch_CPU<=0;
		end
		else begin
			if (Latch_CPU==1)Latch_CPU<=0;
			if (TimerCounter!=0)begin
				TimerCounter<=TimerCounter-1;
				SetCommand(NOP);
			end
			else begin
				case(STM)
					St_Reset:begin
						STM<=St_Init;
						SDRAM_CKE<=0;
						SetTimer(DELAY_INIT);
					end
					St_Init:begin
						STM<=St_Prech;
						SDRAM_CKE<=1;
						SetTimer(DELAY_INIT);
					end
					St_Prech:begin
						STM<=St_ARefr1;
						SetCommand(PRECHARGE);
						SDRAM_A[10]<=1;
						SetTimer(tRP);
					end
					St_ARefr1:begin
						STM<=St_ARefr2;
						SetCommand(AUTO_REFRESH);
						SetTimer(tRFC);
					end
					St_ARefr2:begin
						STM<=St_LMR;
						SetCommand(AUTO_REFRESH);
						SetTimer(tRFC);
					end
					St_LMR:begin
						STM<=St_Idle;
						SetCommand(LMR);
						SDRAM_BA<=0;
						SDRAM_A<=MODE;
						SetTimer(tMRD);
					end
					St_Idle:begin
						Buf_WRn<=1;
						SDRAM_DQML_N<=0;
						if (VIDEO_WAITn==0)begin
							STM<=St_Video_Start_Read;
							SetCommand(ACTIVE);
							SetRow(Video_AL);
							SetTimer(tRCD);
						end
						else if (DO_REFRESH==1 && Round==1)begin
							Round<=~Round;
							STM<=St_Finish_Refresh;
							SetCommand(PRECHARGE);
							SetTimer(tRP);
						end
						else if (CPU_WAITn==0)begin
							if (~CPU_RDn)STM<=St_CPU_Read;
							else STM<=St_CPU_Start_Write;
							Round<=~Round;
							SetCommand(ACTIVE);
							SetRow(CPU_A);
							SetTimer(tRCD);
						end
					end
					St_CPU_Read:begin
						STM<=St_CPU_Precharge;
						SetCommand(READ);
						SetCol(CPU_A);
						SetTimer(tCL);
					end
					St_CPU_Start_Write:begin
						STM<=St_CPU_End_Write;
						SetCommand(WRITE);
						OutputEnable<=1;
						SetCol(CPU_A);
					end
					St_CPU_End_Write:begin
						STM<=St_CPU_Precharge;
						SetCommand(NOP);
						SDRAM_DQML_N<=1;
						SetTimer(tWR-1);
					end
					St_CPU_Precharge:begin
						STM<=St_CPU_Finish;
						OutputEnable<=0;
						if (~CPU_RDn) Latch_CPU<=1;
						SetCommand(PRECHARGE);
						SDRAM_A[10]<=1;
					end
					St_CPU_Finish:begin
						STM<=St_Idle;
						SetCommand(NOP);
						SetTimer(tRP-1);
					end
					St_Video_Start_Read:begin
						STM<=St_Video_Read_Cycle;
						SetCommand(READ);
						SetCol(Video_AL);
						SetTimer(tCL);
					end
					St_Video_Read_Cycle:begin
						STM<=St_Video_Do_Read;
						Buf_WRn<=0;
						//SetTimer(7);/////
						SetTimer(4);
					end
					St_Video_Do_Read:begin
						STM<=St_Video_Finish;
						//Buf_WRn<=1;//
						SetCommand(PRECHARGE);
					end
					St_Video_Finish:begin
						STM<=St_Idle;
						SetCommand(NOP);
						SetTimer(tRP-1);
					end
					St_Finish_Refresh:begin
						STM<=St_Idle;
						SetCommand(AUTO_REFRESH);
						SetTimer(tRFC);
					end
				endcase
			end
		end
	 end
	 
// Adresses Matching	 
//      AAAAAAAAAAAAAAAAAAAA
// BBRR_RRRRRRRRRRRCCCCCCCCC
	task SetRow(input [19:0]Address);
		begin
			SDRAM_A<={2'h0,Address[19:9]};
		end
	endtask

	task SetCol(input [19:0]Address);
		begin
			SDRAM_A<={4'h0,Address[8:0]};
		end
	endtask

	
	task SetCommand(input [3:0]Command);
		begin
			SDRAM_CS_N<=Command[3];
			SDRAM_RAS_N<=Command[2];
			SDRAM_CAS_N<=Command[1];
			SDRAM_WE_N<=Command[0];
		end
	endtask
	 
	 task SetTimer(input [31:0]Cycles);
		begin
			TimerCounter<=Cycles;
		end
	 endtask
	 
	 function [63:0]Cycles_ns(
		input [63:0]nanoseconds);
		begin
			Cycles_ns=((MAIN_FREQ*nanoseconds)/1_000_000_000);
			if (((Cycles_ns*1_000_000_000)/MAIN_FREQ)<nanoseconds)begin
				Cycles_ns=Cycles_ns+1;
			end
			Cycles_ns=Cycles_ns-1;
		end	 
	 endfunction

endmodule
