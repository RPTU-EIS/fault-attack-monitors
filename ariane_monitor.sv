import ariane_pkg::*;

module monitor #()(
    //parameters
    input logic [31:0] secret_addr,
    input logic [19:0] secret_address_tag,

    //enable signals (the driving processor signals are noted in the comments)
    input logic [1:0] priv_lvl,                                           //csr_regfile_i.priv_lvl_q
    input logic debug_mode,                                               //csr_regfile_i.debug_mode_q

    //invariant signals (the driving processor signals are noted in the comments)
    input logic [31:0] addr_reg_1                                         //addr_reg_1[31:0]
    input logic mtvec_rst_load,                                           //csr_regfile_i.mtvec_rst_load_q
    input logic [7:0] scoreboard_mem_issued,                              //issue_stage_i.i_scoreboard.mem_q
    input ariane_pkg::scoreboard_entry_t [7:0] scoreboard_mem_sbe,        //issue_stage_i.i_scoreboard.mem_q[2].sbe
    input scoreboard_entry_t decoded_instr,                               //issue_stage_i.decoded_instr_i.op
    input scoreboard_entry_t instruction,                                 //id_stage_i.decoder_i.instruction_o.op
    input logic [7:0][19:0] commit_queue,                                 //ex_stage_i.lsu_i.i_store_unit.store_buffer_i.commit_queue[7-0].address[31:12]
    input logic [23:0] lsu_paddr,                                         //ex_stage_i.lsu_i.i_mmu.lsu_paddr_o[35:12]
    input logic [3:0] lsu_load_state,                                     //ex_stage_i.lsu_i.i_load_unit.state_q
    input logic [19:0] ptw_pptr,                                          //ex_stage_i.lsu_i.i_mmu.i_ptw.ptw_pptr_q[31:12]
    input logic [19:0] store_amo_mem,                                     //ex_stage_i.lsu_i.i_store_unit.i_amo_buffer.i_amo_fifo.mem_q[0].paddr[31:12]
		input logic [3:0][19:0] speculative_queue_addr,                       //ex_stage_i.lsu_i.i_store_unit.store_buffer_i.speculative_queue_q[0].address[31:12]
    input logic [2:0][19:0] mem_req_tag,                                  //i_cache_subsystem.i_nbdcache.master_ports[2-0].i_cache_ctrl.mem_req_q.tag[19:0]
    input logic [2:0][3:0] icache_ctrl_state,                             //i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.state_q
    input logic [DCACHE_SET_ASSOC-1:0] cache_ctrl_hit_way,                //i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.hit_way_i
    input logic [2:0][3:0] icache_ctrl_previous_state,                    //i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.state_d
    input logic [19:0] icache_miss_bypass_req_addr,                       //i_cache_subsystem.i_nbdcache.i_miss_handler.i_bypass_arbiter.req_q.address[31:12]
    input logic [19:0] icache_miss_mshr_addr,                             //i_cache_subsystem.i_nbdcache.i_miss_handler.mshr_q.addr[31:12]
    input logic [2:0] icache_stream_arbiter_inp_ready,                    //i_cache_subsystem.i_stream_arbiter_ar.inp_ready_o[0]
    input logic [31:0] icache_stream_oup_data,                            //i_cache_subsystem.i_stream_arbiter_ar.oup_data_o
    input logic [2:0][31:0] icache_stream_inp_data,                       //i_cache_subsystem.i_stream_arbiter_ar.inp_data_i
    input logic [2:0] icache_stream_inp_valid,                            //i_cache_subsystem.i_stream_arbiter_ar.inp_valid_i[0-2]
    input logic icache_stream_oup_valid,                                  //i_cache_subsystem.i_stream_arbiter_ar.oup_valid_o
    input logic [19:0] icache_tag_out,                                    //i_cache_subsystem.i_icache.tag_q[19:0]
    input logic axi2rom_req,                                              //i_axi2rom_1.req_o
    input logic [19:0] axi2rom_addr,                                      //i_axi2rom_1.addr_o[31:12]
    input logic [19:0] axi2rom_ax_req_d_addr,                             //i_axi2rom_1.ax_req_d.addr[31:12]
    input logic [19:0] axi2rom_ax_req_q_addr,                             //i_axi2rom_1.ax_req_q.addr[31:12]
    input logic [2:0] axi2rom_state,                                      //i_axi2rom_1.state_q
    input logic [19:0] axi2rom_req_addr,                                  //i_axi2rom_1.req_addr_q[31:12]

    //alarm signal
    output logic alarm
);

localparam NumInvariants = 11;

