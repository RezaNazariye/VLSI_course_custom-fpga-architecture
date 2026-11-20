// Behavioural (reference) HDL of the five required functions
// 1) truth table (combinational)
module func1(
    input wire a,
    input wire b,
    input wire c,
    input wire d, 
    output reg f
    );

    always @(*)
    begin
        case ({a,b,c,d})
            4'b0000: f = 1'b0;   
            4'b0001: f = 1'b0;
            4'b0010: f = 1'b1;   
            4'b0011: f = 1'b0;
            4'b0100: f = 1'b1;   
            4'b0101: f = 1'b1;
            4'b0110: f = 1'b1;   
            4'b0111: f = 1'b0;
            4'b1000: f = 1'b0;   
            4'b1001: f = 1'b1;
            4'b1010: f = 1'b1;   
            4'b1011: f = 1'b1;
            4'b1100: f = 1'b0;   
            4'b1101: f = 1'b0;
            4'b1110: f = 1'b0;   
            4'b1111: f = 1'b1;
        endcase
    end
endmodule

// 2) f = (!a|b)&(c|d)  (combinational)
module func2(
    input wire a,
    input wire b,
    input wire c,
    input wire d, 
    output wire f
    );

    assign f = (~a | b) & (c | d);
endmodule

// 3) f = ((a|b)&(!c&d))^e  (registered output)
module func3(
    input wire clk,
    input wire rst_n,
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    input wire e, 
    output reg f
    );
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            f <= 1'b0;
        end
        else        
        begin
            f <= ((a | b) & (~c & d)) ^ e;
        end
    end
endmodule

// 4) f = b >= a, 3-bit unsigned (combinational)
module func4(
    input wire [2:0] a,
    input wire [2:0] b, 
    output wire f
    );

    assign f = (b >= a);
endmodule

// 5) f = b >= a, 3-bit unsigned (2-stage pipeline: low bits compared in stage 1,
//    high bits + stage-1 result combined in stage 2)
module func5(
    input wire clk, 
    input wire rst_n, 
    input wire [2:0] a, 
    input wire [2:0] b,
    output reg f
    );

    reg t_r;
    reg a2_r;
    reg b2_r;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n) 
        begin 
            t_r <= 0;
            a2_r <= 0; 
            b2_r <= 0; 
            f <= 0; 
        end
        else 
        begin
            t_r  <= (b[1:0] >= a[1:0]);
            a2_r <= a[2];
            b2_r <= b[2];
            f    <= (b2_r > a2_r) | ((b2_r == a2_r) & t_r);
        end
    end
endmodule
