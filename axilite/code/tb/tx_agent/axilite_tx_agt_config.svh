`include"../../tb/common/axilite_params.svh"
//import axilite_header_pkg :: * ;
class axilite_tx_agt_config;

  virtual axilite_interface.drv_mp axi_intf_drv;
  virtual axilite_interface.mon_mp axi_intf_mon;
  
  event   drv2gen_event_w           ;
  event   drv2gen_event_r           ;
  logic   [ADDR_WIDTH -1 :0] aw_addr;
  logic   [ADDR_WIDTH -1 :0] ar_addr;
  logic   [DATA_WIDTH -1 :0] w_data;
  
endclass