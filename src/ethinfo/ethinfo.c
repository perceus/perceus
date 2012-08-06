/*
 * Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
 * Infiscale, Inc. All rights reserved
 */

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <errno.h>
#include <netinet/in.h>
#define __KERNEL__
#include <linux/types.h>
#include <linux/sockios.h>
#include <linux/ethtool.h>
#undef __KERNEL__

#include "../ethinfo.h"

void usage(const char* program) {
  printf("USAGE: %s [options] [ethernet device]\n\n"
      "[options]\n"
      "   -l              Show the link status of the device\n"
      "   -a              Show the hardware address of the device\n"
      "   -q              Only show the relevant information\n"
      "   -h              Display this usage summary\n\n"
      "Ethlink is written and maintained by Greg Kurtzer <gmk@caosity.org>\n",
      program
    );
}

int main( const int argc, const char* argv[]) {
  struct ifreq  ifr;
  int           sd,resultCode = 0;
  int           devLen,devLenMax = sizeof(ifr.ifr_name) - 1;
  int           argn, opt;
  int           opt_usage = 0;
  int           opt_link = 0;
  int           opt_hwaddr = 0;
  int           opt_quiet = 0;
  char*         device;
  char          hwAddr[19];
  int           arg_count = argc;


  /* Process any cli options: */
  while ( (opt = getopt(argc, argv, "lahq")) != -1 ) {
    switch ( opt ) {

      case 'h':
        opt_usage++;
        arg_count--;
        break;

      case 'q':
        opt_quiet++;
        arg_count--;
        break;

      case 'l':
        opt_link++;
        arg_count--;
        break;

      case 'a':
        opt_hwaddr++;
        arg_count--;
        break;

    }
  }

  if ( opt_usage || arg_count <= 0 ) {
    usage(argv[0]);
    exit(0);
  }

  devLen = strlen(argv[argc-1]);

  /* Make sure the device name wasn't too long */
  if ( devLen > devLenMax ) {
    printf("ERROR: Invalid device name (too many characters to be a device!)\n");
    return 1;
  }
  
  if ( opt_link ) {
     if ( ! opt_quiet ) {
        printf("%s: ", argv[argc-1]);
        fflush(stdout);
      }

     /* Setup the ifreq structure */
     memset(&ifr, 0, sizeof(ifr));
     strncpy(ifr.ifr_name, argv[argc-1], devLenMax);
  
     /* Create a socket so we can grab link status from it: */
     if ( (sd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) {
       perror("Cannot get control socket");
       resultCode = 1;
     } else {
       /* Get link status and react accordingly: */
       switch ( linkStatus(sd, &ifr) ) {
      
         case 0:
           printf("ERROR: Something truly weird happened in linkStatus\n");
           resultCode = -1;
           break;
        
         case 1:
           printf("Link detected\n");
           break;
    
         case 2:
           printf("WARNING: no link\n");
           resultCode = 1;
           break;
    
         case 3:
           resultCode = 2;
           break;
      
       }
     }
  }
  if ( opt_hwaddr ) {

  /* Get the node ID: */
  hwAddr[18] = '\0';
  if ( getHWAddrForInterface(argv[argc-1],hwAddr,18) != 0 ) {
    printf("ERROR: Could not determine hardware address of device '%s'\n", argv[argc-1]);
    exit(1);
  }

  if ( opt_quiet ) {
     printf("%s\n", hwAddr);
  } else {
     printf("%s: %s\n", argv[argc-1], hwAddr);
  }

  }
  return resultCode;
}

