`timescale 1ns/1ps
`define CLOCKPERIOD_100MHZ 10
module axilite_clock(output bit clk, output bit rst);

  reg clk_i;
  reg rst_i;
  
  initial begin 
    rst_i <= 1;
    repeat(50)
      @(posedge clk_i) ;
    rst_i <= 0;
  end 
  
  initial clk_i <= 0 ;
  
  always #(`CLOCKPERIOD_100MHZ / 2) clk_i = ~clk ;
  
  assign clk = clk_i;
  assign rst = rst_i;
  
endmodule