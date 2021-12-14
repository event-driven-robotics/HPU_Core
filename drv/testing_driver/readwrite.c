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
#include <stdint.h>

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/mman.h>


/****************************************************************
 * Constants
 ****************************************************************/
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
#define IOC_READ_TS			_IOR(IOC_MAGIC_NUMBER, 1, unsigned int *)
#define IOC_CLEAR_TS			_IOW(IOC_MAGIC_NUMBER, 2, unsigned int *)
#define IOC_SET_TS_TYPE			_IOW(IOC_MAGIC_NUMBER, 7, unsigned int *)
#define IOC_GET_RX_PS			_IOR(IOC_MAGIC_NUMBER, 9, unsigned int *)
#define IOC_SET_LOOP_CFG		_IOW(IOC_MAGIC_NUMBER, 18, spinn_loop_t *)
#define IOC_GET_TX_PS			_IOR(IOC_MAGIC_NUMBER, 20, unsigned int *)
#define IOCTL_SET_BLK_TX_THR		_IOW(IOC_MAGIC_NUMBER, 21, unsigned int *)
#define IOCTL_SET_BLK_RX_THR		_IOW(IOC_MAGIC_NUMBER, 22, unsigned int *)
#define IOC_SET_SPINN_STARTSTOP		_IOW(IOC_MAGIC_NUMBER, 25, unsigned int *)
#define IOC_SET_RX_INTERFACE		_IOW(IOC_MAGIC_NUMBER, 26, hpu_rx_interface_ioctl_t *)
#define IOC_SET_TX_INTERFACE		_IOW(IOC_MAGIC_NUMBER, 27, hpu_tx_interface_ioctl_t *)
#define IOC_SET_AXIS_LATENCY		_IOW(IOC_MAGIC_NUMBER, 28, unsigned int *)
#define IOC_GET_RX_PN			_IOR(IOC_MAGIC_NUMBER, 29, unsigned int *)

typedef enum {
	/* order matters here! Must be consistent with the following array */
	LOOP_NONE,
	LOOP_LNEAR,
	LOOP_LSPINN_AUX,
	LOOP_LSPINN_LEFT,
	LOOP_LSPINN_RIGHT,
	LOOP_LPAER_AUX,
	LOOP_LPAER_LEFT,
	LOOP_LPAER_RIGHT,
	LOOP_LSAER_AUX,
	LOOP_LSAER_LEFT,
	LOOP_LSAER_RIGHT
} spinn_loop_t;

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


uint32_t data[65536], wdata[65536];
int iit_hpu;


void handle_kill(int sig)
{
        printf("\nProgram exited\n");
        exit(0);
}

void _write_data(int chunk_size, int chunk_num, int magic)
{
	int i, j;
	int ret;

	for (i = 0; i < chunk_num; i++) {
		for (j = 0; j < chunk_size; j++) {
			wdata[j * 2] = 0;
			wdata[j * 2 + 1] = (magic << 16) |
				((i * chunk_size + j) & 0xffff);
		}
		ret = write(iit_hpu, wdata, 8 * chunk_size);
		if (ret != 8 * chunk_size)
			fprintf(stderr, "Written only %d insted of %d\n", ret, 8 * chunk_size);
	}
}

void _read_data(int chunk_size, int chunk_num, int magic)
{
	int i, j;
	uint32_t tmp, tmp2, tmp3;
	int ret;

	for (i = 0; i < chunk_num; i++) {
		ret = read(iit_hpu, data,  8 * chunk_size);
		if (ret != 8 * chunk_size) {
			printf("read returned %d\n", ret);
		} else {
			for (j = 0; j < chunk_size; j++) {
				tmp = (magic << 16) | ((i * chunk_size + j) & 0xffff);
				tmp2 = data[j * 2 + 1];
				tmp3 = data[j * 2];
				if (tmp2 != tmp)
					printf("error at %d,%d: rcv: %x (ts %x) exp: %x\n", i, j,tmp2, tmp3, tmp);
			}
		}
	}
}

