/*
 *           HeadProcessorUnit (HPUCore) Linux driver.
 *
 * - this version uses scatter-gather (no cyclic) DMA -
 *
 * For streaming engineering test through char interface.
 * May need to be ported to IIO framework exploiting fast iio from
 * analog devics inc.
 *
 * Copyright (c) 2016 Istituto Italiano di Tecnologia
 * Electronic Design Lab.
 *
 */

#ifndef CONFIG_ARM
/*
 * On ARMv7 (i.e. Zynq7000) the cache invalidation operation required by the
 * dma synchronization primitives lead to worse performances wrt using DMA
 * coherent memory
 */

#define HPU_DMA_STREAMING
/* On ZynqMP it seems conveninet to defer the DMA resubmitting task to a kernel
 * thread. While on Zynq7000 it was expected not to be convenient, because it
 * just have two cores, it seems that it also does not work in principle (i.e.
 * the core that is leveraged from doing this task doesn't seem to get any
 * benefit) for reasons yet to be clarified. For now we just enable it only
 * on ARMv8 (i.e. ZynqMP)
 */
#define HPU_DMA_DEFER_SUBMIT
#endif

#include <asm/io.h>
#include <asm/uaccess.h>
#include <linux/iopoll.h>
#include <linux/cdev.h>
#include <linux/idr.h>
#include <linux/clk.h>
#include <linux/debugfs.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/kernel.h>
#include <linux/kthread.h>
#include <linux/module.h>
#include <linux/of_platform.h>
#include <linux/semaphore.h>
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/wait.h>
#include <linux/kdev_t.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/dmapool.h>
#include <linux/interrupt.h>
#include <linux/stringify.h>
#include <linux/version.h>

/* max HPUs that can be handled */
#define HPU_MINOR_COUNT 10

/* SPINN link */
#define HPU_DEFAULT_START_KEY 0x80000000
#define HPU_DEFAULT_STOP_KEY 0x40000000

/* RX DMA pool */
#define HPU_RX_POOL_SIZE 1024
#define HPU_RX_POOL_NUM 1024 /* must, must, must, must be a power of 2 */
#define HPU_RX_TO_MS 100000

/* TX DMA pool */
#define HPU_TX_POOL_SIZE 4096
#define HPU_TX_POOL_NUM 128 /* must, must, must, must be a power of 2 */
#define HPU_TX_TO_MS 100000

/* names */
#define HPU_NAME "iit-hpu"
#define HPU_DRIVER_NAME HPU_NAME"-driver"
#define HPU_CLASS_NAME HPU_NAME"-class"
#define HPU_DEV_NAME HPU_NAME"-dev"
#define HPU_NAME_FMT HPU_NAME"%d"

/* registers */
#define HPU_CTRL_REG 		0x00
#define HPU_RXDATA_REG 		0x08
#define HPU_RXTIME_REG 		0x0C
#define HPU_DMA_REG 		0x14
#define HPU_RAWSTAT_REG		0x18
#define HPU_IRQ_REG 		0x1C
#define HPU_IRQMASK_REG		0x20
#define HPU_WRAP_REG		0x28
#define HPU_HSSAER_STAT_REG	0x34
#define HPU_HSSAER_RXERR_REG	0x38
#define HPU_HSSAER_RXMSK_REG	0x3C
#define HPU_RXCTRL_REG		0x40
#define HPU_TXCTRL_REG		0x44
#define HPU_RXPAERCNFG_REG	0x48
#define HPU_TXPAERCNFG_REG	0x4C
#define HPU_IPCFONFIG_REG	0x50
#define HPU_FIFOTHRESHOLD_REG	0x54
#define HPU_VER_REG		0x5C
#define HPU_AUX_RXCTRL_REG	0x60
#define HPU_AUX_RX_ERR_REG	0x64
#define HPU_AUX_RX_MSK_REG	0x68
#define HPU_AUX_RX_ERR_THRS_REG 0x6C
#define HPU_AUX_RX_ERR_CH0_REG	0x70
#define HPU_AUX_RX_ERR_CH1_REG	0x74
#define HPU_AUX_RX_ERR_CH2_REG	0x78
#define HPU_AUX_RX_ERR_CH3_REG	0x7C
#define HPU_SPINN_START_KEY_REG	0x80
#define HPU_SPINN_STOP_KEY_REG	0x84
#define HPU_SPINN_TX_MASK_REG	0x88
#define HPU_SPINN_RX_MASK_REG	0x8c
#define HPU_SPINN_CTRL_REG	0x90
#define HPU_TLAST_TIMEOUT	0xA0
#define HPU_TLAST_COUNT		0xA4
#define HPU_DATA_COUNT		0xA8

/* magic constants */
#define HPU_VER_MAGIC			0x48505536

#define HPU_CTRL_DMA_RUNNING		0x0001
#define HPU_CTRL_ENDMA			0x0002
#define HPU_CTRL_ENINT			0x0004
#define HPU_CTRL_FLUSH_RX_FIFO		BIT(4)
#define HPU_CTRL_FLUSH_TX_FIFO		BIT(8)
#define HPU_CTRL_AXIS_LAT		BIT(9)
#define HPU_CTRL_RESETDMASTREAM 	0x1000
#define HPU_CTRL_FULLTS			0x8000
#define HPU_CTRL_LOOP_SPINN		(BIT(22) | BIT(23))
#define HPU_CTRL_LOOP_LNEAR		BIT(25)

#define HPU_DMA_LENGTH_MASK		0xFFFF
#define HPU_DMA_TEST_ON			0x10000

#define HPU_RAWSTAT_RXDATAEMPTY		BIT(0)
#define HPU_RAWSTAT_RXDATAALMOSTEMPTY	BIT(1)
#define HPU_RAWSTAT_RXDATAFULL		BIT(2)
#define HPU_RAWSTAT_TXDATAEMPTY		BIT(3)
#define HPU_RAWSTAT_TXDATAALMOSTFULL	BIT(4)
#define HPU_RAWSTAT_TXDATAFULL		BIT(5)
#define HPU_RAWSTAT_TIMESTAMPWRAPPED	BIT(7)
#define HPU_RAWSTAT_RXBUFFERREADY	BIT(8)
#define HPU_RAWSTAT_RXFIFONOTEMPTY	BIT(9)
#define HPU_RAWSTAT_LRXPAERFIFOFULL	BIT(12)
#define HPU_RAWSTAT_RRXPAERFIFOFULL	BIT(13)
#define HPU_RAWSTAT_AUXRXPAERFIFOFULL	BIT(14)
#define HPU_RAWSTAT_RXFIFOTHRESHOLD	BIT(15)
#define HPU_RAWSTAT_GLBLRXERR_KO	BIT(16)
#define HPU_RAWSTAT_GLBLRXERR_TX	BIT(17)
#define HPU_RAWSTAT_GLBLRXERR_TO	BIT(18)
#define HPU_RAWSTAT_GLBLRXERR_OF	BIT(19)
#define HPU_RAWSTAT_TXSPINNDUMP 	BIT(20)
#define HPU_RAWSTAT_LSPINN_PARITY_ERR	BIT(21)
#define HPU_RAWSTAT_RSPINN_PARITY_ERR	BIT(22)
#define HPU_RAWSTAT_AUXSPINN_PARITY_ERR	BIT(23)
#define HPU_RAWSTAT_LSPINN_RXERR	BIT(24)
#define HPU_RAWSTAT_RSPINN_RXERR	BIT(25)
#define HPU_RAWSTAT_AUXSPINN_RXERR	BIT(26)

#define HPU_RXCTRL_RXHSSAER_EN		0x00000001
#define HPU_RXCTRL_RXPAER_EN		0x00000002
#define HPU_RXCTRL_RXGTP_EN		0x00000004
#define HPU_RXCTRL_SPINN_EN		0x00000008
#define HPU_RXCTRL_RXHSSAERCH0_EN	0x00000100
#define HPU_RXCTRL_RXHSSAERCH1_EN	0x00000200
#define HPU_RXCTRL_RXHSSAERCH2_EN	0x00000400
#define HPU_RXCTRL_RXHSSAERCH3_EN	0x00000800

#define HPU_TXCTRL_TXHSSAER_EN		0x00000001
#define HPU_TXCTRL_TXPAER_EN		0x00000002
#define HPU_TXCTRL_SPINN_EN		0x00000008
#define HPU_TXCTRL_TXHSSAERCH0_EN	0x00000100
#define HPU_TXCTRL_TXHSSAERCH1_EN	0x00000200
#define HPU_TXCTRL_TXHSSAERCH2_EN	0x00000400
#define HPU_TXCTRL_TXHSSAERCH3_EN	0x00000800
#define HPU_TXCTRL_DEST_PAER		(0 << 4)
#define HPU_TXCTRL_DEST_HSSAER		(1 << 4)
#define HPU_TXCTRL_DEST_SPINN		(2 << 4)
#define HPU_TXCTRL_DEST_ALL		(3 << 4)
#define HPU_TXCTRL_ROUTE		BIT(6)
#define HPU_TXCTRL_IFACECFG_MASK        0xF7F
#define HPU_TXCTRL_TIMINGMODE_DELTA	(0 << 12)
#define HPU_TXCTRL_TIMINGMODE_ASAP	(1 << 12)
#define HPU_TXCTRL_TIMINGMODE_ABS	(2 << 12)
#define HPU_TXCTRL_TIMINGMODE_MASK	(3 << 12)

#define HPU_TXCTRL_REG_TS_20BIT		(0 << 20)
#define HPU_TXCTRL_REG_TS_24BIT		(1 << 20)
#define HPU_TXCTRL_REG_TS_28BIT		(2 << 20)
#define HPU_TXCTRL_REG_TS_32BIT		(3 << 20)
#define HPU_TXCTRL_REG_TS_MASK		(3 << 20)

#define HPU_TXCTRL_REG_SYNCTIME_1mS	(0 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_5mS	(1 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_10mS	(2 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_50mS	(3 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_100mS	(4 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_500mS	(5 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_1000mS	(6 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_2500mS	(7 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_5000mS	(8 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_10S	(9 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_25S	(10 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_50S	(11 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_100S	(12 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_250S	(13 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_500S	(14 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_DISABLE	(15 << 16)
#define HPU_TXCTRL_REG_SYNCTIME_MASK	(15 << 16)
#define HPU_TXCTRL_REG_FORCE_RESYNC	BIT(14)
#define HPU_TXCTRL_REG_FORCE_REARM	BIT(15)

#define HPU_SPINN_CTRL_REG_L_KEYEN	BIT(24)
#define HPU_SPINN_CTRL_REG_R_KEYEN	BIT(16)
#define HPU_SPINN_CTRL_REG_AUX_KEYEN	BIT(8)
#define HPU_SPINN_CTRL_REG_STOP		BIT(2)
#define HPU_SPINN_CTRL_REG_START	BIT(1)
#define HPU_SPINN_CTRL_REG_TO_DIS	BIT(0)

#define HPU_MSK_INT_RXFIFOFULL		0x004
#define HPU_MSK_INT_TSTAMPWRAPPED	0x080
#define HPU_MSK_INT_RXBUFFREADY		0x100
#define HPU_MSK_INT_GLBLRXERR_KO	0x00010000
#define HPU_MSK_INT_GLBLRXERR_RX	0x00020000
#define HPU_MSK_INT_GLBLRXERR_TO	0x00040000
#define HPU_MSK_INT_GLBLRXERR_OF	0x00080000

#define HPU_IOCTL_READTIMESTAMP			1
#define HPU_IOCTL_CLEARTIMESTAMP		2
#define HPU_IOCTL_READVERSION			3
/* 4 is not used anymore */
#define HPU_IOCTL_SETTIMESTAMP			7
#define HPU_IOCTL_GEN_REG			8
#define HPU_IOCTL_GET_RX_PS			9
#define HPU_IOCTL_SET_AUX_THRS			10
#define HPU_IOCTL_GET_AUX_THRS			11
#define HPU_IOCTL_GET_AUX_CNT0			12
#define HPU_IOCTL_GET_AUX_CNT1			13
#define HPU_IOCTL_GET_AUX_CNT2			14
#define HPU_IOCTL_GET_AUX_CNT3			15
#define HPU_IOCTL_GET_LOST_CNT			16
/* 17 is not used anymore */
#define HPU_IOCTL_SET_LOOP_CFG			18
/* 19 is not used anymore */
#define HPU_IOCTL_GET_TX_PS			20
#define HPU_IOCTL_SET_BLK_TX_THR		21
#define HPU_IOCTL_SET_BLK_RX_THR		22
#define HPU_IOCTL_SET_SPINN_KEYS		23
/* 24 is not used anymore */
#define HPU_IOCTL_SET_SPINN_STARTSTOP		25
#define HPU_IOCTL_SET_RX_INTERFACE		26
#define HPU_IOCTL_SET_TX_INTERFACE		27
#define HPU_IOCTL_SET_AXIS_LATENCY		28
#define HPU_IOCTL_GET_RX_PN			29
/* 30 is not used anymore */
#define HPU_IOCTL_SET_TS_MASK			31
#define HPU_IOCTL_SET_TX_TIMING_MODE		32
#define HPU_IOCTL_SET_TX_RESYNC_TIMER		33
#define HPU_IOCTL_RESET_TX_RESYNC_TIMER		34
#define HPU_IOCTL_FORCE_TX_RESYNC_TIMER		35
#define HPU_IOCTL_SET_SPINN_TX_MASK		36
#define HPU_IOCTL_SET_SPINN_RX_MASK		37
#define HPU_IOCTL_GET_HW_STATUS			38
#define HPU_IOCTL_SET_SPINN_KEYS_EN_EX		39

static struct debugfs_reg32 hpu_regs[] = {
	{"HPU_CTRL_REG",		0x00},
	{"HPU_RXDATA_REG",		0x08},
	{"HPU_RXTIME_REG",		0x0C},
	{"HPU_DMA_REG",			0x14},
	{"HPU_RAWSTAT_REG",		0x18},
	{"HPU_IRQ_REG",			0x1C},
	{"HPU_IRQMASK_REG",		0x20},
	{"HPU_WRAP_REG",		0x28},
	{"HPU_HSSAER_STAT_REG",		0x34},
	{"HPU_HSSAER_RXERR_REG",	0x38},
	{"HPU_HSSAER_RXMSK_REG",	0x3C},
	{"HPU_RXCTRL_REG",		0x40},
	{"HPU_TXCTRL_REG",		0x44},
	{"HPU_RXPAERCNFG_REG",		0x48},
	{"HPU_TXPAERCNFG_REG",		0x4C},
	{"HPU_IPCFONFIG_REG",		0x50},
	{"HPU_FIFOTHRESHOLD_REG",	0x54},
	{"HPU_VER_REG",			0x5C},
	{"HPU_AUX_RXCTRL_REG",		0x60},
	{"HPU_AUX_RX_ERR_REG",		0x64},
	{"HPU_AUX_RX_MSK_REG",		0x68},
	{"HPU_AUX_RX_ERR_THRS_REG", 	0x6C},
	{"HPU_AUX_RX_ERR_CH0_REG",	0x70},
	{"HPU_AUX_RX_ERR_CH1_REG",	0x74},
	{"HPU_AUX_RX_ERR_CH2_REG",	0x78},
	{"HPU_AUX_RX_ERR_CH3_REG",	0x7C},
	{"HPU_SPINN_START_KEY_REG",	0x80},
	{"HPU_SPINN_STOP_KEY_REG",	0x84},
	{"HPU_SPINN_TX_MASK_REG",	0x88},
	{"HPU_SPINN_RX_MASK_REG",	0x8c},
	{"HPU_TLAST_TIMEOUT",		0xa0},
	{"HPU_TLAST_COUNT",		0xa4},
	{"HPU_DATA_COUNT",		0xa8}
};


