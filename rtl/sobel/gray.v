module gray
(
    input       wire            tft_clk,
    input       wire            tft_rst,
    input       wire    [15:0]  gray_ip_data,
    input       wire            gray_ip_flag,

    output      wire             gray_op_flag,
    output      wire     [7:0]   gray_op_data
);

wire [15:0]   r;
wire [15:0]   g;
wire [15:0]   b;

assign r = gray_ip_data[15:11];
assign g = gray_ip_data[10:5];
assign b = gray_ip_data[4:0];
assign gray_op_data = (r*76 + g*150 + b*30) >> 6;

assign gray_op_flag = gray_ip_flag;

endmodule
