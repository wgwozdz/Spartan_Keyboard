module char_mem (
	input clk,
	input rst,
	
	input read_ready,
	input [7:0] char_in,
	output reg read = 0,
	
   input  [4:0] char_addr,
	output reg [7:0] char_out
	);
	
	reg [7:0] mem [31:0];
	reg [4:0] write_addr = 0;
	reg [4:0] i = 0;

	always @ (posedge clk) begin
		char_out <= mem[char_addr];
		if (rst) begin
			mem[i] <= " ";
			i <= i + 1;
			read <= 0;
			write_addr <= 0;
		end else begin
			if (read && ~read_ready) begin
				read <= 0;
				mem[write_addr] <= char_in;
				write_addr <= write_addr + 1;
			end else if (read_ready) begin
				read <= 1;
			end
		end
	end
endmodule
