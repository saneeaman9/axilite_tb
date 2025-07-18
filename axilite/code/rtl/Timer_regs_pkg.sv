package Timer_regs_pkg;

    // Revision number of the 'Timer' register map
    localparam TIMER_REVISION = 0;

    // Default base address of the 'Timer' register map 
    localparam logic [31:0] TIMER_DEFAULT_BASEADDR = 32'hA0000000;
    
    // Register 'CNT'
    localparam logic [31:0] CNT_OFFSET = 32'h00000000; // address offset of the 'CNT' register
    localparam CNT_ENA_BIT_OFFSET = 0; // bit offset of the 'ENA' field
    localparam CNT_ENA_BIT_WIDTH = 1; // bit width of the 'ENA' field
    localparam logic [0:0] CNT_ENA_RESET = 1'b0; // reset value of the 'ENA' field
    localparam CNT_UDT_BIT_OFFSET = 1; // bit offset of the 'UDT' field
    localparam CNT_UDT_BIT_WIDTH = 1; // bit width of the 'UDT' field
    localparam logic [1:1] CNT_UDT_RESET = 1'b0; // reset value of the 'UDT' field
    localparam CNT_IEN_BIT_OFFSET = 2; // bit offset of the 'IEN' field
    localparam CNT_IEN_BIT_WIDTH = 1; // bit width of the 'IEN' field
    localparam logic [2:2] CNT_IEN_RESET = 1'b0; // reset value of the 'IEN' field
    
    // Register 'TLR'
    localparam logic [31:0] TLR_OFFSET = 32'h00000004; // address offset of the 'TLR' register
    localparam TLR_TLR_BIT_OFFSET = 0; // bit offset of the 'TLR' field
    localparam TLR_TLR_BIT_WIDTH = 32; // bit width of the 'TLR' field
    localparam logic [31:0] TLR_TLR_RESET = 32'b00000000000000000000000000000000; // reset value of the 'TLR' field
    
    // Register 'TCR'
    localparam logic [31:0] TCR_OFFSET = 32'h00000008; // address offset of the 'TCR' register
    localparam TCR_TCR_BIT_OFFSET = 0; // bit offset of the 'TCR' field
    localparam TCR_TCR_BIT_WIDTH = 32; // bit width of the 'TCR' field
    localparam logic [31:0] TCR_TCR_RESET = 32'b00000000000000000000000000000000; // reset value of the 'TCR' field
    
    // Register 'TIR'
    localparam logic [31:0] TIR_OFFSET = 32'h0000000C; // address offset of the 'TIR' register
    localparam TIR_ZERO_BIT_OFFSET = 0; // bit offset of the 'ZERO' field
    localparam TIR_ZERO_BIT_WIDTH = 1; // bit width of the 'ZERO' field
    localparam logic [0:0] TIR_ZERO_RESET = 1'b0; // reset value of the 'ZERO' field

endpackage: Timer_regs_pkg
