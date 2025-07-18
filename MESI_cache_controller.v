module mesi_cache_controller (
    input clk,
    input reset,
    input pr_rd,
    input pr_wr,
    input bus_rd_seen,
    input bus_rdx_seen,
    input shared_line,

    output reg bus_rd,
    output reg bus_rdx,
    output reg flush,
    output reg [1:0] mesi_state
);
    localparam I = 2'b00, S = 2'b01, E = 2'b10, M = 2'b11;
    reg [1:0] state, next_state;

 always @(*) begin
        bus_rd = 0; bus_rdx = 0; flush = 0; next_state = state;



case (state)
            I: begin
                if (pr_rd) begin
                    bus_rd = 1;
                    if (shared_line) next_state = S;
                    else next_state = E;
                end else if (pr_wr) begin
                    bus_rdx = 1;
                    next_state = M;
                end
            end
            S: begin
                if (pr_rd) next_state = S;
                else if (pr_wr) begin
                    bus_rdx = 1;
                    next_state = M;
                end else if (bus_rd_seen) next_state = S;
                else if (bus_rdx_seen) next_state = I;
            end
            E: begin
                if (pr_rd) next_state = E;
                else if (pr_wr) next_state = M;
                else if (bus_rd_seen) begin flush = 1; next_state = S; end
                else if (bus_rdx_seen) next_state = I;
            end
            M: begin
                if (pr_rd || pr_wr) next_state = M;
                else if (bus_rd_seen) begin flush = 1; next_state = S; end
                else if (bus_rdx_seen) begin flush = 1; next_state = I; end
            end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) state <= I;
        else state <= next_state;
    end
always @(*) mesi_state = state;
endmodule
