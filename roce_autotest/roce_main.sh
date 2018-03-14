#!/bin/bash

ROCE_TOP_DIR=$( cd "`dirname $0`" ; pwd )
ROCE_CASE_DIR=${ROCE_TOP_DIR}/case_script

# Load the public configuration library
. ${ROCE_TOP_DIR}/../config/common_config
. ${ROCE_TOP_DIR}/../config/common_lib

# Load module configuration library
. ${ROCE_TOP_DIR}/config/roce_test_config
. ${ROCE_TOP_DIR}/config/roce_test_lib

# Main operation function
# IN : N/A
# OUT: N/A
function main()
{
    Module_Name="ROCE"
    echo "Begin to run "$Module_Name" test"
	local MaxRow=$(sed -n '$=' "${ROCE_TOP_DIR}/${TEST_CASE_DB_FILE}")
	local RowNum=0

	while [ ${RowNum} -lt ${MaxRow} ]
	do
		let RowNum+=1
		local line=$(sed -n "${RowNum}p" "${ROCE_TOP_DIR}/${TEST_CASE_DB_FILE}")

		exec_script=`echo "${line}" | awk -F '\t' '{print $6}'`
		TEST_CASE_FUNCTION_NAME=`echo "${line}" | awk -F '\t' '{print $7}'`
		TEST_CASE_FUNCTION_SWITCH=`echo "${line}" | awk -F '\t' '{print $8}'`
                
                TEST_CASE_TITLE=`echo "${line}" | awk -F '\t' '{print $3}'`

                echo "TestCaseInfo "${TEST_CASE_TITLE}" "${exec_script}" "${TEST_CASE_FUNCTION_NAME}" "${TEST_CASE_FUNCTION_SWITCH} 

		if [ x"${exec_script}" == x"" ]
		then
			MESSAGE="unimplemented automated test cases."
			echo ${MESSAGE}
		else
			if [ ! -f "${ROCE_CASE_DIR}/${exec_script}" ]
			then
				MESSAGE="FILE\tcase_script/${exec_script} execution script does not exist, please check."
				echo ${MESSAGE}
			else
				if [ x"${TEST_CASE_FUNCTION_SWITCH}" == x"on"  ]
				then
			        	echo "Begint to run test "${TEST_CASE_TITLE}
					source ${ROCE_CASE_DIR}/${exec_script}
				else
					echo "Skip the script!"
				fi
			fi
		fi
		echo -e "${line}${MESSAGE}" >> ${ROCE_TOP_DIR}/${OUTPUT_TEST_DB_FILE}
		MESSAGE=""
		#echo "Done test: "${TEST_CASE_TITLE}
	done
}

#roce test is only excute in 159 dash board
#Find the local MAC
tmpMAC=`ifconfig eth0 | grep "HWaddr" | awk '{print $NF}'`
if [ x"${tmpMAC}" = x"${BOARD_159_MAC_ADDR}" ]
then
	echo "ROCE test can be excute in this board!"
else
	echo "ROCE test can not be excute in this board,exit!"
	exit 0
fi

#Get Local IP
initLocalIP 
LOCAL_IP=${COMMON_LOCAL_IP}
echo ${LOCAL_IP}

#Get client ip
getIPofClientServer ${DHCP_SERVER_MAC_ADDR} ${CLIENT_SERVER_MAC_ADDR} ${DHCP_SERVER_USER} ${DHCP_SERVER_PASS}

if [ x"${COMMON_CLIENT_IP}" = x"" ]
then
	echo "No found client IP,try ping default DHCP ip to update arp list!"
        ping ${COMMON_DEFAULT_DHCP_IP} -c 5
        getIPofClientServer ${DHCP_SERVER_MAC_ADDR} ${CLIENT_SERVER_MAC_ADDR} ${DHCP_SERVER_USER} ${DHCP_SERVER_PASS}
        if [ x"${COMMON_CLIENT_IP}" = x"" ]
        then
		echo "Can not find the client IP, exit hns test!"
                exit 0
        fi
fi

BACK_IP=${COMMON_CLIENT_IP}
echo "The client ip is "${BACK_IP}

#get BACK_IP according host's ip
#Init_Net_Ip
init_net_export

TrustRelation ${BACK_IP}

Set_Test_Ip

copy_tool_so

# Output log file header
writeLogHeader

main

# clean exit so lava-test can trust the results
exit 0

