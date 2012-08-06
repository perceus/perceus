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
#include "detect.h"
#include "defs.h"

char ** get_module_from_kern(long long vendor_id, long long device_id, long long class_id) {
   FILE *fd;
   static char class_name[BUFFSIZE];
   char shown_mods[BUFFSIZE];
   char modname[BUFFSIZE];
   char modulename[BUFFSIZE];
   char buffer[BUFFSIZE];
   long long vendor, device, subvendor, subdevice, class, class_mask;
   int driver_data;
   char mod_test[BUFFSIZE];
   char modules_pcitable[BUFFSIZE];
   int count = 0;

   char **ret;

   struct utsname unameinfo;

   ret = calloc(30, BUFFSIZE);

   uname(&unameinfo);

   sprintf(modules_pcitable, "/lib/modules/%s/modules.pcimap", unameinfo.release);

   if ((fd = fopen(modules_pcitable, "r"))  == NULL ) {
      printf("could not open %s!\n", modules_pcitable);
      exit(1);
   }

   while(fgets(buffer, BUFFSIZE, fd)) {
       char *pbuff = buffer;

       if (*buffer == '#') {
           continue;
       }
       sscanf(buffer, "%s", modname);
       pbuff += strlen(modname);
       vendor = strtoll(pbuff, &pbuff, 0);
       if ((vendor != vendor_id) && ((int) vendor != -1)) {
           continue;
       }
       device = strtoll(pbuff, &pbuff, 0);
       if ((vendor != vendor_id) && ((int) vendor != -1)) {
           continue;
       }
       subvendor = strtoll(pbuff, &pbuff, 0);
       subdevice = strtoll(pbuff, &pbuff, 0);
       class = strtoll(pbuff, &pbuff, 0);
       class_mask = strtoll(pbuff, &pbuff, 0);
       driver_data = strtoll(pbuff, &pbuff, 0);

       if ((( vendor == vendor_id && device == device_id ) ||
            ( (int)vendor == -1 && (int)device == -1 && class == class_id )) &&
           ! check_module_ignore(modname)) {

           snprintf(modulename, BUFFSIZE, "%s", check_module_update(modname));

           ret[count] = strdup(modulename);
           count++;

       }
   }
   fclose(fd);
   ret[count] = NULL;
   return(ret);
}



char ** get_module_from_map(long long vendor_id, long long device_id, long long class_id) {
   FILE *fd;
   static char class_name[BUFFSIZE];
   char shown_mods[BUFFSIZE];
   char modname[BUFFSIZE];
   char modulename[BUFFSIZE];
   char buffer[BUFFSIZE];
   long long vendor, device, subvendor, subdevice, class, class_mask;
   int driver_data;
   char mod_test[BUFFSIZE];
   char modules_pcitable[BUFFSIZE];
   int count = 0;

   char **ret;
   ret = calloc(30, BUFFSIZE);


   sprintf(modules_pcitable, "%s/pcimap", DETECTSYSCONFIGDIR);

   if ((fd = fopen(modules_pcitable, "r"))  == NULL ) {
      return(ret);
   }

   while(fgets(buffer, BUFFSIZE, fd)) {
       char *pbuff = buffer;

       if (*buffer == '#') {
           continue;
       }
       sscanf(buffer, "%s", modname);
       pbuff += strlen(modname);
       vendor = strtoll(pbuff, &pbuff, 0);
       device = strtoll(pbuff, &pbuff, 0);
       subvendor = strtoll(pbuff, &pbuff, 0);
       subdevice = strtoll(pbuff, &pbuff, 0);
       class = strtoll(pbuff, &pbuff, 0);
       class_mask = strtoll(pbuff, &pbuff, 0);
       driver_data = strtoll(pbuff, &pbuff, 0);

      if ((( vendor == vendor_id && device == device_id ) ||
           ( (int)vendor == -1 && (int)device == -1 && class == class_id )) &&
           ! check_module_ignore(modname)) {

           snprintf(modulename, BUFFSIZE, "%s", check_module_update(modname));

           ret[count] = strdup(modulename);
           count++;

      }
   }
   fclose(fd);
   ret[count] = NULL;
   return(ret);
}



