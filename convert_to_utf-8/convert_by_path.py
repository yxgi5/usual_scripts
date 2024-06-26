#!/usr/bin/python3

import os
import chardet
import codecs
import argparse
import chardet

def WriteFile(filePath, u, encoding="utf-8"):
    with codecs.open(filePath, "w", encoding) as f:
        # 将CRLF替换为LF
        u = u.replace('\r\n', '\n')
        f.write(u)

def is_binary_file(file_path):
    with open(file_path, 'rb') as f:
        data = f.read(1024)  # 读取前1024字节
        f.close()
        result = chardet.detect(data)
        return result['confidence'] < 0.9
 

def GBK_2_UTF8(src, dst):
    if is_binary_file(src) == True:
        print(src + " is a binary file!")
        return
    #     检测编码，coding可能检测不到编码，有异常
    f = open(src, "rb")
    coding = chardet.detect(f.read())["encoding"]
    f.close()
    #if coding != "utf-8":
    # print(src)
    with codecs.open(src, "r", coding) as f:
        try:
            WriteFile(dst, f.read(), encoding = "utf-8")
            try:
                print(src + "  " + coding + " to utf-8  converted!")
            except Exception:
                print("print error")
        except Exception:
            print(src +" "+ coding+ " read error!")

# 检查路径是否指向一个文件
def is_file(path):
    return os.path.isfile(path)

# 把目录中的*.c/*.h编码由gbk转换为utf-8
def ReadDirectoryFile(rootdir):
    if rootdir=='':
        print("No path given!!")
        return

    if is_file(src_file):
        print(f"{src_file} 是一个文件。")
        return

    for parent, dirnames, filenames in os.walk(rootdir):
        for dirname in dirnames:
          	#递归函数，遍历所有子文件夹
            #ReadDirectoryFile(dirname)
            pass
        for filename in filenames:
            GBK_2_UTF8(os.path.join(parent, filename),
                           os.path.join(parent, filename))
'''
            if filename.endswith(".h"):
                GBK_2_UTF8(os.path.join(parent, filename),
                           os.path.join(parent, filename))
            if filename.endswith(".c"):
                GBK_2_UTF8(os.path.join(parent, filename),
                           os.path.join(parent, filename))
            if filename.endswith(".tcl"):
                GBK_2_UTF8(os.path.join(parent, filename),
                           os.path.join(parent, filename))
'''


def ReadFile(src_file):
    if src_file=='':
        print("No path given!!")
        return
    if is_file(src_file):
        print(f"{src_file} 是一个文件。")
    else:
        print(f"{src_file} 不是一个文件，可能是目录，不存在，或者是一个链接。")
        return

    parent = os.path.dirname(os.path.realpath(src_file))
    filename = os.path.basename(os.path.realpath(src_file))
    #print(parent)
    #print(filename)
    GBK_2_UTF8(os.path.join(parent, filename), os.path.join(parent, filename))
    pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="")
    #src_path = "."
    parser.add_argument('-p','--path', default='')
    parser.add_argument('-f','--file', default='')
    args = parser.parse_args()
    print(args) 
    src_path = args.path
    if src_path!='':
        ReadDirectoryFile(src_path)

    src_file = args.file
    if src_file!='':
        ReadFile(src_file)


