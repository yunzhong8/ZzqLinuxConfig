
BUILD_DIR = ./build

test:
	sbt "test:runMain xxx.MainTest"

verilog:
	sbt "runMain xxx.GenerateVerilogObject"