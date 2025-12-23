module key_filter
#(
    parameter CNT_MAX = 32'd50_000,
    parameter MS_CNT_MAX = 32'd20
)
(
    input       wire                sys_clk,
    input       wire                sys_rst_n,
    input       wire                key_input,

    output      reg                 key_flag
);
reg     [31:0]          cnt;
reg     [31:0]          ms_cnt;

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if(sys_rst_n == 1'b0)
        cnt <= 32'd0;
    else if((cnt == CNT_MAX - 32'd1) && (key_input == 1'd0))
        cnt <= 32'd0;
    else if(key_input == 1'd0)
        cnt <= cnt + 32'd1;
    else
        cnt <= 32'd0;
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if(sys_rst_n == 1'b0)
        ms_cnt <= 32'd0;
    else if(key_input == 1'd1)
        ms_cnt <= 32'd0;
    else if((cnt == CNT_MAX - 32'd1) && (ms_cnt <= MS_CNT_MAX))
        ms_cnt <= ms_cnt + 1;
    else
        ms_cnt <= ms_cnt;
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if(sys_rst_n == 1'b0)
        key_flag <= 1'd0;
    else if((cnt == CNT_MAX - 32'd1) && (ms_cnt == MS_CNT_MAX))
        key_flag <= 1'd1;
    else
        key_flag <= 1'd0;
end

endmodule
