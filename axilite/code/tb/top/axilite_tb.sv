`timescale 1ns / 1ps
import axilite_trnx_pkg       :: *;
import axilite_tx_agent_pkg   :: *;
import axilite_header_pkg     :: *;
import axilite_scoreboard_pkg :: *;
module axilite_tb(axilite_interface axi_intf);

 // virtual axilite_interface axi_intf ;
  
  axilite_tx_agent   m_tx_agent ;
  axilite_scoreboard m_scoreboard;
  
  axilite_tx_agt_config  m_agt_cfg   ;
  mailbox#(axilite_trnx) agent2scb_w ;
  mailbox#(axilite_trnx) agent2scb_r ;
  
  initial begin
    agent2scb_w  = new();
    agent2scb_r  = new();
	m_agt_cfg    = new();
	m_agt_cfg.axi_intf_drv = axi_intf.drv_mp ;
	m_agt_cfg.axi_intf_mon = axi_intf.mon_mp ;
    m_tx_agent   = new(m_agt_cfg,agent2scb_w,agent2scb_r);
	m_scoreboard = new(agent2scb_w,agent2scb_r);
	
	fork
	 `testfile 
	  m_tx_agent.run();
	  m_scoreboard.run();
	  $display("TB :all are created and tx-agent run task is started");
	join
  end
  
endmodule