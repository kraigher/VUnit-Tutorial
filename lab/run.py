from os.path import join, dirname
from vunit import VUnit

prj = VUnit.from_argv()
tlv = prj.add_library("tlv")
tlv.add_source_files(join(dirname(__file__), "*.vhd"))
prj.main()
