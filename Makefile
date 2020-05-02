VFILES=$(wildcard *.v)

OK = $(sort $(wildcard *.ok))
TESTS = $(patsubst %.ok,%,$(OK))
RAWS = $(patsubst %.ok,%.raw,$(OK))
VCDS = $(patsubst %.ok,%.vcd,$(OK))
OUTS = $(patsubst %.ok,%.out,$(OK))
RESULTS = $(patsubst %.ok,%.test,$(OK))

cpu : $(VFILES) Makefile
	iverilog -o cpu $(VFILES)
 
test : $(RESULTS)

clean :
	rm -rf cpu *.cycles *.out *.vcd *.raw mem.hex 

$(RAWS) : %.raw : Makefile cpu %.hex
	cp $*.hex mem.hex
	rm -f $*.raw $*.cycles $*.vcd
	(timeout 10 ./cpu > $*.raw 2> $*.cycles) || (touch $*.raw $*.cycles cpu.vcd)
	mv cpu.vcd $*.vcd

$(VCDS) : %.vcd : %.raw;

$(OUTS) : %.out : Makefile %.raw
	-@grep -v "VCD info: dumpfile cpu.vcd opened for output" $*.raw > $*.out 2> /dev/null

$(RESULTS) : %.test : Makefile %.out %.ok
	@echo -n "$* ... "
	-@((diff -wbB $*.out $*.ok > /dev/null 2>&1) && echo "pass") || (echo "fail")
