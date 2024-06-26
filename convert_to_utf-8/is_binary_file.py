import mimetypes
 
def is_binary_file(filename):
    # 首先通过mimetypes模块判断文件的MIME类型
    mime_type, _ = mimetypes.guess_type(filename)
    if mime_type is None:
        return True  # 如果无法确定MIME类型，则假定是二进制文件
    
    # 尝试以二进制模式打开文件
    try:
        with open(filename, 'rb') as f:
            data = f.read(1024)  # 读取前1024字节
            # 检查这1024字节内是否包含非文本字符
            return b'\0' in data or b'\x01' in data or b'\x02' in data or b'\x03' in data or b'\x04' in data or b'\x05' in data or b'\x06' in data or b'\a' in data or b'\b' in data or b'\t' in data or b'\n' in data or b'\v' in data or b'\f' in data or b'\r' in data or b'\x0e' in data or b'\x0f' in data or b'\x10' in data or b'\x11' in data or b'\x12' in data or b'\x13' in data or b'\x14' in data or b'\x15' in data or b'\x16' in data or b'\x17' in data or b'\x18' in data or b'\x19' in data or b'\x1a' in data or b'\x1b' in data or b'\x1c' in data or b'\x1d' in data or b'\x1e' in data or b'\x1f' in data or b'\x7f' in data or b'\x18' in data or b'\x19' in data or b'\x1a' in data or b'\xe2' in data or b'\x80' in data or b'\x81' in data or b'\x82' in data or b'\x83' in data or b'\x84' in data or b'\x85' in data or b'\x86' in data or b'\x87' in data or b'\x88' in data or b'\x89' in data or b'\x8a' in data or b'\x8b' in data or b'\x8c' in data or b'\x8d' in data or b'\x8e' in data or b'\x8f' in data or b'\x90' in data or b'\x91' in data or b'\x92' in data or b'\x93' in data or b'\x94' in data or b'\x95' in data or b'\x96' in data or b'\x97' in data or b'\x98' in data or b'\x99' in data or b'\x9a' in data or b'\x9b' in data or b'\x9c' in data or b'\x9d' in data or b'\x9e' in data or b'\x9f' in data or b'\xff' in data or b'\xfe' in data:
                return True  # 如果包含非文本字符，则假定是二进制文件
    except FileNotFoundError:
        return False  # 如果文件不存在，则不是二进制文件
    
    return False  # 如果文件是文本，则不是二进制文件
 

"""
import chardet
 
def is_binary_file(file_path):
    # 尝试解码前十千个字节
    with open(file_path, 'rb') as f:
        binary_data = f.read(10000)
    
    # 使用chardet检测编码，如果无法确定编码，则可能是二进制文件
    result = chardet.detect(binary_data)
    return result['confidence'] < 0.95
"""
