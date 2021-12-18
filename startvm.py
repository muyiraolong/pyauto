import datetime
import os
import gc
import threading
from conf import logconf

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

@timecost
def execCmd(cmd,vm):
    cmd = cmd + " " + "start" + " " + vm + " " + "gui"
    try:
        os.system(cmd)
    except:
        print('%s\t 运行失败' % (cmd))

if __name__ == '__main__':
    gc.collect()
    logtarget = os.path.basename(__file__).split('.')[0]
    logger = logconf.logconf(logtarget)        #init log config
    # 是否需要并行运行
    if_parallel = True
    # 需要执行的命令列表
    cmdvm = r'"D:\\Apps\\VMware\\VMware Workstation\\vmrun.exe"'
    print(cmdvm)

    vm1 = "E:\inno\win200\win80.vmx"
    vm3 = "H:\inno.com\win70\win80.vmx"
    vm4 = "H:\inno.com\win71\win80.vmx"
    vm2 = "I:\inno.com\win72\win80.vmx"

    vms = [vm1, vm2, vm3, vm4]

    if if_parallel:
        threads = []
        for vm in vms:
            th = threading.Thread(target=execCmd, args=(cmdvm,vm))
            th.start()
            threads.append(th)
        # 等待线程运行完毕
        for th in threads:
            th.join()
    else:
        # 串行
        for cmd in cmds:
            try:
                print("Command %s start run%s" % (cmd, datetime.datetime.now()))
                os.system(cmd)
                print("Command %s run end %s" % (cmd, datetime.datetime.now()))
            except:
                print('%s\t failed' % (cmd))
    gc.collect()