#!/bin/bash

#Colours
green_C="\e[0;32m\033[1m"
end_C="\033[0m\e[0m"
red_C="\e[0;31m\033[1m"
blue_C="\e[0;34m\033[1m"
yellow_C="\e[0;33m\033[1m"
purple_C="\e[0;35m\033[1m"
turquoise_C="\e[0;36m\033[1m"
gray_C="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${red_C}[!] Program terminated...\n${end_C}"

	rm ut.t* 2>/dev/null
	tput cnorm; exit 1
}

function helpPanel(){
	echo -e "\n${red_C}[!] Use: ./btcAnalyzer${end_C}"
	for i in $(seq 1 80); do echo -ne "${red_C}-"; done; echo -ne "${end_C}";
	echo -e "\n\n\t${gray_C}[-e]${end_C}${yellow_C} Exploration mode${end_C}"
	echo -e "\t\t${purple_C}unconfirmed_transactions${end_C}${yellow_C}:\t List unconfirmed transaction${end_C}"
	echo -e "\t\t${purple_C}inspect${end_C}${yellow_C}:\t\t\t Inspect a transaction hash${end_C}"
	echo -e "\t\t${purple_C}address${end_C}${yellow_C}:\t\t\t Inspect an address transaction${end_C}"
	echo -e "\n\n\t${gray_C}[-n]${end_C}${yellow_C} Limit records returned${end_C}${blue_C} (i.e.: -n 10)${end_C}"
	echo -e "\n\n\t${gray_C}[-i]${end_C}${yellow_C} Provide the transaction id${end_C}${blue_C} (i.e.: -i b52a02a343f60373e22fa8cec22d53f1e8dc2c1256c2bac183b3fa0825ec7550)${end_C}"
        
	echo -e "\n\n\t${gray_C}[-a]${end_C}${yellow_C} Provide the transaction address${end_C}${blue_C} (i.e.: -a 1CRmybnjrWf2oL7ZEGp4Rsp9W4iESVYFUT)${end_C}"
	echo -e "\n\n\t${gray_C}[-h]${end_C}${yellow_C} Show this help panel${end_C}"

	tput cnorm; exit 1
}

# Global Variables

unconfirmed_trx="https://www.blockchain.com/btc/unconfirmed-transactions"
trx_detail="https://www.blockchain.com/btc/tx/"
address_detail="https://www.blockchain.com/btc/address/"

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"
    local -r local_colors="${3}"
    local counter_colors=1
    local pair_numbers=1
    local selected_color=""

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' || "$(echo "${table}" | wc -w)" == "0" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                	if [ "${line}" == " $(echo "${line}" | grep -o "_" | xargs) " ]; then
                		table="${table}$(printf '#+ %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                	else
                		table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                	fi                    
                done

				if [ "${line}" == " $(echo "${line}" | grep -o "_" | xargs) " ]; then
					table="${table}#+\n"
					let pair=pair_numbers%2
					
					if [ $pair -ne 0 ]; then
						selected_color="$(echo "${local_colors}" | awk "{print $"${counter_colors}"}")"
						printTables "${table}" ${selected_color}
						let counter_colors+=1
						table=""
					fi
					let pair_numbers+=1
				else
	                table="${table}#|\n"
	            fi

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done
            
            selected_color="$(echo "${local_colors}" | awk "{print $"${counter_colors}"}")"
			printTables "${table}" "${selected_color}"
        fi
    fi
}

function printTables(){

	local -r current_table="${1}"
	local_color="${2}"

	if [ ! "${local_color}" ]; then
		echo -e "${green_C}"
	else
		echo -e "${!local_color}"
	fi

	if [[ "$(isEmptyString "${current_table}")" = 'false' ]]; then
       echo -e "${current_table}" | column -s '#' -t | awk '/+/{gsub(" ", "-", $0)}1'
    fi
    echo -e "${end_C}"
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function unconfirmedTransactions(){

	num_out=$1
	echo '' > ut.tmp
	
	while [ "$(cat ut.tmp | wc -l)" == "1" ]; do 
		curl -s "$unconfirmed_trx" | html2text > ut.tmp
	done
	
	hashes=$(cat ut.tmp | grep "Hash" -A 2 | grep -v -E "Hash|\--|Time" | cut -d ']' -f 1 | tr -d " [" | head -n $num_out)

	echo "Hash_Quantity_Bitcoin_Time"Â> ut.table

	for hash in $hashes; do
		qty=$(cat ut.tmp | grep "$hash" -A 12 | tail -n 1)
		btc=$(cat ut.tmp | grep "$hash" -A 8 | tail -n 1 | awk '{print $1}')
		tim=$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)
		echo "${hash}_${qty}_${btc}_${tim}" >> ut.table
	done

	cat ut.table | tr '_' ' ' | awk '{print $2}' | grep -v -E "Quantity" | tr '$,' ' ' | tr -d ' ' | sed 's/\..*//g' > money_file

	money=0; cat money_file | while read money_in_line; do 
		let money+=$money_in_line
		echo $money > money.tmp
	done;

	echo " _ _ _ " >> ut.table
	echo " _Total_ _ " >> ut.table
	echo " _$(cat money.tmp | awk '{printf ("$%.2f %s\n",$1,$4)}' | rev | sed "s/[[:digit:]]\{3\}/&,/g" | rev | sed 's/^,//')_ _ " >> ut.table
	
	printTable '_' "$(cat ut.table)" "turquoise_C"
	
	rm ut.t* money* 2>/dev/null
	
	tput cnorm
}

