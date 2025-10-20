// You need to generate this component correctly
module imem (
    input  [11:0] address,
    input         clock,
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
        // Port A (used)
        .address_a(address),
        .clock0(clock),
        .q_a(q),

        // Tie off unused write ports
        .wren_a(1'b0),
        .data_a(32'b0)

        // All Port B and clock1 lines are omitted
    );
endmodule