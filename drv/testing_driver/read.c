/*
 * reading_atis.c
 *
 *  Created on: Nov 17, 2016
 *      Author: diotalev
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <string.h>
#include <signal.h>
#include <termios.h>
#include <time.h>

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <linux/spi/spidev.h>

/****************************************************************
 * Constants
 ****************************************************************/
#define I2C_EYE_LEFT  0x10
#define I2C_EYE_RIGHT 0x11
#define AUTOINCR      0x80
#define VSCTRL_VERSION	0x00005210

#define INFO_REG        0x00
#define SRCCNFG_REG		0x0C
#define SRCDSTCTRL_REG	0x10
#define DMA_REG         0x14
#define HSSAERCNFG_REG	0x18
#define BGCNFGCTRL_REG  0x20
#define BGPRESCALER_REG 0x24
#define BGTIMINGS_REG   0x28
#define BGWRDATA_REG    0x30
#define AUX_RX_CTRL_REG 0x60

#define READ            0
#define WRITE           1

#define ACKSETDELAY		2
#define SAMPLEDELAY		3
#define ACKRELEASEDELAY	5
#define ENABLECH0		1
#define ENABLECH1		2
#define ENABLECH2		4
#define ENABLECH3		8
#define SELDEST_SH      4
#define ENABLESAER_SH	1
#define APS_EN_SH       3
#define TD_EN_SH        1
#define SELDESTHSSAER   1

#define IF_MSK			0x0C000000
#define IF_PAER  		0x00000000
#define IF_SAER  		0x01000000
#define IF_GTP  		0x08000000

#define CH_MSK			0x00300000
#define CH_LEFT 		0x00000000
#define CH_RIGHT  		0x00100000
#define CH_AUX  		0x00200000

#define TYPE_MSK		0x00040000
#define TYPE_TD 		0x00000000
#define TYPE_APS  		0x00040000

#define DIFF_TIMESTAMP          80.0
#define UNITY_TIMESTAMP         0.000000001

#define IOC_MAGIC_NUMBER        0
#define IOC_READ_TS             _IOR(IOC_MAGIC_NUMBER, 1, unsigned int *)
#define IOC_CLEAR_TS            _IOW(IOC_MAGIC_NUMBER, 2, unsigned int *)
#define IOC_SET_TS_TYPE         _IOW(IOC_MAGIC_NUMBER, 7, unsigned int *)
#define IOC_GET_RX_PS           _IOR(IOC_MAGIC_NUMBER, 9, unsigned int *)
#define IOC_SET_LOOP_CFG        _IOW(IOC_MAGIC_NUMBER, 18, unsigned int *)
#define IOC_SET_SPINN           _IOW(IOC_MAGIC_NUMBER, 19, unsigned int *)
#define IOC_GET_TX_PS           _IOR(IOC_MAGIC_NUMBER, 20, unsigned int *)
#define IOCTL_SET_BLK_TX_THR	_IOW(IOC_MAGIC_NUMBER, 21, unsigned int *)
#define IOCTL_SET_BLK_RX_THR	_IOW(IOC_MAGIC_NUMBER, 22, unsigned int *)


unsigned int data[65536], wdata[65536];
int iit_hpu;

void handle_kill(int sig)
{
        printf("\nProgram exited\n");
        exit(0);
}

void write_data(int chunk_size, int chunk_num)
{
	int i, j;
	int ret;

	for (i = 0; i < chunk_num; i++) {
		for (j = 0; j < chunk_size; j++) {
			wdata[j * 2] = 0;
			wdata[j * 2 + 1] = (0xcafe << 16) |
				((i * chunk_size + j) & 0xffff);
		}
		ret = write(iit_hpu, wdata, 8 * chunk_size);
		if (ret != 8 * chunk_size)
			fprintf(stderr, "Written only %d", ret);
	}
}

void read_data(int chunk_size, int chunk_num)
{
	int i, j;
	unsigned int tmp, tmp2;
	int ret;

	for (i = 0; i < chunk_num; i++) {
		ret = read(iit_hpu, data,  8 * chunk_size);
		if (ret != 8 * chunk_size)
			printf("read returned %d\n", ret);
		for (j = 0; j < chunk_size; j++) {
			tmp = (0xcafe << 16) | ((i * chunk_size + j) & 0xffff);
			tmp2 = data[j * 2 + 1];
			if (tmp2 != tmp)
				printf("error at %d,%d: %x %x\n", i, j,tmp2, tmp);
		}
	}
}