logic [NumInvariants - 1 : 0] invariant_logic;

logic [NumInvariants - 1 : 0] enable_logic;

//enable logic:
assign enable_logic[0] = (
(priv_lvl == 2'b00) && (debug_mod == 0)
);
assign enable_logic[1] = (
(priv_lvl == 2'b00) && (debug_mode == 0)
);
assign enable_logic[2] = 1;
assign enable_logic[3] = 1;
assign enable_logic[4] = 1;
assign enable_logic[5] = 1;
assign enable_logic[6] = 1;
assign enable_logic[7] = 1;
assign enable_logic[8] = 1;
assign enable_logic[9] = 1;
assign enable_logic[10] = 1;


//invariant logic:
assign invariant_logic[0] = mtvec_rst_load == 0;

assign invariant_logic[1] = (
    ( ((instruction.op != ariane_pkg::DRET) || (instruction.ex.valid)) )&&
    ( ((decoded_instr.op != ariane_pkg::DRET) || (decoded_instr.ex.valid)) )&&
    ( (((scoreboard_mem_sbe[0].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[0].ex.valid)) || !scoreboard_mem_issued[0] && !scoreboard_mem_sbe[0].valid) )&&
    ( (((scoreboard_mem_sbe[1].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[1].ex.valid)) || !scoreboard_mem_issued[1] && !scoreboard_mem_sbe[1].valid) )&&
    ( (((scoreboard_mem_sbe[2].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[2].ex.valid)) || !scoreboard_mem_issued[2] && !scoreboard_mem_sbe[2].valid) )&&
    ( (((scoreboard_mem_sbe[3].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[3].ex.valid)) || !scoreboard_mem_issued[3] && !scoreboard_mem_sbe[3].valid) )&&
    ( (((scoreboard_mem_sbe[4].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[4].ex.valid)) || !scoreboard_mem_issued[4] && !scoreboard_mem_sbe[4].valid) )&&
    ( (((scoreboard_mem_sbe[5].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[5].ex.valid)) || !scoreboard_mem_issued[5] && !scoreboard_mem_sbe[5].valid) )&&
    ( (((scoreboard_mem_sbe[6].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[6].ex.valid)) || !scoreboard_mem_issued[6] && !scoreboard_mem_sbe[6].valid) )&&
    ( (((scoreboard_mem_sbe[7].op != ariane_pkg::DRET) || (scoreboard_mem_sbe[7].ex.valid)) || !scoreboard_mem_issued[7] && !scoreboard_mem_sbe[7].valid) )&&
    ( ((instruction.op != ariane_pkg::MRET) || (instruction.ex.valid)) )&&
    ( ((decoded_instr.op != ariane_pkg::MRET) || (decoded_instr.ex.valid)) )&&
    ( (((scoreboard_mem_sbe[0].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[0].ex.valid)) || !scoreboard_mem_issued[0] && !scoreboard_mem_sbe[0].valid) )&&
    ( (((scoreboard_mem_sbe[1].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[1].ex.valid)) || !scoreboard_mem_issued[1] && !scoreboard_mem_sbe[1].valid) )&&
    ( (((scoreboard_mem_sbe[2].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[2].ex.valid)) || !scoreboard_mem_issued[2] && !scoreboard_mem_sbe[2].valid) )&&
    ( (((scoreboard_mem_sbe[3].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[3].ex.valid)) || !scoreboard_mem_issued[3] && !scoreboard_mem_sbe[3].valid) )&&
    ( (((scoreboard_mem_sbe[4].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[4].ex.valid)) || !scoreboard_mem_issued[4] && !scoreboard_mem_sbe[4].valid) )&&
    ( (((scoreboard_mem_sbe[5].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[5].ex.valid)) || !scoreboard_mem_issued[5] && !scoreboard_mem_sbe[5].valid) )&&
    ( (((scoreboard_mem_sbe[6].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[6].ex.valid)) || !scoreboard_mem_issued[6] && !scoreboard_mem_sbe[6].valid) )&&
    ( (((scoreboard_mem_sbe[7].op != ariane_pkg::MRET) || (scoreboard_mem_sbe[7].ex.valid)) || !scoreboard_mem_issued[7] && !scoreboard_mem_sbe[7].valid) )&&
    ( ((instruction.op != ariane_pkg::SRET) || (instruction.ex.valid)) )&&
    ( ((decoded_instr.op != ariane_pkg::SRET) || (decoded_instr.ex.valid)) )&&
    ( (((scoreboard_mem_sbe[0].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[0].ex.valid)) || !scoreboard_mem_issued[0] && !scoreboard_mem_sbe[0].valid) )&&
    ( (((scoreboard_mem_sbe[1].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[1].ex.valid)) || !scoreboard_mem_issued[1] && !scoreboard_mem_sbe[1].valid) )&&
    ( (((scoreboard_mem_sbe[2].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[2].ex.valid)) || !scoreboard_mem_issued[2] && !scoreboard_mem_sbe[2].valid) )&&
    ( (((scoreboard_mem_sbe[3].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[3].ex.valid)) || !scoreboard_mem_issued[3] && !scoreboard_mem_sbe[3].valid) )&&
    ( (((scoreboard_mem_sbe[4].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[4].ex.valid)) || !scoreboard_mem_issued[4] && !scoreboard_mem_sbe[4].valid) )&&
    ( (((scoreboard_mem_sbe[5].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[5].ex.valid)) || !scoreboard_mem_issued[5] && !scoreboard_mem_sbe[5].valid) )&&
    ( (((scoreboard_mem_sbe[6].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[6].ex.valid)) || !scoreboard_mem_issued[6] && !scoreboard_mem_sbe[6].valid) )&&
    ( (((scoreboard_mem_sbe[7].op != ariane_pkg::SRET) || (scoreboard_mem_sbe[7].ex.valid)) || !scoreboard_mem_issued[7] && !scoreboard_mem_sbe[7].valid) )
);

assign invariant_logic[2] = (
  ((icache_ctrl_state[1] == 4'b0010) || (icache_ctrl_state[1] == 4'b0001)) ->
  (lsu_load_state == 4'b0010 || lsu_load_state == 4'b0100 || lsu_load_state == 4'b0101)
);

assign invariant_logic[3] = (
  (icache_ctrl_state[1] != 4'b0110) || (cache_ctrl_hit_way != 8'b0)
);

assign invariant_logic[4] = (
  (icache_ctrl_state[1] == 4'b0110) ->
  (icache_ctrl_previous_state[1] != 4'b0101 && icache_ctrl_previous_state[1] != 4'b0111)
);

assign invariant_logic[5] = (
  (icache_stream_arbiter_inp_ready[0] && icache_stream_oup_data == icache_stream_inp_data[0]) ->
  (icache_stream_oup_valid == icache_stream_inp_valid[0])
);

assign invariant_logic[6] = (
  (icache_stream_arbiter_inp_ready[1] && icache_stream_oup_data == icache_stream_inp_data[1]) ->
  (icache_stream_oup_valid == icache_stream_inp_valid[1])
);

assign invariant_logic[7] = (
  (icache_stream_arbiter_inp_ready[2] && icache_stream_oup_data == icache_stream_inp_data[2]) ->
  (icache_stream_oup_valid == icache_stream_inp_valid[2])
);

assign invariant_logic[8] = (
  ptw_pptr != secret_address_tag
);

assign invariant_logic[9] = (
  axi2rom_req ? (axi2rom_addr == axi2rom_ax_req_d_addr) : 1'b1
);

assign invariant_logic[10] = (
  ( addr_reg_1 != secret_addr) &&
  ( axi2rom_ax_req_q_addr != secret_address_tag || axi2rom_state != 3'b001) &&
  ( axi2rom_req_addr != secret_address_tag || axi2rom_state != 3'b001) &&
  ( icache_miss_bypass_req_addr != secret_address_tag) &&
  ( mem_req_tag[0] != secret_address_tag) &&
  ( mem_req_tag[1] != secret_address_tag || ( icache_ctrl_state[1] < 4'b0011)) &&
  ( mem_req_tag[2] != secret_address_tag) &&
  ( icache_miss_mshr_addr != secret_address_tag) &&
  ( icache_tag_out != secret_address_tag) &&
  ( store_amo_mem != secret_address_tag) &&

  ( commit_queue[0] != secret_address_tag) &&
  ( commit_queue[1] != secret_address_tag) &&
  ( commit_queue[2] != secret_address_tag) &&
  ( commit_queue[3] != secret_address_tag) &&
  ( commit_queue[4] != secret_address_tag) &&
  ( commit_queue[5] != secret_address_tag) &&
  ( commit_queue[6] != secret_address_tag) &&
  ( commit_queue[7] != secret_address_tag) &&

  ( speculative_queue_addr[0] != secret_address_tag) &&
  ( speculative_queue_addr[1] != secret_address_tag) &&
  ( speculative_queue_addr[2] != secret_address_tag) &&
  ( speculative_queue_addr[3] != secret_address_tag)
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
