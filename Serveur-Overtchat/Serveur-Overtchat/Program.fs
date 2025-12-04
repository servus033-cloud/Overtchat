open System
open System.Net
open System.Net.Sockets
open System.IO
open System.Collections.Concurrent
open System.Text
open System.Collections.Generic

// ----------------- Types -----------------
let motd =
    try
        System.IO.File.ReadAllLines("motd.dab")
    with _ ->
        [| "Bienvenue sur le serveur Service-Overtchat by SerVuS !" |]

type User =
    { Nick: string
      Ident: string
      Host: string }

let send (client: TcpClient) (msg: string) =
    let data = Encoding.UTF8.GetBytes(msg + "\r\n")
    client.GetStream().Write(data, 0, data.Length)

let handleJoin (client: TcpClient) (user: User) (channel: string) =
    // Confirmer le JOIN
    send client (sprintf ":%s!%s@%s JOIN :%s" user.Nick user.Ident user.Host channel)

    // Envoyer la liste des utilisateurs (ici juste lui-même)
    send client (sprintf ":server 353 %s = %s :%s" user.Nick channel user.Nick)
    send client (sprintf ":server 366 %s %s :End of /NAMES list" user.Nick channel)

let handlePrivmsg (clients: List<TcpClient>) (sender: User) (channel: string) (message: string) =
    for client in clients do
        // éviter de renvoyer au client qui a écrit
        if client.Connected then
            send client (sprintf ":%s!%s@%s PRIVMSG %s :%s" sender.Nick sender.Ident sender.Host channel message)

type UserState() =
    member val Nick = "Anonymous" with get, set
    member val Ident = "" with get, set
    member val RealName = "" with get, set
    member val Modes = "" with get, set
    member val CurrentChannels = Set.empty<string> with get, set
    member val Writer: StreamWriter option = None with get, set

type ChannelState(name: string) =
    member val Name = name with get, set
    member val Topic = "" with get, set
    member val Modes = "" with get, set
    member val Users = ConcurrentDictionary<string, UserState>() with get, set
    member val Operators = Set.empty<string> with get, set
    member val BanMasks = Set.empty<string> with get, set
    member val InviteMasks = Set.empty<string> with get, set
    member val QuietMasks = Set.empty<string> with get, set
    member val UserLimit = None with get, set
    member val ChannelKey = None with get, set
    member val IsInviteOnly = false with get, set
    member val IsModerated = false with get, set
    member val IsSecret = false with get, set
    member val IsPrivate = false with get, set
    member val IsTopicProtected = false with get, set
    member val NoExternalMessages = false with get, set
    member val HalfOperators = Set.empty<string> with get, set
    member val VoicedUsers = Set.empty<string> with get, set
    member val ChannelCreationTime = DateTime.UtcNow with get, set
    member val LastTopicSetTime = DateTime.UtcNow with get, set
    member val LastTopicSetBy = "" with get, set
    member val MessageHistory = ResizeArray<string>() with get, set

    member this.AddMessage(message: string) =
        this.MessageHistory.Add(message)

        if this.MessageHistory.Count > 100 then
            this.MessageHistory.RemoveAt(0)
        else
            ()

    member this.GetMessageHistory() = this.MessageHistory.ToArray()
    member val TopicHistory = ResizeArray<string>() with get, set

    member this.AddTopic(topic: string) =
        this.TopicHistory.Add(topic)

        if this.TopicHistory.Count > 50 then
            this.TopicHistory.RemoveAt(0)
        else
            ()

    member this.GetTopicHistory() = this.TopicHistory.ToArray()
    member val ChannelModesHistory = ResizeArray<string>() with get, set

    member this.AddChannelMode(mode: string) =
        this.ChannelModesHistory.Add(mode)

        if this.ChannelModesHistory.Count > 50 then
            this.ChannelModesHistory.RemoveAt(0)
        else
            ()

    member this.GetChannelModesHistory() = this.ChannelModesHistory.ToArray()
    member val UserModesHistory = ResizeArray<string>() with get, set

    member this.AddUserMode(mode: string) =
        this.UserModesHistory.Add(mode)

        if this.UserModesHistory.Count > 50 then
            this.UserModesHistory.RemoveAt(0)
        else
            ()

    member this.GetUserModesHistory() = this.UserModesHistory.ToArray()
    member val JoinLeaveHistory = ResizeArray<string>() with get, set

    member this.AddJoinLeave(ev: string) =
        this.JoinLeaveHistory.Add(ev)

        if this.JoinLeaveHistory.Count > 100 then
            this.JoinLeaveHistory.RemoveAt(0)
        else
            ()

    member this.GetJoinLeaveHistory() = this.JoinLeaveHistory.ToArray()

type ServerState() =
    member val ServerName = "MinimalIRCServer" with get, set
    member val ServerVersion = "0.1" with get, set
    member val Uptime = DateTime.UtcNow with get, set
    member val Motd = "Serveur Service-Overtchat créer par SerVuS" with get, set
    member val ConnectedUsers = ConcurrentDictionary<string, UserState>() with get, set
    member val ActiveChannels = ConcurrentDictionary<string, ChannelState>() with get, set
    member val OperatorList = Set.empty<string> with get, set
    member val BanList = Set.empty<string> with get, set
    member val InviteList = Set.empty<string> with get, set
    member val QuietList = Set.empty<string> with get, set
    member this.GetUptime() = DateTime.UtcNow - this.Uptime
    member this.GetConnectedUsersCount() = this.ConnectedUsers.Count
    member this.GetActiveChannelsCount() = this.ActiveChannels.Count

type CommandeIRC =
    | Nick of string
    | User of string * string
    | Join of string
    | Msg of string * string
    | Quit
    | Who of string
    | Mode of string * string option
    | Topic of string * string option
    | Whois of string
    | UMode of string
    | Unknown of string
    | NoOp of string
    | Ping of string
    | Pong of string
    | Part of string * string option
    | Kick of string * string * string option
    | Invite of string * string * string option
    | ListUsers of string option
    | ListChannels of string option * string option
    | Away of string option
    | Notice of string * string option
    | Oper of string * string option
    | Wallops of string option
    | Lusers of string option
    | Time of string option
    | Version of string option
    | Stats of string * string option
    | Links of string * string option
    | Trace of string option
    | Admin of string option
    | Info of string option
    | Summon of string option * string option
    | Users of string option
    | Wall of string option
    | Kill of string option * string option
    | Rehash of string option
    | Die of string option
    | SQuit of string * string option
    | Connect of string * string option
    | Restart of string * string option
    | SummonUser of string * string option
    | OperWallops of string option
    | UserHost of string option
    | Ison of string option
    | WhoWas of string * string option
    | Cap of string option
    | AwayMessage of string option
    | InviteOnlyMode of string option
    | NoExternalMessagesMode of string option
    | ModeratedMode of string option
    | SecretMode of string option option
    | PrivateMode of string option
    | TopicProtectionMode of string option
    | ChannelKeyMode of string * string option
    | UserLimitMode of string * string option
    | BanMaskMode of string * string option
    | ExceptionMaskMode of string * string option
    | InviteMaskMode of string * string option
    | QuietMaskMode of string * string option
    | OpMode of string * string option
    | DeOpMode of string * string option
    | VoiceMode of string * string option
    | DeVoiceMode of string * string option
    | HalfOpMode of string * string option
    | DeHalfOpMode of string * string option
    | ChannelBanList of string
    | ChannelExceptionList of string
    | ChannelInviteList of string
    | ChannelQuietList of string
    | WhoChannelList of string
    | WhoServerList of string
    | WhoOperatorList of string
    | WhoIdleList of string
    | WhoRealNameList of string
    | WhoHostList of string
    | WhoAwayList of string
    | WhoIsOperatorList of string
    | WhoIsIdleList of string
    | WhoIsChannelsList of string
    | WhoIsServerList of string
    | WhoIsRealNameList of string
    | WhoIsHostList of string
    | WhoIsAwayList of string
    | WhoWasChannelsList of string
    | WhoWasServerList of string
    | WhoWasRealNameList of string
    | WhoWasHostList of string
    | WhoWasIdleList of string
    | WhoWasOperatorList of string
    | WhoWasAwayList of string option
    | WhoWasList of string option
    | WhoList of string option
    | WhoIsList of string option
    | WhoWasUserList of string option
    | WhoWasChannelList of string option
    | WhoWasServerListOption of string option
    | WhoWasRealNameListOption of string option
    | WhoWasHostListOption of string option
    | WhoWasIdleListOption of string option
    | WhoWasOperatorListOption of string option
    | WhoWasAwayListOption of string option
    | WhoWasListOption of string option
    | WhoListOption of string option
    | WhoIsListOption of string option
    | WhoWasUserListOption of string option
    | WhoWasChannelListOption of string option
    | Motd of string option

