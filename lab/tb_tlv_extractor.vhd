library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.data_types_context;

library osvvm;
use osvvm.RandomPkg.all;

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
  constant max_packet_length : natural := 2**byte_t'length-1;
  signal clk : std_logic := '0';
  signal in_tvalid : std_logic;
  signal in_tdata : byte_t;
  signal out_tvalid : std_logic;
  signal out_tdata : byte_t;

  signal random_in_tvalid : boolean := false;
  constant check_queue : queue_t := new_queue;
  constant stimuli_queue : queue_t := new_queue;

begin

  main : process

    variable rnd : RandomPType;

    procedure create_tlv_data(tag : byte_t;
                              length : natural;
                              should_extract : boolean) is
      procedure push(data : byte_t) is
      begin
        push(stimuli_queue, data);
        if should_extract then
          push(check_queue, data);
        end if;
      end;
    begin
      debug("create_tlv_data(data => " & to_string(to_integer(unsigned(tag))) & ", " & LF &
            "                length => " & to_string(length) & ", " & LF &
            "                should_extract => " & to_string(should_extract) & ")");
      push(tag);
      push(std_logic_vector(to_unsigned(length, tag'length)));

      for j in 0 to length-1 loop
        push(rnd.RandSlv(byte_t'length));
      end loop;
    end;

    procedure random_tlv_data(num_packets : natural) is
      variable tag : byte_t;
      variable length : natural;
    begin
      for i in 1 to num_packets loop
        if rnd.RandInt(0, 2) = 1 then
          tag := extracted_tag;
        else
          tag := rnd.RandSlv(byte_t'length);
        end if;
        length := rnd.RandInt(0, max_packet_length);
        create_tlv_data(tag, length, should_extract => tag = extracted_tag);
      end loop;
    end;
  begin
    test_runner_setup(runner, runner_cfg);
    rnd.InitSeed(rnd'instance_name);

    if run("Test that all packets are extracted") then
      create_tlv_data(extracted_tag, length => 11, should_extract => true);
      create_tlv_data(extracted_tag, length => 3, should_extract => true);
      create_tlv_data(extracted_tag, length => 8, should_extract => true);

    elsif run("Test not all packets are extracted") then
      create_tlv_data(extracted_tag, length => 11, should_extract => true);
      create_tlv_data(not extracted_tag, length => 3, should_extract => false);
      create_tlv_data(extracted_tag, length => 8, should_extract => true);

    elsif run("Test zero length packets") then
      create_tlv_data(extracted_tag, length => 0, should_extract => true);
      create_tlv_data(not extracted_tag, length => 0, should_extract => false);

    elsif run("Test max length packets") then
      create_tlv_data(extracted_tag, length => max_packet_length, should_extract => true);
      create_tlv_data(not extracted_tag, length => max_packet_length, should_extract => false);

    elsif run("Test random") then
      random_tlv_data(64);

    elsif run("Test random in_tvalid") then
      random_in_tvalid <= true;
      random_tlv_data(64);

    end if;

    wait until is_empty(stimuli_queue) and is_empty(check_queue) and rising_edge(clk);

    test_runner_cleanup(runner);
  end process;

  stimuli : process
    variable stimuli_rnd : RandomPType;
  begin
    stimuli_rnd.InitSeed(stimuli_rnd'instance_name);

    outer: loop
      while is_empty(stimuli_queue) loop
        wait until rising_edge(clk);
      end loop;

      in_tvalid <= '1';
      in_tdata <= pop_std_ulogic_vector(stimuli_queue);
      wait until in_tvalid = '1' and rising_edge(clk);
      in_tvalid <= '0';

      if random_in_tvalid then
        for i in 1 to stimuli_rnd.RandInt(4) loop
          wait until rising_edge(clk);
        end loop;
      end if;
    end loop;
  end process;

  checker : process
  begin
    wait until out_tvalid = '1' and rising_edge(clk);
    check_false(is_empty(check_queue), "Got unexpected data");
    check_equal(out_tdata, pop_std_ulogic_vector(check_queue),
                result("for out_tdata"));
  end process;

  monitor : block

    procedure monitor_tlv(logger : logger_t;
                          signal valid : in std_logic;
                          signal data : in byte_t) is

      variable count : natural := 0;

      impure function packet_string(tag : byte_t) return string is
      begin
        return "packet #" & to_string(count) & " with tag = " & to_string(to_integer(unsigned(tag)));
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
        debug(logger, "Packet length = " & to_string(length));

        for i in 0 to length-1 loop
          wait until valid = '1' and rising_edge(clk);
          debug(logger, "data(" & to_string(i) & ") = " & to_string(to_integer(unsigned(data))));
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
