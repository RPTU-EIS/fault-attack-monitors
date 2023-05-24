module monitor #()(
    //enable signals (the driving processor signal is noted in the comments)
    input logic [1:0] priv_lvl_q,           //cs_registers_i.priv_lvl_q
    
    //invariant signals (the driving processor signals are noted in the comments)
    input logic [1:0] csr_op_ex,            //id_stage_i.csr_op_ex_o
    input logic[1:0] alu_operand_b_ex,      //id_stage_i.alu_operand_b_ex_o[9:8]
    
    //alarm signals
    output logic alarm
);

localparam NumInvariants = 1;

logic [NumInvariants - 1 : 0] invariant_logic;

logic [NumInvariants - 1 : 0] enable_logic;

assign enable_logic[0] = (
(priv_lvl_q == 2'b00) 
);

//invariant logic:
assign invariant_logic[0] = (
((csr_op_ex == 2'b00) || !(alu_operand_b_ex > priv_lvl_q) ) 
);

//alarm logic:
always_comb begin: raise_alarm
    logic no_alarm = 1'b1;
    for (int i = NumInvariants - 1; i >= 0; i--) begin
        no_alarm = no_alarm && (!enable_logic[i] || invariant_logic[i]);
    end
    alarm = !no_alarm;
end

endmodule
