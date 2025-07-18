begin

  for (int i = 0; i < 8; i++) begin
    // Write to memory
    m_tx_cfg.write_not_read = 1'b1;
    m_tx_cfg.wdata          = $urandom_range (0, 255);
    m_tx_cfg.addr           = i[2:0];
    m_tx_agt.m_gen.generate_data();
  end
  
  for (int i = 0; i < 8; i++) begin
    // Read from memory
    m_tx_cfg.write_not_read = 1'b0;
    m_tx_cfg.addr           = i[2:0];
    m_tx_agt.m_gen.generate_data();
  end
  
  #1us $stop();
  
end