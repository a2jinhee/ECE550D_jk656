// You need to generate this component correctly
module imem (
    input [11:0] address,
    input clock,
    output [31:0] q
);
    altsyncram #(
        .operation_mode("ROM"),
        .width_a(32),
        .widthad_a(12),
        .numwords_a(4096),
        .outdata_reg_a("UNREGISTERED"),
        .init_file("imem.mif")
    ) imem_mem (
        .clock0(clock),
        .address_a(address),
        .q_a(q),
        .wren_a(1'b0),
        .data_a(32'b0),
        .aclr0(1'b0),
        .aclr1(1'b0),
        .clock1(1'b0),
        .address_b(1'b0),
        .data_b(32'b0),
        .wren_b(1'b0),
        .q_b()
    );
endmodule