from os.path import join, dirname
from vunit import VUnit

prj = VUnit.from_argv()
prj.add_osvvm()
tlv = prj.add_library("tlv")
tlv.add_source_files(join(dirname(__file__), "*.vhd"))
prj.set_compile_option("ghdl.flags", ["-Wno-hide"])
prj.main()
