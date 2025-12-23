`timescale 1ns/1ps

module soble_tb;

    // Parameters
    parameter PIC_W = 24'd10; // Small width for test
    parameter PIC_H = 24'd10; // Small height for test
    parameter THRESHOLD = 9'd112;

    // Inputs
    reg tft_clk;
    reg tft_rst;
    reg ip_flag;
    reg [7:0] ip_data;

    // Outputs
    wire op_flag;
    wire [7:0] op_data;

    // Instantiate the Unit Under Test (UUT)
    soble #(
        .PIC_W(PIC_W),
        .PIC_H(PIC_H),
        .THRESHOLD(THRESHOLD)
    ) uut (
        .tft_clk(tft_clk),
        .tft_rst(tft_rst),
        .ip_flag(ip_flag),
        .ip_data(ip_data),
        .op_flag(op_flag),
        .op_data(op_data)
    );

    // Clock generation
    initial begin
        tft_clk = 0;
        forever #5 tft_clk = ~tft_clk;
    end

    // Test sequence
    integer i, j;
    reg [7:0] test_image [0:PIC_H-1][0:PIC_W-1];

    initial begin
        // Initialize Inputs
        tft_rst = 0;
        ip_flag = 0;
        ip_data = 0;

        // Create a test image with a vertical edge
        // Left half 0, right half 255
        for (i = 0; i < PIC_H; i = i + 1) begin
            for (j = 0; j < PIC_W; j = j + 1) begin
                if (j < PIC_W/2)
                    test_image[i][j] = 8'd0;
                else
                    test_image[i][j] = 8'd255;
            end
        end

        // Wait for global reset
        #100;
        tft_rst = 1;
        #20;

        // Send pixel data
        for (i = 0; i < PIC_H; i = i + 1) begin
            for (j = 0; j < PIC_W; j = j + 1) begin
                @(posedge tft_clk);
                ip_flag = 1;
                ip_data = test_image[i][j];
            end
            // Small gap between lines if needed, or continuous
            // @(posedge tft_clk);
            // ip_flag = 0;
        end

        @(posedge tft_clk);
        ip_flag = 0;

        // Wait for operations to complete
        #1000;

        $stop;
    end

endmodule
