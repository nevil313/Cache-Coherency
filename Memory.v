module memory (
    input clk,
    input [7:0] addr,
    input mem_read,
    output reg [31:0] data_out
);

  reg [31:0] mem_array [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem_array[i] = 32'hFACE0000 + i;
    end

    always @(posedge clk) begin
        if (mem_read)
            data_out <= mem_array[addr];
    end
endmodule