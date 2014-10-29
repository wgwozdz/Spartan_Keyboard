module keyboard_controller(
	input clk,
	input rst,
	input [7:0] cmd,
	input [7:0] cmd_data,
	input cmd_exec,
	output reg [7:0] cmd_result,
	output reg cmd_complete,
	output wire busy,
	
	inout ps2_clk,
	inout ps2_data,
	
	output reg [7:0] char_out,
	output reg char_recv
	);

	wire [7:0] data_out;
	wire data_recv;

	reg [7:0] the_command;
	reg send_command;
	wire command_error;

	// Commands to send
	localparam set_status       = 8'hed,
	           echo             = 8'hee,
				  set_scan_code    = 8'hf0,
				  set_repeat       = 8'hf3,
				  keyboard_enable  = 8'hf4,
				  keyboard_disable = 8'hf5,
				  resend           = 8'hfe,
				  reset            = 8'hff;
				  
	// Responses
	localparam acknowledge   = 8'hfa,
	           self_test_pass = 8'haa,
				  echo_reponse   = 8'hee,
				  resend_request = 8'hfe,
				  error1         = 8'h00,
				  error2         = 8'hff;

	// States
	localparam waiting_test_result = 2'b00,  // waiting for self test result.
				  waiting_ack_data_result    = 2'b01,  // waiting for ack, then send command data.
				  waiting_result      = 2'b10,  // waiting for data/ack response
				  ready               = 2'b11;  // forward keycodes
	reg [1:0] state = waiting_test_result;
	assign busy = (state == ready);

	always @ (posedge clk) begin
		if (rst) begin
		end else begin
		case (state)
			waiting_test_result: begin
				if (data_recv && data_out == self_test_pass) begin
					state <= ready;
				end
			end
			
			waiting_ack_data_result: begin
				if ((command_error) || (data_recv && (data_out == resend || data_out == error1 || data_out == error2))) begin
					send_command <= 1;
				end else if (data_recv && data_out == acknowledge) begin
					state <= waiting_result;
					the_command <= cmd_data;
					send_command <= 1;
				end else begin
					send_command <= 0;
					char_out <= data_out;
					char_recv <= data_recv;
				end
			end
			
			waiting_result: begin
				if ((command_error) || (data_recv && (data_out == resend || data_out == error1 || data_out == error2))) begin
					send_command <= 1;
				end else if (data_recv) begin
					state <= ready;
					cmd_result <= data_out;
					cmd_complete <= 1;
					send_command <= 0;
				end else begin
					send_command <= 0;
				end
			end
			
			ready: begin
				if (cmd_exec) begin
					the_command <= cmd;
					send_command <= 1;
					case (cmd) 
						set_status: state <= waiting_ack_data_result;
						echo: state <= waiting_result;
						set_scan_code: state <= waiting_ack_data_result;
						set_repeat: state <= waiting_ack_data_result;
						keyboard_enable: state <= waiting_result;
						keyboard_disable: state <= waiting_result;
						resend: state <= waiting_result;
						reset: state <= waiting_result;
					endcase
				end else begin
					send_command <= 0;
					cmd_complete <= 0;
				end
				char_out <= data_out;
				char_recv <= data_recv;
			end
		endcase
		end
	end
	
PS2_Controller PS2 (
	// Inputs
	.CLOCK_50				(clk),
	.reset(rst),
	// Bidirectionals
	.PS2_CLK			(ps2_clk),
 	.PS2_DAT			(ps2_data),
	
	.the_command(the_command),
	.send_command(send_command),

	.error_communication_timed_out(command_error),

	// Outputs
	.received_data		(data_out),
	.received_data_en	(data_recv)
);
endmodule
