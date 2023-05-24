module monitor #()(
    //parameters
    input logic[31:0] secret_addr,
    
    //enable signal (the driving processor signal is noted in the comments)
    logic [1:0] priv_lvl                //cs_registers_i.priv_lvl_q
    
    //invariant signals (the driving processor signals are noted in the comments)
    input logic [2:0] ctrl_fsm_cs,      //id_stage_i.controller_i.ctrl_fsm_cs
    input logic [31 : 0] data_addr_o,   //data_addr_o
    input logic data_req_o,             //data_req_o

    //alarm signal
    output logic alarm
);

localparam NumInvariants = 2;

logic [NumInvariants - 1 : 0] invariant_logic;

logic [NumInvariants - 1 : 0] enable_logic;

//enable logic:
assign enable_logic[0] = (
priv_lvl == 2'b00
);
assign enable_logic[1] = (
priv_lvl == 2'b00
);

//invariant logic:
assign invariant_logic[0] = (
ctrl_fsm_cs != 3'b001
);

assign invariant_logic[1] = (
!(data_req_o && (data_addr_o == secret_addr))
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
