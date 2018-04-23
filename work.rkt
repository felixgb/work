#lang racket

(require racket/cmdline
         racket/system)

(struct env (name commands))

(define workspace
  (getenv "WORKSPACE"))

(define (r . cmd)
  (with-output-to-string
    (lambda ()
      (system
       (apply string-append cmd)
       #:set-pwd? #t))))

(define (start cmd)
  (lambda (session)
    (r "tmux send-keys -t " session " '" cmd "' C-m")))

(define (split axis)
  (lambda (session)
    (r "tmux split-window -" axis " -t " session)))

(define split-h (split "h"))
(define split-v (split "v"))

; set term to make sbt happy
(define boring-term (start "export TERM=screen"))
(define sbt (start "sbt"))
(define smserver (start "smserver"))
(define firefox (start "firefox -P felix-work"))
(define idea (start "~/Desktop/idea-IU-181.4203.550/bin/idea.sh"))
(define vpn (start "sudo openvpn ~/hmrc/progs/hmrc-vpn.ovpn"))

(define current-working-repos
  (list (env "email" (list boring-term split-h))
        (env "message" (list boring-term split-h))
        (env "hmrc-email-renderer" (list boring-term split-h))
        (env "progs" (list firefox split-h idea split-v vpn))
        (env "service-manager" (list smserver split-h))))

(define session-names
  (map env-name current-working-repos))

(define (full-path-for repo-name)
  (string-append workspace repo-name))

(define (new-tmux-session dir)
  (r "cd " dir " && tmux new -d -s $(basename $PWD)"))

(define (kill-session name)
  (r "tmux kill-session -t " name))

(define (start-sessions)
  (map
   (lambda (dir) (new-tmux-session (full-path-for dir)))
   session-names))

(define (start-commands-for session)
  (map
   (lambda (cmd) (cmd (env-name session)))
   (env-commands session)))

(define (stop-work)
  (map kill-session session-names))

(define (start-work)
  (begin
    (start-sessions)
    (map start-commands-for current-working-repos)))

(command-line
 #:program "work"
 #:once-any
 [("-t" "--start") "Start doing work" (start-work)]
 [("-p" "--stop") "Stop doing work" (stop-work)])
