#!/bin/bash
remote_ip="103.130.218.221"
user="admin"
pass_da="Tinhvatien!1"
rootuser=$(pwd)

dns_name_da() {
DIR=/var/named
IP=$my_ip

cat $rootuser/log_tranfer/listdomainoke >> /etc/virtual/domains

for domain in `cat /etc/virtual/domains`; do
{
FILE=$DIR/${domain}.db

echo "Creating DB file for ${domain} in ${FILE}";

echo "\$TTL 3600" > $FILE;
echo "@ IN SOA ns1.${domain}. root.${domain}. (" >> $FILE;
echo " 2007051103" >> $FILE;
echo " 3600" >> $FILE;
echo " 3600" >> $FILE;
echo " 1209600" >> $FILE;
echo " 1209600" >> $FILE;
echo " 86400 )" >> $FILE;
echo "${domain}. 3600 IN NS ns1.${domain}." >> $FILE;
echo "${domain}. 3600 IN NS ns2.${domain}." >> $FILE;
echo "${domain}. 3600 IN A $IP" >> $FILE;
echo "ftp 3600 IN A $IP" >> $FILE;
echo "* 3600 IN A $IP" >> $FILE;
echo "www 3600 IN A $IP" >> $FILE;
echo "mail 3600 IN A $IP" >> $FILE;
echo "${domain}. 3600 IN MX 10 mail.${domain}." >> $FILE;


echo "zone "${domain}" { type master; file "/var/named/${domain}.db"; };"  >> /etc/named.conf

};
done;


}


gen_passs() {
    MATRIX='0123456789abcdefghijklmnopqrstuvwxyz'
    LENGTH=6
    while [ ${n:=1} -le $LENGTH ]; do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$PASS"
}
gen_pass() {
    MATRIX='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    LENGTH=10
    while [ ${n:=1} -le $LENGTH ]; do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$PASS"
}
tao_database() {

uapi --user=$user Mysql create_database name=$WPDBNAME1 &> /dev/null
uapi --user=$user Mysql create_user name=$WPDBUSER1 password=$WPDBPASS1 &> /dev/null
uapi --user=$user Mysql set_privileges_on_database user=$WPDBUSER1 database=$WPDBNAME1 privileges=ALL%20PRIVILEGES &> /dev/null

}

tao_database_da() {

    cat > "/tmp/config.temp" <<END
CREATE DATABASE $WPDBNAME1 COLLATE utf8_general_ci;
CREATE USER '$WPDBUSER1'@'localhost' IDENTIFIED BY '$WPDBPASS1';
GRANT ALL PRIVILEGES ON $WPDBNAME1 . * TO '$WPDBUSER1'@'localhost';
FLUSH PRIVILEGES;
END

mysql < /tmp/config.temp
rm -f /tmp/config.temp

}

