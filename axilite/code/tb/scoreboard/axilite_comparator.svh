class axilite_comparator;

   mailbox #(axilite_trnx) agent2scb_r;
   axilite_trnx            rcvd_trnx  ;
   axilite_reg_bank        m_reg_bank;
   int                     rpt_file_h;
   bit [31:0]              expd_rdata ;
   
  function new(mailbox #(axilite_trnx)agent2scb_r,
               mailbox #(axilite_trnx)pred2comp,
			   axilite_reg_bank       m_reg_bank);
		   
    this.agent2scb_r = agent2scb_r;
    this.m_reg_bank  = m_reg_bank;
	rpt_file_h       = $fopen("comparator_rpt.rpt","w");
  
  endfunction 

  task run();
    compare_rdata();
  endtask 
  
  
  task compare_rdata();
    // m_reg_bank = new();
	
	forever begin
	  agent2scb_r.get(rcvd_trnx);
	  rcvd_trnx.display("COMPARATOR");
	  $display("[COMPARATOR] : ");
	  m_reg_bank.read(rcvd_trnx.ar_addr,expd_rdata);
	  
	  if(expd_rdata == rcvd_trnx.r_data)  begin
	    $fdisplay(rpt_file_h,
	    "[INFO]:----------DATA MATCH---------Address = 0x%0x, Data = 0x%0x",
	    rcvd_trnx.ar_addr,expd_rdata);
	  end
	  else begin 
       $fdisplay(rpt_file_h,
	    "[ERROR]----------DATA misMATCH-------Address = 0x%0x, EXPD:r_data = 0x%0x,  RCVD:r_data = 0x%0x",
	    rcvd_trnx.ar_addr,expd_rdata,rcvd_trnx.r_data);
	  end
	end
  endtask 

endclass 