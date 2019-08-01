-- 7 Floors Elevator control Gnd - 6
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elevator is
  port (
	clock,Up_Down,In_Out,en: in std_logic; -- en to know that valid input is given to the system
	inp: in std_logic_vector(2 downto 0) -- Input the destination floor
  ) ;
end entity ; -- elevator

architecture arch of elevator is
type FsmState is (IDLE,Moving_Up,Moving_Down,Load_Up,Load_Down,LOAD);
signal fsm_state: FsmState;
signal lowest_floor_to_go,highest_floor_to_go: integer:=7;
signal low_up,high_down: integer:=7;
signal cur_floor: integer :=0;
signal up_stream,down_stream: std_logic_vector(6 downto 0):= "0000000";
signal transition_counter: integer:=0;
begin
process(clock,inp,Up_Down,In_Out,fsm_state,cur_floor,en)
variable transition_counter_var: integer;
variable next_fsm_state: FsmState;
variable cur_floor_var,inp_var: integer;
variable up_stream_var,down_stream_var: std_logic_vector(6 downto 0);
variable low_up_var,high_down_var: integer;
variable lowest_floor_to_go_var,highest_floor_to_go_var: integer;
begin
next_fsm_state:=fsm_state;
cur_floor_var:=cur_floor;
up_stream_var:=up_stream;down_stream_var:=down_stream;
high_down_var:=high_down;low_up_var:=low_up;
lowest_floor_to_go_var:=lowest_floor_to_go;highest_floor_to_go_var:=highest_floor_to_go;
transition_counter_var:=transition_counter;
inp_var:=to_integer(unsigned(inp));
case (fsm_state) is
	when IDLE =>
		if(en='1') then
			if(inp_var=7) then
				next_fsm_state:= IDLE;
			elsif(cur_floor_var = inp_var) then
				next_fsm_state:=LOAD;
			elsif (cur_floor_var < inp_var) then
				if((In_Out = '0') or (Up_Down='1')) then -- call from inside the lift or external call to go up
					high_down_var:=7; -- as there is no seventh floor, so set for reference
					up_stream_var(inp_var) := '1';
				else -- if the person calling from that floor wants to go down
					high_down_var:=inp_var;
					up_stream_var(inp_var):='1';
					down_stream_var(inp_var):='1';
				end if;
				next_fsm_state:=Moving_Up;
				highest_floor_to_go_var:=inp_var;
				transition_counter_var:=0;
			elsif (cur_floor_var > inp_var) then
				if(In_Out = '0' or Up_Down='0') then -- call from inside the lift or external call to go down
					low_up_var:=7; -- as there is no seventh floor, so set for reference
					down_stream_var(inp_var) := '1';
				else -- if the person calling from that floor wants to go down
					low_up_var:=inp_var;
					up_stream_var(inp_var):='1';
					down_stream_var(inp_var):='1';
				end if;
				next_fsm_state:=Moving_Down;
				lowest_floor_to_go_var:=inp_var;
				transition_counter_var:=0;
			end if;
		end if;
	when Moving_Up =>
			if (transition_counter = 3) then
				cur_floor_var:=cur_floor_var+1;
				transition_counter_var:=0;
				if (up_stream_var(cur_floor_var) = '1') then
					next_fsm_state:=Load_Up;
				end if;
				if (up_stream_var="0000000") then
					next_fsm_state:=IDLE;
				end if;
			end if;
		if(en='1') then
			if(inp_var=7) then
				--do nothing 
			elsif(cur_floor_var = inp_var) then
				if(In_Out='1' and Up_Down='0') then -- if the person at current floor wants to go down
					down_stream_var(inp_var):='1';
				else
					up_stream_var(inp_var):='1';
				end if;
			elsif (cur_floor_var < inp_var) then
				if((In_Out ='0') or (In_Out='1' and Up_Down='1')) then -- internal call or external call to go up
					up_stream_var(inp_var):='1';
					if (inp_var>high_down_var) then -- high_down one always has to go down or else it is kept to be 7
						up_stream_var(high_down_var):='0';
						down_stream_var(high_down_var):='1';
						high_down_var:=7;
					end if;
				else -- external call down
					down_stream_var(inp_var):='1';
					if(inp_var>high_down_var) then -- if the person on the highest floor(from all inputs) wanted to go down,
						up_stream_var(high_down_var):='0';--  then it will be removed from upstream and stored in downstream
						down_stream_var(high_down_var):='1';
						high_down_var:=inp_var;
					elsif (inp_var>highest_floor_to_go_var) then -- happens when high_down_var is 7 and input is > highest floor to go(from the given inputs)
						high_down_var:=inp_var;
						up_stream_var(inp_var):='1';
					end if;
				end if;
				if (inp_var > highest_floor_to_go_var) then
					highest_floor_to_go_var:=inp_var;
				end if;
			else -- call at lower floor
				if ((In_Out ='0') or (In_Out='1' and Up_Down='0')) then -- caller has to go definitely go down 
					down_stream_var(inp_var):='1';
					if (inp_var<low_up_var and low_up_var/=7) then
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						low_up_var:=7;
					end if;
				else -- caller has to definitely go up
					up_stream_var(inp_var):='1';
					if (inp_var<low_up_var and low_up_var/=7) then
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						down_stream_var(inp_var):='1'; -- as the lift must go down to pick that caller;
						low_up_var:=inp_var;
					elsif (inp_var<lowest_floor_to_go_var) then
						down_stream_var(inp_var):='1';
						low_up_var:=inp_var;
					end if;
				end if;
				if (inp_var<lowest_floor_to_go_var) then
					lowest_floor_to_go_var:=inp_var;
				end if;
			end if;
		end if;
		transition_counter_var:=transition_counter_var+1;
	when Load_Up =>
		up_stream_var(cur_floor):='0';down_stream_var(cur_floor):='0';
		if ((highest_floor_to_go_var = cur_floor) and (transition_counter=2)) then
			highest_floor_to_go_var:=7;
			if(down_stream_var="0000000") then
				next_fsm_state:=IDLE;
			else
				next_fsm_state:=Moving_Down;
			end if;
			transition_counter_var:=0;
		elsif (transition_counter=2) then
				next_fsm_state:=Moving_Up;
				transition_counter_var:=0;
		end if;
		transition_counter_var:=transition_counter_var+1;

		--to recieve inputs in this state
		if(en='1') then
			if(inp_var=7) then
				--do nothing 
			elsif(cur_floor_var = inp_var) then
				transition_counter_var:=1; -- behaves similarly to not closing the door 
			elsif (cur_floor_var < inp_var) then
				if((In_Out ='0') or (In_Out='1' and Up_Down='1')) then -- internal call or external call to go up
					up_stream_var(inp_var):='1';
					if (inp_var>high_down_var) then -- high_down one always has to go down or else it is kept to be 7
						up_stream_var(high_down_var):='0';
						down_stream_var(high_down_var):='1';
						high_down_var:=7;
					end if;
				else -- external call down
					down_stream_var(inp_var):='1';
					if(inp_var>high_down_var) then -- if the person on the highest floor(from all inputs) wanted to go down,
						up_stream_var(high_down_var):='0';--  then it will be removed from upstream and stored in downstream
						down_stream_var(high_down_var):='1';
						high_down_var:=inp_var;
					elsif (inp_var>highest_floor_to_go_var) then -- happens when high_down_var is 7 and input is > highest floor to go(from the given inputs)
						high_down_var:=inp_var;
						up_stream_var(inp_var):='1';
					end if;
				end if;
				if (inp_var > highest_floor_to_go_var) then
					highest_floor_to_go_var:=inp_var;
				end if;
			else -- call at lower floor
				if ((In_Out ='0') or (In_Out='1' and Up_Down='0')) then -- caller has to go definitely go down 
					down_stream_var(inp_var):='1';
					if (inp_var<low_up_var and low_up_var/=7) then
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						low_up_var:=7;
					end if;
				else -- caller has to definitely go up
					up_stream_var(inp_var):='1';
					if (inp_var<low_up_var and low_up_var/=7) then
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						down_stream_var(inp_var):='1'; -- as the lift must go down to pick that caller;
						low_up_var:=inp_var;
					elsif (inp_var<lowest_floor_to_go_var) then
						down_stream_var(inp_var):='1';
						low_up_var:=inp_var;
					end if;
				end if;
				if (inp_var<lowest_floor_to_go_var) then
					lowest_floor_to_go_var:=inp_var;
				end if;
			end if;
		end if;
	when Moving_Down =>
		if (transition_counter = 3) then
				cur_floor_var:=cur_floor_var-1;
				transition_counter_var:=0;
				if (down_stream_var(cur_floor_var) = '1') then
					next_fsm_state:=Load_Down;
				end if;
				if (down_stream_var="0000000") then
					next_fsm_state:=IDLE;
				end if;
			end if;
		if(en='1') then
			if(inp_var=7) then
				--do nothing 
			elsif((cur_floor_var = inp_var)) then -- put a deceleration counter here
				if(In_Out ='0' or (In_Out='1' and Up_Down='0')) then
					down_stream_var(inp_var):='1';
				else
					up_stream_var(inp_var):='1';
				end if;
			elsif (cur_floor_var < inp_var) then 
				if((In_Out ='0') or (In_Out='1' and Up_Down='1')) then -- internal call or external call to go up
					up_stream_var(inp_var):='1';
					if (inp_var > high_down_var) then -- but high_down_var has to go down
						up_stream_var(high_down_var):='0';
						down_stream_var(high_down_var):='1';
						high_down_var:=7;
					end if;
				else -- the upper person wants to go down
					down_stream_var(inp_var):='1';
					if(inp_var>high_down_var) then
						up_stream_var(high_down_var):='0';
						down_stream_var(high_down_var):='1';
						up_stream_var(inp_var):='1'; 
						high_down_var:=inp_var;--update hf_Var
					elsif (inp_var>highest_floor_to_go_var) then
						high_down_var:=inp_var;
						up_stream_var(inp_var):='1';
					end if;
				end if;
				if (inp_var > highest_floor_to_go_var) then
					highest_floor_to_go_var:=inp_var;
				end if;
			else -- the lift is going down and the lower button is called
				if ((In_Out ='0') or (In_Out='1' and Up_Down='0')) then 
					down_stream_var(inp_var):='1';
					if (inp_var<low_up_var and low_up_var/=7) then
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						low_up_var:=7;
					end if;
				else -- caller has to go up
					up_stream_var(inp_var):='1'; 
					if (low_up_var=7) then
						low_up_var:=inp_var;
						down_stream_var(low_up_var):='1';
					elsif (inp_var<low_up_var) then -- as low_up_var wants to go up always
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						down_stream_var(inp_var):='1'; -- as lift has to go down so that the caller can go up
						low_up_var:=inp_var;	
					end if;
				end if;
				if (inp_var < lowest_floor_to_go_var) then
					lowest_floor_to_go_var:=inp_var;
				end if;
			end if;
		end if;
		transition_counter_var:=transition_counter_var+1;
	when Load_Down =>
		up_stream_var(cur_floor):='0';down_stream_var(cur_floor):='0';
		if ((lowest_floor_to_go_var = cur_floor) and (transition_counter=2)) then
			lowest_floor_to_go_var:=7;
			low_up_var:=7;
			if(up_stream_var="0000000") then
				next_fsm_state:=IDLE;
			else
				next_fsm_state:=Moving_Up;
			end if;
			transition_counter_var:=0;
		elsif(transition_counter=2) then
			next_fsm_state:=Moving_Down;
			transition_counter_var:=0;
		end if;
		transition_counter_var:=transition_counter_var+1;
		if(en='1') then
			if(inp_var=7) then
				--do nothing 
			elsif((cur_floor_var = inp_var)) then -- put a deceleration counter here
				transition_counter_var:=1;
			elsif (cur_floor_var < inp_var) then 
				if((In_Out ='0') or (In_Out='1' and Up_Down='1')) then -- internal call or external call to go up
					up_stream_var(inp_var):='1';
					if (inp_var > high_down_var) then -- but high_down_var has to go down
						up_stream_var(high_down_var):='0';
						down_stream_var(high_down_var):='1';
						high_down_var:=7;
					end if;
				else -- the upper person wants to go down
					down_stream_var(inp_var):='1';
					if(inp_var>high_down_var) then
						up_stream_var(high_down_var):='0';
						down_stream_var(high_down_var):='1';
						up_stream_var(inp_var):='1'; 
						high_down_var:=inp_var;--update hf_Var
					elsif (inp_var>highest_floor_to_go_var) then
						high_down_var:=inp_var;
						up_stream_var(inp_var):='1';
					end if;
				end if;
				if (inp_var > highest_floor_to_go_var) then
					highest_floor_to_go_var:=inp_var;
				end if;
			else -- the lift is going down and the lower button is called
				if ((In_Out ='0') or (In_Out='1' and Up_Down='0')) then 
					down_stream_var(inp_var):='1';
					if (inp_var<low_up_var and low_up_var/=7) then
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						low_up_var:=7;
					end if;
				else -- caller has to go up
					up_stream_var(inp_var):='1'; 
					if (low_up_var=7) then
						low_up_var:=inp_var;
						down_stream_var(low_up_var):='1';
					elsif (inp_var<low_up_var) then -- as low_up_var wants to go up always
						down_stream_var(low_up_var):='0';
						up_stream_var(low_up_var):='1';
						down_stream_var(inp_var):='1'; -- as lift has to go down so that the caller can go up
						low_up_var:=inp_var;	
					end if;
				end if;
				if (inp_var < lowest_floor_to_go_var) then
					lowest_floor_to_go_var:=inp_var;
				end if;
			end if;
		end if;
	when LOAD =>
		if (transition_counter=2) then
			next_fsm_state:=IDLE;
		end if;
		transition_counter_var:=transition_counter_var+1;
		if (en='1') then
			transition_counter_var:=1;
		end if;
	when others =>
		null;
end case;
up_stream<=up_stream_var;down_stream<=down_stream_var;
if (rising_edge(clock)) then
	fsm_state<=next_fsm_state;
	low_up<=low_up_var;high_down<=high_down_var;cur_floor<=cur_floor_var;
	lowest_floor_to_go<=lowest_floor_to_go_var;
	highest_floor_to_go<=highest_floor_to_go_var;
	transition_counter<=transition_counter_var;
end if;
end process;

end architecture ; -- arch