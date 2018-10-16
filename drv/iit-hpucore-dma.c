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

/* max HPUs that can be handled */
#define HPU_MINOR_COUNT 10

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

/* magic constants */
#define HPU_VER_MAGIC			0x42303130

#define HPU_CTRL_DMA_RUNNING		0x0001
#define HPU_CTRL_ENDMA			0x0002
#define HPU_CTRL_ENINT			0x0004
#define HPU_CTRL_FLUSHFIFOS		0x0010
#define HPU_CTRL_RESETDMASTREAM 	0x1000
#define HPU_CTRL_FULLTS			0x8000

#define HPU_DMA_LENGTH_MASK		0x7FF
#define HPU_DMA_TEST_ON			0x10000

#define HPU_RXCTRL_LRXHSSAER_EN		0x00000001
#define HPU_RXCTRL_LRXPAER_EN		0x00000002
#define HPU_RXCTRL_LRXFTP_EN		0x00000004
#define HPU_RXCTRL_SPINNL_EN		0x00000008
#define HPU_RXCTRL_LRXHSSAERCH0_EN	0x00000100
#define HPU_RXCTRL_LRXHSSAERCH1_EN	0x00000200
#define HPU_RXCTRL_LRXHSSAERCH2_EN	0x00000400
#define HPU_RXCTRL_LRXHSSAERCH3_EN	0x00000800

#define HPU_RXCTRL_RRXHSSAER_EN		0x00010000
#define HPU_RXCTRL_RRXPAER_EN		0x00020000
#define HPU_RXCTRL_RRXFTP_EN		0x00040000
#define HPU_RXCTRL_SPINNR_EN		0x00080000
#define HPU_RXCTRL_RRXHSSAERCH0_EN	0x01000000
#define HPU_RXCTRL_RRXHSSAERCH1_EN	0x02000000
#define HPU_RXCTRL_RRXHSSAERCH2_EN	0x04000000
#define HPU_RXCTRL_RRXHSSAERCH3_EN	0x08000000

#define HPU_MSK_INT_RXFIFOFULL		0x004
#define HPU_MSK_INT_TSTAMPWRAPPED	0x080
#define HPU_MSK_INT_RXBUFFREADY		0x100
#define HPU_MSK_INT_GLBLRXERR_KO	0x00010000
#define HPU_MSK_INT_GLBLRXERR_RX	0x00020000
#define HPU_MSK_INT_GLBLRXERR_TO	0x00040000
#define HPU_MSK_INT_GLBLRXERR_OF	0x00080000

#define HPU_AUXCTRL_AUXRXHSSAER_EN	0x00000001
#define HPU_AUXCTRL_AUXRXPAER_EN	0x00000002
#define HPU_AUXCTRL_AUXRXFTP_EN		0x00000004
#define HPU_AUXCTRL_AUXSPINN_EN		0x00000008
#define HPU_AUXCTRL_AUXRXHSSAERCH0_EN	0x00000100
#define HPU_AUXCTRL_AUXRXHSSAERCH1_EN	0x00000200
#define HPU_AUXCTRL_AUXRXHSSAERCH2_EN	0x00000400
#define HPU_AUXCTRL_AUXRXHSSAERCH3_EN	0x00000800

#define HPU_IOCTL_READTIMESTAMP		1
#define HPU_IOCTL_CLEARTIMESTAMP	2
#define HPU_IOCTL_READVERSION		3
/* 4 is not used anymore */
#define HPU_IOCTL_SETTIMESTAMP		7
/* 8 is not used anymore */
#define HPU_IOCTL_GET_RX_PS		9
#define HPU_IOCTL_SET_AUX_THRS		10
#define HPU_IOCTL_GET_AUX_THRS		11
#define HPU_IOCTL_GET_AUX_CNT0		12
#define HPU_IOCTL_GET_AUX_CNT1		13
#define HPU_IOCTL_GET_AUX_CNT2		14
#define HPU_IOCTL_GET_AUX_CNT3		15
#define HPU_IOCTL_GET_LOST_CNT		16
#define HPU_IOCTL_SET_HSSAER_CH		17
#define HPU_IOCTL_SET_LOOP_CFG		18
#define HPU_IOCTL_SET_SPINN		19
#define HPU_IOCTL_GET_TX_PS		20

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
};


