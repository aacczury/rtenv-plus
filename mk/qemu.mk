QEMU_STM32 ?= ../qemu_stm32/arm-softmmu/qemu-system-arm
UNIT_TEST = $(LIBDIR)/unit_test

qemu: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-monitor stdio \
		-kernel $(OUTDIR)/$(TARGET).bin

qemudbg: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-monitor stdio \
		-gdb tcp::3333 -S \
		-kernel $(OUTDIR)/$(TARGET).bin 2>&1>/dev/null & \
	echo $$! > $(OUTDIR)/qemu_pid && \
	$(CROSS_COMPILE)gdb -x $(TOOLDIR)/gdbscript && \
	cat $(OUTDIR)/qemu_pid | `xargs kill 2>/dev/null || test true` && \
	rm -f $(OUTDIR)/qemu_pid

qemu_remote: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel $(OUTDIR)/$(TARGET).bin -vnc :1

qemudbg_remote: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(OUTDIR)/$(TARGET).bin \
		-vnc :1

qemu_remote_bg: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-kernel $(OUTDIR)/$(TARGET).bin \
		-vnc :1 &

check:
	$(MAKE) $(OUTDIR)/$(TARGET).bin DEBUG_FLAGS=-DDEBUG
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-serial stdio \
		-kernel $(OUTDIR)/$(TARGET).bin -monitor null >/dev/null &
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-strlen.in
	@mv -f gdb.txt $(UNIT_TEST)/test-strlen.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-strcpy.in
	@mv -f gdb.txt $(UNIT_TEST)/test-strcpy.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-strcmp.in
	@mv -f gdb.txt $(UNIT_TEST)/test-strcmp.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-strncmp.in
	@mv -f gdb.txt $(UNIT_TEST)/test-strncmp.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-cmdtok.in
	@mv -f gdb.txt $(UNIT_TEST)/test-cmdtok.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-itoa.in
	@mv -f gdb.txt $(UNIT_TEST)/test-itoa.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-find_events.in
	@mv -f gdb.txt $(UNIT_TEST)/-find_events.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-find_envvar.in
	@mv -f gdb.txt $(UNIT_TEST)/test-find_envvar.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-fill_arg.in
	@mv -f gdb.txt $(UNIT_TEST)/test-fill_arg.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-export_envvar.in
	@mv -f gdb.txt $(UNIT_TEST)/test-export_envvar.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(UNIT_TEST)/test-cat.in
	@mv -f gdb.txt $(UNIT_TEST)/test-ls.txt
	@echo
	@pkill -9 $(notdir $(QEMU_STM32))

qemudbg_remote_bg: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(OUTDIR)/$(TARGET).bin \
		-vnc :1 &

emu: $(OUTDIR)/$(TARGET).bin
	bash $(TOOLDIR)/emulate.sh $(OUTDIR)/$(TARGET).bin

qemuauto: $(OUTDIR)/$(TARGET).bin $(TOOLDIR)gdbscript
	bash $(TOOLDIR)emulate.sh $(OUTDIR)/$(TARGET).bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x gdbscript&
	sleep 5

qemuauto_remote: $(OUTDIR)/$(TARGET).bin $(TOOLDIR)gdbscript
	bash $(TOOLDIR)emulate_remote.sh $(OUTDIR)/$(TARGET).bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x gdbscript&
	sleep 5
