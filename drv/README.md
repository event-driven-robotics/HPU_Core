Linux HPU Driver
================

This is a char (i.e. [read/write]-oriented) Linux driver for the HPU core. A dmaengine-supported DMA core (Xilinx AXI dma, just to say one..) is required.

IOCTLs
------

Here there is a list of the currently supported IOCTLs.

| Name                         |# |R/W| arg type               |
|------------------------------|--|---|------------------------|
|HPU_IOCTL_READTIMESTAMP       |1 | R |      unsigned int      |
|HPU_IOCTL_CLEARTIMESTAMP      |2 | W |      unsigned int      |
|HPU_IOCTL_READVERSION         |3 | R |      unsigned int      |
| *not supported anymore*      |4 |   |                        |
|HPU_IOCTL_SETTIMESTAMP        |7 | W |      unsigned int      |
| *not supported anymore*      |8 |   |                        |
|HPU_IOCTL_GET_RX_PS           |9 | R |      unsigned int      |
|HPU_IOCTL_SET_AUX_THRS        |10| W |     struct aux_cnt     |
|HPU_IOCTL_GET_AUX_THRS        |11| R |      unsigned int      |
|HPU_IOCTL_GET_AUX_CNT0        |12| R |      unsigned int      |
|HPU_IOCTL_GET_AUX_CNT1        |13| R |      unsigned int      |
|HPU_IOCTL_GET_AUX_CNT2        |14| R |      unsigned int      |
|HPU_IOCTL_GET_AUX_CNT3        |15| R |      unsigned int      |
|HPU_IOCTL_GET_LOST_CNT        |16| R |      unsigned int      |
| *not supported anymore*      |17|   |                        |
|HPU_IOCTL_SET_LOOP_CFG        |18| W |      spinn_loop_t      |
| *not supported anymore*      |19|   |                        |
|HPU_IOCTL_GET_TX_PS           |20| R |      unsigned int      |
|HPU_IOCTL_SET_BLK_TX_THR      |21| W |      unsigned int      |
|HPU_IOCTL_SET_BLK_RX_THR      |22| W |      unsigned int      |
|HPU_IOCTL_SET_SPINN_KEYS      |23| W |      spinn_keys_t      |
|HPU_IOCTL_SET_SPINN_KEYS_EN   |24| W |      unsigned int      |
|HPU_IOCTL_SET_SPINN_STARTSTOP |25| W |      unsigned int      |
|HPU_IOCTL_SET_RX_INTERFACE    |26| W |hpu_rx_interface_ioctl_t|
|HPU_IOCTL_SET_TX_INTERFACE    |27| W |hpu_tx_interface_ioctl_t|

non-scalar types are defined as follows

```C
enum hssaersrc { left_eye = 0, right_eye, aux, spinn };

typedef enum {
	INTERFACE_EYE_R,
	INTERFACE_EYE_L,
	INTERFACE_AUX
} hpu_interface_t;

typedef struct {
	int hssaer[4];
	int gtp;
	int paer;
	int spinn;
} hpu_interface_cfg_t;

typedef struct {
	hpu_interface_t interface;
	hpu_interface_cfg_t cfg;
} hpu_rx_interface_ioctl_t;

typedef enum {
	ROUTE_SINGLE,
	ROUTE_AUTO,
	ROUTE_ALL
} hpu_tx_route_t;

typedef struct {
	hpu_interface_cfg_t cfg;
	hpu_tx_route_t route;
} hpu_tx_interface_ioctl_t;

typedef struct aux_cnt {
	enum rx_err err;
	uint8_t cnt_val;
} aux_cnt_t;

typedef struct {
	u32 start;
	u32 stop;
} spinn_keys_t;

typedef enum {
	LOOP_NONE,
	LOOP_LNEAR,
	LOOP_LSPINN,
} spinn_loop_t;

```

All ioctls have *zero* as magic number.

Example of ioctl definition in userspace application:

``` C
#define IOC_MAGIC_NUMBER	0
#define IOC_READ_TS			_IOR(IOC_MAGIC_NUMBER, 1, unsigned int *)
#define IOC_CLEAR_TS		_IOW(IOC_MAGIC_NUMBER, 2, unsigned int *)
```

Module parameters
-----------------

*rx_to:* set the timeout of RX operations in mS.
*rx_pn:* set the number of DMA RX buffers in the ring. Must be a power of two.
*rx_ps:* set the size of DMA RX buffers. This is the minumum transfer size for which the driver is acknowledged of.

*tx_to* and *tx_pn:* as above, but on TX side.
*tx_ps:* set the size of DMA TX buffers. Unlike RX, there is no minumum transfer size.

Debugging stuff
---------------

You can enable driver debugging prints, provided that your kernel has been compiled with *dynamic printk* enabled (CONFIG_DYNAMIC_DEBUG=y), by loading the driver with the following command

``` bash
insmod iit-hpucore-dma.ko dyndbg==p
```

If your kernel supports *debug FS* (CONFIG_DEBUG_FS=y), you can snoop into the HPU registers by looking at */sys/kernel/debug/hpu/regdump.xxxxxxxx* (where 'xxxxxxxx' is the physical address of the HPU address space).

Kernel requirements
-------------------

The DMA driver needs to be able to:
- Enqueue new transfer requests while running
- Support partial transfers (i.e. early-terminated transfers, providing residue information)

EDL Zynq kernel (https://github.com/andreamerello/linux-zynq-stable) has been patched in order to accomplish to this requirements.

Depending by [rx/tx]_[pn_ps] The HPU driver needs to allocate large portions of DMAable memory. Please make sure that CMA (Contiguous Memory Allocator) is enabled in kernel config (CONFIG_CMA=y) and that a reasonable amount of memory is reserved (e.g. append *CMA=32M* to your kernel arguments).
