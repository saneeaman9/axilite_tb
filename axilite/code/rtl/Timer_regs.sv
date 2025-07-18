
`default_nettype none

module Timer_regs #(
    parameter AXI_ADDR_WIDTH = 32, // width of the AXI address bus
    parameter logic [31:0] BASEADDR = 32'hA0000000 // the register file's system base address 
    ) (
    // Clock and Reset
    input  wire                      axi_aclk,
    input  wire                      axi_aresetn,
                                     
    // AXI Write Address Channel     
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [2:0]                s_axi_awprot,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,
                                     
    // AXI Write Data Channel        
    input  wire [31:0]               s_axi_wdata,
    input  wire [3:0]                s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output wire                      s_axi_wready,
                                     
    // AXI Read Address Channel      
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [2:0]                s_axi_arprot,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,
                                     
    // AXI Read Data Channel         
    output wire [31:0]               s_axi_rdata,
    output wire [1:0]                s_axi_rresp,
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,
                                     
    // AXI Write Response Channel    
    output wire [1:0]                s_axi_bresp,
    output wire                      s_axi_bvalid,
    input  wire                      s_axi_bready,
    
    // User Ports          
    output wire cnt_strobe, // Strobe logic for register 'CNT' (pulsed when the register is written from the bus)
    output wire [0:0] cnt_ena, // Value of register 'CNT', field 'ENA'
    output wire [0:0] cnt_udt, // Value of register 'CNT', field 'UDT'
    output wire [0:0] cnt_ien, // Value of register 'CNT', field 'IEN'
    output wire tlr_strobe, // Strobe logic for register 'TLR' (pulsed when the register is written from the bus)
    output wire [31:0] tlr_tlr, // Value of register 'TLR', field 'TLR'
    output wire tcr_strobe, // Strobe logic for register 'TCR' (pulsed when the register is read from the bus)
    input wire [31:0] tcr_tcr, // Value of register 'TCR', field 'TCR'
    input wire tir_zero_set // Set logic for register 'TIR', field 'ZERO' (pulse to set the field to 1'b1)
    );

    // Constants
    localparam logic [1:0]                      AXI_OKAY        = 2'b00;
    localparam logic [1:0]                      AXI_DECERR      = 2'b11;

    // Registered signals
    logic                                       s_axi_awready_r;
    logic                                       s_axi_wready_r;
    logic [$bits(s_axi_awaddr)-1:0]             s_axi_awaddr_reg_r;
    logic                                       s_axi_bvalid_r;
    logic [$bits(s_axi_bresp)-1:0]              s_axi_bresp_r;
    logic                                       s_axi_arready_r;
    logic [$bits(s_axi_araddr)-1:0]             s_axi_araddr_reg_r;
    logic                                       s_axi_rvalid_r;
    logic [$bits(s_axi_rresp)-1:0]              s_axi_rresp_r;
    logic [$bits(s_axi_wdata)-1:0]              s_axi_wdata_reg_r;
    logic [$bits(s_axi_wstrb)-1:0]              s_axi_wstrb_reg_r;
    logic [$bits(s_axi_rdata)-1:0]              s_axi_rdata_r;

    // User-defined registers
    logic s_cnt_strobe_r;
    logic [0:0] s_reg_cnt_ena_r;
    logic [0:0] s_reg_cnt_udt_r;
    logic [0:0] s_reg_cnt_ien_r;
    logic s_tlr_strobe_r;
    logic [31:0] s_reg_tlr_tlr_r;
    logic s_tcr_strobe_r;
    logic [31:0] s_reg_tcr_tcr;
    logic [0:0] s_reg_tir_zero_r;
	
	logic [31:0] reg0;
	logic [31:0] reg1;
	logic [31:0] reg2;
	logic [31:0] reg3;

    //--------------------------------------------------------------------------
    // Inputs
    //
    assign s_reg_tcr_tcr = tcr_tcr;

    //--------------------------------------------------------------------------
    // Read-transaction FSM
    //    
    localparam MEM_WAIT_COUNT = 2;

    typedef enum {
        READ_IDLE,
        READ_REGISTER,
        WAIT_MEMORY_RDATA,
        READ_RESPONSE,
        READ_DONE
    } read_state_t;

    always_ff@(posedge axi_aclk or negedge axi_aresetn) begin: read_fsm
        // registered state variables
        read_state_t v_state_r;
        logic [31:0] v_rdata_r;
        logic [1:0] v_rresp_r;
        int v_mem_wait_count_r;
        // combinatorial helper variables
        logic v_addr_hit;
        logic [AXI_ADDR_WIDTH-1:0] v_mem_addr;
        if (~axi_aresetn) begin
            v_state_r          <= READ_IDLE;
            v_rdata_r          <= '0;
            v_rresp_r          <= '0;
            v_mem_wait_count_r <= 0;            
            s_axi_arready_r    <= '0;
            s_axi_rvalid_r     <= '0;
            s_axi_rresp_r      <= '0;
            s_axi_araddr_reg_r <= '0;
            s_axi_rdata_r      <= '0;
            s_tcr_strobe_r <= '0;
        end else begin
            // Default values:
            s_axi_arready_r <= 1'b0;
            s_tcr_strobe_r <= '0;

            case (v_state_r)

                // Wait for the start of a read transaction, which is 
                // initiated by the assertion of ARVALID
                READ_IDLE: begin
                    v_mem_wait_count_r <= 0;
                    if (s_axi_arvalid) begin
                        s_axi_araddr_reg_r <= s_axi_araddr;     // save the read address
                        s_axi_arready_r    <= 1'b1;             // acknowledge the read-address
                        v_state_r          <= READ_REGISTER;
                    end
                end

                // Read from the actual storage element
                READ_REGISTER: begin
                    // defaults:
                    v_addr_hit    = 1'b0;
                    s_axi_rdata_r <= '0;
                    
                    // register 'CNT' at address offset 0x0
                    if (s_axi_araddr_reg_r == BASEADDR + Timer_regs_pkg::CNT_OFFSET) begin
                        v_addr_hit = 1'b1;
						v_rdata_r  = reg0;
                        // v_rdata_r[0:0] <= s_reg_cnt_ena_r;
                        // v_rdata_r[1:1] <= s_reg_cnt_udt_r;
                        // v_rdata_r[2:2] <= s_reg_cnt_ien_r;
                        v_state_r <= READ_RESPONSE;
                    end
					if (s_axi_araddr_reg_r == BASEADDR + Timer_regs_pkg::TLR_OFFSET) begin
                        v_addr_hit = 1'b1;
						v_rdata_r  = reg1;
                        // v_rdata_r[0:0] <= s_reg_cnt_ena_r;
                        // v_rdata_r[1:1] <= s_reg_cnt_udt_r;
                        // v_rdata_r[2:2] <= s_reg_cnt_ien_r;
                        v_state_r <= READ_RESPONSE;
                    end
                    // register 'TCR' at address offset 0x8
                    if (s_axi_araddr_reg_r == BASEADDR + Timer_regs_pkg::TCR_OFFSET) begin
                        v_addr_hit = 1'b1;
						v_rdata_r  = reg2;
                        // v_rdata_r[31:0] <= s_reg_tcr_tcr;
                        // s_tcr_strobe_r <= 1'b1;
                        v_state_r <= READ_RESPONSE;
                    end
                    // register 'TIR' at address offset 0xC
                    if (s_axi_araddr_reg_r == BASEADDR + Timer_regs_pkg::TIR_OFFSET) begin
                        v_addr_hit = 1'b1;
						v_rdata_r  = reg3;
                        // v_rdata_r[0:0] <= s_reg_tir_zero_r;
                        v_state_r <= READ_RESPONSE;
                    end
					
                    if (v_addr_hit) begin
                        v_rresp_r <= AXI_OKAY;
                    end else begin
                        v_rresp_r <= AXI_DECERR;
                        // pragma translate_off
                        $warning("ARADDR decode error");
                        // pragma translate_on
                        v_state_r <= READ_RESPONSE;
                    end
                end
                
                // Wait for memory read data
                WAIT_MEMORY_RDATA: begin
                    if (v_mem_wait_count_r == MEM_WAIT_COUNT-1) begin
                        v_state_r <= READ_RESPONSE;
                    end else begin
                        v_mem_wait_count_r <= v_mem_wait_count_r + 1;
                    end
                end

                // Generate read response
                READ_RESPONSE: begin
                    s_axi_rvalid_r <= 1'b1;
                    s_axi_rresp_r  <= v_rresp_r;
                    s_axi_rdata_r  <= v_rdata_r;
                    v_state_r      <= READ_DONE;
                end

                // Write transaction completed, wait for master RREADY to proceed
                READ_DONE: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid_r <= 1'b0;
                        s_axi_rdata_r  <= '0;
                        v_state_r      <= READ_IDLE;
                    end
                end        
                                    
            endcase
        end
    end: read_fsm

    //--------------------------------------------------------------------------
    // Write-transaction FSM
    //    

    typedef enum {
        WRITE_IDLE,
        WRITE_ADDR_FIRST,
        WRITE_DATA_FIRST,
        WRITE_UPDATE_REGISTER,
        WRITE_DONE
    } write_state_t;

    always_ff@(posedge axi_aclk or negedge axi_aresetn) begin: write_fsm
        // registered state variables
        write_state_t v_state_r;
        // combinatorial helper variables
        logic v_addr_hit;
        logic [AXI_ADDR_WIDTH-1:0] v_mem_addr;
        if (~axi_aresetn) begin
            v_state_r                   <= WRITE_IDLE;
            s_axi_awready_r             <= 1'b0;
            s_axi_wready_r              <= 1'b0;
            s_axi_awaddr_reg_r          <= '0;
            s_axi_wdata_reg_r           <= '0;
            s_axi_wstrb_reg_r           <= '0;
            s_axi_bvalid_r              <= 1'b0;
            s_axi_bresp_r               <= '0;
                        
            s_cnt_strobe_r <= '0;
            s_reg_cnt_ena_r <= 1'b0;
            s_reg_cnt_udt_r <= 1'b0;
            s_reg_cnt_ien_r <= 1'b0;
            s_tlr_strobe_r <= '0;
            s_reg_tlr_tlr_r <= 32'b00000000000000000000000000000000;
            s_reg_tir_zero_r <= 1'b0;

        end else begin
            // Default values:
            s_axi_awready_r <= 1'b0;
            s_axi_wready_r  <= 1'b0;
            s_cnt_strobe_r <= '0;
            s_tlr_strobe_r <= '0;
            v_addr_hit = 1'b0;

            case (v_state_r)

                // Wait for the start of a write transaction, which may be 
                // initiated by either of the following conditions:
                //   * assertion of both AWVALID and WVALID
                //   * assertion of AWVALID
                //   * assertion of WVALID
                WRITE_IDLE: begin
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        s_axi_awaddr_reg_r <= s_axi_awaddr; // save the write-address 
                        s_axi_awready_r    <= 1'b1; // acknowledge the write-address
                        s_axi_wdata_reg_r  <= s_axi_wdata; // save the write-data
                        s_axi_wstrb_reg_r  <= s_axi_wstrb; // save the write-strobe
                        s_axi_wready_r     <= 1'b1; // acknowledge the write-data
                        v_state_r          <= WRITE_UPDATE_REGISTER;
                    end else if (s_axi_awvalid) begin
                        s_axi_awaddr_reg_r <= s_axi_awaddr; // save the write-address 
                        s_axi_awready_r    <= 1'b1; // acknowledge the write-address
                        v_state_r          <= WRITE_ADDR_FIRST;
                    end else if (s_axi_wvalid) begin
                        s_axi_wdata_reg_r <= s_axi_wdata; // save the write-data
                        s_axi_wstrb_reg_r <= s_axi_wstrb; // save the write-strobe
                        s_axi_wready_r    <= 1'b1; // acknowledge the write-data
                        v_state_r         <= WRITE_DATA_FIRST;
                    end
                end

                // Address-first write transaction: wait for the write-data
                WRITE_ADDR_FIRST: begin
                    if (s_axi_wvalid) begin
                        s_axi_wdata_reg_r <= s_axi_wdata; // save the write-data
                        s_axi_wstrb_reg_r <= s_axi_wstrb; // save the write-strobe
                        s_axi_wready_r    <= 1'b1; // acknowledge the write-data
                        v_state_r         <= WRITE_UPDATE_REGISTER;
                    end
                end

                // Data-first write transaction: wait for the write-address
                WRITE_DATA_FIRST: begin
                    if (s_axi_awvalid) begin
                        s_axi_awaddr_reg_r <= s_axi_awaddr; // save the write-address 
                        s_axi_awready_r    <= 1'b1; // acknowledge the write-address
                        v_state_r          <= WRITE_UPDATE_REGISTER;
                    end
                end

                // Update the actual storage element
                WRITE_UPDATE_REGISTER: begin
                    s_axi_bresp_r  <= AXI_OKAY; // default value, may be overriden in case of decode error
                    s_axi_bvalid_r <= 1'b1;

                    // register 'CNT' at address offset 0x0
                    if (s_axi_awaddr_reg_r == BASEADDR + Timer_regs_pkg::CNT_OFFSET) begin
                        v_addr_hit = 1'b1;
						reg0 = s_axi_wdata_reg_r;
                        // s_cnt_strobe_r <= 1'b1;
                        // // field 'ENA':
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_cnt_ena_r[0] <= s_axi_wdata_reg_r[0]; // ENA[0]
                        // end
                        // // field 'UDT':
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_cnt_udt_r[0] <= s_axi_wdata_reg_r[1]; // UDT[0]
                        // end
                        // // field 'IEN':
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_cnt_ien_r[0] <= s_axi_wdata_reg_r[2]; // IEN[0]
                        // end
                    end

                    // register 'TLR' at address offset 0x4
                    if (s_axi_awaddr_reg_r == BASEADDR + Timer_regs_pkg::TLR_OFFSET) begin
                        v_addr_hit = 1'b1;
						reg1 = s_axi_wdata_reg_r;
                        // s_tlr_strobe_r <= 1'b1;
                        // // field 'TLR':
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[0] <= s_axi_wdata_reg_r[0]; // TLR[0]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[1] <= s_axi_wdata_reg_r[1]; // TLR[1]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[2] <= s_axi_wdata_reg_r[2]; // TLR[2]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[3] <= s_axi_wdata_reg_r[3]; // TLR[3]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[4] <= s_axi_wdata_reg_r[4]; // TLR[4]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[5] <= s_axi_wdata_reg_r[5]; // TLR[5]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[6] <= s_axi_wdata_reg_r[6]; // TLR[6]
                        // end
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // s_reg_tlr_tlr_r[7] <= s_axi_wdata_reg_r[7]; // TLR[7]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[8] <= s_axi_wdata_reg_r[8]; // TLR[8]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[9] <= s_axi_wdata_reg_r[9]; // TLR[9]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[10] <= s_axi_wdata_reg_r[10]; // TLR[10]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[11] <= s_axi_wdata_reg_r[11]; // TLR[11]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[12] <= s_axi_wdata_reg_r[12]; // TLR[12]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[13] <= s_axi_wdata_reg_r[13]; // TLR[13]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[14] <= s_axi_wdata_reg_r[14]; // TLR[14]
                        // end
                        // if (s_axi_wstrb_reg_r[1]) begin
                            // s_reg_tlr_tlr_r[15] <= s_axi_wdata_reg_r[15]; // TLR[15]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[16] <= s_axi_wdata_reg_r[16]; // TLR[16]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[17] <= s_axi_wdata_reg_r[17]; // TLR[17]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[18] <= s_axi_wdata_reg_r[18]; // TLR[18]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[19] <= s_axi_wdata_reg_r[19]; // TLR[19]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[20] <= s_axi_wdata_reg_r[20]; // TLR[20]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[21] <= s_axi_wdata_reg_r[21]; // TLR[21]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[22] <= s_axi_wdata_reg_r[22]; // TLR[22]
                        // end
                        // if (s_axi_wstrb_reg_r[2]) begin
                            // s_reg_tlr_tlr_r[23] <= s_axi_wdata_reg_r[23]; // TLR[23]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[24] <= s_axi_wdata_reg_r[24]; // TLR[24]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[25] <= s_axi_wdata_reg_r[25]; // TLR[25]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[26] <= s_axi_wdata_reg_r[26]; // TLR[26]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[27] <= s_axi_wdata_reg_r[27]; // TLR[27]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[28] <= s_axi_wdata_reg_r[28]; // TLR[28]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[29] <= s_axi_wdata_reg_r[29]; // TLR[29]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[30] <= s_axi_wdata_reg_r[30]; // TLR[30]
                        // end
                        // if (s_axi_wstrb_reg_r[3]) begin
                            // s_reg_tlr_tlr_r[31] <= s_axi_wdata_reg_r[31]; // TLR[31]
                        // end
                    end
					
					// register 'TIR' at address offset 0xC
                    if (s_axi_awaddr_reg_r == BASEADDR + Timer_regs_pkg::TCR_OFFSET) begin
                        v_addr_hit = 1'b1;
						reg2 = s_axi_wdata_reg_r;
                        // field 'ZERO':
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // if (s_axi_wdata_reg_r[0]) begin // ONE_TO_CLEAR
                                // s_reg_tir_zero_r[0] <=  1'b0; // ZERO[0]
                            // end
                        // end
                    end


                    // register 'TIR' at address offset 0xC
                    if (s_axi_awaddr_reg_r == BASEADDR + Timer_regs_pkg::TIR_OFFSET) begin
                        v_addr_hit = 1'b1;
						reg3 = s_axi_wdata_reg_r;
                        // field 'ZERO':
                        // if (s_axi_wstrb_reg_r[0]) begin
                            // if (s_axi_wdata_reg_r[0]) begin // ONE_TO_CLEAR
                                // s_reg_tir_zero_r[0] <=  1'b0; // ZERO[0]
                            // end
                        // end
                    end

                    if (!v_addr_hit) begin
                        s_axi_bresp_r   <= AXI_DECERR;
                        // pragma translate_off
                        $warning("AWADDR decode error");
                        // pragma translate_on
                    end
                    v_state_r <= WRITE_DONE;
                end

                // Write transaction completed, wait for master BREADY to proceed
                WRITE_DONE: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid_r <= 1'b0;
                        v_state_r      <= WRITE_IDLE;
                    end
                end
            endcase

            if (tir_zero_set) begin // pulsed to set the field 'TIR.ZERO' to 1'b1
                s_reg_tir_zero_r <= '1;
            end

        end
    end: write_fsm

    //--------------------------------------------------------------------------
    // Outputs
    //
    assign s_axi_awready = s_axi_awready_r;
    assign s_axi_wready  = s_axi_wready_r;
    assign s_axi_bvalid  = s_axi_bvalid_r;
    assign s_axi_bresp   = s_axi_bresp_r;
    assign s_axi_arready = s_axi_arready_r;
    assign s_axi_rvalid  = s_axi_rvalid_r;
    assign s_axi_rresp   = s_axi_rresp_r;
    assign s_axi_rdata   = s_axi_rdata_r;
    
    assign cnt_strobe = s_cnt_strobe_r;
    assign cnt_ena = s_reg_cnt_ena_r;
    assign cnt_udt = s_reg_cnt_udt_r;
    assign cnt_ien = s_reg_cnt_ien_r;
    assign tlr_strobe = s_tlr_strobe_r;
    assign tlr_tlr = s_reg_tlr_tlr_r;
    assign tcr_strobe = s_tcr_strobe_r;

endmodule: Timer_regs

`resetall
