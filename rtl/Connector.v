module my_Connector(
    input clk,
    input wire [3:0] Ib,
    input wire In,
    output reg [3:0] Out,
    input wire bit_stream,
    input wire bit_stream_valid // on the 1, we program in 4 cycle of clk 
);
    reg [3:0] SRAM;
    reg [2:0] program_count;
    integer counter;

    always @(*)
    begin
        for(counter = 0; counter < 4; counter = counter + 1)
        begin
            Out[counter] = SRAM[counter] ? In : Ib[counter];
        end
    end

    always @(posedge clk)
    begin
        if(bit_stream_valid)
        begin   
            if(program_count[2])
            begin
                program_count <= program_count;
            end
            else
            begin
                SRAM[program_count] <= bit_stream;
                program_count <= program_count + 1'b1;
            end                        
        end
        else
        begin
            program_count <= 0;
        end
    end
endmodule