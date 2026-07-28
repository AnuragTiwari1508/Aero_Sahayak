// db_calculator.v v3
module db_calculator (
    input  wire        clk,
    input  wire [31:0] mag_in,
    input  wire        mag_valid,
    input  wire        mag_last,
    output reg  [31:0] db_out,
    output reg         db_valid,
    output reg         db_last
);
    wire [15:0] mag = mag_in[15:0];
    reg  [3:0]  lz;
    always @(*) begin
        if      (mag>=16'h8000) lz=4'd15; else if (mag>=16'h4000) lz=4'd14;
        else if (mag>=16'h2000) lz=4'd13; else if (mag>=16'h1000) lz=4'd12;
        else if (mag>=16'h0800) lz=4'd11; else if (mag>=16'h0400) lz=4'd10;
        else if (mag>=16'h0200) lz=4'd9;  else if (mag>=16'h0100) lz=4'd8;
        else if (mag>=16'h0080) lz=4'd7;  else if (mag>=16'h0040) lz=4'd6;
        else if (mag>=16'h0020) lz=4'd5;  else if (mag>=16'h0010) lz=4'd4;
        else if (mag>=16'h0008) lz=4'd3;  else if (mag>=16'h0004) lz=4'd2;
        else if (mag>=16'h0002) lz=4'd1;  else                    lz=4'd0;
    end
    always @(posedge clk) begin
        db_out   <= {28'd0,lz} * 32'd6;
        db_valid <= mag_valid;
        db_last  <= mag_last;
    end
endmodule
