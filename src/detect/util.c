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
#include <unistd.h>


#include "detect.h"
#include "config.h"
#include "defs.h"


void usage(char *program) {
   printf("usage: %s [options]\n"
     "\n"
     "Detect is a program used for identifing the needed kernel modules\n"
     "needed for your system. It compares your hardware against the\n"
     "currently running kernel's pcimap, and reports the findings.\n\n"
           "[options]\n"
           "   -q                  Don't show device classes\n"
           "   -a                  Show all devices (even unsupported ones)\n"
           "   -i                  Show the PCI IDs\n"
           "   -p                  Show the PCI address\n"
           "   -h                  This help\n\n"
      "Written for cAos Linux by Greg Kurtzer <greg@caosity.org>\n",
      program);
   exit(0);
}

const char* get_class( long long class_id) {
   FILE *fd;
   long long update_classid;
   static char update_class[BUFFSIZE];
   char buffer[BUFFSIZE];
   char config[BUFFSIZE];

   sprintf(config, "%s/classids", DETECTSYSCONFIGDIR);

   if ((fd = fopen(config, "r"))  == NULL ) {
      printf("could not open %s!\n", config);
      exit(1);
   }

   while(!feof(fd)) {
      fgets(buffer, BUFFSIZE-1, fd);

      if ( strncmp("#", buffer, 1) || strncmp("\n", buffer, 1)) {

         sscanf(buffer, "%llx %s", &update_classid, update_class);

         if ( update_classid == class_id ) {
            fclose(fd);
            return(update_class);
         }
      }
   }
   fclose(fd);


   /* Match the specific device class strings */
   switch ( class_id >> 8 ) {
      case PCI_CLASS_MULTIMEDIA_AUDIO:    return "AUDIO";
      case PCI_CLASS_MULTIMEDIA_VIDEO:    return "VIDEO";
      case PCI_CLASS_BRIDGE_PCI:          return "PCI";
      case PCI_CLASS_BRIDGE_PCMCIA:
      case PCI_CLASS_BRIDGE_CARDBUS:      return "PCMCIA";
      case PCI_CLASS_COMMUNICATION_MODEM: return "MODEM";
      case PCI_CLASS_SERIAL_FIREWIRE:     return "IEEE1394";
      case PCI_CLASS_SERIAL_USB:          return "USB";
   }

   /*
    * Now try to match the base classes if the above didn't
    * match anything.  If I were absolutely sure about the
    * numbering scheme, it would always be possible to just
    * make a string array and key the return-value based on
    * the class_id >> 16.  Cest la vie.
    */
   switch ( class_id >> 16 ) {
      case PCI_BASE_CLASS_STORAGE:        return "SCSI";
      case PCI_BASE_CLASS_NETWORK:        return "NETWORK";
      case PCI_BASE_CLASS_DISPLAY:        return "DISPLAY";
      case PCI_BASE_CLASS_MULTIMEDIA:     return "MULTIMEDIA";
      case PCI_BASE_CLASS_MEMORY:         return "MEMORY";
      case PCI_BASE_CLASS_BRIDGE:         return "BRIDGE";
      case PCI_BASE_CLASS_COMMUNICATION:  return "COMMUNICATION";
      case PCI_BASE_CLASS_INPUT:          return "INPUT";
      case PCI_BASE_CLASS_DOCKING:        return "DOCKING";
      case PCI_BASE_CLASS_PROCESSOR:      return "PROCESSOR";
      case PCI_BASE_CLASS_SERIAL:         return "SERIAL";
      case PCI_BASE_CLASS_INTELLIGENT:    return "INTELLIGENT";
      case PCI_BASE_CLASS_SATELLITE:      return "SATELLITE";
      case PCI_BASE_CLASS_CRYPT:          return "CRYPT";
    }

   /* We didn't match any hardware...so let's call it 'other' */
   return "OTHER";
}

