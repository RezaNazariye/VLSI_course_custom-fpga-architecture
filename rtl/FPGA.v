module my_FPGA (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] Ia,
    input  wire [3:0] Ib,
    output wire CLBb_O,
    input  wire bit_stream,
    input  wire bit_stream_valid // in38 clks
    );

    reg [5:0] Program_counter;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            Program_counter <= 6'd0;
        end
        else if (bit_stream_valid)
        begin
            if (Program_counter != 6'd38)
                Program_counter <= Program_counter + 1'b1;
        end
        else
        begin
            Program_counter <= 6'd0;
        end
    end

    wire valid_a = bit_stream_valid && (Program_counter <=  6'd17);
    wire valid_b = bit_stream_valid && (Program_counter > 6'd17) && (Program_counter <= 6'd34);
    wire valid_c = bit_stream_valid && (Program_counter > 6'd34) && (Program_counter <= 6'd38);

    wire       CLBa_O;
    wire [3:0] Ib_conn;

    my_CLB CLBa (
        .I(Ia),
        .CLB_O(CLBa_O), 
        .clk(clk), 
        .rst_n(rst_n),
        .bit_stream(bit_stream), 
        .bit_stream_valid(valid_a)
    );

    my_CLB CLBb (
        .I(Ib_conn), 
        .CLB_O(CLBb_O), 
        .clk(clk), 
        .rst_n(rst_n),
        .bit_stream(bit_stream), 
        .bit_stream_valid(valid_b)
    );

    my_Connector connector (
        .clk(clk), 
        .Ib(Ib), 
        .In(CLBa_O), 
        .Out(Ib_conn),
        .bit_stream(bit_stream), 
        .bit_stream_valid(valid_c)
    );
endmodule
