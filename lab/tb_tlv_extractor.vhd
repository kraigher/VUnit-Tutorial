library vunit_lib;
context vunit_lib.vunit_context;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_tlv_extractor is
  generic (
    runner_cfg : string);
end entity;

architecture tb of tb_tlv_extractor is

  subtype byte_t is std_logic_vector(7 downto 0);
  constant extracted_tag : byte_t := x"ae";

  signal clk : std_logic := '0';
  signal in_tvalid : std_logic;
  signal in_tdata : byte_t;
  signal out_tvalid : std_logic;
  signal out_tdata : byte_t;

begin
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    test_runner_cleanup(runner);
  end process;

  monitor : block

    procedure monitor_tlv(logger : logger_t;
                          signal valid : in std_logic;
                          signal data : in byte_t) is

      variable count : natural := 0;

      impure function packet_string(tag : byte_t) return string is
      begin
        return "packet #" & to_string(count) & " with tag = " & to_hstring(tag);
      end;

      variable tag : byte_t;
      variable length : natural;

    begin
      loop
        wait until valid = '1' and rising_edge(clk);
        tag := data;
        info(logger, "Start of " & packet_string(tag));

        wait until valid = '1' and rising_edge(clk);
        length := to_integer(unsigned(data));
        info(logger, "Packet length = " & to_string(length));

        for i in 0 to length-1 loop
          wait until valid = '1' and rising_edge(clk);
          debug(logger, "data(" & to_string(i) & ") = " & to_hstring(data));
        end loop;

        debug(logger, "End of " & packet_string(tag));
        count := count + 1;
      end loop;
    end;
  begin
    monitor_tlv(get_logger("monitor:input"), in_tvalid, in_tdata);
    monitor_tlv(get_logger("monitor:output"), out_tvalid, out_tdata);
  end block;

  clk <= not clk after 5 ns;

  dut: entity work.tlv_extractor
    generic map (
      tag => extracted_tag)
    port map (
      clk        => clk,
      in_tvalid  => in_tvalid,
      in_tdata   => in_tdata,
      out_tvalid => out_tvalid,
      out_tdata  => out_tdata);
end architecture;
