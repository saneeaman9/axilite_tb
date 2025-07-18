class axilite_reg_bank ;

  bit [31:0] memory [*];
  
  virtual task write(input bit[31:0] aw_addr,
                     input bit[31:0] w_data);
				
	memory[aw_addr] = w_data;
	$display("[REG_BANK] : data written into memory = %0d , addr = %0d",memory[aw_addr],aw_addr);
  endtask 
  


  virtual task read(input bit [31:0] ar_addr,
                    output bit [31:0] r_data);
					
	r_data = memory[ar_addr];
	$display("[REG_BANK] : data read from memory = %0d, addr =%0d",r_data,ar_addr);
	
  endtask 
  
endclass 