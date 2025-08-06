#!/bin/bash
# 断电续打脚本 - 用于Klipper固件的断电恢复功能

mkdir -p {USER_HOME}/printer_data/gcodes/plr                           # 创建文件存储目录

#rm -f {USER_HOME}/printer_data/gcodes/plr/*                             # 删除可能存在的旧续打文件

# mkdir -p {USER_HOME}/printer_data/gcodes/plr/"${plr}"                           # 创建文件存储目录

PLR_PATH={USER_HOME}/printer_data/gcodes/plr                           # 续打文件存储目录

CONFIG_FILE="{USER_HOME}//printer_data/config/variables.cfg"            # 变量保存位置文件

filepath=$(sed -n "s/.*filepath *= *'\([^']*\)'.*/\1/p" {USER_HOME}/printer_data/config/variables.cfg)   # 获取打印文件路径
# 格式化路径字符串（处理特殊字符）
filepath=$(printf "$filepath")
# 打印文件路径（调试信息）



last_file=$(sed -n "s/.*last_file *= *'\([^']*\)'.*/\1/p" {USER_HOME}/printer_data/config/variables.cfg)  #获取打印文件名子
# 格式化文件名（处理特殊字符）
last_file=$(printf "$last_file")
# 打印文件名（调试信息）

# 设置续打文件名变量（使用原始文件名）
plr=$last_file


# ===== 初始化变量 =====
BED_TEMP="" 
EXTRUDER_TEMP="" 
CHAMBER_TEMP=""
Z_HEIGHT="" 
FILE_PATH="" 
LAST_FILE="" 

# ===== 调试信息头 =====
echo -e "\n===== 断电续打调试信息 ====="

Z_HEIGHT=$(awk -F " = " '/power_resume_z/ {gsub(/'\''/, "", $2); print $2}' $CONFIG_FILE)  # 提取Z高度

EXTRUDER_TEMP=$(awk -F " = " '/print_temp/ {gsub(/'\''/, "", $2); print $2}' $CONFIG_FILE)  # 提取挤出机温度

BED_TEMP=$(awk -F " = " '/bed_temp/ {gsub(/'\''/, "", $2); print $2}' $CONFIG_FILE)  # 提取热床温度

CHAMBER_TEMP=$(awk -F " = " '/hot_temp/ {gsub(/'\''/, "", $2); print $2}' $CONFIG_FILE)  # 提取打印仓温度



# ===== 显示关键信息 =====
echo "文件路径: ${PLR_PATH}/${plr}"
echo "续打文件: $last_file"
echo "Z轴高度: $Z_HEIGHT"
echo "打印仓温: $CHAMBER_TEMP"
echo "热床温度: $BED_TEMP"
echo "挤出温度: $EXTRUDER_TEMP"


# 将原始G代码文件复制到临时文件
cat "${filepath}" > /tmp/plrtmpA.$$

isInFile=$(cat /tmp/plrtmpA.$$ | grep -c "thumbnail")      # 检查文件中是否包含"thumbnail"（缩略图标记）

# # 处理无缩略图的情况
if [ $isInFile -eq 0 ]; then                               # 如果不包含缩略图
     echo 'M109 S200.0' > ${PLR_PATH}/"${plr}"             # 写入初始加热命令（安全温度）   
     echo 'SET_KINEMATIC_POSITION Z='${Z_HEIGHT}'' >> ${PLR_PATH}/"${plr}"  

# # 处理有缩略图的情况
else                                                                                       # 如果包含缩略图
    sed -i '1s/^/;start copy\n/' /tmp/plrtmpA.$$                                           # 在第一行前插入标记
    sed -n '/;start copy/, /thumbnail end/ p' < /tmp/plrtmpA.$$ > ${PLR_PATH}/"${plr}"     # 提取从标记到缩略图结束的内容
    echo ';' >> ${PLR_PATH}/"${plr}"                                                       # 添加注释分隔符
    echo '' >> ${PLR_PATH}/"${plr}"                                                        # 添加空行
    echo 'M109 S200.0' >> ${PLR_PATH}/"${plr}"                                             # 写入初始加热命令
    echo 'SET_KINEMATIC_POSITION Z='${Z_HEIGHT}'' >> ${PLR_PATH}/"${plr}"                  # 从G代码中提取Z高度并生成位置设置命令
fi



# # 添加热床和打印仓温度控制
# echo 'M140 S'${BED_TEMP} >> ${PLR_PATH}/"${plr}"          # 设置热床目标温度

# echo 'M190 S'${BED_TEMP} >> ${PLR_PATH}/"${plr}"          # 设置并等待热床达到目标温度

# echo 'M191 S'${CHAMBER_TEMP} >> ${PLR_PATH}/"${plr}"      # 设置打印仓温度（如有）


# 添加安全移动序列
echo 'G91' >> ${PLR_PATH}/"${plr}"      # 设置相对坐标模式

echo 'G1 Z10' >> ${PLR_PATH}/"${plr}"   # Z轴抬升10mm（避免碰撞）

echo 'G90' >> ${PLR_PATH}/"${plr}"      # 设置绝对坐标模式

echo 'G28 X Y' >> ${PLR_PATH}/"${plr}"  # XY轴归零（确保位置准确）

echo 'G91' >> ${PLR_PATH}/"${plr}"      # 设置相对坐标模式

echo 'G1 Z-5' >> ${PLR_PATH}/"${plr}"   # Z轴下降5mm（恢复原始高度）

echo 'G90' >> ${PLR_PATH}/"${plr}"      # 设置绝对坐标模式

#echo 'M106 S204' >> ${PLR_PATH}/"${plr}" # 开启部分风扇(80%功率)

#进行挤出模式处理

BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`

if [ "${BG_EX}" = "" ]; then
 BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
fi
M83=$(cat /tmp/plrtmpA.$$ | sed '/ Z'${1}'/q' | sed -ne '/\(M83\)/p')
if [ -n "${M83}" ];then
 echo 'G92 E0' >> ${PLR_PATH}/"${plr}"
 echo ${M83} >> ${PLR_PATH}/"${plr}"
else
 echo ${BG_EX} >> ${PLR_PATH}/"${plr}"
fi

# # 添加温度控制命令
#  echo 'M104 S'${EXTRUDER_TEMP} >> ${PLR_PATH}/"${plr}"      # 设置挤出机目标温度

#  echo 'M109 S'${EXTRUDER_TEMP} >> ${PLR_PATH}/"${plr}"        # 设置并等待挤出机达到目标温度

cat /tmp/plrtmpA.$$ | sed '/ Z'${1}'/q' | sed -ne '/\(M104\|M140\|M109\|M190\|M191\)/p' >> ${PLR_PATH}/"${plr}"

echo 'M220 S30' >> ${PLR_PATH}/"${plr}"                        # 降低速度以保证安全续打

# 定位到指定Z高度并输出后续内容

tac /tmp/plrtmpA.$$ | sed -e '/[; ]Z[: ]*'${Z_HEIGHT}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/[; ]Z/,$ p' >> ${PLR_PATH}/"${plr}"


# 清理临时文件
/bin/sleep 3                                 # 等待3秒确保文件写入完成
rm -f /tmp/plrtmpA.$$                       # 删除临时文件