static short int rx_fifo_full = 0;

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


enum hssaersrc { left_eye = 0, right_eye, aux, spinn };

typedef struct ch_en_hssaer {
	enum hssaersrc hssaer_src;
	uint8_t en_channels;
} ch_en_hssaer_t;

enum rx_err { ko_err = 0, rx_err, to_err, of_err, nomeaning_err };

typedef struct aux_cnt {
	enum rx_err err;
	uint8_t cnt_val;
} aux_cnt_t;

struct hpu_priv;

struct hpu_buf {
	dma_addr_t phys;
	void *virt;
	int fill_index;
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

struct hpu_priv {
	struct dentry *regset;
	struct cdev cdev;
	struct platform_device *pdev;
	dev_t devt;
	int id;
	unsigned int irq;
	struct mutex access_lock;
	unsigned int hpu_is_opened;
	void __iomem *regs;
	uint32_t ctrl_reg;
	wait_queue_head_t wait;

	/* dma */
	struct hpu_dma_pool dma_rx_pool;
	struct hpu_dma_pool dma_tx_pool;
	struct dma_chan *dma_rx_chan;
	struct dma_chan *dma_tx_chan;
	struct work_struct rx_housekeeping_work;
	unsigned int cnt_pktloss;
	int pkt_txed;
	unsigned long byte_txed;
	int pkt_rxed;
	unsigned long byte_rxed;
};

static struct dentry *hpu_debugfsdir = NULL;
static struct class *hpu_class = NULL;
static dev_t hpu_devt;
static DEFINE_IDA(hpu_ida);

static int hpu_rx_dma_submit_buffer(struct hpu_priv *priv, struct hpu_buf *buf);
static void hpu_dma_free_pool(struct hpu_priv *priv, struct hpu_dma_pool *hpu_pool);
static int _hpu_chardev_close(struct hpu_priv *priv);

static void hpu_tx_dma_callback(void *_buffer)
{
	struct hpu_buf *buffer = _buffer;
	struct hpu_priv *priv = buffer->priv;

	/* mark as spare */
	spin_lock(&priv->dma_tx_pool.spin_lock);
	buffer->fill_index = 0;
	priv->dma_tx_pool.filled--;
	complete(&priv->dma_tx_pool.completion);
	spin_unlock(&priv->dma_tx_pool.spin_lock);
}

static void hpu_rx_housekeeping(struct work_struct *work)
{
	struct hpu_priv *priv = container_of(work, struct hpu_priv,
					     rx_housekeeping_work);

	int ret;

	dev_dbg(&priv->pdev->dev, "RX housekeeping ..\n");
	mutex_lock(&priv->dma_rx_pool.mutex_lock);

	spin_lock_bh(&priv->dma_rx_pool.spin_lock);
	/* data has been already drained */
	if (priv->dma_rx_pool.filled < (priv->dma_rx_pool.pn - 1)) {
		spin_unlock_bh(&priv->dma_rx_pool.spin_lock);
		mutex_unlock(&priv->dma_rx_pool.mutex_lock);
		return;
	}

	priv->dma_rx_pool.filled--;
	spin_unlock_bh(&priv->dma_rx_pool.spin_lock);

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
	mutex_unlock(&priv->dma_rx_pool.mutex_lock);
}

static void hpu_rx_dma_callback(void *_buffer)
{
	struct hpu_buf *buffer = _buffer;
	struct hpu_priv *priv = buffer->priv;

	dev_dbg(&priv->pdev->dev, "RX DMA cb\n");
	priv->pkt_rxed++;
	priv->byte_rxed += priv->dma_rx_pool.ps;

	spin_lock(&priv->dma_rx_pool.spin_lock);
	priv->dma_rx_pool.filled++;

	if (priv->dma_rx_pool.filled == 1) {
		dev_dbg(&priv->pdev->dev, "RX DMA waking up reader\n");
		/* ring was empty. wake reader, if any.. */
		complete(&priv->dma_rx_pool.completion);
	} else if (priv->dma_rx_pool.filled == (priv->dma_rx_pool.pn - 1)) {
		dev_dbg(&priv->pdev->dev, "RX DMA scheduling worker\n");
		/* ring getting full, throw away old data to make room new one */
		schedule_work(&priv->rx_housekeeping_work);
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
	int time_left;
	int i = 0;
	int count = 0;
	struct hpu_priv *priv = fp->private_data;

	/* allow only pairs TS+VAL that is 4+4 bytes */
	if (lenght % 8)
		return -EINVAL;

	if (!access_ok(VERIFY_WRITE, buf, lenght))
		return -EFAULT;

	while (i < lenght) {
		copy = min_t(size_t, priv->dma_tx_pool.ps, lenght);
		dma_buf = &priv->dma_tx_pool.ring[priv->dma_tx_pool.buf_index];

		spin_lock_bh(&priv->dma_tx_pool.spin_lock);
		while (dma_buf->fill_index) {
			dev_dbg(&priv->pdev->dev, "suspending TX\n");
			spin_unlock_bh(&priv->dma_tx_pool.spin_lock);
			time_left =
				wait_for_completion_timeout(&priv->dma_tx_pool.completion,
							    msecs_to_jiffies(tx_to));
			if (time_left == 0) {
				dev_err(&priv->pdev->dev, "TX DMA timed out\n");
				return -ETIMEDOUT;
			}
			dev_dbg(&priv->pdev->dev, "resuming TX\n");
			spin_lock_bh(&priv->dma_tx_pool.spin_lock);
		}

		priv->dma_tx_pool.filled++;

		spin_unlock_bh(&priv->dma_tx_pool.spin_lock);

		if (__copy_from_user(dma_buf->virt, buf, copy)) {
			dev_err(&priv->pdev->dev, "failed copying from user\n");
			return -EINVAL;
		}

		dma_buf->fill_index = copy;

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

		if (count++ > (priv->dma_tx_pool.pn / 2)) {
			count = 0;
			dma_async_issue_pending(priv->dma_tx_chan);
		}

		priv->dma_tx_pool.buf_index = (priv->dma_tx_pool.buf_index + 1)
			& (priv->dma_tx_pool.pn - 1);
	}

	if (count)
		dma_async_issue_pending(priv->dma_tx_chan);

	return i;
}

static ssize_t hpu_chardev_read(struct file *fp, char *buf, size_t length,
				loff_t *offset)
{
	int ret, ret2;
	int copy;
	u32 msk;
	int index;
	size_t buf_count;
	struct hpu_buf *item;
	int read = 0;

	struct hpu_priv *priv = fp->private_data;

	if (!access_ok(VERIFY_READ, buf, length))
		return -EFAULT;

	/* Unmask RXFIFOFULL interrupt */
	msk = readl(priv->regs + HPU_IRQMASK_REG);
	msk |= HPU_MSK_INT_RXFIFOFULL;
	writel(msk, priv->regs + HPU_IRQMASK_REG);
	rx_fifo_full = 0;

	dev_dbg(&priv->pdev->dev, "----tot to read %d\n", length);

	mutex_lock(&priv->dma_rx_pool.mutex_lock);

	while (length > 0) {
		if (rx_fifo_full == 1)
			goto error_rx_fifo_full;

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
			if (priv->dma_rx_pool.filled > 0)
				break;

			/* drain away any completion leftover */
			try_wait_for_completion(&priv->dma_rx_pool.completion);
			spin_unlock_bh(&priv->dma_rx_pool.spin_lock);

			dev_dbg(&priv->pdev->dev, "wait for dma\n");
			if (wait_for_completion_timeout(&priv->dma_rx_pool.completion,
							msecs_to_jiffies(rx_to)) == 0) {
				dev_err(&priv->pdev->dev, "DMA timed out\n");
				mutex_unlock(&priv->dma_rx_pool.mutex_lock);
				return -ETIMEDOUT;
			}
		}

		/* we got here with lock held */
		spin_unlock_bh(&priv->dma_rx_pool.spin_lock);

		index = priv->dma_rx_pool.buf_index;
		item = &priv->dma_rx_pool.ring[index];
		dev_dbg(&priv->pdev->dev, "reading dma descriptor %d\n", index);

		BUG_ON(DMA_COMPLETE != dma_async_is_tx_complete(
			       priv->dma_rx_chan,
			       priv->dma_rx_pool.ring[index].cookie,
			       NULL, NULL));

		/* data still in buf */
		buf_count = priv->dma_rx_pool.ps - item->fill_index;
		copy = min(length, buf_count);

		dev_dbg(&priv->pdev->dev, "going to read %d bytes from offset %d\n",
			length, item->fill_index);

		ret = __copy_to_user(buf + read,
				     item->virt + item->fill_index, copy);
		if (ret < 0) {
			dev_warn(&priv->pdev->dev, "failed to copy from userspace");
			break;
		}
		/* if ret > 0, then it is the number of _uncopied_ bytes */
		copy -= ret;

		BUG_ON((item->fill_index + copy) > priv->dma_rx_pool.ps);
		if ((item->fill_index + copy) == priv->dma_rx_pool.ps) {
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
			item->fill_index += copy;
			BUG_ON(item->fill_index >= priv->dma_rx_pool.ps);
			dev_dbg(&priv->pdev->dev, "partially consumed, up to %d\n",
				item->fill_index);
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
	mutex_unlock(&priv->dma_rx_pool.mutex_lock);

	/*
	 * AM: I kept the same behaviour here as before, but I'm not sure it
	 * is sane to force a close when a read fails.
	 */
	_hpu_chardev_close(priv);
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
		dma_release_channel(priv->dma_rx_chan);
		priv->dma_tx_chan = NULL;
		dev_err(&priv->pdev->dev, "Can't bind TX DMA chan\n");
		return -ENODEV;
	}

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
		hpu_pool->ring[i].fill_index = 0;
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

	dma_desc->callback = hpu_rx_dma_callback;
	dma_desc->callback_param = buf;

	cookie = dmaengine_submit(dma_desc);
	buf->cookie = cookie;
	/* this buffer is new and has to be fully read */
	buf->fill_index = 0;

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

static int hpu_chardev_open(struct inode *i, struct file *f)
{
	int ret = 0;
	u32 msk;
	struct hpu_priv *priv = container_of(i->i_cdev,
					     struct hpu_priv, cdev);

	f->private_data = priv;

	mutex_lock(&priv->access_lock);
	if (priv->hpu_is_opened == 1) {
		mutex_unlock(&priv->access_lock);
		return -EBUSY;
	}

	priv->pkt_txed = 0;
	priv->byte_txed = 0;
	priv->pkt_rxed = 0;
	priv->byte_rxed = 0;

	priv->hpu_is_opened = 1;
	ret = hpu_dma_init(priv);
	if (ret) {
		mutex_unlock(&priv->access_lock);
		return ret;
	}

	priv->dma_tx_pool.ps = tx_ps;
	priv->dma_tx_pool.pn = tx_pn;
	ret = hpu_dma_alloc_pool(priv, &priv->dma_tx_pool);

	if (ret) {
		dev_err(&priv->pdev->dev,
			"Error allocating memory from TX DMA pool\n");
		goto err_dealloc_dma;
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

	if (!test_dma) {
		/* Unmask RXFIFOFULL interrupt */
		msk = readl(priv->regs + HPU_IRQMASK_REG);
		msk |= HPU_MSK_INT_RXFIFOFULL;
		writel(msk, priv->regs + HPU_IRQMASK_REG);
	}

	priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
	priv->ctrl_reg |= HPU_CTRL_FLUSHFIFOS;
	priv->ctrl_reg |= HPU_CTRL_FULLTS;
	writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);

	priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
	priv->ctrl_reg |= HPU_CTRL_ENINT | HPU_CTRL_ENDMA;
	writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);
	mutex_unlock(&priv->access_lock);

	return 0;

err_dealloc_dma:
	hpu_dma_release(priv);
	mutex_unlock(&priv->access_lock);

	return ret;
}

static int _hpu_chardev_close(struct hpu_priv *priv)
{
	uint32_t val;

	mutex_lock(&priv->access_lock);

	/* Read CTRL_Register and Disable The IP */
	val = readl(priv->regs + HPU_CTRL_REG);
	val = val & ~HPU_CTRL_ENDMA;
	writel(val, priv->regs + HPU_CTRL_REG);

	val = readl(priv->regs + HPU_CTRL_REG);
	val = val | HPU_CTRL_RESETDMASTREAM;
	writel(val, priv->regs + HPU_CTRL_REG);

	priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
	priv->ctrl_reg |= HPU_CTRL_FLUSHFIFOS;
	writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);

	writel(0x00000000, priv->regs + HPU_RXCTRL_REG);
	writel(0x00000000, priv->regs + HPU_AUX_RXCTRL_REG);

	/* TX reg to reset val */
	writel(0x0, priv->regs + HPU_TXCTRL_REG);
	mdelay(100);
	cancel_work_sync(&priv->rx_housekeeping_work);

	hpu_dma_release(priv);
	priv->hpu_is_opened = 0;
	mutex_unlock(&priv->access_lock);

	return 0;
}

static int hpu_chardev_close(struct inode *i, struct file *fp)
{
	struct hpu_priv *priv = fp->private_data;

	return _hpu_chardev_close(priv);
}

static void hpu_handle_err(struct hpu_priv *priv)
{
	uint32_t reg;
	int i;
	uint8_t num_channel = 0;
	int is_aux = 0;

	/* Detect which RX HSSAER channel is enabled */
	reg = readl(priv->regs + HPU_RXCTRL_REG);
	/* Check Left SAER */
	if (reg & 0x1)
		num_channel = num_channel | (reg & (0xF << 8)) >> 8;
	/* Check Right SAER */
	if (reg & 0x10000)
		num_channel = num_channel | (reg & (0xF << 24)) >> 24;

	/* Check Left Aux Saer */
	reg = readl(priv->regs + HPU_AUX_RXCTRL_REG);
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
					 readl(priv->regs +
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
	uint32_t msk;
	struct hpu_priv *priv = platform_get_drvdata(pdev);
	irqreturn_t retval = 0;

	priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
	priv->ctrl_reg &= ~HPU_CTRL_ENINT;
	writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);

	intr = readl(priv->regs + HPU_IRQ_REG);

	if (intr & HPU_MSK_INT_TSTAMPWRAPPED) {
		writel(HPU_MSK_INT_TSTAMPWRAPPED, priv->regs + HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_RXBUFFREADY) {
		dev_info(&priv->pdev->dev, "IRQ: RXBUFFREADY\n");
		writel(HPU_MSK_INT_RXBUFFREADY, priv->regs + HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_RXFIFOFULL) {
		dev_info(&priv->pdev->dev, "IRQ: RXFIFOFULL\n");
		/* Flush the FIFO */
		priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
		priv->ctrl_reg |= HPU_CTRL_FLUSHFIFOS;
		writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);
		/* Delete the interrupt */
		writel(HPU_MSK_INT_RXFIFOFULL, priv->regs + HPU_IRQ_REG);
		/* Deactivate RXFIFOFULL interrupt */
//		msk = readl(priv->regs + HPU_IRQMASK_REG);
//		msk &= (~HPU_MSK_INT_RXFIFOFULL);
//		writel(msk, priv->regs + HPU_IRQMASK_REG);

//		rx_fifo_full = 1;
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_KO) {
		dev_info(&priv->pdev->dev, "IRQ: RX KO Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		writel(HPU_MSK_INT_GLBLRXERR_KO, priv->regs + HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_RX) {
		dev_info(&priv->pdev->dev, "IRQ: RX RX Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		writel(HPU_MSK_INT_GLBLRXERR_RX, priv->regs + HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_TO) {
		dev_info(&priv->pdev->dev, "IRQ: RX TO Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		writel(HPU_MSK_INT_GLBLRXERR_TO, priv->regs + HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	if (intr & HPU_MSK_INT_GLBLRXERR_OF) {
		dev_info(&priv->pdev->dev, "IRQ: RX OF Err\n");
		hpu_handle_err(priv);
		/* Clear the interrupt */
		writel(HPU_MSK_INT_GLBLRXERR_OF, priv->regs + HPU_IRQ_REG);
		retval = IRQ_HANDLED;
	}

	priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
	priv->ctrl_reg |= HPU_CTRL_ENINT;
	writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);

	retval = IRQ_HANDLED;
	return retval;
}

static long hpu_ioctl(struct file *fp, unsigned int cmd, unsigned long arg)
{
	unsigned int ret;
	unsigned int val = 0;
	aux_cnt_t aux_cnt_reg;
	ch_en_hssaer_t ch_en_hssaer;
	unsigned int reg, reg2;

	struct hpu_priv *priv = fp->private_data;

	dev_dbg(&priv->pdev->dev, "ioctl %x\n", cmd);

	switch (cmd) {

	case _IOR(0x0, HPU_IOCTL_READTIMESTAMP, unsigned int):
		ret = readl(priv->regs + HPU_WRAP_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_CLEARTIMESTAMP, unsigned int):
		writel(0, priv->regs + HPU_WRAP_REG);
		break;

	case _IOR(0x0, HPU_IOCTL_READVERSION, unsigned int):
		ret = readl(priv->regs + HPU_VER_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		dev_info(&priv->pdev->dev, "Reading version %d\n", ret);
		break;

	case _IOW(0x0, HPU_IOCTL_SETTIMESTAMP, unsigned int *):
		if (copy_from_user(&val, (unsigned int *) arg, sizeof(val)))
			goto cfuser_err;

		/* if dma is enabled then disable and also flush fifo */
		priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
		if (val)
			priv->ctrl_reg |= HPU_CTRL_FULLTS;
		else
			priv->ctrl_reg &= ~HPU_CTRL_FULLTS;

		writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);
		break;

	case _IOR(0x0, HPU_IOCTL_GET_RX_PS, unsigned int *):
		ret = priv->dma_rx_pool.ps;
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_TX_PS, unsigned int *):
		ret = priv->dma_tx_pool.ps;
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_SET_AUX_THRS, struct aux_cnt *):
		if (copy_from_user(&aux_cnt_reg, (struct aux_cnt*)arg,
				   sizeof(aux_cnt_reg)))
			goto cfuser_err;

		reg = readl(priv->regs + HPU_AUX_RX_ERR_THRS_REG);
		/* Normalize to num of errors, avoiding not valid errors */
		aux_cnt_reg.err = aux_cnt_reg.err % nomeaning_err;
		/* Clear the relevant byte */
		reg = reg & (~((0xFF) << (aux_cnt_reg.err * 8)));
		/* Write the register */
		writel((0xFF & aux_cnt_reg.cnt_val) <<
		       (aux_cnt_reg.err * 8) | reg,
		       priv->regs + HPU_AUX_RX_ERR_THRS_REG);
		/* Read and print the register */
		reg = readl(priv->regs + HPU_AUX_RX_ERR_THRS_REG);

		dev_dbg(&priv->pdev->dev,
			"HPU_AUX_RX_ERR_THRS_REG 0x%08X\n", reg);

		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_THRS, unsigned int *):
		ret = readl(priv->regs + HPU_AUX_RX_ERR_THRS_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT0, unsigned int *):
		ret = readl(priv->regs + HPU_AUX_RX_ERR_CH0_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT1, unsigned int *):
		ret = readl(priv->regs + HPU_AUX_RX_ERR_CH1_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT2, unsigned int *):
		ret = readl(priv->regs + HPU_AUX_RX_ERR_CH2_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_AUX_CNT3, unsigned int *):
		ret = readl(priv->regs + HPU_AUX_RX_ERR_CH3_REG);
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOR(0x0, HPU_IOCTL_GET_LOST_CNT, unsigned int *):
		ret = priv->cnt_pktloss;
		priv->cnt_pktloss = 0;
		if (copy_to_user((unsigned int *)arg, &ret,
				 sizeof(unsigned int)))
			goto cfuser_err;
		break;

	case _IOW(0x0, HPU_IOCTL_SET_HSSAER_CH, struct ch_en_hssaer *):
		if (copy_from_user(&ch_en_hssaer, (struct ch_en_hssaer *)arg,
				   sizeof(ch_en_hssaer)))
			goto cfuser_err;

		if (ch_en_hssaer.hssaer_src < left_eye ||
		    ch_en_hssaer.hssaer_src > aux) {
			dev_err(&priv->pdev->dev,
			       "Error in enabling channels\n");
			return -EINVAL;
		} else {
			if (ch_en_hssaer.hssaer_src == aux) {
				reg = readl(priv->regs + HPU_AUX_RXCTRL_REG);
				reg |= HPU_AUXCTRL_AUXRXHSSAER_EN |
					((ch_en_hssaer.en_channels) << 8);
				writel(reg, priv->regs + HPU_AUX_RXCTRL_REG);
			} else {
				reg = readl(priv->regs + HPU_RXCTRL_REG);

				/* don't overwrite spinn cfg, clear the rest */
				reg &= HPU_RXCTRL_SPINNL_EN |
					HPU_RXCTRL_SPINNR_EN;
				if (ch_en_hssaer.hssaer_src == left_eye) {
					reg |= HPU_RXCTRL_LRXHSSAER_EN |
						(ch_en_hssaer.en_channels << 8);
				} else {	/* right */
					reg |= HPU_RXCTRL_RRXHSSAER_EN |
						(ch_en_hssaer.en_channels << 24);
				}
			}
			writel(reg, priv->regs + HPU_RXCTRL_REG);
		}
		break;

	case _IOW(0x0, HPU_IOCTL_SET_SPINN, unsigned int *):
		if (copy_from_user(&val, (unsigned int *) arg, sizeof(val))) {
			goto cfuser_err;
		} else {
			reg = readl(priv->regs + HPU_AUX_RXCTRL_REG);
			reg2 = readl(priv->regs + HPU_RXCTRL_REG);
			if (val) {
				reg |= HPU_AUXCTRL_AUXSPINN_EN;
				reg2 |= HPU_RXCTRL_SPINNL_EN |
					HPU_RXCTRL_SPINNR_EN;
				/* magic from Maurizio */
				writel(0x68, priv->regs + HPU_TXCTRL_REG);
				dev_dbg(&priv->pdev->dev, "spinn enable\n");
			} else {
				reg &= ~HPU_AUXCTRL_AUXSPINN_EN;
				reg2 &=	~(HPU_RXCTRL_SPINNL_EN |
					  HPU_RXCTRL_SPINNR_EN);
				/* TX reg to reset val as per FD datasheet */
				writel(0x0, priv->regs + HPU_TXCTRL_REG);
				dev_dbg(&priv->pdev->dev, "spinn disable\n");
			}
			writel(reg2, priv->regs + HPU_RXCTRL_REG);
			writel(reg, priv->regs + HPU_AUX_RXCTRL_REG);
			dev_dbg(&priv->pdev->dev, "spinn - AUXRXCTRL reg 0x%x",
				reg);
		}
		break;

	case _IOW(0x0, HPU_IOCTL_SET_LOOP_CFG, unsigned int *):
		if (copy_from_user(&val, (unsigned int *)arg, sizeof(val)))
			goto cfuser_err;

		reg = readl(priv->regs + HPU_CTRL_REG);
		reg &= ~(BIT(22) | BIT(23));
		reg |= (val & 3) << 22;
		writel(reg, priv->regs + HPU_CTRL_REG);
		dev_dbg(&priv->pdev->dev, "set loop - CTRL reg 0x%x", reg);
		break;

	default:
		return -EINVAL;
	}

	return 0;

cfuser_err:
	dev_err(&priv->pdev->dev, "Copy from user space failed\n");
	return -EFAULT;

}

static struct file_operations hpu_fops = {
	.open = hpu_chardev_open,
	.owner = THIS_MODULE,
	.read = hpu_chardev_read,
	.write = hpu_chardev_write,
	.release = hpu_chardev_close,
	.unlocked_ioctl = hpu_ioctl,
};

static int hpu_register_chardev(struct hpu_priv *priv)
{
	int ret;

	cdev_init(&priv->cdev, &hpu_fops);

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

	mutex_init(&priv->access_lock);

	platform_set_drvdata(pdev, priv);
	priv->pdev = pdev;
	priv->ctrl_reg = 0;

	INIT_WORK(&priv->rx_housekeeping_work, hpu_rx_housekeeping);

	spin_lock_init(&priv->dma_rx_pool.spin_lock);
	spin_lock_init(&priv->dma_tx_pool.spin_lock);

	mutex_init(&priv->dma_rx_pool.mutex_lock);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	priv->regs = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(priv->regs)) {
		dev_err(&pdev->dev, "HPU has no regs in DT\n");
		kfree(priv);
		return PTR_ERR(priv->regs);
	}

