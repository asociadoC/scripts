#!/bin/sh

MYUID=`whoami`

if [ $MYUID == "root" ]; then
        echo
        echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
        echo "You must use your NON-root account !"
        echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
        echo 
        exit 1
fi

REMOTE=192.168.120.55

compare() {

        echo "Comparing versions"
        echo 

        echo -n "Local Version : "
        VLOCAL=`md5sum rc.firewall | awk '{ print $1 }'`
        echo $VLOCAL

        echo -n "Remote Version : "
        VREMOTE=`ssh 192.168.120.55 "( cd /scripts ; md5sum rc.firewall )" | awk '{ print $1 }'`
        echo $VREMOTE

        if [ "$VLOCAL" == "$VREMOTE" ]; then
                echo "OK, Versions match"
                echo 
                applyRulesRemote
        else
                echo "WARN, Versions differ, sync required"
                echo -n "sync rc.firewall to $REMOTE now ? (y/n) "

                read ANSWER

                case $ANSWER in
                        y)
                                syncScripts
                                compare
                        ;;
                        n)
                                echo "Not doing anything, exit "
                                exit 0
                        ;;
                        *)
                                "not understood, exiting !"
                                exit 1
                        ;;
                esac
        fi
}

syncScripts() {
        ecoh
        echo "Trying sync "

        tar cf - rc.firewall | ssh $REMOTE "( cd /scripts ; sudo tar xf - )"

        if [ $? -eq 0 ]; then
                echo "OK, rc.firewall synced to $REMOTE"
                echo 
        else
                echo "ERROR, rc.firewall NOT synced"
                echo
        fi

}

applyRulesRemote() {
        echo -n "Apply rules on $REMOTE ? (y/n) "
        read APPLY

        case $APPLY in
                y)
                if ssh $REMOTE "( cd /scripts ; sudo sh rc.firewall stop && sudo sh rc.firewall start )" ; then
                        echo "applied rules on $REMOTE"
                else
                        echo "ERROR, please check on $REMOTE"
                fi
                ;;
                n)
                        echo "OK, exiting without applying"
                        exit 0
                ;;
                *)
                        echo "WARN, not understood, exiting !"
                        exit 1
                ;;
        esac
}

compare
