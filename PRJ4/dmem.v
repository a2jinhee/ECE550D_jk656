// You need to generate this component correctly
module dmem (
    input  [11:0] address,
    input         clock,
    input  [31:0] data,
    input         wren,
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
        // Port A (used)
        .address_a(address),
        .clock0(clock),
        .data_a(data),
        .wren_a(wren),
        .q_a(q)

        // No Port B or clock1 signals
    );
endmodule