Linux HPU Driver
================

This is a char (i.e. [read/write]-oriented) Linux driver for the HPU core. A dmaengine-supported DMA core (Xilinx AXI dma, just to say one..) is required.

IOCTLs
------

Here there is a list of the currently supported IOCTLs.

| Name                                   |# |R/W|  arg type                 |
|----------------------------------------|--|---|---------------------------|
|HPU_IOCTL_READTIMESTAMP                 |1 | R |        unsigned int       |
|HPU_IOCTL_CLEARTIMESTAMP                |2 | W |        unsigned int       |
|HPU_IOCTL_READVERSION                   |3 | R |        unsigned int       |
| *not supported anymore*                |4 |   |                           |
|HPU_IOCTL_SETTIMESTAMP                  |7 | W |        unsigned int       |
|HPU_IOCTL_GEN_REG                       |8 |R/W|        ip_regs_t          |
|HPU_IOCTL_GET_RX_PS                     |9 | R |        unsigned int       |
|HPU_IOCTL_SET_AUX_THRS                  |10| W |       struct aux_cnt      |
|HPU_IOCTL_GET_AUX_THRS                  |11| R |        unsigned int       |
|HPU_IOCTL_GET_AUX_CNT0                  |12| R |        unsigned int       |
|HPU_IOCTL_GET_AUX_CNT1                  |13| R |        unsigned int       |
|HPU_IOCTL_GET_AUX_CNT2                  |14| R |        unsigned int       |
|HPU_IOCTL_GET_AUX_CNT3                  |15| R |        unsigned int       |
|HPU_IOCTL_GET_LOST_CNT                  |16| R |        unsigned int       |
| *not supported anymore*                |17|   |                           |
|HPU_IOCTL_SET_LOOP_CFG                  |18| W |        spinn_loop_t       |
| *not supported anymore*                |19|   |                           |
|HPU_IOCTL_GET_TX_PS                     |20| R |        unsigned int       |
|HPU_IOCTL_SET_BLK_TX_THR                |21| W |        unsigned int       |
|HPU_IOCTL_SET_BLK_RX_THR                |22| W |        unsigned int       |
|HPU_IOCTL_SET_SPINN_KEYS                |23| W |        spinn_keys_t       |
| *not supported anymore*                |24|   |                           |
|HPU_IOCTL_SET_SPINN_STARTSTOP           |25| W |        unsigned int       |
|HPU_IOCTL_SET_RX_INTERFACE              |26| W |  hpu_rx_interface_ioctl_t |
|HPU_IOCTL_SET_TX_INTERFACE              |27| W |  hpu_tx_interface_ioctl_t |
|HPU_IOCTL_SET_AXIS_LATENCY              |28| W |        unsigned int       |
|HPU_IOCTL_GET_RX_PN                     |29| R |        unsigned int       |
| *not supported anymore*                |30| - |                           |
|HPU_IOCTL_SET_TS_MASK                   |31| W |   hpu_timestamp_mask_t    |
|HPU_IOCTL_SET_TX_TIMING_MODE            |32| W |   hpu_tx_timing_mode_t    |
|HPU_IOCTL_SET_TX_RESYNC_TIMER           |33| W |   hpu_tx_resync_time_t    |
|HPU_IOCTL_RESET_TX_RESYNC_TIMER         |34| - |                           |
|HPU_IOCTL_FORCE_TX_RESYNC_TIMER         |35| - |                           |
|HPU_IOCTL_SET_SPINN_TX_MASK             |36| W |        unsigned int       |
|HPU_IOCTL_SET_SPINN_RX_MASK             |37| W |        unsigned int       |
|HPU_IOCTL_GET_HW_STATUS                 |38| R |      hpu_hw_status_t      |
|HPU_IOCTL_SET_SPINN_KEYS_EN_EX          |39| W |    spinn_keys_enable_t    |
|HPU_IOCTL_SET_RX_TS_ENABLE              |40| W |        unsigned int       |
|HPU_IOCTL_SET_TX_TS_ENABLE              |41| W |        unsigned int       |

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

### HPU_IOCTL_READTIMESTAMP
It gives the number of times that the timestamp counter has wrapped.

### HPU_IOCTL_CLEARTIMESTAMP
It clear the timestamp counter.

### HPU_IOCTL_READVERSION
It gives the version number of the HPU.

### HPU_IOCTL_SETTIMESTAMP
When the argument of the IOCTL is equal to zero, it set the timestamp @24 bits with higher 8bits of 32bits set to 0x80. When the argument of the IOCTL is different to zero, the timestamp is fully 32bit wide.

