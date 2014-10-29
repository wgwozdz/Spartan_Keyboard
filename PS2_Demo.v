// For now takes care of initializing keyboard.
module PS2_Demo (
	// Inputs
	clk,
	rst,

	// Bidirectionals
	ps2_clk,
	ps2_data,
	
	char_out,
	char_recv
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				clk;
input rst;

// Bidirectionals
inout				ps2_clk;
inout				ps2_data;

// Outputs
output [7:0] char_out;
output char_recv;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

wire busy, cmd_complete;
wire [7:0] cmd_result;

// Internal Registers
reg [7:0] command;
reg [7:0] command_data;
reg send_command;
// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/
reg [3:0] state = 0;

always @(posedge clk)
	if (rst) begin
	end else begin
		begin
			case (state)
			0: 
				if (~busy)
					state <= 1;
			1: 
				begin
					command_data <= 8'b0;
					command <= 8'hf4;
					send_command <= 1;
					state <= 2;
				end
			2: 
				if (busy) begin
					send_command <= 0;
					state <= 3;
				end
			3: 
				if (cmd_complete) begin
					state <= 4;
				end
			endcase
		end
	end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

keyboard_controller PS2 (
	// Inputs
	.clk				(clk),
	.rst (rst),

	// Command stuff
	.cmd(command),
	.cmd_data(command_data),
	.cmd_exec(send_command),
	.cmd_result(cmd_result),
	.cmd_complete(cmd_complete),
	.busy(busy),

	// Bidirectionals
	.ps2_clk			(ps2_clk),
 	.ps2_data		(ps2_data),

	// Outputs
	.char_out		(char_out),
	.char_recv	(char_recv)
);


endmodule
