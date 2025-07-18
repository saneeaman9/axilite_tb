begin
    //2 writes and a read in a row
    for(int j =0;j<8 ; j++) begin
      for (int i = 0; i < 2; i++) begin
        // Write to memory
        m_tx_cfg.write_not_read = 1'b1;
        m_tx_cfg.wdata          = $urandom_range (0, 255);
        m_tx_cfg.addr           = i[2:0];
        m_tx_agt.m_gen.generate_data();
      end
      
      // @(posedge tif.clk);
        // Read from memory
        m_tx_cfg.write_not_read = 1'b0;
        m_tx_cfg.addr           = j[2:0];
        m_tx_agt.m_gen.generate_data();
        
    end
  
  
  #1us $stop();
  
end