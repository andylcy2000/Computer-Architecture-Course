module ALU #(
    parameter DATA_W = 32
)
(
    input                       i_clk,   // clock
    input                       i_rst_n, // reset

    input                       i_valid, // input valid signal
    input [DATA_W - 1 : 0]      i_A,     // input operand A
    input [DATA_W - 1 : 0]      i_B,     // input operand B
    input [         2 : 0]      i_inst,  // instruction

    output [2*DATA_W - 1 : 0]   o_data,  // output value
    output                      o_done   // output valid signal
);
// Do not Modify the above part !!!

// Parameters
    // ======== choose your FSM style ==========
    // 1. FSM based on operation cycles
    
    parameter S_IDLE           = 2'd0;
    parameter S_ONE_CYCLE_OP   = 2'd1;
    parameter S_MULTI_CYCLE_OP = 2'd2;
    
    // 2. FSM based on operation modes
    /*
     parameter S_IDLE = 4'd0;
     parameter S_ADD  = 4'd1;
     parameter S_SUB  = 4'd2;
     parameter S_AND  = 4'd3;
     parameter S_OR   = 4'd4;
     parameter S_SLT  = 4'd5;
     parameter S_SLL  = 4'd6;
     parameter S_MUL  = 4'd7;
     parameter S_DIV  = 4'd8;
     parameter S_OUT  = 4'd9;
    */
    parameter ADD = 3'd0;
    parameter SUB = 3'd1;
    parameter AND = 3'd2;
    parameter OR  = 3'd3;
    parameter SLT = 3'd4;
    parameter SLL = 3'd5;
    parameter MUL = 3'd6;
    parameter DIV = 3'd7;
// Wires & Regs
    // Todo
    // state
    reg  [         1: 0] state, state_nxt; // remember to expand the bit width if you want to add more states!
    // load input
    reg  [  DATA_W-1: 0] operand_a, operand_a_nxt;
    reg  [  DATA_W-1: 0] operand_b, operand_b_nxt;
    reg  [  DATA_W-1: 0] temp_operand_a;
    reg  [  DATA_W-1: 0] temp_operand_b;
    reg  [2*DATA_W-1: 0] compare;
    reg  [         2: 0] inst, inst_nxt;
    reg  [         5: 0] cnt;
    reg  [2*DATA_W  : 0] result;
    reg  [2*DATA_W  : 0] o_data_in;
    reg  [2*DATA_W - 1 : 0] temp;
    reg  [2*DATA_W - 1 : 0] temp_for_divisor;
    reg  [DATA_W - 1 : 0] temp_last_step;
    reg                  ready;
    reg                  div_flag;
// Wire Assignments
    // Todo
    assign o_data = o_data_in;
    assign o_done = ready;
