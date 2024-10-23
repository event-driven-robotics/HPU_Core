/*
 * HeadProcessorUnit (HPUCore) Register Definitions
 *
 * Copyright (c) 2016 Istituto Italiano di Tecnologia
 * Electronic Design Lab.
 *
 */

#define HPU_CTRL_REG                  0x00
#define HPU_LPBK_LR_CNFG_REG          0x04
#define HPU_RXDATA_REG                0x08
#define HPU_RXTIME_REG                0x0C
#define HPU_DMA_REG                   0x14
#define HPU_STAT_RAW_REG              0x18
#define HPU_IRQ_REG                   0x1C
#define HPU_MSK_REG                   0x20
#define HPU_WRAPTIMESTAMP_REG         0x28
#define HPU_HSSAER_STAT_REG           0x34
#define HPU_HSSAER_RX_ERR_REG         0x38
#define HPU_HSSAER_RX_MSK_REG         0x3C
#define HPU_RX_CTRL_REG               0x40
#define HPU_TX_CTRL_REG	              0x44
#define HPU_RX_PAER_CNFG_REG          0x48
#define HPU_TX_PAER_CNFG_REG          0x4C
#define HPU_IP_CNFG_REG               0x50
#define HPU_FIFO_THRSH_REG            0x54
#define HPU_LPBK_AUX_CNFG_REG         0x58
#define HPU_ID_REG                    0x5C
#define HPU_AUX_RX_CTRL_REG           0x60
#define HPU_HSSAER_AUX_RX_ERR_REG     0x64
#define HPU_HSSAER_AUX_RX_MSK_REG     0x68
#define HPU_HSSAER_AUX_RX_ERR_THR_REG 0x6C
#define HPU_HSSAER_AUX_RX_ERR_CH0_REG 0x70
#define HPU_HSSAER_AUX_RX_ERR_CH1_REG 0x74
#define HPU_HSSAER_AUX_RX_ERR_CH2_REG 0x78
#define HPU_HSSAER_AUX_RX_ERR_CH3_REG 0x7C
#define HPU_SPNN_START_KEY_REG        0x80
#define HPU_SPNN_STOP_KEY_REG         0x84
#define HPU_SPNN_TX_MASK_REG          0x88
#define HPU_SPNN_RX_MASK_REG          0x8C
#define HPU_SPNN_CTRL_REG             0x90
#define HPU_TLASTTO_REG               0xA0
#define HPU_TLASTCNT_REG              0xA4
#define HPU_TDATACNT_REG              0xA8

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
