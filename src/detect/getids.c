/*
 * This is a very simple C program used to probe the PCI bus, and compare the
 * vendor and model ID of every card found against the pcitable ASCII
 * database. From there it pulls the correct module name, and prints all of
 * the module names that were found for your system.
 *
 * Written by: Greg Kurtzer <greg@caosity.org>
 * License: GPL
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include <ctype.h>
#include <sys/types.h>
#include <dirent.h>
#include <linux/pci_ids.h>

#include "config.h"
#include "defs.h"

const char PCIDEVICE_VENDORID_BASE[] = "/sys/bus/pci/devices/%s/vendor";
const char PCIDEVICE_DEVICEID_BASE[] = "/sys/bus/pci/devices/%s/device";
const char PCIDEVICE_CLASSID_BASE[]  = "/sys/bus/pci/devices/%s/class";


long long vendor( const char* addr) {
   FILE*       fPtr;
   long long   vendorID;
   size_t      vendorPathLen = strlen(PCIDEVICE_VENDORID_BASE) + strlen(addr);
   char        vendorPath[vendorPathLen];

   snprintf(vendorPath,vendorPathLen,PCIDEVICE_VENDORID_BASE,addr);
   if ( (fPtr = fopen(vendorPath,"r")) == NULL ) {
      printf("could not open %s!\n",vendorPath);
      exit(1);
   }
   if ( fscanf(fPtr,"%llx",&vendorID) != 1 ) {
      printf("error reading vendor ID for '%s'\n",addr);
      exit(1);
   }
   fclose(fPtr);
   return vendorID;
}

long long device( const char* addr) {
   FILE*       fPtr;
   long long   deviceID;
   size_t      devicePathLen = strlen(PCIDEVICE_DEVICEID_BASE) + strlen(addr);
   char        devicePath[devicePathLen];

   snprintf(devicePath,devicePathLen,PCIDEVICE_DEVICEID_BASE,addr);
   if ( (fPtr = fopen(devicePath,"r")) == NULL ) {
      printf("could not open %s!\n",devicePath);
      exit(1);
   }
   if ( fscanf(fPtr,"%llx",&deviceID) != 1 ) {
      printf("error reading device ID for '%s'\n",addr);
      exit(1);
   }
   fclose(fPtr);
   return deviceID;
}

long long class( const char* addr) {
   FILE*       fPtr;
   long long   classID;
   size_t      classPathLen = strlen(PCIDEVICE_CLASSID_BASE) + strlen(addr);
   char        classPath[classPathLen];

   snprintf(classPath,classPathLen,PCIDEVICE_CLASSID_BASE,addr);
   if ( (fPtr = fopen(classPath,"r")) == NULL ) {
      printf("could not open %s!\n",classPath);
      exit(1);
   }
   if ( fscanf(fPtr,"%llx",&classID) != 1 ) {
      printf("error reading class ID for '%s'\n",addr);
      exit(1);
   }
   fclose(fPtr);
   return classID;
}
