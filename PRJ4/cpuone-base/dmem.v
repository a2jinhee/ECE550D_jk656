// You need to generate this component correctly
module dmem (
    input [11:0] address,
    input clock,
    input [31:0] data,
    input wren,
    output [31:0] q
);
    altsyncram #(
        .operation_mode("SINGLE_PORT"),
        .width_a(32),
        .widthad_a(12),
        .numwords_a(4096),
        .outdata_reg_a("UNREGISTERED"),
        .init_file("dmem.mif")
    ) dmem_mem (
        .clock0(clock),
        .address_a(address),
        .data_a(data),
        .wren_a(wren),
        .q_a(q),
        .aclr0(1'b0),
        .aclr1(1'b0),
        .clock1(1'b0),
        .address_b(1'b0),
        .data_b(32'b0),
        .wren_b(1'b0),
        .q_b()
    );
endmodule