Linux HPU Driver
================

This is a char (i.e. [read/write]-oriented) Linux driver for the HPU core. A dmaengine-supported DMA core (Xilinx AXI dma, just to say one..) is required.

IOCTLs
------

Here there is a list of the currently supported IOCTLs.

```
HPU_IOCTL_READTIMESTAMP		1
HPU_IOCTL_CLEARTIMESTAMP	2
HPU_IOCTL_READVERSION		3
/* 4 is not used anymore */
HPU_IOCTL_SETTIMESTAMP		7
/* 8 is not used anymore */
HPU_IOCTL_GET_RX_PS			9
HPU_IOCTL_SET_AUX_THRS		10
HPU_IOCTL_GET_AUX_THRS		11
HPU_IOCTL_GET_AUX_CNT0		12
HPU_IOCTL_GET_AUX_CNT1		13
HPU_IOCTL_GET_AUX_CNT2		14
HPU_IOCTL_GET_AUX_CNT3		15
HPU_IOCTL_GET_LOST_CNT		16
HPU_IOCTL_SET_HSSAER_CH		17
HPU_IOCTL_SET_LOOP_CFG		18
HPU_IOCTL_SET_SPINN			19
HPU_IOCTL_GET_TX_PS			20
```
