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
#include <pthread.h>
#include <semaphore.h>
#include <string.h>
#include <signal.h>
#include <termios.h>
#include <time.h>
#include <stdint.h>
#include <stdlib.h>

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

#define IOC_SET_RX_TS_ENABLE		_IOW(IOC_MAGIC_NUMBER, 40, unsigned int *)
#define IOC_SET_TX_TS_ENABLE		_IOW(IOC_MAGIC_NUMBER, 41, unsigned int *)

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

#define ACCESS_ONCE(x) (*(volatile typeof(x) *)&(x))

#define GREEN "\033[92m"
#define NORMAL "\x1b[0m"
#define MAGENTA "\033[95m"
#define BLUE "\033[94m"
#define YELLOW "\33[33m"
#define BOLD "\033[1m"
#define UNDERLINE "\033[4m"
void banner(char *b)
{
	printf(MAGENTA"+ " NORMAL BOLD);
	printf(b);
	printf(NORMAL);
	fflush(stdout);
}

void banner_ok()
{
	printf(GREEN" [ OK ]\n"NORMAL);
}

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

void _write_data_nots(int chunk_size, int chunk_num, int magic)
{
	int i, j;
	int ret;

	for (i = 0; i < chunk_num; i++) {
		for (j = 0; j < chunk_size; j++) {
			wdata[j] = (magic << 16) |
				((i * chunk_size + j) & 0xffff);
		}
		ret = write(iit_hpu, wdata, 4 * chunk_size);
		if (ret != 4 * chunk_size)
			fprintf(stderr, "Written only %d insted of %d\n", ret, 8 * chunk_size);
	}
}

