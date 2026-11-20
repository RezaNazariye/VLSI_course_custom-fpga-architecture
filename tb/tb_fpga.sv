`timescale 1ns/1ps

module tb_fpga;

  parameter TESTS = 10000;

  reg clk = 0;
  always #10 clk = ~clk;

  reg rst_n;
  reg [3:0] Ia, Ib;
  reg bit_stream;
  reg bit_stream_valid;

  wire CLBb_O;

  reg [37:0] bitstreams [0:4];

  integer passed [0:4];
  integer failed [0:4];

  integer fd;
  integer i;

  real accuracy;

  //================================================
  // FPGA
  //================================================

  my_FPGA dut (
      .clk(clk),
      .rst_n(rst_n),
      .Ia(Ia),
      .Ib(Ib),
      .CLBb_O(CLBb_O),
      .bit_stream(bit_stream),
      .bit_stream_valid(bit_stream_valid)
  );


  //================================================
  // REFERENCE FUNCTIONS
  //================================================

  reg a, b, c, d, e;
  reg [2:0] a3, b3;

  wire f1_ref, f2_ref, f3_ref, f4_ref, f5_ref;

  func1 ref1 (
    .a(a), .b(b), .c(c), .d(d), .f(f1_ref)
  );

  func2 ref2 (
    .a(a), .b(b), .c(c), .d(d), .f(f2_ref)
  );

  func3 ref3 (
    .clk(clk),
    .rst_n(rst_n),
    .a(a), .b(b), .c(c), .d(d), .e(e),
    .f(f3_ref)
  );

  func4 ref4 (
   .a(a3), .b(b3), .f(f4_ref)
  );

  func5 ref5 (
    .clk(clk),
    .rst_n(rst_n),
    .a(a3), .b(b3), .f(f5_ref)
  );


  //================================================
  // COMMON TASKS
  //================================================

  task reset_fpga;
  begin
      bit_stream_valid = 0;
      bit_stream = 0;
      Ia = 0;
      Ib = 0;

      rst_n = 0;
      repeat(3) @(posedge clk);
      rst_n = 1;

      @(posedge clk);
  end
  endtask


  task program_fpga;
    input integer index;
    integer k;
    begin
      bit_stream_valid = 1;
      @(posedge clk);
      for(k = 0; k < 38; k = k + 1)
      begin
        
        bit_stream = bitstreams[index][37-k];
        @(posedge clk);
      end

      @(posedge clk);
      bit_stream_valid = 0;
      bit_stream = 0;

      repeat(2) @(posedge clk);
  end
  endtask


  task report_result;
    input integer index;
    begin
      if ((passed[index] + failed[index]) != 0)
      begin
        accuracy = 100.0 * passed[index] / (passed[index] + failed[index]);

        $display("------------------------------------");
        $display("Function %0d", index+1);
        $display("Passed   : %0d", passed[index]);
        $display("Failed   : %0d", failed[index]);
        $display("Accuracy : %0.2f%%", accuracy);
        $display("------------------------------------");
      end
    end
  endtask


  //================================================
  // TASK 1: TRUTH TABLE
  //================================================

  task test_function1;
    integer k;
    reg expected;
  begin
      $display("\n========== TEST FUNCTION 1 ==========");

      reset_fpga;
      program_fpga(0);

      for(k = 0; k < TESTS; k = k + 1)
      begin
          @(posedge clk);

          // Four random inputs
          {a,b,c,d} = $urandom;

          // CLBb receives Ib directly
          Ia = 0;
          Ib = {a,b,c,d};

          #1;
          expected = f1_ref;

          if(CLBb_O === expected)
              passed[0] = passed[0] + 1;
          else
          begin
              failed[0] = failed[0] + 1;

              if(failed[0] <= 5)
                  $display("Mismatch: ABCD=%b FPGA=%b REF=%b",
                            {a,b,c,d}, CLBb_O, expected);
          end
      end

      // report_result(0);
  end
  endtask


  //================================================
  // TASK 2: (!a | b) & (c | d)
  //================================================

  task test_function2;
      integer k;
      reg expected;
  begin
      $display("\n========== TEST FUNCTION 2 ==========");

      reset_fpga;
      program_fpga(1);

      for(k = 0; k < TESTS; k = k + 1)
      begin
          @(posedge clk);

          {a,b,c,d} = $urandom;

          Ia = 0;
          Ib = {a,b,c,d};

          #1;
          expected = f2_ref;

          if(CLBb_O === expected)
              passed[1] = passed[1] + 1;
          else
          begin
              failed[1] = failed[1] + 1;

              if(failed[1] <= 5)
                  $display("Mismatch: ABCD=%b FPGA=%b REF=%b",
                            {a,b,c,d}, CLBb_O, expected);
          end
      end

      // report_result(1);
  end
  endtask


  //================================================
  // TASK 3: REGISTERED FUNCTION
  // ((a | b) & (~c & d)) ^ e
  //================================================

  task test_function3;
      integer k;
      reg expected;
  begin
      $display("\n========== TEST FUNCTION 3 ==========");

      reset_fpga;
      program_fpga(2);

      for(k = 0; k < TESTS; k = k + 1)
      begin
          @(posedge clk);

          {a,b,c,d,e} = $urandom;

          // Mapping:
          // CLBa inputs = {d,c,b,a}
          // e is connected to CLBb through Ib[1]

          Ia = {a,b,c,d};
          Ib = {2'b0,e,1'b0};

          @(posedge clk);
          #1;

          expected = f3_ref;

          if(CLBb_O === expected)
              passed[2] = passed[2] + 1;
          else
          begin
              failed[2] = failed[2] + 1;

              if(failed[2] <= 5)
                  $display("Mismatch: ABCDE=%b FPGA=%b REF=%b",
                            {a,b,c,d,e}, CLBb_O, expected);
          end
      end

      // report_result(2);
  end
  endtask


  //================================================
  // TASK 4: COMBINATIONAL COMPARATOR
  // b >= a
  //================================================

  task test_function4;
      integer k;
      reg expected;
  begin
      $display("\n========== TEST FUNCTION 4 ==========");

      reset_fpga;
      program_fpga(3);

      for(k = 0; k < TESTS; k = k + 1)
      begin
          @(posedge clk);

          a3 = $urandom;
          b3 = $urandom;

          // Mapping:
          // Ia = {b[1], b[0], a[1], a[0]}
          // Ib[1] = a[2]
          // Ib[2] = b[2]

          Ia = {b3[1], a3[1], b3[0], a3[0]};

          Ib = {1'b0, b3[2], a3[2], 1'b0};

          #1;
          expected = f4_ref;

          if(CLBb_O === expected)
              passed[3] = passed[3] + 1;
          else
          begin
              failed[3] = failed[3] + 1;

              if(failed[3] <= 5)
                  $display("Mismatch: A=%b B=%b FPGA=%b REF=%b",
                            a3, b3, CLBb_O, expected);
          end
      end

      // report_result(3);
  end
  endtask


  //================================================
  // TASK 5: PIPELINED COMPARATOR
  //================================================

  task test_function5;
    integer k;
    reg expected;
    begin
    $display("\n========== TEST FUNCTION 5 ==========");

    reset_fpga;
    program_fpga(4);

    for(k = 0; k < TESTS; k = k + 1)
    begin
      @(posedge clk);

      a3 = $urandom;
      b3 = $urandom;


      Ia = {b3[1], a3[1], b3[0], a3[0]};
      Ib = {1'b0, b3[2], a3[2], 1'b0};
      
      #1;
      @(posedge clk);
      expected = f5_ref;

      if(CLBb_O === expected)
        passed[4] = passed[4] + 1;
      else
      begin
        failed[4] = failed[4] + 1;

        if(failed[4] <= 5)
          $display("Mismatch: A=%b B=%b FPGA=%b REF=%b", a3, b3, CLBb_O, expected);
      end
    end

    // report_result(4);
    end
  endtask


  //================================================
  // MAIN
  //================================================

  initial
  begin

      rst_n = 0;
      Ia = 0;
      Ib = 0;
      bit_stream = 0;
      bit_stream_valid = 0;

      for(i = 0; i < 5; i = i + 1)
      begin
          passed[i] = 0;
          failed[i] = 0;
      end

      // Read all bitstreams

      fd = $fopen("bitstreams.txt", "r");

      if(fd == 0)
      begin
          $display("ERROR: Cannot open bitstreams.txt");
          $finish;
      end

      for(i = 0; i < 5; i = i + 1)
      begin
          if($fscanf(fd, "%b\n", bitstreams[i]) != 1)
          begin
              $display("ERROR: Invalid bitstream %0d", i+1);
              $finish;
          end
      end

      $fclose(fd);

      // Call the five test tasks

      test_function1;
      test_function2;
      test_function3;
      test_function4;
      test_function5;

      // Final report

      $display("\n========== FINAL REPORT ==========");

      for(i = 0; i < 5; i = i + 1)
        report_result(i);

      $display("\nSimulation finished.");

      $finish;

  end

endmodule