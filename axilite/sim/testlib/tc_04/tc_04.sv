begin
    //2 reads and write in a row
    for(int i =0;i<8 ; i++) begin
      
        // Write to memory
        m_tx_cfg.write_not_read = 1'b1;
        m_tx_cfg.wdata          = $urandom_range (0, 255);
        m_tx_cfg.addr           = i[2:0];
        m_tx_agt.m_gen.generate_data();
      
      for (int i = 0; i < 2; i++) begin
        @(posedge tif.clk);
        // Read from memory
        m_tx_cfg.write_not_read = 1'b0;
        m_tx_cfg.addr           = i[2:0];
        m_tx_agt.m_gen.generate_data();
      end
    end
  
  
  #1us $stop();
  
end