void _read_data(int chunk_size, int chunk_num, int magic, int rx_ts)
{
	int i, j;
	uint32_t tmp, tmp2, tmp3;
	int ret;
	int k = rx_ts ? 1 : 2;
	int read_size;

	for (i = 0; i < chunk_num; i++) {
		read_size = 8 * chunk_size / k;
		ret = read(iit_hpu, data,  read_size);
		if (ret != read_size) {
			printf("read (rxts=%d) returned %d, expected %d\n",
			       rx_ts, ret, read_size);
		} else {
			for (j = 0; j < chunk_size; j++) {
				tmp = (magic << 16) | ((i * chunk_size + j) & 0xffff);
				if (rx_ts) {
					tmp2 = data[j * 2 + 1];
					tmp3 = data[j * 2];
					if (tmp2 != tmp) {
						printf("error at %d,%d: rcv: %x (ts %x) exp: %x\n",
						       i, j,tmp2, tmp3, tmp);
						exit(-1);
					}
				} else {
					tmp2 = data[j];
					if (tmp2 != tmp) {
						printf("error at %d,%d: rcv: %x exp: %x\n",
						       i, j, tmp2, tmp);
						//system("cat /sys/kernel/debug/hpu/hpu.0x0000000080010000/regdump");
						exit(-1);
					}

				}
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
	_read_data(chunk_size, chunk_num, 0x5a, 1);
}

void _read_data_nots(int chunk_size, int chunk_num, int magic)
{
	_read_data(chunk_size, chunk_num, magic, 0);
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
			if (tmp2 != tmp) {
				printf("error at %d,%d: %x %x\n", i, j,tmp2, tmp);
				exit(-1);
			}
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

void fill_fifo(int rx_ps, int rx_pn, spinn_loop_t loop_type, int rx_ts, int tx_ts)
{
	int i, ret;
	unsigned int size;
	/*
	 * when rx timestamps are disabled we need to TX twice the data in order to
	 * fill the RX fifo
	 */
	int k = rx_ts ? 2 : 1;

	/* when tx ts are disabled we need to TX half data */
	int h = tx_ts ? 1 : 2;

	/* cause a fifo full: fill-up the RX ring and the RX FIFO, plus an extra data */
	printf(YELLOW"[intentionally causing fifo full");
	for (i = 0; i < rx_pn; i++) {
		write_data(rx_ps / 4 / k / h, /*rx_pn*/ 1);
		usleep(100);
	}
	for (i = 0; i < 8; i++) {
		write_data(1024 / 4 / 2 / h, /*rx_pn*/ 1);
		usleep(100);
	}
#warning tweak_for_last_boot.bin_fifo_size___needs_better_handling
	write_data(8 / k - (rx_ts ? 1 : 3) / h, /*rx_pn*/ 1);
	/* rx fifo depth can stand at 8192 data, that is 32Kbytes */
	//write_data(32 * 1024 / 8 - 1, /*rx_pn*/ 1);
	//write_data(1, /*rx_pn*/ 1);
	printf(".. fifo filled");
	usleep(100000);
	ret = read(iit_hpu, data, 8);

	printf(".. fifo full %s]"NORMAL"\n", (ret < 0) ? "OK" : "not detected");

	/*
	 * If the IP has been synthesized with at least one "real"
	 * interface (e.g. paer), then during near-loop fifo-overflow
	 * RX-suspend state, the TXFIFO discards data, i.e TXDATA is
	 * discarded until the fifo-full condition is is recovered
	 * (i.e. a read is attempted).
	 * Do a dummy one without blocking, then go on.
	 */
	if (loop_type == LOOP_LNEAR) {
		size = 0x0;
		ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);
		read(iit_hpu, data, 8);
	}

	size = 0x7fff0000;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);
}

void test_throughput(int rx_ps)
{
	pthread_t read_thread;
	int ret;
	int run = -1;
	int thread_kill = 0;
	float thr;
	sem_t write_sem;
	int size;

	void *read_thread_fun(void *arg)
	{
		unsigned long rlen = 0;
		int ret;
		double et = 0.0;
		struct timespec start_time, cur_time;

		clock_gettime(CLOCK_MONOTONIC_RAW, &start_time);

		ACCESS_ONCE(run) = 1;
		while (1) {
			ret = read(iit_hpu, data, rx_ps);
			if (ret < 0) {
				fprintf(stderr, "read err %d\n", ret);
				break;
			}
			sem_post(&write_sem);
			rlen += ret;
			clock_gettime(CLOCK_MONOTONIC_RAW, &cur_time);
			et = time_diff(&start_time, &cur_time);
			if (et > 10)
				break;

			if (ACCESS_ONCE(thread_kill))
				break;
		}

		if (et > 0) {
			thr = (float)rlen / 1024 / 1024 / et;
			printf(UNDERLINE BLUE"%f MB/s\n"NORMAL, thr);
		}
		ACCESS_ONCE(run) = 0;
		sem_post(&write_sem);
		return NULL;
	}

	sem_init(&write_sem, 0, 5);
	pthread_create(&read_thread, NULL, read_thread_fun, NULL);

	while (1) {
		sem_wait(&write_sem);
		if (!ACCESS_ONCE(run))
			break;
		ret = write(iit_hpu, wdata, rx_ps);
		if (ret < 0) {
			fprintf(stderr, "tx error %d\n", ret);
			ACCESS_ONCE(thread_kill) = 1;
			break;
		}
	}

	pthread_join(read_thread, NULL);
	sem_destroy(&write_sem);

	size = 0;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);
	while (read(iit_hpu, data, rx_ps) > 0);

	size = 0x7fff0000;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);

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

	val = 1;
	ioctl(iit_hpu, IOC_SET_RX_TS_ENABLE, &val);
	ioctl(iit_hpu, IOC_SET_TX_TS_ENABLE, &val);

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

	printf("\n");
	banner("check for correctness - write and read not overlapping.. ");
	for (i = 0; i < iter_count; i++) {
		write_data(tx_size, tx_n);
		usleep(10000);
		read_data(rx_size, rx_n);
	}
	banner_ok();

	banner("check for correctness - overlapping write/read");
	for (i = 0; i < iter_count; i++) {
		write_data(tx_size, tx_n);
		read_data(rx_size, rx_n);
	}
	banner_ok();

	banner("check for correctness - overlapping write/read - RX threshold ioctl");
	for (i = 0; i < iter_count; i++) {
		write_data(tx_size, tx_n);
		read_thr_data(rx_size, rx_n);
	}
	banner_ok();

	size = rx_ps;
	ioctl(iit_hpu, IOCTL_SET_BLK_RX_THR, &size);

	banner("check for correctness - overlapping write/read - RX threshold ioctl");
	for (i = 1; i <= 4; i++) {
		ret = write(iit_hpu, wdata, rx_ps * i);
		usleep(10000);
		ret = read(iit_hpu, data, rx_ps * 8);
		if (ret != rx_ps * i)
			printf("read %d instead of %d\n", ret, rx_ps * i);
	}
	banner_ok();

	val = 50;
	ioctl(iit_hpu, IOC_SET_AXIS_LATENCY, &val);

	banner("check for early-tlast mechanism to be OK..");
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts1);
	write_data(rx_ps / 8 / 2, 1);
	read_data(rx_ps / 8 / 2, 1);
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts2);
	time_sec = time_diff(&ts1, &ts2);

	printf(" (got data in %fS) ", time_sec);
	banner_ok();

	banner("testing for throughput.. ");
	test_throughput(rx_ps);

	fill_fifo(rx_ps, rx_pn, loop_type, 1, 1);

	banner("check for fifo-full recover");
	for (i = 0; i < iter_count; i++) {
		_write_data(tx_size, tx_n, 0x55);
		_read_data(rx_size, rx_n, 0x55, 1);
	}
	banner_ok();

	banner("testing for throughput after fifo full: ");
	test_throughput(rx_ps);

	banner("testing RX TS disabling");
	val = 0;
	ioctl(iit_hpu, IOC_SET_RX_TS_ENABLE, &val);

	for (i = 0; i < iter_count; i++) {
		_write_data(tx_size, tx_n, 0x57);
		_read_data_nots(rx_size, rx_n, 0x57);
	}
	banner_ok();

	fill_fifo(rx_ps, rx_pn, loop_type, 0, 1);
	banner("testing fifo full with disabled RX TS");
	for (i = 0; i < iter_count; i++) {
		_write_data(tx_size, tx_n, 0x57);
		_read_data_nots(rx_size, rx_n, 0x57);
	}
	banner_ok();

	banner("testing TX TS disabling");
	val = 0;
	ioctl(iit_hpu, IOC_SET_TX_TS_ENABLE, &val);
	val = 1;
	ioctl(iit_hpu, IOC_SET_RX_TS_ENABLE, &val);

	for (i = 0; i < iter_count; i++) {
		_write_data_nots(tx_size, tx_n, 0x58);
		_read_data(rx_size, rx_n, 0x58, 1);
	}
	banner_ok();

	banner("RX&TX TS disabled; throughput: ");
	val = 0;
	ioctl(iit_hpu, IOC_SET_TX_TS_ENABLE, &val);
	ioctl(iit_hpu, IOC_SET_RX_TS_ENABLE, &val);

	test_throughput(rx_ps);
	fill_fifo(rx_ps, rx_pn, loop_type, 0, 0);
	banner("RX&TX TS disabled, after fifo full; throughput: ");
	test_throughput(rx_ps);
	return 0;
}