static short int test_dma = 0;
module_param(test_dma, short, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(test_dma, "Set to 1 to test DMA");

static int rx_ps = HPU_RX_POOL_SIZE;
static int rx_pn = HPU_RX_POOL_NUM;
static int rx_to = HPU_RX_TO_MS;

module_param(rx_ps, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(rx_ps, "RX Pool size");
module_param(rx_pn, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(rx_pn, "RX Pool num");
module_param(rx_to, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(rx_to, "RX DMA TimeOut in ms");

static int tx_ps = HPU_TX_POOL_SIZE;
static int tx_pn = HPU_TX_POOL_NUM;
static int tx_to = HPU_TX_TO_MS;

module_param(tx_ps, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(tx_ps, "TX Pool size");
module_param(tx_pn, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(tx_pn, "TX Pool num");
module_param(tx_to, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
MODULE_PARM_DESC(tx_to, "TX DMA TimeOut in ms");

typedef struct ip_regs {
       u32 reg_offset;
       char rw;
       u32 data;
} ip_regs_t;

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
	ROUTE_FIXED,
	ROUTE_MSG,
} hpu_tx_route_t;

typedef struct {
	hpu_interface_cfg_t cfg;
	hpu_tx_route_t route;
} hpu_tx_interface_ioctl_t;

enum rx_err { ko_err = 0, rx_err, to_err, of_err, nomeaning_err };

typedef struct aux_cnt {
	enum rx_err err;
	uint8_t cnt_val;
} aux_cnt_t;

typedef struct {
	u32 start;
	u32 stop;
} spinn_keys_t;

typedef struct {
	int enable_l;
	int enable_r;
	int enable_aux;
} spinn_keys_enable_t;

typedef enum {
	LOOP_NONE,
	LOOP_LNEAR,
	LOOP_LSPINN,
} spinn_loop_t;

typedef enum {
	MASK_20BIT,
	MASK_24BIT,
	MASK_28BIT,
	MASK_32BIT,
} hpu_timestamp_mask_t;

typedef enum {
	TIMINGMODE_DELTA,
	TIMINGMODE_ASAP,
	TIMINGMODE_ABS,
} hpu_tx_timing_mode_t;

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

typedef enum {
	EMPTY,
	ALMOST_EMPTY,
	FULL,
	ALMOST_FULL,
	NOT_EMPTY
} fifo_status_t;

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

struct hpu_priv;

struct hpu_buf {
	dma_addr_t phys;
	void *virt;
	int head_index, tail_index;
	dma_cookie_t cookie;
	struct hpu_priv *priv;
	struct list_head node;
};

struct hpu_dma_pool {
	spinlock_t spin_lock;
	struct mutex mutex_lock;
	struct completion completion;
	struct dma_pool *dma_pool;
	struct hpu_buf *ring;
	int buf_index;
	int filled;
	int ps;
	int pn;
	struct list_head pending_list;
	struct wait_queue_head wq;
	struct task_struct *thread;
	struct mutex list_lock;
};

enum fifo_status {
	FIFO_OK,
	FIFO_DRAINED,
	FIFO_OVERFLOW,
	FIFO_OVERFLOW_NOTIFIED,
	FIFO_STOPPED
};

struct hpu_priv {
	struct file_operations fops;
	struct cdev cdev;
	struct platform_device *pdev;
	dev_t devt;
	int id;
	unsigned int irq;
	struct mutex access_lock;
	unsigned int hpu_is_opened;
	void __iomem *reg_base;
	uint32_t ctrl_reg;
	uint32_t loop_bits;
	uint32_t rx_ctrl_reg;
	uint32_t tx_ctrl_reg;
	uint32_t rx_aux_ctrl_reg;
	uint32_t irq_msk;
	uint32_t spinn_ctrl_reg;
	struct dentry *debugfsdir;
	struct clk *clk;
	unsigned long clk_rate;
	spinlock_t irq_lock;
	int rx_suspended;

	/* dma */
	struct hpu_dma_pool dma_rx_pool;
	struct hpu_dma_pool dma_tx_pool;
	struct dma_chan *dma_rx_chan;
	struct dma_chan *dma_tx_chan;
	struct work_struct rx_housekeeping_work;
	size_t rx_blocking_threshold;
	size_t tx_blocking_threshold;
	enum fifo_status rx_fifo_status;
	unsigned long cnt_pktloss;
	unsigned long pkt_txed;
	unsigned long byte_txed;
	unsigned long pkt_rxed;
	unsigned long byte_rxed;
	unsigned long early_tlast;
	int axis_lat;
	unsigned int rx_tlast_count;
	unsigned int rx_data_count;
	bool thread_exit;
};

static inline void *dma_alloc_noncoherent(struct device *dev, size_t size,
		dma_addr_t *dma_handle, enum dma_data_direction dir, gfp_t gfp)
{
	struct page *page;
	void *virt = NULL;

	if (get_order(size) > 0) {
		page = alloc_pages(GFP_KERNEL | __GFP_COMP, get_order(size));
		if (page) {
			*dma_handle = dma_map_page_attrs(dev, page, 0, size, dir,
							 DMA_ATTR_NON_CONSISTENT |
							 DMA_ATTR_WRITE_COMBINE);
			virt = page_address(page);
		}
	} else {
		virt = kmalloc(size, GFP_KERNEL);
		if (virt)
			*dma_handle = dma_map_single_attrs(dev, virt, size, dir,
							   DMA_ATTR_NON_CONSISTENT |
							   DMA_ATTR_WRITE_COMBINE);
	}

	if (virt && dma_mapping_error(dev, *dma_handle)) {
		kfree(virt);
		return NULL;
	}

	return virt;
}

static inline void dma_free_noncoherent(struct device *dev, size_t size, void *virt,
		dma_addr_t dma_handle, enum dma_data_direction dir)
{
	if (get_order(size) > 0) {
		dma_unmap_page_attrs(dev, dma_handle, size, dir,
				     DMA_ATTR_NON_CONSISTENT |
				     DMA_ATTR_WRITE_COMBINE);
		__free_pages(virt_to_page(virt), get_order(size));
	} else {

		dma_unmap_single_attrs(dev, dma_handle, size, dir,
				       DMA_ATTR_NON_CONSISTENT |
				       DMA_ATTR_WRITE_COMBINE);
		kfree(virt);
	}
}

#define HPU_REG_LOG 0

#define HPU_DEBUGFS_ULONG(priv, x) debugfs_create_ulong(__stringify(x), 0444, \
				   priv->debugfsdir, &priv->x);

static struct dentry *hpu_debugfsdir = NULL;
static struct class *hpu_class = NULL;
static dev_t hpu_devt;
static DEFINE_IDA(hpu_ida);

static int hpu_rx_dma_submit_buffer(struct hpu_priv *priv, struct hpu_buf *buf);
static void hpu_rx_dma_submit_buffer_deferred(struct hpu_priv *priv, struct hpu_buf *buf);
static void hpu_rx_dma_wake_deferred(struct hpu_priv *priv);

static void hpu_dma_free_pool(struct hpu_priv *priv, struct hpu_dma_pool *hpu_pool,
	enum dma_data_direction dir);
static void hpu_do_set_axis_lat(struct hpu_priv *priv);
static void _hpu_do_set_axis_lat(struct hpu_priv *priv);

static void hpu_reg_write(struct hpu_priv *priv, u32 val, int offs)
{
	writel(val, priv->reg_base + offs);
#if HPU_REG_LOG
	printk(KERN_INFO "W32 0x%x = 0x%x\n", offs, val);
#endif
}

static u32 hpu_reg_read(struct hpu_priv *priv, int offs)
{
	u32 val;
	val = readl(priv->reg_base + offs);
#if HPU_REG_LOG
	printk(KERN_INFO "R32 0x%x == 0x%x\n", offs, val);
#endif
	return val;
}

static void hpu_clk_enable(struct hpu_priv *priv)
{
	if (!IS_ERR(priv->clk))
		clk_prepare_enable(priv->clk);
}

static void hpu_clk_disable(struct hpu_priv *priv)
{
	if (!IS_ERR(priv->clk))
		clk_disable_unprepare(priv->clk);
}

static void hpu_tx_dma_callback(void *_buffer)
{
	struct hpu_buf *buffer = _buffer;
	struct hpu_priv *priv = buffer->priv;

	/* mark as spare */
#ifdef HPU_DMA_STREAMING
	dma_sync_single_for_cpu(&priv->pdev->dev, buffer->phys,
				priv->dma_tx_pool.ps,
				DMA_TO_DEVICE);
#endif
	spin_lock(&priv->dma_tx_pool.spin_lock);
	priv->dma_tx_pool.filled--;
	complete(&priv->dma_tx_pool.completion);
	spin_unlock(&priv->dma_tx_pool.spin_lock);
}

/*
 * Drain data from RX DMA descriptors that has been already completed.
 * Must be called with RX lock held.
 */
static void hpu_drain_rx_dma(struct hpu_priv *priv)
{
	int finished = 0;
	__maybe_unused int ret;

	while (1) {
		spin_lock_bh(&priv->dma_rx_pool.spin_lock);
		finished = (priv->dma_rx_pool.filled == 0);
		if (!finished)
			priv->dma_rx_pool.filled--;
		spin_unlock_bh(&priv->dma_rx_pool.spin_lock);
		if (finished)
			break;
#ifdef HPU_DMA_DEFER_SUBMIT
		hpu_rx_dma_submit_buffer_deferred(priv,
						  &priv->dma_rx_pool.ring[priv->dma_rx_pool.buf_index]);
#else
		ret = hpu_rx_dma_submit_buffer(priv, &priv->dma_rx_pool.ring[priv->dma_rx_pool.buf_index]);
		if (ret)
			dev_err(&priv->pdev->dev, "DMA RX submit error %d while housekeeping\n", ret);
#endif
		/* forcefully advance index. 1pkt lost */
		priv->dma_rx_pool.buf_index =
			(priv->dma_rx_pool.buf_index + 1) &
		(priv->dma_rx_pool.pn - 1);

		BUG_ON(priv->dma_rx_pool.buf_index >= priv->dma_rx_pool.pn);

		priv->cnt_pktloss++;
#ifdef HPU_DMA_DEFER_SUBMIT
		hpu_rx_dma_wake_deferred(priv);
#else
		dma_async_issue_pending(priv->dma_rx_chan);
#endif
	}
}

static void _hpu_stop_dma_uh(struct hpu_priv *priv)
{
	/* Make the DMA stop ASAP */
	hpu_reg_write(priv, 1, HPU_TLAST_TIMEOUT);

	priv->ctrl_reg &= ~HPU_CTRL_ENDMA;
	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);
}

/* must be called with RX lock held */
static void _hpu_stop_dma_bh(struct hpu_priv *priv)
{
	ktime_t time;

	BUG_ON(priv->ctrl_reg & HPU_CTRL_ENDMA);

	/*
	 * Keep on draining RX DMA descriptor to make sure the IP is
	 * allowed to end up with a TLAST, otherwise it would not
	 * stop properly - wait for the IP to really stop.
	 */
	time = ktime_add_us(ktime_get(), 2000000); /* timeout 2 Sec */
	while (hpu_reg_read(priv, HPU_CTRL_REG) & HPU_CTRL_DMA_RUNNING) {
		if (ktime_compare(ktime_get(), time) > 0) {
			dev_err(&priv->pdev->dev, "Cannot stop IP (DMA running)\n");
			break;
		}
		hpu_drain_rx_dma(priv);
		msleep(5);
	}
}

static void hpu_start_dma(struct hpu_priv *priv)
{
	unsigned long flags;

	spin_lock_irqsave(&priv->irq_lock, flags);
	priv->ctrl_reg |= HPU_CTRL_ENDMA;

	/*
	 * Restore AXI latency setting. Note that hpu_do_set_axis_lat()
	 * does not apply the requested latency until the DMAEN bit is set,
	 * so we set it above.
	 */
	_hpu_do_set_axis_lat(priv);

	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);
	spin_unlock_irqrestore(&priv->irq_lock, flags);
}


/* must be called with RX lock held */
static void hpu_stop_dma(struct hpu_priv *priv)
{
	unsigned long flags;

	spin_lock_irqsave(&priv->irq_lock, flags);
	_hpu_stop_dma_uh(priv);
	spin_unlock_irqrestore(&priv->irq_lock, flags);

	_hpu_stop_dma_bh(priv);
}

/*
 * Perform a full RX-path flush by draining all data
 * Must be called with RX lock held.
 */
static void hpu_flush_rx(struct hpu_priv *priv)
{
	u16 rx_IP_tlast_count, rx_SW_tlast_count;
	u16 rx_IP_data_count, rx_SW_data_count;
	int ret;
	unsigned long flags;

	/*
	 * It doesn't matter if the upper half (_hpu_stop_dma_uh) has been
	 * already called or not.. This way it's always OK.
	 */
	hpu_stop_dma(priv);
	spin_lock_irqsave(&priv->irq_lock, flags);
	hpu_reg_write(priv,
		      priv->ctrl_reg | HPU_CTRL_FLUSH_RX_FIFO, HPU_CTRL_REG);
	spin_unlock_irqrestore(&priv->irq_lock, flags);
	/*
	 * We have flushed RX FIFO, so enabling DMA does not cause any effect on
	 * RX side. But we want to enable it not to block TX for too much time
	 */
	hpu_start_dma(priv);

	while (1) {
		hpu_drain_rx_dma(priv);

		rx_IP_tlast_count = hpu_reg_read(priv, HPU_TLAST_COUNT) >> 16;
		rx_IP_data_count = hpu_reg_read(priv, HPU_DATA_COUNT) >> 16;

		spin_lock_bh(&priv->dma_rx_pool.spin_lock);
		rx_SW_tlast_count = priv->rx_tlast_count;
		rx_SW_data_count = priv->rx_data_count;
		spin_unlock_bh(&priv->dma_rx_pool.spin_lock);

		/*
		 * We check for both TLAST and DATA count:
		 * Checking TLAST should be enough because the IP is stopped and
		 * the HW guarantees that the last tranfer has been TLASTed
		 */
		if (rx_IP_tlast_count == rx_SW_tlast_count) {
			if (rx_IP_data_count != rx_SW_data_count)
				dev_err(&priv->pdev->dev, "Flush error (%d %d %d %d)\n",
					rx_IP_tlast_count, rx_SW_tlast_count,
					rx_IP_data_count, rx_SW_data_count);
			break;
		}

		ret = wait_for_completion_timeout(&priv->dma_rx_pool.completion,
									msecs_to_jiffies(500));
		if (unlikely(ret == 0)) {
			dev_err(&priv->pdev->dev, "RX DMA timed out while flushing(%d %d %d %d)\n",
				rx_IP_tlast_count, rx_SW_tlast_count,
				rx_IP_data_count, rx_SW_data_count);
			break;
		}
	}
}

static void hpu_rx_housekeeping(struct work_struct *work)
{
	struct hpu_priv *priv = container_of(work, struct hpu_priv,
					     rx_housekeeping_work);
	enum fifo_status state;

	dev_dbg(&priv->pdev->dev, "RX housekeeping ..\n");
	mutex_lock(&priv->dma_rx_pool.mutex_lock);

	/* data has been already drained */
	state = READ_ONCE(priv->rx_fifo_status);
	if (state == FIFO_OK || state == FIFO_DRAINED || state == FIFO_STOPPED) {
		mutex_unlock(&priv->dma_rx_pool.mutex_lock);
		return;
	}

	hpu_flush_rx(priv);

	if (state == FIFO_OVERFLOW) {
		WRITE_ONCE(priv->rx_fifo_status, FIFO_DRAINED);
		/*
		 * In theory the reader shouldn't be blocked waiting, because
		 * if fifo was full, then DMA ring should be quite crowder,
		 * but just in case... (make sure the read() can bail out
		 * early reporting failure...
		 */
		complete(&priv->dma_rx_pool.completion);

	} else {
		BUG_ON(state != FIFO_OVERFLOW_NOTIFIED);
		WRITE_ONCE(priv->rx_fifo_status, FIFO_STOPPED);
	}
	mutex_unlock(&priv->dma_rx_pool.mutex_lock);
}

static void hpu_rx_dma_callback(void *_buffer, const struct dmaengine_result *result)
{
	u32 word;
	struct hpu_buf *buffer = _buffer;
	struct hpu_priv *priv = buffer->priv;
	int len, rawlen = priv->dma_rx_pool.ps - result->residue;

	dev_dbg(&priv->pdev->dev, "RX DMA cb\n");

	/*
	 * when HPU prodive odd number of data it means that it has produced
	 * an early TLAST sending also a dummy data, so we need to discard it
	 */
	len = rawlen;
#ifdef HPU_DMA_STREAMING
	dma_sync_single_for_cpu(&priv->pdev->dev, buffer->phys, priv->dma_rx_pool.ps,
				DMA_FROM_DEVICE);
#endif
	if ((len / 4) & 1) {
		priv->early_tlast++;
		len -= 4;
		word = ((u32*)buffer->virt)[len / 4];
		if (unlikely(word != 0xf0cacc1a))
			dev_err(&priv->pdev->dev, "Got early TLAST, but no magic word\n");
	}
	priv->byte_rxed += len;
	priv->pkt_rxed++;

	spin_lock(&priv->dma_rx_pool.spin_lock);
	priv->rx_tlast_count = (priv->rx_tlast_count + 1) & 0xffff;
	priv->rx_data_count = (priv->rx_data_count + rawlen / 4) & 0xffff;
	priv->dma_rx_pool.filled++;
	buffer->tail_index = len;

	if (priv->dma_rx_pool.filled == 1) {
		dev_dbg(&priv->pdev->dev, "RX DMA waking up reader\n");
		/* ring was empty. wake reader, if any.. */
		complete(&priv->dma_rx_pool.completion);
	}
	spin_unlock(&priv->dma_rx_pool.spin_lock);
}

static ssize_t hpu_chardev_write(struct file *fp, const char __user *buf,
				 size_t lenght, loff_t *offset)
{
	struct dma_async_tx_descriptor *dma_desc;
	struct hpu_buf *dma_buf;
	dma_cookie_t cookie;
	size_t copy;
	int ret;
	size_t i = 0;
	int count = 0;
	struct hpu_priv *priv = fp->private_data;

	/* allow only pairs TS+VAL that is 4+4 bytes */
	if (lenght % 8)
		return -EINVAL;

#if LINUX_VERSION_CODE < KERNEL_VERSION(5,0,0)
	if (!access_ok(VERIFY_WRITE, buf, lenght))
#else
	if (!access_ok(buf, lenght))
#endif
		return -EFAULT;

	mutex_lock(&priv->dma_tx_pool.mutex_lock);
	while (lenght) {
		copy = min_t(size_t, priv->dma_tx_pool.ps, lenght);
		dma_buf = &priv->dma_tx_pool.ring[priv->dma_tx_pool.buf_index];

		while (1) {
			spin_lock_bh(&priv->dma_tx_pool.spin_lock);

			/* if the buffer is free, then we are OK */
			if (priv->dma_tx_pool.filled < priv->dma_tx_pool.pn)
				/* unlock in outer block */
				break;
			/*
			 * If we've copied enough wrt blocking threshold, then
			 * return now..
			 */
			if (i >= priv->tx_blocking_threshold) {
				spin_unlock_bh(&priv->dma_tx_pool.spin_lock);
				goto exit;
			}

			/* drain away any completion leftover */
			try_wait_for_completion(&priv->dma_tx_pool.completion);
			spin_unlock_bh(&priv->dma_tx_pool.spin_lock);

			/* wait for more room */
			ret = wait_for_completion_killable_timeout(&priv->dma_tx_pool.completion,
								   msecs_to_jiffies(tx_to));
			if (unlikely(ret == 0)) {
				dev_err(&priv->pdev->dev, "TX DMA timed out\n");
				mutex_unlock(&priv->dma_tx_pool.mutex_lock);
				return -ETIMEDOUT;
			} else if (unlikely(ret < 0)) {
				mutex_unlock(&priv->dma_tx_pool.mutex_lock);
				return ret;
			}
			dev_dbg(&priv->pdev->dev, "resuming TX\n");
		}

		priv->dma_tx_pool.filled++;
		spin_unlock_bh(&priv->dma_tx_pool.spin_lock);

		if (__copy_from_user(dma_buf->virt, buf + i, copy)) {
			dev_err(&priv->pdev->dev, "failed copying from user\n");
			mutex_unlock(&priv->dma_tx_pool.mutex_lock);
			return -EINVAL;
		}

		/* FIXME: shall we use sg ? */
		dma_desc = dmaengine_prep_slave_single(priv->dma_tx_chan,
						       dma_buf->phys,
						       copy,
						       DMA_MEM_TO_DEV,
						       DMA_CTRL_ACK |
						       DMA_PREP_INTERRUPT);
		dma_desc->callback = hpu_tx_dma_callback;
		dma_desc->callback_param = dma_buf;
#ifdef HPU_DMA_STREAMING
		dma_sync_single_for_device(&priv->pdev->dev, dma_buf->phys,
				   priv->dma_tx_pool.ps, DMA_TO_DEVICE);
#endif
		cookie = dmaengine_submit(dma_desc);
		priv->pkt_txed++;
		priv->byte_txed += copy;

		i += copy;
		lenght -= copy;

		if (count++ > (priv->dma_tx_pool.pn / 2)) {
			count = 0;
			dma_async_issue_pending(priv->dma_tx_chan);
		}

		priv->dma_tx_pool.buf_index = (priv->dma_tx_pool.buf_index + 1)
			& (priv->dma_tx_pool.pn - 1);
	}
exit:
	mutex_unlock(&priv->dma_tx_pool.mutex_lock);
	if (count)
		dma_async_issue_pending(priv->dma_tx_chan);

	return i;
}

/* those three func are called with irq lock held */
static void hpu_rx_suspend(struct hpu_priv *priv)
{
	priv->rx_suspended = 1;
	hpu_reg_write(priv, 0, HPU_RXCTRL_REG);
	hpu_reg_write(priv, 0, HPU_AUX_RXCTRL_REG);
	priv->ctrl_reg &= ~HPU_CTRL_LOOP_LNEAR;
	hpu_reg_write(priv, priv->ctrl_reg , HPU_CTRL_REG);
}

static void hpu_rx_resume(struct hpu_priv *priv)
{
	priv->rx_suspended = 0;
	hpu_reg_write(priv, priv->rx_ctrl_reg, HPU_RXCTRL_REG);
	hpu_reg_write(priv, priv->rx_aux_ctrl_reg, HPU_AUX_RXCTRL_REG);
	priv->ctrl_reg |= priv->loop_bits;
	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);
}

static int hpu_rx_is_suspended(struct hpu_priv *priv)
{
	return priv->rx_suspended;
}

static ssize_t hpu_chardev_read(struct file *fp, char *buf, size_t length,
				loff_t *offset)
{
	int ret;
	__maybe_unused int ret2;
	size_t copy;
	int index;
	size_t buf_count;
	struct hpu_buf *item;
	unsigned long flags;
	size_t read = 0;
	int submitted = 0;
	struct hpu_priv *priv = fp->private_data;
#if LINUX_VERSION_CODE < KERNEL_VERSION(5,0,0)
	if (!access_ok(VERIFY_READ, buf, length))
#else
	if (!access_ok(buf, length))
#endif
		return -EFAULT;

	dev_dbg(&priv->pdev->dev, "----tot to read %zu\n", length);

	mutex_lock(&priv->dma_rx_pool.mutex_lock);

	while (length > 0) {
		/*
		 * Wait for some data to be available - this part must lock
		 * against the DMA cb, in order to correctly handle filled count
		 * and completion wakeup
		 */
		while (1) {
			switch(READ_ONCE(priv->rx_fifo_status)) {
			case FIFO_OK:
				break;

			case FIFO_OVERFLOW:
				/*
				 * FIFO-full, nobody cared yet. Bail out failing
				 * and mark as 'notified'.
				 */
				WRITE_ONCE(priv->rx_fifo_status,
					   FIFO_OVERFLOW_NOTIFIED);
				goto error_rx_fifo_full;
				break;

			case FIFO_DRAINED:
				/*
				 * FIFO-full, already drained. Bail out failing
				 * but next time we'll be OK.
				 */
				WRITE_ONCE(priv->rx_fifo_status, FIFO_STOPPED);
				goto error_rx_fifo_full;
				break;

			case FIFO_OVERFLOW_NOTIFIED:
				/*
				 * FIFO-full, we had already notified this, but
				 * no-one has drained the fifo yet. Do it now,
				 * then we are OK and we can go on without fail.
				 */
				hpu_flush_rx(priv);

				/* fall-through */
			case FIFO_STOPPED:
				/*
				 * An overflow has been fixed. We have to
				 * restart the RX machanism, then we can go on.
				 */
				spin_lock_irqsave(&priv->irq_lock, flags);
				hpu_rx_resume(priv);

				/* Re-enable RX FIFO full interrupt */
				priv->irq_msk |= HPU_MSK_INT_RXFIFOFULL;
				hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);

				WRITE_ONCE(priv->rx_fifo_status, FIFO_OK);
				spin_unlock_irqrestore(&priv->irq_lock, flags);
				break;
			}
			/*
			 * Quoting Documentation/dmaengine/client.txt:
			 * Note that callbacks will always be invoked from the DMA
			 * engines tasklet, never from interrupt context.
			 */
			spin_lock_bh(&priv->dma_rx_pool.spin_lock);


			/* if there is data, then do not wait .. */
			if (priv->dma_rx_pool.filled > 0) {
				spin_unlock_bh(&priv->dma_rx_pool.spin_lock);
				break;
			}

			/* if we have read enough not to block then return now */
			if (read >= priv->rx_blocking_threshold) {
				spin_unlock_bh(&priv->dma_rx_pool.spin_lock);
				mutex_unlock(&priv->dma_rx_pool.mutex_lock);
				return read;
			}

			/* drain away any completion leftover */
			try_wait_for_completion(&priv->dma_rx_pool.completion);
			spin_unlock_bh(&priv->dma_rx_pool.spin_lock);

			dev_dbg(&priv->pdev->dev, "wait for dma\n");
			ret = wait_for_completion_killable_timeout(&priv->dma_rx_pool.completion,
									msecs_to_jiffies(rx_to));
			if (unlikely(ret < 0)) {
				mutex_unlock(&priv->dma_rx_pool.mutex_lock);
				return ret;
			} else if (unlikely(ret == 0)) {
				dev_err(&priv->pdev->dev, "DMA timed out\n");
				mutex_unlock(&priv->dma_rx_pool.mutex_lock);
				return -ETIMEDOUT;
			}
		}

		index = priv->dma_rx_pool.buf_index;
		item = &priv->dma_rx_pool.ring[index];
		dev_dbg(&priv->pdev->dev, "reading dma descriptor %d\n", index);

		/* data still in buf */
		buf_count = item->tail_index - item->head_index;
		copy = min(length, buf_count);

		dev_dbg(&priv->pdev->dev, "going to read %zu bytes from offset %d\n",
			length, item->head_index);

		ret = __copy_to_user(buf + read,
				     item->virt + item->head_index, copy);
		if (ret < 0) {
			dev_warn(&priv->pdev->dev, "failed to copy from userspace");
			break;
		}
		/* if ret > 0, then it is the number of _uncopied_ bytes */
		copy -= ret;

		BUG_ON((item->head_index + copy) > item->tail_index);
		if ((item->head_index + copy) == item->tail_index) {
			/* Buffer fully read. */
			dev_dbg(&priv->pdev->dev, "fully consumed\n");

			/* update filled count locking against DMA cb */
			spin_lock_bh(&priv->dma_rx_pool.spin_lock);
			priv->dma_rx_pool.filled--;
			spin_unlock_bh(&priv->dma_rx_pool.spin_lock);

			/* resubmit DMA buffer */
#ifdef HPU_DMA_DEFER_SUBMIT
			hpu_rx_dma_submit_buffer_deferred(priv, &priv->dma_rx_pool.ring[index]);
#else
			ret2 = hpu_rx_dma_submit_buffer(priv, &priv->dma_rx_pool.ring[index]);
			if (ret2)
				dev_err(&priv->pdev->dev,
					"DMA RX submit error %d while reading\n",
                                       ret2);
#endif
			submitted++;

			priv->dma_rx_pool.buf_index = (priv->dma_rx_pool.buf_index + 1)
				& (priv->dma_rx_pool.pn - 1);
			BUG_ON(priv->dma_rx_pool.buf_index >= priv->dma_rx_pool.pn);
			if (submitted == priv->dma_rx_pool.pn / 3) {
#ifdef HPU_DMA_DEFER_SUBMIT
				hpu_rx_dma_wake_deferred(priv);
#else
				dma_async_issue_pending(priv->dma_rx_chan);
#endif
				submitted = 0;
			}
		} else {
			/* buffer partially consumed, advance in-buffer index */
			item->head_index += copy;
			BUG_ON(item->head_index >= item->tail_index);
			dev_dbg(&priv->pdev->dev, "partially consumed, up to %d\n",
				item->head_index);
		}

		read += copy;
		length -= copy;
		BUG_ON(length < 0);
		dev_dbg(&priv->pdev->dev, "read %zu, rem %zu\n", read, length);

		/* partially copied */
		if (ret)
			break;
	}

	if (submitted) {
#ifdef HPU_DMA_DEFER_SUBMIT
		hpu_rx_dma_wake_deferred(priv);
#else
		dma_async_issue_pending(priv->dma_rx_chan);
#endif
	}
	dev_dbg(&priv->pdev->dev, "----END read\n");

	mutex_unlock(&priv->dma_rx_pool.mutex_lock);
	return read;

error_rx_fifo_full:
	mutex_unlock(&priv->dma_rx_pool.mutex_lock);

	return -ENOMEM;
}

static int hpu_dma_init(struct hpu_priv *priv)
{
	priv->dma_rx_chan = dma_request_slave_channel(&priv->pdev->dev, "rx");

	if (IS_ERR_OR_NULL(priv->dma_rx_chan)) {
		dev_err(&priv->pdev->dev, "Can't bind RX DMA chan\n");
		priv->dma_rx_chan = NULL;
		return -ENODEV;
	}

	/*
	 * DMA RX channel is mandatory, while TX is not. We assume RX and TX
	 * CHs are two CHs from the same DMA controller, so we just set the
	 * mask as per the RX channel
	 */
	dma_set_mask_and_coherent(&priv->pdev->dev,
				  dma_get_mask(priv->dma_rx_chan->device->dev));

	priv->dma_tx_chan = dma_request_slave_channel(&priv->pdev->dev, "tx");

	if (IS_ERR_OR_NULL(priv->dma_tx_chan)) {
		priv->dma_tx_chan = NULL;
		dev_notice(&priv->pdev->dev, "Can't bind TX DMA chan: write disabled\n");
	}

	priv->fops.write = priv->dma_tx_chan ? hpu_chardev_write : NULL;

	return 0;
}

static void hpu_dma_release(struct hpu_priv *priv)
{
	if (priv->dma_rx_chan) {
		dma_release_channel(priv->dma_rx_chan);
		hpu_dma_free_pool(priv, &priv->dma_rx_pool, DMA_FROM_DEVICE);
	}

	if (priv->dma_tx_chan) {
		dma_release_channel(priv->dma_tx_chan);
		hpu_dma_free_pool(priv, &priv->dma_tx_pool, DMA_TO_DEVICE);
	}
}

static int hpu_dma_alloc_pool(struct hpu_priv *priv,
			      struct hpu_dma_pool *hpu_pool,
			      enum dma_data_direction dir)
{
	int i;
#ifndef HPU_DMA_STREAMING
	hpu_pool->dma_pool = dma_pool_create(HPU_DRIVER_NAME, &priv->pdev->dev,
					 hpu_pool->ps, 4, 0);

	if (!hpu_pool->dma_pool) {
		dev_err(&priv->pdev->dev, "Error creating DMA pool\n");
		return -ENOMEM;
	}
#endif
	hpu_pool->ring = kmalloc(hpu_pool->pn * sizeof(struct hpu_buf), GFP_KERNEL);
	if (!(hpu_pool->ring)) {
		dev_err(&priv->pdev->dev, "Can't alloc mem for dma ring\n");
		return -ENOMEM;
	}

	for (i = 0; i < hpu_pool->pn; i++) {
#ifdef HPU_DMA_STREAMING
	        hpu_pool->ring[i].virt = dma_alloc_noncoherent(&priv->pdev->dev,
							       hpu_pool->ps,
							       &hpu_pool->ring[i].phys,
							       dir, GFP_KERNEL);
#else
		hpu_pool->ring[i].virt = (unsigned char *)
			dma_pool_alloc(hpu_pool->dma_pool, GFP_KERNEL,
				       &hpu_pool->ring[i].phys);
#endif
		if (!hpu_pool->ring[i].virt)
			return -ENOMEM;
	}

	for (i = 0; i < hpu_pool->pn; i++) {
		hpu_pool->ring[i].priv = priv;
		hpu_pool->ring[i].tail_index = 0;
		hpu_pool->ring[i].head_index = 0;
	}

	hpu_pool->buf_index = 0;
	hpu_pool->filled = 0;

	return 0;
}

static void hpu_dma_free_pool(struct hpu_priv *priv,
			      struct hpu_dma_pool *hpu_pool,
			      enum dma_data_direction dir)
{
	int i;

	for (i = 0; i < hpu_pool->pn; i++) {
#ifdef HPU_DMA_STREAMING
		dma_free_noncoherent(&priv->pdev->dev, hpu_pool->ps, hpu_pool->ring[i].virt,
				     hpu_pool->ring[i].phys, dir);
#else
		dma_pool_free(hpu_pool->dma_pool,
			      hpu_pool->ring[i].virt, hpu_pool->ring[i].phys);
#endif
		hpu_pool->ring[i].virt = NULL;
	}

#ifndef HPU_DMA_STREAMING
	dma_pool_destroy(hpu_pool->dma_pool);
#endif
	hpu_pool->dma_pool = NULL;
	kfree(hpu_pool->ring);
	hpu_pool->ring = NULL;
}

static void __maybe_unused hpu_rx_dma_thread_terminate(struct hpu_priv *priv)
{
	priv->thread_exit = 1;
	wake_up(&priv->dma_rx_pool.wq);
	kthread_stop(priv->dma_rx_pool.thread);
}

static int hpu_rx_dma_submit_thread(void *data)
{
	struct hpu_buf *buf, *tmp;
	struct hpu_priv *priv = data;
	int submitted = 0;

	while (true) {
		wait_event(priv->dma_rx_pool.wq,
			   (!list_empty(&priv->dma_rx_pool.pending_list) ||
			    priv->thread_exit));

		if (priv->thread_exit)
			break;

		mutex_lock(&priv->dma_rx_pool.list_lock);
		list_for_each_entry_safe(buf, tmp, &priv->dma_rx_pool.pending_list, node) {
			list_del(&buf->node);
			mutex_unlock(&priv->dma_rx_pool.list_lock);
			hpu_rx_dma_submit_buffer(priv, buf);
			submitted++;
			if (submitted == priv->dma_rx_pool.pn / 3) {
				dma_async_issue_pending(priv->dma_rx_chan);
				submitted = 0;
			}
			mutex_lock(&priv->dma_rx_pool.list_lock);
		}
		mutex_unlock(&priv->dma_rx_pool.list_lock);
		if (submitted)
			dma_async_issue_pending(priv->dma_rx_chan);
		submitted = 0;
	}

	return 0;
}

static int __maybe_unused hpu_rx_dma_thread_create(struct hpu_priv *priv)
{
	priv->thread_exit = 0;
	init_waitqueue_head(&priv->dma_rx_pool.wq);
	mutex_init(&priv->dma_rx_pool.list_lock);
	INIT_LIST_HEAD(&priv->dma_rx_pool.pending_list);
	priv->dma_rx_pool.thread = kthread_run(hpu_rx_dma_submit_thread,
					       priv, "HPU_%pa_DMA_helper",
					       &priv->reg_base);

	return 0;
}

static void __maybe_unused hpu_rx_dma_submit_buffer_deferred(struct hpu_priv *priv,
					      struct hpu_buf *buf)
{
	mutex_lock(&priv->dma_rx_pool.list_lock);
	list_add_tail(&buf->node, &priv->dma_rx_pool.pending_list);
	mutex_unlock(&priv->dma_rx_pool.list_lock);
}

static void __maybe_unused hpu_rx_dma_wake_deferred(struct hpu_priv *priv)
{
	wake_up(&priv->dma_rx_pool.wq);
}

static int hpu_rx_dma_submit_buffer(struct hpu_priv *priv, struct hpu_buf *buf)
{
	struct dma_async_tx_descriptor *dma_desc;
	dma_cookie_t cookie;

	dma_desc = dmaengine_prep_slave_single(priv->dma_rx_chan,
					       buf->phys,
					       priv->dma_rx_pool.ps,
					       DMA_DEV_TO_MEM,
					       DMA_CTRL_ACK |
					       DMA_PREP_INTERRUPT);

	if (!dma_desc)
		return -ENOMEM;

	dma_desc->callback_result = hpu_rx_dma_callback;
	dma_desc->callback_param = buf;
#ifdef HPU_DMA_STREAMING
	dma_sync_single_for_device(&priv->pdev->dev, buf->phys,
				   priv->dma_rx_pool.ps, DMA_FROM_DEVICE);
#endif
	cookie = dmaengine_submit(dma_desc);
	buf->cookie = cookie;
	/* this buffer is new and has to be fully read */
	buf->head_index = 0;

	return dma_submit_error(cookie);
}

static int hpu_rx_dma_submit_pool(struct hpu_priv *priv)
{
	int i;
	int ret;

	for (i = 0; i < priv->dma_rx_pool.pn; i++) {
		ret = hpu_rx_dma_submit_buffer(priv, &priv->dma_rx_pool.ring[i]);
		if (ret)
			break;
	}

	return ret;
}

static int hpu_spinn_startstop(struct hpu_priv *priv, int start)
{
	if (start != !!start) {
		dev_notice(&priv->pdev->dev, "Invalid start value\n");
		return -EINVAL;
	}

	if (start) {
		dev_dbg(&priv->pdev->dev, "Forcing SPINN start\n");
		hpu_reg_write(priv, priv->spinn_ctrl_reg |
			      HPU_SPINN_CTRL_REG_START,
			      HPU_SPINN_CTRL_REG);
	} else {
		dev_dbg(&priv->pdev->dev, "Forcing SPINN stop\n");
		hpu_reg_write(priv, priv->spinn_ctrl_reg |
			      HPU_SPINN_CTRL_REG_STOP,
			      HPU_SPINN_CTRL_REG);
	}

	return 0;
}

static int hpu_spinn_set_keys(struct hpu_priv *priv, u32 start, u32 stop)
{
	if (start == stop) {
		dev_notice(&priv->pdev->dev, "Start and stop keys must differ\n");
		return -EINVAL;
	}

	hpu_reg_write(priv, start, HPU_SPINN_START_KEY_REG);
	hpu_reg_write(priv, stop, HPU_SPINN_STOP_KEY_REG);

	dev_dbg(&priv->pdev->dev, "Setting keys START:0x%x STOP:0x%x\n",
		start, stop);

	return 0;
}

static int hpu_spinn_keys_enable(struct hpu_priv *priv,
				 int enable_l, int enable_r, int enable_aux)
{
	if (enable_l != !!enable_l) {
		dev_notice(&priv->pdev->dev, "Invalid value for enable_l\n");
		return -EINVAL;
	}
	if (enable_r != !!enable_r) {
		dev_notice(&priv->pdev->dev, "Invalid value for enable_r\n");
		return -EINVAL;
	}
	if (enable_aux != !!enable_aux) {
		dev_notice(&priv->pdev->dev, "Invalid value for enable_aux\n");
		return -EINVAL;
	}

	priv->spinn_ctrl_reg &= ~(HPU_SPINN_CTRL_REG_AUX_KEYEN |
				  HPU_SPINN_CTRL_REG_L_KEYEN |
				  HPU_SPINN_CTRL_REG_R_KEYEN);
	if (enable_aux)
		priv->spinn_ctrl_reg |= HPU_SPINN_CTRL_REG_AUX_KEYEN;
	if (enable_l)
		priv->spinn_ctrl_reg |= HPU_SPINN_CTRL_REG_L_KEYEN;
	if (enable_r)
		priv->spinn_ctrl_reg |= HPU_SPINN_CTRL_REG_R_KEYEN;

	hpu_reg_write(priv, priv->spinn_ctrl_reg, HPU_SPINN_CTRL_REG);

	dev_dbg(&priv->pdev->dev, "Key enabled: l:%d, r:%d, aux:%d\n",
		enable_l, enable_r, enable_aux);

	return 0;
}

static int hpu_set_rx_interface(struct hpu_priv *priv,
				hpu_interface_t interf, hpu_interface_cfg_t cfg)
{
	unsigned long flags;
	int ret = 0;
	u32 bitfield = 0;
	u32 mask = 0xffff;

	if (cfg.hssaer[0])
		bitfield = HPU_RXCTRL_RXHSSAER_EN | HPU_RXCTRL_RXHSSAERCH0_EN;
	if (cfg.hssaer[1])
		bitfield |= HPU_RXCTRL_RXHSSAER_EN | HPU_RXCTRL_RXHSSAERCH1_EN;
	if (cfg.hssaer[2])
		bitfield |= HPU_RXCTRL_RXHSSAER_EN | HPU_RXCTRL_RXHSSAERCH2_EN;
	if (cfg.hssaer[3])
		bitfield |= HPU_RXCTRL_RXHSSAER_EN | HPU_RXCTRL_RXHSSAERCH3_EN;
	if (cfg.gtp)
		bitfield |= HPU_RXCTRL_RXGTP_EN;
	if (cfg.paer)
		bitfield |= HPU_RXCTRL_RXPAER_EN;
	if (cfg.spinn) {
		bitfield |= HPU_RXCTRL_SPINN_EN;
	}

	spin_lock_irqsave(&priv->irq_lock, flags);
	switch (interf) {
	case INTERFACE_EYE_R:
		bitfield <<= 16;
		mask <<= 16;
		/* fall through */
	case INTERFACE_EYE_L:
		priv->rx_ctrl_reg &= ~mask;
		priv->rx_ctrl_reg |= bitfield;
		if (!hpu_rx_is_suspended(priv))
			hpu_reg_write(priv, priv->rx_ctrl_reg, HPU_RXCTRL_REG);
		dev_dbg(&priv->pdev->dev, "RXCTRL reg 0x%x\n", bitfield);
		break;
	case INTERFACE_AUX:
		priv->rx_aux_ctrl_reg = bitfield;
		if (!hpu_rx_is_suspended(priv))
			hpu_reg_write(priv, priv->rx_aux_ctrl_reg, HPU_AUX_RXCTRL_REG);
		dev_dbg(&priv->pdev->dev, "AUXRXCTRL reg 0x%x\n", bitfield);
		break;
	default:
		ret = -EINVAL;
		break;
	}
	spin_unlock_irqrestore(&priv->irq_lock, flags);

	return ret;
}

static int hpu_set_tx_interface(struct hpu_priv *priv,
				hpu_interface_cfg_t cfg, hpu_tx_route_t route)
{
	u32 static_route;
	u32 reg = 0;
	int count = 0;

	/* GTP seems not supported: it has been replace by spinn in register */
	if (cfg.gtp) {
		dev_notice(&priv->pdev->dev, "gtp TX is not supported\n");
		return -EINVAL;
	}

	if (cfg.hssaer[0])
		reg = HPU_TXCTRL_TXHSSAERCH0_EN;
	if (cfg.hssaer[1])
		reg |= HPU_TXCTRL_TXHSSAERCH1_EN;
	if (cfg.hssaer[2])
		reg |= HPU_TXCTRL_TXHSSAERCH2_EN;
	if (cfg.hssaer[3])
		reg |= HPU_TXCTRL_TXHSSAERCH3_EN;

	/* at least on SAER ch has been enabled -> SAER enabled */
	if (reg) {
		reg |= HPU_TXCTRL_TXHSSAER_EN;
		static_route = HPU_TXCTRL_DEST_HSSAER;
		count = 1;
	}
	if (cfg.paer) {
		reg |= HPU_TXCTRL_TXPAER_EN;
		static_route = HPU_TXCTRL_DEST_PAER;
		count++;
	}
	if (cfg.spinn) {
		reg |= HPU_TXCTRL_SPINN_EN;
		static_route = HPU_TXCTRL_DEST_SPINN;
		count++;
	}

	if (route == ROUTE_FIXED) {
		switch (count) {
		case 0:
			break;
		case 1:
			reg |= static_route | HPU_TXCTRL_ROUTE;
			break;
		case 2:
			dev_notice(&priv->pdev->dev,
				   "Either one or all destination can be selected\n");
			return -EINVAL;
			break;
		case 3:
			reg |= HPU_TXCTRL_DEST_ALL;
			break;
		}
	}
	priv->tx_ctrl_reg &= ~HPU_TXCTRL_IFACECFG_MASK;
	priv->tx_ctrl_reg |= reg;
	dev_dbg(&priv->pdev->dev, "writing TX CTRL REG: 0x%x\n", priv->tx_ctrl_reg);
	hpu_reg_write(priv, priv->tx_ctrl_reg, HPU_TXCTRL_REG);

	return 0;
}

static int hpu_set_ts_mask(struct hpu_priv *priv, hpu_timestamp_mask_t ts_mask)
{
	u32 reg = 0;

	switch (ts_mask) {
	case MASK_20BIT:
		reg = HPU_TXCTRL_REG_TS_20BIT;
		break;

	case MASK_24BIT:
		reg = HPU_TXCTRL_REG_TS_24BIT;
		break;

	case MASK_28BIT:
		reg = HPU_TXCTRL_REG_TS_28BIT;
		break;

	case MASK_32BIT:
		reg = HPU_TXCTRL_REG_TS_32BIT;
		break;
	default:
		return -EINVAL;
	}

	priv->tx_ctrl_reg &= ~HPU_TXCTRL_REG_TS_MASK;
	priv->tx_ctrl_reg |= reg;

	hpu_reg_write(priv, priv->tx_ctrl_reg, HPU_TXCTRL_REG);
	dev_dbg(&priv->pdev->dev, "writing TX CTRL REG: 0x%x\n", priv->tx_ctrl_reg);
	return 0;
}

static void hpu_reset_tx_resync_timer(struct hpu_priv *priv)
{
	hpu_reg_write(priv, priv->tx_ctrl_reg |
		      HPU_TXCTRL_REG_FORCE_REARM, HPU_TXCTRL_REG);
	dev_dbg(&priv->pdev->dev, "HPU_TXCTRL_REG_FORCE_REARM\n");
}

static void hpu_force_tx_resync_timer(struct hpu_priv *priv)
{
	hpu_reg_write(priv, priv->tx_ctrl_reg |
		      HPU_TXCTRL_REG_FORCE_RESYNC, HPU_TXCTRL_REG);
	dev_dbg(&priv->pdev->dev, "HPU_TXCTRL_REG_FORCE_RESYNC\n");
}

static int hpu_set_tx_timing_mode(struct hpu_priv *priv,
				  hpu_tx_timing_mode_t mode)
{
	u32 reg = 0;

	switch (mode) {
	case TIMINGMODE_DELTA:
		reg = HPU_TXCTRL_TIMINGMODE_DELTA;
		break;
	case TIMINGMODE_ASAP:
		reg = HPU_TXCTRL_TIMINGMODE_ASAP;
		break;
	case TIMINGMODE_ABS:
		hpu_force_tx_resync_timer(priv);
		reg = HPU_TXCTRL_TIMINGMODE_ABS;
		break;
	default:
		return -EINVAL;
	}

	priv->tx_ctrl_reg &= ~HPU_TXCTRL_TIMINGMODE_MASK;
	priv->tx_ctrl_reg |= reg;

	hpu_reg_write(priv, priv->tx_ctrl_reg, HPU_TXCTRL_REG);
	dev_dbg(&priv->pdev->dev, "writing TX CTRL REG: 0x%x\n", priv->tx_ctrl_reg);
	return 0;
}

static int hpu_set_tx_resync_time(struct hpu_priv *priv,
				  hpu_tx_resync_time_t time)
{
	u32 reg = 0;

	switch (time) {
	case TIME_1mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_1mS;
		break;
	case TIME_5mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_5mS;
		break;
	case TIME_10mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_10mS;
		break;
	case TIME_50mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_50mS;
		break;
	case TIME_100mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_100mS;
		break;
	case TIME_500mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_500mS;
		break;
	case TIME_1000mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_1000mS;
		break;
	case TIME_2500mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_2500mS;
		break;
	case TIME_5000mS:
		reg = HPU_TXCTRL_REG_SYNCTIME_5000mS;
		break;
	case TIME_10S:
		reg = HPU_TXCTRL_REG_SYNCTIME_10S;
		break;
	case TIME_25S:
		reg = HPU_TXCTRL_REG_SYNCTIME_25S;
		break;
	case TIME_50S:
		reg = HPU_TXCTRL_REG_SYNCTIME_50S;
		break;
	case TIME_100S:
		reg = HPU_TXCTRL_REG_SYNCTIME_100S;
		break;
	case TIME_250S:
		reg = HPU_TXCTRL_REG_SYNCTIME_250S;
		break;
	case TIME_500S:
		reg = HPU_TXCTRL_REG_SYNCTIME_500S;
		break;
	case TIME_DISABLE:
		reg = HPU_TXCTRL_REG_SYNCTIME_DISABLE;
		break;
	default:
		return -EINVAL;
	}

	priv->tx_ctrl_reg &= ~HPU_TXCTRL_REG_SYNCTIME_MASK;
	priv->tx_ctrl_reg |= reg;

	hpu_reg_write(priv, priv->tx_ctrl_reg, HPU_TXCTRL_REG);

	return 0;
}

static int hpu_set_loop_cfg(struct hpu_priv *priv, spinn_loop_t loop)
{
	unsigned long flags;

	spin_lock_irqsave(&priv->irq_lock, flags);
	switch (loop) {
	case LOOP_LSPINN:
		priv->loop_bits = HPU_CTRL_LOOP_SPINN;
		break;

	case LOOP_LNEAR:
		priv->loop_bits = HPU_CTRL_LOOP_LNEAR;
		break;

	case LOOP_NONE:
		priv->loop_bits = 0;
		break;
	default:
		spin_unlock_irqrestore(&priv->irq_lock, flags);
		dev_notice(&priv->pdev->dev,
			   "set loop - invalid arg %d\n", loop);
		return -EINVAL;
		break;
	}

	if (!hpu_rx_is_suspended(priv)) {
		priv->ctrl_reg &= ~(HPU_CTRL_LOOP_LNEAR | HPU_CTRL_LOOP_SPINN);
		priv->ctrl_reg |= priv->loop_bits;
		hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);
	}
	spin_unlock_irqrestore(&priv->irq_lock, flags);

	dev_dbg(&priv->pdev->dev, "set loop - CTRL reg 0x%x",
		priv->ctrl_reg);

	return 0;
}

