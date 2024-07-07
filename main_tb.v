`timescale 1ns/100ps
`include "main.v"

module mips32_pipelined_tb1;
    reg clk1, clk2;
    integer k;

    pipelined_mips32_processor processor(clk1, clk2);

    initial
    begin
        clk1 = 0; clk2 = 0;
        repeat(20)
        begin
            #5 clk1 = 1;
            #5 clk1 = 0;
            #5 clk2 = 1;
            #5 clk2 = 0;
        end
    end

    initial
    begin
         $dumpfile("main_tb.vcd");
        $dumpvars (0, mips32_pipelined_tb1);

        for(k=0;k<31;k++)
            processor.Reg[k] = 0;
        processor.Mem[0] = 32'h2401000a;    //ADDI R1, R0, 10
        processor.Mem[1] = 32'h24020014;    //ADDI R2, R0, 20
        processor.Mem[2] = 32'h2403001e;    //ADDI R3, R0, 30
        processor.Mem[3] = 32'h18e73800;    //OR R7, R7, R7(Dummy Instruction)
        processor.Mem[4] = 32'h00222000;    //ADD R4, R1, R2
        processor.Mem[5] = 32'h00432800;    //ADD R5, R2, R3
        processor.Mem[6] = 32'h18e73800;    //OR R7, R7, R7(Dummy Instruction)
        processor.Mem[7] = 32'h04a43000;    //SUB R6, R5, R4
        processor.Mem[8] = 32'h18e73800;    //OR R7, R7, R7(Dummy Instruction)
        processor.Mem[9] = 32'h10c03800;   //SLT R7, R6, R0 (R7=0 if(R6>R0))
        processor.Mem[10] = 32'h19294800;   //OR R8, R8, R8(Dummy Instruction)
        processor.Mem[11] = 32'h48470002;   //SW R7, 2(R2)
        processor.Mem[12] = 32'h18e73800;   //OR R7, R7, R7(Dummy Instruction)
        processor.Mem[13] = 32'h44480002;   //LW R8, 2(R2)
        processor.Mem[14] = 32'h39200001;   //BEQ R9, R0, 2
        processor.Mem[15] = 32'h240c0003;   //ADDI 12, R0, 3
        processor.Mem[16] = 32'h240a000f;   //ADDI R10, R0, 15
        processor.Mem[17] = 32'hfc000000;   //HALT
        processor.HALTED = 0;
        processor.TAKEN_BRANCH = 0;
        processor.EX_MEM_BEQ_Cond = 0;
        processor.PC = 0;

        #500
        if(processor.Mem[22] == 0)
            $display("Positive Reg[12] = %2d", processor.Reg[12]);
        else
            $display("Negative Reg[12] = %2d", processor.Reg[12]);

        $finish;
    end
endmodule