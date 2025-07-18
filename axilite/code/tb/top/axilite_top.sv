import axilite_header_pkg :: * ;
module axilite_top;

  bit clk;
  bit rst;
  //clock module instantiation
  axilite_clock u_axilite_clock(.clk(clk),.rst(rst));
  
  axilite_interface#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(                    DATA_WIDTH)) axi_intf(clk, rst);
  
  // axilite_interface#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(                    DATA_WIDTH)) axi_intf_mon(clk, rst);
  
  
  // assign axi_intf.aw_ready = 1'b0;
  
   //instantiate dut 
  Timer_regs #(.AXI_ADDR_WIDTH(ADDR_WIDTH), 
               .BASEADDR(BASEADDR))
			 u_Timer_regs(.axi_aclk     (clk              ),
                          .axi_aresetn  (~rst             ),
                          .s_axi_awaddr (axi_intf.aw_addr ),
                          .s_axi_awprot (axi_intf.aw_prot ),
                          .s_axi_awvalid(axi_intf.aw_valid),
                          .s_axi_awready(axi_intf.aw_ready),
                          
                          .s_axi_wdata  (axi_intf.w_data  ),
                          .s_axi_wstrb  (axi_intf.w_strb  ),
                          .s_axi_wvalid (axi_intf.w_valid ),
                          .s_axi_wready (axi_intf.w_ready ),
                          
                          
                          .s_axi_araddr (axi_intf.ar_addr ),
                          .s_axi_arprot (axi_intf.ar_prot ),
                          .s_axi_arvalid(axi_intf.ar_valid),
                          .s_axi_arready(axi_intf.ar_ready),
                          
                          
                          .s_axi_rdata  (axi_intf.r_data  ),
                          .s_axi_rresp  (axi_intf.r_resp  ),
                          .s_axi_rvalid (axi_intf.r_valid ),
                          .s_axi_rready (axi_intf.r_ready ),
                          
                          
                          .s_axi_bresp  (axi_intf.b_resp  ),
                          .s_axi_bvalid (axi_intf.b_valid ),
                          .s_axi_bready (axi_intf.b_ready ),
						  
						  .cnt_strobe   (axi_intf.cnt_strobe),
						  .cnt_ena      (axi_intf.cnt_ena   ),
						  .cnt_udt      (axi_intf.cnt_udt   ),
						  .cnt_ien      (axi_intf.cnt_ien   ),
						  .tlr_strobe   (axi_intf.tlr_strobe),
						  .tlr_tlr      (                   ),
						  .tcr_strobe   (                   ),
						  .tcr_tcr      ('0                 ),
						  .tir_zero_set ('0                 )
						  
					    );
  //pass interface to the tb 
  axilite_tb u_axilite_tb(axi_intf);
  
endmodule 