/* called with IRQ lock held */
static void _hpu_do_set_axis_lat(struct hpu_priv *priv)
{
	u32 lat;

	/*
	 * If the DMA is not enabled, then do not touch the actual register:
	 * it is set to 1 when the DMA is terminating, and when the DMA is
	 * restarted this function will be called again to apply the user
	 * setting
	 */
	if (!(priv->ctrl_reg & HPU_CTRL_ENDMA))
		return;

	lat = priv->clk_rate / 1000 * priv->axis_lat;
	hpu_reg_write(priv, lat, HPU_TLAST_TIMEOUT);
}

static void hpu_do_set_axis_lat(struct hpu_priv *priv)
{
	unsigned long flags;

	spin_lock_irqsave(&priv->irq_lock, flags);
	_hpu_do_set_axis_lat(priv);
	spin_unlock_irqrestore(&priv->irq_lock, flags);
}

static void hpu_set_aux_thrs(struct hpu_priv *priv, aux_cnt_t aux_cnt_reg)
{
	unsigned int reg;

	reg = hpu_reg_read(priv, HPU_AUX_RX_ERR_THRS_REG);
	/* Normalize to num of errors, avoiding not valid errors */
	aux_cnt_reg.err = aux_cnt_reg.err % nomeaning_err;
	/* Clear the relevant byte */
	reg = reg & (~((0xFF) << (aux_cnt_reg.err * 8)));
	/* Write the register */
	hpu_reg_write(priv, (0xFF & aux_cnt_reg.cnt_val) <<
	       (aux_cnt_reg.err * 8) | reg,
		        HPU_AUX_RX_ERR_THRS_REG);
	/* Read and print the register */
	reg = hpu_reg_read(priv, HPU_AUX_RX_ERR_THRS_REG);

	dev_dbg(&priv->pdev->dev,
		"HPU_AUX_RX_ERR_THRS_REG 0x%08X\n", reg);
}

