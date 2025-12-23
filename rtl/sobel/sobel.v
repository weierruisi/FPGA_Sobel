module sobel
#(
    parameter PIC_W = 24'd480,
    parameter PIC_H = 24'd272,

    parameter THRESHOLD = 9'd112
)
(
    input       wire            tft_clk,
    input       wire            tft_rst,
    input       wire            ip_flag,
    input       wire    [7:0]   ip_data,

    output      reg             op_flag,
    output      wire     [7:0]   op_data
);


// Optimized counters (12-bit suffices for 4096 resolution, covering 1280x720)
reg [11:0]   col_cnt;
reg [11:0]   row_cnt;
wire        wr_req1;
wire        wr_req2;
wire        rd_req;
reg         trans_flag;

wire [7:0]  data_r1;
wire [7:0]  data_r2;
reg  [7:0]  data_r3;

reg [1:0]   reg_cnt;
reg         sobel_en;
reg         cacu_en;
reg [7:0]   reg0;
reg [7:0]   reg1;
reg [7:0]   reg2;
reg [7:0]   reg3;
reg [7:0]   reg4;
reg [7:0]   reg5;
reg [7:0]   reg6;
reg [7:0]   reg7;
reg [7:0]   reg8;

// Result registers need to be signed 11-bit or larger
// Max value: (255-0) + 2*(255-0) + (255-0) = 1020
// Min value: (0-255) + 2*(0-255) + (0-255) = -1020
// 11 bits signed range: -1024 to +1023. Ideally use 12 bits for safety and easier routing.
reg signed [11:0]   res_x;
reg signed [11:0]   res_y;

reg         aclr;
reg [23:0]   op_cnt;
reg [10:0]   sum_data; // Unsigned sum of absolute values

