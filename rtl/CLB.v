module my_CLB(
    input wire [3:0] I,
    output wire CLB_O,
    input wire clk,
    input wire rst_n,
    input wire bit_stream,
    input wire bit_stream_valid // on the posedge, we program in 17 cycle of clk, 16 LUT first, then the MUX 
);

    reg [15:0] LUT_SRAM;
    reg MUX_SRAM;

    reg LUT_O;
    reg CLB_Register;

    reg [7:0] St_1;
    reg [3:0] St_2;
    reg [1:0] St_3;

    reg [4:0] program_count;
    integer counter;

    assign CLB_O = MUX_SRAM ? CLB_Register : LUT_O;

    always @(posedge clk or negedge rst_n) 
    begin
        if(!rst_n)
        begin
            CLB_Register  <= 0;
            program_count <= 0;
        end

        else
        begin
            CLB_Register <= LUT_O;
            if(bit_stream_valid == 1)
            begin
                if(program_count == 5'd16)
                begin
                    MUX_SRAM <= bit_stream;
                    program_count <= program_count + 1'b1;
                end

                else if(program_count < 5'd16)
                begin
                    LUT_SRAM[program_count] <= bit_stream;
                    program_count <= program_count + 1'b1;
                end
                else
                begin
                    program_count <= program_count;
                end
            end
            else 
            begin
                program_count <= 0;
            end
        end
    end

    always @ (*)
    begin
        for(counter = 0; counter < 8; counter = counter + 1)
        begin
            St_1[counter] = I[0] ? LUT_SRAM[counter*2 + 1] : LUT_SRAM[counter*2];
        end
        for(counter = 0; counter < 4; counter = counter + 1)
        begin
            St_2[counter] = I[1] ? St_1[counter*2 + 1] : St_1[counter*2];
        end
        for(counter = 0; counter < 2; counter = counter + 1)
        begin
            St_3[counter] = I[2] ? St_2[counter*2 + 1] : St_2[counter*2];
        end
        LUT_O = I[3] ? St_3[1] : St_3[0]; 
    end

endmodule