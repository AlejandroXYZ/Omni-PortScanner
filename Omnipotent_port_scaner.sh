#!/bin/bash

# Escaner de Puertos omnipotente ( diferentes tipos de escaneo )


# Variables
hilos=500
dir_router=$(route -n | head -n 3 | awk '{ print $2 }' | tail -n 1| cut -d. -f1-3)
direccion=$(for i in $(seq 1 256); do
    		echo "$dir_router"\.$i 
			done)

# Banner

banner(){
	cat .banner.ascii
}

#Funcion de salida
ctrl_c(){
	echo -e "\nSaliendo...\n"
	rm scan.tmp 2>/dev/null
	exit 1
}
trap ctrl_c INT

## Validar que nc y arp-scan estan instalados

instalar_nc(){
	clear
	if ! command -v nc >/dev/null ; then
		echo "'nc' no está instalado."
		read -p "Deseas instalarlo?, si/no:   " instalacion
		if [[ $instalacion == si ]]; then
			if command -v apt ; then
				echo "Instalando 'nc', espere un momento"
				if	apt update >/dev/null; then
					if ! apt install nc -y >/dev/null; then
						echo "error durante la Instalación"
						exit 1
					fi
				echo "Instalado Correctamente"
				else 
					echo -e "Se produjo un error durante la instalación\nverifica que estas conectado a internet" 
				fi
			elif command -v pacman; then
				echo -e "Instalando 'nc', espera un momento\n"
				if pacman -Sy >/dev/null; then
					if ! pacman -S gnu-netcat --noconfirm >/dev/null; then
						echo "Error durante la instalación"
						exit 1
					fi
					echo "Instalado correctamente"
				else
					echo -e "Error durante la instalación\nVerifica que estes conectado a internet"
				fi
			fi
			
		elif [[ $instalacion == "no" || $instalacion == n ]]; then
			echo "'nc' no se instaló el script no se puede ejecutar."
			exit 1
		elif [[ $instalacion != "s"|| $instalacion != "si"|| $instalacion != "n"|| $instalacion != "no" ]]; then
				echo "Opción no válida"
				instalar_nc
		else
			echo "'nc' ya está instalado"
		fi
	fi
}

instalar_arp(){
	clear
	if ! command -v arp-scan >/dev/null ; then
		echo "'arp-scan' no está instalado."
		read -p "Deseas instalarlo?, si/no:		" instalacion
		if [[ $instalacion == si|| $instalacion == "s" ]]; then
			if command -v apt ; then
				echo "Instalando 'arp-scan', espere un momento"
				if	apt update >/dev/null; then
					if ! apt install arp-scan -y >/dev/null; then
						echo "error durante la Instalación"
						exit 1
					fi
				echo "Instalado Correctamente"
				else 
					echo -e "Se produjo un error durante la instalación\nverifica que estas conectado a internet" 
				fi
			elif command -v pacman; then
				echo -e "Instalando 'arp-scan', espera un momento\n"
				if pacman -Sy >/dev/null; then
					if ! pacman -S arp-scan --noconfirm >/dev/null; then
						echo "Error durante la instalación"
						exit 1
					fi
					echo "Instalado correctamente"
				else
					echo -e "Error durante la instalación\nVerifica que estes conectado a internet"
				fi
			fi
		elif [[ $instalacion == "no" || $instalacion == n ]]; then
				echo "'nc' no se instaló el script no se puede ejecutar."
				exit 1
		elif [[ $instalacion != "s"|| $instalacion != "si"|| $instalacion != "n"|| $instalacion != "no" ]]; then
				echo "Opción no válida"
				instalar_arp
		else
			echo "Arp-scan ya está instalado"
		fi
	fi
}

verificar(){
echo -e "====Verificando Dependencias=======\nPor favor espere..."
instalar_nc
instalar_arp
echo "Dependencias Verificadas Correctamente"
sleep 2
}

verificar
# Verificar si se esta ejecutando como root

if [[ $UID -ne 0 ]]; then
	echo -e "\nEjecuta como root\n"
	ctrl_c
fi

# Limite de hilos
limite_hilos() {
    while (( $(jobs -r | wc -l) >= $hilos  )); do
        sleep 0.1
    done
}

tmp(){
	echo -e "=======IP=======	 ==========MAC========	 	 ========Dispositivo======"
	cat scan.tmp | awk '{ printf " %-24s %-30s %s\n", $1 , $2, $3 }'| tail -n +3 | head -n -2
}

ip_scan(){
	read -p "Deseas ver como funciona el escaneo ICMP( ping )? escribe 'si':    " respuesta
	if [[ $respuesta == "s" || $respuesta == "si" ]]; then
		cat ./.info/ping.txt | less
	fi
	clear
	echo -n "=================Escaneando Dispositivos en tu Red========================="
	for ip in $direccion; do
		timeout 1 ping -c 1 $ip >/dev/null 2>&1 && echo -e "\nEsta Ip esta en tu red :  $ip" &
	limite_hilos
	done; wait
	echo -e "\nEscaner Terminado\n"
}

