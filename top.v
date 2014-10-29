module top(
	input clk,
	inout ps2_clk,
	inout ps2_data,
	output lcd_rs,
	output lcd_rw,
	output lcd_e, 
	output [11:8] sf_d,
	output [7:0] led,
	input [0:0] sw,
	input btn_south
	);

	wire [7:0] char_mem_bus;
	wire [4:0] char_mem_addr;
	wire [7:0] raw_char;
	wire [7:0] proc_char;
	wire char_write, char_aval, char_read;
	assign keyboard_rst = sw[0];
	assign rst = btn_south;
	
	PS2_Demo keyboard_initalizer (
		.clk(clk),
		.rst(keyboard_rst),
		.ps2_data(ps2_data),
		.ps2_clk(ps2_clk),
		.char_out(raw_char),
		.char_recv(char_write)
	);
	
	char_buffer char_buffer (
		.clk(clk),
		.rst(rst),
		.char_in(raw_char),
		.write(char_write),
		.read_ready(char_aval),
		.read(char_read),
		.char_out(proc_char),
		.led(led)
	);
	
	char_mem char_mem (
		.clk(clk),
		.rst(rst),
		.char_addr(char_mem_addr),
		.char_out(char_mem_bus),
		.read_ready(char_aval),
		.read(char_read),
		.char_in(proc_char)
	);
	
	lcd lcd (
		.clk(clk),
		.lcd_rs(lcd_rs),
		.lcd_rw(lcd_rw),
		.lcd_e(lcd_e),
		.lcd_d(sf_d),
		.mem_addr(char_mem_addr),
		.mem_bus(char_mem_bus)
	);
endmodule
