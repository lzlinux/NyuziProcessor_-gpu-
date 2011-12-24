
module pipeline
	#(parameter			CORE_ID = 30'd0)

	(input				clk,
	output [31:0]		iaddress_o,
	input [31:0]		idata_i,
	output				iaccess_o,
	input				icache_hit_i,
	output [31:0]		daddress_o,
	output				daccess_o,
	input				dcache_hit_i,
	input				dstbuf_full_i,
	output				dwrite_o,
	output [1:0]		dstrand_o,
	output [63:0]		dwrite_mask_o,
	output [511:0]		ddata_o,
	input [511:0]		ddata_i,
	input [3:0]			dcache_resume_strand_i,
	output				halt_o);
	
	wire[31:0]			if_instruction0;
	wire[31:0]			if_instruction1;
	wire[31:0]			if_instruction2;
	wire[31:0]			if_instruction3;
	wire				instruction_valid0;
	wire				instruction_valid1;
	wire				instruction_valid2;
	wire				instruction_valid3;
	wire				next_instruction0;
	wire				next_instruction1;
	wire				next_instruction2;
	wire				next_instruction3;
	wire[31:0]			if_pc0;
	wire[31:0]			if_pc1;
	wire[31:0]			if_pc2;
	wire[31:0]			if_pc3;
	wire[31:0]			ss_instruction;
	wire[31:0]			dc_instruction;
	wire[31:0]			ex_instruction;
	wire[31:0]			ma_instruction;
	wire[6:0]			scalar_sel1;
	wire[6:0]			scalar_sel2;
	wire[6:0]			vector_sel1;
	wire[6:0]			vector_sel2;
	wire[31:0]			scalar_value1;
	wire[31:0]			scalar_value2;
	wire[511:0]			vector_value1;
	wire[511:0]			vector_value2;
	wire[31:0]			immediate_value;
	wire[2:0]			mask_src;
	wire				op1_is_vector;
	wire[1:0]			op2_src;
	wire				store_value_is_vector;
	wire[511:0]			ex_store_value;
	wire				ds_has_writeback;
	wire[6:0]			ds_writeback_reg;
	wire				ds_writeback_is_vector;
	wire				ex_has_writeback;
	wire[6:0]			ex_writeback_reg;
	wire				ex_writeback_is_vector;
	wire				ma_has_writeback;
	wire[6:0]			ma_writeback_reg;
	wire				ma_writeback_is_vector;
	wire[6:0]			wb_writeback_reg;
	wire[511:0]			wb_writeback_value;
	wire[15:0]			wb_writeback_mask;
	wire				wb_writeback_is_vector;
	reg					rf_has_writeback = 0;
	reg[6:0]			rf_writeback_reg = 0;		// One cycle after writeback
	reg[511:0]			rf_writeback_value = 0;
	reg[15:0]			rf_writeback_mask = 0;
	reg					rf_writeback_is_vector = 0;
	wire[15:0]			ex_mask;
	wire[15:0]			ma_mask;
	wire[511:0]			ex_result;
	wire[511:0]			ma_result;
	wire[5:0]			alu_op;
	wire [3:0]			ss_reg_lane_select;
	wire [3:0]			ds_reg_lane_select;
	wire [3:0]			ex_reg_lane_select;
	wire [3:0]			ma_reg_lane_select;
	reg[6:0]			vector_sel1_l = 0;
	reg[6:0]			vector_sel2_l = 0;
	reg[6:0]			scalar_sel1_l = 0;
	reg[6:0]			scalar_sel2_l = 0;
	wire[31:0]			ss_pc;
	wire[31:0]			ds_pc;
	wire[31:0]			ex_pc;
	wire[31:0]			ma_pc;
	wire				ex_rollback_request;
	wire[31:0]			ex_rollback_address;
	wire				ma_rollback_request;
	wire				wb_rollback_request;
	wire[31:0]			wb_rollback_address;
	wire				flush_ss;
	wire				flush_ds;
	wire				flush_ex;
	wire				flush_ma;
	wire				rollback_strand0;
	wire[31:0]			rollback_address0;
	wire[31:0]			rollback_strided_offset0;
	wire[3:0]			rollback_reg_lane0;
	wire				rollback_strand1;
	wire[31:0]			rollback_address1;
	wire[31:0]			rollback_strided_offset1;
	wire[3:0]			rollback_reg_lane1;
	wire				rollback_strand2;
	wire[31:0]			rollback_address2;
	wire[31:0]			rollback_strided_offset2;
	wire[3:0]			rollback_reg_lane2;
	wire				rollback_strand3;
	wire[31:0]			rollback_address3;
	wire[31:0]			rollback_strided_offset3;
	wire[3:0]			rollback_reg_lane3;
	wire				wb_has_writeback;
	wire[3:0]			ex_cache_lane_select;
	wire[3:0]			ma_cache_lane_select;
	wire[31:0]			ss_strided_offset;
	wire[31:0]			ds_strided_offset;
	wire				ma_was_access;
	wire[31:0]			ma_rollback_address;
	wire[31:0]			ex_strided_offset;
	wire[1:0]			ss_strand_id;
	wire[1:0]			ds_strand_id;
	wire[1:0]			ex_strand_id;
	wire[1:0]			ma_strand_id;
	wire[1:0]			wb_strand_id;
	reg[1:0]			rf_strand_id = 0;
	
	instruction_fetch_stage ifs(
		.clk(clk),
		.iaddress_o(iaddress_o),
		.iaccess_o(iaccess_o),
		.idata_i(idata_i),
		.icache_hit_i(icache_hit_i),

		.instruction0_o(if_instruction0),
		.instruction_valid0_o(instruction_valid0),
		.rollback_strand0_i(rollback_strand0),
		.rollback_address0_i(rollback_address0),
		.next_instruction0_i(next_instruction0),
		.pc0_o(if_pc0),

		.instruction1_o(if_instruction1),
		.instruction_valid1_o(instruction_valid1),
		.rollback_strand1_i(rollback_strand1),
		.rollback_address1_i(rollback_address1),
		.next_instruction1_i(next_instruction1),
		.pc1_o(if_pc1),

		.instruction2_o(if_instruction2),
		.instruction_valid2_o(instruction_valid2),
		.rollback_strand2_i(rollback_strand2),
		.rollback_address2_i(rollback_address2),
		.next_instruction2_i(next_instruction2),
		.pc2_o(if_pc2),

		.instruction3_o(if_instruction3),
		.instruction_valid3_o(instruction_valid3),
		.rollback_strand3_i(rollback_strand3),
		.rollback_address3_i(rollback_address3),
		.next_instruction3_i(next_instruction3),
		.pc3_o(if_pc3));

	wire suspend_strand0 = ma_rollback_request && ex_strand_id == 0;
	wire suspend_strand1 = ma_rollback_request && ex_strand_id == 1;
	wire suspend_strand2 = ma_rollback_request && ex_strand_id == 2;
	wire suspend_strand3 = ma_rollback_request && ex_strand_id == 3;

	strand_select_stage ss(
		.clk(clk),

		.pc0_i(if_pc0),
		.instruction0_i(if_instruction0),
		.instruction_valid0_i(instruction_valid0),
		.flush0_i(rollback_strand0),
		.next_instruction0_o(next_instruction0),
		.suspend_strand0_i(suspend_strand0),
		.resume_strand0_i(dcache_resume_strand_i[0]),
		.rollback_strided_offset0_i(rollback_strided_offset0),
		.rollback_reg_lane0_i(rollback_reg_lane0),

		.pc1_i(if_pc1),
		.instruction1_i(if_instruction1),
		.instruction_valid1_i(instruction_valid1),
		.flush1_i(rollback_strand1),
		.next_instruction1_o(next_instruction1),
		.suspend_strand1_i(suspend_strand1),
		.resume_strand1_i(dcache_resume_strand_i[1]),
		.rollback_strided_offset1_i(rollback_strided_offset1),
		.rollback_reg_lane1_i(rollback_reg_lane1),

		.pc2_i(if_pc2),
		.instruction2_i(if_instruction2),
		.instruction_valid2_i(instruction_valid2),
		.flush2_i(rollback_strand2),
		.next_instruction2_o(next_instruction2),
		.suspend_strand2_i(suspend_strand2),
		.resume_strand2_i(dcache_resume_strand_i[2]),
		.rollback_strided_offset2_i(rollback_strided_offset2),
		.rollback_reg_lane2_i(rollback_reg_lane2),

		.pc3_i(if_pc3),
		.instruction3_i(if_instruction3),
		.instruction_valid3_i(instruction_valid3),
		.flush3_i(rollback_strand3),
		.next_instruction3_o(next_instruction3),
		.suspend_strand3_i(suspend_strand3),
		.resume_strand3_i(dcache_resume_strand_i[3]),	
		.rollback_strided_offset3_i(rollback_strided_offset3),
		.rollback_reg_lane3_i(rollback_reg_lane3),
		
		.pc_o(ss_pc),
		.instruction_o(ss_instruction),
		.reg_lane_select_o(ss_reg_lane_select),
		.strided_offset_o(ss_strided_offset),
		.strand_id_o(ss_strand_id));

	decode_stage ds(
		.clk(clk),
		.instruction_i(ss_instruction),
		.instruction_o(dc_instruction),
		.strand_id_i(ss_strand_id),
		.strand_id_o(ds_strand_id),
		.pc_i(ss_pc),
		.pc_o(ds_pc),
		.reg_lane_select_i(ss_reg_lane_select),
		.reg_lane_select_o(ds_reg_lane_select),
		.immediate_o(immediate_value),
		.mask_src_o(mask_src),
		.op1_is_vector_o(op1_is_vector),
		.op2_src_o(op2_src),
		.store_value_is_vector_o(store_value_is_vector),
		.scalar_sel1_o(scalar_sel1),
		.scalar_sel2_o(scalar_sel2),
		.vector_sel1_o(vector_sel1),
		.vector_sel2_o(vector_sel2),
		.has_writeback_o(ds_has_writeback),
		.writeback_reg_o(ds_writeback_reg),
		.writeback_is_vector_o(ds_writeback_is_vector),
		.alu_op_o(alu_op),
		.flush_i(flush_ds),
		.strided_offset_i(ss_strided_offset),
		.strided_offset_o(ds_strided_offset));

	wire enable_scalar_reg_store = wb_has_writeback && ~wb_writeback_is_vector;
	wire enable_vector_reg_store = wb_has_writeback && wb_writeback_is_vector;

	scalar_register_file srf(
		.clk(clk),
		.sel1_i(scalar_sel1),
		.sel2_i(scalar_sel2),
		.value1_o(scalar_value1),
		.value2_o(scalar_value2),
		.write_reg_i(wb_writeback_reg),
		.write_value_i(wb_writeback_value[31:0]),
		.write_enable_i(enable_scalar_reg_store));
	
	vector_register_file vrf(
		.clk(clk),
		.sel1_i(vector_sel1),
		.sel2_i(vector_sel2),
		.value1_o(vector_value1),
		.value2_o(vector_value2),
		.write_reg_i(wb_writeback_reg),
		.write_value_i(wb_writeback_value),
		.write_mask_i(wb_writeback_mask),
		.write_en_i(enable_vector_reg_store));
	
	always @(posedge clk)
	begin
		vector_sel1_l <= #1 vector_sel1;
		vector_sel2_l <= #1 vector_sel2;
		scalar_sel1_l <= #1 scalar_sel1;
		scalar_sel2_l <= #1 scalar_sel2;
	end
	
	execute_stage exs(
		.clk(clk),
		.instruction_i(dc_instruction),
		.instruction_o(ex_instruction),
		.strand_id_i(ds_strand_id),
		.strand_id_o(ex_strand_id),
		.flush_i(flush_ex),
		.pc_i(ds_pc),
		.pc_o(ex_pc),
		.reg_lane_select_i(ds_reg_lane_select),
		.reg_lane_select_o(ex_reg_lane_select),
		.mask_src_i(mask_src),
		.op1_is_vector_i(op1_is_vector),
		.op2_src_i(op2_src),
		.scalar_value1_i(scalar_value1),
		.scalar_value2_i(scalar_value2),
		.vector_value1_i(vector_value1),
		.vector_value2_i(vector_value2),
		.scalar_sel1_i(scalar_sel1_l),
		.scalar_sel2_i(scalar_sel2_l),
		.vector_sel1_i(vector_sel1_l),
		.vector_sel2_i(vector_sel2_l),
		.immediate_i(immediate_value),
		.store_value_is_vector_i(store_value_is_vector),
		.store_value_o(ex_store_value),
		.has_writeback_i(ds_has_writeback),
		.writeback_reg_i(ds_writeback_reg),
		.writeback_is_vector_i(ds_writeback_is_vector),
		.has_writeback_o(ex_has_writeback),
		.writeback_reg_o(ex_writeback_reg),
		.writeback_is_vector_o(ex_writeback_is_vector),
		.mask_o(ex_mask),
		.result_o(ex_result),
		.alu_op_i(alu_op),
		.daddress_o(daddress_o),
		.daccess_o(daccess_o),
		.dstrand_o(dstrand_o),
		.bypass1_register(ma_writeback_reg),	
		.bypass1_has_writeback(ma_has_writeback),
		.bypass1_is_vector(ma_writeback_is_vector),
		.bypass1_value(ma_result),
		.bypass1_mask(ma_mask),
		.bypass2_register(wb_writeback_reg),	
		.bypass2_has_writeback(wb_has_writeback),
		.bypass2_is_vector(wb_writeback_is_vector),
		.bypass2_value(wb_writeback_value),
		.bypass2_mask(wb_writeback_mask),
		.bypass3_register(rf_writeback_reg),	
		.bypass3_has_writeback(rf_has_writeback),
		.bypass3_is_vector(rf_writeback_is_vector),
		.bypass3_value(rf_writeback_value),
		.bypass3_mask(rf_writeback_mask),
		.rollback_request_o(ex_rollback_request),
		.rollback_address_o(ex_rollback_address),
		.cache_lane_select_o(ex_cache_lane_select),
		.strided_offset_i(ds_strided_offset),
		.strided_offset_o(ex_strided_offset),
		.was_access_o(ma_was_access));

	memory_access_stage #(CORE_ID) mas(
		.clk(clk),
		.instruction_i(ex_instruction),
		.instruction_o(ma_instruction),
		.strand_id_i(ex_strand_id),
		.strand_id_o(ma_strand_id),
		.flush_i(flush_ma),
		.pc_i(ex_pc),
		.reg_lane_select_i(ex_reg_lane_select),
		.reg_lane_select_o(ma_reg_lane_select),
		.ddata_o(ddata_o),
		.dwrite_o(dwrite_o),
		.write_mask_o(dwrite_mask_o),
		.store_value_i(ex_store_value),
		.has_writeback_i(ex_has_writeback),
		.writeback_reg_i(ex_writeback_reg),
		.writeback_is_vector_i(ex_writeback_is_vector),
		.has_writeback_o(ma_has_writeback),
		.writeback_reg_o(ma_writeback_reg),
		.writeback_is_vector_o(ma_writeback_is_vector),
		.mask_i(ex_mask),
		.mask_o(ma_mask),
		.result_i(ex_result),
		.result_o(ma_result),
		.cache_hit_i(dcache_hit_i),
		.dstbuf_full_i(dstbuf_full_i),
		.cache_lane_select_i(ex_cache_lane_select),
		.cache_lane_select_o(ma_cache_lane_select),
		.rollback_request_o(ma_rollback_request),
		.rollback_address_o(ma_rollback_address),
		.was_access_i(ma_was_access),
		.halt_o(halt_o));

	writeback_stage wbs(
		.clk(clk),
		.instruction_i(ma_instruction),
		.strand_id_i(ma_strand_id),
		.strand_id_o(wb_strand_id),
		.reg_lane_select_i(ma_reg_lane_select),
		.has_writeback_i(ma_has_writeback),
		.writeback_reg_i(ma_writeback_reg),
		.writeback_is_vector_i(ma_writeback_is_vector),
		.has_writeback_o(wb_has_writeback),
		.writeback_is_vector_o(wb_writeback_is_vector),
		.writeback_reg_o(wb_writeback_reg),
		.writeback_value_o(wb_writeback_value),
		.ddata_i(ddata_i),
		.result_i(ma_result),
		.mask_o(wb_writeback_mask),
		.mask_i(ma_mask),
		.cache_lane_select_i(ma_cache_lane_select),
		.rollback_request_o(wb_rollback_request),
		.rollback_address_o(wb_rollback_address));
	
	// Even though the results have already been committed to the
	// register file on this cycle, the new register values were
	// fetched a cycle before the bypass stage, so we may still
	// have stale results there.
	always @(posedge clk)
	begin
		rf_writeback_reg			<= #1 wb_writeback_reg;
		rf_writeback_value			<= #1 wb_writeback_value;
		rf_writeback_mask			<= #1 wb_writeback_mask;
		rf_writeback_is_vector		<= #1 wb_writeback_is_vector;
		rf_has_writeback			<= #1 wb_has_writeback;
		rf_strand_id				<= #1 wb_strand_id;
	end

	rollback_controller rbc(
		.clk(clk),

		// Rollback requests from other stages	
		.ds_strand_i(ss_strand_id),
		.ex_rollback_request_i(ex_rollback_request),
		.ex_rollback_address_i(ex_rollback_address),
		.ex_strand_i(ds_strand_id),
		.ma_rollback_request_i(ma_rollback_request),
		.ma_rollback_address_i(ma_rollback_address),
		.ma_rollback_strided_offset_i(ex_strided_offset),
		.ma_rollback_reg_lane_i(ex_reg_lane_select),
		.ma_strand_i(ex_strand_id), 
		.wb_rollback_request_i(wb_rollback_request),
		.wb_rollback_address_i(wb_rollback_address),
		.wb_strand_i(ma_strand_id),

		.flush_ds_o(flush_ds),
		.flush_ex_o(flush_ex),
		.flush_ma_o(flush_ma),

		.rollback_request_str0_o(rollback_strand0),
		.rollback_address_str0_o(rollback_address0),
		.rollback_strided_offset_str0_o(rollback_strided_offset0),
		.rollback_reg_lane_str0_o(rollback_reg_lane0),

		.rollback_request_str1_o(rollback_strand1),
		.rollback_address_str1_o(rollback_address1),
		.rollback_strided_offset_str1_o(rollback_strided_offset1),
		.rollback_reg_lane_str1_o(rollback_reg_lane1),

		.rollback_request_str2_o(rollback_strand2),
		.rollback_address_str2_o(rollback_address2),
		.rollback_strided_offset_str2_o(rollback_strided_offset2),
		.rollback_reg_lane_str2_o(rollback_reg_lane2),

		.rollback_request_str3_o(rollback_strand3),
		.rollback_address_str3_o(rollback_address3),
		.rollback_strided_offset_str3_o(rollback_strided_offset3),
		.rollback_reg_lane_str3_o(rollback_reg_lane3));
endmodule
