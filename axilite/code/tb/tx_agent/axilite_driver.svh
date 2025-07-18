class axilite_driver ;

  axilite_tx_agt_config            m_agt_cfg;
  mailbox#(axilite_trnx)           gen2drv_w  ;
  mailbox#(axilite_trnx)           gen2drv_r  ;
  event                            drv2gen_event_w;
  event                            drv2gen_event_r;
  virtual axilite_interface.drv_mp axi_intf ;
  axilite_trnx                     m_trnx_w ;
  axilite_trnx                     m_trnx_r ;

  function new(axilite_tx_agt_config m_agt_cfg,
               mailbox#(axilite_trnx)gen2drv_w,
               mailbox#(axilite_trnx)gen2drv_r);
              // mailbox#(axilite_trnx)agent2scb_w);
              // mailbox#(axilite_trnx)agent2scb_r);
			   
    this.m_agt_cfg        = m_agt_cfg;
	this.axi_intf         = m_agt_cfg.axi_intf_drv;
	this.drv2gen_event_w  = m_agt_cfg.drv2gen_event_w;
	this.drv2gen_event_r  = m_agt_cfg.drv2gen_event_r;
	// this.agent2scb_w      = agent2scb_w;
	// this.agent2scb_r      = agent2scb_r;
	this.gen2drv_w        = gen2drv_w;
	this.gen2drv_r        = gen2drv_r;
  endfunction 
  
  
  task run();
    reset();
	@(axi_intf.drv_cb iff !axi_intf.drv_cb.rst);
	repeat (10) @(axi_intf.drv_cb);
	
    fork
      write();
	  read ();
	join 
	
  endtask 
  
  task reset();
    // Reset write channel's signal
	axi_intf.drv_cb.aw_addr  <= '0;
	axi_intf.drv_cb.aw_valid <= '0;
	axi_intf.drv_cb.w_data   <= '0;
	axi_intf.drv_cb.w_valid  <= '0;
	axi_intf.drv_cb.b_ready  <= '0;
	// axi_intf.r_data         <= 0;
	
	// Reset read channel's signal
	axi_intf.drv_cb.ar_addr  <= '0;
	axi_intf.drv_cb.ar_valid <= '0;
	axi_intf.drv_cb.r_ready  <= '0;
  endtask 
  
  
  task write();
	
	forever begin 
	  
	  //wait for a clock and reset
	  //get trnx from generator
	  // Fetch transaction from generator mailbox
	  gen2drv_w.get(m_trnx_w);
	  $display("[DRIVER] : Get trnx from write mailbox");
	  /*driving valids high and waiting for ready from slave
	                            to complete transaction */
	  axi_intf.drv_cb.aw_valid <= 1;
	  axi_intf.drv_cb.w_valid  <= 1;
	  axi_intf.drv_cb.aw_prot  <= '0;
	  axi_intf.drv_cb.w_strb   <= 4'b1111;
	  axi_intf.drv_cb.aw_addr  <= m_trnx_w.aw_addr;
	  axi_intf.drv_cb.w_data   <= m_trnx_w.w_data;
	  
	  @(axi_intf.drv_cb iff !axi_intf.drv_cb.rst);
	  m_trnx_w.display("[DRIVER]");
	  fork
	  
	    begin
	      while (axi_intf.drv_cb.aw_ready === 1'b0 || axi_intf.drv_cb.aw_ready === 1'bz) @(axi_intf.drv_cb);
		  axi_intf.drv_cb.aw_valid <= 0;
		  $display("[DRIVER] : Received!aw_ready,aw_valid=0");
		end
		
		begin
	      while (axi_intf.drv_cb.w_ready === 1'b0 || axi_intf.drv_cb.w_ready === 1'bz) @(axi_intf.drv_cb);
		  axi_intf.drv_cb.w_valid <= 0;
		  $display("[DRIVER] : Received!w_ready,w_valid=0");
		end
	  
	  join
	  
	  axi_intf.drv_cb.b_ready <= 1'b1;
	  @(axi_intf.drv_cb iff !axi_intf.drv_cb.rst);
	  while (axi_intf.drv_cb.b_valid === 1'b0 || axi_intf.drv_cb.b_valid === 1'bz) @(axi_intf.drv_cb);

	  //agent2scb_w.put(m_trnx_w);
	  axi_intf.drv_cb.b_ready <= 1'b0;
	  $display("[DRIVER] : Received!b_valid,b_ready=0");
	   
	  ->drv2gen_event_w;
	  $display("[DRIVER] : write event is triggered");
	end
	 
  endtask
  
  
  task read();
    
    forever begin 
	
	  @(axi_intf.drv_cb iff !axi_intf.drv_cb.rst);
	  gen2drv_r.get(m_trnx_r);
	  $display("[DRIVER] : get from read mbx");
	  //this is input to dut (address valid)
	  axi_intf.drv_cb.ar_valid <= 1;
	  axi_intf.drv_cb.ar_prot  <= '0;
	  axi_intf.drv_cb.ar_addr  <= m_trnx_r.ar_addr ;
	  /*ready can be asserted before valid, since this is a read, 
	    asserting ready */
	  axi_intf.drv_cb.r_ready  <= 1;
	  
      //waiting for ar_ready and deasserting valid after ar_ready is high
	  while(!axi_intf.drv_cb.ar_ready) @(axi_intf.drv_cb);
	  axi_intf.drv_cb.ar_valid <= 0;
	  $display("[DRIVER]:received !ar_ready, ar_valid=0");
	  //read data is sampled in monitor. deasserting r_ready after receiving r_valid from dut. this takes one clock cycle delay due to NB assignment. 
      while(!axi_intf.drv_cb.r_valid) @(axi_intf.drv_cb);
	  axi_intf.drv_cb.r_ready  <= 0;
	  $display("[DRIVER]:received r_valid from dut");
	  
	  
      -> drv2gen_event_r;	  
	  $display("[DRIVER] : read event is triggered");
    end 	
     
  endtask 
  
endclass