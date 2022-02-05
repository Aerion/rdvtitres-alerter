#!/bin/bash
MAIN_URL="https://teleservices.paris.fr/rdvtitres/jsp/site/Portal.jsp?page=appointmenttitresearch"
LOGIN_URL="https://moncompte.paris.fr/"
ZIP_CODE="75001"

if [ -z "$ARRONDISSEMENTS" ]; then
    ARRONDISSEMENTS=".."
fi

if [ -z "$PARIS_USERNAME" ] || [ -z "$PARIS_PASSWORD" ]; then
    echo "PARIS_USERNAME and PARIS_PASSWORD environment variables must be set"
    exit 77
fi

function debug {
    echo "$(date --rfc-3339=ns)"": $1" >&2
}

function login {
    body=$(curl -s -L --referer ";auto" --cookie-jar cookies.txt --cookie cookies.txt "$LOGIN_URL" | hxnormalize -x)
    login_form=$(echo "$body" | hxselect '#form-login')

    if [ -n "$login_form" ]; then
        debug "Login form detected"

        login_post_url=$(echo "$login_form" | hxselect -c '#form-login::attr(action)' | hxunent)
        curl -o /dev/null -s -L --referer ";auto" --cookie-jar cookies.txt --cookie cookies.txt --data-urlencode "username=$PARIS_USERNAME" --data-urlencode "password=$PARIS_PASSWORD" --data-urlencode "Submit=" "$login_post_url"
    else
        logout_icon=$(echo "$body" | hxselect '.mcp-icon-deconnexion')
        if [ -n "$logout_icon" ]; then
            debug "No login form detected, but no logout either. Issue with the script?"
            exit 99
        fi

        debug "No login form detected, cookies from last time are still active"
    fi
}

login

appointments_body=$(curl -s -L --referer ";auto" --cookie-jar cookies.txt --cookie cookies.txt --data "page=appointmenttitresearch&nb_consecutive_slots=1&zip_code=$ZIP_CODE&action_presearch=" "$MAIN_URL" |
    hxnormalize -x)
appointments=$(echo "$appointments_body" | hxselect 'div.nextAvailableAppointments')
if [ "$appointments" = '' ]; then
    if [[ $appointments_body =~ "rendez-vous n'est actuellement disponible" ]]; then
        debug 'No appointments'
        exit 1
    else
        debug 'No appointments detected but neither is the empty message. Issue with the script?'
        exit 99
    fi
fi

matches=$(echo "$appointments" | grep -Eo "750($ARRONDISSEMENTS) PARIS")
echo "$matches"

if [ "$matches" = '' ]; then
    debug "Not available in selected quartiers"
    exit 2
fi

dates=$(echo "$appointments" | hxselect -s '\n' -c "a::attr(title)")
text=$(echo -e "Availabilities in $matches\n$dates\n$MAIN_URL")

touch old_md5sum
hash=$(echo "$text" | md5sum)
previous_hash=$(cat old_md5sum)

echo -n "$hash" >old_md5sum

if [ "$hash" = "$previous_hash" ]; then
    debug "Same hash, no changes"
    exit 3
fi

echo "$text"

if [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -X POST -F "chat_id=$TELEGRAM_CHAT_ID" -F "disable_web_page_preview=true" -F "text=$text" "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
fi