// ----------------- Parseur -----------------

let handlePing (client: TcpClient) (token: string) =
    let response = sprintf "PONG :%s" token
    let data = Encoding.UTF8.GetBytes(response + "\r\n")
    client.GetStream().Write(data, 0, data.Length)

let parseCommande (input: string) : CommandeIRC =
    let tokens = input.Trim().Split(' ') |> List.ofArray

    match tokens with
    | [] -> Unknown input
    | cmd :: rest ->
        match cmd.ToUpper() with
        | _ when cmd.ToUpper() = "NICK" -> if rest.Length >= 1 then Nick rest.[0] else Unknown input
        | _ when cmd.ToUpper() = "USER" ->
            if rest.Length >= 4 then
                let ident = rest.[0]

                let realname =
                    String.concat " " rest.[3..]
                    |> fun s -> if s.StartsWith(":") then s.[1..] else s

                User(ident, realname)
            else
                Unknown input
        | _ when cmd.ToUpper() = "JOIN" -> if rest.Length >= 1 then Join rest.[0] else Unknown input
        | _ when cmd.ToUpper() = "PRIVMSG" ->
            if rest.Length >= 2 then
                let cible = rest.[0]

                let contenu =
                    String.concat " " rest.[1..]
                    |> fun s -> if s.StartsWith(":") then s.[1..] else s

                Msg(cible, contenu)
            else
                Unknown input
        | _ when cmd.ToUpper() = "QUIT" -> Quit
        | _ when cmd.ToUpper() = "WHO" -> if rest.Length >= 1 then Who rest.[0] else Unknown input
        | _ when cmd.ToUpper() = "TOPIC" ->
            if rest.Length >= 1 then
                let channelName = rest.[0]

                let maybeTopic =
                    if rest.Length >= 2 then
                        Some(
                            String.concat " " rest.[1..]
                            |> fun s -> if s.StartsWith(":") then s.[1..] else s
                        )
                    else
                        None

                Topic(channelName, maybeTopic)
            else
                Unknown input
        | _ when cmd.ToUpper() = "MODE" ->
            if rest.Length >= 1 then
                let target = rest.[0]

                let maybeMode =
                    if rest.Length >= 2 then
                        Some(
                            String.concat " " rest.[1..]
                            |> fun s -> if s.StartsWith(":") then s.[1..] else s
                        )
                    else
                        None

                Mode(target, maybeMode)
            else
                Unknown input
        | _ when cmd.ToUpper() = "WHOIS" -> if rest.Length >= 1 then Whois rest.[0] else Unknown input
        | _ when cmd.ToUpper() = "UMODE" ->
            if rest.Length >= 1 then
                UMode(String.concat " " rest)
            else
                Unknown input
        | _ when cmd.ToUpper() = "PING" -> Ping(String.concat " " rest)
        | _ when cmd.ToUpper() = "PONG" -> Pong(String.concat " " rest)
        | _ when cmd.ToUpper() = "PART" ->
            let channel = if rest.Length >= 1 then rest.[0] else ""

            let reason =
                if rest.Length >= 2 then
                    Some(String.concat " " rest.[1..])
                else
                    None

            Part(channel, reason)
        | _ when cmd.ToUpper() = "KICK" ->
            let channel = if rest.Length >= 1 then rest.[0] else ""
            let user = if rest.Length >= 2 then rest.[1] else ""

            let reason =
                if rest.Length >= 3 then
                    Some(String.concat " " rest.[2..])
                else
                    None

            Kick(channel, user, reason)
        | _ when cmd.ToUpper() = "INVITE" ->
            if rest.Length >= 2 then
                Invite(
                    rest.[0],
                    rest.[1],
                    if rest.Length >= 3 then
                        Some(String.concat " " rest.[2..])
                    else
                        None
                )
            else
                Unknown input
        | _ when cmd.ToUpper() = "NOTICE" ->
            if rest.Length >= 1 then
                let cible = rest.[0]

                let message =
                    if rest.Length >= 2 then
                        Some(String.concat " " rest.[1..])
                    else
                        None

                Notice(cible, message)
            else
                Unknown input
        | _ when cmd.ToUpper() = "OPER" ->
            if rest.Length >= 1 then
                let name = rest.[0]

                let password =
                    if rest.Length >= 2 then
                        Some(String.concat " " rest.[1..])
                    else
                        None

                Oper(name, password)
            else
                Unknown input
        | _ when cmd.ToUpper() = "WALLOPS" ->
            Wallops(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "AWAY" ->
            Away(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "LIST" ->
            let chanOpt = if rest.Length >= 1 then Some rest.[0] else None

            let servOpt =
                if rest.Length >= 2 then
                    Some(String.concat " " rest.[1..])
                else
                    None

            ListChannels(chanOpt, servOpt)
        | _ when cmd.ToUpper() = "LUSERS" ->
            Lusers(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "TIME" ->
            Time(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "VERSION" ->
            Version(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "STATS" ->
            if rest.Length >= 1 then
                Stats(
                    rest.[0],
                    if rest.Length >= 2 then
                        Some(String.concat " " rest.[1..])
                    else
                        None
                )
            else
                Stats("", None)
        | _ when cmd.ToUpper() = "LINKS" ->
            if rest.Length >= 1 then
                Links(
                    rest.[0],
                    if rest.Length >= 2 then
                        Some(String.concat " " rest.[1..])
                    else
                        None
                )
            else
                Links("", None)
        | _ when cmd.ToUpper() = "TRACE" ->
            Trace(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "ADMIN" ->
            Admin(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "INFO" ->
            Info(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "SUMMON" ->
            Summon(
                (if rest.Length >= 1 then Some rest.[0] else None),
                (if rest.Length >= 2 then
                     Some(String.concat " " rest.[1..])
                 else
                     None)
            )
        | _ when cmd.ToUpper() = "USERS" ->
            Users(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "WALL" ->
            Wall(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "KILL" ->
            let target = if rest.Length >= 1 then Some rest.[0] else None

            let comment =
                if rest.Length >= 2 then
                    Some(String.concat " " rest.[1..])
                else
                    None

            Kill(target, comment)
        | _ when cmd.ToUpper() = "REHASH" ->
            Rehash(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "DIE" ->
            Die(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "SQUIT" ->
            let server = if rest.Length >= 1 then rest.[0] else ""

            let comment =
                if rest.Length >= 2 then
                    Some(String.concat " " rest.[1..])
                else
                    None

            SQuit(server, comment)
        | _ when cmd.ToUpper() = "CONNECT" ->
            if rest.Length >= 1 then
                Connect(
                    rest.[0],
                    if rest.Length >= 2 then
                        Some(String.concat " " rest.[1..])
                    else
                        None
                )
            else
                Connect("", None)
        | _ when cmd.ToUpper() = "RESTART" ->
            if rest.Length >= 1 then
                Restart(
                    rest.[0],
                    if rest.Length >= 2 then
                        Some(String.concat " " rest.[1..])
                    else
                        None
                )
            else
                Restart("", None)
        | _ when cmd.ToUpper() = "SUMMONUSER" ->
            let user = if rest.Length >= 1 then rest.[0] else ""

            let arg =
                if rest.Length >= 2 then
                    Some(String.concat " " rest.[1..])
                else
                    None

            SummonUser(user, arg)
        | _ when cmd.ToUpper() = "OPERWALLOPS" ->
            OperWallops(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "USERHOST" ->
            UserHost(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "ISON" ->
            Ison(
                if rest.Length >= 1 then
                    Some(String.concat " " rest)
                else
                    None
            )
        | _ when cmd.ToUpper() = "WHOWAS" ->
            let nick = if rest.Length >= 1 then rest.[0] else ""

            let server =
                if rest.Length >= 2 then
                    Some(String.concat " " rest.[1..])
                else
                    None

            WhoWas(nick, server)
        | _ -> Unknown input

// ----------------- Serveur -----------------

let channels = ConcurrentDictionary<string, ChannelState>()
let clients = ConcurrentDictionary<string, UserState>()

let broadcast (message: string) =
    for kvp in clients.Values do
        match kvp.Writer with
        | Some w ->
            w.WriteLine(message)
            w.Flush()
        | None -> ()

let traiterCommande (user: UserState) (cmd: CommandeIRC) =
    match user.Writer with
    | None -> ()
    | Some writer ->
        match cmd with
        | Nick pseudo ->
            let old = user.Nick
            user.Nick <- pseudo
            clients.TryRemove old |> ignore
            clients.TryAdd(pseudo, user) |> ignore
            writer.WriteLine($":server 001 {pseudo} :Bienvenue sur le serveur minimal")
        | User(ident, realname) ->
            user.Ident <- ident
            user.RealName <- realname

            writer.WriteLine($":server 001 {user.Nick} :Bienvenue {user.Nick}")
            writer.WriteLine($":server 002 {user.Nick} :Utilisateur enregistré ({ident})")

            // Envoi du MOTD (RPL_MOTD)
            writer.WriteLine($":server 375 {user.Nick} :- Message du jour -")

            for line in motd do
                writer.WriteLine($":server 372 {user.Nick} :- {line}")

            writer.WriteLine($":server 376 {user.Nick} :Fin du MOTD")

            writer.Flush()
        | Join channelName ->
            let ch = channels.GetOrAdd(channelName, fun n -> ChannelState(n))
            ch.Users.TryAdd(user.Nick, user) |> ignore
            user.CurrentChannels <- user.CurrentChannels.Add(channelName)
            writer.WriteLine($":{user.Nick}!{user.Ident}@localhost JOIN {channelName}")
        | Msg(cible, contenu) ->
            if cible.StartsWith("#") then
                match channels.TryGetValue(cible) with
                | true, ch ->
                    for kvp in ch.Users.Values do
                        match kvp.Writer with
                        | Some w ->
                            w.WriteLine($":{user.Nick}!{user.Ident}@localhost PRIVMSG {cible} :{contenu}")
                            w.Flush()
                        | None -> ()
                | _ -> writer.WriteLine($":server 403 {user.Nick} {cible} :No such channel")
            else
                match clients.TryGetValue(cible) with
                | true, target ->
                    match target.Writer with
                    | Some w ->
                        w.WriteLine($":{user.Nick}!{user.Ident}@localhost PRIVMSG {cible} :{contenu}")
                        w.Flush()
                    | None -> ()
                | false, _ -> writer.WriteLine($":server 401 {user.Nick} {cible} :No such nick")
        | Quit ->
            for chName in user.CurrentChannels do
                match channels.TryGetValue(chName) with
                | true, ch -> ch.Users.TryRemove(user.Nick) |> ignore
                | _ -> ()

            clients.TryRemove user.Nick |> ignore
            writer.WriteLine($":{user.Nick}!{user.Ident}@localhost QUIT :Déconnecté")
        | Who channelName ->
            match channels.TryGetValue(channelName) with
            | true, ch ->
                for u in ch.Users.Values do
                    writer.WriteLine($":server 352 {user.Nick} {channelName} {u.Ident} {u.Nick} :0 {u.RealName}")
            | false, _ -> writer.WriteLine($":server 403 {user.Nick} {channelName} :No such channel")
        | Topic(channelName, maybeTopic) ->
            match channels.TryGetValue(channelName) with
            | true, ch ->
                match maybeTopic with
                | Some t ->
                    ch.Topic <- t
                    writer.WriteLine($":server 332 {user.Nick} {channelName} :{t}")
                | None -> writer.WriteLine($":server 332 {user.Nick} {channelName} :{ch.Topic}")
            | false, _ -> writer.WriteLine($":server 403 {user.Nick} {channelName} :No such channel")
        | Mode(target, maybeMode) ->
            // Pour l'instant juste affichage
            let mode = maybeMode |> Option.defaultValue ""
            writer.WriteLine($":server 324 {user.Nick} {target} :{mode}")
        | Whois targetNick ->
            match clients.TryGetValue(targetNick) with
            | true, u -> writer.WriteLine($":server 311 {user.Nick} {u.Nick} {u.Ident} localhost * :{u.RealName}")
            | false, _ -> writer.WriteLine($":server 401 {user.Nick} {targetNick} :No such nick")
        | UMode modes ->
            user.Modes <- modes
            writer.WriteLine($":server 221 {user.Nick} {modes}")
        | Unknown raw when raw.ToUpper() = "MOTD" ->
            writer.WriteLine($":server 375 {user.Nick} :- Message du jour -")

            for line in motd do
                writer.WriteLine($":server 372 {user.Nick} :- {line}")

            writer.WriteLine($":server 376 {user.Nick} :Fin du MOTD")
        | Unknown raw when raw <> "" -> writer.WriteLine($":server NOTICE {user.Nick} :Commande inconnue '{raw}'")
        | _ -> ()

        writer.Flush()

// ----------------- Gestion connexion -----------------

let handleClient (clientTcp: TcpClient) =
    async {
        use stream = clientTcp.GetStream()
        use reader = new StreamReader(stream)
        use writer = new StreamWriter(stream)
        writer.AutoFlush <- true

        let user = UserState()
        user.Writer <- Some writer

        writer.WriteLine("Bienvenue ! Utilisez NICK <pseudo> et USER <ident> 0 * :<realname>")
        writer.WriteLine("Puis JOIN, PRIVMSG, WHO, MODE, TOPIC, WHOIS, UMODE, QUIT.")

        let rec loop () =
            async {
                let! line = reader.ReadLineAsync() |> Async.AwaitTask

                if line <> null then
                    let cmd = parseCommande line
                    traiterCommande user cmd

                    if cmd <> Quit then
                        return! loop ()
            }

        do! loop ()
    }

[<EntryPoint>]
let main _ =
    let listener = new TcpListener(IPAddress.Any, 6667)
    listener.Start()
    printfn "Serveur IRC local complet démarré sur 0.0.0.0:6667"

    let rec acceptLoop () =
        async {
            let! client = listener.AcceptTcpClientAsync() |> Async.AwaitTask
            Async.Start(handleClient client)
            return! acceptLoop ()
        }

    acceptLoop () |> Async.RunSynchronously
    0
