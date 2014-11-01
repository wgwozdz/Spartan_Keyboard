module char_buffer(
	input clk,
	input rst,
	input [7:0] char_in,
	input write,
	output reg read_ready,
	input read,
	output reg [7:0] char_out,
	output [7:0] led
	);
	
	// TODO: do this in software at some point.
	
	// Keyboard states
	reg shift_e = 0;
	
	// Select character based on shift state
	function [7:0] get_shifted_char;
		input [7:0] lowercase;
		input [7:0] uppercase;
		begin
			get_shifted_char = shift_e ? uppercase : lowercase;
		end
	endfunction
	
	// Based on the states of the keyboard, lookup ascii character
	function [7:0] lookup_normal;
		input [7:0] keycode;
		case(keycode)
			8'h1c: lookup_normal = get_shifted_char("a", "A");
			8'h32: lookup_normal = get_shifted_char("b", "B");
			8'h21: lookup_normal = get_shifted_char("c", "C");
			8'h23: lookup_normal = get_shifted_char("d", "D");
			8'h24: lookup_normal = get_shifted_char("e", "E");
			8'h2b: lookup_normal = get_shifted_char("f", "F");
			8'h34: lookup_normal = get_shifted_char("g", "G");
			8'h33: lookup_normal = get_shifted_char("h", "H");
			8'h43: lookup_normal = get_shifted_char("i", "I");
			8'h3b: lookup_normal = get_shifted_char("j", "J");
			8'h42: lookup_normal = get_shifted_char("k", "K");
			8'h4b: lookup_normal = get_shifted_char("l", "L");
			8'h3a: lookup_normal = get_shifted_char("m", "M");
			
			8'h31: lookup_normal = get_shifted_char("n", "N");
			8'h44: lookup_normal = get_shifted_char("o", "O");
			8'h4d: lookup_normal = get_shifted_char("p", "P");
			8'h15: lookup_normal = get_shifted_char("q", "Q");
			8'h2d: lookup_normal = get_shifted_char("r", "R");
			8'h1b: lookup_normal = get_shifted_char("s", "S");
			8'h2c: lookup_normal = get_shifted_char("t", "T");
			8'h3c: lookup_normal = get_shifted_char("u", "U");
			8'h2a: lookup_normal = get_shifted_char("v", "V");
			8'h1d: lookup_normal = get_shifted_char("w", "W");
			8'h22: lookup_normal = get_shifted_char("x", "X");
			8'h35: lookup_normal = get_shifted_char("y", "Y");
			8'h1a: lookup_normal = get_shifted_char("z", "Z");
			
			8'h45: lookup_normal = get_shifted_char("0", ")");
			8'h16: lookup_normal = get_shifted_char("1", "!");
			8'h1e: lookup_normal = get_shifted_char("2", "@");
			8'h26: lookup_normal = get_shifted_char("3", "#");
			8'h25: lookup_normal = get_shifted_char("4", "$");
			8'h2e: lookup_normal = get_shifted_char("5", "%");
			8'h36: lookup_normal = get_shifted_char("6", "^");
			8'h3d: lookup_normal = get_shifted_char("7", "&");
			8'h3e: lookup_normal = get_shifted_char("8", "*");
			8'h46: lookup_normal = get_shifted_char("9", "(");
			
			8'h0e: lookup_normal = get_shifted_char("`", "~");
			8'h4e: lookup_normal = get_shifted_char("-", "_");
			8'h55: lookup_normal = get_shifted_char("=", "+");
			8'h5d: lookup_normal = get_shifted_char("\\", "|");
			8'h29: lookup_normal = " ";
			
			8'h54: lookup_normal = get_shifted_char("[", "{");
			8'h5b: lookup_normal = get_shifted_char("]", "}");
			8'h4c: lookup_normal = get_shifted_char(";", ":");
			8'h52: lookup_normal = get_shifted_char("'", "\"");
			8'h41: lookup_normal = get_shifted_char(",", "<");
			8'h49: lookup_normal = get_shifted_char(".", ">");
			8'h4a: lookup_normal = get_shifted_char("/", "?");
			
			8'hfa: lookup_normal = 8'b11111101;
			8'haa: lookup_normal = 8'b11111101;
			
			default: lookup_normal = "-";
		endcase
	endfunction
	
	//Special signals
	localparam KEY_BREAK = 8'hf0,
	           KEY_SUPER = 8'he0;
	
	// Memory
	reg [7:0] write_addr = 0;
	reg [7:0] read_addr = 0;
	reg [7:0] buffer [255:0];
	
	// FMA states
	reg state_error = 0;
	localparam NORMAL      = 2'b00,
	           BREAK       = 2'b01,
				  SUPER       = 2'b10,
				  SUPER_BREAK = 2'b11;
	reg [1:0]  write_state = NORMAL;
	
	//Leds for asdfasdf
	assign led[7] = shift_e;
	assign led[1:0] = write_state;
	assign led[6] = read_ready;
	assign led[5] = write;
	assign led[4] = read_ready;
	assign led[3] = state_error;

	always @ (posedge clk) begin
		if (rst) begin
			write_state <= NORMAL;
			write_addr <= 0;
			read_addr <= 0;
		end else begin
		
			// Handle reading
			if (read && read_ready) begin // Undefined behavior if you read while not ready. Read only high for one cycle.
				char_out <= buffer[read_addr];
				read_addr <= read_addr + 1;
				read_ready <= 0; //Ensure consumers wait a cycle before getting next char.
			end else begin
				read_ready <= write_addr != read_addr; //char_out is ready the cycle after read_ready goes high.
			end
			
			// Handle writing.
			if (write) begin
				case (write_state)
					NORMAL: case (char_in)
								KEY_BREAK: write_state <= BREAK;
								KEY_SUPER: write_state <= SUPER;
								8'h12: shift_e <= 1;
								default: begin
									write_state <= NORMAL; // So I don't get confused.
									buffer[write_addr] <= lookup_normal(char_in);
									write_addr <= write_addr + 1;
								end
							endcase
					BREAK: case (char_in)
								KEY_BREAK: state_error <= 1;
								KEY_SUPER: state_error <= 1;
								8'h12: begin
									shift_e <= 0;
									write_state <= NORMAL;
								end
								default: write_state <= NORMAL;
							endcase
					SUPER: case (char_in)
								KEY_BREAK: write_state <= SUPER_BREAK;
								KEY_SUPER: state_error <= 1;
								default: write_state <= NORMAL;
							endcase
					SUPER_BREAK: case (char_in)
								KEY_BREAK: state_error <= 1;
								KEY_SUPER: state_error <= 1;
								default: write_state <= NORMAL;
						endcase
				endcase
			end
		end
	end
endmodule
