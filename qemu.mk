#{
#machine?=qemu
#qemu_machine?=lm3s6965evb
#image_type?=tash_16m
#qemu?=qemu-system-arm
#}

qemu/run: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${qemu_machine} -kernel $< -nographic

qemu/run/bg: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${qemu_machine} -kernel $< -nographic &
	echo $? > pid.tmp

qemu/stop:
	killall ${qemu}

qemu/stop/bg: pid.tmp
	kill $$(cat ${<}) && rm $<

qemu/check: run/bg sleep/20 stop/bg

sleep/%:
	sleep ${@F}
