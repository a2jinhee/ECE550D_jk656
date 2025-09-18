//// Moore mod 5 counter with input w and synchronous active high reset
//// Output event y is internal and depends only on present state
//
//module mod5 (
//    input  wire       clk,
//    input  wire       rst,   // synchronous active high
//    input  wire       w,
//    output reg  [2:0] count, // visible count 0..4
//    output reg  [2:0] state  // present state register
//);
//
//    reg [2:0] next_state;
//
//    // Next state logic
//    always @* begin
//        next_state = 3'd0;
//        case (state)
//            3'd0: next_state = w ? 3'd1 : 3'd0;
//            3'd1: next_state = w ? 3'd2 : 3'd1;
//            3'd2: next_state = w ? 3'd3 : 3'd2;
//            3'd3: next_state = w ? 3'd4 : 3'd3;
//            3'd4: next_state = w ? 3'd0 : 3'd4;
//            default: next_state = 3'd0; // recover 5 6 7 to 0
//        endcase
//    end
//
//    // State register with synchronous reset
//    always @(posedge clk) begin
//        if (rst) state <= 3'd0;
//        else     state <= next_state;
//    end
//
//    // Moore style internal pulse at state 4
//    wire y = (state == 3'd4);
//
//    // Expose count as 0..4
//    always @* begin
//        case (state)
//            3'd0,3'd1,3'd2,3'd3,3'd4: count = state;
//            default:                  count = 3'd0;
//        endcase
//    end
//
//endmodule
//






// Mealy mod 5 counter with input w and synchronous active high reset
// Output event y is internal and depends on present state and w

module mod5 (
    input  wire       clk,
    input  wire       rst,   // synchronous active high
    input  wire       w,
    output reg  [2:0] count, // visible count 0..4
    output reg  [2:0] state  // present state register
);

    reg [2:0] next_state;

    // Next state logic
    always @* begin
        next_state = 3'd0;
        case (state)
            3'd0: next_state = w ? 3'd1 : 3'd0;
            3'd1: next_state = w ? 3'd2 : 3'd1;
            3'd2: next_state = w ? 3'd3 : 3'd2;
            3'd3: next_state = w ? 3'd4 : 3'd3;
            3'd4: next_state = w ? 3'd0 : 3'd4;
            default: next_state = 3'd0; // recover 5 6 7 to 0
        endcase
    end

    // State register with synchronous reset
    always @(posedge clk) begin
        if (rst) state <= 3'd0;
        else     state <= next_state;
    end

    // Mealy style internal pulse
    // y is 1 when at state 3 with w 1 or at state 4 with w 0
    wire y = ((state == 3'd3) & w) | ((state == 3'd4) & ~w);

    // Expose count as 0..4
    always @* begin
        case (state)
            3'd0,3'd1,3'd2,3'd3,3'd4: count = state;
            default:                  count = 3'd0;
        endcase
    end

endmodule