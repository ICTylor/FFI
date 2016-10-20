#lang racket
(require racket/gui/base)
(require ffi/unsafe
         ffi/unsafe/define)

; Set libvlc location
(define-ffi-definer define-vlc (ffi-lib "libvlc"))

; Define some libvlc types
(define _libvlc_instance_t-pointer (_cpointer/null 'libvlc_instance_t))
(define _libvlc_media_player_t-pointer (_cpointer/null 'libvlc_media_player_t))
(define _libvlc_media_t-pointer (_cpointer/null 'libvlc_media_t))
(define _libvlc_time_t _int64)

; libvlc definitions
(define-vlc libvlc_new (_fun _int (_list i _string) -> _libvlc_instance_t-pointer))
(define-vlc libvlc_release (_fun  _libvlc_instance_t-pointer -> _void))

; libvlc media_player definitions
(define-vlc libvlc_media_player_new (_fun _libvlc_instance_t-pointer -> _libvlc_media_player_t-pointer))
(define-vlc libvlc_media_new_location (_fun _libvlc_instance_t-pointer _string -> _libvlc_media_t-pointer))
(define-vlc libvlc_media_new_path (_fun _libvlc_instance_t-pointer _string -> _libvlc_media_t-pointer))
(define-vlc libvlc_media_player_set_media (_fun _libvlc_media_player_t-pointer _libvlc_media_t-pointer -> _void))
(define-vlc libvlc_media_player_set_time (_fun _libvlc_media_player_t-pointer _libvlc_time_t -> _void))
(define-vlc libvlc_media_player_get_time (_fun _libvlc_media_player_t-pointer -> _libvlc_time_t ))
(define-vlc libvlc_media_player_pause (_fun _libvlc_media_player_t-pointer -> _void))
(define-vlc libvlc_media_player_play (_fun _libvlc_media_player_t-pointer -> _int))
(define-vlc libvlc_media_player_stop (_fun _libvlc_media_player_t-pointer -> _void))
(define-vlc libvlc_media_player_release (_fun _libvlc_media_player_t-pointer -> _void))

(define (vlc-time-command media-player sign minutes seconds)
  (let ((current-time (libvlc_media_player_get_time media-player))
        (arg-time-ms (* (+ seconds (* minutes 60)) 1000))
        )
    (match sign
      ["=" (libvlc_media_player_set_time media-player arg-time-ms)]
      ["+" (libvlc_media_player_set_time media-player (+ current-time arg-time-ms))]
      ["-" (libvlc_media_player_set_time media-player (- current-time arg-time-ms))]
      [_ 'nop]
      ))
  )

; Make a frame by instantiating the frame% class
(define frame (new frame% [label "Example"]))
 
; Make a static text message in the frame
(define msg (new message% [parent frame]
                          [label "No events so far..."]
                          [auto-resize #t]))
(define command-field
  ; Make a button in the frame
  (new text-field% [parent frame]
       [label "Command:"]
       ; Callback procedure for a button click:
       [callback (lambda (field event)
                   (let ((text (send field get-value)))
                     (match text
                       ["p;" (send msg set-label "play/pause")
                             (void (libvlc_media_player_pause media-player))]
                       ["s;" (send msg set-label "stop")
                             (void (libvlc_media_player_stop media-player))]
                       ["q;"
                        (void (libvlc_media_player_stop media-player))
                        (void (libvlc_media_player_release media-player))
                        (void (libvlc_release vlc))                      
                        (send msg set-label "quit...")
                        (exit 0)
                        ]
                       ["o;"
                        (let* ((path (get-file ""))
                               (media (libvlc_media_new_path vlc path))
                               )
                          (if path
                              (void
                               (send msg set-label (~a "Path: " path))
                               (void (libvlc_media_player_set_media media-player media))
                               (void (libvlc_media_player_play media-player))
                               )
                              'nop
                              )
                          )
                        ]
                       [(regexp #px"^[+-=]{1}\\d+:\\d+;")
                        (let* ((groups (regexp-match #px"^([+-=]{1})(\\d+):(\\d+);" text))
                               (sign (second groups))
                               (minutes (string->number (third groups)))
                               (seconds (string->number (fourth groups))))
                          (vlc-time-command media-player sign minutes seconds)
                          (send msg set-label (~a sign minutes "minutes" "and" seconds "seconds" #:separator " ") ))
                        ]
                       [(regexp #px"^o(.+);")
                        (let* ((groups (regexp-match #px"^o(.+);" text))
                               (path (second groups))
                               (media (libvlc_media_new_path vlc path))
                               )
                          (send msg set-label (~a "Path: " path))
                          (void (libvlc_media_player_set_media media-player media))
                          (void (libvlc_media_player_play media-player))
                          )
                        ]
                       [_ 'nop])
                     ))])
  )
 
; Show the frame by calling its show method
(send frame show #t)

(define vlc (libvlc_new 0 '("")))
(define media-player (libvlc_media_player_new vlc))
(define big-buck-bunny-url "http://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_480p_surround-fix.avi")
(define media (libvlc_media_new_location vlc big-buck-bunny-url))
(void (libvlc_media_player_set_media media-player media))
(void (libvlc_media_player_play media-player))