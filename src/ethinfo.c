/*
 * Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
 * Infiscale, Inc. All rights reserved
 */



#include <stdio.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <errno.h>
#define __KERNEL__
#include <linux/types.h>
#include <linux/sockios.h>
#include <linux/ethtool.h>
#undef __KERNEL__

int linkStatus( int sd, struct ifreq *ifr)
{
    int                   resultCode = 0;
    struct ethtool_value  edata;
    caddr_t               oldIFRData = ifr->ifr_data;

    /* Setup the command-specific ifreq stuff; we're using an edata
       that's on this function's stack, so we should replace that
       field's old value before we return! */
    edata.cmd = ETHTOOL_GLINK;
    ifr->ifr_data = (caddr_t)&edata;

    /* Make the ioctl call: */
    if ( ioctl(sd, SIOCETHTOOL, ifr) == 0)
    {
        resultCode = ( edata.data ? 1 : 2 );
    }
    else if (errno != EOPNOTSUPP)
    {
        perror("Cannot get link status");
        resultCode = 3;
    }

    /* Restore saved ifr_data field and return: */
    ifr->ifr_data = oldIFRData;
    return resultCode;
}

int getHWAddrForInterface( const char* ifname, char* hwaddr, size_t n)
{
    int             sd;
    struct ifreq    devEA;
    int             resultCode = 0;

    /* Setup the ifreq struct */
    memset(&devEA, 0, sizeof(devEA));
    if ( ifname )
        strncpy(devEA.ifr_name, ifname, sizeof(devEA.ifr_name) - 1);
    else
        snprintf(devEA.ifr_name, sizeof(devEA.ifr_name) - 1, "eth0");

    /* Make a socket on which to do the ioctl request: */
    if ( (sd = socket(AF_INET, SOCK_DGRAM, 0)) >= 0 )
    {
        if ( ioctl(sd, SIOCGIFHWADDR, &devEA) < 0 )
        {
            strncpy(hwaddr, "unknown", n);
            resultCode = 2;
        }
        else
        {
            /* Success! */
            snprintf(hwaddr, n, "%02hhX:%02hhX:%02hhX:%02hhX:%02hhX:%02hhX",
                     devEA.ifr_ifru.ifru_hwaddr.sa_data[0] & 0xFF,
                     devEA.ifr_ifru.ifru_hwaddr.sa_data[1] & 0xFF,
                     devEA.ifr_ifru.ifru_hwaddr.sa_data[2] & 0xFF,
                     devEA.ifr_ifru.ifru_hwaddr.sa_data[3] & 0xFF,
                     devEA.ifr_ifru.ifru_hwaddr.sa_data[4] & 0xFF,
                     devEA.ifr_ifru.ifru_hwaddr.sa_data[5] & 0xFF
                    );
        }
        close(sd);
    }
    else
    {
        resultCode = 1;
    }
    return resultCode;
}

