// alu.v
`timescale 1ns/1ps
module alu(
    input  [31:0] data_operandA,
    input  [31:0] data_operandB,
    input  [4:0]  ctrl_ALUopcode,
    input  [4:0]  ctrl_shiftamt,
    output reg [31:0] data_result,
    output reg        isNotEqual,
    output reg        isLessThan,
    output reg        overflow
);

    // Opcode encodings
    localparam OP_ADD = 5'b00000;
    localparam OP_SUB = 5'b00001;
    localparam OP_AND = 5'b00010;
    localparam OP_OR  = 5'b00011;
    localparam OP_SLL = 5'b00100;
    localparam OP_SRA = 5'b00101;

    // Precompute candidates
    wire [31:0] add_res = data_operandA + data_operandB;
    wire [31:0] sub_res = data_operandA - data_operandB;
    wire [31:0] sll_res = data_operandA << ctrl_shiftamt;

    // Overflow flags for two complement math
    wire add_ovf = (data_operandA[31] == data_operandB[31]) && (add_res[31] != data_operandA[31]);
    wire sub_ovf = (data_operandA[31] != data_operandB[31]) && (sub_res[31] == data_operandB[31]);

    // Signed less than using operands
    wire signed_less = ($signed(data_operandA) < $signed(data_operandB));
    wire notequal    = |sub_res;  // nonzero after subtraction

    always @* begin
        // Defaults
        data_result = 32'd0;
        isNotEqual  = 1'b0;
        isLessThan  = 1'b0;
        overflow    = 1'b0;

        case (ctrl_ALUopcode)
            OP_ADD: begin
                data_result = add_res;
                overflow    = add_ovf;
                // isNotEqual and isLessThan only need to be correct after SUB
            end
            OP_SUB: begin
                data_result = sub_res;
                overflow    = sub_ovf;
                isNotEqual  = notequal;
                isLessThan  = signed_less;
            end
            OP_SLL: begin
                data_result = sll_res;
            end
            // The following are present for completeness if you later expand
            OP_AND: begin
                data_result = data_operandA & data_operandB;
            end
            OP_OR: begin
                data_result = data_operandA | data_operandB;
            end
            OP_SRA: begin
                data_result = $signed(data_operandA) >>> ctrl_shiftamt;
            end
            default: begin
                data_result = 32'd0;
            end
        endcase
    end
endmodule