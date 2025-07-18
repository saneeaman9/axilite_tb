class axilite_predictor ;
  
  mailbox #(axilite_trnx) agent2scb_w;
  mailbox #(axilite_trnx) pred2comp;
  axilite_trnx            m_trnx ;
  axilite_reg_bank        m_reg_bank;


  function new(mailbox #(axilite_trnx)agent2scb_w,
               mailbox #(axilite_trnx)pred2comp,
			   axilite_reg_bank       m_reg_bank);
			   
	this.agent2scb_w = agent2scb_w;
	this.pred2comp   = pred2comp ;
	this.m_reg_bank  = m_reg_bank;
	
  endfunction 
  
  task run();
    
    write_data_to_reg_bank();
    
  endtask 
  
  task write_data_to_reg_bank();
    forever begin  
      agent2scb_w.get(m_trnx);
	  m_trnx.display("PREDICTOR");
	  // m_reg_bank = new();
	  m_reg_bank.write(m_trnx.aw_addr,m_trnx.w_data);
	end
  endtask 
  
endclass
