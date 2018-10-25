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


typedef struct aux_cnt {
	enum rx_err err;
	uint8_t cnt_val;
} aux_cnt_t;


All ioctls have *zero* as magic number.

Example of ioctl definition in userspace application:

``` C
#define IOC_MAGIC_NUMBER	0
#define IOC_READ_TS			_IOR(IOC_MAGIC_NUMBER, 1, unsigned int *)
#define IOC_CLEAR_TS		_IOW(IOC_MAGIC_NUMBER, 2, unsigned int *)
```

Ioctls that expect an integer number as argument expect a pointer to an *unsigned int*.
Ioclts that expect a logic boolean condition as argument want a pointer to an *unsigned int* that has to be either *1* or *0*.
Other non-scalar arguments type are described below.

### HPU_IOCTL_SET_BLK_TX_THR
Sets the minimum amount of data, in bytes, that a *write()* syscall has to successfully submit to the HPU driver before returning (would block otherwise).

The caller should check for the *write()* return value to check how many bytes have been accepted by the driver.

### HPU_IOCTL_SET_BLK_RX_THR
Sets the minimum amount of data, in bytes, that a *read()* syscall has to put in the supplied buffer before returning (would block otherwise).

The caller should check for the *read()* return value to check how many bytes have been put in the user buffer.

### HPU_IOCTL_SET_SPINN_KEYS
Sets both the *start* and *stop* keys to be recognized by the HPU on the SPINN bus.
Note that the *HPU_IOCTL_SPINN_KEYS_EN* ioctl has to be used in order to *enable* or *disable* the keys
recognization feature. The argument is a pointer to an instance of the following type

```C
typedef struct {
	u32 start;
	u32 stop;
} spinn_keys_t;
```

### HPU_IOCTL_SPINN_KEYS_EN
Disables/Enables the *start* and *stop* keys recognization on the SPINN bus.


### HPU_IOCTL_SET_SPINN_STARTSTOP
Forces a *start* (argument = 1) or *stop* (argument = 0) trigger for the SPINN interface. Start/stop keys settings will survive this IOCTL (i.e. if you have set and enabled start/stop keys and you force-start the bus, receiving a stop key will stop the bus).

### HPU_IOCTL_SET_LOOP_CFG
Allows to enable loopback mode (debug). It wants a pointer to an instance of the follwing type as argument

``` C
typedef enum {
	LOOP_NONE,
	LOOP_LNEAR,
	LOOP_LSPINN,
} spinn_loop_t;
```

- The LOOP_NONE mode just disables the loopback; the HW works in the regular way.
- The LOOP_LNEAR mode ("local near") directly loops TX-ed packet onto the RX path
- The LOOP_LSPINN mode ("local spinn") loops TX-ed pakets that are routed towards the SPINN BUS onto the SPINN bus of the RX AUX interface.


### HPU_IOCTL_SET_RX_INTERFACE
Configures the RX (data travelling to the CPU) interfaces. It wants a pointer to an instance of the follwing type as argument

```C
typedef struct {
	hpu_interface_t interface;
	hpu_interface_cfg_t cfg;
} hpu_rx_interface_ioctl_t;
```

The *interface* member identify to which RX interface the configuration has to be applied; it's type is defined as follows:

``` C
typedef enum {
	INTERFACE_EYE_R,
	INTERFACE_EYE_L,
	INTERFACE_AUX
} hpu_interface_t;
```
The *cfg* member contains the configuration to be applied; it's type is defined as follows:

``` C
typedef struct {
	int hssaer[4];
	int gtp;
	int paer;
	int spinn;
} hpu_interface_cfg_t;
```
Each member can be either *1* or *0* in order to enable or disable the corresponding bus.

### HPU_IOCTL_SET_TX_INTERFACE
Sets the TX (data sourced from the CPU and travelling to outside the CPU) inferface configuration.
It wants a pointer to an instance of the follwing type as argument

``` C
typedef struct {
	hpu_interface_cfg_t cfg;
	hpu_tx_route_t route;
} hpu_tx_interface_ioctl_t;
```
The *cfg* member contains the configuration to be applied; it's type is defined as follows:

``` C
typedef struct {
	int hssaer[4];
	int gtp;
	int paer;
	int spinn;
} hpu_interface_cfg_t;
```

Each member can be either *1* or *0* in order to enable or disable the corresponding bus. NOTE: gtp is not currently supported.

the *route* member type is defined as follows:

``` C
typedef enum {
	ROUTE_SINGLE,
	ROUTE_AUTO,
	ROUTE_ALL
} hpu_tx_route_t;
```

- When the *ROUTE_SINGLE* mode is selected, then the TX data is routed to the BUS selected by the *cfg* member. In this case only *one* BUS must be enabled in the *cfg* member.

- When the *ROUTE_ALL* mode is selected, then the TX data is routed to *all* the BUSses selected by the *cfg* member

- When the *ROUTE_AUTO* mode is selected, then the TX data is routed to one or more BUSes depending by the two MSBs of the message according to the following table, *and* depending by the enabled BUSes in *cfg* member:

MSBs|  dest  |
----|--------|
 00 | PAER   |
 01 | HSSAER |
 10 | SPINN  |
 11 | ALL    |


Module parameters
-----------------

*rx_to:* set the timeout of RX operations in mS.
*rx_pn:* set the number of DMA RX buffers in the ring. Must be a power of two.
*rx_ps:* set the size of DMA RX buffers.

*tx_to*, *tx_pn*, *tx_ps*: as above, but on TX side.

Debugging stuff
---------------

You can enable driver debugging prints, provided that your kernel has been compiled with *dynamic printk* enabled (CONFIG_DYNAMIC_DEBUG=y), by loading the driver with the following command

``` bash
insmod iit-hpucore-dma.ko dyndbg==p
```

If your kernel supports *debug FS* (CONFIG_DEBUG_FS=y), you'll find some files in  */sys/kernel/debug/hpu/hpu.xxxxxxxx* (where 'xxxxxxxx' is the physical address of the HPU address space).

Most notably you can snoop into the HPU registers by looking at the *regdump* file

Kernel requirements
-------------------

The DMA driver needs to be able to:
- Enqueue new transfer requests while running
- Support partial transfers (i.e. early-terminated transfers, providing residue information)

EDL Zynq kernel (https://github.com/andreamerello/linux-zynq-stable) has been patched in order to accomplish to this requirements.

Depending by [rx/tx]_[pn/ps] The HPU driver needs to allocate large portions of DMAable memory. Please make sure that CMA (Contiguous Memory Allocator) is enabled in kernel config (CONFIG_CMA=y) and that a reasonable amount of memory is reserved (e.g. append *CMA=32M* to your kernel arguments).