### HPU_IOCTL_GEN_REG
Provide a raw access (R/W) to the HW registers. It's here only for debugging purposes, while it's use in production is discouraged because it could cause weird side-effects.

It wants a pointer to an instance of the follwing type as argument:

```C
typedef struct ip_regs {
       u32 reg_offset;
       char rw;
       u32 data;
} ip_regs_t;
```

The *reg_offset* member must be filled with the address of the register being written (when *rw* is 1) or read (when *rw* is 0).
The *data* field does carry either the data to be written or that has been read.

### HPU_IOCTL_GET_RX_PS
It gives the size of the DMA RX buffers

### HPU_IOCTL_SET_AUX_THRS
Sets the threshold of the AUX RX counter error.
It wants a pointer to an instance of the following type as argument:

```C
enum rx_err { ko_err = 0, rx_err, to_err, of_err, nomeaning_err };

typedef struct aux_cnt {
	enum rx_err err;
	uint8_t cnt_val;
} aux_cnt_t;
```
The *err* member must be filled with 0,1,2 or 3 value meaning repsectively: ko, rx to or of error.
the *cnt_val* is the value of the threshold.

### HPU_IOCTL_GET_AUX_THRS
It gives the values of the AUX RX Error Threshold register

### HPU_IOCTL_GET_AUX_CNT0
It gives the value of the errors occured in the AUX RX Channel 0

### HPU_IOCTL_GET_AUX_CNT1
It gives the value of the errors occured in the AUX RX Channel 1

### HPU_IOCTL_GET_AUX_CNT2
It gives the value of the errors occured in the AUX RX Channel 2

### HPU_IOCTL_GET_AUX_CNT3
It gives the value of the errors occured in the AUX RX Channel 3

### HPU_IOCTL_GET_TX_PS
It gives the size of the DMA TX buffers

### HPU_IOCTL_SET_BLK_TX_THR
Sets the minimum amount of data, in bytes, that a *write()* syscall has to successfully submit to the HPU driver before returning (would block otherwise).

The caller should check for the *write()* return value to check how many bytes have been accepted by the driver.

### HPU_IOCTL_SET_BLK_RX_THR
Sets the minimum amount of data, in bytes, that a *read()* syscall has to put in the supplied buffer before returning (would block otherwise).

The caller should check for the *read()* return value to check how many bytes have been put in the user buffer.

### HPU_IOCTL_SET_SPINN_KEYS
Sets both the *start* and *stop* keys to be recognized by the HPU on the SPINN bus.
Note that the *HPU_IOCTL_SPINN_KEYS_EN_EX* ioctl has to be used in order to *enable* or *disable* the keys
recognization feature. The argument is a pointer to an instance of the following type

```C
typedef struct {
	u32 start;
	u32 stop;
} spinn_keys_t;
```

### HPU_IOCTL_SPINN_KEYS_EN_EX
Disables/Enables the *start* and *stop* keys recognization on the SPINN bus.
The argument is a pointer to an instance of the following type

