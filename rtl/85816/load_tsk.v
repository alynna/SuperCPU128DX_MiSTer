// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
//task load_tsk;
//input [7:0] db;
begin
	case(load_what)
	`BYTE_70:
			begin
				b8 <= db;
				state <= BYTE_CALC;
			end
	`BYTE_71:
			begin
				moveto_ifetch();
				res8 <= db;
			end
	`HALF_70:
				begin
					b16[7:0] <= db;
					load_what <= `HALF_158;
					radr <= radr+24'd1;
					state <= LOAD_MAC1;
				end
	`HALF_158:
				begin
					b16[15:8] <= db;
					if (isTribyte) begin
						radr <= radr+24'd1;
						load_what <= `TRIP_2316;
						next_state(LOAD_MAC1);
					end
					else
						state <= HALF_CALC;
				end
	`TRIP_2316:	begin
					b24 <= db;
					next_state(HALF_CALC);
				end
	`HALF_71:
				begin
					res16[7:0] <= db;
					load_what <= `HALF_159;
					radr <= radr+32'd1;
					next_state(LOAD_MAC1);
				end
	`HALF_159:
				begin
					res16[15:8] <= db;
					moveto_ifetch();
				end
	`HALF_71S:
				begin
					res16[7:0] <= db;
					load_what <= `HALF_159S;
					inc_sp();
					next_state(LOAD_MAC1);
				end
	`HALF_159S:
				begin
					res16[15:8] <= db;
					moveto_ifetch();
				end
	`BYTE_72:
				begin
					wdat[7:0] <= db;
					radr <= mvndst_address;
					wadr <= mvndst_address;
					store_what <= `STW_DEF8;
					acc[15:0] <= acc_dec[15:0];
					if (ir9==`MVN) begin
						x[15:0] <= x_inc[15:0];
						y[15:0] <= y_inc[15:0];
					end
					else begin
						x[15:0] <= x_dec[15:0];
						y[15:0] <= y_dec[15:0];
					end
					next_state(STORE1);
				end
	`SR_70:		begin
					cf <= db[0];
					zf <= db[1];
					if (db[2])
						im <= 1'b1;
					else
						imcd <= 3'b110;
					df <= db[3];
					if (m816) begin
						x_bit <= db[4];
						m_bit <= db[5];
						if (db[4]) begin
							x[15:8] <= 8'd0;
							y[15:8] <= 8'd0;
						end
						//if (db[5]) acc[31:8] <= 24'd0;
					end
					// The following load of the break flag is different than the '02
					// which never loads the flag.
					else
						bf <= db[4];
					vf <= db[6];
					nf <= db[7];
					if (isRTI) begin
						load_what <= `PC_70;
						inc_sp();
						state <= LOAD_MAC1;
					end		
					else begin	// PLP
						moveto_ifetch();
					end
				end
	`PC_70:		begin
					pc[7:0] <= db;
					load_what <= `PC_158;
					if (isRTI|isRTS|isRTL) begin
						inc_sp();
					end
					else begin	// JMP (abs)
						radr <= radr + 24'd1;
					end
					state <= LOAD_MAC1;
				end
	`PC_158:	begin
					pc[15:8] <= db;
					if ((isRTI&m816)|isRTL) begin
						load_what <= `PC_2316;
						inc_sp();
						state <= LOAD_MAC1;
					end
					else if (isRTS)	// rts instruction
						next_state(RTS1);
					else			// jmp (abs)
					begin
						vpb <= `FALSE;
						next_state(IFETCH0);
					end
				end
	`PC_2316:	begin
					pc[23:16] <= db;
					if (isRTL) begin
						load_what <= `NOTHING;
						next_state(RTS1);
					end
					else begin
						load_what <= `NOTHING;
						next_state(IFETCH0);
//						load_what <= `PC_3124;
//						if (isRTI) begin
//							inc_sp();
//						end
//						state <= LOAD_MAC1;	
					end
				end
//	`PC_3124:	begin
//					pc[31:24] <= db;
//					load_what <= `NOTHING;
//					next_state(BYTE_IFETCH);
//				end
	`IA_70:
			begin
				radr <= radr + 24'd1;
				ia[7:0] <= db;
				load_what <= `IA_158;
				state <= LOAD_MAC1;
			end
	`IA_158:
			begin
				ia[15:8] <= db;
				ia[23:16] <= dbr;
				if (isIY24|isI24) begin
					radr <= radr + 24'd1;
					load_what <= `IA_2316;
					state <= LOAD_MAC1;
				end
				else
					state <= isIY ? BYTE_IY5 : BYTE_IX5;
			end
	`IA_2316:
			begin
				ia[23:16] <= db;
				state <= isIY24 ? BYTE_IY5 : BYTE_IX5;
			end
	endcase
end
//endtask
