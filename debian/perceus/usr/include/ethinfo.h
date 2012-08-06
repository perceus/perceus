/*
 * Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
 * Infiscale, Inc. All rights reserved
 */

#ifndef PERCEUS_ETHINFO_H
#define PERCEUS_ETHINFO_H

/*!
  @function linkStatus
  
  Given a socket descriptor (sd) and a device name (ifr->ifr_name) use
  ETHTOOL to determine whether or not that link is "up" (implying
  connected and transmitting).
  
  @result Returns 1 if the link is up; 2 if the link is not up; 3 if
    ioctl doesn't support ETHTOOL calls.  Returns zero when something
    wholy unexpected happens.
*/
int linkStatus(int sd, struct ifreq *ifr);

/*!
  @function getHWAddrForInterface

  Retrieve the hardware address of an interface to the host.  If ifname is
  a NULL or empty string, eth0 is used.  You must supply a character buffer
  (hwaddr) to hold the address and pass the length of the buffer (n).  The
  string written to hwaddr is not guaranteed to be nul-terminated -- if your
  buffer is too small for the address as many characters of the address as
  will possibly fit are placed in hwaddr.

  @result Returns 0 on success; 1 if the socket could not be created; and
    2 if ioctl doesn't know anything about the interface.
*/
int getHWAddrForInterface(const char* ifname,char* hwaddr,size_t n);


#endif /* PERCEUS_ETHINFO_H */
