module bemf_speed_estimator #(
    parameter integer VALID_PULSE_LEN = 64,   // stretch valid so CPU/IRQ logic can catch it
    parameter integer MIN_PERIOD       = 16    // reject tiny glitch measurements
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        sig_in,        // raw comparator output (async)
    input  wire [5:0]  mos_state,     // sector/state gating
    output reg  [31:0] period,        // latched overlap width in clk cycles
    output reg         valid          // stretched pulse when a new measurement is ready
);

    // ------------------------------------------------------------------------
    // Synchronize async comparator input into clk domain
    // ------------------------------------------------------------------------
    reg sig_meta, sig_sync;
    always @(posedge clk) begin
        if (rst) begin
            sig_meta <= 1'b0;
            sig_sync <= 1'b0;
        end else begin
            sig_meta <= sig_in;
            sig_sync <= sig_meta;
        end
    end

    // ------------------------------------------------------------------------
    // Measure how long overlap stays high
    // overlap is only meaningful in the desired MOSFET state
    // ------------------------------------------------------------------------
    reg [31:0] high_counter;
    reg        overlap_d;
    reg [31:0] valid_countdown;

    wire overlap      = mos_state[1] && sig_sync;
    wire overlap_rise = overlap && !overlap_d;
    wire overlap_fall = !overlap && overlap_d;

    always @(posedge clk) begin
        if (rst) begin
            high_counter    <= 32'd0;
            period          <= 32'd0;
            valid           <= 1'b0;
            valid_countdown <= 32'd0;
            overlap_d       <= 1'b0;
        end else begin
            // Track previous overlap state for edge detection
            overlap_d <= overlap;

            // Start of a new overlap window
            if (overlap_rise) begin
                high_counter <= 32'd1;
            end
            // Continue counting while overlap is high
            else if (overlap) begin
                if (high_counter != 32'hFFFF_FFFF)
                    high_counter <= high_counter + 32'd1;
            end
            // End of overlap window: latch only sane measurements
            else if (overlap_fall) begin
                if (high_counter >= MIN_PERIOD) begin
                    period          <= high_counter;
                    valid_countdown <= VALID_PULSE_LEN;
                end
                high_counter <= 32'd0;
            end

            // Stretch valid pulse so software/interrupt logic is less likely to miss it
            if (valid_countdown != 32'd0) begin
                valid           <= 1'b1;
                valid_countdown <= valid_countdown - 32'd1;
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule