/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 *
 * SystemVerilog Training Workshop.
 * Copyright 2006, 2013 by Sutherland HDL, Inc.
 * Tualatin, Oregon, USA.  All rights reserved.
 * www.sutherland-hdl.com
 **********************************************************************/

module instr_register_test (tb_ifc io);  // interface port

  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  int seed = 555;
  class Transaction;
	opcode_t       opcode;
	operand_t      operand_a, operand_b;
	address_t      write_pointer;
	
	function void randomize_transaction();
		// A later lab will replace this function with SystemVerilog
		// constrained random values
		//
		// The static temp variable is required in order to write to fixed
		// addresses of 0, 1 and 2.  This will be replaced with randomized
		// write_pointer values in a later lab
		//
		static int temp = 0;
		operand_a     <= $random(seed)%16;                 // between -15 and 15
		operand_b     <= $unsigned($random)%16;            // between 0 and 15
		opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
		write_pointer <= temp++;
	endfunction : randomize_transaction
	
	function void print_transaction;
		$display("Writing to register location %0d: ", write_pointer);
		$display("  opcode = %0d (%s)", opcode, opcode.name);
		$display("  operand_a = %0d",   operand_a);
		$display("  operand_b = %0d\n", operand_b);
	endfunction: print_transaction
	
   endclass: Transaction
   
   class Driver;
		virtual tb_ifc vifc;
		Transaction tr;
			function new(virtual tb_ifc vifc);
				this.vifc=vifc;
				tr = new();
			endfunction
			
			//function void reset_transaction();
			///$display("\nReseting the instruction register...");
			//vifc.cb.write_pointer   <= 5'h00;      // initialize write pointer
			//vifc.cb.read_pointer    <= 5'h1F;      // initialize read pointer
			//vifc.cb.load_en         <= 1'b0;       // initialize load control line
			//vifc.cb.reset_n         <= 1'b0;       // assert reset_n (active low)
			//repeat (2) @(vifc.cb) ;                // hold in reset for 2 clock cycles
			//vifc.cb.reset_n         <= 1'b1;       // deassert reset_n (active low)
			//endfunction: reset_transaction
			
		task generate_transaction();
			$display("\nReseting the instruction register...");
			vifc.cb.write_pointer   <= 5'h00;      // initialize write pointer
			vifc.cb.read_pointer    <= 5'h1F;      // initialize read pointer
			vifc.cb.load_en         <= 1'b0;       // initialize load control line
			vifc.cb.reset_n         <= 1'b0;       // assert reset_n (active low)
			repeat (2) @(vifc.cb) ;                // hold in reset for 2 clock cycles
			vifc.cb.reset_n         <= 1'b1;       // deassert reset_n (active low)

			$display("\nWriting values to register stack...");
			@(vifc.cb) vifc.cb.load_en <= 1'b1;      // enable writing to register
			repeat (3) begin
			@(vifc.cb) tr.randomize_transaction();
			@(vifc.cb) tr.print_transaction();
			vifc.operand_a <= tr.operand_a;
			vifc.operand_b <= tr.operand_b;
			vifc.opcode <= tr.opcode;
			vifc.write_pointer <= tr.write_pointer;
			end
			@(vifc.cb) vifc.cb.load_en <= 1'b0;      // turn-off writing to register

		endtask
  endclass: Driver
	
	
	class Monitor;
		virtual tb_ifc vifc;
		function new(virtual tb_ifc vifc);
			this.vifc = vifc;
		endfunction
		
		 function void print_results;
			$display("Read from register location %0d: ", io.cb.read_pointer);
			$display("  opcode = %0d (%s)", io.cb.instruction_word.opc, io.cb.instruction_word.opc.name);
			$display("  operand_a = %0d",   io.cb.instruction_word.op_a);
			$display("  operand_b = %0d\n", io.cb.instruction_word.op_b);
		endfunction: print_results
		
		
		    task transaction_monitor();
				$display("\nReading back the same register locations written...");
				for (int i=0; i<=2; i++) begin
					@(this.vifc.cb) this.vifc.cb.read_pointer <= i;
					@(this.vifc.cb) this.print_results();
				end
			endtask
  endclass: Monitor
  
		initial begin
    
			Driver driver;
			Monitor monitor;

			driver = new(io);
			monitor = new(io);

			driver.generate_transaction();
			monitor.transaction_monitor();

			@(io.cb) $finish;

		end
		
		
		  // initial begin
    // $display("\nReseting the instruction register...");
    // io.cb.write_pointer   <= 5'h00;      // initialize write pointer
    // io.cb.read_pointer    <= 5'h1F;      // initialize read pointer
    // io.cb.load_en         <= 1'b0;       // initialize load control line
    // io.cb.reset_n         <= 1'b0;       // assert reset_n (active low)
    // repeat (2) @(io.cb) ;                // hold in reset for 2 clock cycles
    // io.cb.reset_n         <= 1'b1;       // deassert reset_n (active low)

    // $display("\nWriting values to register stack...");
    // @(io.cb) io.cb.load_en <= 1'b1;      // enable writing to register
    // repeat (3) begin
    //   @(io.cb) randomize_transaction;
    //   @(io.cb) print_transaction;
    // end
    // @(io.cb) io.cb.load_en <= 1'b0;      // turn-off writing to register

    // $display("\nReading back the same register locations written...");
    // for (int i=0; i<=2; i++) begin
    //   // A later lab will replace this loop with iterating through a
    //   // scoreboard to determine which addresses were written and the
    //   // expected values to be read back
    //   @(io.cb) io.cb.read_pointer <= i;
    //   @(io.cb) print_results;
    // end

  //   @(io.cb) $finish;
  // end

  // function void randomize_transaction;
  //   // A later lab will replace this function with SystemVerilog
  //   // constrained random values
  //   //
  //   // The static temp variable is required in order to write to fixed
  //   // addresses of 0, 1 and 2.  This will be replaced with randomized
  //   // write_pointer values in a later lab
  //   //
  //   static int temp = 0;
  //   io.cb.operand_a     <= $random(seed)%16;                 // between -15 and 15
  //   io.cb.operand_b     <= $unsigned($random)%16;            // between 0 and 15
  //   io.cb.opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
  //   io.cb.write_pointer <= temp++;
  // endfunction: randomize_transaction

  // function void print_transaction;
  //   $display("Writing to register location %0d: ", io.cb.write_pointer);
  //   $display("  opcode = %0d (%s)", io.cb.opcode, io.cb.opcode.name);
  //   $display("  operand_a = %0d",   io.cb.operand_a);
  //   $display("  operand_b = %0d\n", io.cb.operand_b);
  // endfunction: print_transaction

  // function void print_results;
  //   $display("Read from register location %0d: ", io.cb.read_pointer);
  //   $display("  opcode = %0d (%s)", io.cb.instruction_word.opc, io.cb.instruction_word.opc.name);
  //   $display("  operand_a = %0d",   io.cb.instruction_word.op_a);
  //   $display("  operand_b = %0d\n", io.cb.instruction_word.op_b);
		 
		 
		 
		 
		

endmodule: instr_register_test
