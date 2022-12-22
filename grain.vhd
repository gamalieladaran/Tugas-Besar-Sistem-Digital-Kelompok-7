LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity grain is 
 port(
  i_s : in std_logic;
  i_clk : in std_logic;
  i_rst : in std_logic;
  o_lfsr : out std_logic_vector(0 to 127);
  o_nfsr : out std_logic_vector(0 to 127);
  o_ho	: buffer std_logic;
  o_yt : buffer std_logic;
  o_cip : out std_logic_vector (0 to 63);
  z : out std_logic_vector (63 downto 0);
  zi : out std_logic_vector (63 downto 0)
  );
end grain;

architecture behavior of grain is
 signal s : std_logic;
 signal int_lfsr : std_logic_vector (0 to 127) := (others => '1');
 signal int_nfsr : std_logic_vector (0 to 127) := (others => '1');
 signal i_key : std_logic_vector (0 to 127) := x"000102030405060708090a0b0c0d0e0f";
 signal i_nonce : std_logic_vector (0 to 127) := x"00102030405060708090a0b0" & B"11111111111111111111111111111110";
 signal temp_lfsr : std_logic;
 signal temp_nfsr : std_logic;
 signal i_yt : std_logic;
 signal i_ho : std_logic;
 signal count : integer := -1;
 signal count_j : integer := -1;
 signal i_a0 : std_logic_vector (63 downto 0);
 signal i_r0 : std_logic_vector (63 downto 0);
 signal i_z : std_logic_vector (63 downto 0):= (others => '0');
 signal i_zi : std_logic_vector (63 downto 0):= (others => '0');
 signal int_cip : std_logic_vector (0 to 63) := (others => '0');
 signal int_mes : std_logic_vector (0 to 63) := x"01020304abcdefab";
 type state is (s1, s2, s3, s4, s5);
 signal currentstate, nextstate : state;
 
 begin
  
  s <= i_s;
  o_lfsr <= int_lfsr(0 to 127);
  o_nfsr <= int_nfsr(0 to 127);
  o_cip <= int_cip(0 to 63);
  z <= i_z(63 downto 0);
  zi <= i_zi (63 downto 0);
  o_ho <= i_ho;
  o_yt <= i_yt;
  
  counter : process(i_clk, i_rst)
  begin
  
   if (i_rst='1') then
    count <= -1;
   elsif (i_clk'event and i_clk='1') then
    count <= count + 1;
   else
    count <= count;
   end if;
   
  end process counter;
  
  counter_j : process (i_clk, i_rst, count)
  begin
  
  if (i_rst='1') then
   count_j <= -1;
  elsif (i_clk'event and i_clk='1' and count >= 382) then
   count_j <= count_j + 1;
  else
   count_j <= count_j;
  end if;
  
  end process counter_j;
  
  process_nextstate : process (i_rst, i_clk, s)
  begin
  
  if (i_rst = '1') then
   currentstate <= s1;
  elsif (i_clk'event and i_clk='1' and s = '1') then
   currentstate <= nextstate;
  else
   currentstate <= currentstate;
  end if;
  
  end process process_nextstate;
  
  state_update : process (i_rst, s,currentstate, nextstate, count, count_j)
  begin
  
  case currentstate is
   when s1 => 
    if (s='0' and count <0) then
     nextstate <= s1;
    else
	 nextstate <= s2;
	end if;
	
   when s2 =>
    if (count <= 319) then
     nextstate <= s2;
    else
	 nextstate <= s3;
	end if;
	
   when s3 => 
    if (count > 319 and count < 383) then
     nextstate <= s3;
    else
	 nextstate <= s4;
	end if;
	
   when s4 => 
    if (count_j <= 63) then
     nextstate <= s4;
    else
	 nextstate <= s5;
	end if;
	
   when s5 => 
    if (count > 383 and count <= 511) and (count_j > 63) then
     nextstate <= s5;
    else
	 nextstate <= s1;
	end if;
  
  end case;
  end process state_update;
  
  state_output : process (currentstate, nextstate, count, int_lfsr, int_nfsr, i_yt, temp_lfsr, temp_nfsr, int_mes, i_key, i_z, i_nonce)
  begin
  
  case currentstate is
  when s1 =>
   int_lfsr <= i_nonce;
   int_nfsr <= i_key;
   
  when s2 =>
   int_lfsr <= i_nonce;
   int_nfsr <= i_key;
   
   i_ho <= (int_nfsr(12) and int_lfsr(8)) xor (int_lfsr(13) and int_lfsr(20)) xor (int_nfsr(95) and int_lfsr(42)) xor (int_lfsr(60) and int_lfsr(79)) xor (int_nfsr(12) and int_nfsr(95) and int_lfsr(94));
   i_yt <= i_ho xor int_lfsr(93) xor int_nfsr(2) xor int_nfsr(15) xor int_nfsr(36) xor int_nfsr(45) xor int_nfsr(64) xor int_nfsr(73) xor int_nfsr(89);
  
   temp_lfsr <= int_lfsr(0) xor int_lfsr(7) xor int_lfsr(38) xor int_lfsr(70) xor int_lfsr(81) xor int_lfsr(96) xor i_yt;
   temp_nfsr <= int_lfsr(0) xor int_nfsr(0) xor int_nfsr(26) xor int_nfsr(56) xor int_nfsr(91) xor int_nfsr(96) xor (int_nfsr(3) AND int_nfsr(67)) xor (int_nfsr(11) AND int_nfsr(13)) xor (int_nfsr(17) AND int_nfsr(18)) xor (int_nfsr(27) AND int_nfsr(59)) xor (int_nfsr(40) AND int_nfsr(48)) xor (int_nfsr(61) AND int_nfsr(65)) xor (int_nfsr(68) AND int_nfsr(84)) xor (int_nfsr(22) AND int_nfsr(24) AND int_nfsr(25)) xor (int_nfsr(70) AND int_nfsr(78) AND int_nfsr(82)) xor (int_nfsr(88) AND int_nfsr(92) AND int_nfsr(93) AND int_nfsr(95)) xor i_yt;
	  
   for i in 0 to 126 loop
	int_lfsr(i) <= int_lfsr(i+1);
	int_nfsr(i) <= int_nfsr(i+1);
   end loop;
	 
   int_lfsr(127) <= temp_lfsr;
   int_nfsr(127) <= temp_nfsr;
   
   when s3 =>
    i_ho <= (int_nfsr(12) and int_lfsr(8)) xor (int_lfsr(13) and int_lfsr(20)) xor (int_nfsr(95) and int_lfsr(42)) xor (int_lfsr(60) and int_lfsr(79)) xor (int_nfsr(12) and int_nfsr(95) and int_lfsr(94));
    i_yt <= i_ho xor int_lfsr(93) xor int_nfsr(2) xor int_nfsr(15) xor int_nfsr(36) xor int_nfsr(45) xor int_nfsr(64) xor int_nfsr(73) xor int_nfsr(89);
   
    temp_lfsr <= int_lfsr(0) xor int_lfsr(7) xor int_lfsr(38) xor int_lfsr(70) xor int_lfsr(81) xor int_lfsr(96) xor i_yt xor i_key(count-256);
	temp_nfsr <= int_lfsr(0) xor int_nfsr(0) xor int_nfsr(26) xor int_nfsr(56) xor int_nfsr(91) xor int_nfsr(96) xor (int_nfsr(3) AND int_nfsr(67)) xor (int_nfsr(11) AND int_nfsr(13)) xor (int_nfsr(17) AND int_nfsr(18)) xor (int_nfsr(27) AND int_nfsr(59)) xor (int_nfsr(40) AND int_nfsr(48)) xor (int_nfsr(61) AND int_nfsr(65)) xor (int_nfsr(68) AND int_nfsr(84)) xor (int_nfsr(22) AND int_nfsr(24) AND int_nfsr(25)) xor (int_nfsr(70) AND int_nfsr(78) AND int_nfsr(82)) xor (int_nfsr(88) AND int_nfsr(92) AND int_nfsr(93) AND int_nfsr(95)) xor i_yt xor i_key(count-320);
	  
	for i in 0 to 126 loop
	 int_lfsr(i) <= int_lfsr(i+1);
	 int_nfsr(i) <= int_nfsr(i+1);
	end loop;
	 
	int_lfsr(127) <= temp_lfsr;
	int_nfsr(127) <= temp_nfsr;
	
	if(count mod 2 = 0) then
	  i_z((count-320)/2) <= i_yt;
    elsif ( count mod 2 = 1) and (count <= 126) then
	  i_zi((count-321)/2) <= i_yt;
	end if;
      
   when s4 =>
    i_ho <= (int_nfsr(12) and int_lfsr(8)) xor (int_lfsr(13) and int_lfsr(20)) xor (int_nfsr(95) and int_lfsr(42)) xor (int_lfsr(60) and int_lfsr(79)) xor (int_nfsr(12) and int_nfsr(95) and int_lfsr(94));
    i_yt <= i_ho xor int_lfsr(93) xor int_nfsr(2) xor int_nfsr(15) xor int_nfsr(36) xor int_nfsr(45) xor int_nfsr(64) xor int_nfsr(73) xor int_nfsr(89);
   
    if (count >= 384) and (count <= 447) then
     for j in 0 to 63 loop
      i_a0(j) <= i_yt;
     end loop;
    elsif (count >= 448) and (count <= 511) then
     for k in 0 to 63 loop
      i_r0(k) <= i_yt;
     end loop;
    end if;
    
   when s5 =>
    i_ho <= (int_nfsr(12) and int_lfsr(8)) xor (int_lfsr(13) and int_lfsr(20)) xor (int_nfsr(95) and int_lfsr(42)) xor (int_lfsr(60) and int_lfsr(79)) xor (int_nfsr(12) and int_nfsr(95) and int_lfsr(94));
    i_yt <= i_ho xor int_lfsr(93) xor int_nfsr(2) xor int_nfsr(15) xor int_nfsr(36) xor int_nfsr(45) xor int_nfsr(64) xor int_nfsr(73) xor int_nfsr(89);
   
    temp_lfsr <= int_lfsr(0) xor int_lfsr(7) xor int_lfsr(38) xor int_lfsr(70) xor int_lfsr(81) xor int_lfsr(96);
    temp_nfsr <= int_lfsr(0) xor int_nfsr(0) xor int_nfsr(26) xor int_nfsr(56) xor int_nfsr(91) xor int_nfsr(96) xor (int_nfsr(3) AND int_nfsr(67)) xor (int_nfsr(11) AND int_nfsr(13)) xor (int_nfsr(17) AND int_nfsr(18)) xor (int_nfsr(27) AND int_nfsr(59)) xor (int_nfsr(40) AND int_nfsr(48)) xor (int_nfsr(61) AND int_nfsr(65)) xor (int_nfsr(68) AND int_nfsr(84)) xor (int_nfsr(22) AND int_nfsr(24) AND int_nfsr(25)) xor (int_nfsr(70) AND int_nfsr(78) AND int_nfsr(82)) xor (int_nfsr(88) AND int_nfsr(92) AND int_nfsr(93) AND int_nfsr(95));
	  
    for i in 0 to 126 loop
	  int_lfsr(i) <= int_lfsr(i+1);
	  int_nfsr(i) <= int_nfsr(i+1);
	end loop;
	 
	int_lfsr(127) <= temp_lfsr;
	int_nfsr(127) <= temp_nfsr;
	 
	for m in 0 to 63 loop
	 int_cip(m) <= int_mes(m) xor i_z(m);
	end loop;
 
  end case;
  end process state_output;
 

end behavior;