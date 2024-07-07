module pipelined_mips32_processor (
    clk1, clk2
    );
    input clk1, clk2;  //Two clock phases
    reg [31:0] PC;
    //PC = Program Counter

    reg [31:0] IF_ID_IR, IF_ID_NPC;
    //IF_ID_IR = Instruction register in the latch between IR and ID
    //IF_ID_NPC = New Program Counter between IF and ID
    
    reg [31:0] ID_EX_IR, ID_EX_A, ID_EX_B, ID_EX_Imm, ID_EX_NPC;
    //ID_EX_IR = Instruction register in the latch between ID and EX
    //ID_EX_A = stores value of rs
    //ID_EX_B = stores value of rt
    //ID_EX_Imm = Immediate value(sign extended to make it 32 bit)
    //ID_EX_NPC = New Program Counter between ID and EX

    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
    reg EX_MEM_BEQ_Cond;
    //EX_MEM_IR = Instruction register in the latchc between EX and MEM
    //EX_MEM_ALUOut = Store Output of Execution(ALU Unit Output)
    //EX_MEM_B = For store operation
    //EX_MEM_BEQ_Cond = Output to BEQ Condition

    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    //MEM_WB_IR = Instruction register in the latch between MEM and WB
    //MEM_WB_ALUOut = Contains output of execution
    //MEM_WB_LMD = For load operation

    reg [2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;

    reg[31:0] Reg[0:31]; //32 reigsters of 32 bit
    reg[31:0] Mem[0:1023]; //(32x1024) bits memory = 4Kb memory


    //Opcodes
    parameter
    ADD = 6'b000000,    //rd = rs + rt
    SUB = 6'b000001,    //rd = rs - rt
    MUL = 6'b000010,    //rd = rs * rt
    DIV = 6'b000011,    //rd = rs / rt
    SLT = 6'b000100,    //rd = rs < rt


    AND = 6'b000101,    //rd = rs & rt
    OR  = 6'b000110,    //rd = rs | rt
    SLL = 6'b000111,    //rd = rt << rs
    SRL = 6'b001000,    //rd = rt >> rs

    ADDI = 6'b001001,   //rt = rs + Imm
    SUBI = 6'b001010,   //rt = rs - Imm
    MULI = 6'b001011,   //rt = rs * Imm
    DIVI = 6'b001100,   //rt = rs / Imm
    SLTI = 6'b001101,   //rt = rs < Imm

    BEQ = 6'b001110,    //if(rs==rt) pc+=offset
    
    LW = 6'b010001,     //rt = *(int*)(offset+rs)
    SW = 6'b010010,     //*(int*)(offset+rs) = rt

    HLT = 6'b111111,    //HALT System
    
    //Instruction Type
    RR_ALU = 3'b000,
    RM_ALU = 3'b001,
    LOAD   = 3'b010,
    STORE  = 3'b011,
    BRANCH = 3'b100,
    HALT   = 3'b111;

    reg HALTED;         //if(HLT detected) HALTED=1

    reg TAKEN_BRANCH;   //if(BRANCH detected) TAKEN_BRANCH=l

    //IF Stage
    always @(posedge clk1)
    begin
        if(HALTED==0)
        begin
            if(EX_MEM_IR[31:26]==BEQ && EX_MEM_BEQ_Cond==1)
            begin
                IF_ID_IR <= #2 Mem[EX_MEM_ALUOut];
                IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;
                PC <= #2 EX_MEM_ALUOut + 1;            //Inccreasing program counter by one
                TAKEN_BRANCH <= #2 1'b1;
            end
            else
            begin
                IF_ID_IR <= #2 Mem[PC];
                IF_ID_NPC <= #2 PC + 1;
                PC <= #2 PC + 1;            //Inccreasing program counter by one
            end
        end
    end

    //ID Stage
    always @(posedge clk2)
    begin
        if(HALTED==0)
            begin
                //rs
                if(IF_ID_IR[25:21]==5'b00000)
                    begin
                        ID_EX_A <= 5'b00000;                        
                    end
                else
                    begin
                        ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];
                    end
                //rt
                if(IF_ID_IR[20:16]==5'b00000)
                    begin
                        ID_EX_B <= 5'b00000;
                    end
                else
                    begin
                        ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];
                    end

                case (IF_ID_IR[31:26])
                    ADD, SUB, MUL, DIV, SLT, AND, OR, SLL, SRL: 
                        ID_EX_TYPE <= #2 RR_ALU;
                    ADDI, SUBI, MULI, DIVI, SLTI:
                        ID_EX_TYPE <= #2 RM_ALU;
                    BEQ:
                        ID_EX_TYPE <= #2 BRANCH;
                    LW:
                        ID_EX_TYPE <= #2 LOAD;
                    SW:
                        ID_EX_TYPE <= #2 STORE;
                    HLT:
                        ID_EX_TYPE <= #2 HALT;
                    default:
                        ID_EX_TYPE <= #2 HALT;
                endcase

                ID_EX_IR <= #2 IF_ID_IR;
                ID_EX_NPC <= #2 IF_ID_NPC;
                ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
            end
    end

    //EX Stage
    always @(posedge clk1)
    begin
        if(HALTED==0)
        begin
            EX_MEM_IR <= #2 ID_EX_IR;
            EX_MEM_TYPE <= #2 ID_EX_TYPE;
            TAKEN_BRANCH <= #2 1'b0;
            case(ID_EX_TYPE)
                RR_ALU:
                    begin
                        case(ID_EX_IR[31:26])
                            ADD:
                                EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
                            SUB:
                                EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
                            MUL:
                                EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
                            DIV:
                                EX_MEM_ALUOut <= #2 ID_EX_A / ID_EX_B;
                            SLT:
                                EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
                            AND:
                                EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
                            OR:
                                EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
                            SLL:
                                EX_MEM_ALUOut <= #2 ID_EX_B << ID_EX_A;
                            SRL:
                                EX_MEM_ALUOut <= #2 ID_EX_B >> ID_EX_A;
                        endcase
                    end
                RM_ALU:
                    begin
                        case(ID_EX_IR[31:26])
                            ADDI:
                                EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                            SUBI:
                                EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
                            MULI:
                                EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_Imm;
                            DIVI:
                                EX_MEM_ALUOut <= #2 ID_EX_A / ID_EX_Imm;
                            SLTI:
                                EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
                        endcase
                    end
                BRANCH:
                    begin
                        if(ID_EX_IR[31:26]==BEQ)
                        begin
                            EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;
                            EX_MEM_BEQ_Cond <= (ID_EX_A == ID_EX_B);
                        end
                    end
                LOAD, STORE:
                    begin
                        EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                        EX_MEM_B <= #2 ID_EX_B;
                    end
            endcase
        end
    end

    //MEM Stage
    always @(posedge clk2)
    begin
        if(HALTED==0)
        begin
            MEM_WB_TYPE <= #2 EX_MEM_TYPE;
            MEM_WB_IR <= #2 EX_MEM_IR;
            case(EX_MEM_TYPE)
                RR_ALU, RM_ALU:
                    MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;
                LOAD:
                    MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];
                STORE:
                begin
                    if(TAKEN_BRANCH == 0)    //Disbale writing
                        begin                            
                            Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;      //Writing in Memory                                
                        end
                end
            endcase
        end    
    end

    //WB Stage
    always @(posedge clk1)
    begin
        if(TAKEN_BRANCH==0)
        begin
            case(MEM_WB_TYPE)
                RR_ALU:
                    Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut;  //In rd
                RM_ALU:
                    Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut;  //In rt
                LOAD:
                    Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;     //In rt
                HALT:
                    HALTED <= #2 1'b1;
            endcase
        end
    end
endmodule

