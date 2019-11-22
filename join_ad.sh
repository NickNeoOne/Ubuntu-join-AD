#!/bin/bash
echo ""
echo "====================="
echo "ВНИМАНИЕ! Убедитесь что вы задали правильные параметры переменных в скрипте"
echo "А также убедитесь что имя компьютера является уникальным!"
echo "====================="
echo ""

# Переменные для ввода в домен

# hostname контроллера домена
DC="dc.demo.ru"

#Имя домена
DOMAIN="DEMO.RU"

#Имя пользователя с правами админа в домене
DOMAIN_ADMIN="ad_user"




echo ""
#read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo

echo "Вы хотите продолжить?"
PS3="Выберите Y для продолжения, или N для выхода: "

select number in Y N;
do
    case $REPLY in
    "N")
        echo "Exiting."
        exit
        ;;
    "Y")
        break
        ;;
    esac
done
# continue

echo ""
echo "====================="
echo "Установите hostname. Должен быть уникальный!"
echo "====================="
echo ""

read HOSTNAME

if [ "$HOSTNAME" = "" ]; then
    # $STRING is empty
echo "hostname. не может быть пустой!"
read -sn1 -p "нажмите любую клавишу для для выхода."; echo
    exit
fi


echo ""
echo "====================="
echo "Вы установили имя компьютера:"
echo $HOSTNAME
echo ""

read -sn1 -p "Убедитесь в правильности имени и нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo

hostnamectl set-hostname $HOSTNAME

echo ""
echo "====================="
echo "Устанавливаем пакеты"
echo "====================="
echo ""
apt install sssd heimdal-clients msktutil realmd packagekit adcli

echo ""
read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo

echo ""
echo "====================="
echo "проверяем доступность контроллера"
echo "====================="
echo ""
nslookup $DC
ping -c 3 $DC

echo ""
read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo
echo ""
echo "====================="
echo "пробуем найти доступные домены"
echo "====================="
echo ""
realm discover $DOMAIN

echo ""
read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo
echo ""
echo "====================="
echo "Вводим в домен"
echo "====================="
echo ""
realm join -U $DOMAIN_ADMIN $DC

echo ""
read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo
echo ""
echo "====================="
echo "Изменяем параметр use_fully_qualified_names для возможности ввода имени пользователя без указания домена"
echo "====================="
echo ""
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf_orig
#sed -i 's/.use_fully_qualified_names = True./use_fully_qualified_names = False/' /etc/sssd/sssd.conf
sed -i 's/.*use_fully_qualified_names.*/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep use_fully_qualified_names

echo ""
echo "====================="
echo "Задаем путь домашней директории пользователя"
echo "====================="
echo ""
sed -i 's/.*fallback_homedir.*/fallback_homedir = \/home\/%u/' /etc/sssd/sssd.conf
cat /etc/sssd/sssd.conf | grep fallback_homedir
#echo "fallback_homedir = /home/%u" >> /etc/sssd/sssd.conf

echo ""
echo "====================="
echo "включаем и перезапускаем сервис"
echo "====================="
echo ""
systemctl enable sssd.service
systemctl restart sssd.service

echo ""
read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo
echo ""
echo "====================="
echo "запускаем pam-auth-update и отметчаем там все галочки для того чтобы при первом логине создавалась домашняя директория"
echo "====================="
echo ""
pam-auth-update

echo ""
echo "====================="
echo "получаем информацию о домене запускаем"
echo "====================="
echo ""
realm list

echo ""
echo ""

adcli info $DOMAIN

echo ""
read -sn1 -p "Нажмите любую клавишу для продолжения... или комбинацию Ctrl+C для отмены."; echo
echo ""
echo "====================="
echo "Добавляем пользователей с админскими правами в sudoers"
echo "====================="
echo ""
echo "%Domain\ Admins ALL=(ALL) ALL" >> /etc/sudoers

echo ""
echo "====================="
echo "Устанавливаем SSH (Выберите нужный вариант)"
echo "====================="
echo ""
#apt install openssh-server
echo "Вы хотите установить openssh-server?"
PS3="Выберите Y для продолжения, или N для выхода: "

select number in Y N;
do
    case $REPLY in
    "N")
        echo "Exiting."
        exit
        ;;
    "Y")
    apt install openssh-server
    break
        ;;
    esac
done

echo ""
read -sn1 -p "Если в процессе не возникло никаких ошибок можно перезагрузить компьютер и авторизоваться доменной учетной записью,
если возникли ошибки исправьте их и повторите процедуру."; echo
