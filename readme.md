
`RACK_ENV={production|test|dev}`

# User vorbereiten

user anlegen
```
sudo adduser robert --ingroup sudo
```
Dann als robert einloggen.

# Für lokale Maschine

SSH-Login via Keypair einrichten, Passwort-Login via SSH deaktivieren.

# Pakete installieren
```
# notwendige binaries
sudo apt-get install git nano unrtf postgresql postgresql-client postgresql-contrib netpbm ghostscript potrace tesseract-ocr
# notwendig zum Kompilieren der Ruby native extensions
sudo apt-get install libpq-dev ruby-dev build-essentials zlibc zlib1g zlib1g-dev
# Packages für headless Chrome
sudo apt-get install libgbm1 libxcb-dri3-0
```

# Proxy mit Apache
So kann Puma ohne Sudo laufen / ist nicht direkt offenbart.

```
sudo apt-get install apache2
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod ssl
sudo a2enmod headers
```

Verzeichnis vorbereiten (ist durch das Rakefile vorgegeben)
```
sudo mkdir /var/www/frontend
sudo chown www-data:www-data /var/www/frontend
sudo chmod -R 770 /var/www
TODO Befugnisse setzen für Ausführenden des Stage Scripts
```

In `/etc/apache2/sites-available/000-default.conf`:
```
<VirtualHost *:80>
        # ServerName h2875324.stratoserver.net
        ServerAdmin robert@tacpic.de
        DocumentRoot "/var/www/frontend"

        # Rewrite rules setzen, damit HTML5 history / client-seitiger Router richtig arbeiten kann.
        <Directory /var/www/frontend>
                RewriteEngine On
                RewriteBase /
                RewriteRule ^index\.html$ - [L]
                RewriteCond %{REQUEST_FILENAME} !-f
                RewriteCond %{REQUEST_FILENAME} !-d
                RewriteCond %{REQUEST_FILENAME} !-l
                RewriteRule . /index.html [L]
        </Directory>

        <Location /api>
                ProxyPass http://127.0.0.1:9292
                ProxyPassReverse http://127.0.0.1:9292
        </Location>

        ErrorLog ${APACHE_LOG_DIR}/error.log
</VirtualHost>

```
Dann `sudo service apache2 restart`

## SSL einrichten
siehe https://certbot.eff.org/lets-encrypt/ubuntubionic-apache

# Node installieren
[Aktuelle Hinweise](https://github.com/nodesource/distributions/blob/master/README.md)

```
curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
sudo apt-get install -y nodejs
```

# RVM installieren
```
curl -sSL https://get.rvm.io | sudo bash -s stable # wird fehlschlagen
sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys HIER_DEN_HASH_AUS_DER_MELDUNG_VON_OBEN_EINTRAGEN
curl -sSL https://get.rvm.io | sudo bash -s stable # wird gelingen
sudo usermod -a -G rvm robert ; oder sudo usermod -a -G rvm `whoami`

rvm install ruby-x.y.z
```
Anleitung für sudo befolgen: https://rvm.io/integration/sudo

# Git-Workflow einrichten

## [SSH auf Server einrichten](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)

## Repositorys klonen
```
git clone git@github.com:McMalloc/tacpic_backend.git
git clone git@github.com:McMalloc/tacpic.git

cd ~/tacpic
cp src/env.json.template src/env.json
# API_URL entsprechend der Apache/IP Configuration anpassen
npm install

cd ~/tacpic_backend
gem install bundler
bundle install
npm install # install svgexport/puppeteer for PNG rendering
```
# Backend einrichten

Kopie der Umgebungsdatei anlegen:
```
mv env.rb.template env.rb
```
Und Login-URLs eintragen: postgres://tacpic:password@localhost/tacpic-production

Dateiverzeichnisse anlegen:
```
mkdir tacpic_backend/files
mkdir tacpic_backend/files/vouchers
mkdir tacpic_backend/files/invoices
mkdir tacpic_backend/files/shipment_receipts
mkdir tacpic_backend/files/temp
```
## Datenbank einrichten

```
sudo service postgresql restart
sudo -u postgres psql
postgres=# create database "tacpic-production";
postgres=# create user tacpic with encrypted password 'password';
postgres=# grant all privileges on DATABASE "tacpic-production" to tacpic;
\q

rake db:migrate RACK_ENV=production
```

## Anwendungsserver starten

```
rake run:main RACK_ENV=production
```
Damit er im Hintergrund ohne Terminierung durch `exit` weiterläuft: 
```
tmux new -s app # wenn es noch nicht läuft bzw.
tmux a -t app
rake run:main RACK_ENV=production &
# ctrl+b, d detached von der Session
```