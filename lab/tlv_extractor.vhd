library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tlv_extractor is
  generic (
    -- The tag to extract
    tag : std_logic_vector(7 downto 0)
  );
  port (
    clk : in std_logic;

    -- Input stream of bytes
    in_tvalid : in std_logic;
    in_tdata : in std_logic_vector(7 downto 0);

    -- Output stream of extracted bytes
    out_tvalid : out std_logic;
    out_tdata : out std_logic_vector(7 downto 0)
  );
end entity;

architecture a of tlv_extractor is
  type state_t is (read_tag, read_length, read_value);
  signal state : state_t := read_tag;

begin

  main : process
    variable length : unsigned(in_tdata'range);
    variable extract_packet : boolean;
  begin
    wait until rising_edge(clk);

    if in_tvalid = '1' then
      case state is
        when read_tag =>
          state <= read_length;
          extract_packet := in_tdata = tag;

        when read_length =>
          length := unsigned(in_tdata);

          if length = 0 then
            state <= read_tag;
          else
            state <= read_value;
          end if;

        when read_value =>
          if length = 1 then
            state <= read_tag;
          else
            length := length - 1;
          end if;

      end case;
    end if;

    out_tvalid <= in_tvalid when extract_packet else '0';
    out_tdata <= in_tdata;
  end process;
end;