chuyendata_DA_usercpanel() {


############################################
mkdir $rootuser/log_tranfer/
echo "Dang tien hanh restore cac website..." > $rootuser/log_tranfer/tranferstatus
rsync -avze ssh  root@$remote_ip:/tmp/listdomain $rootuser/log_tranfer &> /dev/null
rsync -avze ssh  root@$remote_ip:/tmp/listdomainoke $rootuser/log_tranfer &> /dev/null
rsync -avze ssh  root@$remote_ip:/tmp/listdomainfail $rootuser/log_tranfer &> /dev/null

cd $rootuser
sleep 5
echo "tien hanh restore website"

echo "tai database"
mkdir $rootuser/data_mysql

rsync -avze ssh  root@$remote_ip:/tmp/mysql_backups/ $rootuser/data_mysql &> /dev/null
echo "done"

cd $rootuser/data_mysql
yes|gunzip *.gz &> /dev/null

if [ ! -f  $rootuser/not_tranfer ]; then
touch $rootuser/not_tranfer
fi
###########################################

while read domain; do

check_valid=$(cat $rootuser/not_tranfer | grep $domain) &> /dev/null

if [[ $check_valid != "" ]] ; then
echo "Khong chuyen du lieu website $domain";
exit
fi

domain_dir=$(cat $rootuser/log_tranfer/listdomain | grep "/$domain/" | awk '{print $3}')


echo "Dang tien hanh restore website $domain tai $domain_dir..." >> $rootuser/log_tranfer/tranferstatus

echo "Bat dau rsyn domain $domain:"

mkdir $rootuser/$domain

rsync -aze ssh root@${remote_ip}:${domain_dir}/ $rootuser/$domain/

echo "rsyn domain $domain hoan tat, dang tien hanh kiem tra va cau hinh config"

###xu ly database



if [ -f $rootuser/$domain/wp-config.php ]; then ## domain them vao la wordpress

WPDBNAME=`cat $rootuser/$domain/wp-config.php | grep DB_NAME | cut -d \' -f 4`


if [ -f $rootuser/data_mysql/$WPDBNAME.sql ]; then

WPDBPASS1=${user}_$(gen_pass)
WPDBUSER1=${user}_$(gen_passs)
WPDBNAME1=${user}_$(gen_passs)

tao_database


mysql $WPDBNAME1 < $rootuser/data_mysql/$WPDBNAME.sql
rm -rf $rootuser/data_mysql/$WPDBNAME.sql

cd $rootuser/$domain

wp config set DB_NAME $WPDBNAME1 --allow-root
wp config set DB_USER $WPDBUSER1 --allow-root
wp config set DB_PASSWORD $WPDBPASS1 --allow-root

echo "website $domain them hoan tat, folder:$rootuser/$domain/ , Thong tin database: dataname: $WPDBNAME1, user: $WPDBUSER1, Passworduser: $WPDBPASS1 " >> $rootuser/log_tranfer/wp-done 

else
echo "$domain" >> $rootuser/log_tranfer/wp_nodata
echo "site $domain tien hanh import va cau hinh data oke" >> $rootuser/log_tranfer/tranferstatus
fi
else
echo "$domain" >> $rootuser/log_tranfer/not-wp
fi

echo "$domain" >> $rootuser/log_tranfer/tranferdone
echo "site $domain tien hanh restore hoan tat" >> $rootuser/log_tranfer/tranferstatus
done < $rootuser/log_tranfer/listdomainoke


echo "phan quyen lai tat ca website:"
chown -R $user:$user $rootuser/

}

