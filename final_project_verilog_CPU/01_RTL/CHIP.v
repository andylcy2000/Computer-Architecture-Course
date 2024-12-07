//----------------------------- DO NOT MODIFY THE I/O INTERFACE!! ------------------------------//
module CHIP #(                                                                                  //
    parameter BIT_W = 32                                                                        //
)(                                                                                              //
    // clock                                                                                    //
        input               i_clk,                                                              //
        input               i_rst_n,                                                            //
    // instruction memory                                                                       //
        input  [BIT_W-1:0]  i_IMEM_data,                                                        //
        output [BIT_W-1:0]  o_IMEM_addr,                                                        //
        output              o_IMEM_cen,                                                         //
    // data memory                                                                              //
        input               i_DMEM_stall,                                                       //
        input  [BIT_W-1:0]  i_DMEM_rdata,                                                       //
        output              o_DMEM_cen,                                                         //
        output              o_DMEM_wen,                                                         //
        output [BIT_W-1:0]  o_DMEM_addr,                                                        //
        output [BIT_W-1:0]  o_DMEM_wdata,                                                       //
    // finish procedure                                                                        //
        output              o_finish,                                                           //
    // cache                                                                                    //
        input               i_cache_finish,                                                     //
        output              o_proc_finish                                                       //
);                                                                                              //
//----------------------------- DO NOT MODIFY THE I/O INTERFACE!! ------------------------------//

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Parameters
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: any declaration
    //====== op code ======
    // R-type
    localparam ADD   = 7'b0110011;
    localparam SUB   = 7'b0110011;
    localparam AND   = 7'b0110011;
    localparam XOR   = 7'b0110011;
    localparam MUL   = 7'b0110011;
    localparam R_type = 7'b0110011;
    // I-type
    localparam ADDI  = 7'b0010011;
    localparam SLTI  = 7'b0010011;
    localparam SLLI  = 7'b0010011;
    localparam LW    = 7'b0000011;
    localparam SRAI  = 7'b0010011;
    localparam ECALL = 7'b1110011;
    localparam I_type = 7'b0010011;
    // B-type
    localparam BEQ   = 7'b1100011;
    localparam BGE   = 7'b1100011;
    localparam BLT   = 7'b1100011;
    localparam BNE   = 7'b1100011;
    localparam B_type = 7'b1100011;
    // S-type
    localparam SW    = 7'b0100011;
    // J-type
    localparam JAL   = 7'b1101111;
    localparam JALR  = 7'b1100111;
    // U-type
    localparam AUIPC = 7'b0010111;

    //====== func3 ======
    localparam ADD_FUNC3   = 3'b000;
    localparam SUB_FUNC3   = 3'b000;
    localparam AND_FUNC3   = 3'b111;
    localparam XOR_FUNC3   = 3'b100;
    localparam MUL_FUNC3   = 3'b000;
    localparam SLLI_FUNC3  = 3'b001;
    localparam SRAI_FUNC3  = 3'b101;
    
    localparam ADDI_FUNC3  = 3'b000;
    localparam SLTI_FUNC3  = 3'b010;
    localparam LW_FUNC3    = 3'b010;
    localparam ECALL_FUNC3 = 3'b000;
    localparam BEQ_FUNC3   = 3'b000;
    localparam BGE_FUNC3   = 3'b101;
    localparam BLT_FUNC3   = 3'b100;
    localparam BNE_FUNC3   = 3'b001;
    localparam SW_FUNC3    = 3'b010;

    //====== func7 ======
    localparam ADD_FUNC7  = 7'b0000000;
    localparam SUB_FUNC7  = 7'b0100000;
    localparam AND_FUNC7  = 7'b0000000;
    localparam XOR_FUNC7  = 7'b0000000;
    localparam MUL_FUNC7  = 7'b0000001;
    localparam SLLI_FUNC7 = 7'b0000000;
    localparam SRAI_FUNC7 = 7'b0100000;
    

    //====== FSM ======
    localparam S_IDLE           = 2'd0;
    localparam S_ONE_CYCLE_OP   = 2'd1;
    localparam S_MULTI_CYCLE_OP = 2'd2;
    

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Wires and Registers
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // TODO: any declaration
    // for instruction memory
        reg [BIT_W-1:0] inst_data;
        reg imem_cen;
    
    // for general
        reg [BIT_W-1:0] PC, next_PC;
        //reg [1:0] state_now, state_nxt;
        reg [BIT_W-1:0] imm;
        reg [6:0] opcode;
        reg [2:0] func3;
        reg [6:0] func7;
        reg MUL_ready;
        reg o_finish_reg;
        
    // for data memory
        reg dmem_cen, dmem_wen; //, dmem_cen_nxt, dmem_wen_nxt
        reg [BIT_W-1:0] mem_addr, mem_wdata, mem_rdata;
        wire mem_stall; //modified
        reg [5:0] stall_cnt;


    // for register file
        reg regWrite;
        reg [4:0] rs1;
        reg [4:0] rs2;
        reg [4:0] rd;
        /*
        reg [BIT_W-1:0] rs1data;
        reg [BIT_W-1:0] rs2data;
        */
        wire [BIT_W-1:0] rs1data;//modified
        wire [BIT_W-1:0] rs2data;//modified
        reg [BIT_W-1:0] rddata;
        /*
        wire [BIT_W-1:0] rs1data_wire;//modified
        wire [BIT_W-1:0] rs2data_wire;//modified
        */
    // for mul and div //modified
        reg muldiv_enable;
        wire muldiv_ready;
        wire [BIT_W-1:0] muldiv_rddata;
        reg [5:0] mul_stall_cnt;
        //reg mul_or_div;

    // for cache //modified
        reg i_cache_finish_reg;
        reg o_proc_finish_reg;

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Continuous Assignment
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: any wire assignment
    /*
    assign rs1data_wire = rs1data;//modified
    assign rs2data_wire = rs2data;//modified
    */

    assign o_IMEM_addr = PC;
    assign o_IMEM_cen = imem_cen;

    assign o_DMEM_wdata = mem_wdata;
    assign o_DMEM_addr = mem_addr;
    assign o_DMEM_wen = dmem_wen;
    assign o_DMEM_cen = dmem_cen;
    assign mem_stall = i_DMEM_stall;//modified

    assign o_finish = o_finish_reg;

    assign o_proc_finish = o_proc_finish_reg;//modified
// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Submoddules
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: Reg_file wire connection
    Reg_file reg0(               
        .i_clk  (i_clk),             
        .i_rst_n(i_rst_n),         
        .wen    (regWrite),          
        .rs1    (rs1),                
        .rs2    (rs2),                
        .rd     (rd),                 
        .wdata  (rddata),             
        .rdata1 (rs1data),           
        .rdata2 (rs2data)
    );

    //MULDIV //modified
    MULDIV_unit muldiv0(
        .i_clk (i_clk),
        .i_rst_n (i_rst_n),
        .rs1_data (rs1data),
        .rs2_data (rs2data),
        .rd_data (muldiv_rddata),
        .enable (muldiv_enable),
        .mul_ready (muldiv_ready)
    );

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Always Blocks
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // Todo: any combinational/sequential circuit

    //FSM
    /*
    always @(*) begin
        case(state_now)
            S_IDLE           : state_nxt = ((opcode == MUL) && (func7 == MUL_FUNC7)) ? S_MULTI_CYCLE_OP : S_ONE_CYCLE_OP;
            S_ONE_CYCLE_OP   : begin
                if (mem_stall) state_nxt = S_ONE_CYCLE_OP;
                else state_nxt = ((opcode == MUL) && (func7 == MUL_FUNC7)) ? S_MULTI_CYCLE_OP : S_ONE_CYCLE_OP;
            end
            S_MULTI_CYCLE_OP : begin
                if (MUL_ready) state_nxt = ((opcode == MUL) && (func7 == MUL_FUNC7)) ? S_MULTI_CYCLE_OP : S_ONE_CYCLE_OP;
                else S_IDLE = S_MULTI_CYCLE_OP;
            end
            default : state_nxt = state_now;
        endcase
    end
    */
    
    always @(posedge i_clk) begin
        if (((opcode == LW) || (opcode == SW)) && mem_stall) stall_cnt = stall_cnt + 1;
        else stall_cnt = 0;
    end
    
    always @(posedge i_clk) begin
        if ((opcode == R_type) && ({func3, func7} == {MUL_FUNC3, MUL_FUNC7}) && muldiv_ready) mul_stall_cnt = mul_stall_cnt + 1;
        else mul_stall_cnt = 0;
    end

    always @(posedge i_clk) begin
        if ((opcode == R_type) && ({func3, func7} == {MUL_FUNC3, MUL_FUNC7})) muldiv_enable = 1;
        else muldiv_enable = 0;
    end

    /*
    always @(posedge i_clk) begin
        if (opcode == LW) begin
            dmem_cen = 1;
             dmem_wen = 0;
        end
        else if (opcode == SW) begin
            //$display(23456);
            dmem_cen = 1;
            dmem_wen = 1;

        end
        else begin
            dmem_cen = 0;
            dmem_wen = 0;
        end
    end
    */

    always @(*) begin

        //memory signal and data
        //mem_stall = i_DMEM_stall;//modified
        //mem_stall = 0;

        imem_cen = (!mem_stall) ? 1 : 0;//modified
        mem_rdata = i_DMEM_rdata; //modified

        //cache signal
        i_cache_finish_reg = i_cache_finish;
        o_proc_finish_reg = 0;

        //Intruction Decode
        imm = 32'b0;
        inst_data = i_IMEM_data;
        
        opcode = inst_data[6:0];
        func3 = inst_data[14:12];
        func7 = inst_data[31:25];
        rs1 = inst_data[19:15];
        rs2 = inst_data[24:20];
        rd  = inst_data[11:7];
        ////////

        //chip signal
        //regWrite = 1;
        regWrite = 0;//modified
        //next_PC = PC + 4;
        next_PC = (!mem_stall) ? (PC+4) : PC; //modified
        //muldiv_enable = 0;//modified
        o_finish_reg = 0;
        mem_addr = 0;

        /*
        if ((opcode == LW) || (opcode == SW)) begin
            imem_cen = 0;
            next_PC = PC;
        end
        else begin
            imem_cen = (!mem_stall) ? 1 : 0;
            next_PC = (!mem_stall) ? (PC+4) : PC;
        end
        */
        /*
        $display("Current dmem_cen:%d", dmem_cen);
        $display("Current dmem_wen:%d", dmem_wen);
        */
        if (!i_rst_n) begin
            next_PC = 0;
            //dmem_cen_nxt = 0;
            //dmem_wen_nxt = 0;
            mem_wdata = 0;
            mem_rdata = 0;
            rddata = 0;
            mem_addr = 0;
            dmem_cen = 0;
            dmem_wen = 0;
            inst_data = 0;
        end
        else if (!mem_stall) begin
            //dmem_cen_nxt = 0;
            //dmem_wen_nxt = 0;
            //next_PC = PC + 4;//modified
            //$display(11);
            dmem_cen = 0;
            dmem_wen = 0;
            mem_rdata = 0;
            mem_wdata = 0;
            rddata = 0;
            case(opcode)
                R_type: begin 
                    regWrite = 1;
                    case({func3, func7})
                        {ADD_FUNC3, ADD_FUNC7}: begin
                            rddata = $signed(rs1data) + $signed(rs2data);
                            /*
                            $display("add rs1 data:%d", rs1data);
                            $display("add rs2 data:%d", rs2data);
                            $display("add rd data:%d", rddata);
                            */
                        end
                        {SUB_FUNC3, SUB_FUNC7}: begin
                            rddata = $signed(rs1data) - $signed(rs2data);
                            /*
                            $display("sub rs1 data:%d", rs1data);
                            $display("sub rs2 data:%d", rs2data);
                            $display("sub rd data:%d", rddata);
                            */
                        end
                        {AND_FUNC3, AND_FUNC7}: rddata = rs1data & rs2data;
                        {XOR_FUNC3, XOR_FUNC7}: rddata = rs1data ^ rs2data;
                        {MUL_FUNC3, MUL_FUNC7}: begin
                            //muldiv_enable = 1;
                            /*
                            if (muldiv_ready && (mul_stall_cnt == 0)) begin
                                regWrite = 1;
                                //mul_stall_flag = 1;
                                next_PC = PC;
                            end
                            else if (muldiv_ready && (mul_stall_cnt > 0)) begin

                                regWrite = 1;//muldiv_enable

                            end
                            else begin
                                next_PC = PC;
                                regWrite = 0;
                            end
                            */
                            if (muldiv_ready) begin
                                regWrite = 1;
                                next_PC = PC + 4;
                            end
                            else begin
                                next_PC = PC;
                                regWrite = 0;
                            end
                            rddata = muldiv_rddata;
                        end
                    endcase
                end
                I_type: begin
                    regWrite = 1;
                    case(func3)
                        ADDI_FUNC3:begin
                            imm[11:0] = inst_data[BIT_W-1:20];
                            rddata = $signed(rs1data) + $signed(imm[11:0]);

                        end
                        SLTI_FUNC3:begin
                            imm[11:0] = inst_data[BIT_W-1:20];
                            rddata = ($signed(rs1data) < $signed(imm))? 32'b1 : 32'b0;
                        end
                        SLLI_FUNC3:begin
                            imm[4:0] = inst_data[24:20];
                            rddata = (rs1data << imm);
                        end
                        SRAI_FUNC3:begin
                            imm[4:0] = inst_data[24:20];
                            //rddata = {{imm{rs1data[BIT_W-1]}}, (rs1data >> imm)};
                            rddata = $signed(rs1data) >> imm; //modified
                        end
                    endcase
                end
                LW:begin
                    regWrite = 1;
                    imm[11:0] = inst_data[31:20];
                    mem_addr = rs1data + $signed(imm[11:0]);
                    dmem_cen = 1;
                    dmem_wen = 0;
                    /*
                    if (stall_cnt > 0) begin
                        next_PC = PC + 4;
                    end
                    else begin
                        next_PC = PC;
                    end
                    */
                    //modified
                    /*
                    if (stall_cnt > 0) begin
                        dmem_cen_nxt = 0;
                    end
                    else begin
                        dmem_cen_nxt = 1;
                        next_PC = PC;
                    end
                    */
                    /*
                    if (!mem_stall) begin
                        next_PC = PC + 4;
                    end
                    else begin
                        //next_PC = PC;
                        if (stall_cnt > 0) begin
                            next_PC = PC + 4;

                        end
                        else begin
                            next_PC = PC;
                        end
                    end
                    */
                    //if (rd == 1 ) $display(rddata);
                    if ((stall_cnt > 0) || !mem_stall) begin
                        next_PC = PC + 4;

                    end
                    else begin
                        next_PC = PC;
                    end
                    rddata =  i_DMEM_rdata;
                 

                end
                ECALL:begin
                    //regWrite = 0;
                    /*
                    o_finish_reg = 1;
                    */
                    o_proc_finish_reg = 1;
                    next_PC = PC;
                    if (i_cache_finish) begin
                        o_finish_reg = 1;
                    end
                    else begin
                        o_finish_reg = 0;
                    end

                    
                end
                B_type: case(func3)
                    BEQ_FUNC3:begin
                        //regWrite = 0;
                        imm[12:1] = {inst_data[31], inst_data[7], inst_data[30:25], inst_data[11:8]};
                        if (rs1data == rs2data) next_PC = PC + imm;
                    end
                    BGE_FUNC3:begin
                        //regWrite = 0;
                        imm[12:1] = {inst_data[31], inst_data[7], inst_data[30:25], inst_data[11:8]};
                        if ($signed(rs1data) >= $signed(rs2data)) next_PC = PC + imm;
                    end
                    BLT_FUNC3:begin
                        //regWrite = 0;
                        imm[12:1] = {inst_data[31], inst_data[7], inst_data[30:25], inst_data[11:8]};
                        if ($signed(rs1data) < $signed(rs2data)) next_PC = PC + imm;
                    end
                    BNE_FUNC3:begin
                        //regWrite = 0;
                        imm[12:1] = {inst_data[31], inst_data[7], inst_data[30:25], inst_data[11:8]};
                        if (rs1data !== rs2data) next_PC = PC + imm;
                    end
                endcase
                SW:begin //modified
                    //regWrite = 0;
                    imm[11:0] = {inst_data[31:25], inst_data[11:7]};
                    mem_addr = rs1data + $signed(imm[11:0]);
                    dmem_cen = 1;
                    dmem_wen = 1;

                    /*
                    if (stall_cnt > 0) begin
                        dmem_cen_nxt = 0;
                        dmem_wen_nxt = 0;
                    end
                    else begin
                        dmem_cen_nxt = 1;
                        dmem_wen_nxt = 1;
                        next_PC = PC;
                    end
                    */

                    //dmem_cen = 1;
                    //dmem_wen = 1;
                    //$display("Current dmem_cen:%d", dmem_cen);
                    //$display("Current dmem_wen:%d", dmem_wen);
                    /*
                    if (!mem_stall) begin
                        next_PC = PC + 4;
                    end
                    else begin
                        //next_PC = PC;
                        if (stall_cnt > 0) begin
                            next_PC = PC + 4;

                        end
                        else begin
                            next_PC = PC;
                        end
                    end
                    */
                    if ((stall_cnt > 0) || !mem_stall) begin
                        next_PC = PC + 4;

                    end
                    else begin
                        next_PC = PC;
                    end
                    mem_wdata = rs2data;

                end
                JAL:begin
                    regWrite = 1;
                    //imm [21:1] = {inst_data[31], inst_data[19:12], inst_data[20], inst_data[30:21]};
                    //next_PC = $signed(PC) + $signed(imm);
                    next_PC = $signed(PC) + $signed({inst_data[31], inst_data[19:12], inst_data[20], inst_data[30:21], 1'b0});
                    rddata = PC + 4;
                end
                JALR:begin
                    regWrite = 1;
                    imm[11:0] = inst_data[31:20];
                    next_PC = $signed(rs1data) + $signed(imm);
                    rddata = PC + 4;
                end
                AUIPC:begin
                    regWrite = 1;
                    imm[31:12] = inst_data[31:12];
                    rddata = PC + imm;
                end
            endcase
        end
        else begin
            next_PC = PC;
            //dmem_cen_nxt = 0;
            //dmem_wen_nxt = 0;
            mem_wdata = rs2data;
            if ((opcode == R_type) && ({func3, func7} == {MUL_FUNC3, MUL_FUNC7})) rddata = muldiv_rddata;
            else rddata = 0;
            
            if (opcode == LW) begin
                imm[11:0] = inst_data[31:20];
                mem_addr = rs1data + $signed(imm[11:0]);
                dmem_cen = 1;
                dmem_wen = 0;
            end
            else if (opcode == SW) begin
                imm[11:0] = {inst_data[31:25], inst_data[11:7]};
                mem_addr = rs1data + $signed(imm[11:0]);
                dmem_cen = 1;
                dmem_wen = 1;
            end
            else begin
                mem_addr = 0;
                dmem_cen = 0;
                dmem_wen = 0;
            end
        end
    end

    //Sequential
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            //state_now <= S_IDLE;
            //dmem_cen <= 0;
            //dmem_wen <= 0;
        end
        else begin
            PC <= next_PC;
            //dmem_cen <= dmem_cen_nxt;
            //dmem_wen <= dmem_wen_nxt;
            //$display(opcode);
            //state_now <= state_nxt;
        end
    end

    
endmodule

module Reg_file(i_clk, i_rst_n, wen, rs1, rs2, rd, wdata, rdata1, rdata2);
   
    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth
    
    input i_clk, i_rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] wdata;
    input [addr_width-1:0] rs1, rs2, rd;

    output [BITS-1:0] rdata1, rdata2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign rdata1 = mem[rs1];
    assign rdata2 = mem[rs2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (rd == i)) ? wdata : mem[i];
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
            /*
            $display(mem[5]);
            */
        end       
    end
endmodule

module MULDIV_unit(
    // TODO: port declaration
    i_clk, i_rst_n, rs1_data, rs2_data, rd_data, enable, mul_ready
    );
    // Todo: HW2
    parameter BIT_W = 32;

    input i_clk, i_rst_n, enable;
    input [31:0] rs1_data, rs2_data;
    output mul_ready;
    output [31:0] rd_data;

    reg [5:0] cnt;
    reg [BIT_W-1:0] rs1data, rs2data, rddata;
    reg [2*BIT_W:0] result, pre_result;
    reg [2*BIT_W-1:0] temp, pre_temp;
    reg enable_reg, mul_ready_reg;

    assign rd_data = rddata;
    assign mul_ready = mul_ready_reg;

    always @(*) begin
        enable_reg = enable;
        rs1data = rs1_data;
        rs2data = rs2_data;
        pre_result = 0;
        pre_result = pre_result + rs2data;
        pre_temp = rs1data << 32;
        if (pre_result[0]) begin
            pre_result = pre_result + pre_temp;
            pre_result = pre_result >> 1;
        end
        else begin
            pre_result = pre_result >> 1;
        end

        /*
        if (enable_reg) begin
            rs1data = rs1_data;
            rs2data = rs2_data;
        end
        else begin
            rs1data = 0;
            rs2data = 0;
        end
        */
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cnt = 0;
        end
        else begin
            cnt = (enable_reg) ? (cnt+1) : 0;
            /*
            $display(131);
            $display(enable_reg);
            $display(rs2data);
            $display(132);
            */
            //$display(result);
        /*
        if (enable_reg) cnt = cnt + 1;
        else cnt = 0;
        */
        end
    end 

    always @(posedge i_clk) begin
        /*
        $display(111);
        $display(enable_reg);
        $display(112);
        */
        if (cnt == 0) begin
            //result = 0;
            result = pre_result;
            //result = result + rs2data;
            temp = rs1data << 32;
        end
        
        if (cnt <= 30) begin
            if (result[0]) begin
                result = result + temp;
                result = result >> 1;
            end
            else begin
                result = result >> 1;
            end
        end
        else result = result + 0;
        
        
        /*
        $display(121);
        $display(cnt);
        $display(result);
        $display(122);
        */

        if ((cnt == 30) || (cnt == 31)) begin
            rddata = result;
            //$display(result);
            mul_ready_reg = 1;
        end
        else begin
            rddata = 0;
            mul_ready_reg = 0;
        end
    end

    
    
endmodule

module Cache#(
        parameter BIT_W = 32,
        parameter ADDR_W = 32
    )(
        input i_clk,
        input i_rst_n,
        // processor interface
            input i_proc_cen,
            input i_proc_wen,
            input [ADDR_W-1:0] i_proc_addr,
            input [BIT_W-1:0]  i_proc_wdata,
            output [BIT_W-1:0] o_proc_rdata,
            output o_proc_stall,
            input i_proc_finish,
            output o_cache_finish,
        // memory interface
            output o_mem_cen,
            output o_mem_wen,
            output [ADDR_W-1:0] o_mem_addr,
            output [BIT_W*4-1:0]  o_mem_wdata,
            input [BIT_W*4-1:0] i_mem_rdata,
            input i_mem_stall,
            output o_cache_available,
        // others
        input  [ADDR_W-1: 0] i_offset
    );

    assign o_cache_available = 1; // change this value to 1 if the cache is implemented

    //------------------------------------------//
    //          default connection              //
    /*
    assign o_mem_cen = i_proc_cen;              //
    assign o_mem_wen = i_proc_wen;              //
    assign o_mem_addr = i_proc_addr;            //
    assign o_mem_wdata = i_proc_wdata;          //
    assign o_proc_rdata = i_mem_rdata[0+:BIT_W];//
    assign o_proc_stall = i_mem_stall;          //
    */
    //------------------------------------------//

    // Todo: BONUS
    
    //parameters
    //state
    localparam INITIAL = 2'b00;
    localparam WRITE_BACK = 2'b01;
    localparam ALLO = 2'b10;
    localparam FINISH = 2'b11;

    //size
    localparam num_of_block = 18;

    //regs
    //for cache block param.
    reg [157:0] cache_block [0:num_of_block-1]; //157:dirty //156:valid //155:128:tag
    reg full;
    reg hit;
    reg [1:0] offset;

    //for stall
    reg cache_stall;
    reg mem_cen, mem_cen_nxt;
    reg mem_wen, mem_wen_nxt;
    reg [3:0] stall_cnt;

    //for FSM
    reg [1:0] state, state_next;
    reg [4:0] idx;
    //reg cen,wen;

    //others
    reg [ADDR_W-1:0] input_addr;
    reg [BIT_W-1:0] return_data;
    reg [4*BIT_W-1:0] write_back_data;  
    reg [ADDR_W-1:0] mem_addr;

    //for finish state
    reg [4:0] finish_cnt, finish_cnt_nxt;
    reg dirty_all;
    reg finish;

    //assign
    assign o_proc_rdata = return_data;
    assign o_cache_finish = finish;
    assign o_mem_wdata = write_back_data;
    assign o_mem_addr = mem_addr;
    assign o_mem_cen = mem_cen;
    assign o_mem_wen = mem_wen;
    assign o_proc_stall = cache_stall;

    //always
    always @(*) begin
        if ($unsigned(i_proc_addr) > 32'h0c000000) input_addr = i_proc_addr;
        else input_addr = i_proc_addr - i_offset;
        full = (cache_block[0][156] & cache_block[1][156] & cache_block[2][156] & cache_block[3][156] & cache_block[4][156] & cache_block[5][156] & cache_block[6][156] & cache_block[7][156] & cache_block[8][156] & cache_block[9][156] & cache_block[10][156] & cache_block[11][156] & cache_block[12][156] & cache_block[13][156] & cache_block[14][156] & cache_block[15][156] & cache_block[16][156] & cache_block[17][156]);
        hit = ((cache_block[0][156] && (cache_block[0][155:128] == input_addr[31:4])) || (cache_block[1][156] && (cache_block[1][155:128] == input_addr[31:4])) || (cache_block[2][156] && (cache_block[2][155:128] == input_addr[31:4])) || (cache_block[3][156] && (cache_block[3][155:128] == input_addr[31:4])) || (cache_block[4][156] && (cache_block[4][155:128] == input_addr[31:4])) || (cache_block[5][156] && (cache_block[5][155:128] == input_addr[31:4])) || (cache_block[6][156] && (cache_block[6][155:128] == input_addr[31:4])) || (cache_block[7][156] && (cache_block[7][155:128] == input_addr[31:4])) || (cache_block[8][156] && (cache_block[8][155:128] == input_addr[31:4])) || (cache_block[9][156] && (cache_block[9][155:128] == input_addr[31:4])) || (cache_block[10][156] && (cache_block[10][155:128] == input_addr[31:4])) || (cache_block[11][156] && (cache_block[11][155:128] == input_addr[31:4])) || (cache_block[12][156] && (cache_block[12][155:128] == input_addr[31:4])) || (cache_block[13][156] && (cache_block[13][155:128] == input_addr[31:4])) || (cache_block[14][156] && (cache_block[14][155:128] == input_addr[31:4])) || (cache_block[15][156] && (cache_block[15][155:128] == input_addr[31:4])) || (cache_block[16][156] && (cache_block[16][155:128] == input_addr[31:4])) || (cache_block[17][156] && (cache_block[17][155:128] == input_addr[31:4])));
        dirty_all = (cache_block[0][157] | cache_block[1][157] | cache_block[2][157] | cache_block[3][157] | cache_block[4][157] | cache_block[5][157] | cache_block[6][157] | cache_block[7][157] | cache_block[8][157] | cache_block[9][157] | cache_block[10][157] | cache_block[11][157] | cache_block[12][157] | cache_block[13][157] | cache_block[14][157] | cache_block[15][157] | cache_block[16][157] | cache_block[17][157]);
        offset = input_addr[3:2];
    end

    //stall

    /*
    always @(*) begin
        if (!hit && i_proc_cen) begin
            cache_stall = 1;
            if (mem_cen || mem_wen) begin
                mem_cen_nxt = 0;
                mem_wen_nxt = 0;
            end
            else if ((state == INITIAL) && (state_next == WRITE_BACK)) begin
                mem_cen_nxt = 1;
                mem_wen_nxt = 1;
            end
            else if ((state == INITIAL) && (state_next == ALLO)) begin
                mem_cen_nxt = 1;
                mem_wen_nxt = 0;
            end
            else if ((state == WRITE_BACK) && (state_next == ALLO)) begin
                mem_cen_nxt = 1;
                mem_wen_nxt = 0;
            end
            else if ((state == ALLO) && (state_next == INITIAL)) begin
                cache_stall = 0;
                mem_cen_nxt = 0;
                mem_wen_nxt = 0;
            end
            else begin 
                cache_stall = cache_stall + 0;

            end
        end
        else begin
            cache_stall = 0;
            mem_cen_nxt = 0;
            mem_wen_nxt = 0;
        end
    end
    */

    /*
    always @(*) begin
        if (!hit) begin
            if (stall_cnt > 0) begin
                // cache_stall = i_mem_stall;
                mem_cen_nxt = 0;
                mem_wen_nxt = 0;
                if ((state == ALLO) && (state_next == INITIAL)) cache_stall = 0;
                else cache_stall = 1;
            end
            else begin
                cache_stall = 1;
                case (state_next) 
                INITIAL: begin
                    mem_cen_nxt = i_proc_cen;
                    mem_wen_nxt = i_proc_wen;
                end
                WRITE_BACK: begin
                    mem_cen_nxt = 1;
                    mem_wen_nxt = 1;
                end
                ALLO: begin
                    mem_cen_nxt = 1;
                    mem_wen_nxt = 0;
                end
                FINISH:
                endcase
            end
        end
        else cache_stall = 0;
    end
    */

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            mem_cen <= 0;
            mem_wen <= 0;
            //stall_cnt = 0;
        end
        else begin
            mem_cen <= mem_cen_nxt;
            mem_wen <= mem_wen_nxt;
            //if (i_mem_stall) stall_cnt = stall_cnt + 1;
            //else stall_cnt = 0;
        end
    end

    //cache hit
    integer i, j, k;

    /*
    always @(*) begin
        for (i=0; i<num_of_block; i=i+1) begin
            cache_block_next[i][32*(offset+1):32*offset] = (i_proc_wen && (input_addr[31:4] == cache_block[i][155:128])) ? i_proc_wdata : cache_block[i][32*(offset+1):32*offset];
            cache_block_next[i][157] = 1;
        end
    end
    */

    //read when hit(moved to state behavior)
    /*
    always @(*) begin
        if (state != INITIAL) return_data = return_data;
        else if (i_proc_cen && !i_proc_wen) begin
            if (hit) begin
                (j=0; j<num_of_block; j=j+1) return_data = (input_addr[31:4] == cache_block[i][155:128]) ? cache_block[i][32*(offset+1):32*offset] : return_data;
            end
            else return_data = 32'hz;
        end
        else return_data = 32'hz;
    end
    */

    //write when hit
    /*
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i=0; i<num_of_block; i=i+1) cache_block[i] = 0;
        end
        else if (i_proc_wen) begin
            for (i=0; i<num_of_block; i=i+1) begin
                if ((input_addr[31:4] == cache_block[i][155:128]) && cache_block[i][156]) begin
                    case (offset)
                        2'b00:cache_block[i][31:0] = i_proc_wdata;
                        2'b01:cache_block[i][63:32] = i_proc_wdata;
                        2'b10:cache_block[i][95:64] = i_proc_wdata;
                        2'b11:cache_block[i][127:96] = i_proc_wdata;
                    endcase
                    cache_block[i][157] = 1;
                end
                else begin
                    cache_block[i] = cache_block[i] + 0;
                end
            end
        end
        else for (i=0; i<num_of_block; i=i+1) cache_block[i] = cache_block[i] + 0;
    end
    */

    //state behavior
    always @(*) begin
        if (!i_rst_n) begin
            finish = 0;
            finish_cnt_nxt = 0;
            return_data = 0;
            cache_stall = 0;
            mem_addr = 0;
            mem_cen_nxt = 0;
            write_back_data = 0;
            mem_wen_nxt = 0;
            //
            for (i=0; i<num_of_block; i=i+1) cache_block[i] = 0;
            //
        end
        else begin
            finish = finish + 0;
            finish_cnt_nxt = finish_cnt_nxt + 0;
            return_data = return_data + 1;
            return_data = return_data - 1;
            for (i=0; i<num_of_block; i=i+1) begin
                cache_block[i] = cache_block[i] + 1;
                cache_block[i] = cache_block[i] - 1;
            end
            case (state)
                INITIAL:begin
                    write_back_data = 0;
                    mem_addr = 0;
                    if (i_proc_cen && !i_proc_wen) begin // read when hit
                        if (hit) begin
                            for (j=0; j<num_of_block; j=j+1) begin
                                if (cache_block[j][156] && (input_addr[31:4] == cache_block[j][155:128])) begin
                                    case (offset)
                                        2'b00:return_data = cache_block[j][31:0];
                                        2'b01:return_data = cache_block[j][63:32];
                                        2'b10:return_data = cache_block[j][95:64];
                                        2'b11:return_data = cache_block[j][127:96];
                                    endcase
                                end
                                else begin 
                                    return_data = return_data + 1;
                                    return_data = return_data - 1;
                                end
                            end
                        end
                        else return_data = 0;
                    end
                    else if (i_proc_wen) begin // write when hit
                        for (i=0; i<num_of_block; i=i+1) begin
                            if ((input_addr[31:4] == cache_block[i][155:128]) && cache_block[i][156]) begin
                                case (offset)
                                    2'b00:cache_block[i][31:0] = i_proc_wdata;
                                    2'b01:cache_block[i][63:32] = i_proc_wdata;
                                    2'b10:cache_block[i][95:64] = i_proc_wdata;
                                    2'b11:cache_block[i][127:96] = i_proc_wdata;
                                endcase
                                cache_block[i][157] = 1;
                            end
                            else begin
                                cache_block[i] = cache_block[i] + 0;
                            end
                        end
                    end
                    else begin
                        return_data = 0;
                        for (i=0; i<num_of_block; i=i+1) cache_block[i] = cache_block[i] + 0;
                    end
                end
                WRITE_BACK:begin
                    write_back_data = cache_block[idx][127:0];
                    mem_addr = ($unsigned({cache_block[idx][155:128], 4'b0}) > 32'h0c000000) ? ({cache_block[idx][155:128], 4'b0}) : ({cache_block[idx][155:128], 4'b0} + i_offset);
                end
                ALLO:begin
                    write_back_data = 0;
                    mem_addr = ($unsigned(i_proc_addr) > 32'h0c000000) ? ({input_addr[31:4], 4'b0}) : ({input_addr[31:4], 4'b0} + i_offset);
                    if (!cache_stall) begin
                        case (offset) 
                            2'b00:begin
                                if (i_proc_wen && (i_proc_wdata != i_mem_rdata[31:0])) begin
                                    cache_block[idx] = {2'b11, input_addr[31:4], i_mem_rdata};
                                    cache_block[idx][31:0] = i_proc_wdata;
                                end
                                else if (i_proc_cen && !i_proc_wen) begin
                                cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                                return_data = cache_block[idx][31:0];
                                end
                                else cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                            end
                            2'b01:begin
                                if (i_proc_wen && (i_proc_wdata != i_mem_rdata[63:32])) begin
                                    cache_block[idx] = {2'b11, input_addr[31:4], i_mem_rdata};
                                    cache_block[idx][63:32] = i_proc_wdata;
                                end
                                else if (i_proc_cen && !i_proc_wen) begin
                                cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                                return_data = cache_block[idx][63:32];
                                end
                                else cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                            end
                            2'b10:begin
                                if (i_proc_wen && (i_proc_wdata != i_mem_rdata[95:64])) begin
                                    cache_block[idx] = {2'b11, input_addr[31:4], i_mem_rdata};
                                    cache_block[idx][95:64] = i_proc_wdata;
                                end
                                else if (i_proc_cen && !i_proc_wen) begin
                                cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                                return_data = cache_block[idx][95:64];
                                end
                                else cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                            end
                            2'b11:begin
                                if (i_proc_wen && (i_proc_wdata != i_mem_rdata[127:96])) begin
                                    cache_block[idx] = {2'b11, input_addr[31:4], i_mem_rdata};
                                    cache_block[idx][127:96] = i_proc_wdata;
                                end
                                else if (i_proc_cen && !i_proc_wen) begin
                                cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                                return_data = cache_block[idx][127:96];
                                end
                                else cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                            end
                            default: cache_block[idx] = {2'b01, input_addr[31:4], i_mem_rdata};
                        endcase
                    end
                    
                    else cache_block[idx] = cache_block[idx] + 0;
                end
                FINISH:begin
                    mem_addr = ($unsigned({cache_block[finish_cnt][155:128], 4'b0}) > 32'h0c000000) ? ({cache_block[finish_cnt][155:128], 4'b0}) : ({cache_block[finish_cnt][155:128], 4'b0} + i_offset);
                    write_back_data = cache_block[finish_cnt][127:0];
                    if (dirty_all) begin
                        if (cache_block[finish_cnt][157]) begin
                            finish_cnt_nxt = finish_cnt;
                            mem_cen_nxt = 1;
                            mem_wen_nxt = 1;
                            cache_block[finish_cnt][157] = 0;
                        end
                        else if (mem_wen_nxt || i_mem_stall) finish_cnt_nxt = finish_cnt;
                        else finish_cnt_nxt = finish_cnt + 1;
                    end
                    else if (mem_wen_nxt || i_mem_stall) finish = 0;
                    else finish = 1;
                end
            endcase

            if (mem_cen || mem_wen) begin
                cache_stall = cache_stall + 1;
                cache_stall = cache_stall - 1;
                mem_cen_nxt = 0;
                mem_wen_nxt = 0;
            end
            else if (!hit && i_proc_cen) begin //cen & wen control
                cache_stall = 1;
                 if ((state == INITIAL) && (state_next == WRITE_BACK)) begin
                    mem_cen_nxt = 1;
                    mem_wen_nxt = 1;
                end
                else if ((state == INITIAL) && (state_next == ALLO)) begin
                    mem_cen_nxt = 1;
                    mem_wen_nxt = 0;
                end
                else if ((state == WRITE_BACK) && (state_next == ALLO)) begin
                    mem_cen_nxt = 1;
                    mem_wen_nxt = 0;
                end
                else if ((state == ALLO) && (state_next == INITIAL)) begin
                    cache_stall = 0;
                    mem_cen_nxt = 0;
                    mem_wen_nxt = 0;
                end
                else begin 
                    cache_stall = cache_stall + 1;
                    cache_stall = cache_stall - 1;
                    mem_cen_nxt = mem_cen_nxt + 1;
                    mem_cen_nxt = mem_cen_nxt - 1;
                    mem_wen_nxt = mem_wen_nxt + 1;
                    mem_wen_nxt = mem_wen_nxt - 1;
                end
            end
            else if (state == FINISH) begin
                cache_stall = 0;
                mem_cen_nxt = mem_cen_nxt + 1;
                mem_cen_nxt = mem_cen_nxt - 1;
                mem_wen_nxt = mem_wen_nxt + 1;
                mem_wen_nxt = mem_wen_nxt - 1;
            end
            else begin
                cache_stall = 0;
                mem_cen_nxt = 0;
                mem_wen_nxt = 0;
            end
        end
    end

    always @(*) begin
        if ((state == INITIAL) && i_proc_cen && !hit && full && !i_proc_finish) begin
            idx = $unsigned(input_addr[31:4] + i_proc_wdata) % num_of_block;
            idx = $unsigned(idx) % num_of_block;
        end
        else if ((state == INITIAL) && i_proc_cen && !hit &&!full && !i_proc_finish) begin
            for (k=0; k<num_of_block; k=k+1) begin
                if (!cache_block[num_of_block-k-1][156]) idx = num_of_block - k - 1;
                else idx = idx;
            end
        end
        else begin
            idx = idx + 1;
            idx = idx - 1;
        end
    end
    //FSM
    always @(*) begin //是不是要跟上面的always block合併?

        //
        case(state)
            INITIAL:begin
                if (i_proc_finish) state_next = FINISH;
                else if (i_proc_cen && i_proc_wen) begin // write
                    if (hit) state_next = INITIAL;
                    else begin
                        /* 
                        TODO: determine which block to replace
                         if not full: choose empty one
                         if full: random
                         */
                        if (full) begin
                            //idx = $random;
                            //idx = $unsigned(input_addr[31:4] + i_proc_wdata) % num_of_block;
                            //idx = $unsigned(idx) % num_of_block; //
                            if (cache_block[idx][157]) state_next = WRITE_BACK; // dirty
                            else state_next = ALLO;
                        end
                        else begin
                            // for (k=0; k<num_of_block; k=k+1) begin
                            //     if (!cache_block[num_of_block-k-1][156]) idx = num_of_block - k - 1;
                            //     else idx = idx;
                            // end
                            state_next = ALLO;
                        end
                        /*
                        if (dirty) state_next = WRITE_BACK;
                        else state_next = ALLO;
                        */
                    end
                end
                else if (i_proc_cen && !i_proc_wen) begin //to read
                    if (hit) state_next = INITIAL;
                    else begin
                        /*
                        TODO: determine which block to replace
                         */
                        //跟上面的一樣/////////////////////////////////
                        if (full) begin
                            //idx = $random;
                            //idx = $unsigned(input_addr[31:4] + i_proc_wdata) % num_of_block;
                            //idx = $unsigned(idx) % num_of_block;
                            if (cache_block[idx][157]) state_next = WRITE_BACK; // dirty
                            else state_next = ALLO;
                        end
                        else begin
                            
                            // for (k=0; k<num_of_block; k=k+1) begin
                            //     if (!cache_block[num_of_block-k-1][156]) idx = num_of_block - k - 1;
                            //     else idx = idx;
                            // end
                            state_next = ALLO;
                        end
                        //////////////////////////////////////////////
                        /*
                        else if (dirty) state_next = WRITE_BACK;
                        else state_next = ALLO;
                        */
                    end
                end
                else state_next = INITIAL;
            end
            WRITE_BACK:begin
                if (i_mem_stall) begin
                    state_next = WRITE_BACK;
                end
                else begin
                    state_next = ALLO;
                end
            end
            ALLO:begin
                /*
                if (i_proc_cen && i_proc_wen && (!i_mem_stall)) begin //如果這樣寫的話上面對memory的wen和cen的pull low時機要改
                    state_next = INITIAL
                end
                else if (i_proc_cen && (!i_proc_wen) && (!i_mem_stall)) begin
                    state_next = INITIAL;
                end
                */
                if (!i_mem_stall) begin
                    state_next = INITIAL;
                end
                else begin
                    state_next = ALLO;
                end
            end
            FINISH: state_next = FINISH;
            default: state_next = state;
        endcase
    end
    
    /*
    always @(posedge i_clk) begin
            if ((state == FINISH) && (!i_mem_stall)) begin
                finish_cnt_nxt = finish_cnt + 1;
            end
            else if (state == FINISH && i_mem_stall) begin
                finish_cnt_nxt = finish_cnt;
            end
            else begin
                finish_cnt_nxt = 0;
            end
    end
    */

    always @(posedge i_clk or negedge i_rst_n ) begin
        if (!i_rst_n) begin
            state <= INITIAL;
            finish_cnt <= 0;
            /*
            input_addr <= i_proc_addr;
            if (i_proc_wen) begin
                i_proc_wdata <= i_proc_wdata;
            end
            */
        end
        else begin
            state <= state_next;
            finish_cnt <= finish_cnt_nxt;
        end
        /*
        if ((cen && wen && (!i_mem_stall)) || (cen && (!i_mem_stall))) begin
            cen <= 0;
            wen <= 0;
        
            addr <= 0;
            wdata <= 0;
            
        end
        else if (i_cen && delay_cnt == 0) begin
            cen <= i_cen;
            wen <= i_wen;
            addr <= i_addr;
            wdata <= i_wdata;
         end
        */
    end
endmodule