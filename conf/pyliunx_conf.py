import paramiko
from timeit import default_timer
import os
import  datetime

user = 'root'
password = 'Lenovo@2020'
#pkey = r'"F:\myauto\pysh\id_rsa"'

def timecost(func):
    def inner(*args, **kwargs):
        starttime = datetime.datetime.now()
        func_name = str(func).split(' ')[1]
        logger.info('Start execute %s at %s',func_name,starttime.strftime('%Y-%m-%d %H:%M:%S.%f'))
        logger.info('Execute %s with parameter: %s ', func_name,(args or kwargs or ('No parameter')))
        result = func(*args, **kwargs)
        func_name = str(func).split(' ')[1]
        endtime = datetime.datetime.now()
        logger.info('Execute %s end at %s', func_name, endtime.strftime('%Y-%m-%d %H:%M:%S.%f'))
        logger.info('Execute %s is successfully finish with parameter: %s done', func_name, (args or kwargs or ('No parameter')))
        logger.info('Execute {} using times: {}s'.format(func_name,endtime - starttime))
        return result
    return inner

# ---- paramiko connect to linux host
@timecost
def get_connection(server, password):
    try:
        if password == None:
            privatekey = paramiko.RSAKey.from_private_key_file(keyfile)
            conn=ssh_client.connect(server, 22, user, pkey=privatekey)
        else:
            conn=ssh_client.connect(server, 22,user,password)

    except paramiko.AuthenticationException:
        try:
            conn=ssh_client.connect(server, 22, user, password)
        except:
            get_connection(password)
    except:
        exit()

    return conn

# ---- 使用 with 的方式来优化代码
class paramiko(object):

    def __init__(self, commit=True, log_time=True, log_label='总用时'):
        """
        :param commit: 是否在最后提交事务(设置为False的时候方便单元测试)
        :param log_time:  是否打印程序运行总时间
        :param log_label:  自定义log的文字
        """
        self._log_time = log_time
        self._log_label = log_label

    def __enter__(self):

        # 如果需要记录时间
        if self._log_time is True:
            self._start = default_timer()

        # 在进入的时候自动获取连接和cursor
        conn = get_connection()

        self._conn = conn
        return self

    def execute(self,sudo=False):
        logfile = logtarget +'.' + server.split('.')[0]+'_'+str(os.getpid())
        logger = logconf.logconf(logfile)  # init log config
        commands=""
        path = os.path.dirname(os.getcwd())
        with open("f:\pyauto\conf\command.txt", 'r', encoding='utf-8') as batch:
            commands = batch.readlines()
        logger.info("following command will be execute %s" % (commands))

        for command in commands:
            command = command.strip("\n")
            try:
                starttime = datetime.datetime.now()
                self.logger.info('Start execute command: (%s) on host (%s) ',command,self.server)
                stdin, stdout, stderr = self.ssh_client.exec_command(command,timeout=180)
                self.logger.info('Following is the (%s) result \n',command)
                self.logger.info(stdout.read().decode(encoding='utf-8'))
                self.logger.info('Execute ({}) used times: ({}s) \n'.format(command, datetime.datetime.now() - starttime))
            except paramiko.SSHException:
                self.logger.error(stderr.read().decode(encoding='utf-8'),exc_info=True)
                self.logger.info("End of  execute on server (%s)",self.server)
                self.logger.error("Pls check the reason and run agin", self.server)
                exit()
                if sudo:
                    stdin.write(self.password + '\n')
                    stdin.flush()
            if stderr.read().decode(encoding='utf-8'):
                self.logger.error(stderr.read().decode(encoding='utf-8'), exc_info=True)
                self.logger.info("End of  execute on server (%s)", self.server)
                self.logger.error("Pls check the command (%s) and run agin",command)
                self.status = False
                break
        if self.status == False:
            self.logger.info("One of the command is run failed  on (%s),pls check the logfile (%s) for detail information !!! \n", self.server,os.path.join(os.path.dirname(os.getcwd()),'worklog',self.logfile))
        else:
            self.logger.info("all the batch process running successfully on (%s) \n", self.server)

    def __exit__(self, *exc_info):
       self._conn.close()
       if self._log_time is True:
           diff = default_timer() - self._start
           print('-- %s: %.6f 秒' % (self._log_label, diff))