static void hpu_set_spinn_rx_mask(struct hpu_priv *priv, unsigned int val)
{
	hpu_reg_write(priv, val, HPU_SPINN_TX_MASK_REG);
}

static void hpu_set_spinn_tx_mask(struct hpu_priv *priv, unsigned int val)
{
	hpu_reg_write(priv, val, HPU_SPINN_RX_MASK_REG);
}

static int hpu_set_timestamp(struct hpu_priv *priv, unsigned int val)
{
	unsigned long flags;

	if (val != !!val)
		return -EINVAL;

	spin_lock_irqsave(&priv->irq_lock, flags);
	/* if dma is enabled then disable and also flush fifo */
	if (val)
		priv->ctrl_reg |= HPU_CTRL_FULLTS;
	else
		priv->ctrl_reg &= ~HPU_CTRL_FULLTS;

	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);
	spin_unlock_irqrestore(&priv->irq_lock, flags);
	return 0;
}

static void hpu_get_hw_status(struct hpu_priv *priv, hpu_hw_status_t *status)
{
	u32 reg = hpu_reg_read(priv, HPU_RAWSTAT_REG);

	memset((void*)status, 0, sizeof(hpu_hw_status_t));

	if (reg & HPU_RAWSTAT_RXDATAEMPTY) {
		status->rx_fifo_status = EMPTY;
	} else if (reg & HPU_RAWSTAT_RXDATAALMOSTEMPTY) {
		status->rx_fifo_status = ALMOST_EMPTY;
	} else if (reg & HPU_RAWSTAT_RXDATAFULL) {
		status->rx_fifo_status = FULL;
	} else {
		status->rx_fifo_status = NOT_EMPTY;
	}

	if (reg & HPU_RAWSTAT_TXDATAEMPTY) {
		status->tx_fifo_status = EMPTY;
	} else if (reg & HPU_RAWSTAT_TXDATAALMOSTFULL) {
		status->tx_fifo_status = ALMOST_FULL;
	} else if (reg & HPU_RAWSTAT_TXDATAFULL) {
		status->tx_fifo_status = FULL;
	} else {
		status->tx_fifo_status = NOT_EMPTY;
	}

	if (reg & HPU_RAWSTAT_RXBUFFERREADY)
		status->rx_buffer_ready = 1;

	if (reg & HPU_RAWSTAT_LRXPAERFIFOFULL)
		status->lrx_paer_fifo_full = 1;

	if (reg & HPU_RAWSTAT_RRXPAERFIFOFULL)
		status->rrx_paer_fifo_full = 1;

	if (reg & HPU_RAWSTAT_AUXRXPAERFIFOFULL)
		status->auxrx_paer_fifo_full = 1;

	if (reg & HPU_RAWSTAT_RXFIFOTHRESHOLD)
		status->rx_fifo_over_threshold = 1;

	if (reg & HPU_RAWSTAT_GLBLRXERR_KO)
		status->global_rx_err_ko = 1;

	if (reg & HPU_RAWSTAT_GLBLRXERR_TX)
		status->global_rx_err_tx = 1;

	if (reg & HPU_RAWSTAT_GLBLRXERR_TO)
		status->global_rx_err_to = 1;

	if (reg & HPU_RAWSTAT_GLBLRXERR_OF)
		status->global_rx_err_of = 1;

	if (reg & HPU_RAWSTAT_TXSPINNDUMP)
		status->tx_spinn_dump = 1;

	if (reg & HPU_RAWSTAT_LSPINN_PARITY_ERR)
		status->lspinn_parity_err = 1;

	if (reg & HPU_RAWSTAT_RSPINN_PARITY_ERR)
		status->rspinn_parity_err = 1;

	if (reg & HPU_RAWSTAT_AUXSPINN_PARITY_ERR)
		status->auxspinn_parity_err = 1;
}

