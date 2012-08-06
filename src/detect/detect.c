/*
 * This is a very simple C program used to probe the PCI bus, and compare the
 * vendor and model ID of every card found against the pcitable ASCII
 * database. From there it pulls the correct module name, and prints all of
 * the module names that were found for your system.
 *
 * Written by: Greg Kurtzer <greg@caosity.org>
 * License: GPL
 * 
 * Updated and cleaned up Arthur A. Stevens  astevens@infiscale.com
 *
 *
 *  
 *
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
#include "defs.h"
#include "config.h"



int show_pci_addr = 0;
int show_pci_ids = 0;
int noclass = 0;
int show_all = 0;


void arg_proccessor(int argc, char **argv)
{
    char c;
    while ((c = getopt (argc, argv, "haiqp")) != EOF)
    {
        switch (c)
        {
        case 'h':
            usage(argv[0]);
            break;
        case 'p':
            show_pci_addr=1;
            break;
        case 'a':
            show_all=1;
            break;
        case 'i':
            show_pci_ids=1;
            break;
        case 'q':
            noclass=1;
            break;
        default:
            usage(argv[0]);
            break;
        }
    }
}


int main (int argc, char **argv)
{
    struct dirent **namelist;
    char module[BUFFSIZE];
    char tmp[BUFFSIZE];
    int n, i, c;

    char **modules;

    arg_proccessor(argc, argv);

    n = scandir("/sys/bus/pci/devices/", &namelist, 0, alphasort);
    if (n < 0)
    {
        printf("ERROR: /sys is not mounted! Unable to probe...\n");
        return(1);
    }
    else
    {
        for (i=2; i<n; i++)
        {
            module[0] = '\0';
            modules = get_module_from_map(
                          vendor(namelist[i]->d_name),
                          device(namelist[i]->d_name),
                          class(namelist[i]->d_name));
            if ( modules[0] == NULL )
            {
                modules = get_module_from_kern(
                              vendor(namelist[i]->d_name),
                              device(namelist[i]->d_name),
                              class(namelist[i]->d_name));
            }
            if ( modules[0] == NULL && show_all )
            {
                if ( show_pci_addr )
                {
                    printf("%s ", namelist[i]->d_name);
                }
                if ( show_pci_ids )
                {
                    printf("%llx:%llx ", vendor(namelist[i]->d_name), device(namelist[i]->d_name));
                }
                if ( ! noclass )
                {
                    printf("%s ", get_class(class(namelist[i]->d_name)));
                }
                printf("unknown device\n");
            }
            else
            {
                for(c=0; modules[c] != NULL; c++)
                {
                    if ( show_pci_addr )
                    {
                        printf("%s ", namelist[i]->d_name);
                    }
                    if ( show_pci_ids )
                    {
                        printf("%llx:%llx ", vendor(namelist[i]->d_name), device(namelist[i]->d_name));
                    }
                    if ( ! noclass )
                    {
                        printf("%s ", get_class(class(namelist[i]->d_name)));
                    }
                    printf("%s\n", modules[c]);
                }
            }
            free(modules);

        }
        free(namelist);
    }
    return(0);
}