# Funcion del menu de opciones
menu(){
	echo -e "\n==============Menu===============\n"
	echo -e "\n 1) Escaneo TCP\n"
	echo -e "\n 2) Escaneo UDP		( No recomendable ya que no recibirás respuesta, **Leer sobre protocolos**)\n"
	echo -e "\n 3) Salir\n"
}

# Escaneo TCP
tcp(){
	echo  -e "\n===========Escaneando===========\n"
	for puerto in $(seq 1 65535); do
		(timeout 1 echo "" > /dev/tcp/$ip_victima/$puerto)>/dev/null 2>&1 && echo "El puerto $puerto esá abierto" &
		limite_hilos
	done;wait
	echo "Terminado"
}

# Escaneo UDP
udp(){
	read -p "Escribe la Ip Victima: " ip_victima
	echo  -e "\n===========Escaneando===========\n"
	for puerto in $(seq 1 65535); do
		(timeout 1 nc -uzv $ip_victima $puerto)>/dev/null 2>&1 && echo "El puerto $puerto esá abierto" &
		limite_hilos
	done;wait
	echo "Terminado"
}

arp_scan(){
	read -p "Deseas ver como funciona el escaneo ARP? Escribe 'si':    " respuesta
		if [[ $respuesta == "s" || $respuesta == "si" ]]; then
			cat ./.info/icmp.txt | less
		fi
	clear
	echo -e "\nEscaneando...\n"
	sudo arp-scan --interface=wlan0 --localnet >scan.tmp 2>&1
	tmp
	rm scan.tmp
	echo "Terminado"
}

lista_de_escaneos(){
		clear
		echo -e "\n"
		echo -e "=================Tipos de Escaneos y Protocolos=========================="
		ls ./.info/ | awk -F "." '{ print $1 }'
		echo ""
				read -p "Sobre que Protocolo o Escaneo deseas saber, escribe 'atras' para volver al menú anterior:	" protocolo
				echo ""
				if [[ $protocolo == "atras" ]];then
					seleccionar_escaneo
					
				elif [[ ! -f ./.info/$protocolo.txt ]]; then
					echo -e "\nNo se encuentra\n"
					sleep 2
					clear
					lista_de_escaneos 
				else
					cat "./.info/$protocolo.txt"| less
					lista_de_escaneos
				fi
}

seleccionar_escaneo(){
	clear
	banner
	echo -e "=====================Tipo de Escaneo a Red =================================\n"
	echo -e "Primer escaneo para verificar que dispositivos están conectados a la red\n\n"
	echo -e "1) ARP ( (Address Resolution Protocol scan )  ( Mas silecioso ) \n"
	echo -e "2) PING ( ICMP ) 	  			( Mas Ruidoso )\n"
	echo -e "3) Listar Protocolos y Escaneos\n"
	echo -e "4) Salir\n" 
	read -p "Qué tipo de escaneo deseas realizar:   " tipo_escaner
		case $tipo_escaner in
		1) arp_scan ;;
		2) ip_scan ;;
		3)  lista_de_escaneos;;
		4) ctrl_c;;
		*) echo -e "\nSelección no Valida\n"
			exit 1
		;;
		esac
}

seleccionar_escaneo

while true ;do
	menu
	read -p "Selecciona:   " seleccion
	if ! [[ $seleccion =~ ^[1-3]$ ]];then
		echo "Opcion no Válida"
		menu
	elif [[ $seleccion == 3 ]]; then
		ctrl_c
	fi
	
	read -p "Escribe la Ip Victima:   " ip_victima
	case $seleccion in
		1)	
		if ! timeout 0.5 ping -c 1 $ip_victima >/dev/null 2>&1 ; then
			echo -e "\nLa ip no es válida o no está en tu red\n"
			exit 1
		else
			read -p "Deseas ver como funciona el escaneo de puertos TCP)? escribe 'si':    " respuesta
			if [[ $respuesta == "s" || $respuesta == "si" ]]; then
				cat ./.info/tcp.txt | less
			fi
			tcp &
			pid=$!
			(sleep 30 && kill $pid 2>/dev/null )&
			wait
			echo "Escaneo Terminado"
			exit 0
		fi ;;
		
		2) 
			if ! timeout 0.5 ping -c 1 $ip_victima >/dev/null 2>&1 ; then
					echo -e "\nLa ip no es válida o no esta en tu red\n"
					exit 1
			else
				udp &
				pid=$!
				(sleep 30 && kill $pid 2>/dev/null )&
				wait
				echo "Escaneo Terminado"
				exit 0
			fi ;;
			
		3) ctrl_c  ;;
		*) echo "Seleccion no válida"
			exit 1
		;;
	esac
done


