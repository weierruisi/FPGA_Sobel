module sobel_top
#(
    parameter PIC_W = 24'd480,
    parameter PIC_H = 24'd272,

    parameter THRESHOLD = 9'd50
)
(
    input       wire            tft_clk,
    input       wire            tft_rst,
    input       wire    [15:0]  ip_data,
    input       wire            ip_flag,

    output      wire            op_flag,
    output      wire     [7:0]   op_data
);

wire            gray_op_flag;
wire    [7:0]   gray_op_data;

gray gray_inst
(
    .tft_clk        (tft_clk),
    .tft_rst        (tft_rst),
    .gray_ip_data   (ip_data),
    .gray_ip_flag   (ip_flag),

    .gray_op_flag   (gray_op_flag),
    .gray_op_data   (gray_op_data)
);

sobel
#(
    .PIC_W  (PIC_W),
    .PIC_H  (PIC_H),

    .THRESHOLD  (THRESHOLD)
)sobel_inst
(
    .tft_clk    (tft_clk),
    .tft_rst    (tft_rst),
    .ip_flag    (gray_op_flag),
    .ip_data    (gray_op_data),

    .op_flag    (op_flag),
    .op_data    (op_data)
);

endmodule