function inspectTrx(){
	url_trx="${trx_detail}${1}"

	echo "" > total.tmp
	echo "Fee_Total output_Total input" > total.table

	while [ "$(cat total.tmp | wc -l)" == "1" ]; do
		curl -s "${url_trx}" | html2text > total.tmp
	done

        header="$(echo "$(cat total.tmp | grep "^Fee" -m 1 -A 6 | grep -v -E "Fee|Amount|\--" | tr -d '\n' | sed 's/)/\n/' | cut -d '(' -f 1 | awk 'NR%2 {printf "%s_",$0;next}1')")"
        input="$(echo "$(cat total.tmp | grep "Total Input" -A 2 | grep -v -E "Total|\--|\n" | tr -d '\n' | cut -d '%' -f 1)")"
        echo "${header}_${input}" >> total.table

	echo " _ " >> total.table
    	echo "Input Address_Amount" >> total.table	
    	echo " _ " >> total.table
	echo "$(cat total.tmp | grep "From" -A 500 | grep "Details" -B 500 | grep "BTC\[\]" -C 3 | grep -v -E "BTC\[\]|Load" | tr -d '\n' | sed 's/\[//' | sed 's/)/\n/g;s/\[/\n/g' | cut -d ']' -f 1 | awk 'NR%2 {printf "%s_",$0;next;}1' | awk '{print $1 " BTC"}')" >> total.table

	echo " _ " >> total.table
        echo "OutInput Address_Amount" >> total.table
        echo " _ " >> total.table
        echo "$(cat total.tmp | grep "To" -m 1 -A 500 | grep "Details" -B 500 -m 1 | grep -v -E "To|Details|transaction|)." | tr -d '\n' | sed 's/\[//' | sed 's/)/\n/g;s/\[/\n/g' | cut -d ']' -f 1 | awk 'NR%2 {printf "%s_",$0;next;}1')" >> total.table

	printTable '_' "$(cat total.table)" ""yellow_C" "green_C" "red_C""

	rm total* 2>/dev/null
	tput cnorm
}

function getAddressDetail(){

  address_tr=$1

  echo "" > address.tmp
  echo "Transactions_Total received (BTC)_Total Sent (BTC)_Final Balance (BTC)" > address.table

  while [ "$(cat address.tmp | wc -l)" == "1" ]; do
    curl -s "${address_detail}${address_tr}" | html2text > address.tmp
  done

  btc_values="$(echo "$(cat address.tmp | grep -E "Transactions|Total Received|Total Sent|Final Balance" -A 2 | grep -v -E "\[|\--|Fee|\n|Total" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g')")"

  btc_value=$(curl -s "https://www.google.com/finance/quote/BTC-USD?sa=X&ved=2ahUKEwi2xfX335f3AhXUQzABHZvwB_UQ-fUHegQIFBAX" | html2text | grep "Bitcoin" -m 1 -A 2 | tail -n 1 | sed 's/,//' | awk '{print $1}' FS=".")

  echo "${btc_values}" >> address.table
  let btc1=$(echo "${btc_values}" | awk -F '_' '{print $2}' | awk '{print $1}' | awk '{print $1}' FS="." )*$btc_value 2>/dev/null
  btc1=$(if [ ! $btc1 ]; then echo "0.00"; else echo "$btc1"; fi)
  let btc2=$(echo "${btc_values}" | awk -F '_' '{print $3}' | awk '{print $1}' | awk '{print $1}' FS="." )*$btc_value 2>/dev/null
  btc2=$(if [ ! $btc2 ]; then echo "0.00"; else echo "$btc2"; fi)
  let btc3=$(echo "${btc_values}" | awk -F '_' '{print $4}' | awk '{print $1}' | awk '{print $1}' FS="." )*$btc_value 2>/dev/null
  btc3=$(if [ ! $btc3 ]; then echo "0.00"; else echo "$btc3"; fi)

  echo " _ _ _ " >> address.table
  echo "Transactions_Total received (USD)_Total Sent (USD)_Final Balance (USD)" >> address.table
  echo " _ _ _ " >> address.table
  echo "$(echo "${btc_values}" | awk -F '_' '{print $1}')_\$"$btc1"_\$"$btc2"_\$"$btc3"" >> address.table

  printTable '_' "$(cat address.table)" ""gray_C" "blue_C""

  rm address* 2>/dev/null
  tput cnorm

}

param_counter=0; while getopts "e:h:i:a:n:" arg; do
	case $arg in
		e) explor_mode=$OPTARG; let param_counter+=1;;
		h) helpPanel;;
		i) trx_id=$OPTARG;;
		n) num_output=$OPTARG;;
                a) address_trx=$OPTARG;;
	esac
done

tput civis

if [ $param_counter -eq 0 ]; then
	helpPanel
else
	if [ "$(echo $explor_mode)" = "unconfirmed_transactions" ]; then
		if [ ! "$num_output" ]; then
			num_output=100
		else
			let num_output+=1;
			let num_output=num_output*2
		fi
		unconfirmedTransactions $num_output
	elif [ "$(echo $explor_mode)" == "inspect" ]; then
		inspectTrx $trx_id
        elif [ "$(echo $explor_mode)" == "address" ]; then
                getAddressDetail $address_trx
	fi
fi