static int hpu_chardev_open(struct inode *i, struct file *f)
{
	int ret = 0;
	u32 reg;
	struct hpu_priv *priv = container_of(i->i_cdev,
					     struct hpu_priv, cdev);

	f->private_data = priv;

	mutex_lock(&priv->access_lock);
	if (priv->hpu_is_opened == 1) {
		mutex_unlock(&priv->access_lock);
		return -EBUSY;
	}

	hpu_clk_enable(priv);

	priv->rx_blocking_threshold = ~0;
	priv->tx_blocking_threshold = ~0;
	priv->pkt_txed = 0;
	priv->byte_txed = 0;
	priv->pkt_rxed = 0;
	priv->byte_rxed = 0;
	priv->early_tlast = 0;
	priv->rx_fifo_status = FIFO_OK;
	priv->axis_lat = 10; /* mS */

	priv->hpu_is_opened = 1;
	ret = hpu_dma_init(priv);
	if (ret) {
		mutex_unlock(&priv->access_lock);
		return ret;
	}

	if (priv->dma_tx_chan) {
		priv->dma_tx_pool.ps = tx_ps;
		priv->dma_tx_pool.pn = tx_pn;
		ret = hpu_dma_alloc_pool(priv, &priv->dma_tx_pool, DMA_TO_DEVICE);

		if (ret) {
			dev_err(&priv->pdev->dev,
				"Error allocating memory from TX DMA pool\n");
			goto err_dealloc_dma;
		}
	}

	priv->dma_rx_pool.ps = rx_ps;
	priv->dma_rx_pool.pn = rx_pn;
	ret = hpu_dma_alloc_pool(priv, &priv->dma_rx_pool, DMA_FROM_DEVICE);

	/*
	 * In case of error go to deallocation rollback path, since
	 * partial allocation has been possibly done.
	 */
	if (ret) {
		dev_err(&priv->pdev->dev,
			"Error allocating memory from RX DMA pool\n");
		goto err_dealloc_dma;
	}

	ret = hpu_rx_dma_submit_pool(priv);
	if (ret) {
		dev_err(&priv->pdev->dev,
			"Error in submitting RX DMA descriptor\n");
		goto err_dealloc_dma;
	}
	dma_async_issue_pending(priv->dma_rx_chan);

	/* as per IP documentation default */
	priv->spinn_ctrl_reg = HPU_SPINN_CTRL_REG_TO_DIS;
	hpu_spinn_set_keys(priv, HPU_DEFAULT_START_KEY, HPU_DEFAULT_STOP_KEY);
	hpu_spinn_keys_enable(priv, 1, 1, 1);

	priv->rx_aux_ctrl_reg = 0;
	priv->rx_ctrl_reg = 0;
	hpu_rx_resume(priv);

	priv->tx_ctrl_reg = HPU_TXCTRL_TIMINGMODE_DELTA |
		HPU_TXCTRL_REG_SYNCTIME_DISABLE;
	hpu_reg_write(priv, priv->tx_ctrl_reg, HPU_TXCTRL_REG);

	/* Initialize HPU with full TS, no loop */
	priv->ctrl_reg = HPU_CTRL_FULLTS;
	priv->loop_bits = 0;
	hpu_reg_write(priv, priv->ctrl_reg |
		      HPU_CTRL_FLUSH_TX_FIFO | HPU_CTRL_FLUSH_RX_FIFO,
		      HPU_CTRL_REG);

	/* default RX/TX mask */
	hpu_reg_write(priv, 0xFFFFFF, HPU_SPINN_TX_MASK_REG);
	hpu_reg_write(priv, 0xFFFFFF, HPU_SPINN_RX_MASK_REG);

	/*
	 * Sample initial value for IP RX TLAST and DATA counters; they are used
	 * to get a clue about how many bytes have been transferred in the
	 * current session, in order to fully flush RX-path when required
	 */
	priv->rx_tlast_count = hpu_reg_read(priv, HPU_TLAST_COUNT) >> 16;
	priv->rx_data_count = hpu_reg_read(priv, HPU_DATA_COUNT) >> 16;

	/* Set RX DMA max pkt len (data count before TLAST) */
	reg = priv->dma_rx_pool.ps / 4;
	if (test_dma)
		reg |= HPU_DMA_TEST_ON;
	hpu_reg_write(priv, reg, HPU_DMA_REG);

	if (test_dma)
		priv->irq_msk = 0;
	else
		/* Unmask RXFIFOFULL interrupt */
		priv->irq_msk = HPU_MSK_INT_RXFIFOFULL;

	hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);
	/* clear all INTs */
	hpu_reg_write(priv, 0xffffffff, HPU_IRQ_REG);

	priv->ctrl_reg |= HPU_CTRL_ENINT | HPU_CTRL_AXIS_LAT;
	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);

	/* this will also set TLAST timeout */
	hpu_start_dma(priv);

	mutex_unlock(&priv->access_lock);
	return 0;

