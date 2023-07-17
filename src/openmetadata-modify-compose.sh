#!/usr/bin/env bash
set -Eeuxo pipefail

# References
# https://mikefarah.gitbook.io/yq/
# https://github.com/mikefarah/yq
# https://betterprogramming.pub/my-yq-cheatsheet-34f2b672ee58
# https://www.baeldung.com/linux/yq-utility-processing-yaml
# https://stackoverflow.com/a/70645530/4854757

# Variables
compose_top_level_name="openmetadata"
compose_file_name="docker-compose.yml"

# Check if yq is installed, else install
os_name=$(awk '/^ID=/{gsub(/ID=/,"");gsub(/"/,"");print $1}' /etc/os-release)
os_family=$(awk '/ID_LIKE=/{gsub(/ID_LIKE=/,"");gsub(/"/,"");print $1}' /etc/os-release)
if [[ -z ${os_family} ]];then os_family=${os_name};fi
required_bin="yq"
if [[ $(which ${required_bin} >/dev/null 2>&1;echo $?) != 0 ]];then
    echo -e "\nNeed to install ${required_bin}"
    if [[ ${os_family} =~ debian ]];then
        echo -e "\nInstalling ${required_bin} deb ... "
        sudo curl -fsSL https://github.com/mikefarah/${required_bin}/releases/latest/download/${required_bin}_linux_amd64 -o /usr/bin/${required_bin} && \
        sudo chmod +x /usr/bin/${required_bin}
    elif [[ ${os_family} =~ rhel ]];then
        echo -e "\nInstalling ${required_bin} rpm ... "
        sudo curl -fsSL https://github.com/mikefarah/${required_bin}/releases/latest/download/${required_bin}_linux_amd64 -o /usr/bin/${required_bin} && \
        sudo chmod +x /usr/bin/${required_bin}
    else
        echo -e "\nUnrecognized OS, but attempting to install anyway ... "
        sudo curl -fsSL https://github.com/mikefarah/${required_bin}/releases/latest/download/${required_bin}_linux_amd64 -o /usr/bin/${required_bin} && \
        sudo chmod +x /usr/bin/${required_bin}
    fi
else
    echo -e "\n${required_bin} is installed ... "
fi


# Update or add top level name for compose file
top_level_name=$(yq ".name" ${compose_file_name})
if [[ ${top_level_name} == null ]]
then
    yq -i ".name = \"${compose_top_level_name}\"" ${compose_file_name}
fi

# Update or add restart values for each service
key_list=$(yq '.services | keys' ${compose_file_name} | cut -c '2-')
for i in ${key_list}
do restart_value=$(yq ".services.${i}.restart" ${compose_file_name})
    if [[ $restart_value == null ]]
    then
        yq -i ".services.${i}.restart = \"always\"" ${compose_file_name}
    fi
done

