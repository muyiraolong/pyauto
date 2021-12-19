import paramiko
import threading
import sys,os
import datetime
from conf import logconf
from conf import pyliunx_conf
import getpass


if __name__ == '__main__':
    logtarget = os.path.basename(__file__).split('.')[0]
    logger = logconf.logconf(logtarget)

    hostname = ""

    with open("vmhost", "r", encoding='utf-8') as batch:
        hostnames = batch.readlines()
        batch.seek(0)
        hosttoal = len(open("vmhost", "r", encoding='utf-8').readlines())

    logger.info("There are  %d target host :/n%s" % (hosttoal, hostnames))
    # logger.info("following command will be execute %s" % (commands))
    logger.info("........................................Batch Process Begin........................................")

    for hostname in hostnames:
        targethost = hostname.strip("\n")

        username = "root"  # 用户名
        sshkey = input("Passwor or key ? Yes for key ,No for password :")

        while True:
            if sshkey == "Yes" or sshkey == "":
                password = ""
                logger.info("Login with ssh key")
                break
            else:
                logger.info("Login with Password")
                password = getpass.getpass('please type password of %s :' % username)
                break

        pyliunx_conf.get_connection(targethost,password)
        batch = threading.Thread(pyliunx_conf.paramiko.execute())
        batch.start()
        batch.join()
    logger.info("........................................Batch Process  End........................................")