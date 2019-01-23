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
#include <pthread.h>

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
	LOOP_NONE,
	LOOP_LNEAR,
	LOOP_LSPINN,
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


unsigned int data[65536], wdata[65536];
int iit_hpu;

#define ACCESS_ONCE(x) (*(volatile typeof(x) *)&(x))

void handle_kill(int sig)
{
        printf("\nProgram exited\n");
        exit(0);
}


const int loop_near = 1;
double time_diff(struct timespec *start, struct timespec *stop)
{
	double ret;
	ret = (double)(stop->tv_nsec - start->tv_nsec) / 1000.0 / 1000.0 / 1000.0;
	ret +=  stop->tv_sec - start->tv_sec;

	return ret;
}

int main(int argc, char * argv[])
{
	int ret;
	int i;
	unsigned int timestamp = 0;
	unsigned int rx_ps, rx_pn;
	int val;
	struct timespec ts1, ts2;
	double time_sec = 0;
	int iter_count = 1000;
	int rx_size = 8192 * 4;
	int tot_data;

	signal(SIGPIPE, SIG_IGN);
	signal(SIGTERM, handle_kill);
	signal(SIGINT, handle_kill);

	mlockall(MCL_CURRENT|MCL_FUTURE);
	memset(wdata, 0, sizeof(wdata) / sizeof(wdata[0]));
	memset(data, 0, sizeof(data) / sizeof(data[0]));

	printf("REMEMBER: driver must be in 'test dma' mode\n");
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

	// Set TimeStamp size
	timestamp = 1;
	ioctl(iit_hpu, IOC_SET_TS_TYPE, &timestamp);

	val = 500;
	ioctl(iit_hpu, IOC_SET_AXIS_LATENCY, &val);

	clock_gettime(CLOCK_MONOTONIC_RAW, &ts1);
	for (i = 0; i < iter_count; i++) {
		ret = read(iit_hpu, data, 8 * rx_size);
		if (ret != 8 * rx_size)
			printf("err TX %d\n", ret);
	}
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts2);

	tot_data = 8 * rx_size * iter_count;
	time_sec = time_diff(&ts1, &ts2);

	printf("RX throughtput %f MBps\n",
	       (double)tot_data / time_sec / 1024.0 / 1024.0);

	return 0;
}
