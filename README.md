# rdvtitres alerter

Script permettant de savoir si un rendez-vous de titre d'identité est disponible à Paris.
Peut envoyer un message optionellement sur Telegram.

Ce script peut vous être utile si vous habitez à Paris et que vous avez besoin de renouveller votre carte d'identité/passeport.

## Utilisation

### Pré-requis

* Installez [html-xml-utils](https://www.w3.org/Tools/HTML-XML-utils/), normalement disponible dans votre package manager (aur, debian, …).
* Crééz un compte sur [https://moncompte.paris.fr/](https://moncompte.paris.fr/)
* Téléchargez ce [script](https://github.com/Aerion/rdvtitres-alerter/raw/main/alerter.sh)/clone du repo et rendez-le exécutable `chmod +x alerter.sh`

### Lancement

PARIS_USERNAME et PARIS_PASSWORD sont nécessaires pour lancer le script.

```sh
$ PARIS_USERNAME="<email>" PARIS_PASSWORD="<password>" ./alerter.sh
debug: No login form detected, cookies from last time are still active
No appointments
```

On peut aussi être alerté par un message Telegram lorsqu'il y a une nouvelle disponibilité

```sh
# Avec envoi message TELEGRAM
$ TELEGRAM_CHAT_ID="<telegram chat id>" TELEGRAM_BOT_TOKEN="<telegram bot token>" PARIS_USERNAME="<email>" PARIS_PASSWORD="<password>" ./alerter.sh
```

Mon utilisation dans un cron, toutes les 20 mins, avec le log dans `/tmp/alerter.log`
```sh
$ crontab -l
*/20 * * * * TELEGRAM_BOT_TOKEN="foo" TELEGRAM_CHAT_ID="bar" PARIS_USERNAME="baz" PARIS_PASSWORD="bla" /home/aerion/projets/rdvtitres-alerter/alerter.sh >> /tmp/alerter.log 2>&1
$ cat /tmp/alerter.log
2023-05-07 14:47:27.954884541+02:00: No login form detected, cookies from last time are still active
2023-05-07 14:47:28.115901926+02:00: No appointments
```

### Autre

* Un code de retour `O` indique lorsqu'un rdv est disponible
* Un code de retour entre `1` et `10` indique qu'il n'y a pas de rdv de disponible
* Un code de retour supérieur à `10` indique un cas d'erreur inattendu
* Deux fichiers sont créés dans le même dossier
  * `cookies.txt` : gardant le contenu des cookies
  * `old_md5sum` : gardant un état des disponibilités, pour éviter de notifier quand ce sont les mêmes rendez-vous

## Contexte

*
https://www.lemonde.fr/m-le-mag/article/2023/05/06/les-conquistadors-du-passeport-j-ai-demande-a-un-stagiaire-de-se-connecter-toutes-les-heures-sur-le-site-jusqu-a-ce-qu-un-rendez-vous-se-libere_6172322_4500055.html
* https://www.leparisien.fr/paris-75/a-paris-lembouteillage-au-guichet-des-passeports-et-cartes-didentite-ne-faiblit-toujours-pas-22-07-2022-YWEQB5DL5BA4NKCLZ63JZQTQJM.php
* https://www.lefigaro.fr/voyages/conseils/obtenir-un-passeport-pour-cet-ete-est-ce-encore-possible-on-a-fait-le-test-a-paris-lyon-et-marseille-20230404
