// magnitude_calculator.v v3
module magnitude_calculator (
    input  wire        clk,
    input  wire [31:0] din,
    input  wire        din_valid,
    input  wire        din_last,
    output reg  [31:0] mag_out,
    output reg         mag_valid,
    output reg         mag_last
);
    wire signed [15:0] re     = din[15:0];
    wire signed [15:0] im     = din[31:16];
    wire        [15:0] abs_re = re[15] ? (~re+1'b1) : re;
    wire        [15:0] abs_im = im[15] ? (~im+1'b1) : im;
    wire        [15:0] mx     = (abs_re>=abs_im) ? abs_re : abs_im;
    wire        [15:0] mn     = (abs_re>=abs_im) ? abs_im : abs_re;
    wire        [16:0] mag17  = {1'b0,mx} + {2'b00,mn[15:1]};
    always @(posedge clk) begin
        mag_out   <= {16'd0, mag17[15:0]};
        mag_valid <= din_valid;
        mag_last  <= din_last;
    end
endmodule
