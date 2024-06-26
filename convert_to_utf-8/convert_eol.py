import os
 
def convert_eol(file_path):
    with open(file_path, 'r') as file:
        data = file.read()
    
    # 将CRLF替换为LF
    data = data.replace('\r\n', '\n')
    
    # 将修改后的数据写回文件
    with open(file_path, 'w') as file:
        file.write(data)
    
    # 如果需要，可以删除原始文件
    os.remove(file_path + '.bak')
 
# 使用函数转换文件
file_path = 'example.txt'
convert_eol(file_path)
