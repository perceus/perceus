/*
 * P E R C E U S
 * provisiond.c
 *
 * Provisioning daemon.  A compute node runs this daemon and sends a provisioning
 * command back to a PERCEUS master server.  The master sends shell commands back
 * to this daemon, and the daemon runs them in a shell.
 *
 * Copyright (c) 2006-2011 Infiscale, Inc. All rights reserved
 *
 * Contributors : A. Stevens G. Kurtzer, S. Houston, J. Brown
 * patches not flames to astevens@infiscale.com
 *
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/sysinfo.h>
#include <netinet/in.h>
#include <net/if.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <stdarg.h>
#include <limits.h>

static void usage(const char *program);
static void signal_handler(int sigVal);
static int ddprintf(const char *format, ...);
static int print_error(const char *format, ...);
static int print_warning(const char *format, ...);
static void loop_end_block(int opt_interval);

const char *gDefaultShell = "/bin/sh";
int gShouldTerminate = 0;
int gShouldDebug = 0;
int gSilent = 1;
int gPipeDidClose = 0;
int sd = -1;

#ifndef PROVISIOND_CONFIG_PORT
#define PROVISIOND_CONFIG_PORT 987
#endif

#ifndef PROVISIOND_COMMAND_BUFFER_LEN
#define PROVISIOND_COMMAND_BUFFER_LEN 1024
#endif

static void
usage(const char *program)
{
    /* *INDENT-OFF* */
    printf("USAGE: %s [options] <server[,server...]> <state> [action]\n\n"
           "[options]\n"
           "   -i <interval>   Run in daemon mode with <interval> checkins\n"
           "   -p <port>       Port to contact on the config server (default: %d)\n"
           "   -r              Randomize config servers (if > 1 are given)\n"
           "   -h              Show this usage summary\n"
           "   -s <shell path> Shell to interpret the receiving script (default: %s)\n"
           "   -d              Run in debug mode (extra output and no forking)\n"
           "   -v              Run in verbose mode (display warnings/errors)\n\n"
           "Provisiond is maintained by Arthur Stevens <astevens@infiscale.com>\n",
           program, PROVISIOND_CONFIG_PORT, gDefaultShell);
    /* *INDENT-ON* */
}

static void
signal_handler(int sigVal)
{
    switch (sigVal)
    {
    case SIGALRM:
        ddprintf("SIGALARM recieved\n");
        if (sd >= 0)
        {
            close(sd);
            sd = -1;
        }
        break;

    case SIGPIPE:
        gPipeDidClose = 1;
        break;

    case SIGTERM:
        ddprintf("SIGTERM recieved, exiting daemon\n");
        gShouldTerminate = 1;
        break;

    case SIGINT:
        ddprintf("SIGINT recieved, exiting daemon\n");
        exit(-1);
        break;

    case SIGHUP:
        ddprintf("SIGHUP recieved, exiting daemon\n");
        gShouldTerminate = 1;
        break;

    default:
        ddprintf("unknown signal (%d) recieved, exiting daemon\n", sigVal);
        gShouldTerminate = 1;
        break;

    }
}

static int
ddprintf(const char *format, ...)
{
    va_list args;
    int n;

    if (!gShouldDebug || gSilent)
    {
        return 0;
    }

    va_start(args, format);
    n = fprintf(stderr, "DEBUG:  ");
    n += vfprintf(stderr, format, args);
    va_end(args);
    fflush(stderr);
    return n;
}

static int
print_error(const char *format, ...)
{
    va_list args;
    int n;

    if (gSilent)
    {
        return 0;
    }
    va_start(args, format);
    n = fprintf(stderr, "ERROR:  ");
    n += vfprintf(stderr, format, args);
    va_end(args);
    fflush(stderr);
    return n;
}

static int
print_warning(const char *format, ...)
{
    va_list args;
    int n;

    if (gSilent)
    {
        return 0;
    }
    va_start(args, format);
    n = fprintf(stderr, "WARNING:  ");
    n += vfprintf(stderr, format, args);
    va_end(args);
    fflush(stderr);
    return n;
}

static void
loop_end_block(int opt_interval)
{
    /* If we have an interval to sleep, then sleep; otherwise, we need
       to immediately exit the loop: */
    if (opt_interval)
    {
        sleep(opt_interval);
    }
    else
    {
        gShouldTerminate = 1;
    }
    if (sd >= 0)
    {
        close(sd);
        sd = -1;
    }
}

