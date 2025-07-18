`ifndef GUARD_AXILITE_TRNX
`define GUARD_AXILITE_TRNX

class axilite_trnx ;
  
  bit [ADDR_WIDTH -1 :0] ar_addr ;
  bit [DATA_WIDTH -1 :0] r_data  ;
  bit [DATA_WIDTH -1 :0] w_data  ;
  bit [ADDR_WIDTH -1 :0] aw_addr ; 
  int                    rpt_file_h;

  
  function void display(string component);
    $display("[%s] :aw_addr=%d ,w_data=%d, ar_addr=%d, r_data=%d",
             component,aw_addr,w_data,aw_addr,r_data);
	
    // $fdisplay(rpt_file_h,
	         // "%s :aw_addr=%d ,w_data=%d, ar_addr=%d, r_data=%d",
             // component,aw_addr,w_data,ar_addr,r_data);	
  
  endfunction
  
  function void compare(axilite_trnx rcvd_trnx);
  
    axilite_trnx rcvd_trnx_;
  
    if(!$cast(rcvd_trnx_,rcvd_trnx))
      $fdisplay(rpt_file_h,"Casting failed");	
    if(ar_addr == rcvd_trnx_.ar_addr && 
	   r_data == rcvd_trnx_.r_data) begin
	  $fdisplay(rpt_file_h,
	  "----------DATA MATCH--------	  EXPD:ar_addr=%d,r_data=%d,  RCVD:ar_addr=%d,r_data=%d",
	  ar_addr,r_data,rcvd_trnx_.ar_addr, rcvd_trnx_.r_data);
	end
	else begin 
	$fdisplay(rpt_file_h,
	  "----------DATA misMATCH--------	  EXPD:ar_addr=%d,r_data=%d,  RCVD:ar_addr=%d,r_data=%d",
	  ar_addr,r_data,rcvd_trnx_.ar_addr, rcvd_trnx_.r_data);
	end
	
  endfunction
	
endclass
`endif