void write_data(int chunk_size, int chunk_num)
{
	_write_data(chunk_size, chunk_num, 0x5a);
}

void read_data(int chunk_size, int chunk_num)
{
	_read_data(chunk_size, chunk_num, 0x5a);
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
			tmp = (0x5a << 16) | ((i * chunk_size + j) & 0xffff);
			tmp2 = data[j * 2 + 1];
			if (tmp2 != tmp)
				printf("error at %d,%d: %x %x\n", i, j,tmp2, tmp);
		}
	}
}

double time_diff(struct timespec *start, struct timespec *stop)
{
	double ret;
	ret = (double)(stop->tv_nsec - start->tv_nsec) / 1000.0 / 1000.0 / 1000.0;
	ret +=  stop->tv_sec - start->tv_sec;

	return ret;
}

int help_bail(char **argv)
{
	fprintf(stderr, "usage:\n");
	fprintf(stderr, "%s near\n", argv[0]);
	fprintf(stderr, "%s [spinn|paer|saer] [L|R|aux]\n", argv[0]);
	return -1;
}

int main(int argc, char * argv[])
{
	int ret;
	int i;
	unsigned int timestamp = 0;
	unsigned int rx_ps, tx_ps, rx_pn;
	int val;
	spinn_loop_t loop_type;
	struct timespec ts1, ts2;
	double time_sec = 0;
	unsigned int size;
	int iter_count = 1000;
	int rx_size = 512;
	int tx_size = 512;
	int tx_n = 32;
	int rx_n = 32;
	hpu_rx_interface_ioctl_t rxiface;
	hpu_tx_interface_ioctl_t txiface;

	signal(SIGPIPE, SIG_IGN);
	signal(SIGTERM, handle_kill);
	signal(SIGINT, handle_kill);

	mlockall(MCL_CURRENT|MCL_FUTURE);
	memset(wdata, 0, sizeof(wdata));
	memset(data, 0, sizeof(data));

	if (argc < 2)
		return help_bail(argv);

	if (0 == strcmp(argv[1], "near")) {
		loop_type = LOOP_LNEAR;
	} else {
		if (argc != 3)
			return help_bail(argv);
		if (0 == strcmp(argv[1], "spinn"))
			loop_type = LOOP_LSPINN_AUX;
		else if (0 == strcmp(argv[1], "paer"))
			loop_type = LOOP_LPAER_AUX;
		else if (0 == strcmp(argv[1], "saer"))
			loop_type = LOOP_LSAER_AUX;
		else return help_bail(argv);

		if (0 == strcmp(argv[2], "L"))
			loop_type++;
		else if (0 == strcmp(argv[2], "R"))
			loop_type += 2;
		else if (strcmp(argv[2], "aux"))
			return help_bail(argv);
	}

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

	ret = ioctl(iit_hpu, IOC_GET_RX_PN, &rx_pn);
	if (ret < 0)
		printf("Unknown RX pn\n");
	else
		printf("RX Pool number = %d\n", rx_pn);

	ret = ioctl(iit_hpu, IOC_GET_TX_PS, &tx_ps);
	if (ret < 0)
		printf("Unknown TX ps size\n");
	else
		printf("TX Pool size = %d\n", tx_ps);

	ret = ioctl(iit_hpu, IOC_SET_LOOP_CFG, &loop_type);
	if (ret < 0) {
		printf("loop cfg ioctl failed with err %d\n", ret);
		return ret;
	}

	memset((void*)&rxiface, 0, sizeof(rxiface));
	memset((void*)&txiface, 0, sizeof(txiface));
	val = 0;
	txiface.route = ROUTE_FIXED;

	switch (loop_type) {
	case LOOP_LSPINN_AUX:
	case LOOP_LSAER_AUX:
	case LOOP_LPAER_AUX:
		rxiface.interface = INTERFACE_AUX;
		break;
	case LOOP_LSPINN_LEFT:
	case LOOP_LSAER_LEFT:
	case LOOP_LPAER_LEFT:
		rxiface.interface = INTERFACE_EYE_L;
		break;
	case LOOP_LSPINN_RIGHT:
	case LOOP_LSAER_RIGHT:
	case LOOP_LPAER_RIGHT:
		rxiface.interface = INTERFACE_EYE_R;
		break;
	case LOOP_NONE:
		fprintf(stderr, "BUG!\n");
		break;
	case LOOP_LNEAR:
		break;
	}

	switch (loop_type) {
	case LOOP_LSPINN_AUX:
	case LOOP_LSPINN_RIGHT:
	case LOOP_LSPINN_LEFT:
		rxiface.cfg.spinn = 1;
		txiface.cfg.spinn = 1;
		val = 1;
		break;

	case LOOP_LSAER_AUX:
	case LOOP_LSAER_RIGHT:
	case LOOP_LSAER_LEFT:
		rxiface.cfg.hssaer[0] = 1;
		txiface.cfg.hssaer[0] = 1;
		break;

	case LOOP_LPAER_AUX:
	case LOOP_LPAER_RIGHT:
	case LOOP_LPAER_LEFT:
		rxiface.cfg.paer = 1;
		txiface.cfg.paer = 1;
		break;

	case LOOP_LNEAR:
		break;
	case LOOP_NONE:
		fprintf(stderr, "BUG!\n");
		break;
	}

	ioctl(iit_hpu, IOC_SET_RX_INTERFACE, &rxiface);
	ioctl(iit_hpu, IOC_SET_TX_INTERFACE, &txiface);
	ioctl(iit_hpu, IOC_SET_SPINN_STARTSTOP, &val);
	// Set TimeStamp size
	timestamp = 1;
	ioctl(iit_hpu, IOC_SET_TS_TYPE, &timestamp);

	val = 500;
	ioctl(iit_hpu, IOC_SET_AXIS_LATENCY, &val);


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
	for (i = 1; i <= 4; i++) {
		ret = write(iit_hpu, wdata, rx_ps * i);
		usleep(10000);
		ret = read(iit_hpu, data, rx_ps * 8);
		if (ret != rx_ps * i)
			printf("read %d instead of %d\n", ret, rx_ps * i);
	}
	printf("phase 4 OK\n");

	val = 50;
	ioctl(iit_hpu, IOC_SET_AXIS_LATENCY, &val);
	/* check for early-tlast mechanism to be OK */
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts1);
	write_data(rx_ps / 8 / 2, 1);
	read_data(rx_ps / 8 / 2, 1);
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts2);
	time_sec = time_diff(&ts1, &ts2);

	printf("phase 5 OK (%f)\n", time_sec);

	/* cause a fifo full: fill-up the RX ring and the RF FIFO, plus an extra data */
	for (i = 0; i < rx_pn; i++) {
		write_data(rx_ps / 8, /*rx_pn*/ 1);
		usleep(100);
	}
	for (i = 0; i < 8; i++) {
		write_data(1024 / 8, /*rx_pn*/ 1);
		usleep(100);
	}
	write_data(4, /*rx_pn*/ 1);
	/* rx fifo depth can stand at 8192 data, that is 32Kbytes */
	//write_data(32 * 1024 / 8 - 1, /*rx_pn*/ 1);
	//write_data(1, /*rx_pn*/ 1);
	printf("fifo filled..\n");
	usleep(100000);
	ret = read(iit_hpu, data, 8);

	printf("fifo full %s\n", (ret < 0) ? "OK" : "not detected");

	size = 0x7fff0000;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);

	/* check for fifo-full recover */
	for (i = 0; i < iter_count; i++) {
		_write_data(tx_size, tx_n, 0x55);
		_read_data(rx_size, rx_n, 0x55);
	}
	printf("phase 6 OK\n");

	return 0;
}
