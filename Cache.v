module cache (
    input clk,
    input reset,
    input [12:0] addr,
    input pr_rd,
    input pr_wr,
    input [31:0] data_in,
    input bus_rd_seen,
    input bus_rdx_seen,
    input shared_line,
    input [31:0] data_from_mem,
    output reg mem_read,
    output reg [31:0] data_out,
    output reg [31:0] flush_data,
    output reg hit,
    output bus_rd,
    output bus_rdx,
    output flush
);
    wire [4:0] index = addr[4:0];
    wire [7:0] tag   = addr[12:5];

    reg [31:0] data[0:31][0:1];
    reg [7:0] tags[0:31][0:1];
    reg valid[0:31][0:1];
    reg lru[0:31];


    reg [0:0] replace_way;
    reg [0:0] hit_way;
    reg pending_fill;

    wire [1:0] mesi_state_0, mesi_state_1;
    wire bus_rd_0, bus_rdx_0, flush_0;
    wire bus_rd_1, bus_rdx_1, flush_1;

    reg way_hit_0, way_hit_1;

    mesi_cache_controller fsm0 (
    .clk(clk), .reset(reset),
    .pr_rd(pr_rd && hit && hit_way == 0),
    .pr_wr(pr_wr && hit && hit_way == 0),
    .bus_rd_seen(bus_rd_seen),
    .bus_rdx_seen(bus_rdx_seen),
    .shared_line(shared_line),
    .bus_rd(bus_rd_0),
    .bus_rdx(bus_rdx_0),
    .flush(flush_0),
    .mesi_state(mesi_state_0)
);

    mesi_cache_controller fsm1 (
    .clk(clk), .reset(reset),
    .pr_rd(pr_rd && hit && hit_way == 1),
    .pr_wr(pr_wr && hit && hit_way == 1),
    .bus_rd_seen(bus_rd_seen),
    .bus_rdx_seen(bus_rdx_seen),
    .shared_line(shared_line),
    .bus_rd(bus_rd_1),
    .bus_rdx(bus_rdx_1),
    .flush(flush_1),
    .mesi_state(mesi_state_1)
);

    assign bus_rd  = bus_rd_0  | bus_rd_1;
    assign bus_rdx = bus_rdx_0 | bus_rdx_1;
    assign flush   = flush_0   | flush_1;

    always @(*) begin
        way_hit_0 = valid[index][0] && (tags[index][0] == tag) && mesi_state_0 != 2'b00;
        way_hit_1 = valid[index][1] && (tags[index][1] == tag) && mesi_state_1 != 2'b00;
        hit = way_hit_0 || way_hit_1;

        if (way_hit_0) begin hit_way = 0; data_out = data[index][0]; end
 else if (way_hit_1) begin hit_way = 1; data_out = data[index][1]; end
        else begin hit_way = 0; data_out = 32'h0; end
    end

    always @(posedge clk) begin
        if (reset) begin
            integer s, w;
            for (s = 0; s < 32; s = s + 1)
                for (w = 0; w < 2; w = w + 1)
                    begin data[s][w]<=0; tags[s][w]<=0; valid[s][w]<=0; end
            for (s = 0; s < 32; s = s + 1) lru[s]<=0;
            mem_read <= 0; pending_fill <= 0;
        end else begin
            if (pr_wr && hit)
                data[index][hit_way] <= data_in;

            if (!hit && (pr_rd || pr_wr) && !pending_fill) begin
                replace_way = lru[index];
                mem_read <= 1;
                pending_fill <= 1;
                if (replace_way == 0) begin tags[index][0] <= tag; valid[index][0] <= 0; lru[index] <= 1; end
                else begin tags[index][1] <= tag; valid[index][1] <= 0; lru[index] <= 0; end
            end else mem_read <= 0;

            if (pending_fill) begin
                if (replace_way == 0) begin data[index][0] <= data_from_mem; valid[index][0] <= 1; end
                else begin data[index][1] <= data_from_mem; valid[index][1] <= 1; end
                pending_fill <= 0;
            end

            if (mesi_state_0 == 2'b00) valid[index][0] <= 0;
            if (mesi_state_1 == 2'b00) valid[index][1] <= 0;
        end
    end

    always @(*) begin
        if (flush_0) flush_data = data[index][0];
        else if (flush_1) flush_data = data[index][1];
        else flush_data = 32'hDEADBEEF;
    end
endmodule