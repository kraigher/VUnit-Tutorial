library ieee;
use ieee.std_logic_1164.all;

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
begin
end;