// Always Combination
    // load input
    always @(*) begin
        if (i_valid) begin
            operand_a_nxt = i_A;
            operand_b_nxt = i_B;
            inst_nxt      = i_inst;
        end
        else begin
            operand_a_nxt = operand_a;
            operand_b_nxt = operand_b;
            inst_nxt      = inst;
        end
    end
    // Todo: FSM
    always @(*) begin
        case(state)
        
            S_IDLE           : state_nxt = (!i_valid) ? S_IDLE : ((i_inst == MUL) || (i_inst == DIV)) ? S_MULTI_CYCLE_OP :S_ONE_CYCLE_OP;
            S_ONE_CYCLE_OP   : state_nxt = S_IDLE;
            S_MULTI_CYCLE_OP : state_nxt = (cnt==32) ? S_IDLE : S_MULTI_CYCLE_OP;

            default : state_nxt = state;
        endcase
    end
    // Todo: Counter
    always @(posedge i_clk) begin
        if (state == S_MULTI_CYCLE_OP) begin
            cnt = cnt + 1;
        end
        else begin
            cnt = 0;
        end
    end
    // Todo: ALU output

    always @(posedge i_clk) begin
        if (state == S_IDLE) begin
            result = 0;
        end
        if (state == S_ONE_CYCLE_OP) begin
            if (inst == ADD) begin
                result = operand_a + operand_b;
                //$display(3);
                /*
                compare = {1, 31'b0};
                compare = compare - 1;
                */
                if (!result[31] && ((operand_a[31])&&(operand_b[31]))) begin
                    result = 32'h80000000;
                end
                else begin
                    if((!operand_a[31] && !operand_b[31]) && result[31]) begin
                        result = 32'h7FFFFFFF;
                    end
                end
                /*
                    if (operand_a >= 0) begin
                        result = 31'b1;
                    end
                    else begin
                        result = 2**31;
                    end
                */
                //end
                /*
                else begin
                    compare = 
                    if (result < -2**31) begin
                        result = -2**31;
                    end
                end
                */

                result = result[31:0];
            end
            else begin
                if (inst == SUB) begin
                    if (operand_a[31] && !operand_b[31]) begin
                        temp_operand_a = ~operand_a;
                        temp_operand_a = temp_operand_a + 1; 
                        temp = temp_operand_a + operand_b;
                        compare = {1, 31'b0};
                        if (temp >= compare) begin
                            result = compare;
                        end
                        else begin
                            result = ~temp;
                            result = result + 1;
                        end
                    end
                    else begin
                        if (!operand_a[31] && operand_b[31]) begin
                            temp_operand_b = ~operand_b;
                            temp_operand_b = temp_operand_b +1 ;
                            temp = operand_a + temp_operand_b;
                            compare = {1, 31'b0};
                            compare = compare - 1;
                            if (temp >= compare) begin
                                result = compare;
                            end
                            else begin
                                result = temp;
                            end
                        end

                        else begin
                            if (operand_a[31] && operand_b[31]) begin
                                temp_operand_a = ~operand_a;
                                temp_operand_a = temp_operand_a + 1; 
                                temp_operand_b = ~operand_b;
                                temp_operand_b = temp_operand_b +1 ;
                                result = temp_operand_b - temp_operand_a;
                            end

                            else begin 
                                result = operand_a - operand_b;
                            end
                        end
                        
                    end
                    /*
                        result = operand_a + operand_b;
                        if (result >= 2**32) begin
                            result = 2**31;
                        end
                    */
                    //end
                /*
                    result = operand_a - operand_b;
                    if (result > 2**31-1 && ((!operand_a[31])&&(!operand_b[31]))) begin
                    result = 2**31-1;
                    end

                    else begin
                        if (result < -(2**31) && ((operand_a[31])&&(!operand_b[31]))) begin
                            result = -2**31;
                        end
                    end
                */
                    result = result[31:0];
                end
                else begin
                    if (inst == AND) begin
                        result = operand_a & operand_b;
                    end

                    else begin
                        if (inst == OR) begin
                            result = operand_a | operand_b;
                        end

                        else begin
                            if (inst == SLT) begin
                                if (((operand_a[31] == 0) && (operand_b[31] == 1)) || ((operand_a >= operand_b) && !operand_a[31]) || ((operand_a[31] && operand_b[31]) && operand_a >= operand_b)) begin
                                    result = 0;
                                end
                                else begin
                                    result = 1;
                                end
                            end
                            else begin
                                if (inst == SLL) begin
                                    result = operand_a << operand_b;
                                    result = result[31:0];
                                end
                            end
                        end
                    end

                end
            end
        end
        else begin
            //cnt = 0;
            if (state == S_MULTI_CYCLE_OP) begin
                if (inst == MUL) begin
                    //$display(cnt);
                    if (cnt == 1) begin
                        result = 0;
                        result = result + operand_b;
                    end

                    if (result[0]) begin
                        //$display(operand_a);
                        temp = operand_a << 32;
                        result = result + temp;
                        result = result >> 1;
                    end
                    else begin
                        result = result >> 1;
                    end
                    /*
                    if (cnt ==31) begin
                        $display(result);
                    end
                    */
                    //$display(result);
                end
                else begin
                    if (inst == DIV) begin
                        if (cnt == 1) begin
                            result = 0;
                            temp = operand_a << 1;
                            result = result + temp;
                        end

                        temp_for_divisor = operand_b << 32;
                        if (result >= temp_for_divisor) begin
                            result = result - temp_for_divisor;
                            //if(cnt == 31 && result[63] == 1) begin
                            result = result << 1;
                            result = result + 1;
                        end
                        else begin
                            result = result << 1;
                        end

                        if (cnt == 32) begin
                            //$display(result);
                            temp_last_step = result >> 32;//result[64:32];
                            temp = 64'b0;
                            if(result[64]) begin
                                temp = {1, 63'b0};
                            end
                            //$display(temp_last_step);
                            //$display(result[32]);
                            /*
                            if (!temp_last_step[0]) begin
                                temp_last_step = temp_last_step >> 1;
                            end
                            else begin
                                //$display(1);
                                temp_last_step = temp_last_step >> 1;
                                temp_last_step = {1, temp_last_step[30:0]};
                            end
                            */
                            temp_last_step = temp_last_step >> 1;
                            result = {temp_last_step, result[31:0]};
                            result = result + temp;
                            //$display(result);
                        end
                        //$display(cnt);
                        //$display(temp_last_step);
                        //$display(result);
                    end
                end
            end
        end
        //$display(result);
    end
    // Todo: output valid signal
    
    always @(posedge i_clk) begin
        if (state == S_ONE_CYCLE_OP || cnt == 32) begin
            //$display(result);
            ready <= 1;
            o_data_in = result;
        end
        else begin
            //pulldown(o_done);
            ready <= 0;
            o_data_in = 0;
        end
    end
    
    // Todo: Sequential always block
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state       <= S_IDLE;
            operand_a   <= 0;
            operand_b   <= 0;
            inst        <= 0;
            //result      <= 0;
        end
        else begin
            state       <= state_nxt;
            operand_a   <= operand_a_nxt;
            operand_b   <= operand_b_nxt;
            inst        <= inst_nxt;

        end
    end

endmodule