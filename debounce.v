module debounce #
(
    parameter integer RISE_STABLE = 10000,   // cycles required for low→high
    parameter integer FALL_STABLE = 10000    // cycles required for high→low
)
(
    input  wire clk,          // 100 MHz clock
    input  wire rst,          // synchronous reset
    input  wire sig_in,       // asynchronous noisy input
    output reg  sig_out       // debounced output
);

    // -----------------------------
    // 2-Flip-Flop Synchronizer
    // -----------------------------
    reg sync_1;
    reg sync_2;

    always @(posedge clk) begin
        if (rst) begin
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
        end else begin
            sync_1 <= sig_in;     // first stage
            sync_2 <= sync_1;     // second stage (synchronized signal)
        end
    end

    // -----------------------------
    // Debounce Logic
    // -----------------------------
    reg        prev_in;
    reg [15:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            sig_out <= 1'b0;
            prev_in <= 1'b0;
            counter <= 16'd0;
        end else begin

            // Use synchronized input (sync_2)
            if (sync_2 != prev_in) begin
                prev_in <= sync_2;
                counter <= 16'd0;
            end else begin
                // Count stable cycles
                if (counter < 16'hFFFF)
                    counter <= counter + 16'd1;

                // LOW → HIGH transition
                if (sig_out == 1'b0 && prev_in == 1'b1) begin
                    if (counter >= RISE_STABLE)
                        sig_out <= 1'b1;
                end
                // HIGH → LOW transition
                else if (sig_out == 1'b1 && prev_in == 1'b0) begin
                    if (counter >= FALL_STABLE)
                        sig_out <= 1'b0;
                end
            end
        end
    end

endmodule
