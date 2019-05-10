VIVADO := vivado -nolog -nojournal -mode batch -source 
TARGET := 

#PRJ_CONFIG=

PHONY := all

all:
	$(VIVADO) apply_ps.tcl -tclargs $(PRJ_CONFIG)

.PHONY :clean
clean:
	@rm -rf build output *.hdf *.jou *.log

distclean:clean
	@rm -rf .config

.PHONY :install 
install:
	echo $(shell pwd)
	echo $(INSTALL_DIR)
	@cp ./output/* $(INSTALL_DIR)