```C
typedef struct {
	int enable_l;
	int enable_r;
	int enable_aux;
} spinn_keys_enable_t;
```

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
	ROUTE_FIXED,
	ROUTE_MSG,
} hpu_tx_route_t;
```

- When the *ROUTE_FIXED* mode is selected, then the TX data is routed to the BUS selected by the *cfg* member. Either only *one* BUS, ora *all* BUSses can be enabled in the *cfg* member, the HW does not support half-way configurations. NOTE: hssaer counts as "one".

- When the *ROUTE_MSG* mode is selected, then the TX data is routed to one or more BUSes depending by the two MSBs of the message according to the following table, *and* depending by the enabled BUSes in *cfg* member:

MSBs|  dest  |
----|--------|
 00 | PAER   |
 01 | HSSAER |
 10 | SPINN  |
 11 | ALL    |

### HPU_IOCTL_SET_AXIS_LATENCY
Set the maximum time (in mS) after which a data transfer is forced to happen, even if it would contain less data than expected.

This affects only the RX channel, and it allows to limit the latency when few data is received, while still keeping large buffers to be able to handle also high-load situations.

## HPU_IOCTL_SET_TS_MASK
Sets the TX timestamp mask. It wants a pointer to an instance of the follwing type as argument.

``` C
typedef enum {
	MASK_20BIT,
	MASK_24BIT,
	MASK_28BIT,
	MASK_32BIT,
} hpu_timestamp_mask_t;
```

## HPU_IOCTL_SET_TX_TIMING_MODE
Sets how the TX timestamp is interpreted by the HW. It wants a pointer to an instance of the follwing type as argument.

``` C
typedef enum {
	TIMINGMODE_DELTA,
	TIMINGMODE_ASAP,
	TIMINGMODE_ABS,
} hpu_tx_timing_mode_t;
```

- In TIMINGMODE_DELTA the timestamp is interpreted as the time to wait before sending the current packet, calculated since the last sent packet.
- In TIMINGMODE_ASAP the timestamp is ignored by the HW
- In TIMINGMODE_ABS the timestamp is interpreted as the absolute time at which the current packet has to be sent. In this case the HPU clock has to be synchronized wrt the system clock. Please look below for more information

## HPU_IOCTL_SET_TX_RESYNC_TIMER
Valid only when the TX timing mode is set as TIMINGMODE_ABS.

This IOCTL configures (or disables) the timeout value after which the HPU assumes its internal clock has to be resynchronized wrt the host clock.

Once the timeout expires the HPU will resynchronize its clock by looking at the timestamp of the next packet TXed by the host.

This IOCTL wants a pointer to an instance of the follwing type as argument:

``` C
typedef enum {
	TIME_1mS,
	TIME_5mS,
	TIME_10mS,
	TIME_50mS,
	TIME_100mS,
	TIME_500mS,
	TIME_1000mS,
	TIME_2500mS,
	TIME_5000mS,
	TIME_10S,
	TIME_25S,
	TIME_50S,
	TIME_100S,
	TIME_250S,
	TIME_500S,
	TIME_DISABLE,
} hpu_tx_resync_time_t;
```

## HPU_IOCTL_RESET_TX_RESYNC_TIMER
This IOCTL had no effect unless the TX timing mode is set as TIMINGMODE_ABS; it takes no arguments and cause the resync timer (see above) to be reset, so it will restart counting and waiting.

## HPU_IOCTL_FORCE_TX_RESYNC_TIMER
This IOCTL has no effect unless the TX timing mode is set as TIMINGMODE_ABS; it takes no arguments and cause the resync timer (see above) to forcefully expire. The HPU will resync on the next TXed packet.

## HPU_IOCTL_SET_SPINN_TX_MASK
Sets the MASK to be applied to data that are transmitted to SPINNAKER.

## HPU_IOCTL_SET_SPINN_RX_MASK
Sets the MASK to be applied to data that are received from SPINNAKER.

## HPU_IOCTL_GET_HW_STATUS
returns a collection of status flags as reported by the hw; It wants a pointer to an instance of the follwing type as argument.

``` C
typedef struct {
	fifo_status_t rx_fifo_status;
	fifo_status_t tx_fifo_status;
	int rx_buffer_ready;
	int lrx_paer_fifo_full;
	int rrx_paer_fifo_full;
	int auxrx_paer_fifo_full;
	int rx_fifo_over_threshold;
	int global_rx_err_ko;
	int global_rx_err_tx;
	int global_rx_err_to;
	int global_rx_err_of;
	int tx_spinn_dump;
	int lspinn_parity_err;
	int rspinn_parity_err;
	int auxspinn_parity_err;
	int lspinn_rx_err;
	int rspinn_rx_err;
	int auxspinn_rx_err;
} hpu_hw_status_t;

typedef enum {
	EMPTY,
	ALMOST_EMPTY,
	FULL,
	ALMOST_FULL,
	NOT_EMPTY
} fifo_status_t;

```

## HPU_IOCTL_SET_RX_TS_ENABLE
Enables/disables RX timestamping. When disabled all RX words contain events; timestamps are othewise interleaved.

## HPU_IOCTL_SET_TX_TS_ENABLE
Enables/disable specifying TX time in TX buffer. When disabled all TX words contain data; TX time is otherwise interleaved.


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

EDL [Zynq7000](https://gitlab.iit.it/edl/linux-kernel-zynq7000) and [ZynqMP](https://gitlab.iit.it/edl/linux-kernel-zynqmp) kernels have been patched with a customized DMA Xilinx driver that satisfy to these requirements.

*NOTE*: expecially on Zynq7000, a lot of coherent memory is used by the drv; depending by [rx/tx]_[pn/ps] The HPU driver needs to allocate large portions of DMAable memory. Please make sure that CMA (Contiguous Memory Allocator) is enabled in kernel config (CONFIG_CMA=y) and that a reasonable amount of memory is reserved (e.g. append *CMA=32M* to your kernel arguments).
