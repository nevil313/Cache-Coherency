module mesi_bus (
    input clk,
    input reset,
 // Cache 0 inputs
    input cache0_bus_rd,
    input cache0_bus_rdx,
    input cache0_flush,

 // Cache 1 inputs
    input cache1_bus_rd,
    input cache1_bus_rdx,
    input cache1_flush,

   // Outputs to cache 0
    output reg bus_rd_seen_0,
    output reg bus_rdx_seen_0,
    output reg shared_line_0,

 // Outputs to cache 1
    output reg bus_rd_seen_1,
    output reg bus_rdx_seen_1,
    output reg shared_line_1
);

    // Bus arbitration: one request per cycle allowed (fixed priority for now)
    reg [1:0] current_requestor; // 0: none, 1: cache0, 2: cache1
    reg bus_rd_active;
    reg bus_rdx_active;
    reg flush_seen;

    // Arbitration & propagation logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_requestor <= 2'b00;
            bus_rd_active <= 0;


            bus_rdx_active <= 0;
            flush_seen <= 0;

            bus_rd_seen_0 <= 0;
            bus_rdx_seen_0 <= 0;
            shared_line_0 <= 0;

            bus_rd_seen_1 <= 0;
            bus_rdx_seen_1 <= 0;
            shared_line_1 <= 0;
        end
        else begin
            // Default outputs
            bus_rd_seen_0 <= 0;
            bus_rdx_seen_0 <= 0;
            shared_line_0 <= 0;

            bus_rd_seen_1 <= 0;
            bus_rdx_seen_1 <= 0;
            shared_line_1 <= 0;

            // Fixed priority: cache0 > cache1
            if (cache0_bus_rd) begin
                current_requestor <= 2'b01;
                bus_rd_active <= 1;
                bus_rdx_active <= 0;
            end else if (cache0_bus_rdx) begin
                current_requestor <= 2'b01;
                bus_rd_active <= 0;
                bus_rdx_active <= 1;
            end else if (cache1_bus_rd) begin
                current_requestor <= 2'b10;
                bus_rd_active <= 1;
                bus_rdx_active <= 0;
            end else if (cache1_bus_rdx) begin
                current_requestor <= 2'b10;
                bus_rd_active <= 0;
                bus_rdx_active <= 1;
            end else begin
                current_requestor <= 2'b00;
                bus_rd_active <= 0;
                bus_rdx_active <= 0;
            end


            // Propagate to snoopers (caches)
            if (bus_rd_active || bus_rdx_active) begin
                if (current_requestor == 2'b01) begin
                    // Cache0 initiated → notify Cache1
                    bus_rd_seen_1 <= bus_rd_active;
                    bus_rdx_seen_1 <= bus_rdx_active;
                    shared_line_0 <= cache1_flush;


                end else if (current_requestor == 2'b10) begin
                    // Cache1 initiated → notify Cache0
                    bus_rd_seen_0 <= bus_rd_active;
                    bus_rdx_seen_0 <= bus_rdx_active;
                    shared_line_1 <= cache0_flush;
                end
            end
        end
    end

endmodule