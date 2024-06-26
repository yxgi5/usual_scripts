import sys
 
# 定义颜色
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
 
# 打印彩色文本的函数
def print_colored(text, color):
    print(color + text + Colors.ENDC)
 
# 使用例子
print_colored('这是红色文本', Colors.FAIL)
print_colored('这是绿色文本', Colors.OKGREEN)