int
main(int argc, char *argv[])
{
    int opt_usage = 0, opt_interval = 0, opt_randomize = 0;
    int opt_port = PROVISIOND_CONFIG_PORT;
    char *opt_shell = NULL;
    int argn, opt, resultCode;
    int loop_count = 0;
    size_t provCmdLen = 0;
    char *provCmd = NULL;
    char **masterAddr = NULL;
    char *provState = NULL;
    char *pbuff;
    char cmdBuffer[PROVISIOND_COMMAND_BUFFER_LEN];
    int myPID;
    struct sockaddr_in sockAddr;
    struct hostent *hostAddr;

    /* Setup signal catches: */
    signal(SIGTERM, signal_handler);
    signal(SIGINT, signal_handler);
    signal(SIGHUP, signal_handler);
    signal(SIGPIPE, signal_handler);
    signal(SIGALRM, signal_handler);

    opt_shell = strdup(gDefaultShell);

    /* Process any cli options: */
    while ((opt = getopt(argc, argv, "p:i:s:drhv")) != -1)
    {
        switch (opt)
        {
        case 'd':
            gShouldDebug++;
            gSilent = 0;
            break;

        case 'p':
        {
            int port = strtol(optarg, NULL, 10);

            if (port > 0)
            {
                opt_port = port;
            }
            else
            {
                print_warning("The specified port was invalid: %s\n", optarg);
            }
            break;
        }

        case 'i':
        {
            int interval = strtol(optarg, NULL, 10);

            if (interval >= 0)
            {
                opt_interval = interval;
            }
            else
            {
                print_warning("The specified interval was invalid: %s\n", optarg);
            }
            break;
        }

        case 's':
            if (opt_shell)
            {
                free(opt_shell);
            }
            opt_shell = strdup(optarg);
            break;

        case 'r':
            opt_randomize = 1;
            break;

        case 'h':
            opt_usage++;
            break;

        case 'v':
            gSilent = 0;
            break;
        }
    }

    if (opt_usage)
    {
        usage(argv[0]);
        exit(0);
    }

    /* We can zip past the options using optind.  Now, <server> = argv[0] */
    argc -= optind;
    argv += optind;

    /* We need at LEAST two more arguments here, so complain if we don't
       have 'em: */
    if (argc < 2)
    {
        print_error("You must specify an IP address to bind to as well as a provisionary state\n");
        exit(1);
    }

    /* Copy host address string to a new buffer and check for comma-separated server list. */
    masterAddr = (char **) malloc(2 * sizeof(char *));
    masterAddr[0] = strdup(*argv++);
    masterAddr[1] = NULL;
    for (pbuff = masterAddr[0], argn = 1; *pbuff; pbuff++)
    {
        if (*pbuff == ',')
        {
            char **tmp;

            /* Terminate string at comma. */
            *pbuff++ = 0;
            ddprintf("Got master server address:  \"%s\"\n", masterAddr[argn - 1]);

            /* Resize string list.  Save old value just in case realloc fails. */
            tmp = (char **) realloc(masterAddr, (argn + 2) * sizeof(char *));
            if (tmp == NULL)
            {
                /* Memory allocation failed.  Stop adding failover hosts. */
                print_error("Memory reallocation failed.  Only %d master servers saved.\n", argn);
                break;
            }
            masterAddr = tmp;
            masterAddr[argn] = pbuff;
            argn++;
            masterAddr[argn] = NULL;
        }
    }
    ddprintf("Got master server address:  \"%s\"\n", masterAddr[argn - 1]);
    ddprintf("Got %d master server addresses.\n", argn);

    /* Randomize master server addresses if requested. */
    if (opt_randomize && (argn > 1))
    {
        int i;

        srandom(time(NULL));
        for (i = 0; i < argn; i++)
        {
            int j;

            /* Pick a random index within the array and swap values. */
            j = (int) (random() % argn);
            if (i != j)
            {
                char *tmp;

                tmp = masterAddr[i];
                masterAddr[i] = masterAddr[j];
                masterAddr[j] = tmp;
            }
        }
    }

    provState = *argv++;
    argc -= 2;

    /* Build the command line we'll invoke for provisioning.  This uses
       whatever was left on the command line after option parsing.  The
       two is a newline and NULL at the end of the string: */
    provCmdLen = strlen(provState) + 2;
    for (argn = 0; argn < argc; argn++)
    {
        provCmdLen += 1 + strlen(argv[argn]);
    }
    if ((provCmd = malloc(provCmdLen)) == NULL)
    {
        print_error("could not allocate command buffer\n");
        exit(1);
    }
    strncpy(provCmd, provState, provCmdLen);
    for (argn = 0; argn < argc; argn++)
    {
        strncat(provCmd, " ", provCmdLen);
        strncat(provCmd, argv[argn], provCmdLen);
    }

    /* If we're in debug mode, show some info: */
    ddprintf("Provisioning in \"%s\" state every %d seconds:  %s \"%s\"\n", provState, opt_interval,
             ((opt_shell) ? (opt_shell) : (gDefaultShell)), provCmd);

    /* Add the trailing newline ONLY after we've (possibly) displayed
       the command we've built to the user in debug mode: */
    provCmd[provCmdLen - 2] = '\n';
    provCmd[provCmdLen - 1] = '\0';

    /* Fork now or forever hold your peace: */
    if (!gShouldDebug && opt_interval)
    {
        if (((myPID = fork()) < 0) || (myPID != 0))
        {
            exit(0);
        }
    }

    /* Voila, here's our main runloop: */
    for (resultCode = 0; !resultCode && !gShouldTerminate; loop_end_block(opt_interval))
    {
        int retries, info_length;
        ssize_t bytesWritten, bytesRead;
        FILE *shellPipe;

        if (sd < 0)
        {
            int i;

            /* Try each master server in order. */
            for (i = 0; masterAddr[i]; i++)
            {

                /* Retry connect() up to 5 times before failing permanently.  2 second timeout. */
                for (retries = 0; retries < 5; retries++)
                {
                    /* Resolve the <server> argument to an IP: */
                    if ((hostAddr = gethostbyname(masterAddr[i])) == NULL)
                    {
                        print_error("No such host:  %s\n", masterAddr[i]);
                        exit(1);
                    }

                    /* Setup the socket address; we'll reuse this: */
                    memset(&sockAddr, 0, sizeof(sockAddr));
                    sockAddr.sin_family = AF_INET;
                    memcpy(&sockAddr.sin_addr.s_addr, hostAddr->h_addr, hostAddr->h_length);
                    sockAddr.sin_port = htons(opt_port);

                    if ((sd < 0) && (sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
                    {
                        print_error("Unable to create socket -- %s\n", strerror(errno));
                        retries = 5;
                        break;
                    }

                    if (gShouldDebug)
                    {
                        char addrBuffer[INET_ADDRSTRLEN];

                        ddprintf("Connecting socket %d to %s (%s) on port %d\n", sd, masterAddr[i],
                                 inet_ntop(hostAddr->h_addrtype, hostAddr->h_addr, addrBuffer, INET_ADDRSTRLEN),
                                 opt_port);
                    }

                    alarm(2);
                    if (connect(sd, (const struct sockaddr *) &sockAddr, sizeof(sockAddr)) == 0)
                    {
                        alarm(0);
                        break;
                    }
                    else
                    {
                        alarm(0);
                        print_warning("Unable to connect to %s -- %s\n", masterAddr[i], strerror(errno));
                        if (errno != EINTR)
                        {
                            /* If the connect failed for something other
                               than SIGALRM, sleep for the 2 second timeout. */
                            sleep(2);
                        }
                    }
                }
                if (retries == 5)
                {
                    print_warning("Unable to connect to %s after %d tries.  Moving on.\n", masterAddr[i], retries);
                    if (sd >= 0)
                    {
                        close(sd);
                        sd = -1;
                    }
                    continue;
                }
                else
                {
                    ddprintf("Connection established.\n");
                    break;
                }
            }
        }

        if (sd < 0)
        {
            if (opt_interval == 0)
            {
                /* Exit out if no connection is made and no repeat interval was given. */
                print_warning("Unable to contact any master server.  Giving up.\n");
                resultCode = 255;
                break;
            }
            else
            {
                print_warning("Unable to contact any master server.  Going back to sleep.\n");
                continue;
            }
        }

        /* We're connected; send the provisionary state and arguments to the master */
        if ((bytesWritten = write(sd, provCmd, provCmdLen)) != (ssize_t) provCmdLen)
        {
            print_warning("Wrote only %d of %d bytes -- %s.  Starting over.\n",
                          ((bytesWritten <= 0) ? (0) : (bytesWritten)), ((errno) ? (strerror(errno)) : ("Reason unknown")));
            continue;
        }

        /* Open a pipe to a shell so we can send it the command that the
           master sends to us: */
        if ((shellPipe = popen(opt_shell, "w")) == NULL)
        {
            print_warning("Unable to open shell pipe -- %s.  Starting over.\n", strerror(errno));
            continue;
        }
        else
        {
            gPipeDidClose = 0;
        }

        /* Keep reading what the master is sending us and writing each chunk to the shell pipe: */
        ddprintf("Reading from socket...\n");
        alarm(5);
        while (!gPipeDidClose && (bytesRead = read(sd, cmdBuffer, PROVISIOND_COMMAND_BUFFER_LEN - 1)) > 0)
        {
            alarm(0);
            /* ddprintf("Read %d bytes.\n", bytesRead); */
            cmdBuffer[bytesRead] = '\0';
            if (fputs(cmdBuffer, shellPipe) == EOF)
            {
                break;
            }
            alarm(5);
        }
        alarm(0);
        resultCode = pclose(shellPipe);
        if (WIFEXITED(resultCode))
        {
            resultCode = WEXITSTATUS(resultCode);
            ddprintf("Command returned %d\n", resultCode);
        }
        else if (WIFSIGNALED(resultCode))
        {
            ddprintf("Command received fatal signal %d\n", WTERMSIG(resultCode));
        }
        loop_count++;
    }

    return (resultCode);
}

