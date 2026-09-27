module clock_divider (
    input wire clk_100mhz,
    output reg clk_5mhz
);
    // 100MHz / 5MHz = 20
    // Toggle every 10 cycles for 50% duty cycle
    localparam DIVISOR = 10;
    
    reg [3:0] counter; // 4 bits needed for counting to 10
    
    always @(posedge clk_100mhz) begin
        if (counter == DIVISOR - 1) begin
            counter <= 0;
            clk_5mhz <= ~clk_5mhz; // Toggle output
        end
        else begin
            counter <= counter + 1;
        end
    end
endmodule