module split3 (
    input  wire [2:0] in_bus,   // 3-bit input
    output wire       out0,     // LSB
    output wire       out1,
    output wire       out2      // MSB
);

    assign out0 = in_bus[0];
    assign out1 = in_bus[1];
    assign out2 = in_bus[2];

endmodule

module split4 (
    input  wire [3:0] in_bus,   // 3-bit input
    output wire       out0,     // LSB
    output wire       out1,
    output wire       out2,      // MSB
    output wire       out3
);

    assign out0 = in_bus[0];
    assign out1 = in_bus[1];
    assign out2 = in_bus[2];
    assign out3 = in_bus[3];

endmodule
