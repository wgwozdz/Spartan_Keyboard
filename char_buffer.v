module char_buffer(
	input clk,
	input rst,
	input [7:0] char_in,
	input write,
	output read_ready,
	input read,
	output reg [7:0] char_out,
	output [7:0] led
	);
	
	// TODO: keep a list of which characters are currently pressed?
	
	//Special signals
	localparam SIG_BREAK = 8'h0f,
	           SIG_SUPER = 8'h0e;
	
	// FMA states
	localparam STATE_NORM  = 2'b00,
	           STATE_BREAK = 2'b01,
				  STATE_SUPER = 2'b10;
	reg [1:0]  write_state = STATE_NORM;

	// Memory addressing
	reg [7:0] write_addr = 0;
	reg [7:0] read_addr = 0;
	reg [7:0] buffer [255:0];
	
	// Keyboard states
	reg shift_e = 0;
	function get_char;
		input [7:0] uppercase;
		input [7:0] lowercase;
		begin
			get_char = shift_e ? uppercase : lowercase;
		end
	endfunction
	
	task write_char;
		input [7:0] char;
		begin
			buffer[write_addr] <= char;
			write_addr <= write_addr + 1;
		end
	endtask
	
	assign read_ready = write_addr != read_addr;

	//Leds for asdfasdf
	assign led[7] = shift_e;
	assign led[1:0] = write_state;
	assign led[6] = read_ready;
	assign led[5] = write;
	assign led[4] = read_ready;
	reg [3:2] asdf;
	assign led[3:2] = asdf;
	always @ (posedge clk) begin
		if (write)
			asdf = char_in[7:6];
	end

	always @ (posedge clk) begin
		if (rst) begin
			write_state <= STATE_NORM;
			write_addr <= 0;
			read_addr <= 0;
		end else begin
		
			// Handle reading
			if (read) begin // Undefined behavior if you read while not ready. Read only high for one cycle.
				char_out <= buffer[read_addr];
				read_addr <= read_addr + 1;
			end
			
			// Handle writing.
			if (write) begin
				buffer[write_addr] <= "A";
				write_addr <= write_addr + 1;
				/*case (write_state)
					STATE_NORM: begin
						case(char_in)
							SIG_BREAK: write_state <= STATE_BREAK;
							SIG_SUPER: write_state <= STATE_SUPER;
							8'h12: shift_e <= 1;
							default:  begin
										buffer[write_addr] <= get_char("A", "a");
										write_addr <= write_addr + 1;
									end
							8'haa: begin
									end
						endcase
					end
					STATE_BREAK: begin
						case(char_in)
							SIG_BREAK: write_state <= STATE_BREAK;
							default: write_state <= STATE_NORM;
							8'h12: shift_e <= 0;
						endcase
					end
					STATE_SUPER: begin
						case(char_in)
							SIG_BREAK: write_state <= STATE_BREAK;
							SIG_SUPER: write_state <= STATE_SUPER;
							default: write_state <= STATE_NORM;
						endcase
					end
				endcase */
			end
		end
	end
endmodule
