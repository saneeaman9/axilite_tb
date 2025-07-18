class axilite_scoreboard;
    
  mailbox #(axilite_trnx) pred2comp   ;
  axilite_predictor       m_predictor ;
  axilite_comparator      m_comparator ;
  axilite_reg_bank        m_reg_bank;
  
  function new(mailbox #(axilite_trnx) agent2scb_w,
               mailbox #(axilite_trnx) agent2scb_r);
			   
	pred2comp         = new();
	m_reg_bank        = new();
    m_predictor       = new(agent2scb_w,pred2comp, m_reg_bank);
	m_comparator      = new(agent2scb_r,pred2comp, m_reg_bank);
    
  endfunction 
	
  task run();
    fork
      m_predictor.run();
      m_comparator.run();
	join
  endtask 
  
endclass 