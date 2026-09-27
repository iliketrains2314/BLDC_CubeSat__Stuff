`timescale 1ns / 1ps

module TOP_tb();

    // Testbench signals
    logic clk;
    logic rst;
    logic [15:0] speed;
    logic [15:0] torque;
    logic [7:0] trap_percent;
    logic [5:0] mosfet_out;
    
    // Clock generation - 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT instantiation
    TOP dut (
        .clk(clk),
        .rst(rst),
        .speed(speed),
        .torque(torque),
        .trap_percent(trap_percent),
        .mosfet_out(mosfet_out)
    );
    
    // Stimulus
    initial begin
        // Initialize signals
        rst = 1;
        speed = 16'h0000;
        torque = 16'h0000;
        trap_percent = 8'd0;
        
        $display("========================================");
        $display("  100%% Torque + 100%% Trapezoid Test");
        $display("========================================");
        
        repeat(10) @(posedge clk);
        rst = 0;
        @(posedge clk);
        
        repeat(100) @(posedge clk);
        
        // Set to 100% torque and 100% trapezoid (clamped to 50% = triangle wave)
        speed = 16'h00FF;      // Moderate speed to clearly see waveform
        torque = 16'hFFFF;     // 100% torque (maximum duty cycle)
        trap_percent = 8'd100; // 100% trapezoid (will be clamped to 50%)
        
        $display("Configuration:");
        $display("  Speed      = 0x%04h", speed);
        $display("  Torque     = 0x%04h = 100%% duty cycle", torque);
        $display("  Trap %%     = %0d%% (requested)", trap_percent);
        
        repeat(10) @(posedge clk);
        
        $display("Calculated Parameters:");
        $display("  Step period = %0d clocks", dut.step_period);
        
        // Run for multiple electrical cycles
        $display("Running simulation...");
        repeat(1200000) @(posedge clk);
        
        $display("Simulation complete");
        $finish;
    end
    
    // Monitor commutation step changes
    logic [2:0] prev_step;
    integer step_count;
    
    initial begin
        prev_step = 3'd0;
        step_count = 0;
        
        forever begin
            @(posedge clk);
            if (dut.commutation_step != prev_step) begin
                step_count = step_count + 1;
                $display("Step %0d: %0d -> %0d, MOSFET=0b%06b", 
                         step_count, prev_step, dut.commutation_step, mosfet_out);
                prev_step = dut.commutation_step;
            end
        end
    end
    
    // Sample PWM duty at key points
    integer sample_point;
    integer pwm_count;
    integer i;
    
    initial begin
        forever begin
            @(posedge clk);
            
            // Sample at 0%, 25%, 50%, 75%, 100% of step
            for (sample_point = 0; sample_point <= 4; sample_point = sample_point + 1) begin
                if (dut.step_counter == ((dut.step_period * sample_point) / 4)) begin
                    pwm_count = 0;
                    for (i = 0; i < 1024; i = i + 1) begin
                        @(posedge clk);
                        if (dut.pwm_signal) pwm_count = pwm_count + 1;
                    end
                    $display("  [%0d%% through step] PWM duty = %0d/1024", 
                             sample_point * 25, pwm_count);
                end
            end
        end
    end

endmodule