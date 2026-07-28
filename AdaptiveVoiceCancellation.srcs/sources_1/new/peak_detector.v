// peak_detector.v v3
module peak_detector (
    input  wire        clk,
    input  wire        resetn,
    input  wire [31:0] din,
    input  wire        din_valid,
    input  wire        din_last,
    output reg  [31:0] peak_mag,
    output reg  [15:0] peak_bin,
    output reg         data_valid
);
    reg [15:0] bin_cnt;
    reg [31:0] curr_max;
    reg [15:0] curr_bin;
    always @(posedge clk) begin
        if (!resetn) begin
            curr_max<=0; curr_bin<=0; peak_mag<=0;
            peak_bin<=0; data_valid<=0; bin_cnt<=0;
        end else begin
            data_valid <= 0;
            if (din_valid) begin
                if (din > curr_max) begin curr_max<=din; curr_bin<=bin_cnt; end
                if (din_last) begin
                    peak_mag<=curr_max; peak_bin<=curr_bin;
                    data_valid<=1'b1;
                    curr_max<=0; curr_bin<=0; bin_cnt<=0;
                end else bin_cnt <= bin_cnt+1;
            end
        end
    end
endmodule