	ver = readl(priv->regs + HPU_VER_REG);

	if (ver != HPU_VER_MAGIC) {
		dev_err(&pdev->dev, "HPU IP has wrong version: %x\n",
		       ver);
		kfree(priv);
		return -ENODEV;
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
	if (tx_ps < 8) {
		dev_warn(&priv->pdev->dev, "tx_ps too small. using default\n");
		tx_ps = HPU_TX_POOL_SIZE;
	}

	/* Set Burst entity of DMA */
	if (test_dma)
		writel(((rx_ps / 4 - 1) & HPU_DMA_LENGTH_MASK) | HPU_DMA_TEST_ON,
		       priv->regs + HPU_DMA_REG);
	else
		writel((rx_ps / 4 - 1) & HPU_DMA_LENGTH_MASK,
		       priv->regs + HPU_DMA_REG);

	init_completion(&priv->dma_rx_pool.completion);
	init_completion(&priv->dma_tx_pool.completion);

	hpu_register_chardev(priv);

	sprintf(buf, "regdump.%x", res->start);
	if (hpu_debugfsdir) {
		regset = devm_kzalloc(&pdev->dev, sizeof(*regset), GFP_KERNEL);
		if (!regset)
			return 0;
		regset->regs = hpu_regs;
		regset->nregs = ARRAY_SIZE(hpu_regs);
		regset->base = priv->regs;

		priv->regset = debugfs_create_regset32(buf, 0444, hpu_debugfsdir, regset);
	}

	return 0;
}

static int hpu_remove(struct platform_device *pdev)
{
	struct hpu_priv *priv = platform_get_drvdata(pdev);

	/* FIXME: resource release ! */
	debugfs_remove(priv->regset);
	priv->ctrl_reg = readl(priv->regs + HPU_CTRL_REG);
	priv->ctrl_reg &= ~HPU_CTRL_ENINT & ~HPU_CTRL_ENDMA;
	writel(priv->ctrl_reg, priv->regs + HPU_CTRL_REG);
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
