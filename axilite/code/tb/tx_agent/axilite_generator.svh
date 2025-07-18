class axilite_generator;
  
  axilite_trnx            m_trnx_w ;
  axilite_trnx            m_trnx_r ;
  mailbox #(axilite_trnx) gen2drv_w;
  mailbox #(axilite_trnx) gen2drv_r;
  axilite_tx_agt_config   m_agt_cfg;
  event                   drv2gen_event_w;
  event                   drv2gen_event_r;
  
  //new function to share mailbox and config 
  function new(axilite_tx_agt_config   m_agt_cfg,
               mailbox #(axilite_trnx) gen2drv_w,
               mailbox #(axilite_trnx) gen2drv_r);
			   
	this.m_agt_cfg        = m_agt_cfg				 ;
	this.drv2gen_event_w  = m_agt_cfg.drv2gen_event_w;
	this.drv2gen_event_r  = m_agt_cfg.drv2gen_event_r;
	this.gen2drv_w        = gen2drv_w  				 ;
	this.gen2drv_r        = gen2drv_r 				 ;
    
  endfunction   

  /* this task is given inputs from testcase 
      using tx_agt_config class */
	   
  task write_or_read(bit write_not_read);

	// Write operation
	if (write_not_read == 1'b1) begin
	  m_trnx_w         = new();
	  m_trnx_w.aw_addr = m_agt_cfg.aw_addr;
	  m_trnx_w.w_data  = m_agt_cfg.w_data;
	  gen2drv_w.put(m_trnx_w);
	  $display("[GENERATOR]: m_trnx write is put into mailbox");
	  m_trnx_w.display("[GENERATOR]");
	  @(drv2gen_event_w);
      $display("[GENERATOR] : write event is triggered");
	end 
	// Read operation
	else begin 
	  m_trnx_r         = new();
	  m_trnx_r.ar_addr = m_agt_cfg.ar_addr;
	  
	  gen2drv_r.put(m_trnx_r);
	  $display("[GENERATOR]: m_trnx read is put into mailbox");
   	  m_trnx_r.display("[GENERATOR]");
	  @(drv2gen_event_r);
      $display("[GENERATOR] : read event is triggered");
	end
	
	
	// assume property (a->b##c);



	// fork 
	// @(drv2gen_event_w);
	// @(drv2gen_event_r);
	// join_any 
  endtask

endclass