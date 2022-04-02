SRCS = src/*.vhd
BUILD_DIR = build/
TOP_ENTITY = uart_tb


analyze:
	cd $(BUILD_DIR) && ghdl -a ../$(SRCS)

elaborate: analyze
	cd $(BUILD_DIR) && ghdl -e $(TOP_ENTITY)

run: elaborate
	cd $(BUILD_DIR) && ghdl -r $(TOP_ENTITY)

run_wave: elaborate
	cd $(BUILD_DIR) && ghdl -r $(TOP_ENTITY) --vcd=$(TOP_ENTITY).vcd

display_wave: run_wave
	cd $(BUILD_DIR) && gtkwave $(TOP_ENTITY).vcd
