import os,time

def newfile(targetfile):
    path = os.path.dirname(os.getcwd())
    logpath = os.path.join(path, "worklog")
    logfileformat = str(targetfile+time.strftime("_%Y-%m-%d_%H_%M_%S", time.localtime()) + '.log')
    createlogfile = os.path.join(logpath, logfileformat)
    createlogfile = createlogfile.replace('\\', '/')
    with open(createlogfile, mode="a", encoding="utf-8") as f:
        pass
    print(f"this logfile : {createlogfile} is create by programer :{targetfile}")
    return createlogfile