#! /usr/bin/bash
# Script to scan hosts ports using NMAP

check_nmap_installation() {
  is_nmap_installed=$(command -v nmap > /dev/null && echo 1 || echo 0)

  if [ "$is_nmap_installed" -eq 0 ] ; then
    echo "nmap is not installed"
    exit 1
  fi
}

check_network() {
  regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$"

  if [ "$1" = "" ] ; then
    echo "No network target to scan. Example: 192.168.0.1/24"
    exit 1
  fi

  if [[ ! $1 =~ $regex ]] ; then
    echo "Invalid network or subnet. Example: 192.168.0.1/24"
    exit 1
  fi
}

{
  check_nmap_installation
  check_network "$1"
}

addresses="$(sudo nmap -n -sn "$1" -oG - | awk '/Up$/{print $2}')"

current_timestamp="$(date '+%s')"

echo "$addresses" > "logs/ips_dump_$current_timestamp.txt"

dump_file="logs/scan_dump_$current_timestamp.log.md"

{
  printf "# NMAP Scans\n\n"
  echo "## Hosts summary"
  printf "\n%s\n\n" "$(
    while IFS= read -r addr
    do
      if [ "$addr" != "" ] ; then
        echo "- $addr"
      fi
    done <<< "$addresses"
  )"
  printf "## Unit scans\n\n"
} >> "$dump_file"

code_block_wrapper_chars="\`\`\`"

# shellcheck disable=SC2183
vertical_divider=$(printf "%*s" "$(tput cols)" | tr " " "-")

while IFS= read -r ipv4
do
  if [ "$ipv4" != "" ] ; then
    {
      printf "### Results for host %s\n\n" "$ipv4"
      printf "%s\n" "$code_block_wrapper_chars"
    } >> "$dump_file"

    sudo nmap -sV -O "$ipv4" | tee -a "$dump_file"

    printf "\n%s\n\n" "$vertical_divider"

    printf "%s\n\n" "$code_block_wrapper_chars" >> "$dump_file"
  fi
done <<< "$addresses"
