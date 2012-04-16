
module scalar_register_file(
	input 					clk,
	input [6:0] 			scalar_sel1,
	input [6:0] 			scalar_sel2,
	output reg[31:0] 		scalar_value1 = 0,
	output reg[31:0] 		scalar_value2 = 0,
	input [6:0] 			wb_writeback_reg,
	input [31:0] 			wb_writeback_value,
	input 					enable_scalar_reg_store);

	localparam NUM_REGISTERS = 4 * 32; // 32 registers per strand * 4 strands

	reg[31:0]				registers[0:NUM_REGISTERS - 1];	
	integer					i;
	
	initial
	begin
		// synthesis translate_off
		for (i = 0; i < NUM_REGISTERS; i = i + 1)
			registers[i] = 0;

		// synthesis translate_on
	end
	
	always @(posedge clk)
	begin
		scalar_value1 <= #1 registers[scalar_sel1];
		scalar_value2 <= #1 registers[scalar_sel2];
		if (enable_scalar_reg_store)
			registers[wb_writeback_reg] <= #1 wb_writeback_value;
	end
	
endmodule
