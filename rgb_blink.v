
module rgb_blink(
	input clock,
	output LED_R,LED_G,LED_B);

reg [31:0] counter=0;

always@(posedge clock)
   counter <= counter +1;

assign {LED_R,LED_G,LED_B}=counter[31:29];

endmodule