err_dealloc_dma:
	hpu_dma_release(priv);
	mutex_unlock(&priv->access_lock);

	return ret;
}

static int hpu_chardev_close(struct inode *i, struct file *fp)
{
	struct hpu_priv *priv = fp->private_data;
	unsigned long flags;

	mutex_lock(&priv->access_lock);
	mutex_lock(&priv->dma_rx_pool.mutex_lock);
	mutex_lock(&priv->dma_tx_pool.mutex_lock);

	spin_lock_irqsave(&priv->irq_lock, flags);
	/* Disable RX */
	hpu_rx_suspend(priv);
	/* Disable TX */
	priv->tx_ctrl_reg = 0;
	hpu_reg_write(priv, priv->tx_ctrl_reg, HPU_TXCTRL_REG);

	/* Mask interrupts - this ensure that pending IRQ are ignored by ISR */
	priv->irq_msk = 0;
	hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);
	spin_unlock_irqrestore(&priv->irq_lock, flags);

	/* Disable interrupts */
        priv->ctrl_reg &= ~HPU_CTRL_ENINT;
	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);

	hpu_stop_dma(priv);

	hpu_reg_write(priv, priv->ctrl_reg |
		      HPU_CTRL_FLUSH_TX_FIFO | HPU_CTRL_FLUSH_RX_FIFO,
		      HPU_CTRL_REG);

	mdelay(100);
	mutex_unlock(&priv->dma_tx_pool.mutex_lock);
	mutex_unlock(&priv->dma_rx_pool.mutex_lock);

	cancel_work_sync(&priv->rx_housekeeping_work);

	hpu_dma_release(priv);
	priv->hpu_is_opened = 0;
	hpu_clk_disable(priv);

	mutex_unlock(&priv->access_lock);

	return 0;
}

static void hpu_handle_err(struct hpu_priv *priv)
{
	uint32_t reg;
	int i;
	uint8_t num_channel = 0;
	int is_aux = 0;

	/* Detect which RX HSSAER channel is enabled */
	reg = priv->rx_ctrl_reg;
	/* Check Left SAER */
	if (reg & 0x1)
		num_channel = num_channel | (reg & (0xF << 8)) >> 8;
	/* Check Right SAER */
	if (reg & 0x10000)
		num_channel = num_channel | (reg & (0xF << 24)) >> 24;

	/* Check Left Aux Saer */
	reg = priv->rx_aux_ctrl_reg;
	if (reg & 0x1) {
		num_channel = num_channel | (reg & (0xF << 8)) >> 8;
		is_aux = 1;
	}

	if (!is_aux)
		dev_info(&priv->pdev->dev,
		       "HSSAER error in Left or Right Eyes\n");
	else {
		dev_info(&priv->pdev->dev,
		       "HSSAER error in Left or Right Eyes or Aux\n");
		for (i = 0; i < 4; i++) {
			if (num_channel & (1 << i))
				dev_info(&priv->pdev->dev,
					 "Aux CNT %d 0x%08X\n", i,
					 hpu_reg_read(priv,
					       (HPU_AUX_RX_ERR_CH0_REG + i * 4)));
		}
	}
}

/*************************************************************************************
  IRQ Handler
**************************************************************************************/
static irqreturn_t hpu_irq_handler(int irq, void *pdev)
{

	u32 intr;

	struct hpu_priv *priv = platform_get_drvdata(pdev);
	irqreturn_t retval = 0;

	spin_lock(&priv->irq_lock);
	intr = hpu_reg_read(priv, HPU_IRQ_REG) & priv->irq_msk;

	if (intr & HPU_MSK_INT_TSTAMPWRAPPED) {
		hpu_reg_write(priv, HPU_MSK_INT_TSTAMPWRAPPED, HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_RXBUFFREADY) {
		dev_info(&priv->pdev->dev, "IRQ: RXBUFFREADY\n");
		hpu_reg_write(priv, HPU_MSK_INT_RXBUFFREADY, HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_RXFIFOFULL) {
		dev_info(&priv->pdev->dev, "IRQ: RXFIFOFULL\n");

		/* Stop feeding the fifos.. */
		hpu_rx_suspend(priv);

		/*
		 * Initiate DMA stop procedure ASAP. We'll wait for the DMA to
		 * be really stopped in the bottom half
		 */
		_hpu_stop_dma_uh(priv);

		/* Mask fifo-full interrupt */
		priv->irq_msk &= ~HPU_MSK_INT_RXFIFOFULL;
		hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);

		/* Clear fifo-full interrupt */
		hpu_reg_write(priv, HPU_MSK_INT_RXFIFOFULL, HPU_IRQ_REG);
		WRITE_ONCE(priv->rx_fifo_status, FIFO_OVERFLOW);

		/* Schedule the rx-purger thread */
		schedule_work(&priv->rx_housekeeping_work);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_KO) {
		dev_info(&priv->pdev->dev, "IRQ: RX KO Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		hpu_reg_write(priv, HPU_MSK_INT_GLBLRXERR_KO, HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_RX) {
		dev_info(&priv->pdev->dev, "IRQ: RX RX Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		hpu_reg_write(priv, HPU_MSK_INT_GLBLRXERR_RX, HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_TO) {
		dev_info(&priv->pdev->dev, "IRQ: RX TO Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		hpu_reg_write(priv, HPU_MSK_INT_GLBLRXERR_TO, HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_OF) {
		dev_info(&priv->pdev->dev, "IRQ: RX OF Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		hpu_reg_write(priv, HPU_MSK_INT_GLBLRXERR_OF, HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	spin_unlock(&priv->irq_lock);
	retval = IRQ_HANDLED;
	return retval;
}

static long hpu_ioctl(struct file *fp, unsigned int cmd, unsigned long _arg)
{
	void *arg = (void*) _arg;
	unsigned int ret;
	aux_cnt_t aux_cnt_reg;
	spinn_keys_t spinn_keys;
	spinn_loop_t loop;
	hpu_rx_interface_ioctl_t rxiface;
	hpu_tx_interface_ioctl_t txiface;
	ip_regs_t temp_reg;
	hpu_timestamp_mask_t ts_mask;
	hpu_tx_timing_mode_t timing_mode;
	hpu_tx_resync_time_t resync_time;
	hpu_hw_status_t hw_status;
	spinn_keys_enable_t keys_enable;
	unsigned int val = 0;
	int res = 0;
	struct hpu_priv *priv = fp->private_data;

	dev_dbg(&priv->pdev->dev, "ioctl %x\n", cmd);

	mutex_lock(&priv->access_lock);
	switch (cmd) {
	case _IOR(0x0, HPU_IOCTL_READTIMESTAMP, unsigned int):
		ret = hpu_reg_read(priv, HPU_WRAP_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_CLEARTIMESTAMP, unsigned int):
		hpu_reg_write(priv, 0, HPU_WRAP_REG);
		break;

	case _IOR(0x0, HPU_IOCTL_READVERSION, unsigned int):
		ret = hpu_reg_read(priv, HPU_VER_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		dev_info(&priv->pdev->dev, "Reading version %d\n", ret);
		break;

	case _IOW(0x0, HPU_IOCTL_SETTIMESTAMP, unsigned int *):
		if (copy_from_user(&val, arg, sizeof(unsigned int)))
			goto cfuser_err;
		res = hpu_set_timestamp(priv, val);
		break;

	case _IOWR(0x0, HPU_IOCTL_GEN_REG, struct ip_regs *):
	       if (copy_from_user(&temp_reg, arg, sizeof(temp_reg)))
		       goto cfuser_err;
	       if (temp_reg.rw == 0) {
		      temp_reg.data = hpu_reg_read(priv, temp_reg.reg_offset);
		       if (copy_to_user(arg, &temp_reg,	sizeof(temp_reg)))
			       goto cfuser_err;
	       } else {
		       hpu_reg_write(priv, temp_reg.data, temp_reg.reg_offset);
	       }
	       break;

	case _IOR(0x0, HPU_IOCTL_GET_RX_PS, unsigned int *):
		ret = priv->dma_rx_pool.ps;
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_TX_PS, unsigned int *):
		ret = priv->dma_tx_pool.ps;
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_SET_AUX_THRS, struct aux_cnt *):
		if (copy_from_user(&aux_cnt_reg, arg, sizeof(aux_cnt_reg)))
			goto cfuser_err;
		hpu_set_aux_thrs(priv, aux_cnt_reg);
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_THRS, unsigned int *):
		ret = hpu_reg_read(priv, HPU_AUX_RX_ERR_THRS_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT0, unsigned int *):
		ret = hpu_reg_read(priv, HPU_AUX_RX_ERR_CH0_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT1, unsigned int *):
		ret = hpu_reg_read(priv, HPU_AUX_RX_ERR_CH1_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT2, unsigned int *):
		ret = hpu_reg_read(priv, HPU_AUX_RX_ERR_CH2_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT3, unsigned int *):
		ret = hpu_reg_read(priv, HPU_AUX_RX_ERR_CH3_REG);
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_LOST_CNT, unsigned int *):
		ret = priv->cnt_pktloss;
		priv->cnt_pktloss = 0;
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_SET_LOOP_CFG, spinn_loop_t *):
		if (copy_from_user(&loop, arg, sizeof(spinn_loop_t)))
			goto cfuser_err;
		res = hpu_set_loop_cfg(priv, loop);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_BLK_TX_THR, unsigned int *):
		if (copy_from_user(&val, arg, sizeof(unsigned int)))
			goto cfuser_err;
		mutex_lock(&priv->dma_tx_pool.mutex_lock);
		priv->tx_blocking_threshold = val;
		mutex_unlock(&priv->dma_tx_pool.mutex_lock);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_BLK_RX_THR, unsigned int *):
		if (copy_from_user(&val, arg, sizeof(unsigned int)))
			goto cfuser_err;
		mutex_lock(&priv->dma_rx_pool.mutex_lock);
		priv->rx_blocking_threshold = val;
		mutex_unlock(&priv->dma_rx_pool.mutex_lock);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_SPINN_KEYS, spinn_keys_t *):
		if (copy_from_user(&spinn_keys, arg, sizeof(spinn_keys_t)))
			goto cfuser_err;
		res = hpu_spinn_set_keys(priv, spinn_keys.start, spinn_keys.stop);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_SPINN_STARTSTOP, unsigned int *):
		if (copy_from_user(&val, arg, sizeof(unsigned int)))
			goto cfuser_err;
		res = hpu_spinn_startstop(priv, val);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_RX_INTERFACE, hpu_rx_interface_ioctl_t *):
		if (copy_from_user(&rxiface, arg, sizeof(hpu_rx_interface_ioctl_t)))
			goto cfuser_err;
		res = hpu_set_rx_interface(priv, rxiface.interface, rxiface.cfg);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_TX_INTERFACE, hpu_tx_interface_ioctl_t *):
		if (copy_from_user(&txiface, arg, sizeof(hpu_tx_interface_ioctl_t)))
			goto cfuser_err;
		res = hpu_set_tx_interface(priv, txiface.cfg, txiface.route);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_AXIS_LATENCY, unsigned int *):
		if (copy_from_user(&val, arg, sizeof(unsigned int)))
			goto cfuser_err;
		mutex_lock(&priv->dma_rx_pool.mutex_lock);
		priv->axis_lat = val;
		hpu_do_set_axis_lat(priv);
		mutex_unlock(&priv->dma_rx_pool.mutex_lock);
		break;

	case _IOR(0x0, HPU_IOCTL_GET_RX_PN, unsigned int *):
		ret = priv->dma_rx_pool.pn;
		if (copy_to_user(arg, &ret, sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_SET_TS_MASK, hpu_timestamp_mask_t *):
		if (copy_from_user(&ts_mask, arg,
				   sizeof(hpu_timestamp_mask_t)))
			goto cfuser_err;
		hpu_set_ts_mask(priv, ts_mask);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_TX_TIMING_MODE, hpu_tx_timing_mode_t *):
		if (copy_from_user(&timing_mode, arg,
				   sizeof(hpu_tx_timing_mode_t)))
			goto cfuser_err;
		hpu_set_tx_timing_mode(priv, timing_mode);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_TX_RESYNC_TIMER, hpu_tx_resync_time_t *):
		if (copy_from_user(&resync_time, arg,
				   sizeof(hpu_tx_resync_time_t)))
			goto cfuser_err;
		hpu_set_tx_resync_time(priv, resync_time);
		break;

	case _IO(0x0, HPU_IOCTL_RESET_TX_RESYNC_TIMER):
		hpu_reset_tx_resync_timer(priv);
		break;

	case _IO(0x0, HPU_IOCTL_FORCE_TX_RESYNC_TIMER):
		hpu_force_tx_resync_timer(priv);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_SPINN_TX_MASK, unsigned int *):
		if (copy_from_user(&val, arg,
				   sizeof(unsigned int)))
			goto cfuser_err;
		hpu_set_spinn_tx_mask(priv, val);
		break;

	case _IOW(0x0, HPU_IOCTL_SET_SPINN_RX_MASK, unsigned int *):
		if (copy_from_user(&val, arg,
				   sizeof(unsigned int)))
			goto cfuser_err;
		hpu_set_spinn_rx_mask(priv, val);
		break;

	case _IOR(0x0, HPU_IOCTL_GET_HW_STATUS, hpu_hw_status_t *):
		hpu_get_hw_status(priv, &hw_status);
		if (copy_to_user(arg, &hw_status, sizeof(hpu_hw_status_t)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_SET_SPINN_KEYS_EN_EX, spinn_keys_enable_t *):
		if (copy_from_user(&keys_enable, arg,
				   sizeof(spinn_keys_enable_t)))
			goto cfuser_err;
		res = hpu_spinn_keys_enable(priv, keys_enable.enable_l,
					    keys_enable.enable_r,
					    keys_enable.enable_aux);
		break;

	default:
		res = -EINVAL;
	}

	mutex_unlock(&priv->access_lock);
	return res;