void read_thr_data(int chunk_size, int chunk_num)
{
	int i, j;
	unsigned int tmp, tmp2;
	int ret;
	int chunk;
	unsigned int size;

	size = chunk_size;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);

	for (i = 0; i < chunk_num; i++) {
		chunk = 0;
		while (chunk < chunk_size * 8) {
			ret = read(iit_hpu, data + chunk,  (8 * chunk_size) - chunk);
			if (ret < size)
				printf("read returned %d\n", ret);
			chunk += ret;
		}

		if (chunk != chunk_size * 8)
			printf("read finished with %d\n", chunk);

		for (j = 0; j < chunk_size; j++) {
			tmp = (0xcafe << 16) | ((i * chunk_size + j) & 0xffff);
			tmp2 = data[j * 2 + 1];
			if (tmp2 != tmp)
				printf("error at %d,%d: %x %x\n", i, j,tmp2, tmp);
		}
	}
}

int main(int argc, char * argv[])
{
	int ret;
	int i, j, k;
	unsigned int timestamp = 0;
	unsigned int rx_ps, tx_ps;
	int val;
	clock_t time;
	double time_sec;

	unsigned int size;
	int iter_count = 1000;
	int tx_size = 512;
	int rx_size = 512;
	int tx_n = 32;
	int rx_n = 32;

	signal(SIGPIPE, SIG_IGN);
	signal(SIGTERM, handle_kill);
	signal(SIGINT, handle_kill);

	iit_hpu = open("/dev/iit-hpu0",O_RDWR);
	if(iit_hpu < 0) {
		printf("Error in opening iit_hpu0 device!\n");
		return 0;
	}
	ret = ioctl(iit_hpu, IOC_GET_RX_PS, &rx_ps);
	if (ret < 0)
		printf("Unknown RX ps size\n");
	else
		printf("RX Pool size = %d\n", rx_ps);

	ret = ioctl(iit_hpu, IOC_GET_TX_PS, &tx_ps);
	if (ret < 0)
		printf("Unknown TX ps size\n");
	else
		printf("TX Pool size = %d\n", tx_ps);

	val = 3;
	ioctl(iit_hpu, IOC_SET_LOOP_CFG, &val);
	val = 1;
	ioctl(iit_hpu, IOC_SET_SPINN, &val);

	// Set TimeStamp size
	timestamp = 1;
	ioctl(iit_hpu, IOC_SET_TS_TYPE, &timestamp);

	/* check for correctness - write and read not overlappin*/
	for (i = 0; i < iter_count; i++) {
		write_data(tx_size, tx_n);
		usleep(10000);
		read_data(rx_size, rx_n);
	}
	printf("phase 1 OK\n");

	/* check for correctness - overlapping write/read */
	for (i = 0; i < iter_count; i++) {
		write_data(tx_size, tx_n);
		read_data(rx_size, rx_n);
	}
	printf("phase 2 OK\n");

	/* check for correctness - overlapping write/read - RX threshold ioctl */
	for (i = 0; i < iter_count; i++) {
		write_data(tx_size, tx_n);
		read_thr_data(rx_size, rx_n);
	}
	printf("phase 3 OK\n");

	size = rx_ps;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);

	/* check for correctness - overlapping write/read - RX threshold ioctl */
	for (i = i; i <= 4; i++) {
		write(iit_hpu, wdata, rx_ps * i);
		usleep(10000);
		ret = read(iit_hpu, data, rx_ps * 8);
		if (ret != rx_ps * i)
			printf("read %d instead of %d\n", ret, rx_ps * i);
	}
	printf("phase 4 OK\n");

	/* tot RX desc = 100 * 32 * 1024 * 8  / 8192 = 3200 */
	iter_count = 20;
	rx_n = 4;
	tx_n = 32;

	tx_size = 1024;
	rx_size = 8192;
	int tot_data = iter_count * tx_size * tx_n * 8;

	if (fork() == 0) {
		for (i = 0; i < iter_count; i++) {
			for (j = 0; j < rx_n; j++) {
				read(iit_hpu, data, 8 * rx_size);
			}
		}

		close(iit_hpu);
	} else {
		sleep(1);
		time = clock();
		for (i = 0; i < iter_count; i++) {
			for (j = 0; j < tx_n; j++) {
				write(iit_hpu, wdata, 8 * tx_size);
			}
		}

		time = clock() - time;
		time_sec = (double)time / CLOCKS_PER_SEC;
		printf("RTX throughtput %f MBps\n",
		       (double)tot_data / time_sec / 1024.0 / 1024.0);
	}

	return 0;
}
