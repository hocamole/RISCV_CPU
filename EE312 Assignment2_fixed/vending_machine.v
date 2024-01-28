`include "vending_machine_def.v"
`timescale 100ps / 100ps

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin,				// Sign of the coin return
	stopwatch,
	current_total,
	return_temp,
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kNumCoins-1:0] o_return_coin;

	output [3:0] stopwatch;
	output [`kTotalBits-1:0] current_total;
	output [`kTotalBits-1:0] return_temp;
	// Normally, every output is register,
	//   so that it can provide stable value to the outside.

//////////////////////////////////////////////////////////////////////	/

	//we have to return many coins
	reg [`kCoinBits-1:0] returning_coin_0;
	reg [`kCoinBits-1:0] returning_coin_1;
	reg [`kCoinBits-1:0] returning_coin_2;
	reg block_item_0;
	reg block_item_1;
	//check timeout
	reg [3:0] stopwatch;
	//when return triggered
	reg have_to_return;
	reg  [`kTotalBits-1:0] return_temp;
	reg [`kTotalBits-1:0] temp;
////////////////////////////////////////////////////////////////////////

	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpate to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;


	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k,l,m,n;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0];
	reg return_finished;
	reg maintain_trigger_return;
	reg [`kTotalBits-1:0] lack_coin_test [`kNumItems-1:0];

	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;
	reg [`kItemBits-1:0] num_items_nxt [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins_nxt [`kNumCoins-1:0];

	// Variables. You may add more your own registers.
	reg [`kTotalBits-1:0] input_total, output_total, return_total_0,return_total_1,return_total_2;


	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		if (i_input_coin) begin
			//$display("left 100: %d", num_coins[0]);
			stopwatch = `kWaitTime;
			return_finished = 0;
			for (i=0; i<4; i=i+1) begin
				if (i_input_coin[i]) begin
					num_coins_nxt[i] = num_coins[i] + 1;
					current_total_nxt = current_total + kkCoinValue[i];
				end
			end
			#100;
		end

		if (i_select_item) begin
			stopwatch = kWaitTime;
			for (i=0; i<5; i=i+1) begin
				if((i_select_item[i]==1) && (num_items[i]>0) && (current_total>kkItemPrice[i])) begin
					num_items_nxt[i] = num_items[i] - 1;
					current_total_nxt = current_total - kkItemPrice[i];
					o_output_item[i] = 1; //*****
				end
				else o_output_item[i] = 0;
			end
			#100;
		end
	end


	// Combinational logic for the outputs
	always @(*) begin
	// TODO: o_available_item
		for (i=0; i<4; i=i+1) begin
			lack_coin_test[i] = current_total - kkItemPrice[i]; //suppose that item i is bought
			if ((current_total>=kkItemPrice[i]) && (num_items[i]>0)) begin
				//test potential lack of coin to prepare for return
				for (k=0; k<3; k=k+1) begin
					if ((lack_coin_test[i]/kkCoinValue[2-k])>=num_coins[2-k]) lack_coin_test[i] = lack_coin_test[i] - kkCoinValue[2-k]*num_coins[2-k];
					else lack_coin_test[i] = lack_coin_test[i] % kkCoinValue[2-k];
				end
				if (lack_coin_test[i]==0) o_available_item[i]=1;
				else o_available_item[i]=0;
			end
			else o_available_item[i]=0;
		end

	// TODO: o_output_item

	end

	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (reset_n==0) begin
			// TODO: reset all states.
			current_total <= 'd0;
			current_total_nxt <= 'd0;
			for (i=0; i<4; i=i+1) num_items[i] = 'd10;
			for (i=0; i<4; i=i+1) num_items_nxt[i] = 'd10;
			for (i=0; i<3; i=i+1) num_coins[i] = 'd5;
			for (i=0; i<3; i=i+1) num_coins_nxt[i] = 'd5;
			for (i=0; i<4; i=i+1) o_output_item[i] = 0;
			for (i=0; i<3; i=i+1) o_return_coin[i] = 0;
			stopwatch = `kWaitTime;
			return_finished = 0;
			maintain_trigger_return = 0;
			for(i=0; i<3; i=i+1) lack_coin_test[i] = 0; 
		end
		else begin
			// TODO: update all states.
			current_total = current_total_nxt;
			for (i=0; i<4; i=i+1) num_items[i] = num_items_nxt[i];
			for (i=0; i<3; i=i+1) num_coins[i] = num_coins_nxt[i];
	/////////////////////////////////////////////////////////////////////////

				// decreas stopwatch
			if (stopwatch > 0) stopwatch = stopwatch - 1;

				//if you have to return some coins then you have to turn on the bit
			if (i_trigger_return) maintain_trigger_return = 1;
			if (return_finished) o_return_coin = 0;
			if ((maintain_trigger_return || (stopwatch==0)) && (return_finished==0)) begin
				//$display("1) 100:%d, 500:%d, 1000:%d", num_coins[0], num_coins[1], num_coins[2]);
				//$display("1) current_total: %d", current_total);
				for (i=0; i<3; i=i+1) begin
					if(current_total>=kkCoinValue[i]) begin
						o_return_coin[i]=1;
						num_coins_nxt[i] = num_coins[i] - 1;
						current_total = current_total - kkCoinValue[i];
					end
					else o_return_coin[i]=0;
				end
				current_total_nxt = current_total;
				if (current_total==0) begin
					return_finished = 1;
					maintain_trigger_return = 0;
					for (i=0; i<4; i=i+1) o_output_item[i] = 0;
					stopwatch = `kWaitTime;
				end
				//$display("2) 100:%d, 500:%d, 1000:%d", num_coins[0], num_coins[1], num_coins[2]);
				//$display("2) current_total: %d", current_total);
			end

/////////////////////////////////////////////////////////////////////////
		end		   //update all state end
	end	   //always end

endmodule
