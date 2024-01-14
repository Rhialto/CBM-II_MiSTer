module rom_mem #(parameter DATAWIDTH, ADDRWIDTH, INITFILE=" ")
(
	input	                     clock_a,
	input	     [ADDRWIDTH-1:0] address_a,
	input	     [DATAWIDTH-1:0] data_a,
	input	                     wren_a,
	output reg [DATAWIDTH-1:0] q_a,

	input	                     clock_b,
	input	     [ADDRWIDTH-1:0] address_b,
	input	     [DATAWIDTH-1:0] data_b,
	input	                     wren_b,
	output reg [DATAWIDTH-1:0] q_b
);

(* ram_init_file = INITFILE *) reg [DATAWIDTH-1:0] ram[1<<ADDRWIDTH];

reg                 wren_a_d;
reg [ADDRWIDTH-1:0] address_a_d;
always @(posedge clock_a) begin
	wren_a_d    <= wren_a;
	address_a_d <= address_a;
end

always @(posedge clock_a) begin
	if(wren_a_d) begin
		ram[address_a_d] <= data_a;
		q_a <= data_a;
	end else begin
		q_a <= ram[address_a_d];
	end
end

reg                 wren_b_d;
reg [ADDRWIDTH-1:0] address_b_d;
always @(posedge clock_b) begin
	wren_b_d    <= wren_b;
	address_b_d <= address_b;
end

always @(posedge clock_b) begin
	if(wren_b_d) begin
		ram[address_b_d] <= data_b;
		q_b <= data_b;
	end else begin
		q_b <= ram[address_b_d];
	end
end

endmodule
