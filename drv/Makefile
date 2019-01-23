.PHONY: check-env
obj-m += iit-hpucore-dma.o
all: check-env
	make -C $(KDIR) M=$(PWD) ARCH=arm CROSS_COMPILE=arm-none-eabi- modules
clean: check-env
	make -C $(KDIR) M=$(PWD) ARCH=arm CROSS_COMPILE=arm-none-eabi- clean

check-env:
ifndef KDIR
  $(error KDIR is not defined)
endif
