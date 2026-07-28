// sample_controller.v v3
module sample_controller #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 16,
    parameter N_SAMPLES  = 1024
)(
    input  wire                  clk,
    input  wire                  resetn,
    output reg  [ADDR_WIDTH-1:0] addra,
    output wire                  ena,
    input  wire [DATA_WIDTH-1:0] sample_in,
    output reg  [DATA_WIDTH-1:0] sample_out,
    output reg                   tvalid,
    input  wire                  tready,
    output reg                   tlast
);
    assign ena = 1'b1;
    localparam IDLE=2'd0, READ=2'd1, WAIT=2'd2, DONE=2'd3;
    reg [1:0] state;
    reg [ADDR_WIDTH-1:0] cnt;
    always @(posedge clk) begin
        if (!resetn) begin
            state<=IDLE; addra<=0; cnt<=0;
            sample_out<=0; tvalid<=0; tlast<=0;
        end else case (state)
            IDLE: begin addra<=0; cnt<=0; tvalid<=0; tlast<=0; state<=READ; end
            READ: begin addra<=cnt; state<=WAIT; end
            WAIT: begin
                sample_out <= sample_in;
                tvalid     <= 1'b1;
                tlast      <= (cnt==N_SAMPLES-1) ? 1'b1 : 1'b0;
                if (tready) begin
                    if (cnt==N_SAMPLES-1) begin cnt<=0; state<=DONE; end
                    else begin cnt<=cnt+1; state<=READ; end
                end
            end
            DONE: begin tvalid<=0; tlast<=0; state<=IDLE; end
        endcase
    end
endmodule
