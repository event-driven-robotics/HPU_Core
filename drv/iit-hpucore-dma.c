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
#define HPU_TLAST_TIMEOUT	0xA0

/* magic constants */
#define HPU_VER_MAGIC			0x42303130

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

#define HPU_MSK_INT_RXFIFOFULL		0x004
#define HPU_MSK_INT_TSTAMPWRAPPED	0x080
#define HPU_MSK_INT_RXBUFFREADY		0x100
#define HPU_MSK_INT_GLBLRXERR_KO	0x00010000
#define HPU_MSK_INT_GLBLRXERR_RX	0x00020000
#define HPU_MSK_INT_GLBLRXERR_TO	0x00040000
#define HPU_MSK_INT_GLBLRXERR_OF	0x00080000

#define HPU_IOCTL_READTIMESTAMP		1
#define HPU_IOCTL_CLEARTIMESTAMP	2
#define HPU_IOCTL_READVERSION		3
/* 4 is not used anymore */
#define HPU_IOCTL_SETTIMESTAMP		7
#define HPU_IOCTL_GEN_REG		8
#define HPU_IOCTL_GET_RX_PS		9
#define HPU_IOCTL_SET_AUX_THRS		10
#define HPU_IOCTL_GET_AUX_THRS		11
#define HPU_IOCTL_GET_AUX_CNT0		12
#define HPU_IOCTL_GET_AUX_CNT1		13
#define HPU_IOCTL_GET_AUX_CNT2		14
#define HPU_IOCTL_GET_AUX_CNT3		15
#define HPU_IOCTL_GET_LOST_CNT		16
/* 17 is not used anymore */
#define HPU_IOCTL_SET_LOOP_CFG		18
/* 19 is not used anymore */
#define HPU_IOCTL_GET_TX_PS		20
#define HPU_IOCTL_SET_BLK_TX_THR	21
#define HPU_IOCTL_SET_BLK_RX_THR	22
#define HPU_IOCTL_SET_SPINN_KEYS	23
#define HPU_IOCTL_SET_SPINN_KEYS_EN	24
#define HPU_IOCTL_SET_SPINN_STARTSTOP	25
#define HPU_IOCTL_SET_RX_INTERFACE	26
#define HPU_IOCTL_SET_TX_INTERFACE	27
#define HPU_IOCTL_SET_AXIS_LATENCY	28

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

typedef enum {
	LOOP_NONE,
	LOOP_LNEAR,
	LOOP_LSPINN,
} spinn_loop_t;

struct hpu_priv;

struct hpu_buf {
	dma_addr_t phys;
	void *virt;
	int head_index, tail_index;
	dma_cookie_t cookie;
	struct hpu_priv *priv;
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
	uint32_t rx_ctrl_reg;
	uint32_t rx_aux_ctrl_reg;
	uint32_t irq_msk;
	struct dentry *debugfsdir;
	struct clk *clk;
	spinlock_t irq_lock;

	/* spinn-related */
	int spinn_start;
	int spinn_start_key;
	int spinn_stop_key;
	int spinn_keys_enable;

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
};

#define HPU_REG_LOG 0

#define HPU_DEBUGFS_ULONG(priv, x) debugfs_create_ulong(__stringify(x), 0444, \
				   priv->debugfsdir, &priv->x);

static struct dentry *hpu_debugfsdir = NULL;
static struct class *hpu_class = NULL;
static dev_t hpu_devt;
static DEFINE_IDA(hpu_ida);

static int hpu_rx_dma_submit_buffer(struct hpu_priv *priv, struct hpu_buf *buf);
static void hpu_dma_free_pool(struct hpu_priv *priv, struct hpu_dma_pool *hpu_pool);

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
	spin_lock(&priv->dma_tx_pool.spin_lock);
	priv->dma_tx_pool.filled--;
	complete(&priv->dma_tx_pool.completion);
	spin_unlock(&priv->dma_tx_pool.spin_lock);
}