cfuser_err:
	dev_err(&priv->pdev->dev, "Copy from user space failed\n");
	mutex_unlock(&priv->access_lock);
	return -EFAULT;
}

static struct file_operations hpu_fops = {
	.open = hpu_chardev_open,
	.owner = THIS_MODULE,
	.read = hpu_chardev_read,
	.write= hpu_chardev_write,
	.release = hpu_chardev_close,
	.unlocked_ioctl = hpu_ioctl,
};

static int hpu_register_chardev(struct hpu_priv *priv)
{
	int ret;

	/*
	 * Copy default fops; write will be cleared/assigned for each instance
	 * depending by whether it will be able to get the (optional) TX DMA ch
	 */
	priv->fops = hpu_fops;
	cdev_init(&priv->cdev, &priv->fops);

	priv->cdev.owner = THIS_MODULE;
	priv->id = ida_simple_get(&hpu_ida, 0, 0, GFP_KERNEL);
	if (priv->id < 0) {
		dev_err(&priv->pdev->dev, "Can't alloc an ID\n");
		return -1;
	}

	priv->devt = MKDEV(MAJOR(hpu_devt), priv->id);
	ret = cdev_add(&priv->cdev, priv->devt, 1);
	if (ret) {
		dev_err(&priv->pdev->dev, "Cannot add chrdev \n");
		return ret;
	}

	device_create(hpu_class, NULL, priv->devt, priv,
		      HPU_NAME_FMT, priv->id);

	dev_info(&priv->pdev->dev, "Registered device major: %d, minor:%d\n",
	       MAJOR(priv->devt), MINOR(priv->devt));

	return 0;
}

static int hpu_unregister_chardev(struct hpu_priv *priv)
{
#ifdef HPU_DMA_DEFER_SUBMIT
	hpu_rx_dma_thread_terminate(priv);
#endif
	cdev_del(&priv->cdev);
	device_destroy(hpu_class, priv->devt);
	ida_simple_remove(&hpu_ida, priv->id);

	return 0;
}

static int hpu_probe(struct platform_device *pdev)
{
	struct hpu_priv *priv;
	struct resource *res;
	struct debugfs_regset32 *regset;
	unsigned int result;
	u32 ver;
	char buf[128];

	/* FIXME: handle error path resource free */

	dev_dbg(&pdev->dev, "Probing hpu\n");
	priv = kmalloc(sizeof(struct hpu_priv), GFP_KERNEL);
	if (!priv) {
		dev_err(&pdev->dev, "Can't alloc priv mem\n");
		return -ENOMEM;
	}
	priv->hpu_is_opened = 0;
	priv->rx_fifo_status = FIFO_OK;

	mutex_init(&priv->access_lock);
	spin_lock_init(&priv->irq_lock);

	platform_set_drvdata(pdev, priv);
	priv->pdev = pdev;
	priv->ctrl_reg = 0;
	INIT_WORK(&priv->rx_housekeeping_work, hpu_rx_housekeeping);

	spin_lock_init(&priv->dma_rx_pool.spin_lock);
	spin_lock_init(&priv->dma_tx_pool.spin_lock);

	mutex_init(&priv->dma_rx_pool.mutex_lock);
	mutex_init(&priv->dma_tx_pool.mutex_lock);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	priv->reg_base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(priv->reg_base)) {
		dev_err(&pdev->dev, "HPU has no regs in DT\n");
		kfree(priv);
		return PTR_ERR(priv->reg_base);
	}

	priv->clk = devm_clk_get(&pdev->dev, "s_axi_aclk");
	if (IS_ERR(priv->clk)) {
		dev_warn(&priv->pdev->dev, "cannot get clock: s_axi_aclk; using default 100MHz\n");
		priv->clk_rate = 100000000;
	} else {
		priv->clk_rate = clk_get_rate(priv->clk);
	}

	hpu_clk_enable(priv);
	ver = hpu_reg_read(priv, HPU_VER_REG);
	hpu_clk_disable(priv);

	if (ver != HPU_VER_MAGIC) {
		if ((ver >> 24) == 'B') {
			dev_warn(&pdev->dev,
				 "HPU IP is a _BETA_ version (0x%x)\n", ver);
		} else {
			dev_err(&pdev->dev,
				"HPU IP has wrong version: 0x%x\n", ver);
			kfree(priv);
			return -ENODEV;
		}
	}

	priv->irq = platform_get_irq(pdev, 0);
	if (priv->irq < 0) {
		dev_err(&pdev->dev, "Error getting irq\n");
		return -EPERM;
	}
	result =
	    request_irq(priv->irq, hpu_irq_handler, IRQF_SHARED, "int_hpucore",
			pdev);
	if (result) {
		dev_err(&pdev->dev, "Error requesting irq: %i\n",
		       result);
		return -EPERM;
	}

	priv->cnt_pktloss = 0;

	if ((rx_pn < 2) || (rx_pn != BIT(fls(rx_pn) - 1))) {
		dev_warn(&priv->pdev->dev, "rx_pn invalid. using default\n");
		rx_pn = HPU_RX_POOL_NUM;
	}
	if ((tx_pn < 2) || (tx_pn != BIT(fls(tx_pn) - 1))) {
		dev_warn(&priv->pdev->dev, "tx_pn invalid. using default\n");
		tx_pn = HPU_TX_POOL_NUM;
	}
	if (rx_ps < 8) {
		dev_warn(&priv->pdev->dev, "rx_ps too small. using default\n");
		rx_ps = HPU_RX_POOL_SIZE;
	}
	if ((rx_ps / 4) > HPU_DMA_LENGTH_MASK) {
		dev_warn(&priv->pdev->dev, "rx_ps too big. using default\n");
		rx_ps = HPU_RX_POOL_SIZE;
	}
	if (tx_ps < 8) {
		dev_warn(&priv->pdev->dev, "tx_ps too small. using default\n");
		tx_ps = HPU_TX_POOL_SIZE;
	}

	init_completion(&priv->dma_rx_pool.completion);
	init_completion(&priv->dma_tx_pool.completion);

#ifdef HPU_DMA_DEFER_SUBMIT
	hpu_rx_dma_thread_create(priv);
#endif
	hpu_register_chardev(priv);

	if (hpu_debugfsdir) {
		sprintf(buf, "hpu.%pa", &res->start);
		priv->debugfsdir = debugfs_create_dir(buf, hpu_debugfsdir);
	}

	if (priv->debugfsdir) {
		regset = devm_kzalloc(&pdev->dev, sizeof(*regset), GFP_KERNEL);
		if (!regset)
			return 0;
		regset->regs = hpu_regs;
		regset->nregs = ARRAY_SIZE(hpu_regs);
		regset->base = priv->reg_base;
		debugfs_create_regset32("regdump", 0444, priv->debugfsdir, regset);
		HPU_DEBUGFS_ULONG(priv, cnt_pktloss);
		HPU_DEBUGFS_ULONG(priv, pkt_txed);
		HPU_DEBUGFS_ULONG(priv, pkt_rxed);
		HPU_DEBUGFS_ULONG(priv, byte_txed);
		HPU_DEBUGFS_ULONG(priv, byte_rxed);
		HPU_DEBUGFS_ULONG(priv, early_tlast);
	}

	return 0;
}

static int hpu_remove(struct platform_device *pdev)
{
	struct hpu_priv *priv = platform_get_drvdata(pdev);

	/* FIXME: resource release ! */
	debugfs_remove_recursive(priv->debugfsdir);
	free_irq(priv->irq, pdev);

	hpu_unregister_chardev(priv);
	kfree(priv);
	return 0;
}

static struct of_device_id hpu_of_match[] = {
	{.compatible = "iit.it,HPU-Core-3.0",},
	{}
};

MODULE_DEVICE_TABLE(of, hpu_of_match);

static struct platform_driver hpu_platform_driver = {
	.probe = hpu_probe,
	.remove = hpu_remove,
	.driver = {
		   .name = HPU_DRIVER_NAME,
		   .owner = THIS_MODULE,
		   .of_match_table = hpu_of_match,
		   },
};

static void __exit hpu_module_remove(void)
{
	platform_driver_unregister(&hpu_platform_driver);
	debugfs_remove_recursive(hpu_debugfsdir);
	class_destroy(hpu_class);

	if (hpu_devt) {
		unregister_chrdev_region(hpu_devt, HPU_MINOR_COUNT);
	}
}

static int __init hpu_module_init(void)
{
	int ret;

	ret = alloc_chrdev_region(&hpu_devt, 0, HPU_MINOR_COUNT, HPU_DEV_NAME);
	if (ret < 0) {
		printk(KERN_ALERT "Error allocating chrdev region for driver "
			HPU_DRIVER_NAME " \n");
		return -ENOMEM;
	}

	hpu_class = class_create(THIS_MODULE, HPU_CLASS_NAME);
	if (hpu_class == NULL) {
		printk(KERN_ALERT "Error creating class " HPU_CLASS_NAME " \n");
		goto unreg_chrreg;
	}

	hpu_debugfsdir = debugfs_create_dir("hpu", NULL);

	ret = platform_driver_register(&hpu_platform_driver);
	if (ret) {
		printk(KERN_ALERT "Error registering driver "
		       HPU_DRIVER_NAME " \n");
		goto unreg_class;
	}

	return 0;

unreg_class:
	class_destroy(hpu_class);

unreg_chrreg:
	unregister_chrdev_region(hpu_devt, HPU_MINOR_COUNT);

	return -1;
}

module_init(hpu_module_init);
module_exit(hpu_module_remove);

MODULE_ALIAS("platform:iit-hpudma");
MODULE_DESCRIPTION("hpu stream driver");
MODULE_AUTHOR("Francesco Diotalevi <francesco.diotalevi@iit.it>");
MODULE_AUTHOR("Andrea Merello <andrea.merello@iit.it>");
MODULE_LICENSE("GPL v2");