assign wr_req1 = ip_flag;
assign wr_req2 = (row_cnt >= 12'd1) ? ip_flag : 1'd0;
assign rd_req = (row_cnt >= 12'd2) ? ip_flag : 1'd0;

// Column Counter
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        col_cnt <= 12'd0;
    else if(ip_flag) begin
        if(col_cnt == PIC_W - 12'd1)
            col_cnt <= 12'd0;
        else
            col_cnt <= col_cnt + 12'd1;
    end
end

// Row Counter
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        row_cnt <= 12'd0;
    else if(ip_flag && (col_cnt == PIC_W - 12'd1)) begin
        if(row_cnt == PIC_H - 12'd1)
            row_cnt <= 12'd0;
        else
            row_cnt <= row_cnt + 12'd1;
    end
end

// Data Shift Register 3
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        data_r3 <= 8'd0;
    else if(rd_req)
        data_r3 <= ip_data;
end

// Trans Flag
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        trans_flag <= 1'd0;
    else
        trans_flag <= rd_req;
end

// Register Load Counter
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        reg_cnt <= 2'd0;
    else if(trans_flag && (reg_cnt <= 2'd2))
        reg_cnt <= reg_cnt + 2'd1;
end

// Sobel Enable
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        sobel_en <= 1'd0;
    else if(trans_flag && (reg_cnt >= 2'd2) &&
           ((col_cnt >= 12'd3) && (col_cnt <= PIC_W - 12'd1) || (col_cnt == 12'd0)))
        sobel_en <= 1'd1;
    else
        sobel_en <= 1'd0;
end

// 3x3 Window Registers
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst) begin
        reg0 <= 8'd0; reg1 <= 8'd0; reg2 <= 8'd0;
        reg3 <= 8'd0; reg4 <= 8'd0; reg5 <= 8'd0;
        reg6 <= 8'd0; reg7 <= 8'd0; reg8 <= 8'd0;
    end
    else if(trans_flag) begin
        if(reg_cnt == 2'd0) begin
            reg0 <= data_r1;
            reg1 <= data_r2;
            reg2 <= data_r3;
        end
        else if(reg_cnt == 2'd1) begin
            reg3 <= data_r1;
            reg4 <= data_r2;
            reg5 <= data_r3;
        end
        else if(reg_cnt == 2'd2) begin
            reg6 <= data_r1;
            reg7 <= data_r2;
            reg8 <= data_r3;
        end
        else if(reg_cnt == 2'd3) begin
            reg0 <= reg3;
            reg1 <= reg4;
            reg2 <= reg5;
            reg3 <= reg6;
            reg4 <= reg7;
            reg5 <= reg8;
            reg6 <= data_r1;
            reg7 <= data_r2;
            reg8 <= data_r3;
        end
    end
end

// Sobel X Calculation
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        res_x <= 12'd0;
    else if(sobel_en)
        // Use signed arithmetic with extended precision to avoid underflow/overflow
        // Casting 8-bit unsigned to 12-bit signed: $signed({4'b0, reg})
        res_x <= ($signed({4'b0, reg6}) - $signed({4'b0, reg0})) +
                 (($signed({4'b0, reg7}) - $signed({4'b0, reg1})) <<< 1) +
                 ($signed({4'b0, reg8}) - $signed({4'b0, reg2}));
end

// Sobel Y Calculation
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        res_y <= 12'd0;
    else if(sobel_en)
        res_y <= ($signed({4'b0, reg2}) - $signed({4'b0, reg0})) +
                 (($signed({4'b0, reg5}) - $signed({4'b0, reg3})) <<< 1) +
                 ($signed({4'b0, reg8}) - $signed({4'b0, reg6}));
end

// Calculation Enable
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        cacu_en <= 1'd0;
    else
        cacu_en <= sobel_en;
end

// Output Flag
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        op_flag <= 1'd0;
    else
        op_flag <= cacu_en;
end

// Sum Data (Absolute Value)
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        sum_data <= 11'd0;
    else if(cacu_en) begin
        // Take absolute value of signed results
        sum_data <= (res_x[11] ? (~res_x + 12'd1) : res_x) +
                   (res_y[11] ? (~res_y + 12'd1) : res_y);
    end
end

// // Output Data
// assign op_data = sum_data[10:3]; // Simple scaling or use threshold
// // assign op_data = (sum_data >= THRESHOLD) ? 8'd255 : 8'd0;

// Use saturation instead of simple shifting to improve contrast.
// The previous sum_data[10:3] divided the result by 8, making edges very faint.
// Now we check if the sum exceeds 255, and if so, clamp it to 255.
assign op_data = (sum_data > 11'd255) ? 8'd255 : sum_data[7:0];

// Output Counter
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        op_cnt <= 24'd0;
    else if(op_flag) begin
        if(op_cnt == (PIC_W-24'd2)*(PIC_H-24'd2) - 1)
            op_cnt <= 24'd0;
        else
            op_cnt <= op_cnt + 24'd1;
    end
end

// Auto Clear
always @(posedge tft_clk or negedge tft_rst) begin
    if(!tft_rst)
        aclr <= 1'd0;
    else if(op_flag && (op_cnt == (PIC_W-24'd2)*(PIC_H-24'd2) - 1))
        aclr <= 1'd1;
    else
        aclr <= 1'd0;
end


fifo_sobel	fifo_sobel_inst1
(
	.aclr ( aclr|(!tft_rst) ),
	.clock ( tft_clk ),
	.data ( ip_data ),
	.rdreq ( rd_req ),
	.wrreq ( wr_req1 ),

	.empty (  ),
	.full (  ),
	.q ( data_r1 ),
	.usedw (  )
);

fifo_sobel	fifo_sobel_inst2
(
	.aclr ( aclr|(!tft_rst) ),
	.clock ( tft_clk ),
	.data ( ip_data ),
	.rdreq ( rd_req ),
	.wrreq ( wr_req2 ),

	.empty (  ),
	.full (  ),
	.q ( data_r2 ),
	.usedw (  )
);

endmodule