chuyendata_DA_DA() {
    
PASSWORD=$(grep mysql= /usr/local/directadmin/scripts/setup.txt | cut -d'=' -f2)    

my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
check_login_da=$(curl -ss --request GET "http://admin:${pass_da}@localhost:2222/CMD_API_SHOW_RESELLER_IPS" | grep $my_ip)

if [[ $check_login_da = "" ]] ; then
echo "Password dang nhap DA sai, vui long cap nhat lai.";
exit
else

################################
mkdir $rootuser/log_tranfer/
echo "Dang tien hanh restore cac website..." > $rootuser/log_tranfer/tranferstatus
rsync -avze ssh  root@$remote_ip:/tmp/listdomain $rootuser/log_tranfer &> /dev/null
rsync -avze ssh  root@$remote_ip:/tmp/listdomainoke $rootuser/log_tranfer &> /dev/null
rsync -avze ssh  root@$remote_ip:/tmp/listdomainfail $rootuser/log_tranfer &> /dev/null

cd $rootuser
sleep 5
echo "tien hanh restore website"

echo "tai database"
mkdir $rootuser/data_mysql

rsync -avze ssh  root@$remote_ip:/tmp/mysql_backups/ $rootuser/data_mysql &> /dev/null
echo "done"

cd $rootuser/data_mysql
yes|gunzip *.gz &> /dev/null

if [ ! -f  $rootuser/not_tranfer ]; then
touch $rootuser/not_tranfer
fi
################################


yum update -y  &> /dev/null

curl -ss -O --insecure https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  &> /dev/null
chmod +x wp-cli.phar  &> /dev/null
yes | mv wp-cli.phar /usr/local/bin/wp &> /dev/null
echo "bat dau ...." &> /dev/null


while read domain; do

check_valid=$(cat $rootuser/not_tranfer | grep $domain) &> /dev/null

if [[ $check_valid != "" ]] ; then
echo "Khong chuyen du lieu website $domain";
exit
fi

domain_dir=$(cat $rootuser/log_tranfer/listdomain | grep "/$domain/" | awk '{print $3}')
#user=$(cat $rootuser/log_tranfer/listdomain | grep "/$domain/" | awk '{print $2}')
#user=$(gen_passs)

user1=${domain//./}
#def=${user1%.*}
user2=${user1:0:5}
randomuser=$(gen_passs)
user="$user2$randomuser"

randompass=$(gen_pass)

curl -ss --location --request GET "http://admin:${pass_da}@127.0.0.1:2222/CMD_API_ACCOUNT_USER?action=create&add=Submit&username=${user}&email=admin@${domain}&passwd=${randompass}&passwd2=${randompass}&domain=${domain}&notify=no&ip=${my_ip}&cgi=ON&php=ON&spam=ON&cron=ON&ssl=ON&sysinfo=ON&login_keys=ON&dnscontrol=ON&suspend_at_limit=ON" >>  $rootuser/log_tranfer/create_user_da
rm -rf /home/$user/domains/$domain/public_html/*

echo "$domain $user $randompass" >>  $rootuser/log_tranfer/list_create_account_da


echo "Dang tien hanh restore website $domain tai $domain_dir..." >> $rootuser/log_tranfer/tranferstatus

echo "Bat dau rsyn domain $domain:"


rsync -aze ssh root@${remote_ip}:${domain_dir}/ /home/$user/domains/$domain/public_html/

echo "rsyn domain $domain hoan tat, dang tien hanh kiem tra va cau hinh config"

###xu ly database



if [ -f /home/$user/domains/$domain/public_html/wp-config.php ]; then ## domain them vao la wordpress

WPDBNAME=`cat /home/$user/domains/$domain/public_html/wp-config.php | grep DB_NAME | cut -d \' -f 4`


if [ -f $rootuser/data_mysql/$WPDBNAME.sql ]; then

databasemoi=$(gen_passs)
WPDBPASS1=${user}_$(gen_pass)


WPDBUSER1=${user}_${databasemoi}
WPDBNAME1=${user}_${databasemoi}

#tao_database_da

curl -ss --location -g --request GET "http://${user}:${randompass}@localhost:2222/CMD_API_DATABASES?action=create&name=${databasemoi}&user=${databasemoi}&passwd=${WPDBPASS1}&passwd2=${WPDBPASS1}"



mysql -uroot -p${PASSWORD} $WPDBNAME1 < $rootuser/data_mysql/$WPDBNAME.sql

rm -rf $rootuser/data_mysql/$WPDBNAME.sql

cd /home/$user/domains/$domain/public_html/

wp config set DB_NAME $WPDBNAME1 --allow-root
wp config set DB_USER $WPDBUSER1 --allow-root
wp config set DB_PASSWORD $WPDBPASS1 --allow-root

echo "website $domain them hoan tat, folder:/home/$user/domains/$domain/public_html/ , Thong tin database: dataname: $WPDBNAME1, user: $WPDBUSER1, Passworduser: $WPDBPASS1 " >> $rootuser/log_tranfer/wp-done 

else
echo "$domain" >> $rootuser/log_tranfer/wp_nodata
echo "site $domain tien hanh import va cau hinh data oke" >> $rootuser/log_tranfer/tranferstatus
fi
else
echo "$domain" >> $rootuser/log_tranfer/not-wp
fi

echo "$domain" >> $rootuser/log_tranfer/tranferdone
echo "site $domain tien hanh restore hoan tat" >> $rootuser/log_tranfer/tranferstatus

echo "phan quyen lai tat ca website:"
chown -R $user:$user /home/$user/domains/$domain/public_html/


#echo "$domain: $user" >> /etc/virtual/domainowners
echo "$domain: $user $randompass" >> $rootuser/log_tranfer/listaccount


done < $rootuser/log_tranfer/listdomainoke

cd /usr/local/directadmin/scripts
./set_permissions.sh all &> /dev/null


webserver=$(grep webserver= /usr/local/directadmin/custombuild/options.conf | cut -d'=' -f2)
cd /usr/local/directadmin/custombuild/
./build $webserver &> /dev/null
./build rewrite_confs &> /dev/null

#dns_name_da &> /dev/null
     

echo "action=rewrite&value=ipcount" >> /usr/local/directadmin/data/task.queue &> /dev/null
echo "action=rewrite&value=domainips" >> /usr/local/directadmin/data/task.queue &> /dev/null
echo "action=rewrite&value=helo_data" >> /usr/local/directadmin/data/task.queue &> /dev/null
echo "action=tally&value=all" >> /usr/local/directadmin/data/task.queue; /usr/local/directadmin/dataskq &> /dev/null

fi


}




echo ""
echo "====================================================================================="
echo "Tranfer all data frome VPS DA"
echo "/-------------------------/"
echo "/-----------------------------------------------------------------------------------/"
echo ""

rm -rf  $rootuser/log_tranfer/tranferstatus



#echo -n "nhap IP VPS remote lay du lieu [ENTER]: "
#read remote_ip

#regex="^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1})|([a-zA-Z0-9][-_\.a-zA-Z0-9]{1,61}[a-zA-Z0-9]))\.([a-zA-Z]{2,13}|[a-zA-Z0-9-]{2,30}\.[a-zA-Z]{2$
#regex="^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"
regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"


if [[ $remote_ip =~ $regex ]] ; then
echo "IP VPS want to retrieve data: $remote_ip"
else
echo "Wrong IP  format, returning to main function."
exit
fi
if [ "$remote_ip" = "" ]; then
echo "The domain you entered is not in the correct format, please try again."
exit
fi

echo "Ban co the kiem tra trang thai hoan tat hay chua bang cach doc file tai: $rootuser/log_tranfer/tranferstatus"

sleep 5
yes | ssh-keygen -f ~/.ssh/id_rsa -P "" &> /dev/null

echo "bat dau thiet lap ket noi toi VPS cu..."
#echo "bat dau thiet lap ket noi toi VPS cu..." > /root/tranferstatus

echo "Vui long nhap mat khau de ket noi toi vps cu"

scp ~/.ssh/id_rsa.pub root@${remote_ip}:~/.ssh/authorized_keys


ssh root@${remote_ip}  <<'ENDSSH'

yum install rsync  -y  &> /dev/null

rm -r /tmp/error1 &> /dev/null
rm -r /tmp/listdomain &> /dev/null
rm -r /tmp/listdomainoke &> /dev/null
rm -rf /tmp/listdomainfail  &> /dev/null


for i in `ls /usr/local/directadmin/data/users`; do
{
 for d in `cat /usr/local/directadmin/data/users/${i}/domains.list`; do
 {
 # echo $d
 # echo $i
   echo "$d $i /home/$i/domains/$d/public_html" >> /tmp/listdomain
   if [ -d /home/$i/domains/$d/public_html ]; then
   echo "$d" >> /tmp/listdomainoke
   else
   echo "$d" >> /tmp/listdomainfail
   fi
 };
 done;
};
done



echo "bat dau tien hanh backup database:"
rm -rf /tmp/mysql_backups

OUTPUT=/tmp/mysql_backups
mkdir -p $OUTPUT
mkdir -p /tmp/mysql_backups

PASSWORD=$(grep mysql= /usr/local/directadmin/scripts/setup.txt | cut -d'=' -f2)

cat > /root/.my.cnf <<END
[client]
user=root
password=$PASSWORD
END


MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
databases=`$MYSQL -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|da_roundcube)"`
for db in $databases; do
        $MYSQLDUMP --force --opt $db | gzip > "${OUTPUT}/$db.sql.gz"
done

echo "backup database hoan tat";
echo '';
exit

ENDSSH


panel_directadmin="/usr/local/directadmin/"
panel_cpanel="/usr/local/cpanel/"


if [ -d $panel_cpanel ]; then
echo "Chuyen website tu VPS directadmin sang cpanel"
chuyendata_DA_usercpanel
fi

if [ -d $panel_directadmin ]; then
echo "Chuyen website tu VPS directadmin sang directadmin"
chuyendata_DA_DA
fi


echo "**************************************************"
echo "**************************************************"
echo "**************************************************"
echo "**************************************************"



if [ -f $rootuser/log_tranfer/wp-done ]; then
echo "Cac website la wordpress da khoi phuc:"
cat $rootuser/log_tranfer/wp-done 
fi
echo ""
echo "**********************"
if [ -f $rootuser/log_tranfer/not-wp ]; then
echo "Vui long truy cap va cau hinh hinh la cac domain khong phai la wordpress:"
cat $rootuser/log_tranfer/not-wp 
fi

echo ""
echo "**********************"
if [ -f $rootuser/log_tranfer/data_mysql-last ]; then
echo "Cac database da them vao VPS khong phai la wordpress, hoac khong duoc cau hinh voi bat ky domain nao:"
cat $rootuser/log_tranfer/data_mysql-last
fi	

echo ""
echo "**********************"
if [ -f $rootuser/log_tranfer/wp_nodata ]; then
echo "Cac Domain wordpress da them nhung khong tim thay database trong file cau hinh:"
cat $rootuser/wp_nodata &> /dev/null
fi

echo "cac domain khong chuyen du lieu qua:"
cat $rootuser/log_tranfer/listdomainfail
cat $rootuser/not_tranfer

echo "Move All Site, done !!..." >> $rootuser/log_tranfer/tranferstatus echo "tranfer done !!"
