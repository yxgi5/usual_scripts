import os.path
 
# 检查路径是否指向一个文件
def is_file(path):
    return os.path.isfile(path)
 
# 示例使用
path_to_file = "/path/to/your/file.txt"
 
if is_file(path_to_file):
    print(f"{path_to_file} 是一个文件。")
else:
    print(f"{path_to_file} 不是一个文件，可能是目录，不存在，或者是一个链接。")
