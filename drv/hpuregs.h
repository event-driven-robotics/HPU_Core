/*
 * HeadProcessorUnit (HPUCore) Register Definitions
 *
 * Copyright (c) 2016 Istituto Italiano di Tecnologia
 * Electronic Design Lab.
 *
 */

#define HPU_CTRL_REG            0x00
#define HPU_LPBK_LR_CNFG_REG    0x04
#define HPU_RXDATA_REG          0x08
#define HPU_RXTIME_REG          0x0C
#define HPU_DMA_REG             0x14
#define HPU_RAWSTAT_REG         0x18
#define HPU_IRQ_REG             0x1C
#define HPU_IRQMASK_REG         0x20
#define HPU_WRAP_REG            0x28
#define HPU_HSSAER_STAT_REG     0x34
#define HPU_HSSAER_RXERR_REG    0x38
#define HPU_HSSAER_RXMSK_REG    0x3C
#define HPU_RXCTRL_REG          0x40
#define HPU_TXCTRL_REG	        0x44
#define HPU_RXPAERCNFG_REG      0x48
#define HPU_TXPAERCNFG_REG      0x4C
#define HPU_IPCONFIG_REG        0x50
#define HPU_IPCONFIG_RXSAER     BIT(0)
#define HPU_IPCONFIG_RXPAER     BIT(1)
#define HPU_IPCONFIG_RXGTP      BIT(2)
#define HPU_IPCONFIG_RXSPINN    BIT(3)
#define HPU_IPCONFIG_RXSAERCH   4
#define HPU_IPCONFIG_TXSAER     BIT(8)
#define HPU_IPCONFIG_TXPAER     BIT(9)
#define HPU_IPCONFIG_TXGTP      BIT(10)
#define HPU_IPCONFIG_TXSPINN    BIT(11)
#define HPU_IPCONFIG_TXSAERCH   12
#define HPU_FIFOTHRESHOLD_REG   0x54
#define HPU_LPBK_AUX_CNFG_REG   0x58
#define HPU_VER_REG             0x5C
#define HPU_AUX_RXCTRL_REG      0x60
#define HPU_AUX_RX_ERR_REG      0x64
#define HPU_AUX_RX_MSK_REG      0x68
#define HPU_AUX_RX_ERR_THRS_REG 0x6C
#define HPU_AUX_RX_ERR_CH0_REG	0x70
#define HPU_AUX_RX_ERR_CH1_REG	0x74
#define HPU_AUX_RX_ERR_CH2_REG	0x78
#define HPU_AUX_RX_ERR_CH3_REG	0x7C
#define HPU_SPINN_START_KEY_REG 0x80
#define HPU_SPINN_STOP_KEY_REG	0x84
#define HPU_SPINN_TX_MASK_REG   0x88
#define HPU_SPINN_RX_MASK_REG   0x8C
#define HPU_SPINN_CTRL_REG      0x90
#define HPU_TLAST_TIMEOUT       0xA0
#define HPU_TLAST_COUNT         0xA4
#define HPU_DATA_COUNT	        0xA8
