
import axilite_header_pkg :: *;
begin

  
    for (int i = 0; i <= 12; i += 4) begin : write
	  bit write_not_read;
      write_not_read = 1;
      m_agt_cfg.w_data  = $urandom();
      m_agt_cfg.aw_addr = BASEADDR + i[3:0];
      // m_agt_cfg.ar_addr = 2 ;
      m_tx_agent.m_gen.write_or_read(write_not_read);
    end
	
	for (int i = 0; i <= 12; i += 4) begin : read
	  bit write_not_read;
      write_not_read = 0;

      m_agt_cfg.ar_addr = BASEADDR + i[3:0];

      m_tx_agent.m_gen.write_or_read(write_not_read);
    end
	
   
  #1us $stop();
  
end