Linux HPU Driver
================

This is a char (i.e. [read/write]-oriented) Linux driver for the HPU core. A dmaengine-supported DMA core (Xilinx AXI dma, just to say one..) is required.

IOCTLs
------

Here there is a list of the currently supported IOCTLs.

| Name						|# |R/W| arg type            |
|---------------------------|--|---|---------------------|
|HPU_IOCTL_READTIMESTAMP	|1 | R |    unsigned int     |
|HPU_IOCTL_CLEARTIMESTAMP	|2 | W |    unsigned int     |
|HPU_IOCTL_READVERSION 		|3 | R |    unsigned int     |
| *not supported anymore*	|4 |   |                     |
|HPU_IOCTL_SETTIMESTAMP 	|7 | W |    unsigned int     |
| *not supported anymore*	|8 |   |                     |
|HPU_IOCTL_GET_RX_PS  		|9 | R |    unsigned int     |
|HPU_IOCTL_SET_AUX_THRS 	|10| W |   struct aux_cnt    |
|HPU_IOCTL_GET_AUX_THRS	   	|11| R |    unsigned int     |
|HPU_IOCTL_GET_AUX_CNT0		|12| R |    unsigned int     |
|HPU_IOCTL_GET_AUX_CNT1		|13| R |    unsigned int     |
|HPU_IOCTL_GET_AUX_CNT2		|14| R |    unsigned int     |
|HPU_IOCTL_GET_AUX_CNT3		|15| R |    unsigned int     |
|HPU_IOCTL_GET_LOST_CNT		|16| R |    unsigned int     |
|HPU_IOCTL_SET_HSSAER_CH	|17| W | struct ch_en_hssaer |
|HPU_IOCTL_SET_LOOP_CFG		|18| W |    unsigned int     |
|HPU_IOCTL_SET_SPINN		|19| W |    unsigned int     |
|HPU_IOCTL_GET_TX_PS		|20| R |    unsigned int     |
|HPU_IOCTL_SET_BLK_TX_THR	|21| W |    unsigned int     |
|HPU_IOCTL_SET_BLK_RX_THR	|22| W |    unsigned int     |

non-scalar types are defined as follows

``` C
enum hssaersrc { left_eye = 0, right_eye, aux, spinn };

typedef struct ch_en_hssaer {
	enum hssaersrc hssaer_src;
	uint8_t en_channels;
} ch_en_hssaer_t;

typedef struct aux_cnt {
	enum rx_err err;
	uint8_t cnt_val;
} aux_cnt_t;

```

All ioctls have *zero* as magic number.

Example of ioctl definition in userspace application:

``` C
#define IOC_MAGIC_NUMBER	0
#define IOC_READ_TS			_IOR(IOC_MAGIC_NUMBER, 1, unsigned int *)
#define IOC_CLEAR_TS		_IOW(IOC_MAGIC_NUMBER, 2, unsigned int *)
```
