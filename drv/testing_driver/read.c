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

typedef struct ip_regs {
	unsigned int reg_offset;
	char rw;
	unsigned int data;
} ip_regs_t;

#define IOC_MAGIC_NUMBER        0
#define IOC_READ_TS             _IOR(IOC_MAGIC_NUMBER, 1, unsigned int *)
#define IOC_CLEAR_TS            _IOW(IOC_MAGIC_NUMBER, 2, unsigned int *)
#define IOC_SET_TS_TYPE         _IOW(IOC_MAGIC_NUMBER, 7, unsigned int *)
#define IOC_GEN_REG             _IOWR(IOC_MAGIC_NUMBER, 8, struct ip_regs *)
#define IOC_GET_PS              _IOR(IOC_MAGIC_NUMBER, 9, unsigned int *)
#define IOC_SET_SPINN           _IOW(IOC_MAGIC_NUMBER, 19, unsigned int *)
#define IOC_SET_LOOP_CFG        _IOW(IOC_MAGIC_NUMBER, 18, unsigned int *)


void handle_kill(int sig) {


        printf("\nProgram exited\n");

        exit(0);
}

int main(int argc, char * argv[])
{
	int i2c_fd;
	unsigned int *data;
	int ret;
	int numbdata=124;
	int i,j;
	int iit_hpu;
	unsigned int timestamp = 0;
	//unsigned int numtimes;
	unsigned int wraptimes;
	ip_regs_t gen_reg;
	int a;
	unsigned int value;
	unsigned int ps;
	unsigned int numtimes;
	int polarity;
	int address;
	int dat;
	int type;
	float dt;
	int val;
	unsigned int tmp;

	signal(SIGPIPE, SIG_IGN);
	signal(SIGTERM, handle_kill);
	signal(SIGINT, handle_kill);

	data=(unsigned int *) malloc (numbdata*sizeof(unsigned int));

	iit_hpu = open("/dev/iit-hpu0",O_RDWR);
	if(iit_hpu < 0) {
		printf("Error in opening iit_hpu0 device!\n");
		return 0;
	}

	// show DMA_REG value
	//gen_reg.reg_offset=DMA_REG;
	//gen_reg.rw=READ;
	//ioctl(iit_hpu, IOC_GEN_REG, &gen_reg);
	//printf ("DMA_REG: 0x%08X\n", gen_reg.data);

	ret=ioctl(iit_hpu, IOC_GET_PS, &ps);
	if (!(ret<0))
		printf("Pool size=: %d\n", ps);
	else
		printf("Unknown ps size\n");

	ps = 120;

	val = 3;
	ioctl(iit_hpu, IOC_SET_LOOP_CFG, &val);
	val = 1;
	ioctl(iit_hpu, IOC_SET_SPINN, &val);
	// Set TimeStamp size
	timestamp=1;
	ioctl(iit_hpu, IOC_SET_TS_TYPE, &timestamp);
	//ioctl(iit_hpu, IOC_CLEAR_TS, 0);
	unsigned int wdata[2];

	for (i = 0; i < 10; i++) {
		wdata[0] = 0;

		fprintf(stderr, "Writing..\n");
		for (j = 0; j < 1024; j++) {
			wdata[1] = (0xcafe << 16) | (j & 0xffff);
			ret = write(iit_hpu, wdata, 8);
			if (ret != 8)
				fprintf(stderr, "Written (%d)", ret);
		}

		fprintf(stderr, "Reading..\n");

		for (j = 0; j < 1024; j++) {
			read(iit_hpu, data,  8);
			tmp = (0xcafe << 16) | (j & 0xffff);
			if (data[1] != tmp)
			    printf("error at %d,%d: %x %x\n", i, j, data[1], tmp);

//			printf("data 0x%x 0x%x\n",
//		       ((unsigned int *)data)[0],
//			       ((unsigned int *)data)[1]);
		}
	}

	close(iit_hpu);


	return 0;
}
