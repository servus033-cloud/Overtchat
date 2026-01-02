# ===============================
# IriX - IRC JSON Service
# ===============================

set IRIX_ROOT "$HOME/Service-Overtchat/IriX"
set IRIX_DATA "$IRIX_ROOT/data"
set IRIX_USERS "$IRIX_DATA/users"
set IRIX_CFG "$IRIX_ROOT/config"
set IRIX_LOG "$IRIX_ROOT/logs"

# Création dossiers
foreach dir [list $IRIX_ROOT $IRIX_DATA $IRIX_USERS $IRIX_CFG $IRIX_LOG "$IRIX_ROOT/tmp"] {
    if {![file exists $dir]} {
        file mkdir $dir
    }
}

foreach f [list \
    "$IRIX_CFG/grades.json" \
    "$IRIX_CFG/cmds.json" \
    ] {
        if {![file exists $f]} {
            putlog "IriX FATAL: fichier manquant: $f"
        die "IriX: configuration incomplète"
    }
    if {[catch {exec jq empty $f}]} {
        putlog "IriX FATAL: JSON invalide: $f"
        die "IriX: JSON invalide"
    }
}

# ===============================
# Utils
# ===============================

proc irix_exec {cmd} {
    return [exec sh -c $cmd]
}

proc irix_time {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z"]
}

proc irix_log {msg} {
    set f [open "$::IRIX_LOG/irix.log" a]
    puts $f "[irix_time] $msg"
    close $f
}

# ===============================
# JSON helpers
# ===============================

proc grade_access {grade} {
    set cmd "jq -r '.\"$grade\".access // empty' $::IRIX_CFG/grades.json"
    return [irix_exec $cmd]
}

proc cmd_access {cmdname} {
    set cmd "jq -r '.cmds[] | select(.cmd==\"$cmdname\") | .access' $::IRIX_CFG/cmds.json"
    return [irix_exec $cmd]
}

# ===============================
# User helpers
# ===============================

proc user_file {user} {
    return "$::IRIX_USERS/$user.json"
}

proc user_exists {user} {
    return [file exists [user_file $user]]
}

# ===============================
# IRC command handler
# ===============================

bind msg - "IriX" irix_msg

proc irix_msg {nick host hand text} {
    set args [split $text]
    set cmd [string tolower [lindex $args 0]]

    switch -- $cmd {
        "add"     { irix_add $nick $args }
        "auth"    { irix_auth $nick $args }
        "deauth"  { irix_deauth $nick }
        "status"  { irix_status $nick }
        "help"    { irix_help $nick }
        default {
            putserv "NOTICE $nick :Commande inconnue. /msg IriX help"
        }
    }
}

# ===============================
# Commands
# ===============================

proc irix_add {nick args} {
    if {[llength $args] < 4} {
        putserv "NOTICE $nick :Usage: add <user> <grade> <password>"
        return
    }

    set user [lindex $args 1]
    set grade [lindex $args 2]
    set pass  [lindex $args 3]

    set access [grade_access $grade]
    if {$access eq ""} {
        putserv "NOTICE $nick :Grade invalide."
        return
    }

    if {[user_exists $user]} {
        putserv "NOTICE $nick :Utilisateur déjà existant."
        return
    }

    set hash [irix_exec "printf \"%s\" \"$pass\" | sha256sum | cut -d' ' -f1"]

    set json "{
        \"user\": \"$user\",
        \"grade\": \"$grade\",
        \"access\": $access,
        \"registered\": true,
        \"created_at\": \"[irix_time]\",
        \"auth\": {
            \"hash\": \"$hash\",
            \"logged\": false
        }
        }"

        set f [open [user_file $user] w]
        puts $f $json
        close $f

        putserv "NOTICE $nick :Utilisateur $user créé (grade $grade)."
        irix_log "ADD user=$user by=$nick"
    }

    proc irix_auth {nick args} {
        if {[llength $args] < 3} {
            putserv "NOTICE $nick :Usage: auth <user> <password>"
            return
        }

        set user [lindex $args 1]
        set pass [lindex $args 2]

        if {![user_exists $user]} {
            putserv "NOTICE $nick :Utilisateur inconnu."
            return
        }

        set hash [irix_exec "printf \"%s\" \"$pass\" | sha256sum | cut -d' ' -f1"]
        set stored [irix_exec "jq -r '.auth.hash' [user_file $user]"]

        if {$hash ne $stored} {
            putserv "NOTICE $nick :Mot de passe invalide."
            return
        }

        irix_exec "jq '.auth.logged=true' [user_file $user] > /tmp/u && mv /tmp/u [user_file $user]"
        putserv "NOTICE $nick :Authentification réussie."
    }

    proc irix_deauth {nick} {
        foreach f [glob -nocomplain "$::IRIX_USERS/*.json"] {
            irix_exec "jq '.auth.logged=false' $f > /tmp/u && mv /tmp/u $f"
        }
        putserv "NOTICE $nick :Dé-authentification effectuée."
    }

    proc irix_status {nick} {
        set count [llength [glob -nocomplain "$::IRIX_USERS/*.json"]]
        putserv "NOTICE $nick :IriX actif | Utilisateurs: $count"
    }

    proc irix_help {nick} {
        set cmds [irix_exec "jq -r '.cmds[] | \"- \(.cmd): \(.desc)\"' $::IRIX_CFG/cmds.json"]
        foreach line [split $cmds "\n"] {
            putserv "NOTICE $nick :$line"
        }
    }

    # ===============================
    # Fin IriX
    # ===============================