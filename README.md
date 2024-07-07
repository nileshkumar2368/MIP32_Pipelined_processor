# MIP32_Pipelined_Processor
Processor based on MIP32 Instruction Set Architecture(ISA) which can perform basic arithmetic operations and logical operations and can perform conditional branching. This processor can store and read data from a bank of registers using pipelining.

The instructions are performed with the cycle as follows:

1. Instruction Feteching(IF)
2. Instruction Decoding(ID)
3. Execution(EX)
4. Accessing Memory(MEM)
5. Writing Back in registers(WB)

Processor can perform the following operations:

1. Addition
2. Subtraction
3. Multiplication
4. Division
5. Comparing two numbers
6. And
7. Or
8. Branching
9. Data Loading
10. Data Storing
    
I have provided a basic test bench code while using all of the operations.
