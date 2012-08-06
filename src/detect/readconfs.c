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

int check_module_ignore(char * module) {
   FILE *fd;
   char ignore[BUFFSIZE];
   char buffer[BUFFSIZE];
   char config[BUFFSIZE];

   sprintf(config, "%s/ignore", DETECTSYSCONFIGDIR);

   if ((fd = fopen(config, "r"))  == NULL ) {
      printf("could not open %s!\n", config);
      exit(1);
   }

   while(!feof(fd)) {
      fgets(buffer, BUFFSIZE-1, fd);

      if ( strncmp("#", buffer, 1) || strncmp("\n", buffer, 1)) {

         sscanf(buffer, "%s\n", ignore);

         if (! strcmp(ignore, module)) {
            fclose(fd);
            return(1);
         }
      }
   }
   fclose(fd);
   return(0);
}

char * check_module_update(char * module) {
   FILE *fd;
   static char module_def[BUFFSIZE];
   static char module_update[BUFFSIZE];
   char buffer[BUFFSIZE];
   char config[BUFFSIZE];

   sprintf(config, "%s/updates", DETECTSYSCONFIGDIR);

   if ((fd = fopen(config, "r"))  == NULL ) {
      printf("could not open %s!\n", config);
      exit(1);
   }

   while(!feof(fd)) {
      fgets(buffer, BUFFSIZE-1, fd);

      if ( strncmp("#", buffer, 1) || strncmp("\n", buffer, 1)) {

         sscanf(buffer, "%s %s", module_def, module_update);

         if (! strcmp(module_def, module)) {
            fclose(fd);
            return(module_update);
         }

      }

   }
   fclose(fd);
   return(module);
}

