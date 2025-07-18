class axilite_tx_monitor ;


  virtual axilite_interface.mon_mp axi_intf_mon;
  mailbox #(axilite_trnx)          mon2scb;
  
  axilite_tx_agt_config            m_agt_cfg;
  mailbox #(axilite_trnx)          agent2scb_w;
  mailbox #(axilite_trnx)          agent2scb_r;
  
  function new(axilite_tx_agt_config   m_agt_cfg,
               mailbox #(axilite_trnx) agent2scb_w,
               mailbox #(axilite_trnx) agent2scb_r);
	this.m_agt_cfg     = m_agt_cfg ;
    this.axi_intf_mon  = m_agt_cfg.axi_intf_mon;	
    this.agent2scb_w   = agent2scb_w;
    this.agent2scb_r   = agent2scb_r;
  endfunction 
  
  task run();
    fork
	  receive_rdata_from_dut();
	  receive_waddr_n_wdata_from_dut();
	join
  
  endtask
  
  //receive read data from dut
  task receive_rdata_from_dut();
  
    bit [31:0]    read_addr_q[$];
    bit [31:0]    read_addr ;
	axilite_trnx  m_trnx_r ;
    forever begin 
    //not using fork join since dut cannot give data without address first 
	  @(axi_intf_mon.mon_cb);
	  if (axi_intf_mon.mon_cb.ar_valid && axi_intf_mon.mon_cb.ar_ready) begin
	    // Sample address and put into internal queue
	    read_addr = axi_intf_mon.mon_cb.ar_addr;
	    read_addr_q.push_back(read_addr);
		$display("TX_MONITOR : ar_valid & ready. read_addr = %d", read_addr);
	  end
	  
	  if (axi_intf_mon.mon_cb.r_valid && axi_intf_mon.mon_cb.r_ready) begin
	    m_trnx_r = new();
	    m_trnx_r.r_data  = axi_intf_mon.mon_cb.r_data;
	    m_trnx_r.ar_addr = read_addr_q.pop_front();
		agent2scb_r.put(m_trnx_r);
		$display("TX_MONITOR :r_valid & ready. read_data = %d", m_trnx_r.r_data);
		
	  end
	  
	end 
  endtask 
  
  
  //task to read "write data" written to dut and send to comparator for comparing with write data from predictor register model
  task receive_waddr_n_wdata_from_dut();
    bit [31:0]    write_addr_q[$];
    bit [31:0]    write_data_q[$];
	bit [31:0]    write_addr;
	bit [31:0]    write_data;
	axilite_trnx  m_trnx_w ;
    forever begin
	  // m_trnx_w = new();
	  @(axi_intf_mon.mon_cb);  
	  
	  //both addr and data are stored in queue 
	  if (axi_intf_mon.mon_cb.aw_valid && 
	      axi_intf_mon.mon_cb.aw_ready) begin
	    write_addr = axi_intf_mon.mon_cb.aw_addr;
		
		if ($size(write_data_q) == 0) begin
		
		  write_addr_q.push_back(write_addr);
		  
		end else begin
		  m_trnx_w         = new();
		  m_trnx_w.w_data  = write_data_q.pop_front();
	      m_trnx_w.aw_addr = write_addr;
		  agent2scb_w.put(m_trnx_w);
		end
		// m_trnx_w.aw_addr = write_addr_q.pop_front();
		// $display("TX_MONITOR:aw_valid & ready. write_addr = %d",m_trnx_w.aw_addr);
	  end

	  if (axi_intf_mon.mon_cb.w_valid && 
	      axi_intf_mon.mon_cb.w_ready) begin
	    
	    write_data = axi_intf_mon.mon_cb.w_data;

		if ($size(write_addr_q) == 0) begin
		  write_data_q.push_back(write_data);
		end else begin
		  m_trnx_w         = new();
		  m_trnx_w.w_data  = write_data;
	      m_trnx_w.aw_addr = write_addr_q.pop_front();
		  agent2scb_w.put(m_trnx_w);
		end

		// m_trnx_w         = new();
	    // write_data_q.push_back(write_data);
	    // m_trnx_w.w_data  = write_data;
	    // m_trnx_w.aw_addr = write_addr_q.pop_front();
		// $display("TX_MONITOR:w_valid & ready. write_data = %d",m_trnx_w.w_data);
	    // agent2scb_w.put(m_trnx_w);
		// $display("TX_MONITOR:w_addr=%d,w_data=%d",m_trnx_w.aw_addr,m_trnx_w.w_data);
	  end
	  
	  // if(axi_intf_mon.mon_cb.b_valid && 
	     // axi_intf_mon.mon_cb.b_ready) begin 
		// $display("TX_MONITOR: b_valid & b_ready are high, m_trnx_w put into mbx"); 
		// m_trnx_w.display("TX_MONITOR");
	  // end
   
    end
  endtask 
  
  
endclass 