#!/bin/sh

DIR1=/etc/perceus/modules/stateful/ready
DIR2=/etc/perceus/modules/stateful/reinit

if [ "x$STATE" = "xinit" ]; then
   if [ ! -f ${DIR1}/${NODENAME} ] || [ -f ${DIR2}/vnfs/${VNFS} ] || [ -f ${DIR2}/group/${GROUPNAME} ] || [ -f ${DIR2}/node/${NODENAME} ]; then
      echo "INIT=yes"

      if [ -f ${DIR1}/${NODENAME} ]; then
         rm -rf ${DIR1}/${NODENAME}
      fi

      for dir in ${DIR2}/vnfs/${VNFS} ${DIR2}/group/${GROUPNAME} ${DIR2}/node/${NODENAME}; do
         if [ -f $dir ]; then
            rm -rf $dir
         fi
      done
   fi
fi

if [ "x$STATE" = "xready" ]; then
   touch ${DIR1}/${NODENAME}
fi