/* called with RX lock held */
static void hpu_flush_rx_fifo(struct hpu_priv *priv)
{
	int finished = 0;
	int ret;

	while (1) {
		spin_lock_bh(&priv->dma_rx_pool.spin_lock);
		finished = (priv->dma_rx_pool.filled == 0);
		if (!finished)
			priv->dma_rx_pool.filled--;
		spin_unlock_bh(&priv->dma_rx_pool.spin_lock);
		if (finished)
			break;

		ret = hpu_rx_dma_submit_buffer(priv, &priv->dma_rx_pool.ring[priv->dma_rx_pool.buf_index]);
		if (ret)
			dev_err(&priv->pdev->dev, "DMA RX submit error %d while housekeeping\n", ret);
		/* forcefully advance index. 1pkt lost */
		priv->dma_rx_pool.buf_index =
			(priv->dma_rx_pool.buf_index + 1) &
		(priv->dma_rx_pool.pn - 1);

		BUG_ON(priv->dma_rx_pool.buf_index >= priv->dma_rx_pool.pn);

		priv->cnt_pktloss++;
		dma_async_issue_pending(priv->dma_rx_chan);
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
	if (state == FIFO_OK || state == FIFO_DRAINED) {
		mutex_unlock(&priv->dma_rx_pool.mutex_lock);
		return;
	}

	hpu_flush_rx_fifo(priv);

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
	int len = priv->dma_rx_pool.ps - result->residue;

	dev_dbg(&priv->pdev->dev, "RX DMA cb\n");
	priv->pkt_rxed++;

	/*
	 * when HPU prodive odd number of data it means that it has produced
	 * an early TLAST sending also a dummy data, so we need to discard it
	 */
	if ((len / 4) & 1) {
		priv->early_tlast++;
		len -= 4;
		word = ((u32*)buffer->virt)[len / 4];
		if (unlikely(word != 0xf0cacc1a))
			dev_err(&priv->pdev->dev, "Got early TLAST, but no magic word\n");
	}
	priv->byte_rxed += len;

	spin_lock(&priv->dma_rx_pool.spin_lock);
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

	if (!access_ok(VERIFY_WRITE, buf, lenght))
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

static ssize_t hpu_chardev_read(struct file *fp, char *buf, size_t length,
				loff_t *offset)
{
	int ret, ret2;
	size_t copy;
	int index;
	size_t buf_count;
	struct hpu_buf *item;
	unsigned long flags;
	size_t read = 0;
	struct hpu_priv *priv = fp->private_data;

	if (!access_ok(VERIFY_READ, buf, length))
		return -EFAULT;

	dev_dbg(&priv->pdev->dev, "----tot to read %d\n", length);

	mutex_lock(&priv->dma_rx_pool.mutex_lock);

	while (length > 0) {
		/*
		 * Wait for some data to be available - this part must lock
		 * against the DMA cb, in order to correctly handle filled count
		 * and completion wakeup
		 */
		while (1) {
			/*
			 * Quoting Documentation/dmaengine/client.txt:
			 * Note that callbacks will always be invoked from the DMA
			 * engines tasklet, never from interrupt context.
			 */
			spin_lock_bh(&priv->dma_rx_pool.spin_lock);

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
				hpu_flush_rx_fifo(priv);

				/* fall-through */
			case FIFO_STOPPED:
				/*
				 * An overflow has been fixed. We have to
				 * restart the RX machanism, then we can go on.
				 */
				spin_lock_irqsave(&priv->irq_lock, flags);
				hpu_reg_write(priv, priv->rx_ctrl_reg,
					      HPU_RXCTRL_REG);
				hpu_reg_write(priv, priv->rx_aux_ctrl_reg,
					      HPU_AUX_RXCTRL_REG);

				/* Re-enable RX FIFO full interrupt */
				priv->irq_msk |= HPU_MSK_INT_RXFIFOFULL;
				hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);

				WRITE_ONCE(priv->rx_fifo_status, FIFO_OK);
				spin_unlock_irqrestore(&priv->irq_lock, flags);
				break;
			}

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

		dev_dbg(&priv->pdev->dev, "going to read %d bytes from offset %d\n",
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
			ret2 = hpu_rx_dma_submit_buffer(priv, &priv->dma_rx_pool.ring[index]);
			if (ret2)
				dev_err(&priv->pdev->dev,
					"DMA RX submit error %d while reading\n",
					ret2);

			priv->dma_rx_pool.buf_index = (priv->dma_rx_pool.buf_index + 1)
				& (priv->dma_rx_pool.pn - 1);
			BUG_ON(priv->dma_rx_pool.buf_index >= priv->dma_rx_pool.pn);
			dma_async_issue_pending(priv->dma_rx_chan);
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
		dev_dbg(&priv->pdev->dev, "read %d, rem %d\n", read, length);

		/* partially copied */
		if (ret)
			break;
	}

	dev_dbg(&priv->pdev->dev, "----END read\n");

	mutex_unlock(&priv->dma_rx_pool.mutex_lock);
	return read;

error_rx_fifo_full:
	spin_unlock_bh(&priv->dma_rx_pool.spin_lock);
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
		hpu_dma_free_pool(priv, &priv->dma_rx_pool);
	}

	if (priv->dma_tx_chan) {
		dma_release_channel(priv->dma_tx_chan);
		hpu_dma_free_pool(priv, &priv->dma_tx_pool);
	}
}

static int hpu_dma_alloc_pool(struct hpu_priv *priv,
			      struct hpu_dma_pool *hpu_pool)
{
	int i;

	hpu_pool->dma_pool = dma_pool_create(HPU_DRIVER_NAME, &priv->pdev->dev,
					 hpu_pool->ps, 4, 0);

	if (!hpu_pool->dma_pool) {
		dev_err(&priv->pdev->dev, "Error creating DMA pool\n");
		return -ENOMEM;
	}

	hpu_pool->ring = kmalloc(hpu_pool->pn * sizeof(struct hpu_buf), GFP_KERNEL);
	if (!(hpu_pool->ring)) {
		dev_err(&priv->pdev->dev, "Can't alloc mem for dma ring\n");
		return -ENOMEM;
	}

	for (i = 0; i < hpu_pool->pn; i++) {
	        hpu_pool->ring[i].virt =
		    (unsigned char *)dma_pool_alloc(hpu_pool->dma_pool, GFP_KERNEL,
						    &hpu_pool->ring[i].phys);

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
			      struct hpu_dma_pool *hpu_pool)
{
	int i;

	for (i = 0; i < hpu_pool->pn; i++) {
		dma_pool_free(hpu_pool->dma_pool,
			      hpu_pool->ring[i].virt, hpu_pool->ring[i].phys);
		hpu_pool->ring[i].virt = NULL;
	}

	dma_pool_destroy(hpu_pool->dma_pool);
	hpu_pool->dma_pool = NULL;
	kfree(hpu_pool->ring);
	hpu_pool->ring = NULL;
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

static void hpu_spinn_do_set_keys(struct hpu_priv *priv)
{
	hpu_reg_write(priv, priv->spinn_start_key, HPU_SPINN_START_KEY_REG);
	hpu_reg_write(priv, priv->spinn_stop_key, HPU_SPINN_STOP_KEY_REG);
	dev_dbg(&priv->pdev->dev, "Enabling keys START:0x%x STOP:0x%x\n",
		priv->spinn_start_key, priv->spinn_stop_key);
}

static void hpu_spinn_do_startstop(struct hpu_priv *priv)
{
	if (priv->spinn_start) {
		dev_dbg(&priv->pdev->dev, "Forcing SPINN start\n");
		hpu_reg_write(priv, 0x0, HPU_SPINN_START_KEY_REG);
		hpu_reg_write(priv, 0x0, HPU_SPINN_STOP_KEY_REG);
	} else {
		dev_dbg(&priv->pdev->dev, "Forcing SPINN stop\n");
		hpu_reg_write(priv, 0xFFFFFFFF, HPU_SPINN_START_KEY_REG);
		hpu_reg_write(priv, 0xFFFFFFFF, HPU_SPINN_STOP_KEY_REG);
	}
}

static int hpu_spinn_keys_enable(struct hpu_priv *priv, int enable)
{
	if (enable != !!enable) {
		dev_notice(&priv->pdev->dev, "Invalid enable/disable value\n");
		return -EINVAL;
	}
	priv->spinn_keys_enable = enable;
	if (priv->spinn_keys_enable) {
		dev_dbg(&priv->pdev->dev, "Enabling start/stop keys\n");
		hpu_spinn_do_set_keys(priv);
	} else {
		dev_dbg(&priv->pdev->dev, "Disabling start/stop keys\n");
		hpu_spinn_do_startstop(priv);
	}

	return 0;
}

static int hpu_spinn_startstop(struct hpu_priv *priv, int start)
{
	priv->spinn_start = start;
	hpu_spinn_do_startstop(priv);
	if (priv->spinn_keys_enable)
		hpu_spinn_do_set_keys(priv);
	return 0;
}

static int hpu_spinn_set_keys(struct hpu_priv *priv, u32 start, u32 stop)
{
	if (start == stop) {
		dev_notice(&priv->pdev->dev, "Start and stop keys must differ\n");
		return -EINVAL;
	}

	priv->spinn_start_key = start;
	priv->spinn_stop_key = stop;

	dev_dbg(&priv->pdev->dev, "Setting keys START:0x%x STOP:0x%x\n",
		priv->spinn_start_key, priv->spinn_stop_key);

	if (priv->spinn_keys_enable)
		hpu_spinn_do_set_keys(priv);

	return 0;
}

static int hpu_set_rx_interface(struct hpu_priv *priv,
				hpu_interface_t interf, hpu_interface_cfg_t cfg)
{
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

	switch (interf) {
	case INTERFACE_EYE_R:
		bitfield <<= 16;
		mask <<= 16;
		/* fall through */
	case INTERFACE_EYE_L:
		priv->rx_ctrl_reg &= ~mask;
		priv->rx_ctrl_reg |= bitfield;
		hpu_reg_write(priv, priv->rx_ctrl_reg, HPU_RXCTRL_REG);
		dev_dbg(&priv->pdev->dev, "RXCTRL reg 0x%x\n", bitfield);
		break;
	case INTERFACE_AUX:
		priv->rx_aux_ctrl_reg = bitfield;
		hpu_reg_write(priv, priv->rx_aux_ctrl_reg, HPU_AUX_RXCTRL_REG);
		dev_dbg(&priv->pdev->dev, "AUXRXCTRL reg 0x%x\n", bitfield);
		break;
	default:
		return -EINVAL;
		break;
	}

	return 0;
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

	dev_dbg(&priv->pdev->dev, "writing TX CTRL REG: 0x%x\n", reg);
	hpu_reg_write(priv, reg, HPU_TXCTRL_REG);

	return 0;
}

static int hpu_set_loop_cfg(struct hpu_priv *priv, spinn_loop_t loop)
{
	priv->ctrl_reg &= ~(HPU_CTRL_LOOP_LNEAR | HPU_CTRL_LOOP_SPINN);
	switch (loop) {
	case LOOP_LSPINN:
		priv->ctrl_reg |= HPU_CTRL_LOOP_SPINN;
		break;

	case LOOP_LNEAR:
		priv->ctrl_reg |= HPU_CTRL_LOOP_LNEAR;
		break;

	case LOOP_NONE:
		break;
	default:
		dev_notice(&priv->pdev->dev,
			   "set loop - invalid arg %d\n", loop);
		return -EINVAL;
		break;
	}

	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);
	dev_dbg(&priv->pdev->dev, "set loop - CTRL reg 0x%x",
		priv->ctrl_reg);

	return 0;
}

static void hpu_do_set_axis_lat(struct hpu_priv *priv)
{
	u32 lat;
	unsigned long rate;


	rate = clk_get_rate(priv->clk);
	lat = rate / 1000 * priv->axis_lat;

	hpu_reg_write(priv, lat, HPU_TLAST_TIMEOUT);
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

static int hpu_set_timestamp(struct hpu_priv *priv, unsigned int val)
{
	if (val != !!val)
		return -EINVAL;

	/* if dma is enabled then disable and also flush fifo */
	if (val)
		priv->ctrl_reg |= HPU_CTRL_FULLTS;
	else
		priv->ctrl_reg &= ~HPU_CTRL_FULLTS;

	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);

	return 0;
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

	priv->hpu_is_opened = 1;
	ret = hpu_dma_init(priv);
	if (ret) {
		mutex_unlock(&priv->access_lock);
		return ret;
	}

	if (priv->dma_tx_chan) {
		priv->dma_tx_pool.ps = tx_ps;
		priv->dma_tx_pool.pn = tx_pn;
		ret = hpu_dma_alloc_pool(priv, &priv->dma_tx_pool);

		if (ret) {
			dev_err(&priv->pdev->dev,
				"Error allocating memory from TX DMA pool\n");
			goto err_dealloc_dma;
		}
	}

	priv->dma_rx_pool.ps = rx_ps;
	priv->dma_rx_pool.pn = rx_pn;
	ret = hpu_dma_alloc_pool(priv, &priv->dma_rx_pool);

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

	priv->spinn_start_key = HPU_DEFAULT_START_KEY;
	priv->spinn_stop_key = HPU_DEFAULT_STOP_KEY;
	priv->spinn_start = 0;
	priv->spinn_keys_enable = 1;
	hpu_spinn_do_startstop(priv);
	hpu_spinn_do_set_keys(priv);

	priv->rx_aux_ctrl_reg = 0;
	priv->rx_ctrl_reg = 0;
	hpu_reg_write(priv, priv->rx_aux_ctrl_reg, HPU_AUX_RXCTRL_REG);
	hpu_reg_write(priv, priv->rx_ctrl_reg, HPU_RXCTRL_REG);

	/* Initialize HPU with full TS, no loop */
	priv->ctrl_reg = HPU_CTRL_FULLTS;
	hpu_reg_write(priv, priv->ctrl_reg |
		      HPU_CTRL_FLUSH_TX_FIFO | HPU_CTRL_FLUSH_RX_FIFO,
		      HPU_CTRL_REG);

	/* Set RX DMA max pkt len (data count before TLAST) */
	reg = priv->dma_rx_pool.ps / 4;
	if (test_dma)
		reg |= HPU_DMA_TEST_ON;
	hpu_reg_write(priv, reg , HPU_DMA_REG);

	priv->axis_lat = 10; /* mS */
	if (test_dma)
		priv->irq_msk = 0;
	else
		/* Unmask RXFIFOFULL interrupt */
		priv->irq_msk = HPU_MSK_INT_RXFIFOFULL;

	hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);
	/* clear all INTs */
	hpu_reg_write(priv, 0xffffffff, HPU_IRQ_REG);

	priv->ctrl_reg |= HPU_CTRL_ENINT | HPU_CTRL_ENDMA;
	if (!IS_ERR(priv->clk)) {
		priv->ctrl_reg |= HPU_CTRL_AXIS_LAT;
		hpu_do_set_axis_lat(priv);
	}
	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);

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
	ktime_t time;

	mutex_lock(&priv->access_lock);
	mutex_lock(&priv->dma_rx_pool.mutex_lock);
	mutex_lock(&priv->dma_tx_pool.mutex_lock);

	spin_lock_irqsave(&priv->irq_lock, flags);
	/* Disable RX */
	hpu_reg_write(priv, 0x0, HPU_RXCTRL_REG);
	hpu_reg_write(priv, 0x0, HPU_AUX_RXCTRL_REG);
	/* Disable TX */
	hpu_reg_write(priv, 0x0, HPU_TXCTRL_REG);

	/* Mask interrupts - this ensure that pending IRQ are ignored by ISR */
	priv->irq_msk = 0;
	hpu_reg_write(priv, priv->irq_msk, HPU_IRQMASK_REG);
	spin_unlock_irqrestore(&priv->irq_lock, flags);

	/*
	 * Ease fifo flushing - in order for DMA to be disabled the stream must
	 * end with a TLAST
	 */
	hpu_reg_write(priv, 1, HPU_TLAST_TIMEOUT);

	/* Disable DMA and interrupts */
        priv->ctrl_reg &= ~(HPU_CTRL_ENDMA | HPU_CTRL_ENINT);
	hpu_reg_write(priv, priv->ctrl_reg, HPU_CTRL_REG);

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
		hpu_flush_rx_fifo(priv);
		msleep(5);
	}

	priv->spinn_start = 0;
	hpu_spinn_do_startstop(priv);

	hpu_reg_write(priv, priv->ctrl_reg | HPU_CTRL_RESETDMASTREAM,
	        HPU_CTRL_REG);

	hpu_reg_write(priv, priv->ctrl_reg |
		      HPU_CTRL_FLUSH_TX_FIFO | HPU_CTRL_FLUSH_RX_FIFO,
		      HPU_CTRL_REG);

	mdelay(100);
	cancel_work_sync(&priv->rx_housekeeping_work);

	hpu_dma_release(priv);
	priv->hpu_is_opened = 0;
	hpu_clk_disable(priv);

	mutex_unlock(&priv->dma_tx_pool.mutex_lock);
	mutex_unlock(&priv->dma_rx_pool.mutex_lock);
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
		hpu_reg_write(priv, 0x00000000, HPU_RXCTRL_REG);
		hpu_reg_write(priv, 0x00000000, HPU_AUX_RXCTRL_REG);

		/* Flush the RX FIFO */
		hpu_reg_write(priv,
			      priv->ctrl_reg | HPU_CTRL_FLUSH_RX_FIFO,
			      HPU_CTRL_REG);

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

	case _IOW(0x0, HPU_IOCTL_SET_SPINN_KEYS_EN, unsigned int *):
		if (copy_from_user(&val, arg, sizeof(unsigned int)))
			goto cfuser_err;
		res = hpu_spinn_keys_enable(priv, val);
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
		priv->axis_lat = val;
		hpu_do_set_axis_lat(priv);
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
	if (IS_ERR(priv->clk))
		dev_warn(&priv->pdev->dev, "cannot get clock: s_axi_aclk; disabling AXIS latency timeout\n");

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

	hpu_register_chardev(priv);

	if (hpu_debugfsdir) {
		sprintf(buf, "hpu.%x", res->start);
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
