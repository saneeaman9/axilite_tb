//import axilite_header_pkg :: * ;
//`include"../../tb/common/axilite_params.svh"

interface axilite_interface #(parameter ADDR_WIDTH =32,                              parameter DATA_WIDTH =32)
                             (input bit clk, input bit rst);

  // write request/address channel
  wire [ADDR_WIDTH -1 :0] aw_addr; 
  wire                    aw_valid; 
  wire                    aw_ready;
  wire [2:0]              aw_prot ;
  
  // write data channel
  wire [DATA_WIDTH -1 :0] w_data ;
  wire [3 :0]             w_strb ;
  wire                    w_valid;
  wire                    w_ready;

  // read request/address channel
  wire [ADDR_WIDTH -1 :0] ar_addr ; 
  wire [2 :0]             ar_prot ; 
  wire                    ar_valid;
  wire                    ar_ready;
  
  // read data channel
  wire [DATA_WIDTH -1 :0] r_data ;
  wire [1 :0]             r_resp ;
  wire                    r_ready;
  wire                    r_valid;
		                   
  // write response channel
  wire [1:0]              b_resp ;
  wire                    b_valid;
  wire                    b_ready;
  
  wire                    cnt_strobe  ;
  wire [0:0]			  cnt_ena     ;
  wire [0:0]			  cnt_udt     ;
  wire [0:0]			  cnt_ien     ;
  wire 				      tlr_strobe  ;
  wire [31:0]			  tlr_tlr     ;
  wire 				      tcr_strobe  ;
  wire [31:0]		      tcr_tcr     ;
  wire 				      tir_zero_set;		  
						  
  
  clocking drv_cb @(posedge clk) ;
                
	input  rst     ;
	output aw_addr ;
	output aw_prot ;
	output aw_valid; 
	input  aw_ready; 
	
	
	output w_data ;
	output w_valid;
	output w_strb ;
	input  w_ready;
	
	output ar_addr ;
	output ar_prot ;
	output ar_valid;
	input  ar_ready;
	
	input  r_data  ;
	input  r_resp  ;
	input  r_valid ;
	output r_ready ;
	
	input  b_resp  ;
	input  b_valid ;
	output b_ready ;
	
	// input   cnt_strobe  ;
	// input   cnt_ena     ;
	// input   cnt_udt     ;
	// input   cnt_ien     ;
	// input   tlr_strobe  ;
	// input   tlr_tlr     ;
	// input   tcr_strobe  ;
	// output  tcr_tcr     ;
	// output  tir_zero_set;	
	
  endclocking
  
  clocking mon_cb @(posedge clk) ;
  
    input  ar_addr ;
	input  ar_prot ;
	input  ar_valid;
	input  ar_ready;
	
	input  aw_addr ;
	input  aw_prot ;
	input  aw_valid;
	input  aw_ready;
	
	input  w_data  ;
	input  w_strb  ;
	input  w_valid ;
	input  w_ready ;
	
	input  r_data  ;
	input  r_resp  ;
	input  r_valid ;
	input  r_ready ;
	
	input  b_resp  ;
	input  b_valid ;
	input  b_ready ;
  
  
  endclocking
  
  modport drv_mp (clocking drv_cb);
  modport mon_mp (clocking mon_cb);
  
  
endinterface 