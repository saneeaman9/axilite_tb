class axilite_tx_agent;

  axilite_generator      m_gen    ;
  axilite_driver         m_drv    ;
  axilite_tx_monitor     m_mon    ;
  mailbox#(axilite_trnx) gen2drv_w;
  mailbox#(axilite_trnx) gen2drv_r;
  mailbox#(axilite_trnx) drv2mon_r;
   
  function new(axilite_tx_agt_config m_agt_cfg,
               mailbox#(axilite_trnx)agent2scb_w,
               mailbox#(axilite_trnx)agent2scb_r);
	gen2drv_w  = new();		   
	gen2drv_r  = new();		   
	m_gen      = new(m_agt_cfg,gen2drv_w,gen2drv_r);
	m_drv      = new(m_agt_cfg,gen2drv_w,gen2drv_r);
	m_mon      = new(m_agt_cfg,agent2scb_w,agent2scb_r);
	
  endfunction
  
  task run();
    fork
      m_drv.run();
	  m_mon.run();
	  $display("TX_AGENT : drv & mon.run is called ");
	join
  endtask 
  
endclass 